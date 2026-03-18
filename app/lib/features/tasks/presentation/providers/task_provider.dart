import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasource/task_local_datasource.dart';
import '../../data/datasource/task_remote_datasource.dart';
import '../../data/dto/task_dto.dart';
import '../../data/models/sync_operation.dart';
import '../../data/sync_service.dart';
import '../../data/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/task_repository.dart';

// ── DI ─────────────────────────────────────────────────────
final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((_) => TaskLocalDataSource());
final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(ref.watch(dioProvider));
});
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    ref.watch(taskRemoteDataSourceProvider),
    ref.watch(taskLocalDataSourceProvider),
  );
});

// ── Task list state ────────────────────────────────────────
class TaskListState {
  final List<TaskEntity> tasks;
  final bool isLoading;
  final String? error;
  final TaskStatus? statusFilter;
  final String searchQuery;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.searchQuery = '',
  });

  TaskListState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    String? error,
    TaskStatus? statusFilter,
    String? searchQuery,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Filtered & searched view of tasks.
  List<TaskEntity> get filteredTasks {
    var list = tasks.toList(); // Create a mutable copy
    if (statusFilter != null) {
      list = list.where((t) => t.status == statusFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((t) => t.title.toLowerCase().contains(q)).toList();
    }
    // Sort by updatedAt desc
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repo;
  final SyncServiceNotifier _syncService;

  TaskListNotifier(this._repo, this._syncService) : super(const TaskListState());

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getTasks(forceRefresh: forceRefresh);
    result.when(
      success: (data) => state = state.copyWith(tasks: data, isLoading: false),
      failure: (msg) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> createTask({
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? reminderAt,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final task = TaskEntity(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      reminderAt: reminderAt,
      createdAt: now,
      updatedAt: now,
      isSynced: false, // Mark as not synced initially
    );
    await _repo.createTask(task);
    // Enqueue sync op
    await _syncService.enqueue(SyncOperation(
      id: const Uuid().v4(),
      type: SyncOpType.create,
      entityId: id,
      payload: TaskDto.fromEntity(task).toMap(),
      createdAt: now,
    ));
    await load();
  }

  Future<void> updateTask(TaskEntity task) async {
    final updated = task.copyWith(updatedAt: DateTime.now(), isSynced: false);
    await _repo.updateTask(updated);
    await _syncService.enqueue(SyncOperation(
      id: const Uuid().v4(),
      type: SyncOpType.update,
      entityId: updated.id,
      payload: TaskDto.fromEntity(updated).toMap(),
      createdAt: DateTime.now(),
    ));
    await load();
  }

  Future<void> trashTask(String id) async {
    // Soft delete - moves to trash on server
    await _repo.deleteTask(id); // Remove from local view
    await _syncService.enqueue(SyncOperation(
      id: const Uuid().v4(),
      type: SyncOpType.trash, // Use trash operation, not delete
      entityId: id,
      createdAt: DateTime.now(),
    ));
    await load();
  }

  Future<void> deleteTask(String id) async {
    // Permanent delete
    await _repo.deleteTask(id);
    await _syncService.enqueue(SyncOperation(
      id: const Uuid().v4(),
      type: SyncOpType.delete,
      entityId: id,
      createdAt: DateTime.now(),
    ));
    await load();
  }

  Future<void> toggleStatus(TaskEntity task) async {
    final next = switch (task.status) {
      TaskStatus.todo => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };
    await updateTask(task.copyWith(status: next));
  }

  void setFilter(TaskStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final notifier = TaskListNotifier(
    ref.watch(taskRepositoryProvider),
    ref.watch(syncServiceProvider.notifier),
  );
  // Initial load
  notifier.load(forceRefresh: true);
  return notifier;
});
