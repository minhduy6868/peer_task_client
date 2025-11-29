import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/operation/operation.dart';

class StorageService {
  static const String _authBoxName = 'auth';
  static const String _boardsBoxName = 'boards';
  static const String _operationsBoxName = 'operations';

  late Box _authBox;
  late Box _boardsBox;
  late Box _operationsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    _authBox = await Hive.openBox(_authBoxName);
    _boardsBox = await Hive.openBox(_boardsBoxName);
    _operationsBox = await Hive.openBox(_operationsBoxName);

    debugPrint('✅ Storage initialized');
  }

  // Auth persistence
  Future<void> saveAuthToken(String token) async {
    await _authBox.put('token', token);
  }

  String? getAuthToken() {
    return _authBox.get('token');
  }

  Future<void> saveRefreshToken(String? token) async {
    if (token == null) {
      await _authBox.delete('refreshToken');
    } else {
      await _authBox.put('refreshToken', token);
    }
  }

  Future<String?> getRefreshToken() async {
    return _authBox.get('refreshToken');
  }

  Future<void> saveUserId(String userId) async {
    await _authBox.put('userId', userId);
  }

  String? getUserId() {
    return _authBox.get('userId');
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _authBox.put('user', json.encode(user));
  }

  Map<String, dynamic>? getUser() {
    final data = _authBox.get('user');
    if (data == null) return null;
    return json.decode(data);
  }

  Future<void> saveLastWorkspace(String? workspaceId) async {
    if (workspaceId == null) {
      await _authBox.delete('lastWorkspaceId');
    } else {
      await _authBox.put('lastWorkspaceId', workspaceId);
    }
  }

  String? getLastWorkspace() {
    return _authBox.get('lastWorkspaceId');
  }

  Future<void> clearAuth() async {
    await _authBox.clear();
  }

  // Board state persistence
  Future<void> saveBoardState(String boardId, Map<String, dynamic> state) async {
    await _boardsBox.put(boardId, json.encode(state));
  }

  Map<String, dynamic>? getBoardState(String boardId) {
    final data = _boardsBox.get(boardId);
    if (data == null) return null;
    return json.decode(data);
  }

  // Operation log persistence
  Future<void> saveOperation(String boardId, Operation operation) async {
    final key = '${boardId}_${operation.opId}';
    await _operationsBox.put(key, json.encode(operation.toJson()));
  }

  Future<void> saveOperations(String boardId, List<Operation> operations) async {
    for (final op in operations) {
      await saveOperation(boardId, op);
    }
  }

  List<Operation> getOperations(String boardId) {
    final operations = <Operation>[];
    
    for (final key in _operationsBox.keys) {
      if (key.toString().startsWith('${boardId}_')) {
        try {
          final data = json.decode(_operationsBox.get(key));
          operations.add(Operation.fromJson(data));
        } catch (e) {
          print('Error loading operation $key: $e');
        }
      }
    }

    // Sort by timestamp
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  Future<void> clearBoardOperations(String boardId) async {
    final keysToDelete = <String>[];
    
    for (final key in _operationsBox.keys) {
      if (key.toString().startsWith('${boardId}_')) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await _operationsBox.delete(key);
    }
  }

  Future<void> clearAll() async {
    await _authBox.clear();
    await _boardsBox.clear();
    await _operationsBox.clear();
  }

  // Offline queue for pending operations
  Future<void> queueOfflineOperation(String boardId, Operation operation) async {
    final key = 'pending_${boardId}_${operation.opId}';
    await _operationsBox.put(key, json.encode(operation.toJson()));
  }

  List<Operation> getPendingOperations(String boardId) {
    final operations = <Operation>[];
    
    for (final key in _operationsBox.keys) {
      if (key.toString().startsWith('pending_${boardId}_')) {
        try {
          final data = json.decode(_operationsBox.get(key));
          operations.add(Operation.fromJson(data));
        } catch (e) {
          print('Error loading pending operation $key: $e');
        }
      }
    }

    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  Future<void> clearPendingOperation(String boardId, String opId) async {
    final key = 'pending_${boardId}_$opId';
    await _operationsBox.delete(key);
  }

  Future<void> clearAllPendingOperations(String boardId) async {
    final keysToDelete = <String>[];
    
    for (final key in _operationsBox.keys) {
      if (key.toString().startsWith('pending_${boardId}_')) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await _operationsBox.delete(key);
    }
  }
}
