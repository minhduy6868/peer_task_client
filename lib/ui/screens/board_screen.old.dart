import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../../providers/app_providers.dart';
import '../../models/operation/operation.dart';
import '../../utils/error_display.dart';
import '../widgets/task_dialog.dart';

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
  List<Map<String, dynamic>> _boardMembers = [];

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
    
    // Load board members
    await _loadBoardMembers();
    
    // Load from backend
    _loadFromBackend();
  }

  Future<void> _loadBoardMembers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final members = await api.getBoardMembers(widget.boardId);
      setState(() {
        _boardMembers = members;
      });
      debugPrint('✅ Loaded ${members.length} board members');
    } catch (e) {
      debugPrint('❌ Error loading board members: $e');
    }
  }

  Future<void> _loadFromBackend() async {
    try {
      debugPrint('🚀 Board initialized for P2P collaboration');
      
      // Load existing tasks from backend API
      final api = ref.read(apiServiceProvider);
      final existingTasks = await api.getBoardTasks(widget.boardId);
      
      final notifier = ref.read(whiteboardProvider.notifier);
      for (final task in existingTasks) {
        // Create operation with simplified task data
        final operation = Operation(
          opId: task['id']?.toString() ?? 'task-${DateTime.now().millisecondsSinceEpoch}',
          actor: task['created_by']?.toString() ?? 'system',
          timestamp: task['created_at'] != null
              ? DateTime.parse(task['created_at'].toString()).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
          type: OperationType.createObject,
          payload: {
            'id': task['id']?.toString() ?? '',
            'type': 'task',
            'data': {
              'title': task['title']?.toString() ?? 'Untitled',
              'description': task['description']?.toString() ?? '',
              'status': task['status']?.toString() ?? 'todo',
              'priority': task['priority']?.toString() ?? 'medium',
              'assignees': (task['assignees'] as List?)?.map((e) => e.toString()).toList() ?? [],
              'assignee_list': (task['assignee_list'] as List?) ?? [],
              'deadline': task['deadline']?.toString() ?? '',
              'labels': (task['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
              'estimated_hours': task['estimated_hours']?.toString() ?? '',
              'parent_id': task['parent_id']?.toString() ?? '',
              'position': task['position']?.toString() ?? '0',
              'created_by': task['created_by']?.toString() ?? '',
              'creator_name': task['creator_name']?.toString() ?? 'Unknown',
              'created_at': task['created_at']?.toString() ?? '',
              'updated_at': task['updated_at']?.toString() ?? '',
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
  
  Future<void> _showTaskDialog({
    String? editTaskId,
    Map<String, dynamic>? existingTask,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => TaskDialog(
        taskId: editTaskId,
        existingTask: existingTask,
        boardMembers: _boardMembers,
        onSave: ({
          required String title,
          String? description,
          required String priority,
          required String status,
          DateTime? deadline,
          List<String>? assignees,
          List<String>? labels,
        }) async {
          if (editTaskId == null) {
            await _createTaskWithDetails(
              title: title,
              description: description,
              priority: priority,
              status: status,
              deadline: deadline,
              assignees: assignees,
              labels: labels,
            );
          } else {
            await _updateTaskWithDetails(
              taskId: editTaskId,
              title: title,
              description: description,
              priority: priority,
              status: status,
              deadline: deadline,
              assignees: assignees,
              labels: labels,
            );
          }
        },
      ),
    );
  }
  
  Future<void> _createTaskWithDetails({
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? deadline,
    List<String>? assignees,
    List<String>? labels,
  }) async {
    try {
      // Save to backend via API first
      final api = ref.read(apiServiceProvider);
      final response = await api.createTask(
        boardId: widget.boardId,
        title: title,
        description: description,
        assignees: assignees,
        status: status,
        priority: priority,
        deadline: deadline,
        parentId: null,
        labels: labels,
        estimatedHours: null,
      );
      
      final taskId = response['id'] as String;
      
      // Ensure all expected fields have values (handle nulls from server)
      final taskData = {
        'id': taskId,
        'title': response['title'] ?? title,
        'description': response['description'],
        'status': response['status'] ?? status,
        'priority': response['priority'] ?? priority,
        'assignees': response['assignees'] ?? [],
        'assignee_list': response['assignee_list'] ?? [],
        'deadline': response['deadline'],
        'labels': response['labels'] ?? [],
        'estimated_hours': response['estimated_hours'],
        'actual_hours': response['actual_hours'],
        'parent_id': response['parent_id'],
        'position': response['position'] ?? 0,
        'created_by': response['created_by'],
        'creator_name': response['creator_name'] ?? 'Unknown',
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      };
      
      // Then broadcast via P2P (without saving to backend again)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.createObject,
        {
          'id': taskId,
          'type': 'task',
          'data': taskData,
        },
        shouldSaveBackend: false, // Already saved via API
      );
      
      debugPrint('✅ Created task: $title (id: $taskId)');
    } catch (e) {
      debugPrint('❌ Error creating task: $e');
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }
  
  Future<void> _updateTaskWithDetails({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? deadline,
    List<String>? assignees,
    List<String>? labels,
  }) async {
    try {
      // Update via API
      final api = ref.read(apiServiceProvider);
      final response = await api.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        assignees: assignees,
        priority: priority,
        status: status,
        deadline: deadline,
        labels: labels,
      );
      
      // Ensure all expected fields have values (handle nulls from server)
      final taskData = {
        'id': taskId,
        'title': response['title'] ?? title,
        'description': response['description'],
        'status': response['status'] ?? status,
        'priority': response['priority'] ?? priority,
        'assignees': response['assignees'] ?? [],
        'assignee_list': response['assignee_list'] ?? [],
        'deadline': response['deadline'],
        'labels': response['labels'] ?? [],
        'estimated_hours': response['estimated_hours'],
        'actual_hours': response['actual_hours'],
        'parent_id': response['parent_id'],
        'position': response['position'] ?? 0,
        'created_by': response['created_by'],
        'creator_name': response['creator_name'] ?? 'Unknown',
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      };
      
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
      
      debugPrint('✅ Updated task: $taskId');
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }
  


  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    try {
      // Use moveTask API for better position handling
      final api = ref.read(apiServiceProvider);
      final response = await api.moveTask(
        taskId: taskId,
        status: newStatus,
      );
      
      // Ensure all expected fields have values (handle nulls from server)
      final taskData = {
        'id': taskId,
        'title': response['title'] ?? 'Untitled',
        'description': response['description'],
        'status': response['status'] ?? newStatus,
        'priority': response['priority'] ?? 'medium',
        'assignees': response['assignees'] ?? [],
        'assignee_list': response['assignee_list'] ?? [],
        'deadline': response['deadline'],
        'labels': response['labels'] ?? [],
        'estimated_hours': response['estimated_hours'],
        'actual_hours': response['actual_hours'],
        'parent_id': response['parent_id'],
        'position': response['position'] ?? 0,
        'created_by': response['created_by'],
        'creator_name': response['creator_name'] ?? 'Unknown',
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      };
      
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
      
      debugPrint('✅ Moved task: $taskId → $newStatus');
    } catch (e) {
      debugPrint('❌ Error moving task: $e');
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }
  
  Future<void> _editTask(String taskId, Map<String, dynamic> taskData) async {
    await _showTaskDialog(
      editTaskId: taskId,
      existingTask: taskData,
    );
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
              width: 360,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with create task button
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.task_alt, color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              'Task Board',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showTaskDialog(),
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text(
                              'Create New Task',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                          onMove: (id, data) => _updateTaskStatus(id, 'doing'),
                          onEdit: _editTask,
                          onDelete: _deleteTask,
                          color: Colors.orange,
                        ),
                        _TaskColumn(
                          title: 'DOING',
                          tasks: doingTasks,
                          onMove: (id, data) => _updateTaskStatus(id, 'done'),
                          onEdit: _editTask,
                          onDelete: _deleteTask,
                          color: Colors.blue,
                        ),
                        _TaskColumn(
                          title: 'DONE',
                          tasks: doneTasks,
                          onMove: null,
                          onEdit: _editTask,
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
  final Function(String, Map<String, dynamic>)? onMove;
  final Function(String, Map<String, dynamic>) onEdit;
  final Function(String) onDelete;
  final Color color;

  const _TaskColumn({
    required this.title,
    required this.tasks,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 220,
          maxWidth: 350,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color.withOpacity(0.9),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final taskId = task['id']?.toString() ?? '';
                  final title = task['title']?.toString() ?? 'Untitled';
                  final description = task['description']?.toString();
                  final priority = task['priority']?.toString() ?? 'medium';
                  final assigneeList = task['assignee_list'] as List<dynamic>?;
                  final deadline = task['deadline']?.toString();
                  
                  // Check if overdue
                  bool isOverdue = false;
                  if (deadline != null && deadline.isNotEmpty) {
                    try {
                      final deadlineDate = DateTime.parse(deadline);
                      isOverdue = deadlineDate.isBefore(DateTime.now()) && 
                          task['status']?.toString() != 'done';
                    } catch (e) {
                      // Invalid date
                    }
                  }
                  
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
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: priorityColor.withOpacity(0.3), width: 1),
                    ),
                    child: InkWell(
                      onTap: () => onEdit(taskId, task),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title row with priority
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(priorityIcon, size: 14, color: priorityColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Description
                            if (description != null && description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            
                            // Metadata section
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Assignees
                                if (assigneeList != null && assigneeList.isNotEmpty) ...[
                                  Flexible(
                                    child: Wrap(
                                      spacing: 3,
                                      runSpacing: 3,
                                      children: [
                                        ...assigneeList.take(2).map((assignee) {
                                          final name = assignee['name'] as String? ?? '?';
                                          return Tooltip(
                                            message: name,
                                            child: CircleAvatar(
                                              radius: 11,
                                              backgroundColor: Colors.blue[600],
                                              child: Text(
                                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        if (assigneeList.length > 2)
                                          Tooltip(
                                            message: '${assigneeList.length - 2} more',
                                            child: CircleAvatar(
                                              radius: 11,
                                              backgroundColor: Colors.grey[500],
                                              child: Text(
                                                '+${assigneeList.length - 2}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                
                                // Deadline
                                if (deadline != null)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isOverdue ? Colors.red[50] : Colors.blue[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isOverdue ? Colors.red[300]! : Colors.blue[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 10,
                                            color: isOverdue ? Colors.red[700] : Colors.blue[700],
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            deadline.substring(5, 10),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isOverdue ? Colors.red[700] : Colors.blue[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            // Action buttons
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (onMove != null) ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => onMove!(taskId, task),
                                      icon: const Icon(Icons.arrow_forward, size: 13),
                                      label: const Text('Move', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  iconSize: 18,
                                  onPressed: () => onEdit(taskId, task),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                  tooltip: 'Edit',
                                  color: Colors.blue[700],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  iconSize: 18,
                                  onPressed: () => onDelete(taskId),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                  tooltip: 'Delete',
                                  color: Colors.red[500],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
