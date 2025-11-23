import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/operation.dart';

/// Hybrid Board - Canvas vẽ + Kanban tasks
/// Kết hợp Canva (vẽ tự do) + Trello (phân công việc)
class HybridBoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const HybridBoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<HybridBoardScreen> createState() => _HybridBoardScreenState();
}

class _HybridBoardScreenState extends ConsumerState<HybridBoardScreen> {
  final _taskController = TextEditingController();
  final _assigneeController = TextEditingController();
  
  // Canvas drawing state
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isDrawing = false;
  bool _showKanban = true; // Toggle Kanban sidebar

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        ref.read(whiteboardProvider.notifier).connectToBoard(widget.boardId);
      }
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (!mounted || _taskController.text.trim().isEmpty) return;

    final authState = ref.read(authStateProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    final taskId = 'task-$now';

    notifier.createOperation(
      OperationType.createObject,
      {
        'id': taskId,
        'type': 'task',
        'data': {
          'title': _taskController.text.trim(),
          'assignee': _assigneeController.text.trim(),
          'status': 'todo',
          'timestamp': now,
        },
        'zIndex': 0,
        'version': 0,
        'createdBy': authState.user?.id ?? 'unknown',
        'createdAt': now,
        'updatedAt': now,
      },
    );

    _taskController.clear();
    _assigneeController.clear();
  }

  void _updateTaskStatus(String taskId, String newStatus) {
    if (!mounted) return;
    
    final state = ref.read(whiteboardProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final existing = state.operations.firstWhere(
      (op) => op.payload['id'] == taskId && op.type == OperationType.createObject,
      orElse: () => state.operations.first,
    );

    final existingData = Map<String, dynamic>.from(existing.payload['data'] ?? {});

    notifier.createOperation(
      OperationType.updateObject,
      {
        'id': taskId,
        'type': 'task',
        'data': {
          ...existingData,
          'status': newStatus,
        },
        'zIndex': existing.payload['zIndex'] ?? 0,
        'version': (existing.payload['version'] ?? 0) + 1,
        'createdBy': existing.payload['createdBy'] ?? 'unknown',
        'createdAt': existing.payload['createdAt'] ?? now,
        'updatedAt': now,
      },
    );
  }

  void _deleteTask(String taskId) {
    if (!mounted) return;
    
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.deleteObject,
      {'id': taskId},
    );
  }

  void _startDrawing(Offset point) {
    if (!_isDrawing) return;
    
    final authState = ref.read(authStateProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    final strokeId = 'stroke-$now';

    notifier.createOperation(
      OperationType.createObject,
      {
        'id': strokeId,
        'type': 'stroke',
        'data': {
          'points': [point.dx, point.dy],
          'color': _selectedColor.value,
          'strokeWidth': _strokeWidth,
        },
        'zIndex': 0,
        'version': 0,
        'createdBy': authState.user?.id ?? 'unknown',
        'createdAt': now,
        'updatedAt': now,
      },
    );
  }

  void _continueDrawing(String strokeId, Offset point) {
    if (!mounted) return;

    final state = ref.read(whiteboardProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = state.operations.firstWhere(
      (op) => op.payload['id'] == strokeId && op.type == OperationType.createObject,
      orElse: () => state.operations.first,
    );

    final existingData = Map<String, dynamic>.from(existing.payload['data'] ?? {});
    final points = List<double>.from(existingData['points'] ?? []);
    points.addAll([point.dx, point.dy]);

    notifier.createOperation(
      OperationType.updateObject,
      {
        'id': strokeId,
        'type': 'stroke',
        'data': {
          ...existingData,
          'points': points,
        },
        'zIndex': existing.payload['zIndex'] ?? 0,
        'version': (existing.payload['version'] ?? 0) + 1,
        'createdBy': existing.payload['createdBy'] ?? 'unknown',
        'createdAt': existing.payload['createdAt'] ?? now,
        'updatedAt': now,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(whiteboardProvider);
    
    // Extract tasks from operations
    final Map<String, Map<String, dynamic>> tasks = {};
    final List<Map<String, dynamic>> strokes = [];

    for (final op in state.operations) {
      final id = op.payload['id'] as String?;
      final type = op.payload['type'] as String?;
      if (id == null || type == null) continue;

      if (op.type == OperationType.createObject) {
        if (type == 'task') {
          tasks[id] = {
            'id': id,
            ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
          };
        } else if (type == 'stroke') {
          strokes.add({
            'id': id,
            ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
          });
        }
      } else if (op.type == OperationType.updateObject) {
        if (tasks.containsKey(id)) {
          tasks[id]!.addAll(Map<String, dynamic>.from(op.payload['data'] ?? {}));
        } else {
          final stroke = strokes.firstWhere(
            (s) => s['id'] == id,
            orElse: () => {},
          );
          if (stroke.isNotEmpty) {
            stroke.addAll(Map<String, dynamic>.from(op.payload['data'] ?? {}));
          }
        }
      } else if (op.type == OperationType.deleteObject) {
        tasks.remove(id);
        strokes.removeWhere((s) => s['id'] == id);
      }
    }

    final todoTasks = tasks.entries.where((e) => e.value['status'] == 'todo').toList();
    final doingTasks = tasks.entries.where((e) => e.value['status'] == 'doing').toList();
    final doneTasks = tasks.entries.where((e) => e.value['status'] == 'done').toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🎨 Hybrid Board - Canvas + Tasks'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Peers counter
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: state.isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text('${state.peers.length + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Toggle Kanban sidebar
          IconButton(
            icon: Icon(_showKanban ? Icons.view_sidebar : Icons.view_sidebar_outlined),
            onPressed: () => setState(() => _showKanban = !_showKanban),
            tooltip: _showKanban ? 'Hide Tasks' : 'Show Tasks',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Canvas area
          Expanded(
            flex: _showKanban ? 2 : 1,
            child: Column(
              children: [
                // Drawing toolbar
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // Drawing mode toggle
                      ToggleButtons(
                        isSelected: [_isDrawing, !_isDrawing],
                        onPressed: (index) {
                          setState(() => _isDrawing = index == 0);
                        },
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.brush, size: 18),
                                SizedBox(width: 4),
                                Text('Draw'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.pan_tool, size: 18),
                                SizedBox(width: 4),
                                Text('Pan'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      
                      // Color picker
                      const Text('Color:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ...['black', 'red', 'blue', 'green', 'orange', 'purple'].map((colorName) {
                        final color = _getColor(colorName);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == color ? Colors.black : Colors.grey[300]!,
                                width: _selectedColor == color ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(width: 16),
                      
                      // Stroke width
                      const Text('Width:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: Slider(
                          value: _strokeWidth,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: '${_strokeWidth.toInt()}px',
                          onChanged: (value) => setState(() => _strokeWidth = value),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Clear canvas
                      OutlinedButton.icon(
                        onPressed: () {
                          // Delete all strokes
                          for (final stroke in strokes) {
                            _deleteTask(stroke['id']);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear Canvas'),
                      ),
                    ],
                  ),
                ),

                // Canvas
                Expanded(
                  child: GestureDetector(
                    onPanStart: _isDrawing 
                        ? (details) => _startDrawing(details.localPosition)
                        : null,
                    onPanUpdate: _isDrawing 
                        ? (details) {
                            if (strokes.isNotEmpty) {
                              _continueDrawing(strokes.last['id'], details.localPosition);
                            }
                          }
                        : null,
                    child: Container(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: _CanvasPainter(strokes: strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Kanban sidebar
          if (_showKanban)
            Container(
              width: 400,
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
                children: [
                  // Task input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '➕ Add Task',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            hintText: 'Task title...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _assigneeController,
                                decoration: InputDecoration(
                                  hintText: '👤 Assignee',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addTask(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Icon(Icons.add, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Task columns
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _TaskSection(
                          title: '📋 To Do',
                          color: Colors.orange,
                          tasks: todoTasks,
                          onStatusChange: (id) => _updateTaskStatus(id, 'doing'),
                          onDelete: _deleteTask,
                          actionLabel: '▶️ Start',
                        ),
                        const SizedBox(height: 12),
                        _TaskSection(
                          title: '⚡ Doing',
                          color: Colors.blue,
                          tasks: doingTasks,
                          onStatusChange: (id) => _updateTaskStatus(id, 'done'),
                          onDelete: _deleteTask,
                          actionLabel: '✅ Done',
                        ),
                        const SizedBox(height: 12),
                        _TaskSection(
                          title: '✅ Done',
                          color: Colors.green,
                          tasks: doneTasks,
                          onStatusChange: null,
                          onDelete: _deleteTask,
                          actionLabel: null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getColor(String name) {
    switch (name) {
      case 'black': return Colors.black;
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      default: return Colors.black;
    }
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Map<String, dynamic>> strokes;

  _CanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final points = List<double>.from(stroke['points']);
      if (points.length < 2) continue;

      final paint = Paint()
        ..color = Color(stroke['color'] as int)
        ..strokeWidth = (stroke['strokeWidth'] as num).toDouble()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(points[0], points[1]);

      for (int i = 2; i < points.length; i += 2) {
        if (i + 1 < points.length) {
          path.lineTo(points[i], points[i + 1]);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) => true;
}

class _TaskSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<MapEntry<String, Map<String, dynamic>>> tasks;
  final Function(String)? onStatusChange;
  final Function(String) onDelete;
  final String? actionLabel;

  const _TaskSection({
    required this.title,
    required this.color,
    required this.tasks,
    required this.onStatusChange,
    required this.onDelete,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Empty', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          else
            ...tasks.map((entry) {
              final task = entry.value;
              return Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (task['assignee'] != null && (task['assignee'] as String).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            task['assignee'] as String,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (onStatusChange != null && actionLabel != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => onStatusChange!(entry.key),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(color: color),
                                foregroundColor: color,
                              ),
                              child: Text(actionLabel!, style: const TextStyle(fontSize: 11)),
                            ),
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => onDelete(entry.key),
                          icon: const Icon(Icons.delete, size: 16),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
