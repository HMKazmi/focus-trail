import { z } from 'zod';

const taskStatusEnum = z.enum(['todo', 'in_progress', 'done']);

export const createTaskSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  status: taskStatusEnum.default('todo'),
  dueDate: z.string().datetime({ offset: true }).optional(),
});

export const updateTaskSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  status: taskStatusEnum,
  dueDate: z.string().datetime({ offset: true }).optional().nullable(),
});

export const patchTaskSchema = updateTaskSchema.partial();

export type CreateTaskDto = z.infer<typeof createTaskSchema>;
export type UpdateTaskDto = z.infer<typeof updateTaskSchema>;
export type PatchTaskDto = z.infer<typeof patchTaskSchema>;
