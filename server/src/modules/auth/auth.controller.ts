import { Request, Response, NextFunction } from 'express';
import * as authService from './auth.service';
import type { AuthRequest } from '../../middlewares/auth';
import { logger } from '../../utils/logger';

export async function register(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    logger.info('Registration attempt', {
      module: 'AuthController',
      data: { email: req.body.email, name: req.body.name },
    });
    
    const result = await authService.registerUser(req.body);
    
    logger.success(`User registered successfully: ${req.body.email}`, { module: 'AuthController' });
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    logger.error('Registration failed', {
      module: 'AuthController',
      data: { email: req.body.email },
      error: err,
    });
    next(err);
  }
}

export async function login(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    logger.info('Login attempt', {
      module: 'AuthController',
      data: { email: req.body.email },
    });
    
    const result = await authService.loginUser(req.body);
    
    logger.success(`User logged in successfully: ${req.body.email}`, { module: 'AuthController' });
    res.json({ success: true, data: result });
  } catch (err) {
    logger.error('Login failed', {
      module: 'AuthController',
      data: { email: req.body.email },
      error: err,
    });
    next(err);
  }
}

export async function me(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = (req as AuthRequest).userId;
    logger.debug(`Fetching user profile: ${userId}`, { module: 'AuthController' });
    
    const user = await authService.getMe(userId);
    
    logger.success(`User profile retrieved: ${userId}`, { module: 'AuthController' });
    res.json({ success: true, data: { user } });
  } catch (err) {
    logger.error('Failed to fetch user profile', {
      module: 'AuthController',
      error: err,
    });
    next(err);
  }
}
