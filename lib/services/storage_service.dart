import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/operation/operation.dart';

class StorageService {
  static const String _authBoxName = 'auth';
  static const String _boardsBoxName = 'boards';
  static const String _operationsBoxName = 'operations';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();

  Box? _authBox;
  Box? _boardsBox;
  Box? _operationsBox;

  // Private constructor
  StorageService._internal();

  // Factory constructor
  factory StorageService() {
    return _instance;
  }

  Future<void> init() async {
    // Skip if already initialized
    if (_authBox != null && _boardsBox != null && _operationsBox != null) {
      debugPrint('✅ Storage already initialized');
      return;
    }

    await Hive.initFlutter();
    
    _authBox = await Hive.openBox(_authBoxName);
    _boardsBox = await Hive.openBox(_boardsBoxName);
    _operationsBox = await Hive.openBox(_operationsBoxName);

    debugPrint('✅ Storage initialized');
  }

  // Auth persistence
  Future<void> saveAuthToken(String token) async {
    if (_authBox == null) return;
    await _authBox!.put('token', token);
  }

  String? getAuthToken() {
    return _authBox?.get('token');
  }

  Future<void> saveRefreshToken(String? token) async {
    if (_authBox == null) return;
    if (token == null) {
      await _authBox!.delete('refreshToken');
    } else {
      await _authBox!.put('refreshToken', token);
    }
  }

  Future<String?> getRefreshToken() async {
    return _authBox?.get('refreshToken');
  }

  Future<void> saveUserId(String userId) async {
    if (_authBox == null) return;
    await _authBox!.put('userId', userId);
  }

  String? getUserId() {
    return _authBox?.get('userId');
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    if (_authBox == null) return;
    await _authBox!.put('user', json.encode(user));
  }

  Map<String, dynamic>? getUser() {
    final data = _authBox?.get('user');
    if (data == null) return null;
    return json.decode(data);
  }

  Future<void> saveLastWorkspace(String? workspaceId) async {
    if (_authBox == null) return;
    if (workspaceId == null) {
      await _authBox!.delete('lastWorkspaceId');
    } else {
      await _authBox!.put('lastWorkspaceId', workspaceId);
    }
  }

  String? getLastWorkspace() {
    return _authBox?.get('lastWorkspaceId');
  }

  // Offline username
  Future<void> saveOfflineUsername(String username) async {
    if (_authBox == null) return;
    await _authBox!.put('offlineUsername', username);
  }

  String? getOfflineUsername() {
    return _authBox?.get('offlineUsername');
  }

  Future<void> clearOfflineUsername() async {
    if (_authBox == null) return;
    await _authBox!.delete('offlineUsername');
  }

  /// Clear authentication data but preserve offline username
  Future<void> clearAuth() async {
    if (_authBox == null) return;
    
    debugPrint('🔄 Clearing auth data...');
    debugPrint('   Before clear - keys: ${_authBox!.keys.toList()}');
    
    // Save offline username before clearing
    final offlineUsername = _authBox!.get('offlineUsername');
    debugPrint('   Saved offline username: $offlineUsername');
    
    // Clear all auth data (removes token, refreshToken, userId, user, lastWorkspaceId, everything)
    await _authBox!.clear();
    debugPrint('   After clear - keys: ${_authBox!.keys.toList()}');
    
    // Restore offline username if it existed
    if (offlineUsername != null) {
      await _authBox!.put('offlineUsername', offlineUsername);
      debugPrint('   Restored offline username: $offlineUsername');
    }
    
    debugPrint('   Final keys: ${_authBox!.keys.toList()}');
    debugPrint('✅ Auth cleared - only offlineUsername preserved');
  }

  // Board state persistence
  Future<void> saveBoardState(String boardId, Map<String, dynamic> state) async {
    if (_boardsBox == null) return;
    await _boardsBox!.put(boardId, json.encode(state));
  }

  Map<String, dynamic>? getBoardState(String boardId) {
    final data = _boardsBox?.get(boardId);
    if (data == null) return null;
    return json.decode(data);
  }

  /// Get all board IDs from storage
  List<String> getAllBoardIds() {
    if (_boardsBox == null) return [];
    return _boardsBox!.keys.map((key) => key.toString()).toList();
  }

  /// Find boardId by share code (first 8 chars of boardId)
  String? getBoardIdByCode(String code) {
    if (_boardsBox == null) {
      debugPrint('❌ Boards box is null');
      return null;
    }
    
    debugPrint('🔎 Looking for code: $code in ${_boardsBox!.keys.length} boards');
    
    for (final key in _boardsBox!.keys) {
      final boardId = key.toString();
      final boardCode = boardId.substring(0, 8).toUpperCase();
      debugPrint('   Checking: $boardCode (boardId: $boardId)');
      
      if (boardCode == code.toUpperCase()) {
        debugPrint('   ✅ MATCH FOUND!');
        return boardId;
      }
    }
    
    debugPrint('   ❌ No match found');
    return null;
  }

  // Operation log persistence
  Future<void> saveOperation(String boardId, Operation operation) async {
    if (_operationsBox == null) return;
    final key = '${boardId}_${operation.opId}';
    await _operationsBox!.put(key, json.encode(operation.toJson()));
  }

  Future<void> saveOperations(String boardId, List<Operation> operations) async {
    for (final op in operations) {
      await saveOperation(boardId, op);
    }
  }

  List<Operation> getOperations(String boardId) {
    if (_operationsBox == null) return [];
    final operations = <Operation>[];
    
    for (final key in _operationsBox!.keys) {
      if (key.toString().startsWith('${boardId}_')) {
        try {
          final data = json.decode(_operationsBox!.get(key));
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
    if (_operationsBox == null) return;
    final keysToDelete = <String>[];
    
    for (final key in _operationsBox!.keys) {
      if (key.toString().startsWith('${boardId}_')) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await _operationsBox!.delete(key);
    }
  }

  Future<void> clearAll() async {
    if (_authBox != null) await _authBox!.clear();
    if (_boardsBox != null) await _boardsBox!.clear();
    if (_operationsBox != null) await _operationsBox!.clear();
  }

  // Offline queue for pending operations
  Future<void> queueOfflineOperation(String boardId, Operation operation) async {
    if (_operationsBox == null) return;
    final key = 'pending_${boardId}_${operation.opId}';
    await _operationsBox!.put(key, json.encode(operation.toJson()));
  }

  List<Operation> getPendingOperations(String boardId) {
    if (_operationsBox == null) return [];
    final operations = <Operation>[];
    
    for (final key in _operationsBox!.keys) {
      if (key.toString().startsWith('pending_${boardId}_')) {
        try {
          final data = json.decode(_operationsBox!.get(key));
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
    if (_operationsBox == null) return;
    final key = 'pending_${boardId}_$opId';
    await _operationsBox!.delete(key);
  }

  Future<void> clearAllPendingOperations(String boardId) async {
    if (_operationsBox == null) return;
    final keysToDelete = <String>[];
    
    for (final key in _operationsBox!.keys) {
      if (key.toString().startsWith('pending_${boardId}_')) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await _operationsBox!.delete(key);
    }
  }
}
