import * as admin from 'firebase-admin';

// Initialize Firebase Admin for testing
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'test-project',
    credential: admin.credential.applicationDefault()
  });
}

// Mock Firestore for testing
jest.mock('firebase-admin/firestore', () => {
  const mockFirestore = {
    collection: jest.fn(),
    doc: jest.fn(),
    batch: jest.fn(),
    Timestamp: {
      now: jest.fn(() => ({ toDate: () => new Date() })),
      fromDate: jest.fn((date: Date) => ({ toDate: () => date }))
    },
    FieldPath: {
      documentId: jest.fn(() => '__name__')
    }
  };

  return {
    getFirestore: () => mockFirestore,
    Timestamp: mockFirestore.Timestamp,
    FieldPath: mockFirestore.FieldPath
  };
});

// Mock Firebase Auth for testing
jest.mock('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: jest.fn(),
    deleteUser: jest.fn()
  })
}));

// Global test timeout
jest.setTimeout(30000);
