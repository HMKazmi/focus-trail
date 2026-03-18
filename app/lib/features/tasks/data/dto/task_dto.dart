import '../../domain/entities/task_entity.dart';

/// Data transfer object for serialisation to/from JSON and Hive maps.
class TaskDto {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String? dueDate;
  final String createdAt;
  final String updatedAt;

  const TaskDto({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── JSON ──────────────────────────────────────────────────
  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'todo',
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'dueDate': dueDate,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
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
        dueDate: dueDate != null ? DateTime.tryParse(dueDate!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory TaskDto.fromEntity(TaskEntity e) => TaskDto(
        id: e.id,
        title: e.title,
        description: e.description,
        status: e.status.toJson(),
        dueDate: e.dueDate?.toIso8601String(),
        createdAt: e.createdAt.toIso8601String(),
        updatedAt: e.updatedAt.toIso8601String(),
      );
}
