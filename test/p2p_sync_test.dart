import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/core/sync_engine.dart';
import 'package:peertask/models/operation/operation.dart';

void main() {
  group('SyncEngine P2P Tests', () {
    late SyncEngine syncEngineA;
    late SyncEngine syncEngineB;
    
    final List<Operation> broadcastedFromA = [];
    final List<Operation> broadcastedFromB = [];
    
    setUp(() {
      broadcastedFromA.clear();
      broadcastedFromB.clear();
      
      // Simulate two peers
      syncEngineA = SyncEngine(
        userId: 'user-a',
        onOperationBroadcast: (op) {
          broadcastedFromA.add(op);
          // Simulate P2P: Send to peer B
          syncEngineB.receiveOperation(op);
        },
      );
      
      syncEngineB = SyncEngine(
        userId: 'user-b',
        onOperationBroadcast: (op) {
          broadcastedFromB.add(op);
          // Simulate P2P: Send to peer A
          syncEngineA.receiveOperation(op);
        },
      );
    });

    test('Should sync create operation between peers', () {
      // User A creates a stroke
      final opA = syncEngineA.createOperation(
        type: OperationType.createObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {
            'points': [10.0, 20.0, 30.0, 40.0],
            'color': 0xFF000000,
            'strokeWidth': 3.0,
          },
        },
      );

      // Verify A broadcasted the operation
      expect(broadcastedFromA.length, 1);
      expect(broadcastedFromA.first.opId, opA.opId);
      
      // Verify B has the same operation log
      expect(syncEngineA.operationLog.length, 1);
      expect(syncEngineB.operationLog.length, 1);
      expect(syncEngineB.operationLog.first.opId, opA.opId);
    });

    test('Should handle bidirectional sync', () {
      // User A creates stroke-1
      syncEngineA.createOperation(
        type: OperationType.createObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {'points': [0.0, 0.0]},
        },
      );

      // User B creates stroke-2
      syncEngineB.createOperation(
        type: OperationType.createObject,
        payload: {
          'id': 'stroke-2',
          'type': 'stroke',
          'data': {'points': [10.0, 10.0]},
        },
      );

      // Both should have 2 operations
      expect(syncEngineA.operationLog.length, 2);
      expect(syncEngineB.operationLog.length, 2);
      
      // Both should have same opIds (order might differ)
      final opIdsA = syncEngineA.operationLog.map((op) => op.opId).toSet();
      final opIdsB = syncEngineB.operationLog.map((op) => op.opId).toSet();
      expect(opIdsA, equals(opIdsB));
    });

    test('Should deduplicate operations', () {
      // User A creates operation
      final op = syncEngineA.createOperation(
        type: OperationType.createObject,
        payload: {'id': 'stroke-1', 'type': 'stroke'},
      );

      // Simulate duplicate receive (network retry)
      syncEngineB.receiveOperation(op);
      syncEngineB.receiveOperation(op);
      syncEngineB.receiveOperation(op);

      // Should only apply once
      expect(syncEngineB.operationLog.length, 1);
    });

    test('Should apply Last-Write-Wins (LWW) conflict resolution', () {
      // User A creates stroke
      final createOp = syncEngineA.createOperation(
        type: OperationType.createObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {'points': [0.0, 0.0]},
          'zIndex': 0,
          'version': 0,
          'createdBy': 'user-a',
          'createdAt': 1000,
          'updatedAt': 1000,
        },
      );

      // Wait to ensure timestamp difference
      Future.delayed(const Duration(milliseconds: 10));

      // User A updates (newer timestamp)
      final updateOp = syncEngineA.createOperation(
        type: OperationType.updateObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {'points': [0.0, 0.0, 10.0, 10.0]},
          'zIndex': 0,
          'version': 1,
          'createdBy': 'user-a',
          'createdAt': 1000,
          'updatedAt': 2000,
        },
      );

      // Try to apply old update (should be ignored by LWW)
      final oldUpdate = Operation(
        opId: 'old-update',
        actor: 'user-b',
        timestamp: 500, // Older timestamp
        type: OperationType.updateObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {'points': [5.0, 5.0]},
        },
      );

      syncEngineA.receiveOperation(oldUpdate);

      // Should have create + new update, ignore old update
      expect(syncEngineA.operationLog.length, 3); // create, update, oldUpdate (logged but not applied)
    });

    test('Should handle update before create (out-of-order)', () {
      // Simulate network delay: update arrives before create
      final updateOp = Operation(
        opId: 'update-1',
        actor: 'user-a',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: OperationType.updateObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {'points': [10.0, 10.0]},
        },
      );

      syncEngineB.receiveOperation(updateOp);

      // Should log warning but not crash
      expect(syncEngineB.operationLog.length, 1);
      
      // Now create arrives
      final createOp = Operation(
        opId: 'create-1',
        actor: 'user-a',
        timestamp: DateTime.now().millisecondsSinceEpoch - 1000,
        type: OperationType.createObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {'points': [0.0, 0.0]},
        },
      );

      syncEngineB.receiveOperation(createOp);
      
      // Both operations should be logged
      expect(syncEngineB.operationLog.length, 2);
    });

    test('Should handle delete operation', () {
      // Create stroke
      syncEngineA.createOperation(
        type: OperationType.createObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {'points': [0.0, 0.0]},
        },
      );

      expect(syncEngineA.operationLog.length, 1);
      expect(syncEngineB.operationLog.length, 1);

      // Delete stroke
      syncEngineA.createOperation(
        type: OperationType.deleteObject,
        payload: {'id': 'stroke-1'},
      );

      expect(syncEngineA.operationLog.length, 2);
      expect(syncEngineB.operationLog.length, 2);
      
      // Verify delete operation exists
      final deleteOp = syncEngineB.operationLog.last;
      expect(deleteOp.type, OperationType.deleteObject);
      expect(deleteOp.payload['id'], 'stroke-1');
    });

    test('Should load operations from backend', () {
      final backendOps = [
        Operation(
          opId: 'op-1',
          actor: 'user-backend',
          timestamp: 1000,
          type: OperationType.createObject,
          payload: {'id': 'stroke-1', 'type': 'stroke'},
        ),
        Operation(
          opId: 'op-2',
          actor: 'user-backend',
          timestamp: 2000,
          type: OperationType.createObject,
          payload: {'id': 'stroke-2', 'type': 'stroke'},
        ),
      ];

      syncEngineA.loadOperations(backendOps);

      expect(syncEngineA.operationLog.length, 2);
      expect(syncEngineA.operationLog[0].opId, 'op-1');
      expect(syncEngineA.operationLog[1].opId, 'op-2');
    });
  });

  group('Operation Serialization Tests', () {
    test('Should serialize and deserialize operation', () {
      final op = Operation(
        opId: 'test-op',
        actor: 'user-123',
        timestamp: 1234567890,
        type: OperationType.createObject,
        payload: {
          'id': 'stroke-1',
          'type': 'stroke',
          'data': {
            'points': [10.0, 20.0, 30.0, 40.0],
            'color': 0xFF000000,
            'strokeWidth': 3.0,
          },
        },
      );

      final json = op.toJson();
      final restored = Operation.fromJson(json);

      expect(restored.opId, op.opId);
      expect(restored.actor, op.actor);
      expect(restored.timestamp, op.timestamp);
      expect(restored.type, op.type);
      expect(restored.payload['id'], op.payload['id']);
    });
  });
}
