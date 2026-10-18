import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/operation/operation.dart';

class StorageService {
  static const String _authBoxName = 'auth';
  static const String _boardsBoxName = 'boards';
  static const String _operationsBoxName = 'operations';
  static const String _settingsBoxName = 'settings';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();

  Box? _authBox;
  Box? _boardsBox;
  Box? _operationsBox;
  Box? _settingsBox;

  // Private constructor
  StorageService._internal();

  // Factory constructor
  factory StorageService() {
    return _instance;
  }

  Future<void> init() async {
    // Skip if already initialized
    if (_authBox != null && _boardsBox != null && _operationsBox != null && _settingsBox != null) {
      debugPrint('✅ Storage already initialized');
      return;
    }

    await Hive.initFlutter();

    _authBox = await _open(_authBoxName);
    _boardsBox = await _open(_boardsBoxName);
    _operationsBox = await _open(_operationsBoxName);
    _settingsBox = await _open(_settingsBoxName);

    debugPrint('✅ Storage initialized');
  }

  /// Opens a box, falling back to an in-memory box when the browser refuses
  /// IndexedDB (private mode, blocked storage, corrupted database).
  static Future<Box> _open(String name) async {
    try {
      return await Hive.openBox(name);
    } catch (e) {
      debugPrint('⚠️ Could not open box $name, using memory: $e');
      return Hive.openBox(name, bytes: Uint8List(0));
    }
  }

  Box? _boxNamed(String name) {
    switch (name) {
      case _authBoxName:
        return _authBox;
      case _boardsBoxName:
        return _boardsBox;
      case _operationsBoxName:
        return _operationsBox;
      default:
        return _settingsBox;
    }
  }

  Future<Box> _reopen(String name) async {
    try {
      await _boxNamed(name)?.close();
    } catch (_) {}
    final box = await _open(name);
    switch (name) {
      case _authBoxName:
        _authBox = box;
      case _boardsBoxName:
        _boardsBox = box;
      case _operationsBoxName:
        _operationsBox = box;
      default:
        _settingsBox = box;
    }
    return box;
  }

  /// Runs a write against [name]. Many callers fire and forget, so this never
  /// throws: a failed IndexedDB transaction (closed connection, another tab
  /// upgrading the database) reopens the box and retries once.
  Future<void> _write(String name, Future<void> Function(Box box) op) async {
    final box = _boxNamed(name);
    if (box == null) return;
    try {
      await op(box);
    } catch (e) {
      debugPrint('⚠️ Storage write to $name failed, reopening: $e');
      try {
        await op(await _reopen(name));
      } catch (e) {
        debugPrint('❌ Storage write to $name failed: $e');
      }
    }
  }

  // Language preference persistence
  Future<void> saveLanguage(String languageCode) async {
    await _write(_settingsBoxName, (box) => box.put('language', languageCode));
  }

  String? getLanguage() {
    return _settingsBox?.get('language') as String?;
  }

  // Auth persistence
  Future<void> saveAuthToken(String token) async {
    await _write(_authBoxName, (box) => box.put('token', token));
  }

  String? getAuthToken() {
    return _authBox?.get('token');
  }

  Future<void> saveRefreshToken(String? token) async {
    await _write(
      _authBoxName,
      (box) => token == null
          ? box.delete('refreshToken')
          : box.put('refreshToken', token),
    );
  }

  Future<String?> getRefreshToken() async {
    return _authBox?.get('refreshToken');
  }

  Future<void> saveUserId(String userId) async {
    await _write(_authBoxName, (box) => box.put('userId', userId));
  }

  String? getUserId() {
    return _authBox?.get('userId');
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _write(_authBoxName, (box) => box.put('user', json.encode(user)));
  }

  Map<String, dynamic>? getUser() {
    final data = _authBox?.get('user');
    if (data == null) return null;
    return json.decode(data);
  }

  Future<void> saveLastWorkspace(String? workspaceId) async {
    await _write(
      _authBoxName,
      (box) => workspaceId == null
          ? box.delete('lastWorkspaceId')
          : box.put('lastWorkspaceId', workspaceId),
    );
  }

  String? getLastWorkspace() {
    return _authBox?.get('lastWorkspaceId');
  }

  // Offline username
  Future<void> saveOfflineUsername(String username) async {
    await _write(_authBoxName, (box) => box.put('offlineUsername', username));
  }

  String? getOfflineUsername() {
    return _authBox?.get('offlineUsername');
  }

  Future<void> clearOfflineUsername() async {
    await _write(_authBoxName, (box) => box.delete('offlineUsername'));
  }

  /// Clear authentication data but preserve offline username
  Future<void> clearAuth() async {
    if (_authBox == null) return;

    final offlineUsername = _authBox!.get('offlineUsername');
    await _write(_authBoxName, (box) async {
      await box.clear();
      if (offlineUsername != null) {
        await box.put('offlineUsername', offlineUsername);
      }
    });
    debugPrint('✅ Auth cleared - only offlineUsername preserved');
  }

  // Board state persistence
  Future<void> saveBoardState(String boardId, Map<String, dynamic> state) async {
    await _write(_boardsBoxName, (box) => box.put(boardId, json.encode(state)));
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
    final key = '${boardId}_${operation.opId}';
    await _write(
      _operationsBoxName,
      (box) => box.put(key, json.encode(operation.toJson())),
    );
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
          debugPrint('Error loading operation $key: $e');
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

    await _write(_operationsBoxName, (box) => box.deleteAll(keysToDelete));
  }

  Future<void> clearAll() async {
    await _write(_authBoxName, (box) => box.clear());
    await _write(_boardsBoxName, (box) => box.clear());
    await _write(_operationsBoxName, (box) => box.clear());
  }

  // Offline queue for pending operations
  Future<void> queueOfflineOperation(String boardId, Operation operation) async {
    final key = 'pending_${boardId}_${operation.opId}';
    await _write(
      _operationsBoxName,
      (box) => box.put(key, json.encode(operation.toJson())),
    );
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
          debugPrint('Error loading pending operation $key: $e');
        }
      }
    }

    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  Future<void> clearPendingOperation(String boardId, String opId) async {
    final key = 'pending_${boardId}_$opId';
    await _write(_operationsBoxName, (box) => box.delete(key));
  }

  Future<void> clearAllPendingOperations(String boardId) async {
    if (_operationsBox == null) return;
    final keysToDelete = <String>[];
    
    for (final key in _operationsBox!.keys) {
      if (key.toString().startsWith('pending_${boardId}_')) {
        keysToDelete.add(key.toString());
      }
    }

    await _write(_operationsBoxName, (box) => box.deleteAll(keysToDelete));
  }

  String _draftKey(String boardId) => 'draft_$boardId';

  /// Local canvas draft (strokes + text). Separate from offline board state.
  Future<void> saveBoardDraft(String boardId, Map<String, dynamic> draft) async {
    await _write(_operationsBoxName, (box) => box.put(_draftKey(boardId), json.encode(draft)));
  }

  Map<String, dynamic>? getBoardDraft(String boardId) {
    final data = _operationsBox?.get(_draftKey(boardId));
    if (data == null) return null;
    try {
      final decoded = json.decode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('Error loading board draft $boardId: $e');
    }
    return null;
  }

  Future<void> clearBoardDraft(String boardId) async {
    await _write(_operationsBoxName, (box) => box.delete(_draftKey(boardId)));
  }
}
