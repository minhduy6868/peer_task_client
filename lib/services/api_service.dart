import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/workspace/workspace.dart';
import '../models/board/board.dart';
import 'storage_service.dart';

/// PeerTask API Service
/// 
/// Complete REST API client with JWT authentication and token refresh.
/// 
/// **API Endpoints (48 total):**
/// 
/// **Authentication (6 endpoints):**
/// - POST /auth/register - Register new user
/// - POST /auth/login - Login user
/// - POST /auth/forgot-password - Request password reset
/// - POST /auth/reset-password - Reset password with token
/// - POST /token/refresh - Refresh access token
/// - POST /token/logout - Logout user
/// 
/// **Workspaces (13 endpoints):**
/// - POST /workspaces - Create workspace
/// - GET /workspaces - List user's workspaces
/// - GET /workspaces/:id - Get workspace details
/// - PUT /workspaces/:id - Update workspace
/// - DELETE /workspaces/:id - Delete workspace
/// - POST /workspaces/:id/invite - Email invite
/// - POST /workspaces/:id/invite-link - Generate invite link with QR
/// - GET /workspaces/:id/invite-links - List active invites
/// - GET /workspaces/invite/:token - Get invite info
/// - POST /workspaces/join/:token - Join workspace
/// - DELETE /workspaces/:id/invite-links/:inviteId - Revoke invite
/// 
/// **Workspace Members (4 endpoints):**
/// - GET /workspaces/:id/members - List members
/// - POST /workspaces/:id/members - Add member
/// - PUT /workspaces/:id/members/:userId - Update member role
/// - DELETE /workspaces/:id/members/:userId - Remove member
/// 
/// **Boards (5 endpoints):**
/// - POST /boards - Create board
/// - GET /boards/workspace/:workspaceId - List workspace boards
/// - GET /boards/:id - Get board details
/// - PUT /boards/:id - Update board
/// - DELETE /boards/:id - Delete board
/// 
/// **Board Members (4 endpoints):**
/// - GET /boards/:id/members - List members
/// - POST /boards/:id/members - Add member
/// - PUT /boards/:id/members/:userId - Update member permission
/// - DELETE /boards/:id/members/:userId - Remove member
/// 
/// **Tasks (4 endpoints):**
/// - GET /tasks/board/:boardId - Get board tasks
/// - POST /tasks - Create task
/// - PUT /tasks/:id - Update task
/// - DELETE /tasks/:id - Delete task
/// 
/// **Operations (5 endpoints):**
/// - GET /operations/board/:boardId - Get operations (with ?since=timestamp)
/// - POST /operations - Save operation
/// - GET /operations/board/:boardId/count - Get operation count
/// - DELETE /operations/board/:boardId/cleanup - Cleanup old operations
/// 
/// **Permission System:**
/// - Workspace roles: owner (full control) / editor (create boards) / viewer (read-only)
/// - Board permissions: edit (full access) / view (read-only)
/// - Board ownership: is_board_owner (manage board members)
/// - Access control: owner sees ALL boards, editor/viewer only see boards they're added to

class ApiService {
  final String baseUrl;
  final StorageService storage;
  String? _accessToken;
  String? _refreshToken;

  ApiService({
    String? baseUrl,
    required this.storage,
  }) : baseUrl = baseUrl ?? (kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000');

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens({String? accessToken, String? refreshToken}) {
    if (accessToken != null) {
      _accessToken = accessToken;
      storage.saveAuthToken(accessToken);
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      storage.saveRefreshToken(refreshToken);
    }
  }

  Future<void> loadTokens() async {
    // Try to load access token first
    _accessToken = storage.getAuthToken();
    _refreshToken = await storage.getRefreshToken();
    
    // If no access token but have refresh token, try to refresh
    if (_accessToken == null && _refreshToken != null) {
      try {
        await refreshAccessToken();
      } catch (e) {
        // Refresh failed, clear tokens
        await clearTokens();
      }
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await storage.clearAuth();
  }

  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/token/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': _refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Save new access token
      _accessToken = data['accessToken'];
      await storage.saveAuthToken(data['accessToken']);
      
      // Handle refresh token rotation (if server provides new refresh token)
      if (data['refreshToken'] != null) {
        _refreshToken = data['refreshToken'];
        await storage.saveRefreshToken(data['refreshToken']);
      }
    } else {
      throw Exception('Token refresh failed');
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // Auto-retry helper with token refresh
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();

    // If unauthorized and we have a refresh token, try to refresh
    if (response.statusCode == 401 && _refreshToken != null) {
      try {
        await refreshAccessToken();
        response = await request(); // Retry with new access token
      } catch (e) {
        await clearTokens();
        rethrow;
      }
    }

    return response;
  }

  Future<http.Response> _get(String endpoint) async {
    return _requestWithRetry(() => http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    ));
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      setTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    // Always clear local tokens first for security
    final refreshTokenToRevoke = _refreshToken;
    await clearTokens();
    
    // Then try to revoke on server (best effort)
    if (refreshTokenToRevoke != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/token/logout'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refreshToken': refreshTokenToRevoke}),
        );
      } catch (e) {
        // Ignore server logout errors - local tokens already cleared
        debugPrint('Server logout failed: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _get('/auth/me');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get user info');
  }

  Future<void> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send reset email: ${response.body}');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'token': token,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to reset password');
    }
  }

  // Workspaces
  Future<Workspace> createWorkspace({required String name}) async {
    debugPrint('📤 Creating workspace: $name');
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces'),
      headers: _headers,
      body: json.encode({'name': name}),
    );

    debugPrint('📥 Response status: ${response.statusCode}');
    debugPrint('📥 Response body: ${response.body}');

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      debugPrint('✅ Workspace created: $data');
      return Workspace.fromJson(data);
    } else {
      throw Exception('Failed to create workspace: ${response.body}');
    }
  }

  Future<List<Workspace>> getWorkspaces() async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((w) => Workspace.fromJson(w)).toList();
    } else {
      throw Exception('Failed to get workspaces: ${response.body}');
    }
  }

  Future<void> inviteToWorkspace({
    required String workspaceId,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/invite'),
      headers: _headers,
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to invite user: ${response.body}');
    }
  }

  // Boards
  Future<Board> createBoard({
    required String workspaceId,
    required String name,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/boards'),
      headers: _headers,
      body: json.encode({
        'workspaceId': workspaceId,
        'name': name,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Board.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create board: ${response.body}');
    }
  }

  Future<List<Board>> getWorkspaceBoards(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/boards/workspace/$workspaceId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((b) => Board.fromJson(b)).toList();
    } else {
      throw Exception('Failed to get boards: ${response.body}');
    }
  }

  Future<Board> getBoard(String boardId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/boards/$boardId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Board.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get board: ${response.body}');
    }
  }

  Future<Workspace> updateWorkspace({
    required String workspaceId,
    required String name,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId'),
      headers: _headers,
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      return Workspace.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update workspace: ${response.body}');
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete workspace: ${response.body}');
    }
  }

  Future<Workspace> getWorkspace(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Workspace.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get workspace: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createInviteLink({
    required String workspaceId,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/invite-link'),
      headers: _headers,
      body: json.encode({
        if (maxUses != null) 'maxUses': maxUses,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create invite link: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getInviteLinks(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/invite-links'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get invite links: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getInviteInfo(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/invite/$token'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get invite info: ${response.body}');
    }
  }

  Future<void> joinWorkspace(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/join/$token'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to join workspace: ${response.body}');
    }
  }

  Future<void> revokeInviteLink({
    required String workspaceId,
    required String inviteId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/invite-links/$inviteId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to revoke invite: ${response.body}');
    }
  }

  // Workspace Members
  Future<List<Map<String, dynamic>>> getWorkspaceMembers(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/members'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get members: ${response.body}');
    }
  }

  Future<void> addWorkspaceMember({
    required String workspaceId,
    required String userId,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/members'),
      headers: _headers,
      body: json.encode({
        'userId': userId,
        'role': role,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add member: ${response.body}');
    }
  }

  Future<void> updateWorkspaceMemberRole({
    required String workspaceId,
    required String userId,
    required String role,
  }) async {
    final url = '$baseUrl/workspaces/$workspaceId/members/$userId';
    print('[API] PUT $url');
    print('[API] Headers: ${_headers}');
    print('[API] Body: ${json.encode({'role': role})}');
    
    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: json.encode({'role': role}),
    );

    print('[API] Response status: ${response.statusCode}');
    print('[API] Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update member role: ${response.body}');
    }
  }

  Future<void> removeWorkspaceMember({
    required String workspaceId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/members/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove member: ${response.body}');
    }
  }

  // Board CRUD
  Future<Board> updateBoard({
    required String boardId,
    String? name,
    String? description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/boards/$boardId'),
      headers: _headers,
      body: json.encode({
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return Board.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update board: ${response.body}');
    }
  }

  Future<void> deleteBoard(String boardId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/boards/$boardId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete board: ${response.body}');
    }
  }

  // Board Members
  Future<List<Map<String, dynamic>>> getBoardMembers(String boardId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/boards/$boardId/members'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get board members: ${response.body}');
    }
  }

  Future<void> addBoardMember({
    required String boardId,
    required String userId,
    required String permission,
  }) async {
    final url = '$baseUrl/boards/$boardId/members';
    final body = json.encode({
      'userId': userId,
      'permission': permission,
    });
    
    print('[API] POST $url');
    print('[API] Headers: ${_headers}');
    print('[API] Body: $body');
    
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    );

    print('[API] Response status: ${response.statusCode}');
    print('[API] Response body: ${response.body}');
    
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add board member: ${response.body}');
    }
  }

  Future<void> updateBoardMemberPermission({
    required String boardId,
    required String userId,
    required String permission,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/boards/$boardId/members/$userId'),
      headers: _headers,
      body: json.encode({'permission': permission}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update board member permission: ${response.body}');
    }
  }

  Future<void> removeBoardMember({
    required String boardId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/boards/$boardId/members/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove board member: ${response.body}');
    }
  }

  // Tasks
  Future<List<Map<String, dynamic>>> getBoardTasks(
    String boardId, {
    String? assigneeId,
    String? status,
    String? priority,
    String? parentId,
  }) async {
    final queryParams = <String, String>{};
    if (assigneeId != null) queryParams['assignee_id'] = assigneeId;
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (parentId != null) queryParams['parent_id'] = parentId;
    
    final uri = Uri.parse('$baseUrl/tasks/board/$boardId').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get tasks: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createTask({
    required String boardId,
    required String title,
    String? description,
    List<String>? assignees,
    String? status,
    String? priority,
    DateTime? deadline,
    String? parentId,
    List<String>? labels,
    double? estimatedHours,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers,
      body: json.encode({
        'boardId': boardId,
        'title': title,
        if (description != null) 'description': description,
        if (assignees != null) 'assignees': assignees,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        if (parentId != null) 'parent_id': parentId,
        if (labels != null) 'labels': labels,
        if (estimatedHours != null) 'estimated_hours': estimatedHours,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create task: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    String? title,
    String? description,
    List<String>? assignees,
    String? status,
    int? position,
    String? priority,
    DateTime? deadline,
    List<String>? labels,
    double? estimatedHours,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _headers,
      body: json.encode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (assignees != null) 'assignees': assignees,
        if (status != null) 'status': status,
        if (position != null) 'position': position,
        if (priority != null) 'priority': priority,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        if (labels != null) 'labels': labels,
        if (estimatedHours != null) 'estimated_hours': estimatedHours,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  Future<void> deleteTask(String taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }

  Future<void> reorderTasks({
    required String boardId,
    required String status,
    required List<String> taskIds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/reorder'),
      headers: _headers,
      body: json.encode({
        'boardId': boardId,
        'status': status,
        'taskIds': taskIds,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reorder tasks: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> moveTask({
    required String taskId,
    required String status,
    int? position,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/move'),
      headers: _headers,
      body: json.encode({
        'status': status,
        if (position != null) 'position': position,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to move task: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTaskStats(String boardId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/board/$boardId/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get task stats: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getMyTasks({
    String? status,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;
    
    final uri = Uri.parse('$baseUrl/tasks/my-tasks').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get my tasks: ${response.body}');
    }
  }

  // Operations (P2P Sync)
  Future<List<Map<String, dynamic>>> getBoardOperations(
    String boardId, {
    int? since,
  }) async {
    final uri = since != null
        ? Uri.parse('$baseUrl/operations/board/$boardId?since=$since')
        : Uri.parse('$baseUrl/operations/board/$boardId');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get operations: ${response.body}');
    }
  }

  Future<void> saveOperation({
    required String boardId,
    required String operationId,
    required String operationType,
    required Map<String, dynamic> payload,
    required int timestamp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/operations'),
      headers: _headers,
      body: json.encode({
        'boardId': boardId,
        'operationId': operationId,
        'operationType': operationType,
        'payload': payload,
        'timestamp': timestamp,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to save operation: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOperationCount(String boardId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/operations/board/$boardId/count'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get operation count: ${response.body}');
    }
  }

  Future<void> cleanupOperations(String boardId, int olderThan) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/operations/board/$boardId/cleanup'),
      headers: _headers,
      body: json.encode({'olderThan': olderThan}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cleanup operations: ${response.body}');
    }
  }
}
