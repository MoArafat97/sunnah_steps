import { Router } from 'express';
import * as admin from 'firebase-admin';
import { authenticateUser } from '../middleware/auth';
import { Habit, HabitsQueryParams, ApiResponse, PaginatedResponse } from '../models';

const router = Router();
const db = admin.firestore();

/**
 * GET /api/habits
 * Get all habits with optional filtering
 */
router.get('/', authenticateUser, async (req, res) => {
  try {
    const {
      category,
      tags,
      limit = 50,
      offset = 0
    } = req.query as any as HabitsQueryParams;

    let query = db.collection('habits').orderBy('priority', 'desc');

    // Apply category filter
    if (category) {
      query = query.where('category', '==', category);
    }

    // Apply tags filter (array-contains-any)
    if (tags && Array.isArray(tags) && tags.length > 0) {
      // Firestore array-contains-any supports up to 10 values
      const tagsToFilter = tags.slice(0, 10);
      query = query.where('tags', 'array-contains-any', tagsToFilter);
    }

    // Apply pagination
    const limitNum = Math.min(Number(limit) || 50, 100); // Max 100 items
    const offsetNum = Number(offset) || 0;

    if (offsetNum > 0) {
      query = query.offset(offsetNum);
    }
    query = query.limit(limitNum);

    const snapshot = await query.get();
    const habits: Habit[] = [];

    snapshot.forEach(doc => {
      habits.push({
        id: doc.id,
        ...doc.data()
      } as Habit);
    });

    // Get total count for pagination (this is expensive, consider caching)
    let totalQuery: admin.firestore.Query = db.collection('habits');
    if (category) {
      totalQuery = totalQuery.where('category', '==', category);
    }
    if (tags && Array.isArray(tags) && tags.length > 0) {
      const tagsToFilter = tags.slice(0, 10);
      totalQuery = totalQuery.where('tags', 'array-contains-any', tagsToFilter);
    }
    const totalSnapshot = await totalQuery.count().get();
    const total = totalSnapshot.data().count;

    const response: ApiResponse<PaginatedResponse<Habit>> = {
      success: true,
      data: {
        items: habits,
        total,
        limit: limitNum,
        offset: offsetNum,
        hasMore: offsetNum + limitNum < total
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching habits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch habits'
    });
  }
});

/**
 * GET /api/habits/:id
 * Get a specific habit by ID
 */
router.get('/:id', authenticateUser, async (req, res) => {
  try {
    const { id } = req.params;

    const doc = await db.collection('habits').doc(id).get();

    if (!doc.exists) {
      res.status(404).json({
        success: false,
        error: 'Habit not found'
      });
      return;
    }

    const habit: Habit = {
      id: doc.id,
      ...doc.data()
    } as Habit;

    const response: ApiResponse<Habit> = {
      success: true,
      data: habit
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching habit:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch habit'
    });
  }
});

/**
 * GET /api/habits/search/:query
 * Search habits by title, tags, or benefits
 */
router.get('/search/:query', authenticateUser, async (req, res) => {
  try {
    const { query: searchQuery } = req.params;
    const { limit = 20 } = req.query as any;

    if (!searchQuery || searchQuery.length < 2) {
      res.status(400).json({
        success: false,
        error: 'Search query must be at least 2 characters'
      });
      return;
    }

    // Note: Firestore doesn't support full-text search natively
    // This is a basic implementation - consider using Algolia or similar for production
    const snapshot = await db.collection('habits')
      .orderBy('priority', 'desc')
      .limit(Number(limit) || 20)
      .get();

    const searchTerm = searchQuery.toLowerCase();
    const habits: Habit[] = [];

    snapshot.forEach(doc => {
      const data = doc.data() as Habit;
      const title = data.title.toLowerCase();
      const benefits = data.benefits.toLowerCase();
      const tags = data.tags.map(tag => tag.toLowerCase());

      // Simple text matching
      if (title.includes(searchTerm) ||
          benefits.includes(searchTerm) ||
          tags.some(tag => tag.includes(searchTerm))) {
        habits.push({
          ...data,
          id: doc.id
        });
      }
    });

    const response: ApiResponse<Habit[]> = {
      success: true,
      data: habits
    };

    res.json(response);
  } catch (error) {
    console.error('Error searching habits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search habits'
    });
  }
});

export { router as habitsRouter };
