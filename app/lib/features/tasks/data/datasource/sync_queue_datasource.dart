import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../models/sync_operation.dart';

/// Persists pending sync operations in Hive.
class SyncQueueDataSource {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.syncQueue);

  List<SyncOperation> getAll() {
    return _box.values.map((m) => SyncOperation.fromMap(m)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> add(SyncOperation op) async {
    await _box.put(op.id, op.toMap());
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  int get length => _box.length;
}
