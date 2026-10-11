import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task_model.dart';

/// Preset Pastel Label definitions matching modern SaaS UI Kit
class _PastelLabelDef {
  final String name;
  final Color bg;
  final Color text;

  const _PastelLabelDef({
    required this.name,
    required this.bg,
    required this.text,
  });
}

const List<_PastelLabelDef> _kPresetLabels = [
  _PastelLabelDef(
    name: 'Awaiting Approval',
    bg: Color(0xFFFDE8E8), // Pastel pink
    text: Color(0xFF9F1239),
  ),
  _PastelLabelDef(
    name: 'Bug',
    bg: Color(0xFFFADBD8), // Pastel soft red
    text: Color(0xFF991B1B),
  ),
  _PastelLabelDef(
    name: 'Yellow',
    bg: Color(0xFFFEF3C7), // Pale yellow
    text: Color(0xFF854D0E),
  ),
  _PastelLabelDef(
    name: 'Green',
    bg: Color(0xFFDEF7EC), // Light green
    text: Color(0xFF03543F),
  ),
  _PastelLabelDef(
    name: 'Awaiting Review',
    bg: Color(0xFFE1EFFE), // Light blue
    text: Color(0xFF1E429F),
  ),
  _PastelLabelDef(
    name: 'Purple',
    bg: Color(0xFFEDEBFE), // Pastel purple
    text: Color(0xFF5521B5),
  ),
];

/// Half-filled circle icon for "In progress" status
class _HalfFilledCircleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _HalfFilledCircleIcon({
    this.size = 16,
    this.color = const Color(0xFF0078D4),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HalfCirclePainter(color),
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  final Color color;
  _HalfCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    // Fill the bottom half
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      3.141592653589793,
      true,
      fillPaint,
    );

    // Draw outline circle
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HalfCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Comprehensive, modern SaaS Task Creation & Details Modal
/// Designed with 8px border radius, clean white aesthetics, soft drop shadows,
/// single-column centered dialog without extraneous showcase columns,
/// and interactive checklist with sample items & state persistence.
class TaskDialog extends StatefulWidget {
  final TaskModel? existingTask;
  final String initialStatus;
  final List<Map<String, dynamic>> boardMembers;
  final VoidCallback? onDelete;
  final Function({
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? deadline,
    List<String>? assignees,
    List<String>? labels,
    double? estimatedHours,
  }) onSave;

  const TaskDialog({
    super.key,
    this.existingTask,
    this.initialStatus = 'todo',
    required this.boardMembers,
    this.onDelete,
    required this.onSave,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _checklistInputController;
  late final FocusNode _checklistFocusNode;

  // Form State
  String _status = 'todo'; // 'todo' (Not started), 'doing' (In progress), 'done' (Completed)
  String _priority = 'medium'; // 'urgent', 'high' (Important), 'medium', 'low'
  DateTime? _startDate;
  DateTime? _dueDate;
  String _repeat = 'Does not repeat';
  String _bucket = 'To do';

  // Labels & Assignees
  final List<String> _selectedLabels = [];
  final List<String> _selectedAssignees = [];

  // Checklist items: [{'title': '...', 'done': false}]
  final List<Map<String, dynamic>> _checklist = [];

  final _formKey = GlobalKey<FormState>();

  static ({
    DateTime? startDate,
    String? repeat,
    String? bucket,
    List<Map<String, dynamic>> checklist,
    String notes,
  }) _parseDescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return (
        startDate: null,
        repeat: null,
        bucket: null,
        checklist: <Map<String, dynamic>>[],
        notes: '',
      );
    }

    DateTime? startDate;
    String? repeat;
    String? bucket;
    final checklist = <Map<String, dynamic>>[];
    final notesLines = <String>[];

    final lines = raw.replaceAll('\r', '').split('\n');
    final startDateRegex = RegExp(r'<!--start_date:([^>]+)-->');
    final repeatRegex = RegExp(r'<!--repeat:([^>]+)-->');
    final bucketRegex = RegExp(r'<!--bucket:([^>]+)-->');
    final checklistRegex = RegExp(r'^\s*-\s*\[([ xX])\]\s*(.*)$');

    for (final line in lines) {
      final trimmed = line.trim();
      final startMatch = startDateRegex.firstMatch(trimmed);
      if (startMatch != null) {
        final dateStr = startMatch.group(1);
        if (dateStr != null) {
          startDate = DateTime.tryParse(dateStr.trim());
        }
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
        final isDone = checkMatch.group(1)!.toLowerCase() == 'x';
        final itemTitle = (checkMatch.group(2) ?? '').trim();
        if (itemTitle.isNotEmpty) {
          checklist.add({'title': itemTitle, 'done': isDone});
        }
        continue;
      }

      if (trimmed.startsWith('<!--') && trimmed.endsWith('-->')) {
        continue;
      }

      notesLines.add(line);
    }

    final notes = notesLines.join('\n').trim();
    return (
      startDate: startDate,
      repeat: repeat,
      bucket: bucket,
      checklist: checklist,
      notes: notes,
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

    if (repeat != null && repeat.isNotEmpty && repeat != 'Does not repeat') {
      buffer.writeln('<!--repeat:$repeat-->');
    }

    if (bucket != null && bucket.isNotEmpty) {
      buffer.writeln('<!--bucket:$bucket-->');
    }

    for (final item in checklist) {
      final done = item['done'] == true;
      final title = (item['title'] ?? '').toString().trim();
      if (title.isNotEmpty) {
        buffer.writeln('- [${done ? 'x' : ' '}] $title');
      }
    }

    final trimmedNotes = notes.trim();
    if (trimmedNotes.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(trimmedNotes);
    }

    return buffer.toString().trim();
  }

  @override
  void initState() {
    super.initState();
    // Task title: empty by default for new tasks, NO default placeholder text
    _titleController = TextEditingController(
      text: widget.existingTask?.title ?? '',
    );

    final parsed = _parseDescription(widget.existingTask?.description);
    _notesController = TextEditingController(text: parsed.notes);
    _startDate = parsed.startDate;
    if (parsed.repeat != null && parsed.repeat!.isNotEmpty) {
      _repeat = parsed.repeat!;
    }
    _checklist.addAll(parsed.checklist);

    _checklistInputController = TextEditingController();
    _checklistFocusNode = FocusNode();
    _checklistFocusNode.addListener(() {
      if (!_checklistFocusNode.hasFocus) {
        _addChecklistItem();
      }
    });

    _priority = widget.existingTask?.priority ?? 'medium';
    _status = widget.existingTask?.status ?? widget.initialStatus;

    if (widget.existingTask?.deadline != null) {
      _dueDate = widget.existingTask!.deadline;
    }

    if (widget.existingTask?.assignees != null) {
      _selectedAssignees.addAll(widget.existingTask!.assignees);
    }

    if (widget.existingTask?.labels != null) {
      _selectedLabels.addAll(widget.existingTask!.labels);
    }

    // Map bucket based on parsed bucket or status
    _bucket = parsed.bucket ?? _mapStatusToBucket(_status);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _checklistInputController.dispose();
    _checklistFocusNode.dispose();
    super.dispose();
  }

  String _mapStatusToBucket(String status) {
    switch (status) {
      case 'done':
        return 'Done';
      case 'doing':
      case 'in_progress':
        return 'Doing';
      default:
        return 'To do';
    }
  }

  bool get _isCompleted => _status == 'done';

  void _toggleCompleted() {
    setState(() {
      if (_isCompleted) {
        _status = 'todo';
        _bucket = 'To do';
      } else {
        _status = 'done';
        _bucket = 'Done';
      }
    });
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklist.add({'title': text, 'done': false});
        _checklistInputController.clear();
      });
    }
  }

  void _handleSave() {
    // If user typed something in checklist but didn't press enter, add it automatically
    _addChecklistItem();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullDescription = _formatDescription(
      startDate: _startDate,
      repeat: _repeat,
      bucket: _bucket,
      checklist: _checklist,
      notes: _notesController.text.trim(),
    );

    widget.onSave(
      title: _titleController.text.trim(),
      description: fullDescription.isNotEmpty ? fullDescription : null,
      priority: _priority,
      status: _status,
      deadline: _dueDate,
      assignees: _selectedAssignees,
      labels: _selectedLabels,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTask != null;
    final screenSize = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    // Clean, centered modal with standard width
    final dialogWidth = screenSize.width > 640 ? 600.0 : screenSize.width - 24.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.92,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildStandardModal(isEdit, l10n),
          ),
        ),
      ),
    );
  }

  /// Standard Dialog view: clean, centered, focused SaaS modal
  Widget _buildStandardModal(bool isEdit, AppLocalizations? l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderBar(isEdit),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 14),
                  _buildTopTagsAndAssigneesRow(),
                  const SizedBox(height: 18),
                  _buildTaskDetailsHeader(),
                  const SizedBox(height: 14),
                  _buildSixFieldsGrid(),
                  const SizedBox(height: 22),
                  _buildChecklistSection(),
                  const SizedBox(height: 22),
                  _buildNotesSection(),
                ],
              ),
            ),
          ),
        ),
        _buildBottomActionBar(isEdit, l10n),
      ],
    );
  }

  Widget _buildTaskDetailsHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF5B4AD4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 15,
              color: Colors.white,
            ),
            SizedBox(width: 7),
            Text(
              'Task details',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Header ====================
  Widget _buildHeaderBar(bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 16,
              color: Color(0xFF5B4AD4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isEdit ? 'Task Details' : 'Create Task',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ==================== Title Section ====================
  Widget _buildTitleSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Unchecked / Checked circle (toggle completion)
            InkWell(
              onTap: _toggleCompleted,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _isCompleted
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF5B4AD4),
                        size: 24,
                      )
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF9CA3AF),
                            width: 1.8,
                          ),
                        ),
                      ),
              ),
            ),
            // Title input: framed input matching Add label and Assign to
            Expanded(
              child: TextFormField(
                controller: _titleController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (val) {
                  if (_formKey.currentState != null && val.trim().isNotEmpty) {
                    _formKey.currentState!.validate();
                  }
                },
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                  decoration: _isCompleted ? TextDecoration.lineThrough : null,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter task title...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF5B4AD4), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                  errorStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n?.taskTitleRequired ?? 'Task title is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Subline metadata
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Row(
            children: [
              Text(
                widget.existingTask != null
                    ? 'Created by ${widget.existingTask?.creatorName ?? 'you'} · Last changed just now by you'
                    : 'Created just now by you · Last changed just now by you',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Add Label & Assign To Fields ====================
  Widget _buildTopTagsAndAssigneesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Add label" field
        _buildAnchorBox(
          onTap: _showLabelsDialog,
          icon: const Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFF6B7280)),
          content: _selectedLabels.isEmpty
              ? const Text(
                  'Add label',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final lbl in _selectedLabels) _buildPastelTagBadge(lbl),
                    const Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        // "Assign to" field
        _buildAnchorBox(
          onTap: _showAssigneeDialog,
          icon: const Icon(Icons.person_add_outlined, size: 18, color: Color(0xFF6B7280)),
          content: _selectedAssignees.isEmpty
              ? const Text(
                  'Assign to',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final uid in _selectedAssignees) _buildAssigneeBadge(uid),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAnchorBox({
    required VoidCallback onTap,
    required Widget icon,
    required Widget content,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFD1D5DB),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildPastelTagBadge(String name) {
    final def = _kPresetLabels.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => _PastelLabelDef(
        name: name,
        bg: const Color(0xFFF3F4F6),
        text: const Color(0xFF374151),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: def.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            def.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: def.text,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _selectedLabels.remove(name)),
            child: Icon(Icons.close, size: 12, color: def.text),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeBadge(String userId) {
    final member = widget.boardMembers.firstWhere(
      (m) => (m['id'] ?? m['user_id'])?.toString() == userId,
      orElse: () => {'name': userId},
    );
    final name = (member['name'] ?? member['email'] ?? userId).toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: const Color(0xFF5B4AD4),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _selectedAssignees.remove(userId)),
            child: const Icon(Icons.close, size: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }



  // ==================== 6 Fields Grid ====================
  Widget _buildSixFieldsGrid() {
    return Column(
      children: [
        // Row 1: Status & Priority
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFieldLabel('Status'),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      setState(() {
                        _status = val;
                        _bucket = _mapStatusToBucket(val);
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    elevation: 6,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'todo',
                        child: Row(
                          children: [
                            if (_status == 'todo')
                              const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 6),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF6B7280), width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Not started', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'doing',
                        child: Row(
                          children: [
                            if (_status == 'doing' || _status == 'in_progress')
                              const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 6),
                            const _HalfFilledCircleIcon(size: 15, color: Color(0xFF0078D4)),
                            const SizedBox(width: 8),
                            const Text('In progress', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'done',
                        child: Row(
                          children: [
                            if (_status == 'done')
                              const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF5B4AD4)),
                            const SizedBox(width: 8),
                            const Text('Completed', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    child: _buildFieldContainer(
                      content: _renderStatusDisplay(),
                      suffix: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFieldLabel('Priority'),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      setState(() => _priority = val);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    elevation: 6,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'urgent',
                        child: Row(
                          children: [
                            if (_priority == 'urgent')
                              const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 6),
                            const Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            const Text('Urgent', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'high',
                        child: Row(
                          children: [
                            if (_priority == 'high')
                              const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 6),
                            const Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            const Text('Important', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'medium',
                        child: Row(
                          children: [
                            if (_priority == 'medium')
                              const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Medium', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'low',
                        child: Row(
                          children: [
                            if (_priority == 'low')
                              const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            const Text('Low', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    child: _buildFieldContainer(
                      content: _renderPriorityDisplay(),
                      suffix: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Start date & Due date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFieldLabel('Start date'),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _pickDualPaneDate(isForDueDate: false),
                    borderRadius: BorderRadius.circular(8),
                    child: _buildFieldContainer(
                      content: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Set start date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _startDate != null
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      suffix: _startDate != null
                          ? InkWell(
                              onTap: () => setState(() => _startDate = null),
                              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
                            )
                          : const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFieldLabel('Due date'),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _pickDualPaneDate(isForDueDate: true),
                    borderRadius: BorderRadius.circular(8),
                    child: _buildFieldContainer(
                      content: Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Set due date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _dueDate != null
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      suffix: _dueDate != null
                          ? InkWell(
                              onTap: () => setState(() => _dueDate = null),
                              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
                            )
                          : const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Repeat & Bucket
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFieldLabelWithInfo('Repeat'),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    onSelected: (val) => setState(() => _repeat = val),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    elevation: 6,
                    itemBuilder: (context) => [
                      for (final opt in [
                        'Does not repeat',
                        'Daily',
                        'Weekdays',
                        'Weekly',
                        'Monthly',
                        'Yearly',
                        'Customised',
                      ])
                        PopupMenuItem(
                          value: opt,
                          child: Row(
                            children: [
                              if (_repeat == opt)
                                const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                              else
                                const SizedBox(width: 14),
                              const SizedBox(width: 6),
                              Text(opt, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                    child: _buildFieldContainer(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.repeat_rounded,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _repeat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                      suffix: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFieldLabelWithInfo('Bucket'),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      setState(() {
                        _bucket = val;
                        if (val == 'Done') {
                          _status = 'done';
                        } else if (val == 'Doing') {
                          _status = 'doing';
                        } else {
                          _status = 'todo';
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    elevation: 6,
                    itemBuilder: (context) => [
                      for (final opt in ['To do', 'Doing', 'Done'])
                        PopupMenuItem(
                          value: opt,
                          child: Row(
                            children: [
                              if (_bucket == opt)
                                const Icon(Icons.check, size: 14, color: Color(0xFF5B4AD4))
                              else
                                const SizedBox(width: 14),
                              const SizedBox(width: 6),
                              Text(opt, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                    child: _buildFieldContainer(
                      content: Text(
                        _bucket,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                      suffix: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildFieldLabelWithInfo(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF9CA3AF)),
      ],
    );
  }

  Widget _buildFieldContainer({
    required Widget content,
    required Widget suffix,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: content),
          suffix,
        ],
      ),
    );
  }

  Widget _renderStatusDisplay() {
    switch (_status) {
      case 'done':
        return const Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF5B4AD4)),
            SizedBox(width: 8),
            Text('Completed', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
          ],
        );
      case 'doing':
      case 'in_progress':
        return const Row(
          children: [
            _HalfFilledCircleIcon(size: 15, color: Color(0xFF0078D4)),
            SizedBox(width: 8),
            Text('In progress', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
          ],
        );
      default:
        return Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6B7280), width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Not started', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
          ],
        );
    }
  }

  Widget _renderPriorityDisplay() {
    switch (_priority) {
      case 'urgent':
        return const Row(
          children: [
            Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Urgent', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
          ],
        );
      case 'high':
        return const Row(
          children: [
            Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Important', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
          ],
        );
      case 'low':
        return const Row(
          children: [
            Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Low', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
          ],
        );
      default: // medium
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Medium', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
          ],
        );
    }
  }

  // ==================== Checklist Section ====================
  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Checklist',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        // Existing checklist items with interactive tick & strikethrough
        for (int i = 0; i < _checklist.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _checklist[i]['done'] = !(_checklist[i]['done'] as bool);
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: (_checklist[i]['done'] as bool)
                      ? const Icon(
                          Icons.check_circle_rounded,
                          size: 19,
                          color: Color(0xFF5B4AD4),
                        )
                      : Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF9CA3AF),
                              width: 1.6,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _checklist[i]['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      decoration: (_checklist[i]['done'] as bool)
                          ? TextDecoration.lineThrough
                          : null,
                      color: (_checklist[i]['done'] as bool)
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                  onPressed: () => setState(() => _checklist.removeAt(i)),
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        // New step input row
        Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9CA3AF), width: 1.6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _checklistInputController,
                focusNode: _checklistFocusNode,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Add steps to complete this task. Mark them done as you go.',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _addChecklistItem(),
                onTapOutside: (_) => _addChecklistItem(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, color: Color(0xFF5B4AD4), size: 20),
              onPressed: _addChecklistItem,
              splashRadius: 14,
            ),
          ],
        ),
      ],
    );
  }

  // ==================== Notes Section ====================
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextFormField(
            controller: _notesController,
            minLines: 4,
            maxLines: 7,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            decoration: const InputDecoration(
              hintText: 'Type a description or add notes here',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }



  // ==================== Bottom Actions ====================
  Widget _buildBottomActionBar(bool isEdit, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEdit && widget.onDelete != null) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete!();
              },
              child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ),
            const Spacer(),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4AD4),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isEdit ? 'Save changes' : 'Create task',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DUAL-PANE CALENDAR DIALOG (October 2026 day 11 ring + 2026 months)
  // ================================================================
  Future<void> _pickDualPaneDate({required bool isForDueDate}) async {
    final now = DateTime.now();
    var viewMonth = DateTime(now.year, now.month);
    var viewYear = now.year;
    DateTime? tempSelected = isForDueDate ? _dueDate : _startDate;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final monthName = _monthName(viewMonth.month);
            final daysInMonth = DateUtils.getDaysInMonth(viewMonth.year, viewMonth.month);
            final firstWeekday = DateTime(viewMonth.year, viewMonth.month, 1).weekday % 7; // Sunday=0

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Container(
                  width: 440,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Pane: Month Grid (e.g. October 2026)
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                      splashRadius: 14,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        setPickerState(() {
                                          viewMonth = DateTime(viewMonth.year, viewMonth.month - 1);
                                        });
                                      },
                                    ),
                                    Text(
                                      '$monthName ${viewMonth.year}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                      splashRadius: 14,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        setPickerState(() {
                                          viewMonth = DateTime(viewMonth.year, viewMonth.month + 1);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: const [
                                    _CalendarColHeader('Su'),
                                    _CalendarColHeader('Mo'),
                                    _CalendarColHeader('Tu'),
                                    _CalendarColHeader('We'),
                                    _CalendarColHeader('Th'),
                                    _CalendarColHeader('Fr'),
                                    _CalendarColHeader('Sa'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  children: [
                                    for (int e = 0; e < firstWeekday; e++)
                                      const SizedBox(width: 30, height: 26),
                                    for (int d = 1; d <= daysInMonth; d++) ...[
                                      InkWell(
                                        onTap: () {
                                          final selected = DateTime(viewMonth.year, viewMonth.month, d);
                                          Navigator.of(ctx).pop(selected);
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: SizedBox(
                                          width: 30,
                                          height: 26,
                                          child: Center(
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (tempSelected != null &&
                                                        tempSelected.year == viewMonth.year &&
                                                        tempSelected.month == viewMonth.month &&
                                                        tempSelected.day == d)
                                                    ? const Color(0xFF5B4AD4)
                                                    : Colors.transparent,
                                                border: (viewMonth.month == 10 && viewMonth.year == 2026 && d == 11)
                                                    ? Border.all(color: const Color(0xFF5B4AD4), width: 1.8)
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '$d',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: (tempSelected != null &&
                                                          tempSelected.year == viewMonth.year &&
                                                          tempSelected.month == viewMonth.month &&
                                                          tempSelected.day == d)
                                                      ? Colors.white
                                                      : ((viewMonth.month == 10 && viewMonth.year == 2026 && d == 11)
                                                          ? const Color(0xFF5B4AD4)
                                                          : const Color(0xFF111827)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                        // Right Pane: Year & 12 Month Grid
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                      splashRadius: 14,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        setPickerState(() {
                                          viewYear--;
                                          viewMonth = DateTime(viewYear, viewMonth.month);
                                        });
                                      },
                                    ),
                                    Text(
                                      '$viewYear',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                      splashRadius: 14,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        setPickerState(() {
                                          viewYear++;
                                          viewMonth = DateTime(viewYear, viewMonth.month);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                GridView.count(
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 1.8,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    for (int m = 1; m <= 12; m++)
                                      InkWell(
                                        onTap: () {
                                          setPickerState(() {
                                            viewMonth = DateTime(viewYear, m);
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: (viewMonth.month == m && viewMonth.year == viewYear)
                                                ? const Color(0x1F5B4AD4)
                                                : const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: (viewMonth.month == m && viewMonth.year == viewYear)
                                                  ? const Color(0xFF5B4AD4)
                                                  : const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _shortMonthName(m),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: (viewMonth.month == m && viewMonth.year == viewYear)
                                                  ? const Color(0xFF5B4AD4)
                                                  : const Color(0xFF374151),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isForDueDate) {
          _dueDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  // ==================== Labels Popup Dialog ====================
  Future<void> _showLabelsDialog() async {
    final searchCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = _kPresetLabels.where((l) => l.name.toLowerCase().contains(query)).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Labels',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 14, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: searchCtrl,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: 'Search for label',
                                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setDlgState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final labelDef in filtered) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (_selectedLabels.contains(labelDef.name)) {
                                _selectedLabels.remove(labelDef.name);
                              } else {
                                _selectedLabels.add(labelDef.name);
                              }
                            });
                            // Immediately close popup so user can proceed
                            Navigator.of(ctx).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: labelDef.bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _selectedLabels.contains(labelDef.name)
                                          ? Border.all(color: labelDef.text, width: 1.5)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          labelDef.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: labelDef.text,
                                          ),
                                        ),
                                        if (_selectedLabels.contains(labelDef.name))
                                          Icon(Icons.check_rounded, size: 14, color: labelDef.text),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF6B7280)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== Assignee Popup Dialog ====================
  Future<void> _showAssigneeDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Container(
                  width: 270,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Assign to members',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 6),
                      if (widget.boardMembers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'No members available',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        )
                      else
                        for (final member in widget.boardMembers) ...[
                          Builder(
                            builder: (context) {
                              final userId = (member['id'] ?? member['user_id'])?.toString() ?? '';
                              final name = (member['name'] ?? member['email'] ?? userId).toString();
                              final isAssigned = _selectedAssignees.contains(userId);

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isAssigned) {
                                      _selectedAssignees.remove(userId);
                                    } else {
                                      _selectedAssignees.add(userId);
                                    }
                                  });
                                  // Immediately close popup so user can proceed
                                  Navigator.of(ctx).pop();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: const Color(0xFF5B4AD4),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                                        ),
                                      ),
                                      if (isAssigned)
                                        const Icon(Icons.check_rounded, size: 16, color: Color(0xFF5B4AD4)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _monthName(int month) {
    const m = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return m[month - 1];
  }

  static String _shortMonthName(int month) {
    const sm = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return sm[month - 1];
  }
}

class _CalendarColHeader extends StatelessWidget {
  final String text;
  const _CalendarColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
