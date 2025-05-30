import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

// Initialize Firebase Admin
admin.initializeApp();

// Import route handlers
import { habitsRouter } from './routes/habits';
import { bundlesRouter } from './routes/bundles';
import { usersRouter } from './routes/users';
import { completionsRouter } from './routes/completions';
import { graphqlHandler } from './graphql/server';

// Create Express app
const app = express();

// Security middleware
app.use(helmet());
app.use(cors({ origin: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API routes
app.use('/api/habits', habitsRouter);
app.use('/api/bundles', bundlesRouter);
app.use('/api/users', usersRouter);
app.use('/api/completions', completionsRouter);

// GraphQL endpoint
app.use('/graphql', graphqlHandler);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`
  });
});

// Error handling middleware
app.use((error: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('API Error:', error);
  res.status(error.status || 500).json({
    error: error.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
});

// Export the Express app as a Firebase Cloud Function
export const api = functions
  .runWith({
    memory: '512MB',
    timeoutSeconds: 60
  })
  .https.onRequest(app);

// Export individual functions for direct access
export { seedDatabaseFunction as seedDatabase } from './scripts/seed';
export { onUserCreate, onUserDelete } from './triggers/auth';
