import 'package:dio/dio.dart';

import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/task_entity.dart';
import '../domain/task_repository.dart';
import 'datasource/task_local_datasource.dart';
import 'datasource/task_remote_datasource.dart';
import 'dto/task_dto.dart';

/// Offline-first implementation.
/// Local Hive is the source of truth; background sync pushes changes to remote.
class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remote;
  final TaskLocalDataSource _local;

  TaskRepositoryImpl(this._remote, this._local);

  @override
  Future<Result<List<TaskEntity>>> getTasks({bool forceRefresh = false}) async {
    // Always return local first.
    if (forceRefresh) {
      try {
        final remoteDtos = await _remote.fetchTasks();
        await _local.replaceAll(remoteDtos);
      } on DioException catch (e) {
        // If refresh fails, we still return local data.
        // Only fail if local is also empty.
        final local = _local.getAll();
        if (local.isEmpty) return Result.failure(mapDioError(e));
      } catch (_) {
        // ignore
      }
    }
    final localDtos = _local.getAll();
    return Result.success(localDtos.map((d) => d.toEntity()).toList());
  }

  @override
  Future<Result<TaskEntity>> createTask(TaskEntity task) async {
    final dto = TaskDto.fromEntity(task);
    await _local.put(dto);
    return Result.success(dto.toEntity());
  }

  @override
  Future<Result<TaskEntity>> updateTask(TaskEntity task) async {
    final dto = TaskDto.fromEntity(task);
    await _local.put(dto);
    return Result.success(dto.toEntity());
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    await _local.delete(id);
    return Result.success(null);
  }
}
