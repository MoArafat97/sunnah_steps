import * as admin from 'firebase-admin';
import { AuthenticationError, ForbiddenError, UserInputError } from 'apollo-server-express';
import { Habit, Bundle, User, CompletionLog } from '../models';

const db = admin.firestore();

// Helper function to convert Firestore timestamp to ISO string
const timestampToISO = (timestamp: admin.firestore.Timestamp): string => {
  return timestamp.toDate().toISOString();
};

// Helper function to create cursor from document
const createCursor = (doc: admin.firestore.DocumentSnapshot): string => {
  return Buffer.from(doc.id).toString('base64');
};

// Helper function to decode cursor
const decodeCursor = (cursor: string): string => {
  return Buffer.from(cursor, 'base64').toString();
};

export const resolvers = {
  // Scalar resolvers
  DateTime: {
    serialize: (value: any) => {
      if (value instanceof admin.firestore.Timestamp) {
        return timestampToISO(value);
      }
      return value instanceof Date ? value.toISOString() : value;
    },
    parseValue: (value: any) => new Date(value),
    parseLiteral: (ast: any) => new Date(ast.value),
  },

  // Query resolvers
  Query: {
    // Habits queries
    habits: async (
      _: any,
      { filter, first = 50, after }: { filter?: any; first?: number; after?: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      let query = db.collection('habits').orderBy('priority', 'desc');

      // Apply filters
      if (filter?.category) {
        query = query.where('category', '==', filter.category);
      }

      if (filter?.tags && filter.tags.length > 0) {
        const tagsToFilter = filter.tags.slice(0, 10); // Firestore limit
        query = query.where('tags', 'array-contains-any', tagsToFilter);
      }

      // Apply cursor pagination
      if (after) {
        const startAfterDoc = await db.collection('habits').doc(decodeCursor(after)).get();
        if (startAfterDoc.exists) {
          query = query.startAfter(startAfterDoc);
        }
      }

      query = query.limit(first + 1); // Get one extra to check if there's more

      const snapshot = await query.get();
      const habits: Habit[] = [];
      const docs = snapshot.docs;

      // Process results
      const hasNextPage = docs.length > first;
      const habitsToReturn = hasNextPage ? docs.slice(0, -1) : docs;

      habitsToReturn.forEach(doc => {
        habits.push({
          id: doc.id,
          ...doc.data(),
          createdAt: doc.data().createdAt
        } as Habit);
      });

      // Get total count
      const totalSnapshot = await db.collection('habits').count().get();
      const totalCount = totalSnapshot.data().count;

      return {
        edges: habits.map((habit, index) => ({
          node: habit,
          cursor: createCursor(habitsToReturn[index])
        })),
        pageInfo: {
          hasNextPage,
          hasPreviousPage: !!after,
          startCursor: habits.length > 0 ? createCursor(habitsToReturn[0]) : null,
          endCursor: habits.length > 0 ? createCursor(habitsToReturn[habitsToReturn.length - 1]) : null,
        },
        totalCount
      };
    },

    habit: async (
      _: any,
      { id }: { id: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      const doc = await db.collection('habits').doc(id).get();
      if (!doc.exists) return null;

      return {
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data()?.createdAt
      } as Habit;
    },

    searchHabits: async (
      _: any,
      { query: searchQuery, limit = 20 }: { query: string; limit?: number },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      if (!searchQuery || searchQuery.length < 2) {
        throw new UserInputError('Search query must be at least 2 characters');
      }

      const snapshot = await db.collection('habits')
        .orderBy('priority', 'desc')
        .limit(limit)
        .get();

      const searchTerm = searchQuery.toLowerCase();
      const habits: Habit[] = [];

      snapshot.forEach(doc => {
        const data = doc.data() as Habit;
        const title = data.title.toLowerCase();
        const benefits = data.benefits.toLowerCase();
        const tags = data.tags.map(tag => tag.toLowerCase());

        if (title.includes(searchTerm) ||
            benefits.includes(searchTerm) ||
            tags.some(tag => tag.includes(searchTerm))) {
          habits.push({
            ...data,
            id: doc.id,
            createdAt: data.createdAt
          });
        }
      });

      return habits;
    },

    // Bundles queries
    bundles: async (
      _: any,
      { first = 20, after }: { first?: number; after?: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      let query = db.collection('bundles').orderBy('displayOrder', 'asc');

      if (after) {
        const startAfterDoc = await db.collection('bundles').doc(decodeCursor(after)).get();
        if (startAfterDoc.exists) {
          query = query.startAfter(startAfterDoc);
        }
      }

      query = query.limit(first + 1);

      const snapshot = await query.get();
      const bundles: Bundle[] = [];
      const docs = snapshot.docs;

      const hasNextPage = docs.length > first;
      const bundlesToReturn = hasNextPage ? docs.slice(0, -1) : docs;

      bundlesToReturn.forEach(doc => {
        bundles.push({
          id: doc.id,
          ...doc.data(),
          createdAt: doc.data().createdAt
        } as Bundle);
      });

      const totalSnapshot = await db.collection('bundles').count().get();
      const totalCount = totalSnapshot.data().count;

      return {
        edges: bundles.map((bundle, index) => ({
          node: bundle,
          cursor: createCursor(bundlesToReturn[index])
        })),
        pageInfo: {
          hasNextPage,
          hasPreviousPage: !!after,
          startCursor: bundles.length > 0 ? createCursor(bundlesToReturn[0]) : null,
          endCursor: bundles.length > 0 ? createCursor(bundlesToReturn[bundlesToReturn.length - 1]) : null,
        },
        totalCount
      };
    },

    bundle: async (
      _: any,
      { id }: { id: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      const doc = await db.collection('bundles').doc(id).get();
      if (!doc.exists) return null;

      return {
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data()?.createdAt
      } as Bundle;
    },

    bundleHabits: async (
      _: any,
      { bundleId }: { bundleId: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      const bundleDoc = await db.collection('bundles').doc(bundleId).get();
      if (!bundleDoc.exists) {
        throw new UserInputError('Bundle not found');
      }

      const bundle = bundleDoc.data() as Bundle;
      if (!bundle.habitIds || bundle.habitIds.length === 0) {
        return [];
      }

      const habits: Habit[] = [];

      // Process in chunks of 10 (Firestore 'in' query limit)
      for (let i = 0; i < bundle.habitIds.length; i += 10) {
        const chunk = bundle.habitIds.slice(i, i + 10);
        const snapshot = await db.collection('habits')
          .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
          .get();

        snapshot.forEach(doc => {
          habits.push({
            id: doc.id,
            ...doc.data(),
            createdAt: doc.data().createdAt
          } as Habit);
        });
      }

      // Sort habits by their order in the bundle
      habits.sort((a, b) => {
        const indexA = bundle.habitIds.indexOf(a.id);
        const indexB = bundle.habitIds.indexOf(b.id);
        return indexA - indexB;
      });

      return habits;
    },

    // User queries
    user: async (
      _: any,
      { userId }: { userId: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      // Check if user is requesting their own data or has coach role
      if (user.uid !== userId && user.role !== 'coach') {
        throw new ForbiddenError('Access denied');
      }

      const doc = await db.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return {
        uid: doc.id,
        ...doc.data(),
        createdAt: doc.data()?.createdAt
      } as User;
    },

    me: async (
      _: any,
      __: any,
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      const doc = await db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return {
        uid: doc.id,
        ...doc.data(),
        createdAt: doc.data()?.createdAt
      } as User;
    },

    // Completions queries
    completions: async (
      _: any,
      {
        userId,
        habitId,
        startDate,
        endDate,
        first = 50,
        after
      }: {
        userId: string;
        habitId?: string;
        startDate?: string;
        endDate?: string;
        first?: number;
        after?: string;
      },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      // Check if user is requesting their own data or has coach role
      if (user.uid !== userId && user.role !== 'coach') {
        throw new ForbiddenError('Access denied');
      }

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

      // Apply cursor pagination
      if (after) {
        const startAfterDoc = await db.collection('users').doc(userId)
          .collection('completion_log').doc(decodeCursor(after)).get();
        if (startAfterDoc.exists) {
          query = query.startAfter(startAfterDoc);
        }
      }

      query = query.limit(first + 1);

      const snapshot = await query.get();
      const completions: CompletionLog[] = [];
      const docs = snapshot.docs;

      const hasNextPage = docs.length > first;
      const completionsToReturn = hasNextPage ? docs.slice(0, -1) : docs;

      completionsToReturn.forEach(doc => {
        completions.push({
          id: doc.id,
          ...doc.data(),
          completedAt: doc.data().completedAt
        } as CompletionLog);
      });

      // Get total count
      const totalSnapshot = await db.collection('users').doc(userId)
        .collection('completion_log').count().get();
      const totalCount = totalSnapshot.data().count;

      return {
        edges: completions.map((completion, index) => ({
          node: completion,
          cursor: createCursor(completionsToReturn[index])
        })),
        pageInfo: {
          hasNextPage,
          hasPreviousPage: !!after,
          startCursor: completions.length > 0 ? createCursor(completionsToReturn[0]) : null,
          endCursor: completions.length > 0 ? createCursor(completionsToReturn[completionsToReturn.length - 1]) : null,
        },
        totalCount
      };
    },

    completionStats: async (
      _: any,
      { userId }: { userId: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      // Check if user is requesting their own data or has coach role
      if (user.uid !== userId && user.role !== 'coach') {
        throw new ForbiddenError('Access denied');
      }

      const now = new Date();
      const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

      // Get all completions
      const allCompletionsSnapshot = await db.collection('users').doc(userId)
        .collection('completion_log')
        .orderBy('completedAt', 'desc')
        .get();

      const totalCompletions = allCompletionsSnapshot.size;

      // Get completions this week
      const weekCompletionsSnapshot = await db.collection('users').doc(userId)
        .collection('completion_log')
        .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(startOfWeek))
        .get();

      const completionsThisWeek = weekCompletionsSnapshot.size;

      // Get completions this month
      const monthCompletionsSnapshot = await db.collection('users').doc(userId)
        .collection('completion_log')
        .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(startOfMonth))
        .get();

      const completionsThisMonth = monthCompletionsSnapshot.size;

      // Calculate streaks and category stats (simplified implementation)
      const currentStreak = 0; // TODO: Implement streak calculation
      const longestStreak = 0; // TODO: Implement streak calculation

      // Get recent completions (last 10)
      const recentCompletionsSnapshot = await db.collection('users').doc(userId)
        .collection('completion_log')
        .orderBy('completedAt', 'desc')
        .limit(10)
        .get();

      const recentCompletions: CompletionLog[] = [];
      recentCompletionsSnapshot.forEach(doc => {
        recentCompletions.push({
          id: doc.id,
          ...doc.data(),
          completedAt: doc.data().completedAt
        } as CompletionLog);
      });

      // Category stats (simplified)
      const completionsByCategory = [
        { category: 'daily', count: 0, percentage: 0 },
        { category: 'weekly', count: 0, percentage: 0 },
        { category: 'occasional', count: 0, percentage: 0 }
      ];

      return {
        totalCompletions,
        completionsThisWeek,
        completionsThisMonth,
        currentStreak,
        longestStreak,
        completionsByCategory,
        recentCompletions
      };
    },
  },

  // Mutation resolvers
  Mutation: {
    // User mutations
    createUser: async (
      _: any,
      { input }: { input: any },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      const { displayName, email, role = 'user', locale = 'en' } = input;

      if (!displayName || !email) {
        throw new UserInputError('displayName and email are required');
      }

      // Use the authenticated user's UID
      const uid = user.uid;

      // Check if user document already exists
      const existingDoc = await db.collection('users').doc(uid).get();
      if (existingDoc.exists) {
        throw new UserInputError('User document already exists');
      }

      const userData = {
        displayName,
        email,
        role,
        locale,
        createdAt: admin.firestore.Timestamp.now()
      };

      await db.collection('users').doc(uid).set(userData);

      return {
        uid,
        ...userData
      };
    },

    updateUser: async (
      _: any,
      { userId, input }: { userId: string; input: any },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      // Check if user is updating their own data or has coach role
      if (user.uid !== userId && user.role !== 'coach') {
        throw new ForbiddenError('Access denied');
      }

      const { displayName, locale } = input;

      const updateData: any = {};
      if (displayName) updateData.displayName = displayName;
      if (locale) updateData.locale = locale;

      if (Object.keys(updateData).length === 0) {
        throw new UserInputError('No valid fields to update');
      }

      // Check if user exists
      const doc = await db.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw new UserInputError('User not found');
      }

      await db.collection('users').doc(userId).update(updateData);

      const updatedDoc = await db.collection('users').doc(userId).get();
      return {
        uid: updatedDoc.id,
        ...updatedDoc.data(),
        createdAt: updatedDoc.data()?.createdAt
      } as User;
    },

    deleteUser: async (
      _: any,
      { userId }: { userId: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      // Check if user is deleting their own data or has coach role
      if (user.uid !== userId && user.role !== 'coach') {
        throw new ForbiddenError('Access denied');
      }

      // Check if user exists
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw new UserInputError('User not found');
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
      return true;
    },

    // Completion mutations
    createCompletion: async (
      _: any,
      { input }: { input: any },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      const { habitId, source = 'api', note } = input;
      const userId = user.uid;

      if (!habitId) {
        throw new UserInputError('habitId is required');
      }

      if (!['checklist', 'api'].includes(source)) {
        throw new UserInputError('source must be either "checklist" or "api"');
      }

      // Verify habit exists
      const habitDoc = await db.collection('habits').doc(habitId).get();
      if (!habitDoc.exists) {
        throw new UserInputError('Habit not found');
      }

      const completionData = {
        habitId,
        completedAt: admin.firestore.Timestamp.now(),
        source,
        ...(note && { note })
      };

      const docRef = await db.collection('users').doc(userId)
        .collection('completion_log').add(completionData);

      return {
        id: docRef.id,
        ...completionData
      };
    },

    deleteCompletion: async (
      _: any,
      { id }: { id: string },
      { user }: { user: admin.auth.DecodedIdToken }
    ) => {
      if (!user) throw new AuthenticationError('Authentication required');

      const userId = user.uid;

      // Check if completion exists and belongs to user
      const doc = await db.collection('users').doc(userId)
        .collection('completion_log').doc(id).get();

      if (!doc.exists) {
        throw new UserInputError('Completion not found');
      }

      await db.collection('users').doc(userId)
        .collection('completion_log').doc(id).delete();

      return true;
    },
  },

  // Field resolvers
  Bundle: {
    habits: async (parent: Bundle) => {
      if (!parent.habitIds || parent.habitIds.length === 0) {
        return [];
      }

      const habits: Habit[] = [];

      // Process in chunks of 10 (Firestore 'in' query limit)
      for (let i = 0; i < parent.habitIds.length; i += 10) {
        const chunk = parent.habitIds.slice(i, i + 10);
        const snapshot = await db.collection('habits')
          .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
          .get();

        snapshot.forEach(doc => {
          habits.push({
            id: doc.id,
            ...doc.data(),
            createdAt: doc.data().createdAt
          } as Habit);
        });
      }

      // Sort habits by their order in the bundle
      habits.sort((a, b) => {
        const indexA = parent.habitIds.indexOf(a.id);
        const indexB = parent.habitIds.indexOf(b.id);
        return indexA - indexB;
      });

      return habits;
    },
  },

  CompletionLog: {
    habit: async (parent: CompletionLog) => {
      const doc = await db.collection('habits').doc(parent.habitId).get();
      if (!doc.exists) return null;

      return {
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data()?.createdAt
      } as Habit;
    },
  },
};
