import { Request, Response, NextFunction } from 'express';
import * as tasksService from './tasks.service';
import type { AuthRequest } from '../../middlewares/auth';
import { logger } from '../../utils/logger';

function uid(req: Request): string {
  return (req as AuthRequest).userId;
}

export async function listTasks(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const { status, search, sort } = req.query as Record<string, string>;
    
    logger.info(`Fetching tasks for user: ${userId}`, {
      module: 'TasksController',
      data: { status, search, sort },
    });
    
    const tasks = await tasksService.listTasks(userId, { status, search, sort });
    
    logger.success(`Retrieved ${tasks.length} tasks for user: ${userId}`, { module: 'TasksController' });
    res.json({ success: true, data: { tasks, count: tasks.length } });
  } catch (err) {
    logger.error('Failed to list tasks', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function createTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    console.log("#######################\n Received create task request with body:", req.body);
    const userId = uid(req);
    logger.info(`Creating task for user: ${userId}`, {
      module: 'TasksController',
      data: { title: req.body.title },
    });
    
    const task = await tasksService.createTask(userId, req.body);
    
    logger.success(`Task created: ${task._id} for user: ${userId}`, { module: 'TasksController' });
    res.status(201).json({ success: true, data: { task } });
  } catch (err) {
    logger.error('Failed to create task', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function getTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const taskId = String(req.params['id']);
    
    logger.debug(`Fetching task: ${taskId} for user: ${userId}`, { module: 'TasksController' });
    const task = await tasksService.getTaskById(userId, taskId);
    
    logger.success(`Task retrieved: ${taskId}`, { module: 'TasksController' });
    res.json({ success: true, data: { task } });
  } catch (err) {
    logger.error('Failed to get task', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function updateTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const taskId = String(req.params['id']);
    
    logger.info(`Updating task: ${taskId} for user: ${userId}`, {
      module: 'TasksController',
      data: req.body,
    });
    
    const task = await tasksService.updateTask(userId, taskId, req.body);
    
    logger.success(`Task updated: ${taskId}`, { module: 'TasksController' });
    res.json({ success: true, data: { task } });
  } catch (err) {
    logger.error('Failed to update task', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function patchTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const taskId = String(req.params['id']);
    
    logger.info(`Patching task: ${taskId} for user: ${userId}`, {
      module: 'TasksController',
      data: req.body,
    });
    
    const task = await tasksService.patchTask(userId, taskId, req.body);
    
    logger.success(`Task patched: ${taskId}`, { module: 'TasksController' });
    res.json({ success: true, data: { task } });
  } catch (err) {
    logger.error('Failed to patch task', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function deleteTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const taskId = String(req.params['id']);
    
    logger.info(`Deleting task: ${taskId} for user: ${userId}`, { module: 'TasksController' });
    await tasksService.deleteTask(userId, taskId);
    
    logger.success(`Task deleted: ${taskId}`, { module: 'TasksController' });
    res.status(204).send();
  } catch (err) {
    logger.error('Failed to delete task', { module: 'TasksController', error: err });
    next(err);
  }
}
