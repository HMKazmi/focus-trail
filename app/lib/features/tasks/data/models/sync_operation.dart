/// Represents a pending operation to sync with the server.
class SyncOperation {
  final String id;
  final SyncOpType type;
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.entityId,
    this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'entityId': entityId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncOperation.fromMap(Map map) {
    final m = Map<String, dynamic>.from(map);
    return SyncOperation(
      id: m['id'] as String,
      type: SyncOpType.values.firstWhere((e) => e.name == m['type']),
      entityId: m['entityId'] as String,
      payload: m['payload'] != null ? Map<String, dynamic>.from(m['payload'] as Map) : null,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
}

enum SyncOpType { create, update, delete }
