import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/signaling_service.dart';
import '../services/storage_service.dart';
import '../services/webrtc_service.dart';
import '../core/sync_engine.dart';
import '../models/user.dart';
import '../models/workspace.dart';
import '../models/board.dart';
import '../models/whiteboard_object.dart';
import '../models/operation.dart';
import '../models/task_node.dart';
import '../models/peer.dart';

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

  AuthNotifier(this.ref) : super(AuthState()) {
    _loadAuthFromStorage();
  }

  Future<void> _loadAuthFromStorage() async {
    final storage = ref.read(storageServiceProvider);
    final api = ref.read(apiServiceProvider);
    
    try {
      await api.loadTokens();
      if (api.accessToken != null) {
        // Token loaded and refreshed successfully
        state = state.copyWith(
          accessToken: api.accessToken,
          refreshToken: api.refreshToken,
        );
      }
    } catch (e) {
      // Token refresh failed, clear auth
      await storage.clearAuth();
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
    final api = ref.read(apiServiceProvider);
    await api.logout();
    
    final storage = ref.read(storageServiceProvider);
    await storage.clearAuth();

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

  Future<void> connectToBoard(String boardId) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.accessToken == null) {
      throw Exception('Not authenticated');
    }

    // Initialize sync engine
    _syncEngine = SyncEngine(
      userId: authState.user!.id,
      onOperationApplied: (op) {
        // Update state when operation is applied
        state = state.copyWith(
          operations: [...state.operations, op],
        );
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
      },
      onPeerConnected: (peerId) {
        print('Peer connected: $peerId');
      },
      onPeerDisconnected: (peerId) {
        print('Peer disconnected: $peerId');
      },
    );

    // Initialize signaling
    _signaling = SignalingService(
      serverUrl: 'http://localhost:3000',
      onRoomJoined: (peers) {
        state = state.copyWith(peers: peers, isConnected: true);
        
        // Initiate WebRTC connections with existing peers
        for (final peer in peers) {
          _webrtc!.initPeerConnection(peer.socketId, (signal) {
            _signaling!.sendSignal(peer.socketId, signal);
          });
        }
      },
      onPeerJoined: (peer) {
        state = state.copyWith(peers: [...state.peers, peer]);
        
        // Initiate WebRTC connection
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
    );

    _signaling!.connect(authState.accessToken!);
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
