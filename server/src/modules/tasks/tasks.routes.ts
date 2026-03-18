import { Router } from 'express';
import { authenticate } from '../../middlewares/auth';
import { validate } from '../../middlewares/validate';
import { createTaskSchema, updateTaskSchema, patchTaskSchema } from './tasks.schemas';
import * as tasksController from './tasks.controller';

const router = Router();

router.use(authenticate);

// ── Dashboard & Analytics ─────────────────────────────────────
router.get('/stats', tasksController.getDashboardStats);
router.get('/analytics/completion', tasksController.getCompletionTrend);
router.get('/analytics/trend', tasksController.getCreatedVsCompletedTrend);

// ── Trash Bin ─────────────────────────────────────────────────
router.get('/trash', tasksController.listTrash);
router.delete('/trash', tasksController.emptyTrash);
router.patch('/:id/trash', tasksController.trashTask);
router.patch('/:id/restore', tasksController.restoreTask);

// ── Reminders & Notifications ─────────────────────────────────
router.get('/reminders', tasksController.getUpcomingReminders);
router.get('/due-soon', tasksController.getDueSoonTasks);
router.get('/overdue', tasksController.getOverdueTasks);

// ── Export ────────────────────────────────────────────────────
router.get('/export', tasksController.exportTasks);

// ── CRUD Operations ───────────────────────────────────────────
router.get('/', tasksController.listTasks);
router.post('/', validate(createTaskSchema), tasksController.createTask);
router.get('/:id', tasksController.getTask);
router.put('/:id', validate(updateTaskSchema), tasksController.updateTask);
router.patch('/:id', validate(patchTaskSchema), tasksController.patchTask);
router.delete('/:id', tasksController.deleteTask);

export default router;
