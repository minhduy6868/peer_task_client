import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/signaling_service.dart';
import '../services/storage_service.dart';
import '../services/config_service.dart';
import '../services/webrtc_service.dart';
import '../core/sync_engine.dart';
import '../models/user/user.dart';
import '../models/workspace/workspace.dart';
import '../models/api_error.dart';
import '../models/board/board.dart';
import '../models/whiteboard_object/whiteboard_object.dart';
import '../models/operation/operation.dart';
import '../models/task_node/task_node.dart';
import '../models/peer/peer.dart';
import '../models/task_model.dart';

// Services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final config = ref.watch(configServiceProvider);
  return ApiService(
    storage: storage, 
    configService: config,
    baseUrl: config.serverUrl,
  );
});

// Auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null && accessToken != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(isLoading: true)) {
    _loadAuthFromStorage();
  }

  Future<void> _loadAuthFromStorage() async {
    final storage = ref.read(storageServiceProvider);
    final api = ref.read(apiServiceProvider);

    try {
      // Load tokens from storage
      await api.loadTokens();

      if (api.accessToken != null) {
        // Try to load user from storage first
        final userJson = storage.getUser();
        if (userJson != null) {
          final user = User.fromJson(userJson);
          state = state.copyWith(
            user: user,
            accessToken: api.accessToken,
            refreshToken: api.refreshToken,
            isLoading: false,
          );
          return;
        }

        // If no cached user, fetch from API
        try {
          final userInfo = await api.getCurrentUser();
          final user = User.fromJson(userInfo);
          await storage.saveUser(userInfo);

          state = state.copyWith(
            user: user,
            accessToken: api.accessToken,
            refreshToken: api.refreshToken,
            isLoading: false,
          );
        } catch (e) {
          // Failed to get user info, clear auth
          await api.clearTokens();
          state = AuthState(isLoading: false);
        }
      } else {
        state = AuthState(isLoading: false);
      }
    } catch (e) {
      // Token loading or refresh failed, clear auth
      await api.clearTokens();
      state = AuthState(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.login(email: email, password: password);

      final user = User.fromJson(response['user']);
      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];

      final storage = ref.read(storageServiceProvider);
      await storage.saveUserId(user.id);
      await storage.saveUser(response['user']);

      state = state.copyWith(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        isLoading: false,
      );
    } on ApiError catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String email, String password, String? name) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.register(
        email: email,
        password: password,
        name: name,
      );

      final user = User.fromJson(response['user']);
      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];

      final storage = ref.read(storageServiceProvider);
      await storage.saveUserId(user.id);
      await storage.saveUser(response['user']);

      state = state.copyWith(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        isLoading: false,
      );
    } on ApiError catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    // Disconnect from whiteboard and clear P2P connections
    try {
      ref.read(whiteboardProvider.notifier).disconnect();
    } catch (e) {
      debugPrint('Error disconnecting whiteboard: $e');
    }

    // Logout from API (clears tokens from storage)
    final api = ref.read(apiServiceProvider);
    await api.logout();

    // Clear auth state
    state = AuthState();
  }

  void updateUser(Map<String, dynamic> userData) {
    final user = User.fromJson(userData);
    state = state.copyWith(user: user);
    
    final storage = ref.read(storageServiceProvider);
    storage.saveUser(userData);
  }

  Future<void> refreshUser() async {
    try {
      final api = ref.read(apiServiceProvider);
      final userInfo = await api.getCurrentUser();
      final user = User.fromJson(userInfo);

      final storage = ref.read(storageServiceProvider);
      await storage.saveUser(userInfo);

      state = state.copyWith(user: user);
    } catch (e) {
      debugPrint('Error refreshing user: $e');
      rethrow;
    }
  }
}

// Workspaces
final workspacesProvider =
    StateNotifierProvider<WorkspacesNotifier, AsyncValue<List<Workspace>>>((
      ref,
    ) {
      return WorkspacesNotifier(ref);
    });

class WorkspacesNotifier extends StateNotifier<AsyncValue<List<Workspace>>> {
  final Ref ref;

  WorkspacesNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(apiServiceProvider);
      final workspaces = await api.getWorkspaces();
      state = AsyncValue.data(workspaces);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createWorkspace(String name) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.createWorkspace(name: name);
      await loadWorkspaces();
    } catch (e) {
      rethrow;
    }
  }
}

// Current board state
final currentBoardIdProvider = StateProvider<String?>((ref) => null);

final currentBoardProvider = FutureProvider<Board?>((ref) async {
  final boardId = ref.watch(currentBoardIdProvider);
  if (boardId == null) return null;

  final api = ref.read(apiServiceProvider);
  return await api.getBoard(boardId);
});

// Whiteboard state
final whiteboardProvider =
    StateNotifierProvider<WhiteboardNotifier, WhiteboardState>((ref) {
      return WhiteboardNotifier(ref);
    });

class WhiteboardState {
  final List<Operation> operations;
  final List<WhiteboardObject> objects;
  final List<TaskNode> taskNodes;
  final List<Peer> peers;
  final bool isConnected;
  final double zoom;
  final Offset pan;
  final DateTime? draftSavedAt;
  final bool hasUnsavedChanges;

  WhiteboardState({
    this.operations = const [],
    this.objects = const [],
    this.taskNodes = const [],
    this.peers = const [],
    this.isConnected = false,
    this.zoom = 1.0,
    this.pan = Offset.zero,
    this.draftSavedAt,
    this.hasUnsavedChanges = false,
  });

  WhiteboardState copyWith({
    List<Operation>? operations,
    List<WhiteboardObject>? objects,
    List<TaskNode>? taskNodes,
    List<Peer>? peers,
    bool? isConnected,
    double? zoom,
    Offset? pan,
    DateTime? draftSavedAt,
    bool clearDraftSavedAt = false,
    bool? hasUnsavedChanges,
  }) {
    return WhiteboardState(
      operations: operations ?? this.operations,
      objects: objects ?? this.objects,
      taskNodes: taskNodes ?? this.taskNodes,
      peers: peers ?? this.peers,
      isConnected: isConnected ?? this.isConnected,
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
      draftSavedAt: clearDraftSavedAt
          ? null
          : (draftSavedAt ?? this.draftSavedAt),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

class WhiteboardNotifier extends StateNotifier<WhiteboardState> {
  final Ref ref;
  SignalingService? _signaling;
  WebRTCService? _webrtc;
  SyncEngine? _syncEngine;
  String? _currentBoardId;
  Timer? _draftSaveTimer;
  bool _hydrating = false;
  final Set<String> _syncedOpIds = {};

  static const _draftableTypes = {'stroke', 'text'};

  WhiteboardNotifier(this.ref) : super(WhiteboardState());

  bool _isDraftable(Operation op) {
    final type = op.payload['type'] as String?;
    return type != null && _draftableTypes.contains(type);
  }

  void _markDraftDirtyIfNeeded(Operation op) {
    if (_hydrating || !_isDraftable(op)) return;
    state = state.copyWith(hasUnsavedChanges: true);
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    final boardId = _currentBoardId;
    if (boardId == null) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(saveDraft(boardId: boardId));
    });
  }

  void _refreshDraftStatus({DateTime? savedAt}) {
    final unsynced = state.operations
        .where(_isDraftable)
        .any((op) => !_syncedOpIds.contains(op.opId));
    state = state.copyWith(
      hasUnsavedChanges: unsynced,
      draftSavedAt: unsynced ? state.draftSavedAt : (savedAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> _payloadForBackend(Operation op) {
    final payload = Map<String, dynamic>.from(op.payload);
    payload.remove('_saveBackend');
    return payload;
  }

  // Getter to access WebRTC service
  WebRTCService? get webrtc => _webrtc;

  // Save operation to backend database
  Future<bool> _saveOperationToBackend(
    String boardId,
    Operation op,
    ApiService api,
  ) async {
    try {
      await api.saveOperation(
        boardId: boardId,
        operationId: op.opId,
        operationType: op.type.name,
        payload: _payloadForBackend(op),
        timestamp: op.timestamp,
      );
      _syncedOpIds.add(op.opId);
      return true;
    } catch (e) {
      debugPrint('Error saving operation to backend: $e');
      return false;
    }
  }

  Future<int> _flushOpsToServer(String boardId, List<Operation> ops) async {
    final api = ref.read(apiServiceProvider);
    var saved = 0;
    var failed = 0;
    for (final op in ops) {
      if (_syncedOpIds.contains(op.opId)) {
        saved++;
        continue;
      }
      final ok = await _saveOperationToBackend(boardId, op, api);
      if (ok) {
        saved++;
      } else {
        failed++;
      }
    }
    if (failed > 0) {
      throw ApiError.network('Failed to save draft to server');
    }
    return saved;
  }

  Future<int> connectToBoard(
    String boardId, [
    void Function(Operation)? onRemoteOperation,
  ]) async {
    // Disconnect from previous board if connected
    if (_currentBoardId != null && _currentBoardId != boardId) {
      debugPrint('🔄 Switching from board $_currentBoardId to $boardId');
      disconnect();
    } else if (_currentBoardId == boardId && state.isConnected) {
      debugPrint('⚠️  Already connected to board $boardId, skipping reconnect');
      return hydrateCanvas(boardId);
    }

    _currentBoardId = boardId;

    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.accessToken == null) {
      throw ApiError.unauthorized();
    }

    final api = ref.read(apiServiceProvider);
    String? _boardId = boardId; // Store boardId for callbacks

    debugPrint('🚀 Connecting to board: $boardId');

    // Initialize sync engine
    _syncEngine = SyncEngine(
      userId: authState.user!.id,
      onOperationApplied: (op) {
        // Update state when operation is applied
        state = state.copyWith(operations: [...state.operations, op]);
        _markDraftDirtyIfNeeded(op);
      },
      onOperationBroadcast: (op) {
        // Save to backend ONLY if shouldSaveBackend flag is true
        final shouldSave = op.payload['_saveBackend'] ?? true;
        if (shouldSave) {
          debugPrint('💾 Saving operation to backend: ${op.type.name}');
          unawaited((() async {
            final ok = await _saveOperationToBackend(_boardId, op, api);
            if (ok) _refreshDraftStatus();
          })());
        } else {
          debugPrint('⏭️  Skipping backend save for: ${op.type.name}');
        }

        // Always broadcast via WebRTC to peers for realtime sync
        debugPrint('📡 Broadcasting operation via WebRTC: ${op.type.name}');
        _webrtc?.sendOperation(op);
      },
    );

    // Initialize WebRTC
    _webrtc = WebRTCService(
      userId: authState.user!.id,
      onOperationReceived: (peerId, operation) {
        debugPrint(
          '📥 Received operation from $peerId: ${operation.type.name}',
        );
        _syncEngine?.receiveOperation(operation);
        // Call custom callback if provided
        onRemoteOperation?.call(operation);
      },
      onPeerConnected: (peerId) {
        debugPrint('✅ Peer CONNECTED and ready: $peerId');
        debugPrint(
          '📊 Total connected peers: ${_webrtc?.connectedPeersCount ?? 0}',
        );
      },
      onPeerDisconnected: (peerId) {
        debugPrint('Peer disconnected: $peerId');
      },
      onRemoteAudioStream: (peerId, stream) {
        debugPrint('🎵 Received remote audio stream from $peerId');
        // You can store this stream or play it directly
        // For now, just log it - implement audio playback in UI later
      },
    );

    // Initialize signaling - sử dụng URL từ ConfigService
    final config = ref.read(configServiceProvider);
    final serverUrl = config.serverUrl;
    debugPrint('🌐 Signaling server URL: $serverUrl');

    _signaling = SignalingService(
      serverUrl: serverUrl,
      onRoomJoined: (peers) {
        debugPrint('📥 Room joined with ${peers.length} existing peers');
        for (final peer in peers) {
          debugPrint('   - Peer: ${peer.socketId} (user: ${peer.userId})');
        }
        state = state.copyWith(peers: peers, isConnected: true);

        // Initiate WebRTC connections with existing peers
        // Perfect negotiation: only peer with higher userId creates offer
        final myUserId = authState.user!.id;
        for (final peer in peers) {
          final shouldInitiate = myUserId.compareTo(peer.userId) > 0;
          if (shouldInitiate) {
            debugPrint(
              '🚀 Initiating WebRTC connection with ${peer.socketId} (we are initiator)',
            );
            _webrtc!.initPeerConnection(peer.socketId, (signal) {
              _signaling!.sendSignal(peer.socketId, signal);
            });
          } else {
            debugPrint(
              '⏳ Waiting for offer from ${peer.socketId} (they are initiator)',
            );
          }
        }
      },
      onPeerJoined: (peer) {
        debugPrint(
          '📥 New peer joined: ${peer.socketId} (user: ${peer.userId})',
        );
        state = state.copyWith(peers: [...state.peers, peer]);

        // Perfect negotiation: only peer with higher userId creates offer
        final myUserId = authState.user!.id;
        final shouldInitiate = myUserId.compareTo(peer.userId) > 0;
        if (shouldInitiate) {
          debugPrint(
            '🚀 Initiating WebRTC connection with ${peer.socketId} (we are initiator)',
          );
          _webrtc!.initPeerConnection(peer.socketId, (signal) {
            _signaling!.sendSignal(peer.socketId, signal);
          });
        } else {
          debugPrint(
            '⏳ Waiting for offer from ${peer.socketId} (they are initiator)',
          );
        }
      },
      onPeerLeft: (peer) {
        state = state.copyWith(
          peers: state.peers.where((p) => p.socketId != peer.socketId).toList(),
        );
        _webrtc!.closePeerConnection(peer.socketId);
      },
      onSignal: (from, signal) {
        _webrtc!.handleSignal(from, signal, (responseSignal) {
          _signaling!.sendSignal(from, responseSignal);
        });
      },
      onPeerMicUpdated: (socketId, isMuted) {
        debugPrint(
          '🎤 Peer $socketId mic updated: ${isMuted ? 'muted' : 'unmuted'}',
        );
        // Update peer state
        final updatedPeers = state.peers.map((peer) {
          if (peer.socketId == socketId) {
            return peer.copyWith(isMuted: isMuted);
          }
          return peer;
        }).toList();
        state = state.copyWith(peers: updatedPeers);
      },
      onReconnected: () async {
        // When reconnected, sync operations from backend
        debugPrint('♻️ Reconnected - syncing operations from backend');
        await hydrateCanvas(boardId);
      },
    );

    debugPrint('🔌 Connecting to signaling server...');
    _signaling!.connect(authState.accessToken!);
    debugPrint('🚪 Joining room: $boardId');
    _signaling!.joinRoom(boardId);

    // Load offline operations
    final storage = ref.read(storageServiceProvider);
    final offlineOps = storage.getPendingOperations(boardId);
    for (final op in offlineOps) {
      _syncEngine!.receiveOperation(op);
      await storage.clearPendingOperation(boardId, op.opId);
    }

    return hydrateCanvas(boardId);
  }

  /// Replay server history, then upload any newer local-only strokes/text.
  Future<int> hydrateCanvas(String boardId) async {
    _hydrating = true;
    var restored = 0;
    try {
      await _loadBackendOperations(boardId);
      restored = await restoreDraft(boardId);
    } finally {
      _hydrating = false;
    }
    final unsynced = state.operations
        .where(_isDraftable)
        .where((op) => !_syncedOpIds.contains(op.opId))
        .toList();
    if (unsynced.isNotEmpty) {
      try {
        await saveDraft(boardId: boardId);
      } catch (e) {
        debugPrint('Error flushing restored draft to server: $e');
      }
    }
    return restored;
  }

  Future<void> _loadBackendOperations(String boardId) async {
    try {
      final api = ref.read(apiServiceProvider);
      final operations = await api.getBoardOperations(boardId);
      for (final opData in operations) {
        try {
          final mapped = Map<String, dynamic>.from(opData);
          mapped['actor'] ??= 'unknown';
          final payload = mapped['payload'];
          if (payload is Map) {
            mapped['payload'] = Map<String, dynamic>.from(payload);
          }
          final operation = Operation.fromJson(mapped);
          if ((operation.payload['type'] as String?) == 'cursor') continue;
          _syncedOpIds.add(operation.opId);
          _applyLocally(operation);
        } catch (e) {
          debugPrint('Error applying backend operation: $e');
        }
      }
      debugPrint('✅ Loaded ${operations.length} operations from backend');
    } catch (e) {
      debugPrint('Error loading board operations: $e');
    }
  }

  void _applyLocally(Operation operation) {
    if (_syncEngine != null) {
      _syncEngine!.receiveOperation(operation);
      return;
    }
    if (state.operations.any((op) => op.opId == operation.opId)) return;
    state = state.copyWith(operations: [...state.operations, operation]);
  }

  bool _shouldRestoreDraftOp(Operation draftOp) {
    if (state.operations.any((op) => op.opId == draftOp.opId)) return false;
    final objectId = draftOp.payload['id'];
    if (objectId == null) return true;
    final existing = state.operations.where(
      (op) => op.payload['id'] == objectId && _isDraftable(op),
    );
    if (existing.isEmpty) return true;
    final latest = existing
        .map((op) => op.timestamp)
        .reduce((a, b) => a > b ? a : b);
    return draftOp.timestamp > latest;
  }

  Future<int> saveDraft({
    String? boardId,
    List<Operation>? opsSnapshot,
    bool throwOnError = false,
  }) async {
    final id = boardId ?? _currentBoardId;
    if (id == null) return 0;

    final ops = opsSnapshot ?? state.operations.where(_isDraftable).toList();
    final storage = ref.read(storageServiceProvider);
    await storage.saveBoardDraft(id, {
      'boardId': id,
      'savedAt': DateTime.now().toIso8601String(),
      'operations': ops.map((op) => op.toJson()).toList(),
    });

    try {
      final saved = await _flushOpsToServer(id, ops);
      final savedAt = DateTime.now();
      if (_currentBoardId == id) {
        _refreshDraftStatus(savedAt: savedAt);
      }
      debugPrint('💾 Saved canvas draft to server for $id ($saved ops)');
      return saved;
    } catch (e) {
      debugPrint('Error flushing draft to server: $e');
      if (_currentBoardId == id) {
        state = state.copyWith(hasUnsavedChanges: true);
      }
      if (throwOnError) rethrow;
      return 0;
    }
  }

  Future<int> restoreDraft(String boardId) async {
    final storage = ref.read(storageServiceProvider);
    final draft = storage.getBoardDraft(boardId);
    if (draft == null) return 0;

    DateTime? savedAt;
    final rawSavedAt = draft['savedAt'] as String?;
    if (rawSavedAt != null) {
      savedAt = DateTime.tryParse(rawSavedAt);
    }

    final rawOps = draft['operations'];
    var restored = 0;
    if (rawOps is List) {
      final draftOps = <Operation>[];
      for (final item in rawOps) {
        if (item is! Map) continue;
        try {
          final op = Operation.fromJson(Map<String, dynamic>.from(item));
          if (_isDraftable(op)) draftOps.add(op);
        } catch (e) {
          debugPrint('Error parsing draft operation: $e');
        }
      }
      draftOps.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final op in draftOps) {
        if (!_shouldRestoreDraftOp(op)) continue;
        _applyLocally(op);
        restored++;
      }
    }

    if (_currentBoardId == boardId) {
      state = state.copyWith(
        draftSavedAt: savedAt ?? state.draftSavedAt,
        hasUnsavedChanges: false,
      );
    }

    if (restored > 0) {
      debugPrint('📝 Restored $restored draft operation(s) for $boardId');
    }
    return restored;
  }

  Future<void> discardDraft(String boardId) async {
    _draftSaveTimer?.cancel();
    final storage = ref.read(storageServiceProvider);
    await storage.clearBoardDraft(boardId);
    if (_currentBoardId == boardId) {
      state = state.copyWith(
        clearDraftSavedAt: true,
        hasUnsavedChanges: false,
      );
    }
  }

  void createOperation(
    OperationType type,
    Map<String, dynamic> payload, {
    bool shouldSaveBackend = true,
  }) {
    _syncEngine?.createOperation(
      type: type,
      payload: payload,
      shouldSaveBackend: shouldSaveBackend,
    );
  }

  void receiveOperation(Operation operation) {
    _syncEngine?.receiveOperation(operation);
  }

  void broadcastOperation(Operation operation) {
    // Send to local sync engine
    _syncEngine?.receiveOperation(operation);
    // Broadcast via WebRTC P2P
    _webrtc?.sendOperation(operation);
  }

  void addObject(WhiteboardObject object) {
    state = state.copyWith(objects: [...state.objects, object]);
    // Create operation to sync across peers
    createOperation(OperationType.createObject, {
      'objectType': 'whiteboardObject',
      'object': object.toJson(),
    });
  }

  void updateObject(String objectId, Map<String, dynamic> updates) {
    final objects = state.objects.map((obj) {
      if (obj.id == objectId) {
        final updatedData = Map<String, dynamic>.from(obj.data)
          ..addAll(updates);
        return obj.copyWith(
          data: updatedData,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          version: obj.version + 1,
        );
      }
      return obj;
    }).toList();

    state = state.copyWith(objects: objects);
    createOperation(OperationType.updateObject, {
      'objectType': 'whiteboardObject',
      'objectId': objectId,
      'updates': updates,
    });
  }

  void deleteObject(String objectId) {
    state = state.copyWith(
      objects: state.objects.where((obj) => obj.id != objectId).toList(),
    );
    createOperation(OperationType.deleteObject, {
      'objectType': 'whiteboardObject',
      'objectId': objectId,
    });
  }

  void addTaskNode(TaskNode taskNode) {
    state = state.copyWith(taskNodes: [...state.taskNodes, taskNode]);
    createOperation(OperationType.createObject, {
      'objectType': 'taskNode',
      'taskNode': taskNode.toJson(),
    });
  }

  void updateTaskNode(String taskNodeId, Map<String, dynamic> updates) {
    final taskNodes = state.taskNodes.map((node) {
      if (node.id == taskNodeId) {
        return TaskNode.fromJson({
          ...node.toJson(),
          ...updates,
          'version': node.version + 1,
        });
      }
      return node;
    }).toList();

    state = state.copyWith(taskNodes: taskNodes);
    createOperation(OperationType.updateObject, {
      'objectType': 'taskNode',
      'taskNodeId': taskNodeId,
      'updates': updates,
    });
  }

  void deleteTaskNode(String taskNodeId) {
    state = state.copyWith(
      taskNodes: state.taskNodes
          .where((node) => node.id != taskNodeId)
          .toList(),
    );
    createOperation(OperationType.deleteObject, {
      'objectType': 'taskNode',
      'taskNodeId': taskNodeId,
    });
  }

  void clearAll() {
    state = state.copyWith(objects: [], taskNodes: []);
    createOperation(OperationType.deleteObject, {'objectType': 'all'});
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  void setPan(Offset pan) {
    state = state.copyWith(pan: pan);
  }

  void updateMicStatus(bool isMuted) {
    debugPrint('🎤 Updating my mic status: ${isMuted ? 'muted' : 'unmuted'}');
    _signaling?.updateMicStatus(isMuted);
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting from board: $_currentBoardId');
    _draftSaveTimer?.cancel();
    final boardId = _currentBoardId;
    final draftOps = state.operations.where(_isDraftable).toList();
    if (boardId != null && draftOps.isNotEmpty) {
      unawaited(saveDraft(boardId: boardId, opsSnapshot: draftOps));
    }
    _signaling?.disconnect();
    _webrtc?.closeAllConnections();
    _syncEngine = null;
    _signaling = null;
    _webrtc = null;
    _currentBoardId = null;
    _syncedOpIds.clear();
    state = WhiteboardState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Task provider - manages tasks separately from canvas objects
final boardTasksProvider =
    StateNotifierProvider.family<BoardTasksNotifier, List<TaskModel>, String>((
      ref,
      boardId,
    ) {
      return BoardTasksNotifier(ref, boardId);
    });

class BoardTasksNotifier extends StateNotifier<List<TaskModel>> {
  final Ref _ref;
  final String _boardId;

  BoardTasksNotifier(this._ref, this._boardId) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final tasksData = await api.getBoardTasks(_boardId);

      state = tasksData.map<TaskModel>((taskJson) {
        return TaskModel(
          id: taskJson['id'] as String,
          boardId: _boardId,
          title: taskJson['title'] as String? ?? 'Untitled',
          description: taskJson['description'] as String?,
          status: taskJson['status'] as String? ?? 'todo',
          priority: taskJson['priority'] as String? ?? 'medium',
          assignees: (taskJson['assignees'] as List?)?.cast<String>() ?? [],
          assigneeList:
              (taskJson['assignee_list'] as List?)
                  ?.map(
                    (a) => AssigneeInfo(
                      id: a['id'] as String,
                      name: a['name'] as String,
                      email: a['email'] as String?,
                      avatar: null,
                    ),
                  )
                  .toList() ??
              [],
          labels: (taskJson['labels'] as List?)?.cast<String>() ?? [],
          deadline: taskJson['deadline'] != null
              ? DateTime.tryParse(taskJson['deadline'] as String)
              : null,
          estimatedHours: taskJson['estimated_hours'] != null
              ? double.tryParse(taskJson['estimated_hours'].toString())
              : null,
          actualHours: taskJson['actual_hours'] != null
              ? double.tryParse(taskJson['actual_hours'].toString())
              : null,
          parentId: taskJson['parent_id'] as String?,
          position: taskJson['position'] as int? ?? 0,
          createdBy: taskJson['created_by'] as String,
          creatorName: taskJson['creator_name'] as String?,
          createdAt:
              DateTime.tryParse(taskJson['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(taskJson['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();

      debugPrint('✅ Loaded ${state.length} tasks for board $_boardId');
    } catch (e) {
      debugPrint('❌ Error loading tasks: $e');
    }
  }

  Future<void> createTask({
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? deadline,
    List<String>? assignees,
    List<String>? labels,
    double? estimatedHours,
  }) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.createTask(
        boardId: _boardId,
        title: title,
        description: description,
        assignees: assignees,
        status: status,
        priority: priority,
        deadline: deadline,
        parentId: null,
        labels: labels,
        estimatedHours: estimatedHours,
      );

      final newTask = TaskModel(
        id: response['id'] as String,
        boardId: _boardId,
        title: response['title'] as String? ?? title,
        description: response['description'] as String?,
        status: response['status'] as String? ?? status,
        priority: response['priority'] as String? ?? priority,
        assignees: (response['assignees'] as List?)?.cast<String>() ?? [],
        assigneeList:
            (response['assignee_list'] as List?)
                ?.map(
                  (a) => AssigneeInfo(
                    id: a['id'] as String,
                    name: a['name'] as String,
                    email: a['email'] as String?,
                    avatar: null,
                  ),
                )
                .toList() ??
            [],
        labels: (response['labels'] as List?)?.cast<String>() ?? [],
        deadline: response['deadline'] != null
            ? DateTime.tryParse(response['deadline'] as String)
            : null,
        estimatedHours: response['estimated_hours'] != null
            ? double.tryParse(response['estimated_hours'].toString())
            : null,
        actualHours: response['actual_hours'] != null
            ? double.tryParse(response['actual_hours'].toString())
            : null,
        parentId: response['parent_id'] as String?,
        position: response['position'] as int? ?? 0,
        createdBy: response['created_by'] as String,
        creatorName: response['creator_name'] as String?,
        createdAt:
            DateTime.tryParse(response['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(response['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

      state = [...state, newTask];
      debugPrint('✅ Created task: ${newTask.id}');
    } catch (e) {
      debugPrint('❌ Error creating task: $e');
      rethrow;
    }
  }

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? deadline,
    List<String>? assignees,
    List<String>? labels,
    double? estimatedHours,
  }) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        assignees: assignees,
        status: status,
        priority: priority,
        deadline: deadline,
        labels: labels,
        estimatedHours: estimatedHours,
      );

      final updatedTask = TaskModel(
        id: response['id'] as String,
        boardId: _boardId,
        title: response['title'] as String? ?? 'Untitled',
        description: response['description'] as String?,
        status: response['status'] as String? ?? 'todo',
        priority: response['priority'] as String? ?? 'medium',
        assignees: (response['assignees'] as List?)?.cast<String>() ?? [],
        assigneeList:
            (response['assignee_list'] as List?)
                ?.map(
                  (a) => AssigneeInfo(
                    id: a['id'] as String,
                    name: a['name'] as String,
                    email: a['email'] as String?,
                    avatar: null,
                  ),
                )
                .toList() ??
            [],
        labels: (response['labels'] as List?)?.cast<String>() ?? [],
        deadline: response['deadline'] != null
            ? DateTime.tryParse(response['deadline'] as String)
            : null,
        estimatedHours: response['estimated_hours'] != null
            ? double.tryParse(response['estimated_hours'].toString())
            : null,
        actualHours: response['actual_hours'] != null
            ? double.tryParse(response['actual_hours'].toString())
            : null,
        parentId: response['parent_id'] as String?,
        position: response['position'] as int? ?? 0,
        createdBy: response['created_by'] as String,
        creatorName: response['creator_name'] as String?,
        createdAt:
            DateTime.tryParse(response['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(response['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

      state = [
        for (final task in state)
          if (task.id == taskId) updatedTask else task,
      ];

      debugPrint('✅ Updated task: $taskId');
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
      rethrow;
    }
  }

  Future<void> moveTask(String taskId, String newStatus) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.moveTask(
        taskId: taskId,
        status: newStatus,
        boardId: _boardId,
      );

      final updatedTask = TaskModel(
        id: response['id'] as String,
        boardId: _boardId,
        title: response['title'] as String? ?? 'Untitled',
        description: response['description'] as String?,
        status: response['status'] as String? ?? newStatus,
        priority: response['priority'] as String? ?? 'medium',
        assignees: (response['assignees'] as List?)?.cast<String>() ?? [],
        assigneeList:
            (response['assignee_list'] as List?)
                ?.map(
                  (a) => AssigneeInfo(
                    id: a['id'] as String,
                    name: a['name'] as String,
                    email: a['email'] as String?,
                    avatar: null,
                  ),
                )
                .toList() ??
            [],
        labels: (response['labels'] as List?)?.cast<String>() ?? [],
        deadline: response['deadline'] != null
            ? DateTime.tryParse(response['deadline'] as String)
            : null,
        estimatedHours: response['estimated_hours'] != null
            ? double.tryParse(response['estimated_hours'].toString())
            : null,
        actualHours: response['actual_hours'] != null
            ? double.tryParse(response['actual_hours'].toString())
            : null,
        parentId: response['parent_id'] as String?,
        position: response['position'] as int? ?? 0,
        createdBy: response['created_by'] as String,
        creatorName: response['creator_name'] as String?,
        createdAt:
            DateTime.tryParse(response['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(response['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

      state = [
        for (final task in state)
          if (task.id == taskId) updatedTask else task,
      ];

      debugPrint('✅ Moved task $taskId to $newStatus');
    } catch (e) {
      debugPrint('❌ Error moving task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final api = _ref.read(apiServiceProvider);
      await api.deleteTask(taskId);

      state = state.where((task) => task.id != taskId).toList();

      debugPrint('✅ Deleted task: $taskId');
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
      rethrow;
    }
  }

  void refresh() {
    _loadTasks();
  }
}
