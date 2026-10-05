import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task_model.dart';
import '../theme/app_colors.dart';

/// Clean Trello-style Task Creation/Edit Dialog
class TaskDialog extends StatefulWidget {
  final TaskModel? existingTask;
  final String initialStatus;
  final List<Map<String, dynamic>> boardMembers;
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_rounded : Icons.add_task_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? l10n.editTask : l10n.createTask,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: l10n.title,
                          hintText: l10n.taskTitle,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.taskTitleRequired;
                          }
                          return null;
                        },
                        autofocus: !isEdit,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: l10n.description,
                          hintText: l10n.boardDescriptionOptional,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.description_rounded),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Priority and Status
                      _sideBySide(
                        DropdownButtonFormField<String>(
                          value: _priority,
                          decoration: InputDecoration(
                            labelText: l10n.priority,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.flag),
                          ),
                          items: [
                            _buildPriorityItem('low', l10n.low, AppColors.success),
                            _buildPriorityItem('medium', l10n.medium, AppColors.info),
                            _buildPriorityItem('high', l10n.high, AppColors.warning),
                            _buildPriorityItem('urgent', l10n.urgent, AppColors.error),
                          ],
                          onChanged: (value) {
                            setState(() => _priority = value!);
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            labelText: l10n.status,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.list),
                          ),
                          items: [
                            DropdownMenuItem(value: 'todo', child: Text(l10n.todo)),
                            DropdownMenuItem(value: 'doing', child: Text(l10n.inProgress)),
                            DropdownMenuItem(value: 'done', child: Text(l10n.done)),
                          ],
                          onChanged: (value) {
                            setState(() => _status = value!);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Deadline and Hours
                      _sideBySide(
                        InkWell(
                          onTap: _pickDeadline,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.deadline,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today_rounded),
                              suffixIcon: _deadline == null
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () => setState(() => _deadline = null),
                                    ),
                            ),
                            child: Text(
                              _deadline != null
                                  ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                  : l10n.selectDate,
                              style: TextStyle(
                                color: _deadline != null ? null : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _hoursController,
                          decoration: InputDecoration(
                            labelText: l10n.estimatedHours,
                            hintText: '0',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.timer),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assignees
                      Text(
                        l10n.assignees,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAssigneeSelector(),
                      const SizedBox(height: 16),

                      // Labels
                      Text(
                        l10n.labels,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildLabelInput(),
                      if (_labels.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _labels.map((label) {
                            return Chip(
                              label: Text(label),
                              deleteIcon: const Icon(Icons.close_rounded, size: 16),
                              onDeleted: () {
                                setState(() => _labels.remove(label));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

  Widget _sideBySide(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: widget.boardMembers.isEmpty
          ? Text(AppLocalizations.of(context)!.noMembersAvailable, style: const TextStyle(color: AppColors.textSecondary))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.boardMembers.map((member) {
                final userId = member['id'] as String;
                final userName = member['name'] as String?;
                final userEmail = member['email'] as String?;
                // Hiển thị tên nếu có, không thì hiển thị email
                final displayName = (userName != null && userName.isNotEmpty) 
                    ? userName 
                    : (userEmail ?? 'Unknown');
                final isSelected = _selectedAssignees.contains(userId);

                return FilterChip(
                  selected: isSelected,
                  label: Text(displayName),
                  avatar: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400],
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAssignees.add(userId);
                      } else {
                        _selectedAssignees.remove(userId);
                      }
                    });
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLabelInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              hintText: 'Add a label',
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
      firstDate: DateTime.now(),
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
