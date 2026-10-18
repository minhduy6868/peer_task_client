import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task_model.dart';
import 'user_avatar.dart';

/// Label definitions with modern pastel background and text colors
class _LabelItem {
  final String name;
  final Color bg;
  final Color text;

  const _LabelItem({required this.name, required this.bg, required this.text});
}

const List<_LabelItem> _kAvailableLabels = [
  _LabelItem(
    name: 'Web',
    bg: Color(0xFFEFF6FF), // soft blue
    text: Color(0xFF1D4ED8),
  ),
  _LabelItem(
    name: 'Backend',
    bg: Color(0xFFF5F3FF), // soft purple
    text: Color(0xFF6D28D9),
  ),
  _LabelItem(
    name: 'Frontend',
    bg: Color(0xFFECFDF5), // soft emerald
    text: Color(0xFF047857),
  ),
  _LabelItem(
    name: 'UI/UX',
    bg: Color(0xFFFDF2F8), // soft pink
    text: Color(0xFFBE185D),
  ),
  _LabelItem(
    name: 'P2P-Sync',
    bg: Color(0xFFFFFBEB), // soft amber
    text: Color(0xFFB45309),
  ),
];

class TaskDialog extends StatefulWidget {
  final TaskModel? existingTask;
  final String initialStatus;
  final List<Map<String, dynamic>> boardMembers;
  final VoidCallback? onDelete;
  final List<Map<String, dynamic>> initialAttachments;

  /// Uploads image bytes and returns the hosted URL; attachments are hidden when null.
  final Future<String> Function(Uint8List bytes, String fileName)?
  onUploadImage;
  final Function({
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? deadline,
    DateTime? startDate,
    List<String>? assignees,
    List<String>? labels,
    double? estimatedHours,
    List<Map<String, dynamic>>? attachments,
  })
  onSave;

  const TaskDialog({
    super.key,
    this.existingTask,
    this.initialStatus = 'todo',
    required this.boardMembers,
    this.onDelete,
    this.initialAttachments = const [],
    this.onUploadImage,
    required this.onSave,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _checklistInputController =
      TextEditingController();
  final FocusNode _checklistFocusNode = FocusNode();
  final List<Map<String, dynamic>> _checklist = [];
  String? _bucket;

  // Form State
  String _status = 'todo'; // todo, doing, review, done
  String _priority = 'medium'; // urgent, high, medium, low
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _enableReminder = false;
  String _repeatInterval = 'none';

  // Labels & Assignees
  final List<String> _selectedLabels = [];
  final List<String> _selectedAssignees = [];

  // Options
  bool _notifyMembers = true;
  bool _addToSprint = false;

  // Image attachments (Cloudinary)
  bool _isDragHovered = false;
  bool _isUploading = false;
  final List<Map<String, dynamic>> _attachments = [];
  static const int _maxImageBytes = 10 * 1024 * 1024;

  // Validation & Saving
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _dateRangeError;

  @override
  void initState() {
    super.initState();

    final parsed = _parseDescription(widget.existingTask?.description);
    _titleController = TextEditingController(
      text: widget.existingTask?.title ?? '',
    );
    _descController = TextEditingController(text: parsed.notes);

    _checklist.addAll(parsed.checklist);
    _bucket = parsed.bucket;
    if (const ['daily', 'weekly', 'monthly'].contains(parsed.repeat)) {
      _repeatInterval = parsed.repeat!;
    }
    _attachments.addAll(
      widget.initialAttachments.map((a) => Map<String, dynamic>.from(a)),
    );
    _checklistFocusNode.addListener(() {
      if (!_checklistFocusNode.hasFocus) _addChecklistItem();
    });

    _startDate = parsed.startDate ?? DateTime.now();
    _dueDate =
        widget.existingTask?.deadline ??
        DateTime.now().add(const Duration(days: 3));

    _priority = widget.existingTask?.priority ?? 'medium';
    _status = widget.existingTask?.status ?? widget.initialStatus;

    if (widget.existingTask?.assignees != null &&
        widget.existingTask!.assignees.isNotEmpty) {
      _selectedAssignees.clear();
      _selectedAssignees.addAll(widget.existingTask!.assignees);
    }

    if (widget.existingTask?.labels != null &&
        widget.existingTask!.labels.isNotEmpty) {
      _selectedLabels.clear();
      _selectedLabels.addAll(widget.existingTask!.labels);
    }

    _titleController.addListener(_onFormUpdated);
    _descController.addListener(_onFormUpdated);
  }

  void _onFormUpdated() {
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFormUpdated);
    _descController.removeListener(_onFormUpdated);
    _titleController.dispose();
    _descController.dispose();
    _checklistInputController.dispose();
    _checklistFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static ({
    DateTime? startDate,
    String? repeat,
    String? bucket,
    List<Map<String, dynamic>> checklist,
    String notes,
  })
  _parseDescription(String? raw) {
    DateTime? startDate;
    String? repeat;
    String? bucket;
    final checklist = <Map<String, dynamic>>[];
    final notesLines = <String>[];

    final startDateRegex = RegExp(r'<!--start_date:([^>]+)-->');
    final repeatRegex = RegExp(r'<!--repeat:([^>]+)-->');
    final bucketRegex = RegExp(r'<!--bucket:([^>]+)-->');
    final checklistRegex = RegExp(r'^\s*-\s*\[([ xX])\]\s*(.*)$');

    for (final line in (raw ?? '').replaceAll('\r', '').split('\n')) {
      final trimmed = line.trim();
      final startMatch = startDateRegex.firstMatch(trimmed);
      if (startMatch != null) {
        startDate = DateTime.tryParse(startMatch.group(1)!.trim());
        continue;
      }
      final repeatMatch = repeatRegex.firstMatch(trimmed);
      if (repeatMatch != null) {
        repeat = repeatMatch.group(1)?.trim();
        continue;
      }
      final bucketMatch = bucketRegex.firstMatch(trimmed);
      if (bucketMatch != null) {
        bucket = bucketMatch.group(1)?.trim();
        continue;
      }
      final checkMatch = checklistRegex.firstMatch(line);
      if (checkMatch != null) {
        final title = (checkMatch.group(2) ?? '').trim();
        if (title.isNotEmpty) {
          checklist.add({
            'title': title,
            'done': checkMatch.group(1)!.toLowerCase() == 'x',
          });
        }
        continue;
      }
      if (trimmed.startsWith('<!--') && trimmed.endsWith('-->')) continue;
      notesLines.add(line);
    }

    return (
      startDate: startDate,
      repeat: repeat,
      bucket: bucket,
      checklist: checklist,
      notes: notesLines.join('\n').trim(),
    );
  }

  static String _formatDescription({
    DateTime? startDate,
    String? repeat,
    String? bucket,
    required List<Map<String, dynamic>> checklist,
    required String notes,
  }) {
    final buffer = StringBuffer();
    if (startDate != null) {
      buffer.writeln('<!--start_date:${startDate.toIso8601String()}-->');
    }
    if (repeat != null && repeat != 'none') {
      buffer.writeln('<!--repeat:$repeat-->');
    }
    if (bucket != null && bucket.isNotEmpty) {
      buffer.writeln('<!--bucket:$bucket-->');
    }
    for (final item in checklist) {
      final title = (item['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      buffer.writeln('- [${item['done'] == true ? 'x' : ' '}] $title');
    }
    final trimmedNotes = notes.trim();
    if (trimmedNotes.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(trimmedNotes);
    }
    return buffer.toString().trim();
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add({'title': text, 'done': false});
      _checklistInputController.clear();
    });
  }

  bool _validateDates([AppLocalizations? l10n]) {
    if (_startDate != null && _dueDate != null) {
      if (_dueDate!.isBefore(_startDate!)) {
        setState(() {
          _dateRangeError =
              l10n?.dueDateMustBeAfterStartDate ??
              AppLocalizations.of(context)!.deadlineBeforeStart;
        });
        return false;
      }
    }
    setState(() {
      _dateRangeError = null;
    });
    return true;
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final isValidForm = _formKey.currentState?.validate() ?? false;
    final isValidDates = _validateDates(l10n);

    if (!isValidForm || !isValidDates) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      _addChecklistItem();
      final description = _formatDescription(
        startDate: _startDate,
        repeat: _repeatInterval,
        bucket: _bucket,
        checklist: _checklist,
        notes: _descController.text,
      );

      widget.onSave(
        title: _titleController.text.trim(),
        description: description,
        priority: _priority,
        status: _status,
        deadline: _dueDate,
        startDate: _startDate,
        assignees: _selectedAssignees,
        labels: _selectedLabels,
        attachments: widget.onUploadImage != null ? _attachments : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImages() async {
    final upload = widget.onUploadImage;
    if (upload == null || _isUploading) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);

    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (picked.isEmpty || !mounted) return;

    setState(() => _isUploading = true);
    try {
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        if (bytes.length > _maxImageBytes) {
          messenger?.showSnackBar(
            SnackBar(content: Text(l10n.imageTooLarge(file.name))),
          );
          continue;
        }
        final url = await upload(bytes, file.name);
        if (!mounted) return;
        setState(() {
          _attachments.add({
            'url': url,
            'name': file.name,
            'bytes': bytes.length,
          });
        });
      }
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _previewImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existingTask != null;
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogWidth = isDesktop ? 920.0 : (screenSize.width - 24.0);

    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Center(
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(maxHeight: screenSize.height * 0.94),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2D2D3F)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Top Header
                  _buildModalHeader(isEdit, isDark, l10n),

                  // Modal Main Content (2-Column Scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Form(
                        key: _formKey,
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Form Column (60%)
                                  Expanded(
                                    flex: 6,
                                    child: _buildLeftFormColumn(isDark, l10n),
                                  ),
                                  const SizedBox(width: 24),
                                  // Right Preview & Options Column (40%)
                                  Expanded(
                                    flex: 4,
                                    child: _buildRightSideColumn(isDark, l10n),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLeftFormColumn(isDark, l10n),
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  _buildRightSideColumn(isDark, l10n),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Sticky Bottom Footer Bar
                  _buildStickyFooter(isEdit, isDark, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Header ====================
  Widget _buildModalHeader(bool isEdit, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF5B4CF0).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.assignment_outlined,
                color: Color(0xFF5B4CF0),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? l10n.editTaskTitle : l10n.createNewTaskTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.taskDialogSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.closeTooltip,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ==================== Left Column: Form Fields ====================
  Widget _buildLeftFormColumn(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tên nhiệm vụ *
        _buildFieldLabel(l10n.taskNameLabel, isRequired: true, isDark: isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: l10n.taskNamePlaceholder,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF262638) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3B3B52)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3B3B52)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF5B4CF0),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFFEF4444),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.taskNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // 2. Mô tả: ghi chú + checklist
        _buildFieldLabel(l10n.descriptionLabel, isDark: isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descController,
          minLines: 2,
          maxLines: 5,
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: l10n.taskNotesPlaceholder,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF262638) : Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3B3B52)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3B3B52)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF5B4CF0),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildChecklistSection(isDark, l10n),
        const SizedBox(height: 18),

        // 3. Row: Danh sách (Cột) & Độ ưu tiên
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.listLabel, isDark: isDark),
                  const SizedBox(height: 6),
                  _buildStatusDropdown(isDark, l10n),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.priorityLabel, isDark: isDark),
                  const SizedBox(height: 6),
                  _buildPriorityDropdown(isDark, l10n),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 4. Row: Người phụ trách & Nhãn (Label)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.assigneeLabel, isDark: isDark),
                  const SizedBox(height: 6),
                  _buildAssigneeSelector(isDark, l10n),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.labelsLabel, isDark: isDark),
                  const SizedBox(height: 6),
                  _buildLabelChips(isDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 5. Row: Ngày bắt đầu & Hạn hoàn thành
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.startDateLabel, isDark: isDark),
                  const SizedBox(height: 6),
                  _buildDatePickerButton(
                    date: _startDate,
                    hint: l10n.pickDate,
                    onSelect: (dt) {
                      setState(() {
                        _startDate = dt;
                        _validateDates(l10n);
                      });
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.dueDateLabel, isDark: isDark),
                  const SizedBox(height: 6),
                  _buildDatePickerButton(
                    date: _dueDate,
                    hint: l10n.pickDate,
                    hasError: _dateRangeError != null,
                    onSelect: (dt) {
                      setState(() {
                        _dueDate = dt;
                        _validateDates(l10n);
                      });
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_dateRangeError != null) ...[
          const SizedBox(height: 4),
          Text(
            _dateRangeError!,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444)),
          ),
        ],
        const SizedBox(height: 18),

        // 6. Row: Đặt lời nhắc & Lặp lại
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262638) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B3B52)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.setReminder,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: _enableReminder,
                        thumbColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? const Color(0xFF5B4CF0)
                              : null,
                        ),
                        activeTrackColor: const Color(
                          0xFF5B4CF0,
                        ).withValues(alpha: 0.5),
                        onChanged: (val) =>
                            setState(() => _enableReminder = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262638) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B3B52)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _repeatInterval,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'none',
                              child: Text(l10n.doesNotRepeat),
                            ),
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text(l10n.repeatDaily),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text(l10n.repeatWeekly),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text(l10n.repeatMonthly),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _repeatInterval = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 7. File đính kèm (Dropzone)
        if (widget.onUploadImage != null) ...[
          _buildFieldLabel(l10n.attachmentsLabel, isDark: isDark),
          const SizedBox(height: 6),
          _buildImageAttachments(isDark, l10n),
        ],
      ],
    );
  }

  // ==================== Right Column: Quick Create + Preview + Other Options ====================
  Widget _buildRightSideColumn(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tạo nhiệm vụ nhanh chóng Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262638) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4CF0).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_task_rounded,
                    color: Color(0xFF5B4CF0),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quickCreationTitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.quickCreationBody,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Xem trước (Live Realtime Preview)
        Text(
          l10n.previewLabel,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 8),
        _buildLivePreviewCard(isDark, l10n),
        const SizedBox(height: 20),

        // 3. Tùy chọn khác
        Text(
          l10n.moreOptions,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262638) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              // Gửi thông báo cho các thành viên
              Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.notifyMembers,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _notifyMembers,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF5B4CF0)
                            : null,
                      ),
                      activeTrackColor: const Color(
                        0xFF5B4CF0,
                      ).withValues(alpha: 0.5),
                      onChanged: (val) => setState(() => _notifyMembers = val),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              // Thêm vào kế hoạch sprint
              Row(
                children: [
                  const Icon(
                    Icons.view_kanban_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.addToSprintPlan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: AppLocalizations.of(context)!.sprintHint,
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _addToSprint,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF5B4CF0)
                            : null,
                      ),
                      activeTrackColor: const Color(
                        0xFF5B4CF0,
                      ).withValues(alpha: 0.5),
                      onChanged: (val) => setState(() => _addToSprint = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Live Preview Card ====================
  Widget _buildLivePreviewCard(bool isDark, AppLocalizations l10n) {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262638) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Dot indicator
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF5B4CF0),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.isEmpty ? l10n.taskNameLabel : title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: title.isEmpty
                        ? (isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8))
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Priority badge
          _buildPriorityPill(_priority, l10n),
          const SizedBox(height: 10),

          // Label chips
          if (_selectedLabels.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _selectedLabels.map((lbl) {
                final def = _kAvailableLabels.firstWhere(
                  (l) => l.name == lbl,
                  orElse: () => _LabelItem(
                    name: lbl,
                    bg: const Color(0xFFF1F5F9),
                    text: const Color(0xFF475569),
                  ),
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: def.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    def.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: def.text,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Assignee
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _selectedAssignees.isEmpty
                      ? l10n.unassigned
                      : _getAssigneeName(_selectedAssignees.first, l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date range
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${_formatDate(_startDate)}  →  ${_formatDate(_dueDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description preview
          Text(
            desc.isEmpty ? l10n.previewDescriptionDefault : desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontStyle: desc.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: desc.isEmpty
                  ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                  : (isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Sticky Footer ====================
  Widget _buildStickyFooter(bool isEdit, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel button
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              foregroundColor: isDark ? Colors.white : const Color(0xFF475569),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF3B3B52)
                    : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Primary Save/Create Button
          FilledButton(
            onPressed: _isLoading ? null : _handleSave,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B4CF0),
              disabledBackgroundColor: const Color(
                0xFF5B4CF0,
              ).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEdit ? l10n.saveChanges : l10n.createTask,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== Checklist ====================
  Widget _buildChecklistSection(bool isDark, AppLocalizations l10n) {
    const accent = Color(0xFF5B4CF0);
    final muted = isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
    final done = _checklist.where((c) => c['done'] == true).length;

    Widget emptyCircle() => Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: muted, width: 1.6),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262638) : const Color(0xFFFAFAFE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, size: 17, color: accent),
              const SizedBox(width: 6),
              Text(
                l10n.checklistLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (_checklist.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '$done/${_checklist.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < _checklist.length; i++)
            Row(
              children: [
                InkWell(
                  onTap: () => setState(
                    () => _checklist[i]['done'] = _checklist[i]['done'] != true,
                  ),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _checklist[i]['done'] == true
                        ? const Icon(
                            Icons.check_circle_rounded,
                            size: 19,
                            color: accent,
                          )
                        : emptyCircle(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _checklist[i]['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      decoration: _checklist[i]['done'] == true
                          ? TextDecoration.lineThrough
                          : null,
                      color: _checklist[i]['done'] == true
                          ? muted
                          : (isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF374151)),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.removeChecklistStep,
                  icon: Icon(Icons.close_rounded, size: 16, color: muted),
                  onPressed: () => setState(() => _checklist.removeAt(i)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Padding(padding: const EdgeInsets.all(2), child: emptyCircle()),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _checklistInputController,
                  focusNode: _checklistFocusNode,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.checklistHint,
                    hintStyle: TextStyle(color: muted, fontSize: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) {
                    _addChecklistItem();
                    _checklistFocusNode.requestFocus();
                  },
                ),
              ),
              IconButton(
                tooltip: l10n.addChecklistStep,
                icon: const Icon(Icons.add_rounded, color: accent, size: 20),
                onPressed: _addChecklistItem,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== Image attachments ====================
  Widget _buildImageAttachments(bool isDark, AppLocalizations l10n) {
    const accent = Color(0xFF5B4CF0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isDragHovered = true),
          onExit: (_) => setState(() => _isDragHovered = false),
          child: InkWell(
            onTap: _isUploading ? null : _pickImages,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: _isDragHovered
                    ? accent.withValues(alpha: 0.08)
                    : (isDark
                          ? const Color(0xFF262638)
                          : const Color(0xFFFAFAFE)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDragHovered ? accent : const Color(0xFFC7D2FE),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  if (_isUploading)
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: accent,
                        size: 22,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _isUploading ? l10n.uploadingImages : l10n.uploadImages,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.imageSupportHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in _attachments)
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InkWell(
                          onTap: () => _previewImage(a['url'] as String),
                          borderRadius: BorderRadius.circular(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              a['url'] as String,
                              cacheWidth: 168,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isDark
                                    ? const Color(0xFF262638)
                                    : const Color(0xFFF1F5F9),
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Tooltip(
                          message: l10n.removeAttachment,
                          child: InkWell(
                            onTap: () => setState(() => _attachments.remove(a)),
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0x99000000),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ==================== Helper Components ====================
  Widget _buildFieldLabel(
    String label, {
    bool isRequired = false,
    required bool isDark,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusDropdown(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262638) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          items: [
            _buildStatusMenuItem(
              'todo',
              l10n.statusTodo,
              const Color(0xFF5B4CF0),
            ),
            _buildStatusMenuItem(
              'doing',
              l10n.statusDoing,
              const Color(0xFFF59E0B),
            ),
            _buildStatusMenuItem(
              'review',
              l10n.statusReview,
              const Color(0xFF3B82F6),
            ),
            _buildStatusMenuItem(
              'done',
              l10n.statusDone,
              const Color(0xFF10B981),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _status = val);
          },
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildStatusMenuItem(
    String val,
    String title,
    Color color,
  ) {
    return DropdownMenuItem(
      value: val,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDropdown(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262638) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _priority,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          items: [
            _buildPriorityMenuItem(
              'urgent',
              l10n.priorityUrgent,
              const Color(0xFFEF4444),
            ),
            _buildPriorityMenuItem(
              'high',
              l10n.priorityHigh,
              const Color(0xFFF97316),
            ),
            _buildPriorityMenuItem(
              'medium',
              l10n.priorityMedium,
              const Color(0xFFF59E0B),
            ),
            _buildPriorityMenuItem(
              'low',
              l10n.priorityLow,
              const Color(0xFF10B981),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _priority = val);
          },
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildPriorityMenuItem(
    String val,
    String title,
    Color color,
  ) {
    return DropdownMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(Icons.flag_rounded, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityPill(String priority, AppLocalizations l10n) {
    Color bg;
    Color fg;
    String label;

    switch (priority) {
      case 'urgent':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = l10n.priorityBadgeUrgent;
        break;
      case 'high':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFEA580C);
        label = l10n.priorityBadgeHigh;
        break;
      case 'low':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = l10n.priorityBadgeLow;
        break;
      case 'medium':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = l10n.priorityBadgeMedium;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeSelector(bool isDark, AppLocalizations l10n) {
    final name = _selectedAssignees.isEmpty
        ? l10n.selectMemberPlaceholder
        : _getAssigneeName(_selectedAssignees.first, l10n);

    return InkWell(
      onTap: () => _showAssigneePicker(l10n),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262638) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssigneePicker(AppLocalizations l10n) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => _AssigneePickerDialog(
        members: widget.boardMembers,
        selectedId: _selectedAssignees.isEmpty
            ? null
            : _selectedAssignees.first,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedAssignees.clear();
      if (picked.isNotEmpty) _selectedAssignees.add(picked);
    });
  }

  String _getAssigneeName(String id, [AppLocalizations? l10n]) {
    for (final m in widget.boardMembers) {
      if ((m['id'] ?? m['user_id'])?.toString() == id) {
        return (m['name'] ?? m['email'] ?? id).toString();
      }
    }
    return l10n?.unknownUser ?? 'Unknown';
  }

  Widget _buildLabelChips(bool isDark) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262638) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _kAvailableLabels.map((lbl) {
            final isSelected = _selectedLabels.contains(lbl.name);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(lbl.name),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? lbl.text
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
                selected: isSelected,
                selectedColor: lbl.bg,
                backgroundColor: isDark
                    ? const Color(0xFF2D2D3F)
                    : const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: isSelected
                        ? lbl.text.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedLabels.add(lbl.name);
                    } else {
                      _selectedLabels.remove(lbl.name);
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton({
    required DateTime? date,
    required String hint,
    required ValueChanged<DateTime> onSelect,
    bool hasError = false,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: now.subtract(const Duration(days: 365)),
          lastDate: now.add(const Duration(days: 365 * 3)),
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262638) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasError
                ? const Color(0xFFEF4444)
                : (isDark ? const Color(0xFF3B3B52) : const Color(0xFFE2E8F0)),
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: hasError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? _formatDate(date) : hint,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: date != null
                      ? (isDark ? Colors.white : const Color(0xFF1E293B))
                      : (isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--/--/----';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

/// Pops the chosen member id, or an empty string for "Unassigned".
class _AssigneePickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final String? selectedId;

  const _AssigneePickerDialog({required this.members, this.selectedId});

  @override
  State<_AssigneePickerDialog> createState() => _AssigneePickerDialogState();
}

class _AssigneePickerDialogState extends State<_AssigneePickerDialog> {
  String _query = '';

  static String _idOf(Map<String, dynamic> m) =>
      (m['id'] ?? m['user_id'])?.toString() ?? '';
  static String _nameOf(Map<String, dynamic> m) =>
      (m['name'] ?? m['email'] ?? _idOf(m)).toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _query.toLowerCase();
    final members = widget.members.where((m) {
      if (q.isEmpty) return true;
      return _nameOf(m).toLowerCase().contains(q) ||
          (m['email']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();

    Widget row({
      required String id,
      required String title,
      String? subtitle,
      required Widget avatar,
    }) {
      final selected = (widget.selectedId ?? '') == id;
      return ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: selected,
        selectedTileColor: const Color(0xFF5B4CF0).withValues(alpha: 0.08),
        leading: avatar,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
        trailing: selected
            ? const Icon(
                Icons.check_rounded,
                color: Color(0xFF5B4CF0),
                size: 20,
              )
            : null,
        onTap: () => Navigator.of(context).pop(id),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.assigneeLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.searchMembersPlaceholder,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF262638)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    row(
                      id: '',
                      title: l10n.unassigned,
                      avatar: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(
                          Icons.person_off_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    if (widget.members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.noMembersAvailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    else if (members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.noMembersFound,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    else
                      for (final m in members)
                        row(
                          id: _idOf(m),
                          title: _nameOf(m),
                          subtitle: m['name'] != null && m['email'] != null
                              ? m['email'].toString()
                              : null,
                          avatar: UserAvatar(
                            name: _nameOf(m),
                            imageUrl: m['avatar']?.toString(),
                            size: 32,
                            maxInitials: 1,
                            fontSize: 13,
                            backgroundColor: const Color(0xFF5B4CF0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
