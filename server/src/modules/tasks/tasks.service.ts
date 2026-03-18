import { Types } from 'mongoose';
import { Task } from '../../models/Task';
import { ApiError } from '../../utils/ApiError';
import { logger } from '../../utils/logger';
import type { CreateTaskDto, UpdateTaskDto, PatchTaskDto } from './tasks.schemas';

function toObjectId(id: string): Types.ObjectId {
  if (!Types.ObjectId.isValid(id)) {
    logger.warn(`Invalid ObjectId format: ${id}`, { module: 'TasksService' });
    throw ApiError.badRequest('Invalid id format');
  }
  return new Types.ObjectId(id);
}

export interface ListTasksQuery {
  status?: string;
  search?: string;
  sort?: string;
}

export async function listTasks(userId: string, query: ListTasksQuery) {
  const filter: Record<string, unknown> = { userId: toObjectId(userId) };

  if (query.status) {
    filter['status'] = query.status;
    logger.debug(`Filtering by status: ${query.status}`, { module: 'TasksService' });
  }
  if (query.search) {
    filter['$or'] = [
      { title: { $regex: query.search, $options: 'i' } },
      { description: { $regex: query.search, $options: 'i' } },
    ];
    logger.debug(`Searching for: ${query.search}`, { module: 'TasksService' });
  }

  const sortField = query.sort === 'createdAt' ? 'createdAt' : 'updatedAt';
  logger.db('FIND', 'tasks', { data: { filter, sort: sortField } });
  
  const tasks = await Task.find(filter).sort({ [sortField]: -1 });
  logger.success(`Found ${tasks.length} tasks`, { module: 'TasksService' });
  
  return tasks;
}

export async function createTask(userId: string, dto: CreateTaskDto) {
  logger.db('CREATE', 'tasks', { data: { userId, title: dto.title } });
  
  const task = await Task.create({
    ...dto,
    dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
    userId: toObjectId(userId),
  });
  
  logger.success(`Task created: ${task._id}`, { module: 'TasksService' });
  return task;
}

export async function getTaskById(userId: string, taskId: string) {
  logger.db('FIND_ONE', 'tasks', { data: { taskId, userId } });
  
  const task = await Task.findOne({ _id: toObjectId(taskId), userId: toObjectId(userId) });
  if (!task) {
    logger.warn(`Task not found: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found');
  }
  
  logger.success(`Task found: ${taskId}`, { module: 'TasksService' });
  return task;
}

export async function updateTask(userId: string, taskId: string, dto: UpdateTaskDto) {
  logger.db('UPDATE', 'tasks', { data: { taskId, userId, updates: dto } });
  
  const task = await Task.findOneAndUpdate(
    { _id: toObjectId(taskId), userId: toObjectId(userId) },
    { ...dto, dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined },
    { returnDocument: 'after', runValidators: true },
  );
  
  if (!task) {
    logger.warn(`Task not found for update: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found');
  }
  
  logger.success(`Task updated: ${taskId}`, { module: 'TasksService' });
  return task;
}

export async function patchTask(userId: string, taskId: string, dto: PatchTaskDto) {
  logger.db('PATCH', 'tasks', { data: { taskId, userId, patches: dto } });
  
  const update: Record<string, unknown> = { ...dto };
  if (dto.dueDate !== undefined) {
    update['dueDate'] = dto.dueDate ? new Date(dto.dueDate) : null;
  }

  const task = await Task.findOneAndUpdate(
    { _id: toObjectId(taskId), userId: toObjectId(userId) },
    update,
    { returnDocument: 'after', runValidators: true },
  );
  
  if (!task) {
    logger.warn(`Task not found for patch: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found');
  }
  
  logger.success(`Task patched: ${taskId}`, { module: 'TasksService' });
  return task;
}

export async function deleteTask(userId: string, taskId: string) {
  logger.db('DELETE', 'tasks', { data: { taskId, userId } });
  
  const task = await Task.findOneAndDelete({
    _id: toObjectId(taskId),
    userId: toObjectId(userId),
  });
  
  if (!task) {
    logger.warn(`Task not found for deletion: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found');
  }
  
  logger.success(`Task deleted: ${taskId}`, { module: 'TasksService' });
}
