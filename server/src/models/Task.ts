import { Schema, model, Document, Types } from 'mongoose';

export type TaskStatus = 'todo' | 'in_progress' | 'done';
export type TaskPriority = 'low' | 'medium' | 'high';

export interface ITask extends Document {
  title: string;
  description?: string;
  status: TaskStatus;
  priority: TaskPriority;
  dueDate?: Date;
  reminderAt?: Date;
  completedAt?: Date;
  deletedAt?: Date; // Soft delete for trash bin
  userId: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const taskSchema = new Schema<ITask>(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String, trim: true },
    status: {
      type: String,
      enum: ['todo', 'in_progress', 'done'],
      default: 'todo',
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium',
    },
    dueDate: { type: Date },
    reminderAt: { type: Date },
    completedAt: { type: Date },
    deletedAt: { type: Date, default: null }, // null = not deleted
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  },
  { timestamps: true },
);

// Index for efficient trash queries
taskSchema.index({ userId: 1, deletedAt: 1 });
// Index for reminders
taskSchema.index({ reminderAt: 1, deletedAt: 1 });
// Text index for search
taskSchema.index({ title: 'text', description: 'text' });

taskSchema.set('toJSON', {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  transform: (_doc: unknown, ret: any) => {
    delete ret.__v;
    return ret;
  },
});

export const Task = model<ITask>('Task', taskSchema);
