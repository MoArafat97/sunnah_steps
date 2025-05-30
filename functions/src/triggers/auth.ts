import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { User } from '../models';

const db = admin.firestore();

/**
 * Cloud Function triggered when a new user is created in Firebase Auth
 * Automatically creates a user document in Firestore
 */
export const onUserCreate = functions.auth.user().onCreate(async (user: admin.auth.UserRecord) => {
  try {
    console.log('Creating user document for:', user.uid);

    // Extract user information
    const userData: Omit<User, 'uid'> = {
      displayName: user.displayName || user.email?.split('@')[0] || 'User',
      email: user.email || '',
      role: 'user', // Default role
      locale: 'en', // Default locale
      createdAt: admin.firestore.Timestamp.now()
    };

    // Create user document in Firestore
    await db.collection('users').doc(user.uid).set(userData);

    console.log('User document created successfully for:', user.uid);
  } catch (error) {
    console.error('Error creating user document:', error);
    // Don't throw error to avoid blocking user creation
  }
});

/**
 * Cloud Function triggered when a user is deleted from Firebase Auth
 * Cleans up associated Firestore data
 */
export const onUserDelete = functions.auth.user().onDelete(async (user: admin.auth.UserRecord) => {
  try {
    console.log('Cleaning up data for deleted user:', user.uid);

    const batch = db.batch();

    // Delete user document
    const userDocRef = db.collection('users').doc(user.uid);
    batch.delete(userDocRef);

    // Delete user's completion log (subcollection)
    const completionLogs = await db.collection('users').doc(user.uid)
      .collection('completion_log').get();

    completionLogs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log('User data cleanup completed for:', user.uid);
  } catch (error) {
    console.error('Error cleaning up user data:', error);
    // Don't throw error to avoid blocking user deletion
  }
});
