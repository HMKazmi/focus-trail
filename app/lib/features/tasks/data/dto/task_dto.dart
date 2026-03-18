import '../../domain/entities/task_entity.dart';

/// Data transfer object for serialisation to/from JSON and Hive maps.
class TaskDto {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? dueDate;
  final String? reminderAt;
  final String? completedAt;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final bool isSynced;

  const TaskDto({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.priority = 'medium',
    this.dueDate,
    this.reminderAt,
    this.completedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  // ── JSON ──────────────────────────────────────────────────
  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'todo',
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['dueDate'] as String?,
      reminderAt: json['reminderAt'] as String?,
      completedAt: json['completedAt'] as String?,
      deletedAt: json['deletedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      isSynced: json['isSynced'] as bool? ?? true, // Server data is always synced
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'dueDate': dueDate,
        'reminderAt': reminderAt,
        'completedAt': completedAt,
        'deletedAt': deletedAt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'isSynced': isSynced,
      };

  // ── Hive map ──────────────────────────────────────────────
  factory TaskDto.fromMap(Map map) => TaskDto.fromJson(Map<String, dynamic>.from(map));
  Map<String, dynamic> toMap() => toJson();

  // ── Domain mapping ────────────────────────────────────────
  TaskEntity toEntity() => TaskEntity(
        id: id,
        title: title,
        description: description,
        status: TaskStatus.fromJson(status),
        priority: TaskPriority.fromJson(priority),
        dueDate: dueDate != null ? DateTime.tryParse(dueDate!) : null,
        reminderAt: reminderAt != null ? DateTime.tryParse(reminderAt!) : null,
        completedAt: completedAt != null ? DateTime.tryParse(completedAt!) : null,
        deletedAt: deletedAt != null ? DateTime.tryParse(deletedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        isSynced: isSynced,
      );

  factory TaskDto.fromEntity(TaskEntity e) => TaskDto(
        id: e.id,
        title: e.title,
        description: e.description,
        status: e.status.toJson(),
        priority: e.priority.toJson(),
        dueDate: e.dueDate?.toIso8601String(),
        reminderAt: e.reminderAt?.toIso8601String(),
        completedAt: e.completedAt?.toIso8601String(),
        deletedAt: e.deletedAt?.toIso8601String(),
        createdAt: e.createdAt.toIso8601String(),
        updatedAt: e.updatedAt.toIso8601String(),
        isSynced: e.isSynced,
      );
}
