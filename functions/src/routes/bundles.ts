import { Router } from 'express';
import * as admin from 'firebase-admin';
import { authenticateUser } from '../middleware/auth';
import { Bundle, BundlesQueryParams, ApiResponse, PaginatedResponse } from '../models';

const router = Router();
const db = admin.firestore();

/**
 * GET /api/bundles
 * Get all bundles with optional pagination
 */
router.get('/', authenticateUser, async (req, res) => {
  try {
    const {
      limit = 20,
      offset = 0
    } = req.query as any as BundlesQueryParams;

    let query = db.collection('bundles').orderBy('displayOrder', 'asc');

    // Apply pagination
    const limitNum = Math.min(Number(limit) || 20, 50); // Max 50 items
    const offsetNum = Number(offset) || 0;

    if (offsetNum > 0) {
      query = query.offset(offsetNum);
    }
    query = query.limit(limitNum);

    const snapshot = await query.get();
    const bundles: Bundle[] = [];

    snapshot.forEach(doc => {
      bundles.push({
        id: doc.id,
        ...doc.data()
      } as Bundle);
    });

    // Get total count for pagination
    const totalSnapshot = await db.collection('bundles').count().get();
    const total = totalSnapshot.data().count;

    const response: ApiResponse<PaginatedResponse<Bundle>> = {
      success: true,
      data: {
        items: bundles,
        total,
        limit: limitNum,
        offset: offsetNum,
        hasMore: offsetNum + limitNum < total
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching bundles:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch bundles'
    });
  }
});

/**
 * GET /api/bundles/:id
 * Get a specific bundle by ID
 */
router.get('/:id', authenticateUser, async (req, res) => {
  try {
    const { id } = req.params;
    
    const doc = await db.collection('bundles').doc(id).get();
    
    if (!doc.exists) {
      res.status(404).json({
        success: false,
        error: 'Bundle not found'
      });
      return;
    }

    const bundle: Bundle = {
      id: doc.id,
      ...doc.data()
    } as Bundle;

    const response: ApiResponse<Bundle> = {
      success: true,
      data: bundle
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching bundle:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch bundle'
    });
  }
});

/**
 * GET /api/bundles/:id/habits
 * Get all habits in a specific bundle
 */
router.get('/:id/habits', authenticateUser, async (req, res) => {
  try {
    const { id } = req.params;
    
    // First get the bundle to get habit IDs
    const bundleDoc = await db.collection('bundles').doc(id).get();
    
    if (!bundleDoc.exists) {
      res.status(404).json({
        success: false,
        error: 'Bundle not found'
      });
      return;
    }

    const bundle = bundleDoc.data() as Bundle;
    
    if (!bundle.habitIds || bundle.habitIds.length === 0) {
      res.json({
        success: true,
        data: []
      });
      return;
    }

    // Firestore 'in' query supports up to 10 values
    const habits: any[] = [];
    
    // Process in chunks of 10
    for (let i = 0; i < bundle.habitIds.length; i += 10) {
      const chunk = bundle.habitIds.slice(i, i + 10);
      const snapshot = await db.collection('habits')
        .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
        .get();
      
      snapshot.forEach(doc => {
        habits.push({
          id: doc.id,
          ...doc.data()
        });
      });
    }

    // Sort habits by their order in the bundle
    habits.sort((a, b) => {
      const indexA = bundle.habitIds.indexOf(a.id);
      const indexB = bundle.habitIds.indexOf(b.id);
      return indexA - indexB;
    });

    const response: ApiResponse<any[]> = {
      success: true,
      data: habits
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching bundle habits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch bundle habits'
    });
  }
});

export { router as bundlesRouter };
