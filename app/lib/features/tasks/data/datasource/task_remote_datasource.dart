import 'package:dio/dio.dart';

import '../dto/task_dto.dart';

class TaskRemoteDataSource {
  final Dio _dio;
  TaskRemoteDataSource(this._dio);

  Future<List<TaskDto>> fetchTasks() async {
    final res = await _dio.get('/api/tasks');
    final list = res.data as List<dynamic>;
    return list.map((e) => TaskDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<TaskDto> createTask(TaskDto dto) async {
    final res = await _dio.post('/api/tasks', data: {
      'title': dto.title,
      'description': dto.description,
      'status': dto.status,
      'dueDate': dto.dueDate != null ? '${dto.dueDate}Z' : null,
    });
    return TaskDto.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<TaskDto> updateTask(TaskDto dto) async {
    final res = await _dio.put('/api/tasks/${dto.id}', data: {
      'title': dto.title,
      'description': dto.description,
      'status': dto.status,
      'dueDate': dto.dueDate != null ? '${dto.dueDate}Z' : null,
    });
    return TaskDto.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/api/tasks/$id');
  }
}
