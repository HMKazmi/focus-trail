import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/ApiError';
import { logger } from '../utils/logger';

interface ErrorResponse {
  success: false;
  error: {
    message: string;
    statusCode: number;
  };
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof ApiError) {
    logger.warn(`API Error: ${err.message}`, {
      module: 'ErrorHandler',
      data: {
        statusCode: err.statusCode,
        path: req.originalUrl,
        method: req.method,
      },
    });
    
    const body: ErrorResponse = {
      success: false,
      error: { message: err.message, statusCode: err.statusCode },
    };
    res.status(err.statusCode).json(body);
    return;
  }

  // Mongoose duplicate key
  if ((err as NodeJS.ErrnoException).name === 'MongoServerError' && 'code' in err && (err as NodeJS.ErrnoException & { code: number }).code === 11000) {
    logger.warn('Duplicate key error', {
      module: 'ErrorHandler',
      data: { path: req.originalUrl, method: req.method },
      error: err,
    });
    
    res.status(409).json({
      success: false,
      error: { message: 'A resource with that value already exists', statusCode: 409 },
    });
    return;
  }

  logger.error('Unhandled error occurred', {
    module: 'ErrorHandler',
    data: {
      path: req.originalUrl,
      method: req.method,
      body: req.body,
    },
    error: err,
  });
  
  res.status(500).json({
    success: false,
    error: { message: 'Internal server error', statusCode: 500 },
  });
}
