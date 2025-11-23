import '../models/operation.dart';
import '../models/whiteboard_object.dart';
import 'package:uuid/uuid.dart';

class SyncEngine {
  final String userId;
  final Function(Operation)? onOperationApplied;
  final Function(Operation)? onOperationBroadcast;

  // Operation log with deduplication
  final Set<String> _appliedOpIds = {};
  final List<Operation> _operationLog = [];
  
  // Object registry
  final Map<String, WhiteboardObject> _objects = {};

  SyncEngine({
    required this.userId,
    this.onOperationApplied,
    this.onOperationBroadcast,
  });

  final _uuid = const Uuid();

  // Create and broadcast a new operation
  Operation createOperation({
    required OperationType type,
    required Map<String, dynamic> payload,
  }) {
    final operation = Operation(
      opId: _uuid.v4(),
      actor: userId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: type,
      payload: payload,
    );

    // Apply locally
    _applyOperation(operation);

    // Broadcast to peers
    onOperationBroadcast?.call(operation);

    return operation;
  }

  // Receive operation from peer or offline queue
  void receiveOperation(Operation operation) {
    // Deduplicate
    if (_appliedOpIds.contains(operation.opId)) {
      print('⏭️  Skipping duplicate operation: ${operation.opId}');
      return;
    }

    _applyOperation(operation);
  }

  void _applyOperation(Operation operation) {
    // Already applied?
    if (_appliedOpIds.contains(operation.opId)) {
      return;
    }

    print('⚡ Applying operation: ${operation.type} by ${operation.actor}');

    switch (operation.type) {
      case OperationType.createObject:
        _handleCreateObject(operation);
        break;
      case OperationType.updateObject:
        _handleUpdateObject(operation);
        break;
      case OperationType.deleteObject:
        _handleDeleteObject(operation);
        break;
      case OperationType.moveObject:
        _handleMoveObject(operation);
        break;
      case OperationType.resizeObject:
        _handleResizeObject(operation);
        break;
    }

    // Mark as applied
    _appliedOpIds.add(operation.opId);
    _operationLog.add(operation.copyWith(applied: true));

    onOperationApplied?.call(operation);
  }

  void _handleCreateObject(Operation operation) {
    final object = WhiteboardObject.fromJson(operation.payload);
    _objects[object.id] = object;
  }

  void _handleUpdateObject(Operation operation) {
    final objectId = operation.payload['id'] as String;
    final existing = _objects[objectId];

    if (existing == null) {
      print('⚠️  Object not found for update: $objectId');
      return;
    }

    // Last-Write-Wins (LWW) conflict resolution
    if (operation.timestamp < existing.updatedAt) {
      print('⏭️  Skipping outdated update for $objectId');
      return;
    }

    final updated = WhiteboardObject.fromJson(operation.payload);
    _objects[objectId] = updated;
  }

  void _handleDeleteObject(Operation operation) {
    final objectId = operation.payload['id'] as String;
    _objects.remove(objectId);
  }

  void _handleMoveObject(Operation operation) {
    final objectId = operation.payload['id'] as String;
    final existing = _objects[objectId];

    if (existing == null) return;

    // LWW
    if (operation.timestamp < existing.updatedAt) {
      return;
    }

    final updatedData = Map<String, dynamic>.from(existing.data);
    updatedData['position'] = operation.payload['position'];

    _objects[objectId] = existing.copyWith(
      data: updatedData,
      updatedAt: operation.timestamp,
    );
  }

  void _handleResizeObject(Operation operation) {
    final objectId = operation.payload['id'] as String;
    final existing = _objects[objectId];

    if (existing == null) return;

    // LWW
    if (operation.timestamp < existing.updatedAt) {
      return;
    }

    final updatedData = Map<String, dynamic>.from(existing.data);
    updatedData['size'] = operation.payload['size'];

    _objects[objectId] = existing.copyWith(
      data: updatedData,
      updatedAt: operation.timestamp,
    );
  }

  // Public API
  List<WhiteboardObject> get objects => _objects.values.toList();
  
  WhiteboardObject? getObject(String id) => _objects[id];

  List<Operation> get operationLog => List.unmodifiable(_operationLog);

  List<Operation> getUnappliedOperations() {
    return _operationLog.where((op) => !op.applied).toList();
  }

  void loadOperations(List<Operation> operations) {
    // Sort by timestamp for deterministic replay
    final sorted = List<Operation>.from(operations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final op in sorted) {
      receiveOperation(op);
    }
  }

  void clear() {
    _objects.clear();
    _appliedOpIds.clear();
    _operationLog.clear();
  }

  Map<String, dynamic> getState() {
    return {
      'objects': _objects.values.map((o) => o.toJson()).toList(),
      'operations': _operationLog.map((o) => o.toJson()).toList(),
    };
  }
}
