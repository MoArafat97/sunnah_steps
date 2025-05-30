import { Router } from 'express';
import * as admin from 'firebase-admin';
import { authenticateUser, requireOwnershipOrRole } from '../middleware/auth';
import { User, CreateUserRequest, ApiResponse } from '../models';

const router = Router();
const db = admin.firestore();

/**
 * POST /api/users
 * Create a new user document (usually called after Firebase Auth user creation)
 */
router.post('/', authenticateUser, async (req, res) => {
  try {
    const { displayName, email, role = 'user', locale = 'en' } = req.body as CreateUserRequest;
    
    if (!displayName || !email) {
      res.status(400).json({
        success: false,
        error: 'displayName and email are required'
      });
      return;
    }

    // Use the authenticated user's UID
    const uid = req.user!.uid;

    // Check if user document already exists
    const existingDoc = await db.collection('users').doc(uid).get();
    if (existingDoc.exists) {
      res.status(409).json({
        success: false,
        error: 'User document already exists'
      });
      return;
    }

    const userData: Omit<User, 'uid'> = {
      displayName,
      email,
      role: role as 'user' | 'coach',
      locale,
      createdAt: admin.firestore.Timestamp.now()
    };

    await db.collection('users').doc(uid).set(userData);

    const response: ApiResponse<User> = {
      success: true,
      data: {
        uid,
        ...userData
      }
    };

    res.status(201).json(response);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create user'
    });
  }
});

/**
 * GET /api/users/:userId
 * Get user profile
 */
router.get('/:userId', authenticateUser, requireOwnershipOrRole('userId'), async (req, res) => {
  try {
    const { userId } = req.params;
    
    const doc = await db.collection('users').doc(userId).get();
    
    if (!doc.exists) {
      res.status(404).json({
        success: false,
        error: 'User not found'
      });
      return;
    }

    const user: User = {
      uid: doc.id,
      ...doc.data()
    } as User;

    const response: ApiResponse<User> = {
      success: true,
      data: user
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user'
    });
  }
});

/**
 * PUT /api/users/:userId
 * Update user profile
 */
router.put('/:userId', authenticateUser, requireOwnershipOrRole('userId'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { displayName, locale } = req.body;

    // Validate input
    const updateData: Partial<User> = {};
    if (displayName) updateData.displayName = displayName;
    if (locale) updateData.locale = locale;

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({
        success: false,
        error: 'No valid fields to update'
      });
      return;
    }

    // Check if user exists
    const doc = await db.collection('users').doc(userId).get();
    if (!doc.exists) {
      res.status(404).json({
        success: false,
        error: 'User not found'
      });
      return;
    }

    await db.collection('users').doc(userId).update(updateData);

    // Return updated user
    const updatedDoc = await db.collection('users').doc(userId).get();
    const user: User = {
      uid: updatedDoc.id,
      ...updatedDoc.data()
    } as User;

    const response: ApiResponse<User> = {
      success: true,
      data: user
    };

    res.json(response);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update user'
    });
  }
});

/**
 * DELETE /api/users/:userId
 * Delete user account and all associated data
 */
router.delete('/:userId', authenticateUser, requireOwnershipOrRole('userId'), async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user exists
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      res.status(404).json({
        success: false,
        error: 'User not found'
      });
      return;
    }

    // Delete user's completion log (subcollection)
    const completionLogs = await db.collection('users').doc(userId)
      .collection('completion_log').get();
    
    const batch = db.batch();
    completionLogs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Delete user document
    batch.delete(db.collection('users').doc(userId));

    await batch.commit();

    // Also delete from Firebase Auth if user is deleting their own account
    if (req.user!.uid === userId) {
      try {
        await admin.auth().deleteUser(userId);
      } catch (authError) {
        console.error('Error deleting auth user:', authError);
        // Continue even if auth deletion fails
      }
    }

    res.json({
      success: true,
      message: 'User account deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete user'
    });
  }
});

export { router as usersRouter };
