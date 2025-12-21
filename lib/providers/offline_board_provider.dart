import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/operation/operation.dart';
import '../models/whiteboard_object/whiteboard_object.dart';
import 'app_providers.dart';

/// Offline Board State - Simple local-only collaboration
class OfflineBoardState {
  final String boardId;
  final String boardName;
  final String? userName;
  final List<Operation> operations;
  final List<WhiteboardObject> objects;
  final List<Map<String, dynamic>> tasks;
  final bool isLoading;
  final String? error;
  final DateTime lastSaved;

  OfflineBoardState({
    required this.boardId,
    required this.boardName,
    this.userName,
    this.operations = const [],
    this.objects = const [],
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    DateTime? lastSaved,
  }) : lastSaved = lastSaved ?? DateTime.now();

  OfflineBoardState copyWith({
    String? boardId,
    String? boardName,
    String? userName,
    List<Operation>? operations,
    List<WhiteboardObject>? objects,
    List<Map<String, dynamic>>? tasks,
    bool? isLoading,
    String? error,
    DateTime? lastSaved,
  }) {
    return OfflineBoardState(
      boardId: boardId ?? this.boardId,
      boardName: boardName ?? this.boardName,
      userName: userName ?? this.userName,
      operations: operations ?? this.operations,
      objects: objects ?? this.objects,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }
}

/// Offline Board Notifier - Manages local-only board state
class OfflineBoardNotifier extends StateNotifier<OfflineBoardState> {
  final Ref ref;
  final String boardId;

  OfflineBoardNotifier(this.ref, this.boardId)
      : super(OfflineBoardState(
          boardId: boardId,
          boardName: 'Offline Board',
          isLoading: true,
        )) {
    _initBoard();
  }

  Future<void> _initBoard() async {
    try {
      final storage = ref.read(storageServiceProvider);

      // Load operations from local storage
      final operations = storage.getOperations(boardId);

      // Reconstruct objects from operations
      final objects = <WhiteboardObject>[];

      for (final op in operations) {
        if (op.type == OperationType.createObject) {
          final objType = op.payload['type'] as String?;
          final objTypeEnum = _stringToObjectType(objType);
          
          objects.add(WhiteboardObject(
            id: op.payload['id'] as String,
            type: objTypeEnum,
            data: op.payload['data'] as Map<String, dynamic>? ?? {},
            createdBy: op.actor,
            createdAt: op.timestamp,
            updatedAt: op.timestamp,
          ));
        }
      }

      // Load board state
      final boardState = storage.getBoardState(boardId);
      final boardName = boardState?['name'] as String? ?? 'Offline Board';
      final userName = boardState?['userName'] as String?;
      final tasks = (boardState?['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      state = state.copyWith(
        boardName: boardName,
        userName: userName,
        operations: operations,
        objects: objects,
        tasks: tasks,
        isLoading: false,
      );

      debugPrint('✅ Offline board loaded: $boardName');
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      debugPrint('❌ Error loading offline board: $e');
    }
  }

  /// Convert string to WhiteboardObjectType
  WhiteboardObjectType _stringToObjectType(String? type) {
    switch (type) {
      case 'stroke':
        return WhiteboardObjectType.stroke;
      case 'task':
        return WhiteboardObjectType.task;
      case 'text':
        return WhiteboardObjectType.textBox;
      default:
        return WhiteboardObjectType.textBox;
    }
  }

  /// Create a new operation and save to local storage
  void createOperation(
    OperationType type,
    Map<String, dynamic> payload,
  ) {
    try {
      final storage = ref.read(storageServiceProvider);
      final username = storage.getOfflineUsername() ?? 'Guest';
      
      final operation = Operation(
        opId: payload['id'] as String? ?? 'op-${DateTime.now().millisecondsSinceEpoch}',
        actor: username,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: type,
        payload: payload,
      );

      // Save to storage
      storage.saveOperation(boardId, operation);

      // Update state based on operation type
      var updatedObjects = List<WhiteboardObject>.from(state.objects);
      
      if (type == OperationType.createObject) {
        final objType = payload['type'] as String?;
        final objTypeEnum = _stringToObjectType(objType);
        final now = DateTime.now().millisecondsSinceEpoch;
        
        updatedObjects.add(WhiteboardObject(
          id: payload['id'] as String,
          type: objTypeEnum,
          data: payload['data'] as Map<String, dynamic>? ?? {},
          createdBy: username,
          createdAt: now,
          updatedAt: now,
        ));
      } else if (type == OperationType.updateObject) {
        // Update existing object
        final objId = payload['id'] as String?;
        final objIndex = updatedObjects.indexWhere((obj) => obj.id == objId);
        
        if (objIndex >= 0) {
          final existing = updatedObjects[objIndex];
          final newData = Map<String, dynamic>.from(existing.data);
          newData.addAll(payload['data'] as Map<String, dynamic>? ?? {});
          
          updatedObjects[objIndex] = existing.copyWith(
            data: newData,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
      } else if (type == OperationType.deleteObject) {
        // Delete object
        final objId = payload['id'] as String?;
        updatedObjects.removeWhere((obj) => obj.id == objId);
      }

      state = state.copyWith(
        operations: [...state.operations, operation],
        objects: updatedObjects,
      );

      debugPrint('✅ Operation saved by $username: ${operation.opId}');
    } catch (e) {
      debugPrint('❌ Error creating operation: $e');
    }
  }

  /// Receive operation from another user (for local P2P sync)
  void receiveOperation(Operation operation) {
    try {
      final storage = ref.read(storageServiceProvider);
      storage.saveOperation(boardId, operation);

      // Update state based on operation type
      var updatedObjects = List<WhiteboardObject>.from(state.objects);
      var updatedTasks = List<Map<String, dynamic>>.from(state.tasks);
      
      if (operation.type == OperationType.createObject) {
        final objType = operation.payload['type'] as String?;
        
        // Check if it's a task
        if (objType == 'task') {
          final taskData = operation.payload['data'] as Map<String, dynamic>? ?? {};
          updatedTasks.add(taskData);
        } else {
          // Regular object (stroke, text)
          final objTypeEnum = _stringToObjectType(objType);
          
          updatedObjects.add(WhiteboardObject(
            id: operation.payload['id'] as String,
            type: objTypeEnum,
            data: operation.payload['data'] as Map<String, dynamic>? ?? {},
            createdBy: operation.actor,
            createdAt: operation.timestamp,
            updatedAt: operation.timestamp,
          ));
        }
      } else if (operation.type == OperationType.updateObject) {
        final objType = operation.payload['type'] as String?;
        
        if (objType == 'task') {
          // Update task
          final taskId = operation.payload['id'] as String?;
          final taskIndex = updatedTasks.indexWhere((t) => t['id'] == taskId);
          
          if (taskIndex >= 0) {
            final updatedData = operation.payload['data'] as Map<String, dynamic>? ?? {};
            updatedTasks[taskIndex] = {
              ...updatedTasks[taskIndex],
              ...updatedData,
            };
          }
        } else {
          // Update existing object
          final objId = operation.payload['id'] as String?;
          final objIndex = updatedObjects.indexWhere((obj) => obj.id == objId);
          
          if (objIndex >= 0) {
            final existing = updatedObjects[objIndex];
            final newData = Map<String, dynamic>.from(existing.data);
            newData.addAll(operation.payload['data'] as Map<String, dynamic>? ?? {});
            
            updatedObjects[objIndex] = existing.copyWith(
              data: newData,
              updatedAt: operation.timestamp,
            );
          }
        }
      } else if (operation.type == OperationType.deleteObject) {
        final objType = operation.payload['type'] as String?;
        
        if (objType == 'task') {
          // Delete task
          final taskId = operation.payload['id'] as String?;
          updatedTasks.removeWhere((t) => t['id'] == taskId);
        } else {
          // Delete object
          final objId = operation.payload['id'] as String?;
          updatedObjects.removeWhere((obj) => obj.id == objId);
        }
      }

      state = state.copyWith(
        operations: [...state.operations, operation],
        objects: updatedObjects,
        tasks: updatedTasks,
      );

      debugPrint('✅ Remote operation from ${operation.actor}: ${operation.opId}');
    } catch (e) {
      debugPrint('❌ Error receiving operation: $e');
    }
  }

  /// Apply operation received from P2P peer (alias for receiveOperation)
  void applyRemoteOperation(Operation operation) {
    receiveOperation(operation);
  }

  /// Create a task in offline mode
  void createTask({
    required String title,
    String? description,
    String status = 'todo',
    String priority = 'medium',
    String? assignee,
  }) {
    try {
      final taskId = 'task-${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      
      // Create task with proper structure
      final task = {
        'id': taskId,
        'boardId': boardId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'assignee': assignee,
        'assignees': assignee != null ? [assignee] : [],
        'assigneeList': assignee != null
            ? [
                {
                  'id': 'local-$assignee',
                  'name': assignee,
                  'email': null,
                  'avatar': null,
                }
              ]
            : [],
        'labels': [],
        'position': state.tasks.length,
        'createdBy': 'local-user',
        'creatorName': 'You',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final updatedTasks = [...state.tasks, task];

      // Save to storage
      final storage = ref.read(storageServiceProvider);
      final boardState = storage.getBoardState(boardId) ?? {};
      boardState['tasks'] = updatedTasks;
      storage.saveBoardState(boardId, boardState);

      state = state.copyWith(tasks: updatedTasks);

      // Also create an operation for P2P sync
      createOperation(
        OperationType.createObject,
        {
          'id': taskId,
          'type': 'task',
          'data': task,
        },
      );

      debugPrint('✅ Task created offline: $title (assigned: $assignee)');
    } catch (e) {
      debugPrint('❌ Error creating task: $e');
    }
  }

  /// Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      final updatedTasks = state.tasks.map((task) {
        if (task['id'] == taskId) {
          return {
            ...task, 
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          };
        }
        return task;
      }).toList();

      // Save to storage
      final storage = ref.read(storageServiceProvider);
      final boardState = storage.getBoardState(boardId) ?? {};
      boardState['tasks'] = updatedTasks;
      await storage.saveBoardState(boardId, boardState);

      state = state.copyWith(tasks: updatedTasks);

      debugPrint('✅ Task status updated: $taskId -> $newStatus');
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      final updatedTasks = state.tasks.where((t) => t['id'] != taskId).toList();

      // Save to storage
      final storage = ref.read(storageServiceProvider);
      final boardState = storage.getBoardState(boardId) ?? {};
      boardState['tasks'] = updatedTasks;
      await storage.saveBoardState(boardId, boardState);

      state = state.copyWith(tasks: updatedTasks);

      debugPrint('✅ Task deleted: $taskId');
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
    }
  }

  /// Update board name
  Future<void> updateBoardName(String newName) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final boardState = storage.getBoardState(boardId) ?? {};
      boardState['name'] = newName;
      await storage.saveBoardState(boardId, boardState);

      state = state.copyWith(boardName: newName);

      debugPrint('✅ Board name updated: $newName');
    } catch (e) {
      debugPrint('❌ Error updating board name: $e');
    }
  }

  /// Set username for this session
  Future<void> setUserName(String name) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final boardState = storage.getBoardState(boardId) ?? {};
      boardState['userName'] = name;
      await storage.saveBoardState(boardId, boardState);

      state = state.copyWith(userName: name);

      debugPrint('✅ Username set: $name');
    } catch (e) {
      debugPrint('❌ Error setting username: $e');
    }
  }

  /// Force persist all changes
  Future<void> persistAll() async {
    try {
      final storage = ref.read(storageServiceProvider);
      
      // Save all operations
      storage.saveOperations(boardId, state.operations);
      
      // Save board state
      final boardState = storage.getBoardState(boardId) ?? {};
      boardState['name'] = state.boardName;
      boardState['userName'] = state.userName;
      boardState['tasks'] = state.tasks;
      boardState['lastUpdated'] = DateTime.now().toIso8601String();
      await storage.saveBoardState(boardId, boardState);

      state = state.copyWith(lastSaved: DateTime.now());

      debugPrint('✅ All data persisted');
    } catch (e) {
      debugPrint('❌ Error persisting data: $e');
    }
  }

  /// Clear all data
  Future<void> clearBoard() async {
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.clearBoardOperations(boardId);

      state = state.copyWith(
        operations: [],
        objects: [],
        tasks: [],
      );

      debugPrint('✅ Board cleared');
    } catch (e) {
      debugPrint('❌ Error clearing board: $e');
    }
  }
}

/// Provider for offline board
final offlineBoardProvider = StateNotifierProvider.family<
    OfflineBoardNotifier,
    OfflineBoardState,
    String>((ref, boardId) {
  return OfflineBoardNotifier(ref, boardId);
});

/// Get strokes from objects
List<Map<String, dynamic>> extractStrokes(List<WhiteboardObject> objects) {
  return objects
      .where((obj) => obj.type == 'stroke')
      .map((obj) => {
            'id': obj.id,
            'type': 'stroke',
            'points': obj.data['points'] as List? ?? [],
            'color': obj.data['color'] as int? ?? 0xFF000000,
            'width': obj.data['width'] as double? ?? 3.0,
            'actor': obj.data['actor'] as String? ?? 'unknown',
            'actorName': obj.data['actorName'] as String? ?? 'Unknown',
            'isEraser': obj.data['isEraser'] as bool? ?? false,
          })
      .toList();
}

/// Get texts from objects
List<Map<String, dynamic>> extractTexts(List<WhiteboardObject> objects) {
  return objects
      .where((obj) => obj.type == 'text')
      .map((obj) => {
            'id': obj.id,
            'type': 'text',
            'text': obj.data['text'] as String? ?? '',
            'position': obj.data['position'] as List? ?? [0, 0],
            'color': obj.data['color'] as int? ?? 0xFF000000,
            'fontSize': obj.data['fontSize'] as double? ?? 16.0,
            'actor': obj.data['actor'] as String? ?? 'unknown',
            'actorName': obj.data['actorName'] as String? ?? 'Unknown',
          })
      .toList();
}
