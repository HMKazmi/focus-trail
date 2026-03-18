import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../dto/task_dto.dart';

/// Local Hive data source for tasks.
class TaskLocalDataSource {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.tasks);

  List<TaskDto> getAll() {
    return _box.values.map((m) => TaskDto.fromMap(m)).toList();
  }

  TaskDto? getById(String id) {
    final raw = _box.get(id);
    return raw != null ? TaskDto.fromMap(raw) : null;
  }

  Future<void> put(TaskDto dto) async {
    await _box.put(dto.id, dto.toMap());
  }

  Future<void> putAll(List<TaskDto> dtos) async {
    final map = {for (final d in dtos) d.id: d.toMap()};
    await _box.putAll(map);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> replaceAll(List<TaskDto> dtos) async {
    await _box.clear();
    await putAll(dtos);
  }
}
