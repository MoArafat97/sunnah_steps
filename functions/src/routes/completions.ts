import { Router } from 'express';
import * as admin from 'firebase-admin';
import { authenticateUser, requireOwnershipOrRole } from '../middleware/auth';
import {
  CompletionLog,
  CreateCompletionRequest,
  CompletionLogQueryParams,
  ApiResponse,
  PaginatedResponse
} from '../models';

const router = Router();
const db = admin.firestore();

/**
 * POST /api/completions
 * Create a new habit completion log entry
 * This is the endpoint mentioned in the requirements for unit testing
 */
router.post('/', authenticateUser, async (req, res) => {
  try {
    const { habitId, source = 'api', note } = req.body as CreateCompletionRequest;
    const userId = req.user!.uid;

    // Validate required fields
    if (!habitId) {
      res.status(400).json({
        success: false,
        error: 'habitId is required'
      });
      return;
    }

    // Validate source
    if (!['checklist', 'api'].includes(source)) {
      res.status(400).json({
        success: false,
        error: 'source must be either "checklist" or "api"'
      });
      return;
    }

    // Verify habit exists
    const habitDoc = await db.collection('habits').doc(habitId).get();
    if (!habitDoc.exists) {
      res.status(404).json({
        success: false,
        error: 'Habit not found'
      });
      return;
    }

    // Create completion log entry
    const completionData: Omit<CompletionLog, 'id'> = {
      habitId,
      completedAt: admin.firestore.Timestamp.now(),
      source,
      ...(note && { note })
    };

    // Add to user's completion_log subcollection
    const docRef = await db.collection('users').doc(userId)
      .collection('completion_log').add(completionData);

    const completion: CompletionLog = {
      id: docRef.id,
      ...completionData
    };

    const response: ApiResponse<CompletionLog> = {
      success: true,
      data: completion,
      message: 'Habit completion logged successfully'
    };

    res.status(201).json(response);
  } catch (error) {
    console.error('Error creating completion:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to log habit completion'
    });
  }
});

/**
 * GET /api/completions/:userId
 * Get completion log for a specific user
 */
router.get('/:userId', authenticateUser, requireOwnershipOrRole('userId'), async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      habitId,
      startDate,
      endDate,
      limit = 50,
      offset = 0
    } = req.query as any as CompletionLogQueryParams;

    let query = db.collection('users').doc(userId)
      .collection('completion_log')
      .orderBy('completedAt', 'desc');

    // Apply filters
    if (habitId) {
      query = query.where('habitId', '==', habitId);
    }

    if (startDate) {
      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      query = query.where('completedAt', '>=', start);
    }

    if (endDate) {
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
      query = query.where('completedAt', '<=', end);
    }

    // Apply pagination
    const limitNum = Math.min(Number(limit) || 50, 100); // Max 100 items
    const offsetNum = Number(offset) || 0;

    if (offsetNum > 0) {
      query = query.offset(offsetNum);
    }
    query = query.limit(limitNum);

    const snapshot = await query.get();
    const completions: CompletionLog[] = [];

    snapshot.forEach(doc => {
      completions.push({
        id: doc.id,
        ...doc.data()
      } as CompletionLog);
    });

    // Get total count for pagination
    let countQuery: admin.firestore.Query = db.collection('users').doc(userId).collection('completion_log');
    if (habitId) {
      countQuery = countQuery.where('habitId', '==', habitId);
    }
    if (startDate) {
      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      countQuery = countQuery.where('completedAt', '>=', start);
    }
    if (endDate) {
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
      countQuery = countQuery.where('completedAt', '<=', end);
    }

    const totalSnapshot = await countQuery.count().get();
    const total = totalSnapshot.data().count;

    const response: ApiResponse<PaginatedResponse<CompletionLog>> = {
      success: true,
      data: {
        items: completions,
        total,
        limit: limitNum,
        offset: offsetNum,
        hasMore: offsetNum + limitNum < total
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching completions:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch completion log'
    });
  }
});

/**
 * GET /api/completions/:userId/stats
 * Get completion statistics for a user
 */
router.get('/:userId/stats', authenticateUser, requireOwnershipOrRole('userId'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { days = 30 } = req.query as any;

    const daysNum = Math.min(Number(days) || 30, 365); // Max 1 year
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - daysNum);

    const snapshot = await db.collection('users').doc(userId)
      .collection('completion_log')
      .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .get();

    const stats = {
      totalCompletions: snapshot.size,
      uniqueHabits: new Set<string>(),
      completionsByDay: {} as Record<string, number>,
      completionsByHabit: {} as Record<string, number>,
      completionsBySource: { checklist: 0, api: 0 }
    };

    snapshot.forEach(doc => {
      const data = doc.data() as CompletionLog;

      // Track unique habits
      stats.uniqueHabits.add(data.habitId);

      // Track completions by day
      const day = data.completedAt.toDate().toISOString().split('T')[0];
      stats.completionsByDay[day] = (stats.completionsByDay[day] || 0) + 1;

      // Track completions by habit
      stats.completionsByHabit[data.habitId] = (stats.completionsByHabit[data.habitId] || 0) + 1;

      // Track completions by source
      stats.completionsBySource[data.source]++;
    });

    const response: ApiResponse<any> = {
      success: true,
      data: {
        ...stats,
        uniqueHabitsCount: stats.uniqueHabits.size,
        uniqueHabits: undefined // Remove the Set object
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching completion stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch completion statistics'
    });
  }
});

/**
 * DELETE /api/completions/:userId/:completionId
 * Delete a specific completion log entry
 */
router.delete('/:userId/:completionId', authenticateUser, requireOwnershipOrRole('userId'), async (req, res) => {
  try {
    const { userId, completionId } = req.params;

    const docRef = db.collection('users').doc(userId)
      .collection('completion_log').doc(completionId);

    const doc = await docRef.get();
    if (!doc.exists) {
      res.status(404).json({
        success: false,
        error: 'Completion log entry not found'
      });
      return;
    }

    await docRef.delete();

    res.json({
      success: true,
      message: 'Completion log entry deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting completion:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete completion log entry'
    });
  }
});

export { router as completionsRouter };
