import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';

// Extend Express Request to include user info
declare global {
  namespace Express {
    interface Request {
      user?: {
        uid: string;
        email?: string;
        role?: string;
      };
    }
  }
}

/**
 * Middleware to verify Firebase Auth token
 */
export const authenticateUser = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing or invalid authorization header'
      });
      return;
    }

    const token = authHeader.split('Bearer ')[1];
    
    if (!token) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing authentication token'
      });
      return;
    }

    // Verify the token with Firebase Admin
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Get additional user info from Firestore if needed
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(decodedToken.uid)
      .get();

    // Attach user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      role: userDoc.exists ? userDoc.data()?.role : 'user'
    };

    next();
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid authentication token'
    });
  }
};

/**
 * Middleware to check if user has admin/coach role
 */
export const requireRole = (requiredRole: string) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required'
      });
      return;
    }

    if (req.user.role !== requiredRole && req.user.role !== 'coach') {
      res.status(403).json({
        error: 'Forbidden',
        message: `Role '${requiredRole}' required`
      });
      return;
    }

    next();
  };
};

/**
 * Middleware to check if user can access resource (owns it or is coach)
 */
export const requireOwnershipOrRole = (userIdParam: string = 'userId') => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required'
      });
      return;
    }

    const targetUserId = req.params[userIdParam];
    
    // Allow if user owns the resource or has coach role
    if (req.user.uid === targetUserId || req.user.role === 'coach') {
      next();
      return;
    }

    res.status(403).json({
      error: 'Forbidden',
      message: 'Access denied'
    });
  };
};
