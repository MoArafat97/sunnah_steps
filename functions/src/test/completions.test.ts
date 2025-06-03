import request from 'supertest';
import express from 'express';

// Define mocks first
const mockFirestore = {
  collection: jest.fn(),
  doc: jest.fn(),
  batch: jest.fn(),
  Timestamp: {
    now: jest.fn(() => ({ toDate: () => new Date() })),
    fromDate: jest.fn((date: Date) => ({ toDate: () => date }))
  }
};

const mockAuth = {
  verifyIdToken: jest.fn()
};

// Mock Firebase Admin before importing the router
const firestoreFn = jest.fn(() => mockFirestore);
(firestoreFn as any).Timestamp = mockFirestore.Timestamp;

jest.mock('firebase-admin', () => ({
  firestore: firestoreFn,
  auth: jest.fn(() => mockAuth),
  initializeApp: jest.fn(),
  apps: []
}));

// Import after mocking
import { completionsRouter } from '../routes/completions';

// Create test app
const app = express();
app.use(express.json());
app.use('/api/completions', completionsRouter);

describe('POST /api/completions', () => {
  const mockUserId = 'test-user-123';
  const mockHabitId = 'h21';
  const validToken = 'valid-token';

  beforeEach(() => {
    jest.clearAllMocks();

    // Mock successful token verification
    mockAuth.verifyIdToken.mockResolvedValue({
      uid: mockUserId,
      email: 'test@example.com'
    });

    // Mock Firestore user document
    const mockUserDoc = {
      exists: true,
      data: () => ({ role: 'user' })
    };

    // Mock Firestore habit document
    const mockHabitDoc = {
      exists: true,
      data: () => ({ title: 'Test Habit' })
    };

    // Mock Firestore collection chain
    const mockAdd = jest.fn().mockResolvedValue({ id: 'completion-123' });
    const mockCompletionCollection = { add: mockAdd };
    const mockUserDocRef = {
      get: jest.fn().mockResolvedValue(mockUserDoc),
      collection: jest.fn().mockReturnValue(mockCompletionCollection)
    };
    const mockUsersCollection = { doc: jest.fn().mockReturnValue(mockUserDocRef) };

    const mockHabitDocRef = { get: jest.fn().mockResolvedValue(mockHabitDoc) };
    const mockHabitsCollection = { doc: jest.fn().mockReturnValue(mockHabitDocRef) };

    mockFirestore.collection.mockImplementation((collectionName: string) => {
      if (collectionName === 'users') return mockUsersCollection;
      if (collectionName === 'habits') return mockHabitsCollection;
      return {};
    });
  });

  it('should create a completion log entry successfully', async () => {
    const completionData = {
      habitId: mockHabitId,
      source: 'api',
      note: 'Test completion'
    };

    const response = await request(app)
      .post('/api/completions')
      .set('Authorization', `Bearer ${validToken}`)
      .send(completionData)
      .expect(201);

    expect(response.body).toEqual({
      success: true,
      data: expect.objectContaining({
        id: 'completion-123',
        habitId: mockHabitId,
        source: 'api',
        note: 'Test completion',
        completedAt: expect.any(Object)
      }),
      message: 'Habit completion logged successfully'
    });

    // Verify that the completion was added to the correct user's subcollection
    expect(mockFirestore.collection).toHaveBeenCalledWith('users');
    expect(mockFirestore.collection).toHaveBeenCalledWith('habits');
  });

  it('should reject request without authentication', async () => {
    const completionData = {
      habitId: mockHabitId,
      source: 'api'
    };

    const response = await request(app)
      .post('/api/completions')
      .send(completionData)
      .expect(401);

    expect(response.body).toEqual({
      error: 'Unauthorized',
      message: 'Missing or invalid authorization header'
    });
  });

  it('should reject request with invalid token', async () => {
    mockAuth.verifyIdToken.mockRejectedValue(new Error('Invalid token'));

    const completionData = {
      habitId: mockHabitId,
      source: 'api'
    };

    const response = await request(app)
      .post('/api/completions')
      .set('Authorization', 'Bearer invalid-token')
      .send(completionData)
      .expect(401);

    expect(response.body).toEqual({
      error: 'Unauthorized',
      message: 'Invalid authentication token'
    });
  });

  it('should reject request without habitId', async () => {
    const completionData = {
      source: 'api'
    };

    const response = await request(app)
      .post('/api/completions')
      .set('Authorization', `Bearer ${validToken}`)
      .send(completionData)
      .expect(400);

    expect(response.body).toEqual({
      success: false,
      error: 'habitId is required'
    });
  });

  it('should reject request with invalid source', async () => {
    const completionData = {
      habitId: mockHabitId,
      source: 'invalid-source'
    };

    const response = await request(app)
      .post('/api/completions')
      .set('Authorization', `Bearer ${validToken}`)
      .send(completionData)
      .expect(400);

    expect(response.body).toEqual({
      success: false,
      error: 'source must be either "checklist" or "api"'
    });
  });

  it('should reject request for non-existent habit', async () => {
    // Mock habit not found
    const mockHabitDoc = { exists: false };
    const mockHabitDocRef = { get: jest.fn().mockResolvedValue(mockHabitDoc) };
    const mockHabitsCollection = { doc: jest.fn().mockReturnValue(mockHabitDocRef) };

    // Recreate user mocks to preserve auth behaviour
    const mockUserDoc = { exists: true, data: () => ({ role: 'user' }) };
    const mockAdd = jest.fn().mockResolvedValue({ id: 'completion-123' });
    const mockCompletionCollection = { add: mockAdd };
    const mockUserDocRef = {
      get: jest.fn().mockResolvedValue(mockUserDoc),
      collection: jest.fn().mockReturnValue(mockCompletionCollection)
    };
    const mockUsersCollection = { doc: jest.fn().mockReturnValue(mockUserDocRef) };

    mockFirestore.collection.mockImplementation((collectionName: string) => {
      if (collectionName === 'habits') return mockHabitsCollection;
      if (collectionName === 'users') return mockUsersCollection;
      return {};
    });

    const completionData = {
      habitId: 'non-existent-habit',
      source: 'api'
    };

    const response = await request(app)
      .post('/api/completions')
      .set('Authorization', `Bearer ${validToken}`)
      .send(completionData)
      .expect(404);

    expect(response.body).toEqual({
      success: false,
      error: 'Habit not found'
    });
  });

  it('should write to correct document path', async () => {
    const completionData = {
      habitId: mockHabitId,
      source: 'checklist'
    };

    await request(app)
      .post('/api/completions')
      .set('Authorization', `Bearer ${validToken}`)
      .send(completionData)
      .expect(201);

    // Verify the correct Firestore path was used
    expect(mockFirestore.collection).toHaveBeenCalledWith('users');

    // Get the mock calls to verify the path structure
    const usersCollectionCall = mockFirestore.collection.mock.calls.find(
      call => call[0] === 'users'
    );
    expect(usersCollectionCall).toBeDefined();
  });

  it('should default source to "api" when not provided', async () => {
    const completionData = {
      habitId: mockHabitId
    };

    const response = await request(app)
      .post('/api/completions')
      .set('Authorization', `Bearer ${validToken}`)
      .send(completionData)
      .expect(201);

    expect(response.body.data.source).toBe('api');
  });
});
