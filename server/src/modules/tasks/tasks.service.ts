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
  priority?: string;
  search?: string;
  sort?: string;
  dueBefore?: string;
  dueAfter?: string;
  includeCompleted?: string;
}

export async function listTasks(userId: string, query: ListTasksQuery) {
  const filter: Record<string, unknown> = { 
    userId: toObjectId(userId),
    deletedAt: null, // Exclude trashed tasks
  };

  if (query.status) {
    filter['status'] = query.status;
    logger.debug(`Filtering by status: ${query.status}`, { module: 'TasksService' });
  }
  if (query.priority) {
    filter['priority'] = query.priority;
    logger.debug(`Filtering by priority: ${query.priority}`, { module: 'TasksService' });
  }
  if (query.search) {
    filter['$or'] = [
      { title: { $regex: query.search, $options: 'i' } },
      { description: { $regex: query.search, $options: 'i' } },
    ];
    logger.debug(`Searching for: ${query.search}`, { module: 'TasksService' });
  }
  if (query.dueBefore) {
    filter['dueDate'] = { ...((filter['dueDate'] as object) || {}), $lte: new Date(query.dueBefore) };
  }
  if (query.dueAfter) {
    filter['dueDate'] = { ...((filter['dueDate'] as object) || {}), $gte: new Date(query.dueAfter) };
  }

  const sortField = query.sort === 'createdAt' ? 'createdAt' : 
                    query.sort === 'dueDate' ? 'dueDate' :
                    query.sort === 'priority' ? 'priority' : 'updatedAt';
  logger.db('FIND', 'tasks', { data: { filter, sort: sortField } });
  
  const tasks = await Task.find(filter).sort({ [sortField]: -1 });
  logger.success(`Found ${tasks.length} tasks`, { module: 'TasksService' });
  
  return tasks;
}

export async function createTask(userId: string, dto: CreateTaskDto) {
  logger.db('CREATE', 'tasks', { data: { userId, title: dto.title } });
  
  const task = await Task.create({
    title: dto.title,
    description: dto.description || undefined,
    status: dto.status,
    priority: dto.priority,
    dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
    reminderAt: dto.reminderAt ? new Date(dto.reminderAt) : undefined,
    userId: toObjectId(userId),
  });
  
  logger.success(`Task created: ${task._id}`, { module: 'TasksService' });
  return task;
}

export async function getTaskById(userId: string, taskId: string) {
  logger.db('FIND_ONE', 'tasks', { data: { taskId, userId } });
  
  const task = await Task.findOne({ 
    _id: toObjectId(taskId), 
    userId: toObjectId(userId),
    deletedAt: null,
  });
  if (!task) {
    logger.warn(`Task not found: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found');
  }
  
  logger.success(`Task found: ${taskId}`, { module: 'TasksService' });
  return task;
}

export async function updateTask(userId: string, taskId: string, dto: UpdateTaskDto) {
  logger.db('UPDATE', 'tasks', { data: { taskId, userId, updates: dto } });
  
  const updateData: Record<string, unknown> = { ...dto };
  if (dto.dueDate !== undefined) {
    updateData['dueDate'] = dto.dueDate ? new Date(dto.dueDate) : null;
  }
  if (dto.reminderAt !== undefined) {
    updateData['reminderAt'] = dto.reminderAt ? new Date(dto.reminderAt) : null;
  }
  
  // Track completion time
  if (dto.status === 'done') {
    updateData['completedAt'] = new Date();
  } else {
    updateData['completedAt'] = null;
  }
  
  const task = await Task.findOneAndUpdate(
    { _id: toObjectId(taskId), userId: toObjectId(userId), deletedAt: null },
    updateData,
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
  if (dto.reminderAt !== undefined) {
    update['reminderAt'] = dto.reminderAt ? new Date(dto.reminderAt) : null;
  }
  
  // Track completion time
  if (dto.status === 'done') {
    update['completedAt'] = new Date();
  } else if (dto.status) {
    // If status changed to anything other than 'done', clear completedAt
    update['completedAt'] = null;
  }

  const task = await Task.findOneAndUpdate(
    { _id: toObjectId(taskId), userId: toObjectId(userId), deletedAt: null },
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

// ═══════════════════════════════════════════════════════════
// SOFT DELETE / TRASH BIN
// ═══════════════════════════════════════════════════════════

export async function trashTask(userId: string, taskId: string) {
  logger.db('TRASH', 'tasks', { data: { taskId, userId } });
  
  const task = await Task.findOneAndUpdate(
    { _id: toObjectId(taskId), userId: toObjectId(userId), deletedAt: null },
    { deletedAt: new Date() },
    { returnDocument: 'after' },
  );
  
  if (!task) {
    logger.warn(`Task not found for trash: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found');
  }
  
  logger.success(`Task trashed: ${taskId}`, { module: 'TasksService' });
  return task;
}

export async function restoreTask(userId: string, taskId: string) {
  logger.db('RESTORE', 'tasks', { data: { taskId, userId } });
  
  const task = await Task.findOneAndUpdate(
    { _id: toObjectId(taskId), userId: toObjectId(userId), deletedAt: { $ne: null } },
    { deletedAt: null },
    { returnDocument: 'after' },
  );
  
  if (!task) {
    logger.warn(`Trashed task not found for restore: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found in trash');
  }
  
  logger.success(`Task restored: ${taskId}`, { module: 'TasksService' });
  return task;
}

export async function listTrash(userId: string) {
  logger.db('FIND', 'tasks (trash)', { data: { userId } });
  
  const tasks = await Task.find({
    userId: toObjectId(userId),
    deletedAt: { $ne: null },
  }).sort({ deletedAt: -1 });
  
  logger.success(`Found ${tasks.length} trashed tasks`, { module: 'TasksService' });
  return tasks;
}

export async function emptyTrash(userId: string) {
  logger.db('DELETE_MANY', 'tasks (trash)', { data: { userId } });
  
  const result = await Task.deleteMany({
    userId: toObjectId(userId),
    deletedAt: { $ne: null },
  });
  
  logger.success(`Permanently deleted ${result.deletedCount} tasks from trash`, { module: 'TasksService' });
  return result.deletedCount;
}

export async function deleteTask(userId: string, taskId: string) {
  logger.db('DELETE', 'tasks', { data: { taskId, userId } });
  
  // Hard delete (for permanently deleting from trash)
  const task = await Task.findOneAndDelete({
    _id: toObjectId(taskId),
    userId: toObjectId(userId),
  });
  
  if (!task) {
    logger.warn(`Task not found for deletion: ${taskId}`, { module: 'TasksService' });
    throw ApiError.notFound('Task not found');
  }
  
  logger.success(`Task permanently deleted: ${taskId}`, { module: 'TasksService' });
}

// ═══════════════════════════════════════════════════════════
// REMINDERS
// ═══════════════════════════════════════════════════════════

export async function getUpcomingReminders(userId: string, hoursAhead: number = 24) {
  const now = new Date();
  const until = new Date(now.getTime() + hoursAhead * 60 * 60 * 1000);
  
  logger.db('FIND', 'tasks (reminders)', { data: { userId, hoursAhead } });
  
  const tasks = await Task.find({
    userId: toObjectId(userId),
    deletedAt: null,
    reminderAt: { $gte: now, $lte: until },
    status: { $ne: 'done' },
  }).sort({ reminderAt: 1 });
  
  logger.success(`Found ${tasks.length} upcoming reminders`, { module: 'TasksService' });
  return tasks;
}

export async function getDueSoonTasks(userId: string, hoursAhead: number = 24) {
  const now = new Date();
  const until = new Date(now.getTime() + hoursAhead * 60 * 60 * 1000);
  
  logger.db('FIND', 'tasks (due soon)', { data: { userId, hoursAhead } });
  
  const tasks = await Task.find({
    userId: toObjectId(userId),
    deletedAt: null,
    dueDate: { $gte: now, $lte: until },
    status: { $ne: 'done' },
  }).sort({ dueDate: 1 });
  
  logger.success(`Found ${tasks.length} tasks due soon`, { module: 'TasksService' });
  return tasks;
}

export async function getOverdueTasks(userId: string) {
  const now = new Date();
  
  logger.db('FIND', 'tasks (overdue)', { data: { userId } });
  
  const tasks = await Task.find({
    userId: toObjectId(userId),
    deletedAt: null,
    dueDate: { $lt: now },
    status: { $ne: 'done' },
  }).sort({ dueDate: 1 });
  
  logger.success(`Found ${tasks.length} overdue tasks`, { module: 'TasksService' });
  return tasks;
}

// ═══════════════════════════════════════════════════════════
// DASHBOARD / ANALYTICS
// ═══════════════════════════════════════════════════════════

export interface DashboardStats {
  total: number;
  byStatus: { todo: number; in_progress: number; done: number };
  byPriority: { low: number; medium: number; high: number };
  overdue: number;
  dueSoon: number;
  completedToday: number;
  completedThisWeek: number;
  completedThisMonth: number;
  streak: number;
  avgCompletionTime: number | null; // in hours
}

export async function getDashboardStats(userId: string): Promise<DashboardStats> {
  const userObjId = toObjectId(userId);
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const weekStart = new Date(todayStart);
  weekStart.setDate(weekStart.getDate() - weekStart.getDay());
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const tomorrowEnd = new Date(todayStart);
  tomorrowEnd.setDate(tomorrowEnd.getDate() + 1);

  logger.db('AGGREGATE', 'tasks (dashboard stats)', { data: { userId } });

  // Run aggregations in parallel
  const [
    statusAgg,
    priorityAgg,
    overdueCount,
    dueSoonCount,
    completedTodayCount,
    completedWeekCount,
    completedMonthCount,
    avgCompletionAgg,
    recentCompletions,
  ] = await Promise.all([
    // Status counts
    Task.aggregate([
      { $match: { userId: userObjId, deletedAt: null } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),
    // Priority counts
    Task.aggregate([
      { $match: { userId: userObjId, deletedAt: null } },
      { $group: { _id: '$priority', count: { $sum: 1 } } },
    ]),
    // Overdue
    Task.countDocuments({
      userId: userObjId,
      deletedAt: null,
      dueDate: { $lt: now },
      status: { $ne: 'done' },
    }),
    // Due soon (next 24 hours)
    Task.countDocuments({
      userId: userObjId,
      deletedAt: null,
      dueDate: { $gte: now, $lte: tomorrowEnd },
      status: { $ne: 'done' },
    }),
    // Completed today
    Task.countDocuments({
      userId: userObjId,
      deletedAt: null,
      status: 'done',
      completedAt: { $gte: todayStart },
    }),
    // Completed this week
    Task.countDocuments({
      userId: userObjId,
      deletedAt: null,
      status: 'done',
      completedAt: { $gte: weekStart },
    }),
    // Completed this month
    Task.countDocuments({
      userId: userObjId,
      deletedAt: null,
      status: 'done',
      completedAt: { $gte: monthStart },
    }),
    // Average completion time
    Task.aggregate([
      { 
        $match: { 
          userId: userObjId, 
          deletedAt: null,
          status: 'done',
          completedAt: { $ne: null },
        },
      },
      {
        $project: {
          completionTime: {
            $divide: [
              { $subtract: ['$completedAt', '$createdAt'] },
              1000 * 60 * 60, // Convert to hours
            ],
          },
        },
      },
      { $group: { _id: null, avg: { $avg: '$completionTime' } } },
    ]),
    // Recent completions for streak calculation
    Task.find({
      userId: userObjId,
      deletedAt: null,
      status: 'done',
      completedAt: { $ne: null },
    })
      .select('completedAt')
      .sort({ completedAt: -1 })
      .limit(100),
  ]);

  // Process status counts
  const byStatus = { todo: 0, in_progress: 0, done: 0 };
  for (const s of statusAgg) {
    if (s._id in byStatus) {
      byStatus[s._id as keyof typeof byStatus] = s.count;
    }
  }

  // Process priority counts
  const byPriority = { low: 0, medium: 0, high: 0 };
  for (const p of priorityAgg) {
    if (p._id in byPriority) {
      byPriority[p._id as keyof typeof byPriority] = p.count;
    }
  }

  // Calculate streak (consecutive days with at least one completed task)
  let streak = 0;
  if (recentCompletions.length > 0) {
    const completionDates = new Set<string>();
    for (const t of recentCompletions) {
      if (t.completedAt) {
        const date = t.completedAt.toISOString().split('T')[0];
        completionDates.add(date);
      }
    }
    
    const checkDate = new Date(todayStart);
    while (true) {
      const dateStr = checkDate.toISOString().split('T')[0];
      if (completionDates.has(dateStr)) {
        streak++;
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        break;
      }
    }
  }

  const total = byStatus.todo + byStatus.in_progress + byStatus.done;
  const avgCompletionTime = avgCompletionAgg.length > 0 ? Math.round(avgCompletionAgg[0].avg * 10) / 10 : null;

  logger.success(`Dashboard stats calculated for user: ${userId}`, { module: 'TasksService' });

  return {
    total,
    byStatus,
    byPriority,
    overdue: overdueCount,
    dueSoon: dueSoonCount,
    completedToday: completedTodayCount,
    completedThisWeek: completedWeekCount,
    completedThisMonth: completedMonthCount,
    streak,
    avgCompletionTime,
  };
}

export interface AnalyticsPeriod {
  period: 'day' | 'week' | 'month';
  days: number;
}

export async function getCompletionTrend(userId: string, period: AnalyticsPeriod['period'] = 'week') {
  const userObjId = toObjectId(userId);
  const now = new Date();
  let startDate: Date;
  let groupFormat: string;
  
  switch (period) {
    case 'day':
      startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      groupFormat = '%Y-%m-%d %H:00';
      break;
    case 'month':
      startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
      groupFormat = '%Y-%m-%d';
      break;
    case 'week':
    default:
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      groupFormat = '%Y-%m-%d';
  }

  logger.db('AGGREGATE', 'tasks (completion trend)', { data: { userId, period } });

  const trend = await Task.aggregate([
    {
      $match: {
        userId: userObjId,
        deletedAt: null,
        completedAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: { $dateToString: { format: groupFormat, date: '$completedAt' } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  logger.success(`Completion trend calculated: ${trend.length} data points`, { module: 'TasksService' });
  return trend.map((t) => ({ date: t._id, count: t.count }));
}

export async function getCreatedVsCompletedTrend(userId: string, days: number = 7) {
  const userObjId = toObjectId(userId);
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  startDate.setHours(0, 0, 0, 0);

  logger.db('AGGREGATE', 'tasks (created vs completed)', { data: { userId, days } });

  const [created, completed] = await Promise.all([
    Task.aggregate([
      {
        $match: {
          userId: userObjId,
          createdAt: { $gte: startDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]),
    Task.aggregate([
      {
        $match: {
          userId: userObjId,
          completedAt: { $gte: startDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$completedAt' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]),
  ]);

  // Merge into unified data
  const dateMap = new Map<string, { created: number; completed: number }>();
  
  for (let i = 0; i <= days; i++) {
    const date = new Date(startDate);
    date.setDate(date.getDate() + i);
    const dateStr = date.toISOString().split('T')[0];
    dateMap.set(dateStr, { created: 0, completed: 0 });
  }
  
  for (const c of created) {
    const existing = dateMap.get(c._id);
    if (existing) existing.created = c.count;
  }
  
  for (const c of completed) {
    const existing = dateMap.get(c._id);
    if (existing) existing.completed = c.count;
  }

  const trend = Array.from(dateMap.entries())
    .map(([date, data]) => ({ date, ...data }))
    .sort((a, b) => a.date.localeCompare(b.date));

  logger.success(`Created vs completed trend calculated: ${trend.length} data points`, { module: 'TasksService' });
  return trend;
}

// ═══════════════════════════════════════════════════════════
// EXPORT
// ═══════════════════════════════════════════════════════════

export async function exportTasks(userId: string, format: 'json' | 'csv' = 'json') {
  logger.db('FIND', 'tasks (export)', { data: { userId, format } });
  
  const tasks = await Task.find({
    userId: toObjectId(userId),
    deletedAt: null,
  }).sort({ createdAt: -1 });

  logger.success(`Exporting ${tasks.length} tasks as ${format}`, { module: 'TasksService' });

  if (format === 'csv') {
    const headers = ['id', 'title', 'description', 'status', 'priority', 'dueDate', 'reminderAt', 'completedAt', 'createdAt', 'updatedAt'];
    const csvRows = [headers.join(',')];
    
    for (const task of tasks) {
      const row = [
        task._id.toString(),
        `"${(task.title || '').replace(/"/g, '""')}"`,
        `"${(task.description || '').replace(/"/g, '""')}"`,
        task.status,
        task.priority || 'medium',
        task.dueDate?.toISOString() || '',
        task.reminderAt?.toISOString() || '',
        task.completedAt?.toISOString() || '',
        task.createdAt.toISOString(),
        task.updatedAt.toISOString(),
      ];
      csvRows.push(row.join(','));
    }
    
    return csvRows.join('\n');
  }

  // JSON format
  return tasks.map((t) => ({
    id: t._id.toString(),
    title: t.title,
    description: t.description,
    status: t.status,
    priority: t.priority || 'medium',
    dueDate: t.dueDate?.toISOString() || null,
    reminderAt: t.reminderAt?.toISOString() || null,
    completedAt: t.completedAt?.toISOString() || null,
    createdAt: t.createdAt.toISOString(),
    updatedAt: t.updatedAt.toISOString(),
  }));
}
