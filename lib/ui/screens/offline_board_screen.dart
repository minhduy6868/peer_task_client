import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/offline_board_provider.dart';
import '../../providers/app_providers.dart';
import '../../models/operation/operation.dart';
import '../../models/whiteboard_object/whiteboard_object.dart';
import '../../services/storage_service.dart';
import '../../services/p2p/p2p_manager.dart';
import '../../utils/platform_utils.dart';

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

/// Simplified Offline Board Screen - No server, pure local storage
class OfflineBoardScreen extends ConsumerStatefulWidget {
  final String boardId;
  final String? boardName;

  const OfflineBoardScreen({
    super.key,
    required this.boardId,
    this.boardName,
  });

  @override
  ConsumerState<OfflineBoardScreen> createState() => _OfflineBoardScreenState();
}

class _OfflineBoardScreenState extends ConsumerState<OfflineBoardScreen> {
  // Drawing state
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  String? _currentStrokeId;
  String? _userName;

  // Drawing tools
  DrawingTool _selectedTool = DrawingTool.pen;

  // Text tool state
  final _textController = TextEditingController();
  Offset? _textPosition;
  double _textSize = 16.0;

  // Undo stack
  final List<String> _undoStack = [];

  // Active strokes
  final Map<String, _ActiveStroke> _activeStrokes = {};

  // Kanban state
  final _taskController = TextEditingController();
  bool _showKanban = true;
  double _kanbanWidth = 350;
  bool _kanbanFullscreen = false;

  // Share/Join state
  String? _shareCode;
  TextEditingController _shareCodeController = TextEditingController();

  // P2P state - using unified P2PManager
  P2PManager? _p2pManager;
  int _connectedPeers = 0;
  bool _p2pEnabled = false;

  // Screenshot controller
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _generateShareCode();
    _initP2P();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final storage = StorageService();
    final username = storage.getOfflineUsername() ?? 'Anonymous';
    setState(() {
      _userName = username;
    });
  }

  /// Initialize P2P service using unified P2PManager
  Future<void> _initP2P() async {
    try {
      final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      final deviceName = '${_userName ?? "Anonymous"} (${PlatformUtils.platformName})';
      
      _p2pManager = P2PManager.create(
        boardId: widget.boardId,
        userId: userId,
        deviceName: deviceName,
      );
      
      _p2pManager!.onPeerJoined = (peerId, peerName) {
        if (mounted) {
          setState(() => _connectedPeers = _p2pManager?.connectedPeerCount ?? 0);
          debugPrint('🎉 Peer joined: $peerName (ID: $peerId)');
          debugPrint('   Total peers: $_connectedPeers');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${peerName ?? "Peer"} joined!'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      };
      
      _p2pManager!.onPeerLeft = (peerId) {
        if (mounted) {
          setState(() => _connectedPeers = _p2pManager?.connectedPeerCount ?? 0);
        }
      };
      
      _p2pManager!.onOperationReceived = (operation) {
        _applyReceivedOperation(operation);
      };
      
      _p2pManager!.onBoardDataReceived = (data) {
        debugPrint('📥 Received board data from peer');
      };
      
      await _p2pManager!.start();
      setState(() => _p2pEnabled = _p2pManager?.isRunning ?? false);
      
      debugPrint('✅ P2P initialized on ${PlatformUtils.platformName}');
    } catch (e) {
      debugPrint('❌ Failed to initialize P2P: $e');
    }
  }

  /// Apply operation received from peer
  void _applyReceivedOperation(Operation operation) {
    debugPrint('📥 Received operation from peer: ${operation.type} by ${operation.actor}');
    debugPrint('   Payload: ${operation.payload}');
    try {
      ref.read(offlineBoardProvider(widget.boardId).notifier).applyRemoteOperation(operation);
      debugPrint('✅ Operation applied successfully');
    } catch (e) {
      debugPrint('❌ Error applying operation: $e');
    }
  }

  /// Broadcast operation to P2P peers
  void _broadcastOperation(OperationType type, Map<String, dynamic> data) {
    if (!_p2pEnabled || _p2pManager == null) {
      debugPrint('⚠️ P2P not enabled - skip broadcast');
      return;
    }
    
    final operation = Operation(
      opId: 'op-${DateTime.now().millisecondsSinceEpoch}',
      actor: _userName ?? 'Anonymous',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: type,
      payload: data,
    );
    debugPrint('📤 Broadcasting operation: ${operation.type} by ${operation.actor}');
    debugPrint('   Peers connected: ${_p2pManager!.connectedPeerCount}');
    _p2pManager!.broadcastOperation(operation);
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _userName ?? 'Anonymous');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Name'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Enter your name...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty && name.length <= 20) {
                final storage = StorageService();
                await storage.saveOfflineUsername(name);
                setState(() => _userName = name);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _p2pManager?.stop();
    _textController.dispose();
    _taskController.dispose();
    _shareCodeController.dispose();
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
                // Open file explorer at location (platform specific)
                if (Platform.isWindows) {
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

  /// Generate a simple share code for offline board
  void _generateShareCode() {
    setState(() {
      _shareCode = widget.boardId.substring(0, 8).toUpperCase();
    });
  }

  /// Drawing methods
  void _onPanStart(Offset point) {
    if (_selectedTool == DrawingTool.text) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStrokeId = 'stroke-$now';
    _currentPoints = [point];

    final isEraser = _selectedTool == DrawingTool.eraser;
    final strokeColor = isEraser ? Colors.white : _selectedColor;
    final strokeWidth = isEraser ? _strokeWidth * 3 : _strokeWidth;
    final displayName = _userName ?? 'Anonymous';

    setState(() {
      _activeStrokes[_currentStrokeId!] = _ActiveStroke(
        points: [point],
        color: strokeColor,
        width: strokeWidth,
        userName: displayName,
        isEraser: isEraser,
      );
    });

    // Create operation
    ref.read(offlineBoardProvider(widget.boardId).notifier).createOperation(
          OperationType.createObject,
          {
            'id': _currentStrokeId,
            'type': 'stroke',
            'data': {
              'points': [point.dx, point.dy],
              'color': strokeColor.value,
              'width': strokeWidth,
              'actor': 'local-user',
              'actorName': displayName,
              'isEraser': isEraser,
            },
          },
        );
  }

  void _onPanUpdate(Offset point) {
    if (_currentStrokeId == null || _selectedTool == DrawingTool.text) return;

    setState(() {
      _currentPoints.add(point);
      _activeStrokes[_currentStrokeId!]?.points.add(point);
    });

    final isEraser = _selectedTool == DrawingTool.eraser;
    final strokeColor = isEraser ? Colors.white : _selectedColor;
    final strokeWidth = isEraser ? _strokeWidth * 3 : _strokeWidth;
    final points = _currentPoints.expand((p) => [p.dx, p.dy]).toList();
    final displayName = _userName ?? 'Anonymous';

    ref.read(offlineBoardProvider(widget.boardId).notifier).createOperation(
          OperationType.updateObject,
          {
            'id': _currentStrokeId,
            'type': 'stroke',
            'data': {
              'points': points,
              'color': strokeColor.value,
              'width': strokeWidth,
              'actor': 'local-user',
              'actorName': displayName,
              'isEraser': isEraser,
            },
          },
        );
  }

  void _onPanEnd() async {
    if (_currentStrokeId == null) return;

    final isEraser = _selectedTool == DrawingTool.eraser;
    final strokeColor = isEraser ? Colors.white : _selectedColor;
    final strokeWidth = isEraser ? _strokeWidth * 3 : _strokeWidth;
    final points = _currentPoints.expand((p) => [p.dx, p.dy]).toList();
    final displayName = _userName ?? 'Anonymous';
    
    final strokeData = {
      'id': _currentStrokeId,
      'type': 'stroke',
      'data': {
        'points': points,
        'color': strokeColor.value,
        'width': strokeWidth,
        'actor': 'local-user',
        'actorName': displayName,
        'isEraser': isEraser,
      },
    };

    ref.read(offlineBoardProvider(widget.boardId).notifier).createOperation(
          OperationType.updateObject,
          strokeData,
        );

    // Broadcast to P2P peers for real-time sync
    _broadcastOperation(OperationType.createObject, strokeData);

    // Persist to storage immediately - AWAIT to ensure data is saved
    await ref
        .read(offlineBoardProvider(widget.boardId).notifier)
        .persistAll();

    _undoStack.add(_currentStrokeId!);

    // Don't remove from active strokes yet - let provider handle persistence
    // Keep the stroke visible until it's confirmed in provider state
    // This fixes the issue where strokes disappear after 1 second
    // The stroke stays in provider.objects and will render from there
    
    _currentStrokeId = null;
    _currentPoints = [];
  }

  void _undo() async {
    if (_undoStack.isEmpty) return;

    final strokeId = _undoStack.removeLast();
    final deleteData = {
      'id': strokeId,
      'type': 'stroke',
    };
    
    ref.read(offlineBoardProvider(widget.boardId).notifier).createOperation(
          OperationType.deleteObject,
          deleteData,
        );
    
    // Broadcast delete to P2P peers
    _broadcastOperation(OperationType.deleteObject, deleteData);
    
    // Persist undo
    await ref
        .read(offlineBoardProvider(widget.boardId).notifier)
        .persistAll();
  }

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

  void _addText() async {
    if (_textController.text.trim().isEmpty || _textPosition == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final textId = 'text-$now';
    final displayName = _userName ?? 'Anonymous';

    final textData = {
      'id': textId,
      'type': 'text',
      'data': {
        'text': _textController.text.trim(),
        'position': [_textPosition!.dx, _textPosition!.dy],
        'color': _selectedColor.value,
        'fontSize': _textSize,
        'actor': 'local-user',
        'actorName': displayName,
      },
    };

    ref.read(offlineBoardProvider(widget.boardId).notifier).createOperation(
          OperationType.createObject,
          textData,
        );

    // Broadcast to P2P peers for real-time sync
    _broadcastOperation(OperationType.createObject, textData);

    // Persist immediately - AWAIT to ensure saved
    await ref
        .read(offlineBoardProvider(widget.boardId).notifier)
        .persistAll();

    _textController.clear();
    _textPosition = null;
    _undoStack.add(textId);
  }

  void _addTask() async {
    _showTaskDetailDialog();
  }

  /// Show detailed task creation dialog
  void _showTaskDetailDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final assigneeController = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Task'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'What needs to be done?',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.assignment),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 12),
              // Description
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add details...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),
              // Assignee
              TextField(
                controller: assigneeController,
                decoration: InputDecoration(
                  labelText: 'Assign To',
                  hintText: 'Person name (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 12),
              // Priority
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                  DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                  DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                  DropdownMenuItem(value: 'urgent', child: Text('🔥 Urgent')),
                ],
                onChanged: (value) {
                  if (value != null) selectedPriority = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task title is required')),
                );
                return;
              }

              final now = DateTime.now();
              final taskId = 'task-${now.millisecondsSinceEpoch}';
              final description = descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim();
              final assignee = assigneeController.text.trim().isEmpty
                  ? null
                  : assigneeController.text.trim();

              // Create task data structure
              final taskData = {
                'id': taskId,
                'type': 'task',
                'data': {
                  'id': taskId,
                  'boardId': widget.boardId,
                  'title': title,
                  'description': description,
                  'status': 'todo',
                  'priority': selectedPriority,
                  'assignee': assignee,
                  'assignees': assignee != null ? [assignee] : [],
                  'assigneeList': assignee != null
                      ? [
                          {
                            'id': 'local-$assignee',
                            'name': assignee,
                            'email': null,
                            'avatar': null,
                          }
                        ]
                      : [],
                  'labels': [],
                  'position': 0,
                  'createdBy': 'local-user',
                  'creatorName': 'You',
                  'createdAt': now.toIso8601String(),
                  'updatedAt': now.toIso8601String(),
                },
              };

              ref.read(offlineBoardProvider(widget.boardId).notifier).createTask(
                    title: title,
                    description: description,
                    status: 'todo',
                    priority: selectedPriority,
                    assignee: assignee,
                  );

              // Broadcast to P2P peers for real-time sync
              _broadcastOperation(OperationType.createObject, taskData);

              await ref
                  .read(offlineBoardProvider(widget.boardId).notifier)
                  .persistAll();

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(String taskId, String newStatus) async {
    await ref
        .read(offlineBoardProvider(widget.boardId).notifier)
        .updateTaskStatus(taskId, newStatus);
  }

  void _deleteTask(String taskId) async {
    await ref
        .read(offlineBoardProvider(widget.boardId).notifier)
        .deleteTask(taskId);
  }

  /// Show share code dialog with QR code
  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Offline Board'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share this board with others on the same network:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Scan with another device:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    // QR Code (screenshot and share the code below)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              _shareCode!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Share Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Or share this code:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _shareCode!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share code copied! 📋')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Code'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                '💡 How to join:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. They go to "Offline Boards"\n'
                '2. Tap "Join Board"\n'
                '3. Scan QR or enter code\n'
                '4. Both users see same board!\n\n'
                '⚠️ Must be on same WiFi/LAN',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show join board dialog
  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Offline Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the share code to join an existing board.\n'
              'You must have the same LAN/WiFi connection:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _shareCodeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g., ABC12345',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share code is 8 characters from board ID',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = _shareCodeController.text.trim().toUpperCase();
              if (code.length == 8) {
                final storage = StorageService();
                
                // Find board with matching prefix
                final allBoardIds = storage.getAllBoardIds();
                String? matchingBoardId;
                Map<String, dynamic>? boardState;
                
                for (final boardId in allBoardIds) {
                  if (boardId.startsWith(code)) {
                    matchingBoardId = boardId;
                    boardState = storage.getBoardState(matchingBoardId);
                    break;
                  }
                }
                
                if (boardState != null && matchingBoardId != null) {
                  // Board found - navigate to it with full boardId
                  _shareCodeController.clear();
                  Navigator.pop(context);
                  
                  if (mounted) {
                    final boardName = boardState['name'] as String? ?? 'Shared Board';
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => OfflineBoardScreen(
                          boardId: matchingBoardId!,
                          boardName: boardName,
                        ),
                      ),
                    );
                  }
                } else {
                  // Board not found
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          '❌ Board not found. Make sure both users are on the same network and the code is correct.',
                        ),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.red[400],
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code must be exactly 8 characters'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  /// Show P2P capability info dialog
  void _showP2PInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PlatformUtils.isP2PLanSupported ? Icons.check_circle : Icons.warning,
              color: PlatformUtils.isP2PLanSupported ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('P2P Status'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      kIsWeb ? Icons.web : Icons.desktop_windows,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Platform: ${PlatformUtils.platformName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // P2P capability
              Text(
                PlatformUtils.p2pCapabilityMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: PlatformUtils.isP2PLanSupported ? Colors.green[700] : Colors.orange[700],
                ),
              ),
              const SizedBox(height: 16),
              
              // Connection status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectedPeers > 0 ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _connectedPeers > 0 ? Colors.green[200]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _connectedPeers > 0 ? Icons.people : Icons.person,
                          color: _connectedPeers > 0 ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _connectedPeers > 0 
                            ? '$_connectedPeers peer(s) connected'
                            : 'No peers connected',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _connectedPeers > 0 ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (_p2pEnabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        'P2P service is running',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              
              if (!PlatformUtils.isP2PLanSupported) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  '💡 Để sử dụng P2P LAN thực sự:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Build app Windows/macOS/Linux\n'
                  '• Hoặc cài APK trên Android\n'
                  '• Hoặc build iOS app\n\n'
                  'App desktop/mobile có thể:\n'
                  '✅ Tự động tìm peers trên LAN\n'
                  '✅ Realtime sync giữa các thiết bị\n'
                  '✅ Không cần server!',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(offlineBoardProvider(widget.boardId));
    final strokes = boardState.objects
        .where((obj) => obj.type == WhiteboardObjectType.stroke)
        .map((obj) => {
              'id': obj.id,
              'type': 'stroke',
              'points': obj.data['points'] as List? ?? [],
              'color': obj.data['color'] as int? ?? 0xFF000000,
              'width': obj.data['width'] as double? ?? 3.0,
              'actor': obj.data['actor'] as String? ?? 'unknown',
              'actorName': obj.data['actorName'] as String? ?? 'Unknown',
              'isEraser': obj.data['isEraser'] as bool? ?? false,
            })
        .toList();

    final texts = boardState.objects
        .where((obj) => obj.type == WhiteboardObjectType.textBox)
        .map((obj) => {
              'id': obj.id,
              'type': 'text',
              'text': obj.data['text'] as String? ?? '',
              'position': obj.data['position'] as List? ?? [0, 0],
              'color': obj.data['color'] as int? ?? 0xFF000000,
              'fontSize': obj.data['fontSize'] as double? ?? 16.0,
              'actor': obj.data['actor'] as String? ?? 'unknown',
              'actorName': obj.data['actorName'] as String? ?? 'Unknown',
            })
        .toList();

    final todoTasks = boardState.tasks.where((t) => t['status'] == 'todo').toList();
    final doingTasks = boardState.tasks.where((t) => t['status'] == 'doing').toList();
    final doneTasks = boardState.tasks.where((t) => t['status'] == 'done').toList();

    if (boardState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offline Board')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _p2pManager?.stop();
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '📱 ${boardState.boardName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (MediaQuery.of(context).size.width > 600) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _userName ?? 'Anonymous',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Set Your Name',
            child: IconButton(
              icon: const Icon(Icons.person_rounded),
              onPressed: _showNameDialog,
            ),
          ),
          Tooltip(
            message: 'Share Board Code',
            child: IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _showShareDialog,
            ),
          ),
          Tooltip(
            message: 'Toggle Kanban',
            child: IconButton(
              icon: Icon(
                _showKanban ? Icons.unfold_less : Icons.unfold_more,
              ),
              onPressed: () => setState(() => _showKanban = !_showKanban),
            ),
          ),
          Tooltip(
            message: 'Capture Screenshot',
            child: IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _captureScreenshot,
            ),
          ),
          Tooltip(
            message: 'Board Info',
            child: IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Board Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Board Name: ${boardState.boardName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text('Strokes: ${strokes.length}'),
                        Text('Texts: ${texts.length}'),
                        Text('Tasks: ${boardState.tasks.length}'),
                        Text('Operations: ${boardState.operations.length}'),
                        const SizedBox(height: 12),
                        const Text(
                          '💾 All data saved locally',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
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
          ),
          // Logout button
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Do you want to exit offline mode and return to login?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          _p2pManager?.stop();
                          // Clear offline username to trigger login
                          final storage = ref.read(storageServiceProvider);
                          storage.clearOfflineUsername();
                          Navigator.pop(context); // Close dialog
                          // Navigate to login screen
                          if (mounted) {
                            context.go('/login');
                          }
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: _kanbanFullscreen
            ? _buildKanbanFullscreen(boardState, todoTasks, doingTasks, doneTasks)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final effectiveKanbanWidth = isMobile ? constraints.maxWidth * 0.85 : _kanbanWidth;
                  
                  return Stack(
                children: [
                  Row(
                  children: [
                    // Canvas area
                    Expanded(
                      child: _buildCanvasArea(strokes, texts),
                    ),
                    // Kanban sidebar
                    if (_showKanban)
                      MouseRegion(
                        onHover: (event) {
                          // Allow drag to resize
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: effectiveKanbanWidth,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: _buildKanbanContent(boardState, todoTasks, doingTasks, doneTasks),
                            ),
                            // Resize handle
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 4,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeColumn,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    setState(() {
                                      _kanbanWidth = (_kanbanWidth - details.delta.dx)
                                          .clamp(250.0, 600.0);
                                    });
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            );
                },
              ),
      ),
      floatingActionButton: _kanbanFullscreen
          ? FloatingActionButton(
              onPressed: () => setState(() => _kanbanFullscreen = false),
              tooltip: 'Exit Fullscreen',
              child: const Icon(Icons.unfold_less),
            )
          : null,
    );
  }

  Widget _buildCanvasArea(
    List<Map<String, dynamic>> strokes,
    List<Map<String, dynamic>> texts,
  ) {
    return Column(
      children: [
        // Tools toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _userName ?? 'You',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ToolButton(
                  icon: Icons.edit_rounded,
                  label: 'Pen',
                  isSelected: _selectedTool == DrawingTool.pen,
                  onTap: () => setState(() => _selectedTool = DrawingTool.pen),
                ),
                _ToolButton(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Eraser',
                  isSelected: _selectedTool == DrawingTool.eraser,
                  onTap: () => setState(() => _selectedTool = DrawingTool.eraser),
                ),
                _ToolButton(
                  icon: Icons.text_fields_rounded,
                  label: 'Text',
                  isSelected: _selectedTool == DrawingTool.text,
                  onTap: () => setState(() => _selectedTool = DrawingTool.text),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pick Color'),
                            content: SizedBox(
                              width: 200,
                              height: 150,
                              child: GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  Colors.black,
                                  Colors.red,
                                  Colors.green,
                                  Colors.blue,
                                  Colors.yellow,
                                  Colors.orange,
                                  Colors.purple,
                                  Colors.pink,
                                ]
                                    .map((color) => GestureDetector(
                                          onTap: () {
                                            setState(() => _selectedColor = color);
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 10,
                    onChanged: (value) => setState(() => _strokeWidth = value),
                  ),
                ),
                const SizedBox(width: 16),
                _ToolButton(
                  icon: Icons.undo_rounded,
                  label: 'Undo',
                  isSelected: false,
                  onTap: _undo,
                ),
              ],
            ),
          ),
        ),
        // Canvas
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: GestureDetector(
                onTapUp: (details) => _onCanvasTap(details.localPosition),
                onPanStart: (details) => _onPanStart(details.localPosition),
                onPanUpdate: (details) => _onPanUpdate(details.localPosition),
                onPanEnd: (details) => _onPanEnd(),
                child: Container(
                  width: 2000,
                  height: 2000,
                  color: Colors.white,
                  child: CustomPaint(
                    painter: _StrokePainter(
                      strokes: strokes,
                      texts: texts,
                      activeStrokes: _activeStrokes,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanContent(
    OfflineBoardState boardState,
    List<Map<String, dynamic>> todoTasks,
    List<Map<String, dynamic>> doingTasks,
    List<Map<String, dynamic>> doneTasks,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📋 Tasks',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Tooltip(
                    message: 'Fullscreen',
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, size: 18),
                      onPressed: () => setState(() => _kanbanFullscreen = true),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Task'),
                onPressed: _addTask,
              ),
            ],
          ),
        ),
        // Kanban columns
        Expanded(
          child: Row(
            children: [
              _TaskColumn(
                title: 'TODO',
                tasks: todoTasks,
                onMove: (id, _) => _updateTaskStatus(id, 'doing'),
                onDelete: _deleteTask,
                color: Colors.orange,
              ),
              _TaskColumn(
                title: 'DOING',
                tasks: doingTasks,
                onMove: (id, _) => _updateTaskStatus(id, 'done'),
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
    );
  }

  Widget _buildKanbanFullscreen(
    OfflineBoardState boardState,
    List<Map<String, dynamic>> todoTasks,
    List<Map<String, dynamic>> doingTasks,
    List<Map<String, dynamic>> doneTasks,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Tasks - Fullscreen'),
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Exit Fullscreen',
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit),
              onPressed: () => setState(() => _kanbanFullscreen = false),
            ),
          ),
        ],
      ),
      body: _buildKanbanContent(boardState, todoTasks, doingTasks, doneTasks),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        onPressed: _addTask,
      ),
    );
  }
}

// Tool button widget
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
    return Tooltip(
      message: label,
      child: Material(
        color: isSelected ? Colors.blue[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}

// Stroke painter
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
      for (int i = 0; i < pointsList.length; i += 2) {
        points.add(Offset(pointsList[i] as double, pointsList[i + 1] as double));
      }

      final paint = Paint()
        ..color = Color(stroke['color'] as int)
        ..strokeWidth = stroke['width'] as double
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (points.isNotEmpty) {
        canvas.drawPoints(ui.PointMode.polygon, points, paint);
      }
    }

    // Draw texts
    for (final text in texts) {
      final position = text['position'] as List?;
      if (position == null || position.length < 2) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text['text'] as String,
          style: TextStyle(
            color: Color(text['color'] as int),
            fontSize: text['fontSize'] as double,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(position[0] as double, position[1] as double),
      );
    }

    // Draw active strokes
    for (final entry in activeStrokes.entries) {
      final stroke = entry.value;
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPoints(ui.PointMode.polygon, stroke.points, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Task column widget
class _TaskColumn extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> tasks;
  final Function(String, Map<String, dynamic>)? onMove;
  final Function(String) onDelete;
  final Color color;

  const _TaskColumn({
    required this.title,
    required this.tasks,
    required this.onMove,
    required this.onDelete,
    required this.color,
  });

  String _getPriorityEmoji(String? priority) {
    switch (priority) {
      case 'low':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'high':
        return '🔴';
      case 'urgent':
        return '🔥';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: color)),
              ),
              child: Text(
                '$title (${tasks.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final priority = task['priority'] as String? ?? 'medium';
                  final assignee = task['assignee'] as String?;
                  final description = task['description'] as String?;

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(task['title'] as String? ?? 'Untitled'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description != null && description.isNotEmpty) ...[
                                  const Text(
                                    'Description:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(description),
                                  const SizedBox(height: 12),
                                ],
                                if (assignee != null && assignee.isNotEmpty) ...[
                                  const Text(
                                    'Assigned to:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(assignee),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  'Priority: ${_getPriorityEmoji(priority)} $priority',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Priority
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  task['title'] as String? ?? 'Untitled',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                _getPriorityEmoji(priority),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          // Description preview
                          if (description != null && description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          // Assignee
                          if (assignee != null && assignee.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    assignee,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Actions
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (onMove != null)
                                Tooltip(
                                  message: 'Move',
                                  child: GestureDetector(
                                    onTap: () => onMove!(task['id'], task),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: Colors.blue[400],
                                    ),
                                  ),
                                ),
                              Tooltip(
                                message: 'Delete',
                                child: GestureDetector(
                                  onTap: () => onDelete(task['id']),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ),
                            ],
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
