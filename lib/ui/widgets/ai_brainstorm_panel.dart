import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_service.dart';
import '../../services/config_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// AI Brainstorm Panel Widget
/// A beautiful, interactive panel for AI-powered brainstorming
class AIBrainstormPanel extends StatefulWidget {
  /// Initial idea/topic to brainstorm (optional)
  final String? initialIdea;
  
  /// Callback when user wants to create task from AI suggestion
  final Function(String title, String? description)? onCreateTask;
  
  /// Callback when user wants to add text to board
  final Function(String text)? onAddToBoard;
  
  /// ConfigService for dynamic URL loading
  final ConfigService? configService;

  const AIBrainstormPanel({
    super.key,
    this.initialIdea,
    this.onCreateTask,
    this.onAddToBoard,
    this.configService,
  });

  @override
  State<AIBrainstormPanel> createState() => _AIBrainstormPanelState();
}

class _AIBrainstormPanelState extends State<AIBrainstormPanel>
    with SingleTickerProviderStateMixin {
  late AIService _aiService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _pulseController;
  
  bool _isConnected = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  String _response = '';
  String _selectedMode = 'brainstorm';
  
  // History of conversations
  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _aiService = AIService(configService: widget.configService);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    if (widget.initialIdea != null) {
      _inputController.text = widget.initialIdea!;
    }
    _initAIService();
  }
  
  Future<void> _initAIService() async {
    setState(() => _isLoading = true);
    await _aiService.init();
    final connected = await _aiService.checkConnection();
    if (mounted) {
      setState(() {
        _isConnected = connected;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);
    // Try to refresh from Firebase first if not connected
    if (!_aiService.isConnected && widget.configService != null) {
      await _aiService.refreshFromFirebase();
    }
    final connected = await _aiService.checkConnection();
    if (mounted) {
      setState(() {
        _isConnected = connected;
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _generate() async {
    final input = _inputController.text.trim();
    if (input.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _response = '';
      _messages.add(_ChatMessage(
        text: input,
        isUser: true,
        mode: _selectedMode,
      ));
    });
    
    _inputController.clear();
    _scrollToBottom();

    // Add AI response placeholder
    _messages.add(_ChatMessage(
      text: '',
      isUser: false,
      mode: _selectedMode,
    ));

    try {
      Stream<String> stream;
      
      switch (_selectedMode) {
        case 'tasks':
          stream = _aiService.generateTasks(projectDescription: input);
          break;
        case 'improve':
          stream = _aiService.improve(text: input);
          break;
        case 'brainstorm':
        default:
          stream = _aiService.brainstorm(idea: input);
      }

      await for (final chunk in stream) {
        if (!mounted) return;
        setState(() {
          _response += chunk;
          _messages.last = _ChatMessage(
            text: _response,
            isUser: false,
            mode: _selectedMode,
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.last = _ChatMessage(
          text: '❌ Lỗi: $e',
          isUser: false,
          mode: _selectedMode,
          isError: true,
        );
      });
    } finally {
      setState(() {
        _isGenerating = false;
        _response = '';
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Đã copy!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isConnected && !_isLoading) _buildConnectionError(),
          _buildModeSelector(),
          Expanded(child: _buildChatArea()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.accentPurple,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Animated AI Icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2 + _pulseController.value * 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.aiBrainstorm,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConnected ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLoading
                          ? AppLocalizations.of(context)!.loading
                          : _isConnected
                              ? AppLocalizations.of(context)!.aiConnected
                              : AppLocalizations.of(context)!.offline,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: _checkConnection,
            icon: Icon(
              Icons.refresh,
              color: Colors.white.withOpacity(0.8),
            ),
            tooltip: AppLocalizations.of(context)!.aiRetryConnection,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionError() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.aiConnectionError,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.aiConnectionErrorHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildModeChip(
            'brainstorm',
            '💡 ${AppLocalizations.of(context)!.brainstormMode}',
            AppLocalizations.of(context)!.brainstormHint,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            'tasks',
            '📋 ${AppLocalizations.of(context)!.tasksMode}',
            AppLocalizations.of(context)!.tasksHint,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            'improve',
            '✨ ${AppLocalizations.of(context)!.improveMode}',
            AppLocalizations.of(context)!.improveHint,
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, String tooltip) {
    final isSelected = _selectedMode == mode;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessage(message);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '${AppLocalizations.of(context)!.aiBrainstorm}!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.brainstormHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            // Quick suggestions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('App quản lý task'),
                _buildSuggestionChip('Tính năng collaboration'),
                _buildSuggestionChip('UI/UX cải tiến'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      avatar: const Icon(Icons.add, size: 16),
      onPressed: () {
        _inputController.text = text;
        _generate();
      },
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Mode badge for AI messages
            if (!isUser && message.mode != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 8),
                child: Text(
                  _getModeLabel(message.mode!, context),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            // Message bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : message.isError
                        ? AppColors.errorLight
                        : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show loading indicator for empty AI response
                  if (!isUser && message.text.isEmpty && _isGenerating)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.aiThinking,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else
                    _buildFormattedText(
                      message.text,
                      isUser: isUser,
                    ),
                ],
              ),
            ),
            // Action buttons for AI messages
            if (!isUser && message.text.isNotEmpty && !_isGenerating)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.copy,
                      AppLocalizations.of(context)!.copy,
                      () => _copyToClipboard(message.text),
                    ),
                    if (widget.onAddToBoard != null)
                      _buildActionButton(
                        Icons.add_circle_outline,
                        AppLocalizations.of(context)!.addToBoard,
                        () => widget.onAddToBoard!(message.text),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  String _getModeLabel(String mode, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'tasks':
        return '📋 ${l10n.tasksMode}';
      case 'improve':
        return '✨ ${l10n.improveMode}';
      case 'brainstorm':
      default:
        return '💡 ${l10n.brainstormMode}';
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: _isConnected && !_isGenerating,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: _getHintText(context),
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _generate(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _isGenerating ? AppColors.textTertiary : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _isConnected && !_isGenerating ? _generate : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build formatted text with proper styling for sections, bullets, and emojis
  Widget _buildFormattedText(String text, {required bool isUser}) {
    if (isUser) {
      return SelectableText(
        text,
        style: const TextStyle(
          color: Colors.white,
          height: 1.4,
        ),
      );
    }

    // Clean markdown from text first
    final cleanedText = _cleanMarkdown(text);
    
    // Parse and format AI response
    final lines = cleanedText.split('\n');
    final List<Widget> widgets = [];
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check if line is a section header (starts with emoji)
      final isHeader = _isHeaderLine(line);
      final isBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('☐');
      final isNumbered = RegExp(r'^\d+\.').hasMatch(line);

      if (isHeader) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: i > 0 ? 12 : 0,
              bottom: 4,
            ),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        );
      } else if (isBullet) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.startsWith('☐') ? '☐ ' : '• ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    line.replaceFirst(RegExp(r'^[•\-☐]\s*'), ''),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (isNumbered) {
        final match = RegExp(r'^(\d+\.)\s*(.*)').firstMatch(line);
        if (match != null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.group(1)} ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      match.group(2) ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // Regular text
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: SelectableText(
              line,
              style: TextStyle(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Clean markdown formatting from text
  String _cleanMarkdown(String text) {
    String cleaned = text;
    
    // Remove bold markers **text** -> text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (match) => match.group(1) ?? '',
    );
    
    // Remove italic markers *text* -> text (but not bullet points)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'),
      (match) => match.group(1) ?? '',
    );
    
    // Remove __text__ -> text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (match) => match.group(1) ?? '',
    );
    
    // Remove _text_ -> text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!_)_([^_\n]+)_(?!_)'),
      (match) => match.group(1) ?? '',
    );
    
    // Remove code markers `text` -> text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => match.group(1) ?? '',
    );
    
    // Remove headers # ## ### etc
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    
    // Clean excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return cleaned.trim();
  }

  /// Check if a line is a header (starts with emoji followed by text in caps)
  bool _isHeaderLine(String line) {
    // Check for common header patterns
    if (line.isEmpty) return false;
    
    // Check if line starts with **text** pattern (markdown header)
    if (line.startsWith('**') && line.contains('**', 2)) {
      return true;
    }
    
    // Lines that start with emoji and contain mostly uppercase or are section titles
    final emojiPattern = RegExp(r'^[\p{Emoji}]', unicode: true);
    if (emojiPattern.hasMatch(line)) {
      // Check if the rest is uppercase-ish (section header)
      final textAfterEmoji = line.replaceFirst(emojiPattern, '').trim();
      if (textAfterEmoji.toUpperCase() == textAfterEmoji && textAfterEmoji.length > 2) {
        return true;
      }
      // Also check for common header words
      final headerKeywords = [
        'Ý TƯỞNG', 'LIÊN QUAN', 'KẾT NỐI', 'HÀNH ĐỘNG', 'CÂU HỎI',
        'PHÂN TÍCH', 'ƯU TIÊN', 'GỢI Ý', 'RỦI RO', 'TỔNG KẾT',
        'DANH SÁCH', 'VĂN BẢN', 'THAY ĐỔI', 'CAO', 'TRUNG BÌNH', 'THẤP',
        'BƯỚC', 'LƯU Ý', 'QUAN TRỌNG', 'GHI CHÚ',
      ];
      for (final keyword in headerKeywords) {
        if (textAfterEmoji.toUpperCase().contains(keyword)) {
          return true;
        }
      }
    }
    
    // Check for "Bước X:" pattern
    if (RegExp(r'^Bước\s*\d+', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    
    return false;
  }

  String _getHintText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedMode) {
      case 'tasks':
        return l10n.describeProjectForTasks;
      case 'improve':
        return l10n.enterTextToImprove;
      case 'brainstorm':
      default:
        return l10n.enterIdeaToBrainstorm;
    }
  }
}

/// Internal message model
class _ChatMessage {
  final String text;
  final bool isUser;
  final String? mode;
  final bool isError;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.mode,
    this.isError = false,
  });
}
