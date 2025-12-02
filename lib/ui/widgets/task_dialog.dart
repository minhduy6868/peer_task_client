import 'package:flutter/material.dart';
import '../../models/task_model.dart';

/// Clean Trello-style Task Creation/Edit Dialog
class TaskDialog extends StatefulWidget {
  final TaskModel? existingTask;
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
    _status = widget.existingTask?.status ?? 'todo';
    
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
    final dialogWidth = screenSize.width > 700 
        ? 600.0 
        : (screenSize.width > 500 ? screenSize.width * 0.85 : screenSize.width * 0.95);
    
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
                    isEdit ? Icons.edit : Icons.add_task,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Task' : 'Create Task',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
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
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter task title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                        autofocus: !isEdit,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Add more details...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Priority and Status
                      Row(
                        children: [
                          // Priority
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flag),
                              ),
                              items: [
                                _buildPriorityItem('low', 'Low', Colors.green),
                                _buildPriorityItem('medium', 'Medium', Colors.blue),
                                _buildPriorityItem('high', 'High', Colors.orange),
                                _buildPriorityItem('urgent', 'Urgent', Colors.red),
                              ],
                              onChanged: (value) {
                                setState(() => _priority = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Status
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.list),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'todo', child: Text('To Do')),
                                DropdownMenuItem(value: 'doing', child: Text('In Progress')),
                                DropdownMenuItem(value: 'done', child: Text('Done')),
                              ],
                              onChanged: (value) {
                                setState(() => _status = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Deadline and Hours
                      Row(
                        children: [
                          // Deadline
                          Expanded(
                            child: InkWell(
                              onTap: _pickDeadline,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Deadline',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _deadline != null
                                      ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _deadline != null ? null : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_deadline != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => setState(() => _deadline = null),
                            ),
                          const SizedBox(width: 16),
                          // Estimated Hours
                          Expanded(
                            child: TextFormField(
                              controller: _hoursController,
                              decoration: const InputDecoration(
                                labelText: 'Hours',
                                hintText: '0',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Assignees
                      const Text(
                        'Assignees',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAssigneeSelector(),
                      const SizedBox(height: 16),

                      // Labels
                      const Text(
                        'Labels',
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
                              deleteIcon: const Icon(Icons.close, size: 16),
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: Icon(isEdit ? Icons.save : Icons.add),
                    label: Text(isEdit ? 'Save' : 'Create'),
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
          ? const Text('No members available', style: TextStyle(color: Colors.grey))
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
              prefixIcon: Icon(Icons.label),
            ),
            onSubmitted: _addLabel,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: () => _addLabel(_labelController.text),
          icon: const Icon(Icons.add),
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
