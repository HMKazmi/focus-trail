import '../../../core/utils/result.dart';
import 'entities/task_entity.dart';

/// Task repository contract.
abstract class TaskRepository {
  /// Fetches tasks, preferring local cache; refreshes from remote when possible.
  Future<Result<List<TaskEntity>>> getTasks({bool forceRefresh = false});

  Future<Result<TaskEntity>> createTask(TaskEntity task);

  Future<Result<TaskEntity>> updateTask(TaskEntity task);

  Future<Result<void>> deleteTask(String id);
}
