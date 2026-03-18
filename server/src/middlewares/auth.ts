import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';
import { ApiError } from '../utils/ApiError';
import { logger } from '../utils/logger';

export interface AuthRequest extends Request {
  userId: string;
}

export function authenticate(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  
  if (!authHeader?.startsWith('Bearer ')) {
    logger.warn('Authentication failed: Missing or malformed Authorization header', {
      module: 'Auth',
      data: { path: req.originalUrl, method: req.method },
    });
    return next(ApiError.unauthorized('Missing or malformed Authorization header'));
  }

  const token = authHeader.slice(7);
  try {
    const payload = verifyToken(token);
    (req as AuthRequest).userId = payload.userId;
    
    logger.debug(`User authenticated: ${payload.userId}`, {
      module: 'Auth',
      data: { path: req.originalUrl, method: req.method },
    });
    
    next();
  } catch (err) {
    logger.warn('Authentication failed: Invalid or expired token', {
      module: 'Auth',
      data: { path: req.originalUrl, method: req.method },
      error: err,
    });
    next(ApiError.unauthorized('Invalid or expired token'));
  }
}
