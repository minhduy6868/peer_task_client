import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/operation/operation.dart';
import '../dialogs/board_settings_dialog.dart';

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
  String _drawMode = 'draw'; // 'draw', 'text', 'pan', 'rectangle', 'circle', 'line'
  bool _showKanban = true; // Toggle Kanban sidebar
  List<Map<String, dynamic>> _boardMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _showMemberDropdown = false;
  String? _currentStrokeId; // Track current stroke being drawn
  double _fontSize = 16.0;
  String? _selectedObjectId; // Track selected object for deletion
  Offset? _shapeStartPoint; // Starting point for drawing shapes
  DateTime? _lastDrawUpdate; // Throttle drawing updates
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    
    // Listen to assignee input changes for member filtering
    _assigneeController.addListener(_filterMembers);
  }

  Future<void> _initializeBoard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      
      ref.read(whiteboardProvider.notifier).connectToBoard(widget.boardId);
      await _loadBoardMembers();
      await _loadTasksFromBackend();
      await _loadOperationsFromBackend();
      
      // Wait a bit for WebRTC connections
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading board: $e';
        });
      }
    }
  }

  Future<void> _loadTasksFromBackend() async {
    try {
      final api = ref.read(apiServiceProvider);
      final tasks = await api.getBoardTasks(widget.boardId);
      
      // Convert backend tasks to operations
      final notifier = ref.read(whiteboardProvider.notifier);
      for (final task in tasks) {
        notifier.createOperation(
          OperationType.createObject,
          {
            'id': task['id'],
            'type': 'task',
            'data': {
              'title': task['title'],
              'assignee': task['assignee'],
              'status': task['status'],
              'timestamp': task['created_at'] != null
                  ? DateTime.parse(task['created_at']).millisecondsSinceEpoch
                  : DateTime.now().millisecondsSinceEpoch,
            },
            'zIndex': 0,
            'version': 0,
            'createdBy': task['created_by'] ?? 'unknown',
            'createdAt': task['created_at'] != null
                ? DateTime.parse(task['created_at']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            'updatedAt': task['updated_at'] != null
                ? DateTime.parse(task['updated_at']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _loadBoardMembers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final members = await api.getBoardMembers(widget.boardId);
      
      if (mounted) {
        setState(() {
          _boardMembers = members.cast<Map<String, dynamic>>();
          _filteredMembers = _boardMembers;
        });
        debugPrint('Loaded ${members.length} board members');
      }
    } catch (e) {
      debugPrint('Error loading board members: $e');
    }
  }

  void _filterMembers() {
    final query = _assigneeController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _boardMembers;
        _showMemberDropdown = false;
      } else {
        _filteredMembers = _boardMembers
            .where((member) =>
                (member['name'] as String? ?? '').toLowerCase().contains(query) ||
                (member['email'] as String? ?? '').toLowerCase().contains(query))
            .toList();
        _showMemberDropdown = _filteredMembers.isNotEmpty;
      }
    });
  }

  Future<void> _loadOperationsFromBackend() async {
    try {
      final api = ref.read(apiServiceProvider);
      final operations = await api.getBoardOperations(widget.boardId);
      
      debugPrint('📦 Loaded ${operations.length} operations from backend');
      
      for (final opData in operations) {
        try {
          // Validate required fields before parsing
          if (opData['opId'] == null || opData['opId'].toString().isEmpty) {
            debugPrint('⚠️ Skipping operation without opId: $opData');
            continue;
          }
          
          if (opData['actor'] == null || opData['actor'].toString().isEmpty) {
            debugPrint('⚠️ Skipping operation without actor: ${opData['opId']}');
            continue;
          }
          
          if (opData['type'] == null) {
            debugPrint('⚠️ Skipping operation without type: ${opData['opId']}');
            continue;
          }
          
          final operation = Operation.fromJson(opData);
          
          // Validate operation payload has required fields
          if (operation.payload['id'] == null) {
            debugPrint('⚠️ Skipping operation without payload.id: ${operation.opId}');
            continue;
          }
          
          // For canvas operations, ensure 'type' field exists
          final opType = operation.payload['type'];
          if (opType == null || opType.toString().isEmpty) {
            debugPrint('⚠️ Skipping operation without payload.type: ${operation.opId}');
            continue;
          }
          
          // Use receiveOperation to avoid duplicate saves
          ref.read(whiteboardProvider.notifier).receiveOperation(operation);
        } catch (e) {
          debugPrint('❌ Error parsing operation: $e');
          debugPrint('   Data: $opData');
        }
      }
      
      debugPrint('✅ Operations loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading operations: $e');
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    _assigneeController.removeListener(_filterMembers);
    _assigneeController.dispose();
    super.dispose();
  }

  void _addTask() async {
    if (!mounted || _taskController.text.trim().isEmpty) return;

    final authState = ref.read(authStateProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    final taskId = 'task-$now';

    // Save to backend first
    try {
      final api = ref.read(apiServiceProvider);
      await api.createTask(
        boardId: widget.boardId,
        title: _taskController.text.trim(),
        assignee: _assigneeController.text.trim().isEmpty 
          ? null 
          : _assigneeController.text.trim(),
        status: 'todo',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
      return;
    }

    // Create P2P operation
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

  void _updateTaskStatus(String taskId, String newStatus) async {
    if (!mounted) return;
    
    // Update backend first
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateTask(
        taskId: taskId,
        status: newStatus,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
      return;
    }
    
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

  void _deleteTask(String taskId) async {
    if (!mounted) return;
    
    // Delete from backend first
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteTask(taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting task: $e')),
        );
      }
      return;
    }
    
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.deleteObject,
      {'id': taskId},
    );
  }

  void _addTextAtPosition(Offset position) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onSubmitted: (_) => Navigator.pop(context, textController.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || !mounted) return;

    final authState = ref.read(authStateProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    final textId = 'text-$now-${DateTime.now().microsecond}';

    notifier.createOperation(
      OperationType.createObject,
      {
        'id': textId,
        'type': 'text',
        'data': {
          'text': result,
          'x': position.dx,
          'y': position.dy,
          'color': _selectedColor.value,
          'fontSize': _fontSize,
        },
        'zIndex': 1,
        'version': 0,
        'createdBy': authState.user?.id ?? 'unknown',
        'createdAt': now,
        'updatedAt': now,
      },
    );
  }

  void _startShape(Offset point) {
    if (!['rectangle', 'circle', 'line'].contains(_drawMode)) return;
    setState(() => _shapeStartPoint = point);
  }

  void _finishShape(Offset endPoint) {
    if (_shapeStartPoint == null) return;

    final authState = ref.read(authStateProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    final shapeId = '$_drawMode-$now-${DateTime.now().microsecond}';

    notifier.createOperation(
      OperationType.createObject,
      {
        'id': shapeId,
        'type': _drawMode,
        'data': {
          'x1': _shapeStartPoint!.dx,
          'y1': _shapeStartPoint!.dy,
          'x2': endPoint.dx,
          'y2': endPoint.dy,
          'color': _selectedColor.value,
          'strokeWidth': _strokeWidth,
        },
        'zIndex': 1,
        'version': 0,
        'createdBy': authState.user?.id ?? 'unknown',
        'createdAt': now,
        'updatedAt': now,
      },
    );

    setState(() => _shapeStartPoint = null);
  }

  void _selectObject(Offset position, List<Map<String, dynamic>> allObjects) {
    // Find object at position
    for (final obj in allObjects.reversed) {
      if (_isPointInObject(position, obj)) {
        setState(() => _selectedObjectId = obj['id'] as String);
        return;
      }
    }
    setState(() => _selectedObjectId = null);
  }

  bool _isPointInObject(Offset point, Map<String, dynamic> obj) {
    final type = obj['type'] as String?;
    if (type == 'text') {
      final x = (obj['x'] as num?)?.toDouble() ?? 0;
      final y = (obj['y'] as num?)?.toDouble() ?? 0;
      // Simple hit test: 100x50 box
      return point.dx >= x && point.dx <= x + 100 && 
             point.dy >= y && point.dy <= y + 50;
    } else if (type == 'rectangle' || type == 'circle' || type == 'line') {
      final x1 = (obj['x1'] as num?)?.toDouble() ?? 0;
      final y1 = (obj['y1'] as num?)?.toDouble() ?? 0;
      final x2 = (obj['x2'] as num?)?.toDouble() ?? 0;
      final y2 = (obj['y2'] as num?)?.toDouble() ?? 0;
      final minX = x1 < x2 ? x1 : x2;
      final maxX = x1 > x2 ? x1 : x2;
      final minY = y1 < y2 ? y1 : y2;
      final maxY = y1 > y2 ? y1 : y2;
      return point.dx >= minX && point.dx <= maxX && 
             point.dy >= minY && point.dy <= maxY;
    }
    return false;
  }

  void _deleteSelectedObject() {
    if (_selectedObjectId == null) return;
    
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.deleteObject,
      {'id': _selectedObjectId!},
    );
    
    setState(() => _selectedObjectId = null);
  }

  void _startDrawing(Offset point) {
    if (_drawMode != 'draw') return;
    
    final authState = ref.read(authStateProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    final strokeId = 'stroke-$now-${DateTime.now().microsecond}';
    
    _currentStrokeId = strokeId;

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

  void _continueDrawing(Offset point) {
    if (!mounted || _currentStrokeId == null) return;

    // Throttle updates to 50ms to reduce operations
    final now = DateTime.now();
    if (_lastDrawUpdate != null && now.difference(_lastDrawUpdate!).inMilliseconds < 50) {
      return;
    }
    _lastDrawUpdate = now;

    final state = ref.read(whiteboardProvider);
    final notifier = ref.read(whiteboardProvider.notifier);
    final timestamp = now.millisecondsSinceEpoch;

    // Find the current stroke being drawn
    Operation? existing;
    try {
      existing = state.operations.firstWhere(
        (op) => op.payload['id'] == _currentStrokeId && op.type == OperationType.createObject,
      );
    } catch (e) {
      return;
    }

    final existingData = Map<String, dynamic>.from(existing.payload['data'] ?? {});
    final points = List<double>.from(existingData['points'] ?? []);
    points.addAll([point.dx, point.dy]);

    notifier.createOperation(
      OperationType.updateObject,
      {
        'id': _currentStrokeId,
        'type': 'stroke',
        'data': {
          ...existingData,
          'points': points,
        },
        'zIndex': existing.payload['zIndex'] ?? 0,
        'version': (existing.payload['version'] ?? 0) + 1,
        'createdBy': existing.payload['createdBy'] ?? 'unknown',
        'createdAt': existing.payload['createdAt'] ?? timestamp,
        'updatedAt': timestamp,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(whiteboardProvider);
    
    // Extract tasks, strokes, texts, and shapes from operations with proper update merging
    final Map<String, Map<String, dynamic>> tasks = {};
    final Map<String, Map<String, dynamic>> strokesMap = {};
    final Map<String, Map<String, dynamic>> textsMap = {};
    final Map<String, Map<String, dynamic>> shapesMap = {};

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
          strokesMap[id] = {
            'id': id,
            ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
          };
        } else if (type == 'text') {
          textsMap[id] = {
            'id': id,
            ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
          };
        } else if (['rectangle', 'circle', 'line'].contains(type)) {
          shapesMap[id] = {
            'id': id,
            'type': type,
            ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
          };
        }
      } else if (op.type == OperationType.updateObject) {
        // Merge update data with existing object
        if (tasks.containsKey(id)) {
          tasks[id]!.addAll(Map<String, dynamic>.from(op.payload['data'] ?? {}));
        } else if (strokesMap.containsKey(id)) {
          strokesMap[id]!.addAll(Map<String, dynamic>.from(op.payload['data'] ?? {}));
        } else if (textsMap.containsKey(id)) {
          textsMap[id]!.addAll(Map<String, dynamic>.from(op.payload['data'] ?? {}));
        } else if (shapesMap.containsKey(id)) {
          shapesMap[id]!.addAll(Map<String, dynamic>.from(op.payload['data'] ?? {}));
        }
      } else if (op.type == OperationType.deleteObject) {
        tasks.remove(id);
        strokesMap.remove(id);
        textsMap.remove(id);
        shapesMap.remove(id);
      }
    }
    
    final strokes = strokesMap.values.toList();
    final texts = textsMap.values.toList();
    final shapes = shapesMap.values.toList();
    final allObjects = [...texts, ...shapes]; // For selection

    final todoTasks = tasks.entries.where((e) => e.value['status'] == 'todo').toList();
    final doingTasks = tasks.entries.where((e) => e.value['status'] == 'doing').toList();
    final doneTasks = tasks.entries.where((e) => e.value['status'] == 'done').toList();

    // Show loading screen
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('🎨 Hybrid Board'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading board...', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('Connecting to peers...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

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
          // Board settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => BoardSettingsDialog(
                  boardId: widget.boardId,
                  boardName: 'Board', // TODO: Get from board details
                  boardDescription: null,
                ),
              );
              
              if (result == 'deleted' && mounted) {
                Navigator.pop(context);
              }
            },
            tooltip: 'Board Settings',
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
      body: Column(
        children: [
          // Error banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[100],
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: Row(
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Drawing mode toggle
                        ToggleButtons(
                          isSelected: [_drawMode == 'draw', _drawMode == 'text', _drawMode == 'pan'],
                          onPressed: (index) {
                            setState(() {
                              _drawMode = ['draw', 'text', 'pan'][index];
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.brush, size: 18),
                                  SizedBox(width: 4),
                                  Text('Draw'),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.text_fields, size: 18),
                                  SizedBox(width: 4),
                                  Text('Text'),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
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
                        
                        // Font size slider (only for text mode)
                        ...(_drawMode == 'text' ? [
                          const Text('Size:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: Slider(
                              value: _fontSize,
                              min: 10,
                              max: 48,
                              divisions: 19,
                              label: '${_fontSize.toInt()}px',
                              onChanged: (value) => setState(() => _fontSize = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ] : []),
                        
                        // Stroke width (only for draw mode)
                        ...(_drawMode == 'draw' ? [
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
                          const SizedBox(width: 16),
                        ] : []),
                        
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
                        
                        // Delete selected object button
                        ...(_selectedObjectId != null ? [
                          OutlinedButton.icon(
                            onPressed: _deleteSelectedObject,
                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ] : []),
                        
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
                ),

                // Canvas
                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) {
                      if (_drawMode == 'text') {
                        _addTextAtPosition(details.localPosition);
                      } else {
                        _selectObject(details.localPosition, allObjects);
                      }
                    },
                    onPanStart: (details) {
                      if (_drawMode == 'draw') {
                        _startDrawing(details.localPosition);
                      } else if (['rectangle', 'circle', 'line'].contains(_drawMode)) {
                        _startShape(details.localPosition);
                      }
                    },
                    onPanUpdate: _drawMode == 'draw'
                        ? (details) => _continueDrawing(details.localPosition)
                        : null,
                    onPanEnd: (details) {
                      if (_drawMode == 'draw') {
                        _currentStrokeId = null;
                      } else if (['rectangle', 'circle', 'line'].contains(_drawMode)) {
                        _finishShape(details.localPosition);
                      }
                    },
                    child: Container(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: _CanvasPainter(
                          strokes: strokes,
                          texts: texts,
                          shapes: shapes,
                          selectedObjectId: _selectedObjectId,
                          shapeStartPoint: _shapeStartPoint,
                          currentShapeType: _drawMode,
                          currentColor: _selectedColor,
                          currentStrokeWidth: _strokeWidth,
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
                              child: Stack(
                                children: [
                                  TextField(
                                    controller: _assigneeController,
                                    decoration: InputDecoration(
                                      hintText: '👤 Select Assignee',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      isDense: true,
                                      suffixIcon: _boardMembers.isNotEmpty
                                          ? const Icon(Icons.arrow_drop_down, size: 20)
                                          : null,
                                    ),
                                    onTap: () {
                                      setState(() => _showMemberDropdown = true);
                                    },
                                    onSubmitted: (_) => _addTask(),
                                  ),
                                  // Member dropdown
                                  if (_showMemberDropdown && _filteredMembers.isNotEmpty)
                                    Positioned(
                                      top: 50,
                                      left: 0,
                                      right: 0,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          constraints: const BoxConstraints(maxHeight: 200),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.white,
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: _filteredMembers.length,
                                            itemBuilder: (context, index) {
                                              final member = _filteredMembers[index];
                                              final name = member['name'] as String? ?? 'Unknown';
                                              final email = member['email'] as String? ?? '';
                                              return InkWell(
                                                onTap: () {
                                                  _assigneeController.text = name;
                                                  setState(() => _showMemberDropdown = false);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                                      ),
                                                      Text(
                                                        email,
                                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
  final List<Map<String, dynamic>> texts;
  final List<Map<String, dynamic>> shapes;
  final String? selectedObjectId;
  final Offset? shapeStartPoint;
  final String currentShapeType;
  final Color currentColor;
  final double currentStrokeWidth;

  _CanvasPainter({
    required this.strokes,
    required this.texts,
    required this.shapes,
    this.selectedObjectId,
    this.shapeStartPoint,
    required this.currentShapeType,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw strokes
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

    // Draw shapes
    for (final shape in shapes) {
      final shapeType = shape['type'] as String;
      final x1 = (shape['x1'] as num?)?.toDouble() ?? 0;
      final y1 = (shape['y1'] as num?)?.toDouble() ?? 0;
      final x2 = (shape['x2'] as num?)?.toDouble() ?? 0;
      final y2 = (shape['y2'] as num?)?.toDouble() ?? 0;
      final color = Color(shape['color'] as int? ?? 0xFF000000);
      final strokeWidth = (shape['strokeWidth'] as num?)?.toDouble() ?? 2;

      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      if (shapeType == 'rectangle') {
        canvas.drawRect(
          Rect.fromPoints(Offset(x1, y1), Offset(x2, y2)),
          paint,
        );
      } else if (shapeType == 'circle') {
        final center = Offset((x1 + x2) / 2, (y1 + y2) / 2);
        final radius = ((x2 - x1).abs() + (y2 - y1).abs()) / 4;
        canvas.drawCircle(center, radius, paint);
      } else if (shapeType == 'line') {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }

      // Draw selection border
      if (shape['id'] == selectedObjectId) {
        final selectionPaint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawRect(
          Rect.fromPoints(Offset(x1 - 5, y1 - 5), Offset(x2 + 5, y2 + 5)),
          selectionPaint,
        );
      }
    }

    // Draw texts
    for (final textObj in texts) {
      final text = textObj['text'] as String? ?? '';
      final x = (textObj['x'] as num?)?.toDouble() ?? 0;
      final y = (textObj['y'] as num?)?.toDouble() ?? 0;
      final color = Color(textObj['color'] as int? ?? 0xFF000000);
      final fontSize = (textObj['fontSize'] as num?)?.toDouble() ?? 16;

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));

      // Draw selection border
      if (textObj['id'] == selectedObjectId) {
        final selectionPaint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawRect(
          Rect.fromLTWH(x - 2, y - 2, textPainter.width + 4, textPainter.height + 4),
          selectionPaint,
        );
      }
    }

    // Draw shape preview while dragging
    if (shapeStartPoint != null && ['rectangle', 'circle', 'line'].contains(currentShapeType)) {
      // This will be updated in real-time by mouse position
      // Note: We need mouse position which we don't have here
      // This is a limitation - we'd need to pass current mouse position
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
