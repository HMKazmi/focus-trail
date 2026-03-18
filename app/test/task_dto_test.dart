import 'package:flutter_test/flutter_test.dart';

import 'package:focus_trail/features/tasks/data/dto/task_dto.dart';
import 'package:focus_trail/features/tasks/domain/entities/task_entity.dart';

void main() {
  group('TaskDto mapping', () {
    test('fromJson → toEntity roundtrip preserves data', () {
      final json = {
        '_id': 'abc123',
        'title': 'Test Task',
        'description': 'A description',
        'status': 'in_progress',
        'dueDate': '2026-04-01T00:00:00.000Z',
        'createdAt': '2026-03-17T10:00:00.000Z',
        'updatedAt': '2026-03-17T12:00:00.000Z',
      };

      final dto = TaskDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.id, 'abc123');
      expect(entity.title, 'Test Task');
      expect(entity.description, 'A description');
      expect(entity.status, TaskStatus.inProgress);
      expect(entity.dueDate, isNotNull);
      expect(entity.dueDate!.year, 2026);
    });

    test('fromEntity → toJson produces correct status string', () {
      final entity = TaskEntity(
        id: '1',
        title: 'My Task',
        status: TaskStatus.done,
        createdAt: DateTime(2026, 3, 17),
        updatedAt: DateTime(2026, 3, 17),
      );

      final dto = TaskDto.fromEntity(entity);
      final json = dto.toJson();

      expect(json['status'], 'done');
      expect(json['title'], 'My Task');
      expect(json['description'], isNull);
    });
  });

  group('TaskStatus', () {
    test('fromJson handles all values', () {
      expect(TaskStatus.fromJson('todo'), TaskStatus.todo);
      expect(TaskStatus.fromJson('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromJson('done'), TaskStatus.done);
      expect(TaskStatus.fromJson('unknown'), TaskStatus.todo);
    });
  });
}
