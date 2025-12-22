import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

/// Service quản lý cấu hình server URL
/// Cho phép load từ Firebase Realtime Database, assets và lưu override vào local storage
class ConfigService {
  static const String _configBoxName = 'app_config';
  static const String _serverUrlKey = 'server_url';
  static const String _assetConfigPath = 'assets/config.json';
  static const String _firebaseUrl = 'https://clone-puretrovey-default-rtdb.firebaseio.com/peer-task-be-url.json';
  
  late Box _configBox;
  String? _cachedServerUrl;
  
  /// Get cached URL (for ApiService initialization)
  String? get cachedUrl => _cachedServerUrl;
  
  /// Get backend URL with async initialization if needed
  Future<String> getBackendUrl() async {
    if (_cachedServerUrl == null) {
      await _loadConfig();
    }
    return serverUrl;
  }
  
  /// Initialize ConfigService
  Future<void> init() async {
    _configBox = await Hive.openBox(_configBoxName);
    await _loadConfig();
  }
  
  /// Load config with priority and retry:
  /// 1. User override (local storage)
  /// 2. Firebase Realtime Database (REST API - works on all platforms)
  /// 3. Assets config.json
  /// 4. Fallback localhost
  Future<void> _loadConfig() async {
    try {
      // 1. Check user override
      final savedUrl = _configBox.get(_serverUrlKey);
      
      if (savedUrl != null && savedUrl is String && savedUrl.isNotEmpty) {
        _cachedServerUrl = savedUrl;
        debugPrint('📱 Using saved server URL: $_cachedServerUrl');
        final isHealthy = await testConnection(_cachedServerUrl!);
        if (!isHealthy) {
          debugPrint('⚠️ Saved URL unhealthy, trying Firebase...');
          await _tryLoadFromFirebase();
        }
        return;
      }
      
      // 2. Load from Firebase (REST API works on all platforms)
      final firebaseLoaded = await _tryLoadFromFirebase();
      if (firebaseLoaded) {
        return;
      }
      
      // 3. Load from assets/config.json
      try {
        final configString = await rootBundle.loadString(_assetConfigPath);
        final configJson = jsonDecode(configString) as Map<String, dynamic>;
        
        _cachedServerUrl = configJson['api_base_url'] as String?;
        if (_cachedServerUrl != null && _cachedServerUrl!.isNotEmpty) {
          debugPrint('📱 Loaded server URL from assets: $_cachedServerUrl');
          final isHealthy = await testConnection(_cachedServerUrl!);
          if (isHealthy) {
            return;
          } else {
            debugPrint('⚠️ Assets URL unhealthy, using fallback...');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Assets load failed: $e');
      }
      
      // 4. Fallback
      _cachedServerUrl = _getDefaultUrl();
      debugPrint('📱 Using fallback URL: $_cachedServerUrl');
      
    } catch (e) {
      debugPrint('⚠️ Error loading config: $e');
      _cachedServerUrl = _getDefaultUrl();
    }
  }
  
  /// Get default URL based on platform
  String _getDefaultUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (_isDesktopPlatform()) {
      return 'http://localhost:3000';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }
  
  /// Check if desktop platform
  bool _isDesktopPlatform() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// Try load from Firebase using REST API
  Future<bool> _tryLoadFromFirebase({int maxRetries = 2}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('🔥 Firebase load attempt ${attempt + 1}/$maxRetries...');
        
        final response = await http.get(
          Uri.parse(_firebaseUrl),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final firebaseUrl = json.decode(response.body) as String?;
          
          if (firebaseUrl != null && firebaseUrl.isNotEmpty && _isValidUrl(firebaseUrl)) {
            final isHealthy = await testConnection(firebaseUrl);
            if (isHealthy) {
              _cachedServerUrl = firebaseUrl;
              debugPrint('✅ Firebase URL verified: $_cachedServerUrl');
              return true;
            } else {
              debugPrint('⚠️ Firebase URL unhealthy: $firebaseUrl');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Firebase attempt ${attempt + 1} failed: $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }
    return false;
  }
  
  /// Get current server URL
  String get serverUrl {
    return _cachedServerUrl ?? _getDefaultUrl();
  }
  
  /// Update server URL
  Future<void> updateServerUrl(String newUrl) async {
    if (!_isValidUrl(newUrl)) {
      throw ArgumentError('Invalid URL format: $newUrl');
    }
    
    await _configBox.put(_serverUrlKey, newUrl);
    _cachedServerUrl = newUrl;
    
    debugPrint('✅ Server URL updated to: $newUrl');
  }
  
  /// Reset to default
  Future<void> resetToDefault() async {
    await _configBox.delete(_serverUrlKey);
    await _loadConfig();
    debugPrint('🔄 Server URL reset to default: $_cachedServerUrl');
  }
  
  /// Refresh from Firebase
  Future<bool> refreshFromFirebase({int maxRetries = 2}) async {
    debugPrint('🔄 Refreshing URL from Firebase...');
    
    final loaded = await _tryLoadFromFirebase(maxRetries: maxRetries);
    
    if (!loaded) {
      _cachedServerUrl = _getDefaultUrl();
      debugPrint('⚠️ Firebase refresh failed, using default: $_cachedServerUrl');
    }
    
    return loaded;
  }
  
  /// Handle API error
  Future<String> handleApiError() async {
    debugPrint('❌ API Error detected, attempting recovery...');
    
    final refreshed = await refreshFromFirebase(maxRetries: 2);
    if (refreshed) {
      return serverUrl;
    }
    
    _cachedServerUrl = _getDefaultUrl();
    debugPrint('🏠 Using default fallback: $_cachedServerUrl');
    
    return serverUrl;
  }
  
  /// Watch URL changes (polling)
  Stream<String> watchUrlChanges() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      try {
        final response = await http.get(Uri.parse(_firebaseUrl));
        if (response.statusCode == 200) {
          final url = json.decode(response.body) as String?;
          if (url != null && url.isNotEmpty && _isValidUrl(url)) {
            if (_cachedServerUrl != url) {
              _cachedServerUrl = url;
              debugPrint('🔥 Firebase URL changed: $url');
              yield url;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Firebase polling error: $e');
      }
    }
  }
  
  /// Validate URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// Test connection
  Future<bool> testConnection(String url) async {
    try {
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 5));
      
      debugPrint('🔍 Connection test to $url: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }
  
  /// Get config
  Map<String, dynamic> getConfig() {
    return {
      'server_url': serverUrl,
      'is_custom': _configBox.containsKey(_serverUrlKey),
      'cached_at': DateTime.now().toIso8601String(),
    };
  }
}
