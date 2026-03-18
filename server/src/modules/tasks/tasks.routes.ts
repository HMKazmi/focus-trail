import { Router } from 'express';
import { authenticate } from '../../middlewares/auth';
import { validate } from '../../middlewares/validate';
import { createTaskSchema, updateTaskSchema, patchTaskSchema } from './tasks.schemas';
import * as tasksController from './tasks.controller';

const router = Router();

router.use(authenticate);

router.get('/', tasksController.listTasks);
router.post('/', validate(createTaskSchema), tasksController.createTask);
router.get('/:id', tasksController.getTask);
router.put('/:id', validate(updateTaskSchema), tasksController.updateTask);
router.patch('/:id', validate(patchTaskSchema), tasksController.patchTask);
router.delete('/:id', tasksController.deleteTask);

export default router;
