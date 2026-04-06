import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';

/// AI Service for Ollama LLM integration
/// ALWAYS prioritizes online server proxy (ngrok), falls back to localhost only if unavailable
/// Provides brainstorming, task generation, and smart suggestions
class AIService {
  /// Ollama API endpoint (fallback for direct connection)
  String _ollamaUrl;
  String get ollamaUrl => _ollamaUrl;
  
  /// Server URL for proxy mode (prioritized)
  String? _serverUrl;
  String? get serverUrl => _serverUrl;
  
  /// Use proxy through server (ALWAYS prioritize online)
  bool _useProxy = false;
  bool get useProxy => _useProxy;
  
  /// ConfigService reference
  final ConfigService? _configService;
  
  /// Default model to use
  final String defaultModel;
  
  /// HTTP client
  final http.Client _client;
  
  /// Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  /// Available models
  List<String> _availableModels = [];
  List<String> get availableModels => _availableModels;

  AIService({
    String? ollamaUrl,
    this.defaultModel = 'llama3.2:1b',
    ConfigService? configService,
  }) : _ollamaUrl = ollamaUrl ?? 'http://localhost:11434',
       _configService = configService,
       _client = http.Client();
  
  /// Initialize with ConfigService (call this after ConfigService.init())
  /// ALWAYS prioritizes online server proxy, fallback to localhost only if unavailable
  Future<void> init() async {
    if (_configService != null) {
      _serverUrl = _configService.serverUrl;
      _ollamaUrl = await _configService.getOllamaUrl();
      
      // PRIORITY: Always try server proxy first if server URL is online (not localhost)
      final isServerOnline = _serverUrl != null && 
          !_serverUrl!.contains('localhost') && 
          !_serverUrl!.contains('127.0.0.1') &&
          !_serverUrl!.contains('10.0.2.2');
      
      if (isServerOnline) {
        // Server is online (ngrok) → use proxy mode
        _useProxy = true;
        debugPrint('🤖 AIService: Using ONLINE proxy mode through server: $_serverUrl');
      } else {
        // Server is localhost → use direct Ollama (only works on desktop)
        _useProxy = false;
        debugPrint('🤖 AIService: Using direct Ollama (localhost): $_ollamaUrl');
      }
      
      debugPrint('🤖 AIService initialized: serverUrl=$_serverUrl, ollamaUrl=$_ollamaUrl, useProxy=$_useProxy');
    }
  }
  
  /// Update Ollama URL dynamically
  void updateUrl(String newUrl) {
    _ollamaUrl = newUrl;
    _isConnected = false; // Reset connection status
    debugPrint('🤖 AIService URL updated to: $_ollamaUrl');
  }
  
  /// Refresh URL from Firebase and re-determine proxy mode
  Future<void> refreshFromFirebase() async {
    if (_configService != null) {
      await _configService.refreshFromFirebase();
      _serverUrl = _configService.serverUrl;
      _ollamaUrl = _configService.ollamaUrl;
      
      // Re-check if should use proxy
      final isServerOnline = _serverUrl != null && 
          !_serverUrl!.contains('localhost') && 
          !_serverUrl!.contains('127.0.0.1') &&
          !_serverUrl!.contains('10.0.2.2');
      
      _useProxy = isServerOnline;
      debugPrint('🤖 AIService refreshed: serverUrl=$_serverUrl, useProxy=$_useProxy');
    }
  }

  /// Check if Ollama is running and get available models
  /// Tries proxy first (online), then fallback to direct localhost
  Future<bool> checkConnection() async {
    // PRIORITY 1: Try server proxy (online) first
    if (_serverUrl != null && !_serverUrl!.contains('localhost')) {
      try {
        final proxyUrl = '$_serverUrl/ai/tags';
        debugPrint('🤖 Trying proxy connection: $proxyUrl');
        
        final response = await _client
            .get(
              Uri.parse(proxyUrl),
              headers: {'ngrok-skip-browser-warning': 'true'},
            )
            .timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final models = data['models'] as List? ?? [];
          _availableModels = models
              .map((m) => m['name']?.toString() ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
          _isConnected = true;
          _useProxy = true;
          debugPrint('✅ Ollama connected via PROXY: $proxyUrl. Models: $_availableModels');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Proxy connection failed: $e');
      }
    }
    
    // PRIORITY 2: Fallback to direct Ollama (only works on desktop)
    try {
      final directUrl = '$_ollamaUrl/api/tags';
      debugPrint('🤖 Trying direct connection: $directUrl');
      
      final response = await _client
          .get(
            Uri.parse(directUrl),
            headers: {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List? ?? [];
        _availableModels = models
            .map((m) => m['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        _isConnected = true;
        _useProxy = false;
        debugPrint('✅ Ollama connected DIRECT: $directUrl. Models: $_availableModels');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Direct Ollama connection failed: $e');
    }
    
    _isConnected = false;
    return false;
  }

  /// Generate text response from Ollama
  /// Returns a stream of response chunks for real-time display
  Stream<String> generateStream({
    required String prompt,
    String? model,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async* {
    final useModel = model ?? defaultModel;
    
    // Choose endpoint based on proxy mode
    final endpoint = _useProxy 
        ? '$_serverUrl/ai/generate/stream'  // Proxy endpoint
        : '$_ollamaUrl/api/generate';        // Direct Ollama
    
    debugPrint('🤖 Generating via ${_useProxy ? "proxy" : "direct"}: $endpoint');
    
    try {
      final request = http.Request(
        'POST',
        Uri.parse(endpoint),
      );
      
      request.headers['Content-Type'] = 'application/json';
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.body = json.encode({
        'model': useModel,
        'prompt': prompt,
        if (systemPrompt != null) 'system': systemPrompt,
        'stream': true,
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
        },
      });

      final streamedResponse = await _client.send(request);
      
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // Each chunk may contain multiple JSON objects separated by newlines
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = json.decode(line);
            final response = data['response'] as String? ?? '';
            if (response.isNotEmpty) {
              yield response;
            }
            // Check if done
            if (data['done'] == true) {
              return;
            }
          } catch (e) {
            // Skip malformed JSON
          }
        }
      }
    } catch (e) {
      debugPrint('❌ AI generate error: $e');
      yield '[Error: $e]';
    }
  }

  /// Generate text response (non-streaming, returns complete response)
  Future<String> generate({
    required String prompt,
    String? model,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    final useModel = model ?? defaultModel;
    
    // Choose endpoint based on proxy mode
    final endpoint = _useProxy 
        ? '$_serverUrl/ai/generate'    // Proxy endpoint
        : '$_ollamaUrl/api/generate';  // Direct Ollama
    
    debugPrint('🤖 Generating (non-stream) via ${_useProxy ? "proxy" : "direct"}: $endpoint');
    
    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'model': useModel,
          'prompt': prompt,
          if (systemPrompt != null) 'system': systemPrompt,
          'stream': false,
          'options': {
            'temperature': temperature,
            'num_predict': maxTokens,
          },
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] as String? ?? '';
      } else {
        throw Exception('Ollama error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ AI generate error: $e');
      rethrow;
    }
  }

  /// Brainstorm ideas from a topic or seed idea
  /// Returns expanded ideas, suggestions, and related concepts
  Stream<String> brainstorm({
    required String idea,
    String? context,
    int maxIdeas = 5,
    String language = 'Vietnamese',
  }) {
    final systemPrompt = '''Bạn là trợ lý brainstorm sáng tạo cho ứng dụng whiteboard cộng tác.
Nhiệm vụ của bạn là giúp người dùng mở rộng ý tưởng và đưa ra gợi ý sáng tạo.
LUÔN trả lời bằng tiếng Việt.
Sử dụng format rõ ràng với emoji và bullet points.
Tập trung vào các ý tưởng thực tế, có thể hành động được.

QUY TẮC FORMAT:
- Dùng emoji ở đầu mỗi section chính
- Dùng bullet points (•) cho các mục con
- Mỗi ý tưởng ngắn gọn 1-2 câu
- KHÔNG dùng markdown bold (**) hay italic (*)
- Ngăn cách các section bằng dòng trống''';

    final prompt = '''Hãy brainstorm và mở rộng ý tưởng sau:

Chủ đề: $idea
${context != null ? '\nBối cảnh: $context' : ''}

Trả lời theo format sau:

🎯 Ý TƯỞNG CHÍNH
Giải thích và làm rõ ý tưởng cốt lõi trong 2-3 câu.

💡 $maxIdeas Ý TƯỞNG LIÊN QUAN
• Ý tưởng 1: mô tả ngắn
• Ý tưởng 2: mô tả ngắn
• Ý tưởng 3: mô tả ngắn
• Ý tưởng 4: mô tả ngắn
• Ý tưởng 5: mô tả ngắn

🔗 KẾT NỐI
• Liên kết với khái niệm/lĩnh vực khác
• Cơ hội phát triển

⚡ HÀNH ĐỘNG TIẾP THEO
• Bước 1: hành động cụ thể
• Bước 2: hành động cụ thể
• Bước 3: hành động cụ thể

❓ CÂU HỎI ĐỂ SUY NGẪM
• Câu hỏi gợi mở 1?
• Câu hỏi gợi mở 2?''';

    return generateStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      temperature: 0.8, // Higher for creativity
      maxTokens: 1024,
    );
  }

  /// Generate tasks from a project description
  Stream<String> generateTasks({
    required String projectDescription,
    String? existingTasks,
    int maxTasks = 10,
    String language = 'Vietnamese',
  }) {
    final systemPrompt = '''Bạn là trợ lý quản lý dự án.
Tạo các task thực tế, có cấu trúc rõ ràng cho dự án được mô tả.
LUÔN trả lời bằng tiếng Việt.
Mỗi task phải rõ ràng, có thể hành động được và có ước tính thời gian.

QUY TẮC FORMAT:
- Dùng emoji cho mỗi category
- Dùng checkbox (☐) cho mỗi task
- Ghi rõ độ ưu tiên và thời gian ước tính
- KHÔNG dùng markdown bold (**) hay italic (*)''';

    final prompt = '''Tạo danh sách task cho dự án sau:

Dự án: $projectDescription
${existingTasks != null ? '\nCác task hiện có: $existingTasks' : ''}

Tạo tối đa $maxTasks tasks theo format:

📋 DANH SÁCH CÔNG VIỆC

🔴 ƯU TIÊN CAO
☐ Tên task 1 (Thời gian: Xh)
   Mô tả ngắn gọn việc cần làm
☐ Tên task 2 (Thời gian: Xh)
   Mô tả ngắn gọn

🟡 ƯU TIÊN TRUNG BÌNH
☐ Tên task (Thời gian: Xh)
   Mô tả ngắn gọn

🟢 ƯU TIÊN THẤP
☐ Tên task (Thời gian: Xh)
   Mô tả ngắn gọn

📊 TỔNG KẾT
• Tổng số task: X
• Tổng thời gian ước tính: Xh''';

    return generateStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      temperature: 0.6, // Lower for more structured output
      maxTokens: 1500,
    );
  }

  /// Get smart suggestions based on current board state
  Stream<String> getSuggestions({
    required List<String> currentTasks,
    required List<String> completedTasks,
    String? projectGoal,
    String language = 'Vietnamese',
  }) {
    final systemPrompt = '''Bạn là trợ lý năng suất phân tích task board.
Đưa ra gợi ý hữu ích để cải thiện quy trình làm việc và tiến độ.
LUÔN trả lời bằng tiếng Việt. Ngắn gọn và thực tế.

QUY TẮC FORMAT:
- Dùng emoji cho sections
- Bullet points cho các điểm chi tiết
- KHÔNG dùng markdown formatting''';

    final prompt = '''Phân tích board này và đưa ra gợi ý:

Công việc đang làm: ${currentTasks.join(', ')}
Công việc đã hoàn thành: ${completedTasks.join(', ')}
${projectGoal != null ? 'Mục tiêu dự án: $projectGoal' : ''}

Trả lời theo format:

📊 PHÂN TÍCH TIẾN ĐỘ
Đánh giá ngắn gọn tình trạng hiện tại.

🎯 ƯU TIÊN GỢI Ý
• Việc nên tập trung tiếp theo
• Lý do

⚠️ RỦI RO TIỀM ẨN
• Vấn đề có thể xảy ra
• Cách phòng tránh

💡 GỢI Ý CẢI THIỆN
• Mẹo 1
• Mẹo 2
• Mẹo 3''';

    return generateStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      temperature: 0.5,
      maxTokens: 800,
    );
  }

  /// Improve or refine existing text/idea
  Stream<String> improve({
    required String text,
    String? instruction,
    String language = 'Vietnamese',
  }) {
    final systemPrompt = '''Bạn là trợ lý viết lách.
Giúp cải thiện và hoàn thiện văn bản trong khi giữ nguyên ý định ban đầu.
LUÔN trả lời bằng tiếng Việt.

QUY TẮC FORMAT:
- Trình bày rõ ràng bản cải thiện
- Giải thích ngắn gọn các thay đổi
- KHÔNG dùng markdown formatting''';

    final prompt = '''Cải thiện văn bản sau:

Văn bản gốc: $text
${instruction != null ? '\nYêu cầu: $instruction' : ''}

Trả lời theo format:

✨ VĂN BẢN CẢI THIỆN
[Văn bản đã được cải thiện]

📝 THAY ĐỔI
• Điểm thay đổi 1
• Điểm thay đổi 2
• Điểm thay đổi 3''';

    return generateStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      temperature: 0.6,
      maxTokens: 512,
    );
  }

  /// Clean up resources
  void dispose() {
    _client.close();
  }
}
