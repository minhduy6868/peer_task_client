import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/workspace/workspace.dart';
import '../models/board/board.dart';
import '../models/api_error.dart';
import 'storage_service.dart';
import 'config_service.dart';

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
  String baseUrl;
  final StorageService storage;
  final ConfigService configService;
  String? _accessToken;
  String? _refreshToken;

  ApiService({
    String? baseUrl,
    required this.storage,
    required this.configService,
  }) : baseUrl = baseUrl ?? configService.cachedUrl ?? 'http://localhost:3000' {
    // If no cached URL, initialize asynchronously in background
    if (baseUrl == null && configService.cachedUrl == null) {
      _initializeBaseUrl();
    }
  }

  Future<void> _initializeBaseUrl() async {
    try {
      baseUrl = await configService.getBackendUrl();
    } catch (e) {
      // Keep using fallback localhost
    }
  }

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
      throw ApiError.unauthorized('No refresh token available');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setTokens(accessToken: data['accessToken']);
      } else {
        throw ApiError.unauthorized('Token refresh failed');
      }
    } catch (e) {
      // Nếu refresh token fail, thử refresh URL và retry
      debugPrint('⚠️ Token refresh failed, checking if URL issue: $e');
      await _handleConnectionError();
      rethrow;
    }
  }
  
  /// Handle connection error - refresh URL từ Firebase và retry
  Future<void> _handleConnectionError() async {
    debugPrint('🔄 Handling connection error, refreshing URL...');
    final newUrl = await configService.handleApiError();
    if (newUrl != baseUrl) {
      baseUrl = newUrl;
      debugPrint('✅ Updated baseUrl to: $baseUrl');
    }
  }
  
  /// Wrapper cho HTTP requests với auto-retry on connection error
  Future<http.Response> _safeHttpRequest(
    Future<http.Response> Function() request, {
    int maxRetries = 1,
  }) async {
    http.Response? response;
    Exception? lastError;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        response = await request();
        
        // Check if response indicates connection issue
        if (response.statusCode >= 500 || response.statusCode == 0) {
          throw ApiError.server('Server error: ${response.statusCode}');
        }
        
        return response;
        
      } on SocketException catch (e) {
        lastError = e;
        debugPrint('❌ Socket error (attempt ${attempt + 1}/${maxRetries + 1}): $e');
        
        if (attempt < maxRetries) {
          await _handleConnectionError();
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      } on TimeoutException catch (e) {
        lastError = e as Exception;
        debugPrint('❌ Timeout (attempt ${attempt + 1}/${maxRetries + 1}): $e');
        
        if (attempt < maxRetries) {
          await _handleConnectionError();
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      } catch (e) {
        lastError = e as Exception;
        debugPrint('❌ Request error (attempt ${attempt + 1}/${maxRetries + 1}): $e');
        
        if (attempt < maxRetries) {
          await _handleConnectionError();
          await Future.delayed(Duration(seconds: attempt + 1));
        } else {
          rethrow;
        }
      }
    }
    
    throw lastError ?? Exception('Request failed after $maxRetries retries');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // Auto-retry helper with token refresh
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiError.timeout(),
      );

      // If unauthorized and we have a refresh token, try to refresh
      if (response.statusCode == 401 && _refreshToken != null) {
        try {
          await refreshAccessToken();
          response = await request().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiError.timeout(),
          );
        } catch (e) {
          await clearTokens();
          rethrow;
        }
      }

      return response;
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on http.ClientException {
      throw ApiError.network('Failed to connect to server');
    }
  }

  /// Parse response and handle errors
  dynamic _handleResponse(http.Response response, {bool expectData = true}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (!expectData) return null;
      
      try {
        return json.decode(response.body);
      } catch (e) {
        throw ApiError(
          message: 'Failed to parse server response',
          code: 'PARSE_ERROR',
          statusCode: response.statusCode,
        );
      }
    }

    // Handle error responses
    try {
      final errorData = json.decode(response.body);
      throw ApiError.fromJson(errorData);
    } catch (e) {
      if (e is ApiError) rethrow;
      
      // Fallback error messages based on status code
      switch (response.statusCode) {
        case 400:
          throw ApiError.validation('Bad request');
        case 401:
          throw ApiError.unauthorized();
        case 403:
          throw ApiError.forbidden();
        case 404:
          throw ApiError.notFound();
        case 408:
          throw ApiError.timeout();
        case 500:
        case 502:
        case 503:
          throw ApiError.server();
        default:
          throw ApiError(
            message: 'Request failed with status ${response.statusCode}',
            code: 'HTTP_ERROR',
            statusCode: response.statusCode,
          );
      }
    }
  }

  Future<http.Response> _get(String endpoint) async {
    return _requestWithRetry(() => http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    ));
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    return _requestWithRetry(() => http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(body),
    ));
  }

  Future<http.Response> _put(String endpoint, Map<String, dynamic> body) async {
    return _requestWithRetry(() => http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(body),
    ));
  }

  Future<http.Response> _delete(String endpoint, [Map<String, dynamic>? body]) async {
    return _requestWithRetry(() => http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    ));
  }

  List<Map<String, dynamic>> _mapList(dynamic data) {
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiError.timeout(),
      );

      final data = _handleResponse(response);
      setTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return data;
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError.server('Registration failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiError.timeout(),
      );

      // Don't use _requestWithRetry for login - direct response handling
      final data = _handleResponse(response);
      setTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return data;
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError.server('Login failed: ${e.toString()}');
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
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;

    final response = await _put('/auth/profile', body);
    return _handleResponse(response);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    _handleResponse(response, expectData: false);
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiError.timeout(),
      );

      _handleResponse(response, expectData: false);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError.server('Failed to send reset email');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiError.timeout(),
      );

      _handleResponse(response, expectData: false);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError.server('Failed to reset password');
    }
  }

  Future<Workspace> createWorkspace({required String name}) async {
    final data = _handleResponse(await _post('/workspaces', {'name': name}));
    return Workspace.fromJson(data);
  }

  Future<List<Workspace>> getWorkspaces() async {
    final List data = _handleResponse(await _get('/workspaces'));
    return data.map((w) => Workspace.fromJson(w)).toList();
  }

  Future<void> inviteToWorkspace({
    required String workspaceId,
    required String email,
  }) async {
    _handleResponse(
      await _post('/workspaces/$workspaceId/invite', {'email': email}),
      expectData: false,
    );
  }

  Future<Board> createBoard({
    required String workspaceId,
    required String name,
    String? description,
  }) async {
    final data = _handleResponse(await _post('/boards', {
      'workspaceId': workspaceId,
      'name': name,
      if (description != null) 'description': description,
    }));
    return Board.fromJson(data);
  }

  Future<List<Board>> getWorkspaceBoards(String workspaceId) async {
    final List data = _handleResponse(await _get('/boards/workspace/$workspaceId'));
    return data.map((b) => Board.fromJson(b)).toList();
  }

  Future<Board> getBoard(String boardId) async {
    return Board.fromJson(_handleResponse(await _get('/boards/$boardId')));
  }

  Future<Workspace> updateWorkspace({
    required String workspaceId,
    required String name,
  }) async {
    final data = _handleResponse(
      await _put('/workspaces/$workspaceId', {'name': name}),
    );
    return Workspace.fromJson(data);
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    _handleResponse(await _delete('/workspaces/$workspaceId'), expectData: false);
  }

  Future<Workspace> getWorkspace(String workspaceId) async {
    return Workspace.fromJson(_handleResponse(await _get('/workspaces/$workspaceId')));
  }

  Future<Map<String, dynamic>> createInviteLink({
    required String workspaceId,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    return Map<String, dynamic>.from(_handleResponse(await _post(
      '/workspaces/$workspaceId/invite-link',
      {
        if (maxUses != null) 'maxUses': maxUses,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      },
    )));
  }

  Future<List<Map<String, dynamic>>> getInviteLinks(String workspaceId) async {
    return _mapList(_handleResponse(await _get('/workspaces/$workspaceId/invite-links')));
  }

  Future<Map<String, dynamic>> getInviteInfo(String token) async {
    return Map<String, dynamic>.from(
      _handleResponse(await _get('/workspaces/invite/$token')),
    );
  }

  Future<void> joinWorkspace(String token) async {
    _handleResponse(await _post('/workspaces/join/$token', {}), expectData: false);
  }

  Future<void> revokeInviteLink({
    required String workspaceId,
    required String inviteId,
  }) async {
    _handleResponse(
      await _delete('/workspaces/$workspaceId/invite-links/$inviteId'),
      expectData: false,
    );
  }

  Future<List<Map<String, dynamic>>> getWorkspaceMembers(String workspaceId) async {
    return _mapList(_handleResponse(await _get('/workspaces/$workspaceId/members')));
  }

  Future<void> addWorkspaceMember({
    required String workspaceId,
    required String userId,
    required String role,
  }) async {
    _handleResponse(
      await _post('/workspaces/$workspaceId/members', {
        'userId': userId,
        'role': role,
      }),
      expectData: false,
    );
  }

  Future<void> updateWorkspaceMemberRole({
    required String workspaceId,
    required String userId,
    required String role,
  }) async {
    _handleResponse(
      await _put('/workspaces/$workspaceId/members/$userId', {'role': role}),
      expectData: false,
    );
  }

  Future<void> removeWorkspaceMember({
    required String workspaceId,
    required String userId,
  }) async {
    _handleResponse(
      await _delete('/workspaces/$workspaceId/members/$userId'),
      expectData: false,
    );
  }

  Future<Board> updateBoard({
    required String boardId,
    String? name,
    String? description,
  }) async {
    return Board.fromJson(_handleResponse(await _put('/boards/$boardId', {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    })));
  }

  Future<void> deleteBoard(String boardId) async {
    _handleResponse(await _delete('/boards/$boardId'), expectData: false);
  }

  Future<List<Map<String, dynamic>>> getBoardMembers(String boardId) async {
    return _mapList(_handleResponse(await _get('/boards/$boardId/members')));
  }

  Future<void> addBoardMember({
    required String boardId,
    required String userId,
    required String permission,
  }) async {
    _handleResponse(
      await _post('/boards/$boardId/members', {
        'userId': userId,
        'permission': permission,
      }),
      expectData: false,
    );
  }

  Future<void> updateBoardMemberPermission({
    required String boardId,
    required String userId,
    required String permission,
  }) async {
    _handleResponse(
      await _put('/boards/$boardId/members/$userId', {'permission': permission}),
      expectData: false,
    );
  }

  Future<void> removeBoardMember({
    required String boardId,
    required String userId,
  }) async {
    _handleResponse(
      await _delete('/boards/$boardId/members/$userId'),
      expectData: false,
    );
  }

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

    final response = await _requestWithRetry(() => http.get(uri, headers: _headers));
    return _mapList(_handleResponse(response));
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
    return Map<String, dynamic>.from(_handleResponse(await _post('/tasks', {
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
    })));
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
    return Map<String, dynamic>.from(_handleResponse(await _put('/tasks/$taskId', {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (assignees != null) 'assignees': assignees,
      if (status != null) 'status': status,
      if (position != null) 'position': position,
      if (priority != null) 'priority': priority,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      if (labels != null) 'labels': labels,
      if (estimatedHours != null) 'estimated_hours': estimatedHours,
    })));
  }

  Future<void> deleteTask(String taskId) async {
    _handleResponse(await _delete('/tasks/$taskId'), expectData: false);
  }

  Future<void> reorderTasks({
    required String boardId,
    required String status,
    required List<String> taskIds,
  }) async {
    _handleResponse(
      await _post('/tasks/reorder', {
        'boardId': boardId,
        'status': status,
        'taskIds': taskIds,
      }),
      expectData: false,
    );
  }

  Future<Map<String, dynamic>> moveTask({
    required String taskId,
    required String status,
    String? boardId,
    int? position,
  }) async {
    return Map<String, dynamic>.from(_handleResponse(await _post('/tasks/$taskId/move', {
      'status': status,
      if (boardId != null) 'boardId': boardId,
      if (position != null) 'position': position,
    })));
  }

  Future<Map<String, dynamic>> getTaskStats(String boardId) async {
    return Map<String, dynamic>.from(
      _handleResponse(await _get('/tasks/board/$boardId/stats')),
    );
  }

  Future<List<Map<String, dynamic>>> getMyTasks({
    String? status,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };
    final uri = Uri.parse('$baseUrl/tasks/my-tasks').replace(queryParameters: queryParams);
    final response = await _requestWithRetry(() => http.get(uri, headers: _headers));
    return _mapList(_handleResponse(response));
  }

  Future<List<Map<String, dynamic>>> getBoardOperations(
    String boardId, {
    int? since,
  }) async {
    final path = since != null
        ? '/operations/board/$boardId?since=$since'
        : '/operations/board/$boardId';
    return _mapList(_handleResponse(await _get(path)));
  }

  Future<void> saveOperation({
    required String boardId,
    required String operationId,
    required String operationType,
    required Map<String, dynamic> payload,
    required int timestamp,
  }) async {
    _handleResponse(
      await _post('/operations', {
        'boardId': boardId,
        'operationId': operationId,
        'operationType': operationType,
        'payload': payload,
        'timestamp': timestamp,
      }),
      expectData: false,
    );
  }

  Future<Map<String, dynamic>> getOperationCount(String boardId) async {
    return Map<String, dynamic>.from(
      _handleResponse(await _get('/operations/board/$boardId/count')),
    );
  }

  Future<void> cleanupOperations(String boardId, int olderThan) async {
    _handleResponse(
      await _delete('/operations/board/$boardId/cleanup', {'olderThan': olderThan}),
      expectData: false,
    );
  }
}
