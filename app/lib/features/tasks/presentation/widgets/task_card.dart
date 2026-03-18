import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (task.status) {
      TaskStatus.todo => cs.outline,
      TaskStatus.inProgress => cs.primary,
      TaskStatus.done => cs.tertiary,
    };
  }

  IconData _statusIcon() {
    return switch (task.status) {
      TaskStatus.todo => Icons.radio_button_unchecked,
      TaskStatus.inProgress => Icons.timelapse,
      TaskStatus.done => Icons.check_circle,
    };
  }

  Color _priorityColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (task.priority) {
      TaskPriority.low => Colors.green,
      TaskPriority.medium => Colors.orange,
      TaskPriority.high => cs.error,
    };
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final diff = dueDay.difference(today).inDays;

    if (diff == 0) {
      return 'Today ${DateFormat.jm().format(date)}';
    } else if (diff == 1) {
      return 'Tomorrow ${DateFormat.jm().format(date)}';
    } else if (diff == -1) {
      return 'Yesterday ${DateFormat.jm().format(date)}';
    } else if (diff > 1 && diff <= 7) {
      return '${DateFormat.E().format(date)} ${DateFormat.jm().format(date)}';
    } else {
      return '${DateFormat.MMMd().format(date)} ${DateFormat.jm().format(date)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(context);
    final priorityColor = _priorityColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Material(
            color:
                isDark
                    ? cs.surfaceContainerHighest.withAlpha(100)
                    : cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color:
                    isDark
                        ? statusColor.withAlpha(80)
                        : statusColor.withAlpha(120),
                width: isDark ? 1 : 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Status toggle with sync indicator
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            _statusIcon(),
                            color: statusColor,
                            size: 28,
                          ),
                          onPressed: onToggleStatus,
                          tooltip: 'Change status',
                        ),
                        // Sync indicator
                        if (!task.isSynced)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isDark
                                          ? cs.surface
                                          : cs.surfaceContainerHigh,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Priority indicator
                              Container(
                                width: 4,
                                height: 16,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    decoration:
                                        task.status == TaskStatus.done
                                            ? TextDecoration.lineThrough
                                            : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? statusColor.withAlpha(30)
                                          : statusColor.withAlpha(50),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      isDark
                                          ? null
                                          : Border.all(
                                            color: statusColor.withAlpha(100),
                                            width: 0.5,
                                          ),
                                ),
                                child: Text(
                                  task.status.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        isDark
                                            ? statusColor
                                            : statusColor.withAlpha(255),
                                    fontWeight:
                                        isDark
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (task.dueDate != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  task.isOverdue
                                      ? Icons.warning
                                      : Icons.schedule,
                                  size: 12,
                                  color:
                                      task.isOverdue
                                          ? cs.error
                                          : task.isDueSoon
                                          ? Colors.orange
                                          : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDueDate(task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        task.isOverdue
                                            ? cs.error
                                            : task.isDueSoon
                                            ? Colors.orange
                                            : cs.onSurfaceVariant,
                                    fontWeight:
                                        task.isOverdue ? FontWeight.bold : null,
                                  ),
                                ),
                              ],
                              if (task.hasReminder) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.notifications_active,
                                  size: 12,
                                  color: cs.primary,
                                ),
                              ],
                              // Sync status text
                              if (!task.isSynced) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.orange.withAlpha(30)
                                            : Colors.orange.withAlpha(50),
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        isDark
                                            ? null
                                            : Border.all(
                                              color: Colors.orange.withAlpha(
                                                150,
                                              ),
                                              width: 0.5,
                                            ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.cloud_off,
                                        size: 10,
                                        color:
                                            isDark
                                                ? Colors.orange
                                                : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Pending',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color:
                                              isDark
                                                  ? Colors.orange
                                                  : Colors.orange.shade700,
                                          fontWeight:
                                              isDark
                                                  ? FontWeight.normal
                                                  : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Delete
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: cs.error.withAlpha(180),
                      ),
                      onPressed: () => _confirmDelete(context),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
