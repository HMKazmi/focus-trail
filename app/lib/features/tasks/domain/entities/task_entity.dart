/// Status of a task.
enum TaskStatus {
  todo,
  inProgress,
  done;

  String toJson() {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  static TaskStatus fromJson(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

/// Priority of a task.
enum TaskPriority {
  low,
  medium,
  high;

  String toJson() {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  static TaskPriority fromJson(String? value) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

/// Domain entity for a task.
class TaskEntity {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced; // Track if task is synced with server

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.reminderAt,
    this.completedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  bool get isDeleted => deletedAt != null;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && status != TaskStatus.done;
  bool get isDueSoon {
    if (dueDate == null || status == TaskStatus.done) return false;
    final diff = dueDate!.difference(DateTime.now());
    return diff.inHours >= 0 && diff.inHours <= 24;
  }
  bool get hasReminder => reminderAt != null && reminderAt!.isAfter(DateTime.now());

  TaskEntity copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? reminderAt,
    DateTime? completedAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool clearDueDate = false,
    bool clearReminder = false,
    bool clearDeletedAt = false,
  }) {
    return TaskEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      completedAt: completedAt ?? this.completedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
