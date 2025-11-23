import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workspace.dart';
import '../models/board.dart';
import 'storage_service.dart';

class ApiService {
  final String baseUrl;
  final StorageService storage;
  String? _accessToken;
  String? _refreshToken;

  ApiService({
    this.baseUrl = 'http://localhost:3000',
    required this.storage,
  });

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      storage.saveRefreshToken(refreshToken);
    }
  }

  Future<void> loadTokens() async {
    _refreshToken = await storage.getRefreshToken();
    if (_refreshToken != null) {
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
    await storage.saveRefreshToken(null);
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
      _accessToken = data['accessToken'];
    } else {
      throw Exception('Token refresh failed');
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // Auto-retry helper for future use
  // ignore: unused_element
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
    if (_refreshToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/token/logout'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refreshToken': _refreshToken}),
        );
      } catch (e) {
        // Ignore logout errors
      }
    }
    await clearTokens();
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
    print('📤 Creating workspace: $name');
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces'),
      headers: _headers,
      body: json.encode({'name': name}),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      print('✅ Workspace created: $data');
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
}
