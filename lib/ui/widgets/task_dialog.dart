import 'package:flutter/material.dart';

/// Task Creation/Edit Dialog
/// Full featured dialog with all task properties
class TaskDialog extends StatefulWidget {
  final String? taskId;
  final Map<String, dynamic>? existingTask;
  final List<Map<String, dynamic>> boardMembers;
  final Function({
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? deadline,
    List<String>? assignees,
    List<String>? labels,
  }) onSave;

  const TaskDialog({
    super.key,
    this.taskId,
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
  String _priority = 'medium';
  String _status = 'todo';
  DateTime? _deadline;
  final List<String> _selectedAssignees = [];
  final List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingTask?['title'] ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingTask?['description'] ?? '',
    );
    _priority = widget.existingTask?['priority'] ?? 'medium';
    _status = widget.existingTask?['status'] ?? 'todo';
    
    if (widget.existingTask?['deadline'] != null) {
      try {
        _deadline = DateTime.parse(widget.existingTask!['deadline'] as String);
      } catch (e) {
        debugPrint('Error parsing deadline: $e');
      }
    }
    
    // Load existing assignees
    if (widget.existingTask?['assignees'] != null) {
      final assignees = widget.existingTask!['assignees'];
      if (assignees is List) {
        _selectedAssignees.addAll(assignees.cast<String>());
      }
    }
    
    if (widget.existingTask?['labels'] != null) {
      final labels = widget.existingTask!['labels'];
      if (labels is List) {
        _labels.addAll(labels.cast<String>());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskId != null;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 700 
        ? 600.0 
        : (screenSize.width > 500 ? screenSize.width * 0.85 : screenSize.width * 0.95);
    final maxHeight = screenSize.height * 0.85;
    
    return AlertDialog(
      title: Text(isEdit ? 'Edit Task' : 'Create Task'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              
              // Description
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              
              // Priority & Status Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Low'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text('Medium'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text('High'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text('Urgent'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _priority = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.analytics),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'todo',
                          child: Row(
                            children: [
                              Icon(Icons.circle_outlined, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text('TODO'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'doing',
                          child: Row(
                            children: [
                              Icon(Icons.pending, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text('DOING'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'done',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('DONE'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Deadline
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date != null) {
                    setState(() => _deadline = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Deadline',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: _deadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _deadline = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _deadline == null
                        ? 'No deadline'
                        : '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _deadline == null ? Colors.grey : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Assignees
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assignees', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_selectedAssignees.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedAssignees.map((userId) {
                            final member = widget.boardMembers.firstWhere(
                              (m) => m['id'] == userId,
                              orElse: () => {'name': 'Unknown', 'id': userId},
                            );
                            final name = member['name'] as String? ?? 'Unknown';
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              label: Text(name.length > 15 ? '${name.substring(0, 15)}...' : name),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() => _selectedAssignees.remove(userId));
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Add Assignee',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    value: null,
                    items: widget.boardMembers
                        .where((m) => !_selectedAssignees.contains(m['id']))
                        .map((member) {
                          final name = member['name'] as String? ?? 'Unknown';
                          return DropdownMenuItem<String>(
                            value: member['id'] as String,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (userId) {
                      if (userId != null) {
                        setState(() => _selectedAssignees.add(userId));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                widget.onSave(
                  title: title,
                  description: _descController.text.trim().isEmpty
                      ? null
                      : _descController.text.trim(),
                  priority: _priority,
                  status: _status,
                  deadline: _deadline,
                  assignees: _selectedAssignees.isEmpty ? null : _selectedAssignees,
                  labels: _labels.isEmpty ? null : _labels,
                );
              },
              icon: Icon(isEdit ? Icons.save : Icons.add),
              label: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ],
    );
  }
}
