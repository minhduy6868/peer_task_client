import 'package:flutter/material.dart';
import '../../models/whiteboard_object.dart';
import '../../models/task_node.dart';
import 'common/color_picker.dart';
import 'common/stroke_width_slider.dart';

class PropertiesPanel extends StatefulWidget {
  final WhiteboardObject? selectedObject;
  final TaskNode? selectedTaskNode;
  final Function(Map<String, dynamic> properties)? onPropertiesChanged;
  final VoidCallback? onDelete;

  const PropertiesPanel({
    super.key,
    this.selectedObject,
    this.selectedTaskNode,
    this.onPropertiesChanged,
    this.onDelete,
  });

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  late TextEditingController _textController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _updateControllers();
  }

  @override
  void didUpdateWidget(PropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedObject != widget.selectedObject ||
        oldWidget.selectedTaskNode != widget.selectedTaskNode) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    if (widget.selectedTaskNode != null) {
      _titleController.text = widget.selectedTaskNode!.title;
      _descriptionController.text = widget.selectedTaskNode!.description ?? '';
    } else if (widget.selectedObject != null) {
      final data = widget.selectedObject!.data;
      _textController.text = (data['text'] as String?) ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedObject == null && widget.selectedTaskNode == null) {
      return Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No object selected',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an object to edit properties',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Properties',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),

          // Properties
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.selectedTaskNode != null
                  ? _buildTaskNodeProperties()
                  : _buildObjectProperties(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskNodeProperties() {
    final task = widget.selectedTaskNode!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Task Node', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),

        // Title
        const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          onChanged: (value) {
            widget.onPropertiesChanged?.call({'title': value});
          },
        ),
        const SizedBox(height: 16),

        // Description
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 3,
          onChanged: (value) {
            widget.onPropertiesChanged?.call({'description': value});
          },
        ),
        const SizedBox(height: 16),

        // Status
        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: task.status,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: ['todo', 'in_progress', 'done'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(_formatStatus(status)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onPropertiesChanged?.call({'status': value});
            }
          },
        ),
        const SizedBox(height: 16),

        // Priority
        const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: task.priority,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: ['low', 'medium', 'high'].map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: _getPriorityColor(priority),
                  ),
                  const SizedBox(width: 8),
                  Text(_formatStatus(priority)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onPropertiesChanged?.call({'priority': value});
            }
          },
        ),
        const SizedBox(height: 16),

        // Position
        const Text('Position', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'X: ${task.position.dx.toStringAsFixed(1)}, Y: ${task.position.dy.toStringAsFixed(1)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildObjectProperties() {
    final obj = widget.selectedObject!;
    final data = obj.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          obj.type.name.toUpperCase(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Text (if applicable)
        if (obj.type == WhiteboardObjectType.textBox || 
            obj.type == WhiteboardObjectType.stickyNote) ...[
          const Text('Text', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: obj.type == WhiteboardObjectType.stickyNote ? 5 : 1,
            onChanged: (value) {
              widget.onPropertiesChanged?.call({'text': value});
            },
          ),
          const SizedBox(height: 16),
        ],

        // Color
        const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ColorPicker(
          selectedColor: (data['color'] as int?) ?? (data['strokeColor'] as int?) ?? 0xFF000000,
          onColorSelected: (color) {
            widget.onPropertiesChanged?.call({'color': color});
          },
        ),
        const SizedBox(height: 16),

        // Stroke Width (if applicable)
        if (obj.type == WhiteboardObjectType.path || 
            obj.type == WhiteboardObjectType.rectangle ||
            obj.type == WhiteboardObjectType.circle ||
            obj.type == WhiteboardObjectType.arrow) ...[
          const Text('Stroke Width', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StrokeWidthSlider(
            value: ((data['strokeWidth'] as num?)?.toDouble() ?? 2.0).clamp(1.0, 20.0),
            onChanged: (value) {
              widget.onPropertiesChanged?.call({'strokeWidth': value});
            },
          ),
          const SizedBox(height: 16),
        ],

        // Position & Size
        const Text('Position', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            // Try to get position from different data structures
            Offset? position;
            if (data['position'] != null) {
              final posData = data['position'];
              if (posData is Map) {
                position = Offset((posData['dx'] as num?)?.toDouble() ?? 0, 
                                  (posData['dy'] as num?)?.toDouble() ?? 0);
              }
            } else if (data['points'] != null && data['points'] is List && (data['points'] as List).isNotEmpty) {
              final points = data['points'] as List;
              final firstPoint = points.first;
              if (firstPoint is Map) {
                position = Offset((firstPoint['dx'] as num?)?.toDouble() ?? 0, 
                                  (firstPoint['dy'] as num?)?.toDouble() ?? 0);
              }
            }
            
            return Text(
              'X: ${position?.dx.toStringAsFixed(1) ?? "0"}, '
              'Y: ${position?.dy.toStringAsFixed(1) ?? "0"}',
              style: TextStyle(color: Colors.grey[600]),
            );
          },
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
