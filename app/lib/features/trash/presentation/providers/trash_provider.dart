import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../tasks/data/datasource/task_remote_datasource.dart';
import '../../../tasks/domain/entities/task_entity.dart';

// ── DI ─────────────────────────────────────────────────────

final trashRemoteProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(ref.watch(dioProvider));
});

// ── Trash State ────────────────────────────────────────────

class TrashState {
  final List<TaskEntity> tasks;
  final bool isLoading;
  final String? error;

  const TrashState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  TrashState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrashState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Trash Notifier ─────────────────────────────────────────

class TrashNotifier extends StateNotifier<TrashState> {
  final TaskRemoteDataSource _remote;

  TrashNotifier(this._remote) : super(const TrashState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final dtos = await _remote.fetchTrash();
      final entities = dtos.map((d) => d.toEntity()).toList();
      state = state.copyWith(tasks: entities, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> restoreTask(String id) async {
    try {
      await _remote.restoreTask(id);
      // Remove from local trash list
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> permanentlyDelete(String id) async {
    try {
      await _remote.deleteTask(id);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<int> emptyTrash() async {
    try {
      final count = await _remote.emptyTrash();
      state = state.copyWith(tasks: []);
      return count;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }
}

// ── Provider ───────────────────────────────────────────────

final trashProvider = StateNotifierProvider<TrashNotifier, TrashState>((ref) {
  final remote = ref.watch(trashRemoteProvider);
  return TrashNotifier(remote);
});
