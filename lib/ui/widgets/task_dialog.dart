import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task_model.dart';
import '../theme/app_colors.dart';

/// Clean Trello-style Task Creation/Edit Dialog
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
  late TextEditingController _descController;
  late TextEditingController _hoursController;
  late TextEditingController _labelController;
  String _priority = 'medium';
  String _status = 'todo';
  DateTime? _deadline;
  final List<String> _selectedAssignees = [];
  final List<String> _labels = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingTask?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingTask?.description ?? '',
    );
    _hoursController = TextEditingController(
      text: widget.existingTask?.estimatedHours?.toString() ?? '',
    );
    _labelController = TextEditingController();
    _priority = widget.existingTask?.priority ?? 'medium';
    _status = widget.existingTask?.status ?? widget.initialStatus;
    
    if (widget.existingTask?.deadline != null) {
      _deadline = widget.existingTask!.deadline;
    }
    
    // Load existing assignees
    if (widget.existingTask?.assignees != null) {
      _selectedAssignees.addAll(widget.existingTask!.assignees);
    }
    
    // Load existing labels
    if (widget.existingTask?.labels != null) {
      _labels.addAll(widget.existingTask!.labels);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _hoursController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTask != null;
    final screenSize = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;
    final dialogWidth = screenSize.width > 640 ? 560.0 : screenSize.width - 40;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? l10n.editTask : l10n.createTask,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 560;
                      final story = _storyFields(l10n);
                      final meta = _metaFields(l10n);
                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [story, const SizedBox(height: 16), meta],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: story),
                          const SizedBox(width: 20),
                          SizedBox(width: 240, child: meta),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isEdit && widget.onDelete != null)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDelete!();
                      },
                      child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                    label: Text(isEdit ? l10n.save : l10n.create),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _titleController,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(hintText: l10n.taskTitle),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return l10n.taskTitleRequired;
            return null;
          },
          autofocus: widget.existingTask == null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descController,
          decoration: InputDecoration(
            hintText: l10n.description,
            alignLabelWithHint: true,
          ),
          minLines: 4,
          maxLines: 8,
        ),
        const SizedBox(height: 16),
        Text(l10n.labels, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        _buildLabelInput(),
        if (_labels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in _labels)
                Chip(
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _labels.remove(label)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _metaFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(labelText: l10n.status),
          items: [
            DropdownMenuItem(value: 'todo', child: Text(l10n.todo)),
            DropdownMenuItem(value: 'doing', child: Text(l10n.inProgress)),
            DropdownMenuItem(value: 'done', child: Text(l10n.done)),
          ],
          onChanged: (value) => setState(() => _status = value!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _priority,
          decoration: InputDecoration(labelText: l10n.priority),
          items: [
            _buildPriorityItem('low', l10n.low, AppColors.success),
            _buildPriorityItem('medium', l10n.medium, AppColors.info),
            _buildPriorityItem('high', l10n.high, AppColors.warning),
            _buildPriorityItem('urgent', l10n.urgent, AppColors.error),
          ],
          onChanged: (value) => setState(() => _priority = value!),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDeadline,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.deadline,
              suffixIcon: _deadline == null
                  ? const Icon(Icons.calendar_today_outlined, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _deadline = null),
                    ),
            ),
            child: Text(
              _deadline != null ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}' : l10n.selectDate,
              style: TextStyle(color: _deadline != null ? AppColors.textPrimary : AppColors.textTertiary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hoursController,
          decoration: InputDecoration(labelText: l10n.estimatedHours, hintText: '0'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Text(l10n.assignees, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        _buildAssigneeSelector(),
      ],
    );
  }

  DropdownMenuItem<String> _buildPriorityItem(
    String value,
    String label,
    Color color,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildAssigneeSelector() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.boardMembers.isEmpty) {
      return Text(l10n.noMembersAvailable, style: const TextStyle(color: AppColors.textSecondary));
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.boardMembers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final member = widget.boardMembers[index];
          final userId = (member['id'] ?? member['user_id'])?.toString() ?? '';
          if (userId.isEmpty) return const SizedBox.shrink();
          final userName = member['name']?.toString();
          final userEmail = member['email']?.toString();
          final displayName = (userName != null && userName.isNotEmpty) ? userName : (userEmail ?? '?');
          final selected = _selectedAssignees.contains(userId);
          return Material(
            color: selected ? AppColors.primarySubtle : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedAssignees.remove(userId);
                  } else {
                    _selectedAssignees.add(userId);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryDark,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: selected ? AppColors.primaryDark : AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabelInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _labelController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.addLabel,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_rounded),
            ),
            onSubmitted: _addLabel,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: () => _addLabel(_labelController.text),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  void _addLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isNotEmpty && !_labels.contains(trimmed)) {
      setState(() {
        _labels.add(trimmed);
        _labelController.clear();
      });
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _deadline = date);
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final estimatedHours = double.tryParse(_hoursController.text.trim());

    widget.onSave(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      priority: _priority,
      status: _status,
      deadline: _deadline,
      assignees: _selectedAssignees.isNotEmpty ? _selectedAssignees : null,
      labels: _labels.isNotEmpty ? _labels : null,
      estimatedHours: estimatedHours,
    );

    Navigator.of(context).pop();
  }
}
