import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/signaling_service.dart';
import '../services/storage_service.dart';
import '../services/webrtc_service.dart';
import '../core/sync_engine.dart';
import '../models/user/user.dart';
import '../models/workspace/workspace.dart';
import '../models/board/board.dart';
import '../models/whiteboard_object/whiteboard_object.dart';
import '../models/operation/operation.dart';
import '../models/task_node/task_node.dart';
import '../models/peer/peer.dart';

// Services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage: storage);
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
}

// Workspaces
final workspacesProvider = StateNotifierProvider<WorkspacesNotifier, AsyncValue<List<Workspace>>>((ref) {
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
final whiteboardProvider = StateNotifierProvider<WhiteboardNotifier, WhiteboardState>((ref) {
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

  WhiteboardState({
    this.operations = const [],
    this.objects = const [],
    this.taskNodes = const [],
    this.peers = const [],
    this.isConnected = false,
    this.zoom = 1.0,
    this.pan = Offset.zero,
  });

  WhiteboardState copyWith({
    List<Operation>? operations,
    List<WhiteboardObject>? objects,
    List<TaskNode>? taskNodes,
    List<Peer>? peers,
    bool? isConnected,
    double? zoom,
    Offset? pan,
  }) {
    return WhiteboardState(
      operations: operations ?? this.operations,
      objects: objects ?? this.objects,
      taskNodes: taskNodes ?? this.taskNodes,
      peers: peers ?? this.peers,
      isConnected: isConnected ?? this.isConnected,
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
    );
  }
}

class WhiteboardNotifier extends StateNotifier<WhiteboardState> {
  final Ref ref;
  SignalingService? _signaling;
  WebRTCService? _webrtc;
  SyncEngine? _syncEngine;

  WhiteboardNotifier(this.ref) : super(WhiteboardState());

  // Save operation to backend database
  Future<void> _saveOperationToBackend(
    String boardId,
    Operation op,
    ApiService api,
  ) async {
    try {
      await api.saveOperation(
        boardId: boardId,
        operationId: op.opId,
        operationType: op.type.name,
        payload: op.payload,
        timestamp: op.timestamp,
      );
    } catch (e) {
      debugPrint('Error saving operation to backend: $e');
      // Don't throw - P2P sync should continue even if backend save fails
    }
  }

  Future<void> connectToBoard(
    String boardId, [
    void Function(Operation)? onRemoteOperation,
  ]) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.accessToken == null) {
      throw Exception('Not authenticated');
    }

    final api = ref.read(apiServiceProvider);

    // Initialize sync engine
    _syncEngine = SyncEngine(
      userId: authState.user!.id,
      onOperationApplied: (op) {
        // Update state when operation is applied
        state = state.copyWith(
          operations: [...state.operations, op],
        );
        
        // Save operation to backend (async, don't await)
        _saveOperationToBackend(boardId, op, api);
      },
      onOperationBroadcast: (op) {
        // Broadcast via WebRTC
        _webrtc?.sendOperation(op);
      },
    );

    // Initialize WebRTC
    _webrtc = WebRTCService(
      userId: authState.user!.id,
      onOperationReceived: (peerId, operation) {
        _syncEngine?.receiveOperation(operation);
        // Call custom callback if provided
        onRemoteOperation?.call(operation);
      },
      onPeerConnected: (peerId) {
        debugPrint('Peer connected: $peerId');
      },
      onPeerDisconnected: (peerId) {
        debugPrint('Peer disconnected: $peerId');
      },
    );

    // Initialize signaling
    _signaling = SignalingService(
      serverUrl: kIsWeb ? 'http://127.0.0.1:3000' : 'http://localhost:3000',
      onRoomJoined: (peers) {
        debugPrint('📥 Room joined with ${peers.length} existing peers');
        for (final peer in peers) {
          debugPrint('   - Peer: ${peer.socketId} (user: ${peer.userId})');
        }
        state = state.copyWith(peers: peers, isConnected: true);
        
        // Initiate WebRTC connections with existing peers
        for (final peer in peers) {
          debugPrint('🚀 Initiating WebRTC connection with ${peer.socketId}');
          _webrtc!.initPeerConnection(peer.socketId, (signal) {
            _signaling!.sendSignal(peer.socketId, signal);
          });
        }
      },
      onPeerJoined: (peer) {
        debugPrint('📥 New peer joined: ${peer.socketId} (user: ${peer.userId})');
        state = state.copyWith(peers: [...state.peers, peer]);
        
        // Initiate WebRTC connection
        debugPrint('🚀 Initiating WebRTC connection with new peer ${peer.socketId}');
        _webrtc!.initPeerConnection(peer.socketId, (signal) {
          _signaling!.sendSignal(peer.socketId, signal);
        });
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
      onReconnected: () async {
        // When reconnected, sync operations from backend
        debugPrint('♻️ Reconnected - syncing operations from backend');
        try {
          final api = ref.read(apiServiceProvider);
          final operations = await api.getBoardOperations(boardId);
          for (final opData in operations) {
            try {
              final operation = Operation.fromJson(opData);
              _syncEngine?.receiveOperation(operation);
            } catch (e) {
              debugPrint('Error applying operation after reconnect: $e');
            }
          }
        } catch (e) {
          debugPrint('Error syncing operations after reconnect: $e');
        }
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
  }

  void createOperation(OperationType type, Map<String, dynamic> payload) {
    _syncEngine?.createOperation(type: type, payload: payload);
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
    state = state.copyWith(
      objects: [...state.objects, object],
    );
    // Create operation to sync across peers
    createOperation(OperationType.createObject, {
      'objectType': 'whiteboardObject',
      'object': object.toJson(),
    });
  }

  void updateObject(String objectId, Map<String, dynamic> updates) {
    final objects = state.objects.map((obj) {
      if (obj.id == objectId) {
        final updatedData = Map<String, dynamic>.from(obj.data)..addAll(updates);
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
    state = state.copyWith(
      taskNodes: [...state.taskNodes, taskNode],
    );
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
      taskNodes: state.taskNodes.where((node) => node.id != taskNodeId).toList(),
    );
    createOperation(OperationType.deleteObject, {
      'objectType': 'taskNode',
      'taskNodeId': taskNodeId,
    });
  }

  void clearAll() {
    state = state.copyWith(
      objects: [],
      taskNodes: [],
    );
    createOperation(OperationType.deleteObject, {
      'objectType': 'all',
    });
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  void setPan(Offset pan) {
    state = state.copyWith(pan: pan);
  }

  void disconnect() {
    _signaling?.disconnect();
    _webrtc?.closeAllConnections();
    state = WhiteboardState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
