import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';

class TaskFormPage extends ConsumerStatefulWidget {
  final String? taskId;
  const TaskFormPage({super.key, this.taskId});

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  DateTime? _reminderAt;
  bool _initialized = false;

  bool get isEditing => widget.taskId != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _initFromTask(TaskEntity task) {
    if (_initialized) return;
    _titleCtrl.text = task.title;
    _descCtrl.text = task.description ?? '';
    _status = task.status;
    _priority = task.priority;
    _dueDate = task.dueDate;
    _reminderAt = task.reminderAt;
    _initialized = true;
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : const TimeOfDay(hour: 23, minute: 59), // Default to end of day
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickReminder() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderAt != null
          ? TimeOfDay.fromDateTime(_reminderAt!)
          : TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _reminderAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(taskListProvider.notifier);

    if (isEditing) {
      // Find the existing task from state
      final existing =
          ref.read(taskListProvider).tasks.firstWhere((t) => t.id == widget.taskId);
      await notifier.updateTask(
        existing.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          reminderAt: _reminderAt,
          clearDueDate: _dueDate == null && existing.dueDate != null,
          clearReminder: _reminderAt == null && existing.reminderAt != null,
        ),
      );
    } else {
      await notifier.createTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        reminderAt: _reminderAt,
      );
    }

    if (mounted) context.go('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    // If editing, seed fields from existing task
    if (isEditing) {
      final tasks = ref.watch(taskListProvider).tasks;
      final match = tasks.where((t) => t.id == widget.taskId);
      if (match.isNotEmpty) _initFromTask(match.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tasks'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Status and Priority row
                  Row(
                    children: [
                      // Status
                      Expanded(
                        child: DropdownButtonFormField<TaskStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: TaskStatus.values
                              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Priority
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                          initialValue: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            prefixIcon: Icon(Icons.priority_high),
                          ),
                          items: TaskPriority.values
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 12,
                                          color: _getPriorityColor(p),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(p.label),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _priority = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Due date
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(
                        _dueDate != null
                            ? 'Due: ${DateFormat.yMMMd().add_jm().format(_dueDate!)}'
                            : 'No due date',
                      ),
                      subtitle: _dueDate != null ? null : const Text('Tap to set due date and time'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _dueDate = null),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: _pickDate,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Reminder
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(
                        _reminderAt != null
                            ? 'Reminder: ${DateFormat.yMMMd().add_jm().format(_reminderAt!)}'
                            : 'No reminder',
                      ),
                      subtitle: _reminderAt != null ? null : const Text('Tap to set reminder'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_reminderAt != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _reminderAt = null),
                            ),
                          IconButton(
                            icon: const Icon(Icons.alarm_add),
                            onPressed: _pickReminder,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: Icon(isEditing ? Icons.save : Icons.add),
                    label: Text(isEditing ? 'Save Changes' : 'Create Task'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}
