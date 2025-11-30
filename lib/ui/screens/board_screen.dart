import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../../providers/app_providers.dart';
import '../../models/operation/operation.dart';

enum DrawingTool { pen, eraser, text }

class _ActiveStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final String userName;
  final bool isEraser;

  _ActiveStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.userName,
    this.isEraser = false,
  });
}

/// Board Screen - Canvas (Canva) + Kanban (Trello)
/// Simple and clean implementation for realtime P2P collaboration
class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  // Drawing state
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  String? _currentStrokeId;
  
  // Drawing tools
  DrawingTool _selectedTool = DrawingTool.pen;
  
  // Text tool state
  final _textController = TextEditingController();
  Offset? _textPosition;
  double _textSize = 16.0; // Default text size
  
  // Undo/Redo
  final List<String> _undoStack = [];
  
  // Active strokes (for showing username while drawing)
  final Map<String, _ActiveStroke> _activeStrokes = {};
  
  // Kanban state
  final _taskController = TextEditingController();
  bool _showKanban = true;

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initBoard() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    
    // Connect to P2P first
    ref.read(whiteboardProvider.notifier).connectToBoard(widget.boardId);
    
    // Load from backend
    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    try {
      debugPrint('🚀 Board initialized for P2P collaboration');
      
      // Load existing tasks from backend API
      final api = ref.read(apiServiceProvider);
      final existingTasks = await api.getBoardTasks(widget.boardId);
      
      final notifier = ref.read(whiteboardProvider.notifier);
      for (final task in existingTasks) {
        // Create operation with full task data from database
        final operation = Operation(
          opId: task['id'] ?? 'task-${DateTime.now().millisecondsSinceEpoch}',
          actor: task['created_by'] ?? 'backend',
          timestamp: task['created_at'] != null
              ? DateTime.parse(task['created_at'] as String).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
          type: OperationType.createObject,
          payload: {
            'id': task['id'],
            'type': 'task',
            'data': {
              'title': task['title'] ?? 'Untitled',
              'description': task['description'],
              'status': task['status'] ?? 'todo',
              'priority': task['priority'] ?? 'medium',
              'assignee': task['assignee'],
              'assignee_id': task['assignee_id'],
              'assignee_name': task['assignee_name'],
              'progress': task['progress'] ?? 0,
              'deadline': task['deadline'],
              'labels': task['labels'],
              'estimated_hours': task['estimated_hours'],
              'parent_id': task['parent_id'],
              'position': task['position'],
              'created_by': task['created_by'],
              'creator_name': task['creator_name'],
              'created_at': task['created_at'],
              'updated_at': task['updated_at'],
            },
          },
        );
        notifier.receiveOperation(operation);
      }
      
      debugPrint('✅ Loaded ${existingTasks.length} tasks from backend');
    } catch (e) {
      debugPrint('❌ Error loading tasks: $e');
    }
  }

  // ===== DRAWING METHODS =====
  
  void _onPanStart(Offset point) {
    if (_selectedTool == DrawingTool.text) return;
    
    final notifier = ref.read(whiteboardProvider.notifier);
    final authState = ref.read(authStateProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Get display name: use name if available, otherwise email
    final displayName = authState.user?.name?.isNotEmpty == true
        ? authState.user!.name!
        : authState.user?.email ?? 'Unknown';
    
    _currentStrokeId = 'stroke-$now';
    _currentPoints = [point];
    
    // For eraser, use white color with thicker width
    final isEraser = _selectedTool == DrawingTool.eraser;
    final strokeColor = isEraser ? Colors.white : _selectedColor;
    final strokeWidth = isEraser ? _strokeWidth * 3 : _strokeWidth;
    
    // Track active stroke for realtime display
    setState(() {
      _activeStrokes[_currentStrokeId!] = _ActiveStroke(
        points: [point],
        color: strokeColor,
        width: strokeWidth,
        userName: displayName,
        isEraser: isEraser,
      );
    });
    
    // Create initial stroke - SAVE to backend
    notifier.createOperation(
      OperationType.createObject,
      {
        'id': _currentStrokeId,
        'type': 'stroke',
        'data': {
          'points': [point.dx, point.dy],
          'color': strokeColor.value,
          'width': strokeWidth,
          'actor': authState.user?.id ?? 'unknown',
          'actorName': displayName,
          'isEraser': isEraser,
        },
      },
      shouldSaveBackend: true,
    );
    
    debugPrint('🖊️ Start ${isEraser ? "eraser" : "stroke"}: $_currentStrokeId by $displayName');
  }

  void _onPanUpdate(Offset point) {
    if (_currentStrokeId == null || _selectedTool == DrawingTool.text) return;
    
    setState(() {
      _currentPoints.add(point);
      _activeStrokes[_currentStrokeId!]?.points.add(point);
    });
    
    final notifier = ref.read(whiteboardProvider.notifier);
    final authState = ref.read(authStateProvider);
    final points = _currentPoints.expand((p) => [p.dx, p.dy]).toList();
    
    // Get display name
    final displayName = authState.user?.name?.isNotEmpty == true
        ? authState.user!.name!
        : authState.user?.email ?? 'Unknown';
    
    // For eraser, use white color with thicker width
    final isEraser = _selectedTool == DrawingTool.eraser;
    final strokeColor = isEraser ? Colors.white : _selectedColor;
    final strokeWidth = isEraser ? _strokeWidth * 3 : _strokeWidth;
    
    // Update stroke - P2P ONLY (no backend save)
    notifier.createOperation(
      OperationType.updateObject,
      {
        'id': _currentStrokeId,
        'type': 'stroke',
        'data': {
          'points': points,
          'color': strokeColor.value,
          'width': strokeWidth,
          'actor': authState.user?.id ?? 'unknown',
          'actorName': displayName,
          'isEraser': isEraser,
        },
      },
      shouldSaveBackend: false, // P2P only for smooth drawing
    );
  }

  void _onPanEnd() {
    if (_currentStrokeId == null) return;
    
    final notifier = ref.read(whiteboardProvider.notifier);
    final authState = ref.read(authStateProvider);
    final points = _currentPoints.expand((p) => [p.dx, p.dy]).toList();
    
    // Get display name
    final displayName = authState.user?.name?.isNotEmpty == true
        ? authState.user!.name!
        : authState.user?.email ?? 'Unknown';
    
    // For eraser, use white color with thicker width
    final isEraser = _selectedTool == DrawingTool.eraser;
    final strokeColor = isEraser ? Colors.white : _selectedColor;
    final strokeWidth = isEraser ? _strokeWidth * 3 : _strokeWidth;
    
    // Final stroke - SAVE to backend
    notifier.createOperation(
      OperationType.updateObject,
      {
        'id': _currentStrokeId,
        'type': 'stroke',
        'data': {
          'points': points,
          'color': strokeColor.value,
          'width': strokeWidth,
          'actor': authState.user?.id ?? 'unknown',
          'actorName': displayName,
          'isEraser': isEraser,
        },
      },
      shouldSaveBackend: true,
    );
    
    // Add to undo stack
    _undoStack.add(_currentStrokeId!);
    
    debugPrint('✅ Finish ${isEraser ? "eraser" : "stroke"}: $_currentStrokeId (${_currentPoints.length} points)');
    
    // Clear active stroke after a delay to show completion
    final strokeId = _currentStrokeId;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _activeStrokes.remove(strokeId);
        });
      }
    });
    
    _currentStrokeId = null;
    _currentPoints = [];
  }

  // ===== UNDO/REDO =====
  
  void _undo() {
    if (_undoStack.isEmpty) return;
    
    final strokeId = _undoStack.removeLast();
    final notifier = ref.read(whiteboardProvider.notifier);
    
    notifier.createOperation(
      OperationType.deleteObject,
      {
        'id': strokeId,
        'type': 'stroke',
      },
      shouldSaveBackend: true,
    );
    
    debugPrint('↩️ Undo stroke: $strokeId');
  }
  
  // ===== TEXT TOOL =====
  
  void _onCanvasTap(Offset position) {
    if (_selectedTool != DrawingTool.text) return;
    
    setState(() {
      _textPosition = position;
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addText();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _addText() {
    if (_textController.text.trim().isEmpty || _textPosition == null) return;
    
    final notifier = ref.read(whiteboardProvider.notifier);
    final authState = ref.read(authStateProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final textId = 'text-$now';
    
    // Get display name
    final displayName = authState.user?.name?.isNotEmpty == true
        ? authState.user!.name!
        : authState.user?.email ?? 'Unknown';
    
    notifier.createOperation(
      OperationType.createObject,
      {
        'id': textId,
        'type': 'text',
        'data': {
          'text': _textController.text.trim(),
          'position': [_textPosition!.dx, _textPosition!.dy],
          'color': _selectedColor.value,
          'fontSize': _textSize,
          'actor': authState.user?.id ?? 'unknown',
          'actorName': displayName,
        },
      },
      shouldSaveBackend: true,
    );
    
    _textController.clear();
    _textPosition = null;
    _undoStack.add(textId);
    
    debugPrint('📝 Added text by $displayName');
  }

  // ===== KANBAN METHODS =====
  
  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;
    
    final title = _taskController.text.trim();
    _taskController.clear();
    
    try {
      // Save to backend via API first
      final api = ref.read(apiServiceProvider);
      final response = await api.createTask(
        boardId: widget.boardId,
        title: title,
        description: null,
        assignee: null,
        assigneeId: null,
        status: 'todo',
        priority: 'medium',
        deadline: null,
        progress: 0,
        parentId: null,
        labels: null,
        estimatedHours: null,
      );
      
      final taskId = response['id'] as String;
      
      // Then broadcast via P2P (without saving to backend again)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.createObject,
        {
          'id': taskId,
          'type': 'task',
          'data': {
            'title': title,
            'description': response['description'],
            'status': 'todo',
            'priority': response['priority'] ?? 'medium',
            'assignee': response['assignee'],
            'assignee_id': response['assignee_id'],
            'progress': response['progress'] ?? 0,
            'created_by': response['created_by'],
            'creator_name': response['creator_name'],
          },
        },
        shouldSaveBackend: false, // Already saved via API
      );
      
      debugPrint('✅ Added task: $title (id: $taskId)');
    } catch (e) {
      debugPrint('❌ Error adding task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    // Find current task data
    Map<String, dynamic>? taskData;
    for (final op in ref.read(whiteboardProvider).operations) {
      if (op.payload['id'] == taskId && op.payload['type'] == 'task') {
        taskData = Map<String, dynamic>.from(op.payload['data'] ?? {});
        break;
      }
    }
    
    if (taskData == null) {
      debugPrint('⚠️  Task not found: $taskId');
      return;
    }
    
    try {
      // Update via API
      final api = ref.read(apiServiceProvider);
      await api.updateTask(taskId: taskId, status: newStatus);
      
      // Update local state
      taskData['status'] = newStatus;
      
      // Broadcast P2P (without backend save)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.updateObject,
        {
          'id': taskId,
          'type': 'task',
          'data': taskData,
        },
        shouldSaveBackend: false, // Already saved via API
      );
      
      debugPrint('✅ Updated task status: $taskId → $newStatus');
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      // Delete via API
      final api = ref.read(apiServiceProvider);
      await api.deleteTask(taskId);
      
      // Broadcast P2P (without backend save)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.deleteObject,
        {
          'id': taskId,
          'type': 'task',
        },
        shouldSaveBackend: false, // Already deleted via API
      );
      
      debugPrint('✅ Deleted task: $taskId');
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(whiteboardProvider);
    
    // Extract strokes and tasks from operations
    final strokes = <Map<String, dynamic>>[];
    final texts = <Map<String, dynamic>>[];
    final tasks = <Map<String, dynamic>>[];
    final peerActiveStrokes = <String, _ActiveStroke>{}; // Track peer strokes
    
    final myUserId = ref.watch(authStateProvider).user?.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final op in state.operations) {
      final id = op.payload['id'] as String?;
      final type = op.payload['type'] as String?;
      
      if (id == null || type == null) continue;
      
      if (op.type == OperationType.deleteObject) {
        strokes.removeWhere((s) => s['id'] == id);
        texts.removeWhere((t) => t['id'] == id);
        tasks.removeWhere((t) => t['id'] == id);
        peerActiveStrokes.remove(id);
      } else if (type == 'stroke') {
        final data = Map<String, dynamic>.from(op.payload['data'] ?? {});
        final isFromPeer = op.actor != myUserId;
        final age = now - op.timestamp;
        
        // If stroke is recent (< 2 seconds) and from peer, show as active
        if (isFromPeer && age < 2000) {
          final pointsList = data['points'] as List?;
          if (pointsList != null && pointsList.length >= 2) {
            final points = <Offset>[];
            for (int i = 0; i < pointsList.length - 1; i += 2) {
              points.add(Offset(
                (pointsList[i] as num).toDouble(),
                (pointsList[i + 1] as num).toDouble(),
              ));
            }
            
            if (points.isNotEmpty) {
              peerActiveStrokes[id] = _ActiveStroke(
                points: points,
                color: Color((data['color'] as num?)?.toInt() ?? 0xFF000000),
                width: (data['width'] as num?)?.toDouble() ?? 3.0,
                userName: data['actorName'] as String? ?? 'Unknown',
                isEraser: data['isEraser'] == true,
              );
            }
          }
        }
        
        // Remove old version and add new
        strokes.removeWhere((s) => s['id'] == id);
        strokes.add({
          'id': id,
          ...data,
        });
      } else if (type == 'text') {
        texts.removeWhere((t) => t['id'] == id);
        texts.add({
          'id': id,
          ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
        });
      } else if (type == 'task') {
        tasks.removeWhere((t) => t['id'] == id);
        tasks.add({
          'id': id,
          ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
        });
      }
    }
    
    final todoTasks = tasks.where((t) => t['status'] == 'todo').toList();
    final doingTasks = tasks.where((t) => t['status'] == 'doing').toList();
    final doneTasks = tasks.where((t) => t['status'] == 'done').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board - Canvas + Kanban'),
        actions: [
          IconButton(
            icon: Icon(_showKanban ? Icons.view_sidebar : Icons.view_sidebar_outlined),
            onPressed: () => setState(() => _showKanban = !_showKanban),
            tooltip: 'Toggle Kanban',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('P2P Status'),
                  content: Text(
                    'Strokes: ${strokes.length}\n'
                    'Texts: ${texts.length}\n'
                    'Tasks: ${tasks.length}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Canvas area
          Expanded(
            child: Column(
              children: [
                // Color picker and tools
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      // Show current user
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              ref.watch(authStateProvider).user?.name?.isNotEmpty == true
                                  ? ref.watch(authStateProvider).user!.name!
                                  : ref.watch(authStateProvider).user?.email ?? 'You',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Drawing tools
                      _ToolButton(
                        icon: Icons.edit,
                        label: 'Pen',
                        isSelected: _selectedTool == DrawingTool.pen,
                        onTap: () => setState(() => _selectedTool = DrawingTool.pen),
                      ),
                      _ToolButton(
                        icon: Icons.cleaning_services,
                        label: 'Eraser',
                        isSelected: _selectedTool == DrawingTool.eraser,
                        onTap: () => setState(() => _selectedTool = DrawingTool.eraser),
                      ),
                      _ToolButton(
                        icon: Icons.text_fields,
                        label: 'Text',
                        isSelected: _selectedTool == DrawingTool.text,
                        onTap: () => setState(() => _selectedTool = DrawingTool.text),
                      ),
                      
                      const VerticalDivider(),
                      
                      // Undo button
                      IconButton(
                        icon: const Icon(Icons.undo),
                        onPressed: _undoStack.isEmpty ? null : _undo,
                        tooltip: 'Undo (${_undoStack.length})',
                      ),
                      
                      const VerticalDivider(),
                      const Text('Color: '),
                      const SizedBox(width: 8),
                      ...['black', 'red', 'blue', 'green', 'yellow', 'orange', 'purple'].map(
                        (colorName) {
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
                                  color: _selectedColor == color ? Colors.black : Colors.grey,
                                  width: _selectedColor == color ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      
                      // Stroke width slider
                      const Text('Width: '),
                      SizedBox(
                        width: 100,
                        child: Slider(
                          value: _strokeWidth,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _strokeWidth.round().toString(),
                          onChanged: (value) => setState(() => _strokeWidth = value),
                        ),
                      ),
                      
                      // Text size slider (shown only when text tool selected)
                      if (_selectedTool == DrawingTool.text) ...[
                        const SizedBox(width: 16),
                        const Text('Text Size: '),
                        SizedBox(
                          width: 120,
                          child: Slider(
                            value: _textSize,
                            min: 12,
                            max: 72,
                            divisions: 12,
                            label: _textSize.round().toString(),
                            onChanged: (value) => setState(() => _textSize = value),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Canvas
                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) => _onCanvasTap(details.localPosition),
                    onPanStart: (details) => _onPanStart(details.localPosition),
                    onPanUpdate: (details) => _onPanUpdate(details.localPosition),
                    onPanEnd: (details) => _onPanEnd(),
                    child: Container(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: _StrokePainter(
                          strokes: strokes,
                          texts: texts,
                          activeStrokes: {..._activeStrokes, ...peerActiveStrokes},
                        ),
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
              width: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Add task input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _taskController,
                          decoration: const InputDecoration(
                            hintText: 'Add new task...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addTask,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Task'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Task columns
                  Expanded(
                    child: Row(
                      children: [
                        _TaskColumn(
                          title: 'TODO',
                          tasks: todoTasks,
                          onMove: (id) => _updateTaskStatus(id, 'doing'),
                          onDelete: _deleteTask,
                          color: Colors.orange,
                        ),
                        _TaskColumn(
                          title: 'DOING',
                          tasks: doingTasks,
                          onMove: (id) => _updateTaskStatus(id, 'done'),
                          onDelete: _deleteTask,
                          color: Colors.blue,
                        ),
                        _TaskColumn(
                          title: 'DONE',
                          tasks: doneTasks,
                          onMove: null,
                          onDelete: _deleteTask,
                          color: Colors.green,
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
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      default: return Colors.black;
    }
  }
}

// ===== CANVAS PAINTER =====

class _StrokePainter extends CustomPainter {
  final List<Map<String, dynamic>> strokes;
  final List<Map<String, dynamic>> texts;
  final Map<String, _ActiveStroke> activeStrokes;

  _StrokePainter({
    required this.strokes,
    required this.texts,
    required this.activeStrokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      final pointsList = stroke['points'] as List?;
      if (pointsList == null || pointsList.length < 2) continue;
      
      final points = <Offset>[];
      for (int i = 0; i < pointsList.length - 1; i += 2) {
        points.add(Offset(
          (pointsList[i] as num).toDouble(),
          (pointsList[i + 1] as num).toDouble(),
        ));
      }
      
      if (points.isEmpty) continue;
      
      final color = Color((stroke['color'] as num?)?.toInt() ?? 0xFF000000);
      final width = (stroke['width'] as num?)?.toDouble() ?? 3.0;
      
      // Draw stroke
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      
      final path = ui.Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Draw active strokes with username labels (realtime)
    for (final entry in activeStrokes.entries) {
      final activeStroke = entry.value;
      if (activeStroke.points.isEmpty) continue;
      
      // Draw stroke
      final paint = Paint()
        ..color = activeStroke.color
        ..strokeWidth = activeStroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      
      final path = ui.Path();
      path.moveTo(activeStroke.points[0].dx, activeStroke.points[0].dy);
      for (int i = 1; i < activeStroke.points.length; i++) {
        path.lineTo(activeStroke.points[i].dx, activeStroke.points[i].dy);
      }
      
      canvas.drawPath(path, paint);
      
      // Draw username label with tool indicator
      final toolIcon = activeStroke.isEraser ? '🧽' : '🖊️';
      final textSpan = TextSpan(
        text: '$toolIcon ${activeStroke.userName}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: activeStroke.isEraser 
              ? Colors.grey[700]!.withOpacity(0.8)
              : activeStroke.color.withOpacity(0.8),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      
      // Position label at current drawing position (last point)
      final lastPoint = activeStroke.points.last;
      final labelOffset = Offset(
        lastPoint.dx + 10,
        lastPoint.dy - 10,
      );
      textPainter.paint(canvas, labelOffset);
    }
    
    // Draw text objects
    for (final textObj in texts) {
      final text = textObj['text'] as String?;
      final positionList = textObj['position'] as List?;
      if (text == null || positionList == null || positionList.length < 2) continue;
      
      final position = Offset(
        (positionList[0] as num).toDouble(),
        (positionList[1] as num).toDouble(),
      );
      final color = Color((textObj['color'] as num?)?.toInt() ?? 0xFF000000);
      final fontSize = (textObj['fontSize'] as num?)?.toDouble() ?? 16.0;
      final actorName = textObj['actorName'] as String?;
      
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, position);
      
      // Draw author label if available
      if (actorName != null && actorName.isNotEmpty) {
        final authorSpan = TextSpan(
          text: '- $actorName',
          style: TextStyle(
            color: color.withOpacity(0.6),
            fontSize: fontSize * 0.6,
            fontStyle: FontStyle.italic,
          ),
        );
        final authorPainter = TextPainter(
          text: authorSpan,
          textDirection: ui.TextDirection.ltr,
        );
        authorPainter.layout();
        authorPainter.paint(
          canvas,
          Offset(position.dx, position.dy + fontSize + 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) {
    return strokes.length != oldDelegate.strokes.length ||
        texts.length != oldDelegate.texts.length ||
        activeStrokes.length != oldDelegate.activeStrokes.length;
  }
}

// ===== TASK COLUMN =====

class _TaskColumn extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> tasks;
  final Function(String)? onMove;
  final Function(String) onDelete;
  final Color color;

  const _TaskColumn({
    required this.title,
    required this.tasks,
    required this.onMove,
    required this.onDelete,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final taskId = task['id'] as String;
                  final title = task['title'] as String? ?? 'Untitled';
                  final description = task['description'] as String?;
                  final priority = task['priority'] as String? ?? 'medium';
                  final assigneeName = task['assignee_name'] as String?;
                  final progress = task['progress'] as int? ?? 0;
                  
                  // Priority colors
                  Color priorityColor = Colors.grey;
                  IconData priorityIcon = Icons.flag_outlined;
                  switch (priority) {
                    case 'urgent':
                      priorityColor = Colors.red;
                      priorityIcon = Icons.flag;
                      break;
                    case 'high':
                      priorityColor = Colors.orange;
                      priorityIcon = Icons.flag;
                      break;
                    case 'medium':
                      priorityColor = Colors.blue;
                      priorityIcon = Icons.flag_outlined;
                      break;
                    case 'low':
                      priorityColor = Colors.green;
                      priorityIcon = Icons.flag_outlined;
                      break;
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description != null && description.isNotEmpty)
                            Text(
                              description,
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(priorityIcon, size: 10, color: priorityColor),
                              const SizedBox(width: 4),
                              if (assigneeName != null)
                                Expanded(
                                  child: Text(
                                    assigneeName,
                                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (progress > 0)
                                Text(
                                  '$progress%',
                                  style: TextStyle(fontSize: 9, color: Colors.blue[700]),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onMove != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              onPressed: () => onMove!(taskId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            onPressed: () => onDelete(taskId),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== TOOL BUTTON WIDGET =====

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
