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
    } on ApiError catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.userMessage,
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
    } on ApiError catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.userMessage,
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
  String? _currentBoardId;

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
    // Disconnect from previous board if connected
    if (_currentBoardId != null && _currentBoardId != boardId) {
      debugPrint('🔄 Switching from board $_currentBoardId to $boardId');
      disconnect();
    } else if (_currentBoardId == boardId && state.isConnected) {
      debugPrint('⚠️  Already connected to board $boardId, skipping reconnect');
      return;
    }

    _currentBoardId = boardId;
    
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.accessToken == null) {
      throw Exception('Not authenticated');
    }

    final api = ref.read(apiServiceProvider);
    String? _boardId = boardId; // Store boardId for callbacks

    debugPrint('🚀 Connecting to board: $boardId');

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
        // Save to backend ONLY if shouldSaveBackend flag is true
        final shouldSave = op.payload['_saveBackend'] ?? true;
        if (shouldSave) {
          debugPrint('💾 Saving operation to backend: ${op.type.name}');
          _saveOperationToBackend(_boardId, op, api);
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
        debugPrint('📥 Received operation from $peerId: ${operation.type.name}');
        _syncEngine?.receiveOperation(operation);
        // Call custom callback if provided
        onRemoteOperation?.call(operation);
      },
      onPeerConnected: (peerId) {
        debugPrint('✅ Peer CONNECTED and ready: $peerId');
        debugPrint('📊 Total connected peers: ${_webrtc?.connectedPeersCount ?? 0}');
      },
      onPeerDisconnected: (peerId) {
        debugPrint('Peer disconnected: $peerId');
      },
    );

    // Initialize signaling
    final serverUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
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
            debugPrint('🚀 Initiating WebRTC connection with ${peer.socketId} (we are initiator)');
            _webrtc!.initPeerConnection(peer.socketId, (signal) {
              _signaling!.sendSignal(peer.socketId, signal);
            });
          } else {
            debugPrint('⏳ Waiting for offer from ${peer.socketId} (they are initiator)');
          }
        }
      },
      onPeerJoined: (peer) {
        debugPrint('📥 New peer joined: ${peer.socketId} (user: ${peer.userId})');
        state = state.copyWith(peers: [...state.peers, peer]);
        
        // Perfect negotiation: only peer with higher userId creates offer
        final myUserId = authState.user!.id;
        final shouldInitiate = myUserId.compareTo(peer.userId) > 0;
        if (shouldInitiate) {
          debugPrint('🚀 Initiating WebRTC connection with ${peer.socketId} (we are initiator)');
          _webrtc!.initPeerConnection(peer.socketId, (signal) {
            _signaling!.sendSignal(peer.socketId, signal);
          });
        } else {
          debugPrint('⏳ Waiting for offer from ${peer.socketId} (they are initiator)');
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
        debugPrint('🎤 Peer $socketId mic updated: ${isMuted ? 'muted' : 'unmuted'}');
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

  void updateMicStatus(bool isMuted) {
    debugPrint('🎤 Updating my mic status: ${isMuted ? 'muted' : 'unmuted'}');
    _signaling?.updateMicStatus(isMuted);
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting from board: $_currentBoardId');
    _signaling?.disconnect();
    _webrtc?.closeAllConnections();
    _syncEngine = null;
    _signaling = null;
    _webrtc = null;
    _currentBoardId = null;
    state = WhiteboardState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Task provider - manages tasks separately from canvas objects
final boardTasksProvider = StateNotifierProvider.family<BoardTasksNotifier, List<TaskModel>, String>(
  (ref, boardId) {
    return BoardTasksNotifier(ref, boardId);
  },
);

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
          assigneeList: (taskJson['assignee_list'] as List?)
              ?.map((a) => AssigneeInfo(
                    id: a['id'] as String,
                    name: a['name'] as String,
                    email: a['email'] as String?,
                    avatar: null,
                  ))
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
          createdAt: DateTime.tryParse(taskJson['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(taskJson['updated_at'] as String? ?? '') ??
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
        assigneeList: (response['assignee_list'] as List?)
            ?.map((a) => AssigneeInfo(
                  id: a['id'] as String,
                  name: a['name'] as String,
                  email: a['email'] as String?,
                  avatar: null,
                ))
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
        createdAt: DateTime.tryParse(response['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(response['updated_at'] as String? ?? '') ??
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
        assigneeList: (response['assignee_list'] as List?)
            ?.map((a) => AssigneeInfo(
                  id: a['id'] as String,
                  name: a['name'] as String,
                  email: a['email'] as String?,
                  avatar: null,
                ))
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
        createdAt: DateTime.tryParse(response['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(response['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

      state = [
        for (final task in state)
          if (task.id == taskId) updatedTask else task
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
        assigneeList: (response['assignee_list'] as List?)
            ?.map((a) => AssigneeInfo(
                  id: a['id'] as String,
                  name: a['name'] as String,
                  email: a['email'] as String?,
                  avatar: null,
                ))
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
        createdAt: DateTime.tryParse(response['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(response['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

      state = [
        for (final task in state)
          if (task.id == taskId) updatedTask else task
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
