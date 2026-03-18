import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/hive_boxes.dart';
import '../data/datasource/sync_queue_datasource.dart';
import '../data/datasource/task_local_datasource.dart';
import '../data/datasource/task_remote_datasource.dart';
import '../data/dto/task_dto.dart';
import '../data/models/sync_operation.dart';

// ── Sync state ─────────────────────────────────────────────
class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingCount;
  final String? lastError;

  const SyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingCount = 0,
    this.lastError,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingCount,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

// ── Providers ──────────────────────────────────────────────
final syncQueueDataSourceProvider = Provider<SyncQueueDataSource>((ref) {
  return SyncQueueDataSource();
});

final syncServiceProvider = StateNotifierProvider<SyncServiceNotifier, SyncState>((ref) {
  return SyncServiceNotifier(
    remote: TaskRemoteDataSource(ref.watch(dioProvider)),
    local: TaskLocalDataSource(),
    queue: ref.watch(syncQueueDataSourceProvider),
  );
});

// ── Sync service notifier ──────────────────────────────────
class SyncServiceNotifier extends StateNotifier<SyncState> {
  final TaskRemoteDataSource remote;
  final TaskLocalDataSource local;
  final SyncQueueDataSource queue;
  Timer? _timer;

  SyncServiceNotifier({
    required this.remote,
    required this.local,
    required this.queue,
  }) : super(SyncState(
          pendingCount: SyncQueueDataSource().length,
          lastSyncTime: _loadLastSync(),
        )) {
    // Periodic background sync every 30s.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => sync());
  }

  static DateTime? _loadLastSync() {
    final raw = Hive.box(HiveBoxes.settings).get('lastSyncTime') as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Enqueue a pending operation.
  Future<void> enqueue(SyncOperation op) async {
    await queue.add(op);
    state = state.copyWith(pendingCount: queue.length);
  }

  /// Process the queue + pull fresh data from server.
  Future<void> sync() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // 1. Push pending operations.
      final ops = queue.getAll();
      for (final op in ops) {
        try {
          switch (op.type) {
            case SyncOpType.create:
              await remote.createTask(TaskDto.fromMap(op.payload!));
              break;
            case SyncOpType.update:
              await remote.updateTask(TaskDto.fromMap(op.payload!));
              break;
            case SyncOpType.delete:
              await remote.deleteTask(op.entityId);
              break;
          }
          await queue.remove(op.id);
        } on DioException catch (e) {
          // 404 on delete means already gone, safe to remove
          if (op.type == SyncOpType.delete && e.response?.statusCode == 404) {
            await queue.remove(op.id);
            continue;
          }
          debugPrint('Sync op failed: ${op.id} – ${e.message}');
          // Stop processing remaining ops when server is unreachable
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            break;
          }
        }
      }

      // 2. Pull fresh data (last-write-wins: server data replaces local).
      try {
        final remoteTasks = await remote.fetchTasks();
        await local.replaceAll(remoteTasks);
      } catch (_) {
        // If pull fails, keep local data as-is.
      }

      final now = DateTime.now();
      Hive.box(HiveBoxes.settings).put('lastSyncTime', now.toIso8601String());
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: now,
        pendingCount: queue.length,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
        pendingCount: queue.length,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
