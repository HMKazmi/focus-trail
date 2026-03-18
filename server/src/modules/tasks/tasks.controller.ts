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
    const { status, priority, search, sort, dueBefore, dueAfter } = req.query as Record<string, string>;
    
    logger.info(`Fetching tasks for user: ${userId}`, {
      module: 'TasksController',
      data: { status, priority, search, sort },
    });
    
    const tasks = await tasksService.listTasks(userId, { status, priority, search, sort, dueBefore, dueAfter });
    
    logger.success(`Retrieved ${tasks.length} tasks for user: ${userId}`, { module: 'TasksController' });
    res.json({ success: true, data: { tasks, count: tasks.length } });
  } catch (err) {
    logger.error('Failed to list tasks', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function createTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    logger.info(`Creating task for user: ${userId}`, {
      module: 'TasksController',
      data: { title: req.body.title },
    });
    
    // Define Task type or import it from your models
    type Task = { _id: string; [key: string]: any };

    const rawTask = await tasksService.createTask(userId, req.body);
    const task: Task = { ...rawTask.toObject(), _id: rawTask._id.toString() };
    
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
    
    logger.info(`Permanently deleting task: ${taskId} for user: ${userId}`, { module: 'TasksController' });
    await tasksService.deleteTask(userId, taskId);
    
    logger.success(`Task permanently deleted: ${taskId}`, { module: 'TasksController' });
    res.status(204).send();
  } catch (err) {
    logger.error('Failed to delete task', { module: 'TasksController', error: err });
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════
// TRASH BIN
// ═══════════════════════════════════════════════════════════

export async function trashTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const taskId = String(req.params['id']);
    
    logger.info(`Moving task to trash: ${taskId} for user: ${userId}`, { module: 'TasksController' });
    const task = await tasksService.trashTask(userId, taskId);
    
    logger.success(`Task moved to trash: ${taskId}`, { module: 'TasksController' });
    res.json({ success: true, data: { task } });
  } catch (err) {
    logger.error('Failed to trash task', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function restoreTask(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const taskId = String(req.params['id']);
    
    logger.info(`Restoring task from trash: ${taskId} for user: ${userId}`, { module: 'TasksController' });
    const task = await tasksService.restoreTask(userId, taskId);
    
    logger.success(`Task restored: ${taskId}`, { module: 'TasksController' });
    res.json({ success: true, data: { task } });
  } catch (err) {
    logger.error('Failed to restore task', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function listTrash(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    
    logger.info(`Fetching trashed tasks for user: ${userId}`, { module: 'TasksController' });
    const tasks = await tasksService.listTrash(userId);
    
    logger.success(`Retrieved ${tasks.length} trashed tasks`, { module: 'TasksController' });
    res.json({ success: true, data: { tasks, count: tasks.length } });
  } catch (err) {
    logger.error('Failed to list trash', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function emptyTrash(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    
    logger.info(`Emptying trash for user: ${userId}`, { module: 'TasksController' });
    const deletedCount = await tasksService.emptyTrash(userId);
    
    logger.success(`Trash emptied: ${deletedCount} tasks deleted`, { module: 'TasksController' });
    res.json({ success: true, data: { deletedCount } });
  } catch (err) {
    logger.error('Failed to empty trash', { module: 'TasksController', error: err });
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════
// REMINDERS & NOTIFICATIONS
// ═══════════════════════════════════════════════════════════

export async function getUpcomingReminders(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const hoursAhead = parseInt(req.query['hours'] as string) || 24;
    
    logger.info(`Fetching upcoming reminders for user: ${userId}`, {
      module: 'TasksController',
      data: { hoursAhead },
    });
    
    const tasks = await tasksService.getUpcomingReminders(userId, hoursAhead);
    
    logger.success(`Retrieved ${tasks.length} upcoming reminders`, { module: 'TasksController' });
    res.json({ success: true, data: { tasks, count: tasks.length } });
  } catch (err) {
    logger.error('Failed to get reminders', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function getDueSoonTasks(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const hoursAhead = parseInt(req.query['hours'] as string) || 24;
    
    logger.info(`Fetching tasks due soon for user: ${userId}`, {
      module: 'TasksController',
      data: { hoursAhead },
    });
    
    const tasks = await tasksService.getDueSoonTasks(userId, hoursAhead);
    
    logger.success(`Retrieved ${tasks.length} tasks due soon`, { module: 'TasksController' });
    res.json({ success: true, data: { tasks, count: tasks.length } });
  } catch (err) {
    logger.error('Failed to get tasks due soon', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function getOverdueTasks(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    
    logger.info(`Fetching overdue tasks for user: ${userId}`, { module: 'TasksController' });
    const tasks = await tasksService.getOverdueTasks(userId);
    
    logger.success(`Retrieved ${tasks.length} overdue tasks`, { module: 'TasksController' });
    res.json({ success: true, data: { tasks, count: tasks.length } });
  } catch (err) {
    logger.error('Failed to get overdue tasks', { module: 'TasksController', error: err });
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════
// DASHBOARD & ANALYTICS
// ═══════════════════════════════════════════════════════════

export async function getDashboardStats(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    
    logger.info(`Fetching dashboard stats for user: ${userId}`, { module: 'TasksController' });
    const stats = await tasksService.getDashboardStats(userId);
    
    logger.success(`Dashboard stats retrieved for user: ${userId}`, { module: 'TasksController' });
    res.json({ success: true, data: { stats } });
  } catch (err) {
    logger.error('Failed to get dashboard stats', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function getCompletionTrend(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const period = (req.query['period'] as 'day' | 'week' | 'month') || 'week';
    
    logger.info(`Fetching completion trend for user: ${userId}`, {
      module: 'TasksController',
      data: { period },
    });
    
    const trend = await tasksService.getCompletionTrend(userId, period);
    
    logger.success(`Completion trend retrieved: ${trend.length} data points`, { module: 'TasksController' });
    res.json({ success: true, data: { trend } });
  } catch (err) {
    logger.error('Failed to get completion trend', { module: 'TasksController', error: err });
    next(err);
  }
}

export async function getCreatedVsCompletedTrend(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const days = parseInt(req.query['days'] as string) || 7;
    
    logger.info(`Fetching created vs completed trend for user: ${userId}`, {
      module: 'TasksController',
      data: { days },
    });
    
    const trend = await tasksService.getCreatedVsCompletedTrend(userId, days);
    
    logger.success(`Created vs completed trend retrieved: ${trend.length} data points`, { module: 'TasksController' });
    res.json({ success: true, data: { trend } });
  } catch (err) {
    logger.error('Failed to get created vs completed trend', { module: 'TasksController', error: err });
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════
// EXPORT
// ═══════════════════════════════════════════════════════════

export async function exportTasks(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = uid(req);
    const format = (req.query['format'] as 'json' | 'csv') || 'json';
    
    logger.info(`Exporting tasks for user: ${userId}`, {
      module: 'TasksController',
      data: { format },
    });
    
    const data = await tasksService.exportTasks(userId, format);
    
    if (format === 'csv') {
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="tasks-export-${new Date().toISOString().split('T')[0]}.csv"`);
      res.send(data);
    } else {
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename="tasks-export-${new Date().toISOString().split('T')[0]}.json"`);
      res.json({ success: true, data: { tasks: data, exportedAt: new Date().toISOString() } });
    }
    
    logger.success(`Tasks exported as ${format}`, { module: 'TasksController' });
  } catch (err) {
    logger.error('Failed to export tasks', { module: 'TasksController', error: err });
    next(err);
  }
}
