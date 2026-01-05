import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../providers/app_providers.dart';
import '../../models/operation/operation.dart';
import '../../models/task_model.dart';
import '../../utils/error_display.dart';
import '../widgets/task_dialog.dart';
import '../theme/app_colors.dart';

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
  // Screenshot controller
  final ScreenshotController _screenshotController = ScreenshotController();

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
  double _kanbanWidth = 350.0; // Resizable width
  List<Map<String, dynamic>> _boardMembers = [];
  String? _currentBoardId;

  // Voice call state
  bool _isVoiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentBoardId = widget.boardId;
    _initBoard();
  }

  @override
  void didUpdateWidget(BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If board ID changed, disconnect from old board and connect to new one
    if (oldWidget.boardId != widget.boardId) {
      debugPrint('🔄 Board changed: ${oldWidget.boardId} -> ${widget.boardId}');
      ref.read(whiteboardProvider.notifier).disconnect();
      _currentBoardId = widget.boardId;
      _boardMembers = [];
      _initBoard();
    }
  }

  @override
  void dispose() {
    // Disconnect from P2P when leaving board
    debugPrint('🚪 Leaving board: $_currentBoardId');
    _taskController.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// Capture screenshot of current board
  Future<void> _captureScreenshot() async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Failed to capture screenshot')),
          );
        }
        return;
      }

      if (kIsWeb) {
        // For web, just show the image in a dialog or let user download via anchor
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Screenshot'),
            content: Image.memory(image),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
      }

      // Get directory to save
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Windows/Desktop
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Failed to get save directory')),
          );
        }
        return;
      }

      // Create filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'board_${widget.boardId}_$timestamp.png';
      final filePath = '${directory.path}/$fileName';

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(image);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 Screenshot saved!\n$filePath'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                if (!kIsWeb && Platform.isWindows) {
                  Process.run('explorer.exe', ['/select,', filePath]);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  Future<void> _initBoard() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    debugPrint('🎯 Initializing board: ${widget.boardId}');

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

      // Map board members to use consistent field names (id, name, email)
      final mappedMembers = members.map((member) {
        return {
          'id': member['user_id'] ?? member['id'],
          'name': member['name'],
          'email': member['email'],
          'permission': member['permission'],
          'is_board_owner': member['is_board_owner'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _boardMembers = mappedMembers;
        });
      }
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
        // Create operation with full task data from database
        final operation = Operation(
          opId: task['id'] ?? 'task-${DateTime.now().millisecondsSinceEpoch}',
          actor: task['created_by'] ?? 'backend',
          timestamp: task['created_at'] != null
              ? DateTime.parse(
                  task['created_at'] as String,
                ).millisecondsSinceEpoch
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
              'assignees': task['assignees'] ?? [],
              'assignee_list': task['assignee_list'] ?? [],
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
    if (mounted) {
      setState(() {
        _activeStrokes[_currentStrokeId!] = _ActiveStroke(
        points: [point],
        color: strokeColor,
        width: strokeWidth,
        userName: displayName,
        isEraser: isEraser,
      );
      });
    }

    // Create initial stroke - SAVE to backend
    notifier.createOperation(OperationType.createObject, {
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
    }, shouldSaveBackend: true);

    debugPrint(
      '🖊️ Start ${isEraser ? "eraser" : "stroke"}: $_currentStrokeId by $displayName',
    );
  }

  void _onPanUpdate(Offset point) {
    if (_currentStrokeId == null || _selectedTool == DrawingTool.text) return;

    if (mounted) {
      setState(() {
        _currentPoints.add(point);
        _activeStrokes[_currentStrokeId!]?.points.add(point);
      });
    }

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
    notifier.createOperation(OperationType.updateObject, {
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
    }, shouldSaveBackend: true);

    // Add to undo stack
    _undoStack.add(_currentStrokeId!);

    debugPrint(
      '✅ Finish ${isEraser ? "eraser" : "stroke"}: $_currentStrokeId (${_currentPoints.length} points)',
    );

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

    notifier.createOperation(OperationType.deleteObject, {
      'id': strokeId,
      'type': 'stroke',
    }, shouldSaveBackend: true);

    debugPrint('↩️ Undo stroke: $strokeId');
  }

  // ===== TEXT TOOL =====

  void _onCanvasTap(Offset position) {
    if (_selectedTool != DrawingTool.text) return;

    if (mounted) {
      setState(() {
        _textPosition = position;
      });
    }

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

    notifier.createOperation(OperationType.createObject, {
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
    }, shouldSaveBackend: true);

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
    // Convert Map to TaskModel if editing
    TaskModel? taskModel;
    if (existingTask != null) {
      try {
        taskModel = TaskModel(
          id: existingTask['id'] as String,
          boardId: widget.boardId,
          title: existingTask['title'] as String? ?? 'Untitled',
          description: existingTask['description'] as String?,
          status: existingTask['status'] as String? ?? 'todo',
          priority: existingTask['priority'] as String? ?? 'medium',
          assignees: (existingTask['assignees'] as List?)?.cast<String>() ?? [],
          assigneeList:
              (existingTask['assignee_list'] as List?)
                  ?.map(
                    (a) => AssigneeInfo(
                      id: a['id'] as String,
                      name: a['name'] as String? ?? '',
                      email: a['email'] as String?,
                      avatar: null,
                    ),
                  )
                  .toList() ??
              [],
          labels: (existingTask['labels'] as List?)?.cast<String>() ?? [],
          deadline: existingTask['deadline'] != null
              ? DateTime.tryParse(existingTask['deadline'] as String)
              : null,
          estimatedHours: existingTask['estimated_hours'] != null
              ? double.tryParse(existingTask['estimated_hours'].toString())
              : null,
          actualHours: existingTask['actual_hours'] != null
              ? double.tryParse(existingTask['actual_hours'].toString())
              : null,
          parentId: existingTask['parent_id'] as String?,
          position: existingTask['position'] as int? ?? 0,
          createdBy: existingTask['created_by'] as String? ?? '',
          creatorName: existingTask['creator_name'] as String?,
          createdAt:
              DateTime.tryParse(existingTask['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(existingTask['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
      } catch (e) {
        debugPrint('Error converting task: $e');
      }
    }

    await showDialog(
      context: context,
      builder: (context) => TaskDialog(
        existingTask: taskModel,
        boardMembers: _boardMembers,
        onSave:
            ({
              required String title,
              String? description,
              required String priority,
              required String status,
              DateTime? deadline,
              List<String>? assignees,
              List<String>? labels,
              double? estimatedHours,
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
                  estimatedHours: estimatedHours,
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
                  estimatedHours: estimatedHours,
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
    double? estimatedHours,
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
        estimatedHours: estimatedHours,
      );

      final taskId = response['id'] as String;

      // Then broadcast via P2P (without saving to backend again)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.createObject,
        {'id': taskId, 'type': 'task', 'data': response},
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
    double? estimatedHours,
  }) async {
    try {
      // Update via API
      final api = ref.read(apiServiceProvider);
      debugPrint('📤 Updating task $taskId via API...');
      final response = await api.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        assignees: assignees,
        priority: priority,
        status: status,
        deadline: deadline,
        labels: labels,
        estimatedHours: estimatedHours,
      );

      debugPrint('📥 Received update response: ${response.keys}');

      // Broadcast P2P (without backend save)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.updateObject,
        {'id': taskId, 'type': 'task', 'data': response},
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
        boardId: widget.boardId,
      );

      // Broadcast P2P (without backend save)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.updateObject,
        {'id': taskId, 'type': 'task', 'data': response},
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
    await _showTaskDialog(editTaskId: taskId, existingTask: taskData);
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      // Delete via API
      final api = ref.read(apiServiceProvider);
      debugPrint('🗑️ Deleting task $taskId via API...');
      await api.deleteTask(taskId);

      // Broadcast P2P (without backend save)
      final notifier = ref.read(whiteboardProvider.notifier);
      notifier.createOperation(
        OperationType.deleteObject,
        {'id': taskId, 'type': 'task'},
        shouldSaveBackend: false, // Already deleted via API
      );

      debugPrint('✅ Deleted task: $taskId');
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
      if (mounted) {
        context.showErrorSnackBar(e);
      }
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
              points.add(
                Offset(
                  (pointsList[i] as num).toDouble(),
                  (pointsList[i + 1] as num).toDouble(),
                ),
              );
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
        strokes.add({'id': id, ...data});
      } else if (type == 'text') {
        texts.removeWhere((t) => t['id'] == id);
        texts.add({
          'id': id,
          ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
        });
      } else if (type == 'task') {
        // Handle both create and update for tasks
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Try to pop first (simplest way to go back to boards list)
            if (context.canPop()) {
              context.pop();
            } else {
              // Try to navigate to boards list
              final boardAsync = ref.read(currentBoardProvider);
              final board = boardAsync.value;
              
              if (board != null) {
                context.go('/workspace/${board.workspaceId}/boards');
              } else {
                // Last fallback - go to workspaces
                context.go('/workspaces');
              }
            }
          },
          tooltip: 'Back to boards',
        ),
        title: const Text('Canvas + Kanban'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _showKanban ? Icons.view_sidebar : Icons.view_sidebar_outlined,
            ),
            onPressed: () => setState(() => _showKanban = !_showKanban),
            tooltip: 'Toggle Kanban',
          ),
          Tooltip(
            message: 'Capture Screenshot',
            child: IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _captureScreenshot,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_rounded),
            onPressed: () {
              // Capture state here before showDialog
              final peers = state.peers;
              final strokeCount = strokes.length;
              final textCount = texts.length;
              final taskCount = tasks.length;
              
              showDialog(
                context: context,
                builder: (dialogContext) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 400,
                    constraints: const BoxConstraints(maxHeight: 600),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.people_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'P2P Status & Active Users',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      '${peers.length + 1} online',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stats section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Statistics',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _StatRow(
                                        icon: Icons.brush_rounded,
                                        label: 'Strokes',
                                        value: '$strokeCount',
                                      ),
                                      const SizedBox(height: 8),
                                      _StatRow(
                                        icon: Icons.text_fields_rounded,
                                        label: 'Texts',
                                        value: '$textCount',
                                      ),
                                      const SizedBox(height: 8),
                                      _StatRow(
                                        icon: Icons.task_rounded,
                                        label: 'Tasks',
                                        value: '$taskCount',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Active Users section
                                Text(
                                  'Active Users',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Current user (You)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final currentUser = ref.watch(authStateProvider).user;
                                    return _UserItem(
                                      name: currentUser?.name ?? currentUser?.email ?? 'You',
                                      isCurrentUser: true,
                                      isConnected: true,
                                      avatar: currentUser?.avatar,
                                      isMuted: false,
                                      isVoiceEnabled: _isVoiceEnabled,
                                    );
                                  },
                                ),
                                if (peers.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...peers.map((peer) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _UserItem(
                                        name: peer.userName ?? peer.userId,
                                        isCurrentUser: false,
                                        isConnected: peer.connected,
                                        avatar: peer.avatar,
                                        isMuted: peer.isMuted,
                                        isVoiceEnabled: _isVoiceEnabled,
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // Voice call controls
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: _isVoiceEnabled
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.error,
                                            AppColors.error.withOpacity(0.8),
                                          ],
                                        )
                                      : AppColors.gradientPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isVoiceEnabled
                                              ? AppColors.error
                                              : AppColors.primary)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _toggleVoice();
                                  },
                                  icon: Icon(
                                    _isVoiceEnabled
                                        ? Icons.mic_rounded
                                        : Icons.mic_off_rounded,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _isVoiceEnabled ? 'End Voice Call' : 'Start Voice Call',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              if (_isVoiceEnabled) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.success.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.graphic_eq_rounded,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Voice call active',
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )); 
            },
            tooltip: 'P2P Status & Active Users',
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            Row(
              children: [
              // Canvas area
              Expanded(
                child: Column(
                  children: [
                    // Color picker and tools
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          bottom: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Show current user
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ref
                                                .watch(authStateProvider)
                                                .user
                                                ?.name
                                                ?.isNotEmpty ==
                                            true
                                        ? ref
                                              .watch(authStateProvider)
                                              .user!
                                              .name!
                                        : ref
                                                  .watch(authStateProvider)
                                                  .user
                                                  ?.email ??
                                              'You',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Drawing tools
                            _ToolButton(
                              icon: Icons.edit_rounded,
                              label: 'Pen',
                              isSelected: _selectedTool == DrawingTool.pen,
                              onTap: () => setState(
                                () => _selectedTool = DrawingTool.pen,
                              ),
                            ),
                            _ToolButton(
                              icon: Icons.auto_fix_high_rounded,
                              label: 'Eraser',
                              isSelected: _selectedTool == DrawingTool.eraser,
                              onTap: () => setState(
                                () => _selectedTool = DrawingTool.eraser,
                              ),
                            ),
                            _ToolButton(
                              icon: Icons.text_fields_rounded,
                              label: 'Text',
                              isSelected: _selectedTool == DrawingTool.text,
                              onTap: () => setState(
                                () => _selectedTool = DrawingTool.text,
                              ),
                            ),

                            const VerticalDivider(),

                            // Undo button
                            IconButton(
                              icon: const Icon(Icons.undo_rounded),
                              onPressed: _undoStack.isEmpty ? null : _undo,
                              tooltip: 'Undo (${_undoStack.length})',
                            ),

                            const VerticalDivider(),
                            const Text('Color: '),
                            const SizedBox(width: 8),
                            ...[
                              'black',
                              'red',
                              'blue',
                              'green',
                              'yellow',
                              'orange',
                              'purple',
                            ].map((colorName) {
                              final color = _getColor(colorName);
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = color),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedColor == color
                                          ? Colors.black
                                          : Colors.grey,
                                      width: _selectedColor == color ? 3 : 1,
                                    ),
                                  ),
                                ),
                              );
                            }),
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
                                onChanged: (value) =>
                                    setState(() => _strokeWidth = value),
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
                                  onChanged: (value) =>
                                      setState(() => _textSize = value),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Canvas
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 0.1,
                        maxScale: 5.0,
                        constrained: false,
                        child: GestureDetector(
                          onTapUp: (details) =>
                              _onCanvasTap(details.localPosition),
                          onPanStart: (details) =>
                              _onPanStart(details.localPosition),
                          onPanUpdate: (details) =>
                              _onPanUpdate(details.localPosition),
                          onPanEnd: (details) => _onPanEnd(),
                          child: Container(
                            width: 2000,
                            height: 2000,
                            color: Colors.white,
                            child: CustomPaint(
                              painter: _StrokePainter(
                                strokes: strokes,
                                texts: texts,
                                activeStrokes: {
                                  ..._activeStrokes,
                                  ...peerActiveStrokes,
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Kanban sidebar (resizable)
              if (_showKanban)
                Row(
                  children: [
                    // Resize handle
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _kanbanWidth = (_kanbanWidth - details.delta.dx).clamp(250.0, 600.0);
                          });
                        },
                        child: Container(
                          width: 8,
                          color: Colors.grey[300],
                          child: Center(
                            child: Container(
                              width: 2,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Kanban panel
                    Container(
                      width: _kanbanWidth,
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
                      // Create task button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showTaskDialog(),
                            icon: const Icon(
                              Icons.add_circle_rounded,
                              size: 20,
                            ),
                            label: const Text('Create Task'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Task columns - responsive layout
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Use single column for narrow screens (mobile)
                            if (constraints.maxWidth < 800) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: constraints.maxWidth * 0.9,
                                      child: _TaskColumn(
                                        title: 'TODO',
                                        tasks: todoTasks,
                                        onMove: (id, data) =>
                                            _updateTaskStatus(id, 'doing'),
                                        onEdit: _editTask,
                                        onDelete: _deleteTask,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth * 0.9,
                                      child: _TaskColumn(
                                        title: 'DOING',
                                        tasks: doingTasks,
                                        onMove: (id, data) =>
                                            _updateTaskStatus(id, 'done'),
                                        onEdit: _editTask,
                                        onDelete: _deleteTask,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth * 0.9,
                                      child: _TaskColumn(
                                        title: 'DONE',
                                        tasks: doneTasks,
                                        onMove: null,
                                        onEdit: _editTask,
                                        onDelete: _deleteTask,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Desktop - show all columns side by side
                            return Row(
                              children: [
                                Expanded(
                                  child: _TaskColumn(
                                    title: 'TODO',
                                    tasks: todoTasks,
                                    onMove: (id, data) =>
                                        _updateTaskStatus(id, 'doing'),
                                    onEdit: _editTask,
                                    onDelete: _deleteTask,
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _TaskColumn(
                                    title: 'DOING',
                                    tasks: doingTasks,
                                    onMove: (id, data) =>
                                        _updateTaskStatus(id, 'done'),
                                    onEdit: _editTask,
                                    onDelete: _deleteTask,
                                    color: Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: _TaskColumn(
                                    title: 'DONE',
                                    tasks: doneTasks,
                                    onMove: null,
                                    onEdit: _editTask,
                                    onDelete: _deleteTask,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _toggleVoice() {
    if (!mounted) return;
    setState(() {
      _isVoiceEnabled = !_isVoiceEnabled;
    });

    if (_isVoiceEnabled) {
      _startVoiceCall();
    } else {
      _stopVoiceCall();
    }
  }

  Future<void> _startVoiceCall() async {
    debugPrint('🎤 Starting voice call...');

    try {
      // Check microphone permission first
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          if (mounted) {
            _showSnackBar('❌ Microphone permission denied', isError: true);
            setState(() {
              _isVoiceEnabled = false;
            });
          }
          return;
        }
      }

      // Check if we have webrtc service
      final webrtc = ref.read(whiteboardProvider.notifier).webrtc;

      if (webrtc == null) {
        if (mounted) {
          _showSnackBar('❌ WebRTC service not available', isError: true);
          setState(() {
            _isVoiceEnabled = false;
          });
        }
        return;
      }

      // Request microphone permission and start audio stream
      final success = await webrtc.startAudioStream();

      if (!success) {
        if (mounted) {
          _showSnackBar('❌ Failed to access microphone', isError: true);
          setState(() {
            _isVoiceEnabled = false;
          });
        }
        return;
      }

      if (mounted) {
        _showSnackBar('🎤 Voice call started', isError: false);
      }
      debugPrint('✅ Voice call started successfully');
    } catch (e) {
      debugPrint('❌ Error starting voice call: $e');
      if (mounted) {
        _showSnackBar('❌ Failed to start voice call: $e', isError: true);
        setState(() {
          _isVoiceEnabled = false;
        });
      }
    }
  }

  void _stopVoiceCall() {
    debugPrint('🔇 Stopping voice call...');

    try {
      // Get webrtc service
      final webrtc = ref.read(whiteboardProvider.notifier).webrtc;

      if (webrtc != null) {
        webrtc.stopAudioStream();
        _showSnackBar('🔇 Voice call ended', isError: false);
        debugPrint('✅ Voice call stopped successfully');
      }
    } catch (e) {
      debugPrint('❌ Error stopping voice call: $e');
      _showSnackBar('❌ Failed to stop voice call: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getColor(String name) {
    switch (name) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.black;
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
        points.add(
          Offset(
            (pointsList[i] as num).toDouble(),
            (pointsList[i + 1] as num).toDouble(),
          ),
        );
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
      final labelOffset = Offset(lastPoint.dx + 10, lastPoint.dy - 10);
      textPainter.paint(canvas, labelOffset);
    }

    // Draw text objects
    for (final textObj in texts) {
      final text = textObj['text'] as String?;
      final positionList = textObj['position'] as List?;
      if (text == null || positionList == null || positionList.length < 2)
        continue;

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No tasks',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ),
                  )
                : Scrollbar(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final taskId = task['id'] as String;
                        final title = task['title'] as String? ?? 'Untitled';
                        final description = task['description'] as String?;
                        final priority =
                            task['priority'] as String? ?? 'medium';
                        final assigneeList =
                            task['assignee_list'] as List<dynamic>?;
                        final deadline = task['deadline'] as String?;

                        // Check if overdue
                        bool isOverdue = false;
                        if (deadline != null) {
                          try {
                            final deadlineDate = DateTime.parse(deadline);
                            isOverdue =
                                deadlineDate.isBefore(DateTime.now()) &&
                                task['status'] != 'done';
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onEdit(taskId, task),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 120,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Title row with priority
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          priorityIcon,
                                          size: 14,
                                          color: priorityColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Description
                                    if (description != null &&
                                        description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],

                                    // Metadata section
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Assignees row
                                        if (assigneeList != null &&
                                            assigneeList.isNotEmpty) ...[
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              ...assigneeList.take(3).map((
                                                assignee,
                                              ) {
                                                final name =
                                                    assignee['name']
                                                        as String? ??
                                                    '?';
                                                return CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: Colors.blue,
                                                  child: Text(
                                                    name.isNotEmpty
                                                        ? name
                                                              .substring(0, 1)
                                                              .toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              }),
                                              if (assigneeList.length > 3)
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor:
                                                      Colors.grey[400],
                                                  child: Text(
                                                    '+${assigneeList.length - 3}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],

                                        // Deadline badge
                                        if (deadline != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOverdue
                                                  ? Colors.red[50]
                                                  : Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isOverdue
                                                    ? Colors.red[300]!
                                                    : Colors.blue[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 12,
                                                  color: isOverdue
                                                      ? Colors.red[700]
                                                      : Colors.blue[700],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  deadline.substring(
                                                    5,
                                                    10,
                                                  ), // MM-DD
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isOverdue
                                                        ? Colors.red[700]
                                                        : Colors.blue[700],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // Action buttons
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        // Edit button
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                onEdit(taskId, task),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 14,
                                            ),
                                            label: const Text(
                                              'Edit',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              side: BorderSide(
                                                color: Colors.blue[300]!,
                                              ),
                                              foregroundColor: Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () => onDelete(taskId),
                                          padding: const EdgeInsets.all(6),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          tooltip: 'Delete',
                                          color: Colors.red[400],
                                          style: IconButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.red[300]!,
                                            ),
                                          ),
                                        ),
                                        if (onMove != null) ...[
                                          const SizedBox(width: 6),
                                          // Move button
                                          IconButton(
                                            icon: const Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                onMove!(taskId, task),
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            tooltip: 'Move',
                                            color: Colors.green[600],
                                            style: IconButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.green[300]!,
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
                        ));
                      },
                    ),
                  ),
          ),
        ],
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== STAT ROW WIDGET =====

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ===== USER ITEM WIDGET =====

class _UserItem extends StatelessWidget {
  final String name;
  final bool isCurrentUser;
  final bool isConnected;
  final String? avatar;
  final bool isMuted;
  final bool isVoiceEnabled;

  const _UserItem({
    required this.name,
    required this.isCurrentUser,
    required this.isConnected,
    this.avatar,
    this.isMuted = false,
    this.isVoiceEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCurrentUser
                      ? AppColors.gradientPrimary
                      : LinearGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.secondary.withOpacity(0.7),
                          ],
                        ),
                ),
                child: avatar != null && avatar!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              // Online status indicator
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isConnected ? AppColors.success : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrentUser)
                  const Text(
                    '(You)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Mic status (only show when voice is enabled)
          if (isVoiceEnabled) ...[
            Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              size: 18,
              color: isMuted ? AppColors.error : AppColors.success,
            ),
            const SizedBox(width: 8),
          ],

          // Status
          Icon(
            isConnected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isConnected ? AppColors.success : Colors.grey,
          ),
        ],
      ),
    );
  }
}
