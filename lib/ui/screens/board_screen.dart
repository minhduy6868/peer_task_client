import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/operation/operation.dart';
import '../../models/task_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/theme_provider.dart';
import '../../services/cloudinary_service.dart';
import '../widgets/user_avatar.dart';
import '../../utils/error_display.dart';
import '../dialogs/change_password_dialog.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../widgets/app_toast.dart';
import '../widgets/task_dialog.dart';

enum _BoardPage { tasks, canvas }

enum _WhiteboardTool {
  select,
  hand,
  pen,
  eraser,
  rectangle,
  circle,
  arrow,
  note,
  text,
  kanban,
}

class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen>
    with SingleTickerProviderStateMixin {
  // Navigation & Page State
  _BoardPage _page = _BoardPage.tasks;
  bool _isSidebarCollapsed = false;
  bool _isVoicePanelCollapsed = false;
  String _activeNavId = 'tasks'; // 'tasks', 'whiteboard'

  // Drawing & Canvas State
  _WhiteboardTool _tool = _WhiteboardTool.pen;
  Color _color = const Color(0xFF5B4CF0);
  double _strokeWidth = 2.0;
  List<Offset> _points = [];
  String? _strokeId;
  Offset? _shapeStart;
  Offset? _shapeCurrent;
  final List<String> _localActionHistory = [];

  // Whiteboard Pagination State
  int _currentPageIndex = 0;

  // Voice & Meeting Room State
  bool _voice = true;
  bool _speakerOn = true;
  late final AnimationController _waveAnimController;

  // Discussion notes
  final TextEditingController _discussionNoteController =
      TextEditingController();
  final ScrollController _notesScroll = ScrollController();
  final FocusNode _noteFocus = FocusNode();
  int _shownNoteCount = 0;

  // Kanban & Sprint State
  String _taskSearchQuery = '';
  bool _tasksLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Responsive & Scaffold Key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _initializedSidebar = false;

  // Board Data
  List<Map<String, dynamic>> _members = [];
  String? _currentBoardId;

  @override
  void initState() {
    super.initState();
    _currentBoardId = widget.boardId;
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initBoard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedSidebar) {
      _initializedSidebar = true;
      final width = MediaQuery.of(context).size.width;
      if (width < 1280) {
        _isSidebarCollapsed = true;
      }
    }
  }

  @override
  void didUpdateWidget(BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boardId == widget.boardId) return;
    ref.read(whiteboardProvider.notifier).disconnect();
    _currentBoardId = widget.boardId;
    _members = [];
    _currentPageIndex = 0;
    _initBoard();
  }

  @override
  void dispose() {
    final boardId = _currentBoardId;
    if (boardId != null) {
      try {
        ref.read(whiteboardProvider.notifier).saveDraft(boardId: boardId);
      } catch (_) {}
    }
    _waveAnimController.dispose();
    _searchController.dispose();
    _discussionNoteController.dispose();
    _notesScroll.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _initBoard() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    ref.read(currentBoardIdProvider.notifier).state = widget.boardId;

    // connectToBoard resets the board synchronously before its first await,
    // so tasks and members can load in parallel without being wiped.
    final connecting = ref
        .read(whiteboardProvider.notifier)
        .connectToBoard(widget.boardId);
    final tasksAndMembers = Future.wait([_loadTasks(), _loadMembers()]);

    try {
      final restored = await connecting;
      if (mounted && restored > 0) {
        AppToast.show(
          context,
          message: AppLocalizations.of(context)!.canvasRestored,
        );
      }
    } catch (e) {
      await ref.read(whiteboardProvider.notifier).restoreDraft(widget.boardId);
      if (mounted) context.showErrorSnackBar(e);
    }
    await tasksAndMembers;
  }

  Future<void> _loadMembers() async {
    try {
      final members = await ref
          .read(apiServiceProvider)
          .getBoardMembers(widget.boardId);
      if (!mounted) return;
      setState(() => _members = members);
    } catch (e) {
      debugPrint('Board members failed: $e');
    }
  }

  Future<void> _loadTasks() async {
    if (mounted) setState(() => _tasksLoading = true);
    try {
      final tasks = await ref
          .read(apiServiceProvider)
          .getBoardTasks(widget.boardId);
      final notifier = ref.read(whiteboardProvider.notifier);
      for (final task in tasks) {
        final stamp = DateTime.tryParse(
          (task['updated_at'] ?? task['created_at'] ?? '').toString(),
        );
        notifier.receiveOperation(
          Operation(
            opId: 'api-${task['id']}-${stamp?.millisecondsSinceEpoch ?? 0}',
            actor: task['created_by'] ?? 'backend',
            timestamp:
                stamp?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
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
                'startDate': task['start_date'] ?? task['startDate'],
                'labels': task['labels'] ?? [],
                'attachments': task['attachments'] ?? [],
                'estimated_hours': task['estimated_hours'],
                'position': task['position'],
                'created_by': task['created_by'],
                'creator_name': task['creator_name'],
                'created_at': task['created_at'],
                'updated_at': task['updated_at'],
              },
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Load tasks failed: $e');
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _tasksLoading = false);
    }
  }

  void _openTask(Map<String, dynamic>? task, {String status = 'todo'}) {
    final existingStartDate = task != null ? _getTaskStartDate(task) : null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TaskDialog(
        initialStatus: status,
        existingTask: task != null
            ? TaskModel(
                id: task['id'] ?? '',
                boardId: widget.boardId,
                title: task['title'] ?? '',
                description: task['description'] as String?,
                status: task['status'] ?? status,
                priority: task['priority'] ?? 'medium',
                assignees: List<String>.from(task['assignees'] ?? []),
                assigneeList: const [],
                labels: List<String>.from(task['labels'] ?? []),
                deadline: task['deadline'] != null
                    ? DateTime.tryParse(task['deadline'].toString())
                    : null,
                position: (task['position'] as num?)?.toInt() ?? 0,
                createdBy: task['created_by']?.toString() ?? '',
                createdAt: existingStartDate ?? DateTime.now(),
                updatedAt: DateTime.now(),
              )
            : null,
        boardMembers: _members,
        initialAttachments: [
          for (final a in (task?['attachments'] as List?) ?? const [])
            if (a is Map) Map<String, dynamic>.from(a),
        ],
        onUploadImage: (bytes, fileName) => CloudinaryService().uploadImage(
          api: ref.read(apiServiceProvider),
          imageBytes: bytes,
          fileName: fileName,
        ),
        onSave:
            ({
              required String title,
              String? description,
              required String priority,
              required String status,
              DateTime? deadline,
              DateTime? startDate,
              List<String>? assignees,
              List<String>? labels,
              double? estimatedHours,
              List<Map<String, dynamic>>? attachments,
            }) async {
              if (task == null) {
                await _createTask(
                  title: title,
                  description: description,
                  priority: priority,
                  status: status,
                  deadline: deadline,
                  startDate: startDate,
                  assignees: assignees,
                  labels: labels,
                  estimatedHours: estimatedHours,
                  attachments: attachments,
                );
              } else {
                await _updateTask(
                  taskId: task['id'],
                  title: title,
                  description: description,
                  priority: priority,
                  status: status,
                  deadline: deadline,
                  startDate: startDate,
                  assignees: assignees,
                  labels: labels,
                  estimatedHours: estimatedHours,
                  attachments: attachments,
                );
              }
            },
        onDelete: task != null ? () => _deleteTask(task['id']) : null,
      ),
    );
  }

  Future<void> _createTask({
    required String title,
    String status = 'todo',
    String? description,
    String priority = 'medium',
    DateTime? deadline,
    DateTime? startDate,
    List<String>? assignees,
    List<String>? labels,
    double? estimatedHours,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final response = await ref
          .read(apiServiceProvider)
          .createTask(
            boardId: widget.boardId,
            title: title,
            description: description,
            status: status,
            priority: priority,
            deadline: deadline,
            assignees: assignees,
            labels: labels,
            estimatedHours: estimatedHours,
            attachments: attachments,
          );
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.createObject,
        {
          'id': response['id'],
          'type': 'task',
          'data': {
            ...response,
            'title': title,
            'description': description,
            'status': status,
            'priority': priority,
            'assignees': assignees ?? response['assignees'] ?? [],
            'labels': labels ?? response['labels'] ?? [],
            'deadline': deadline?.toIso8601String() ?? response['deadline'],
            'startDate': startDate?.toIso8601String(),
          },
        },
        shouldSaveBackend: false,
      );
      if (mounted)
        AppToast.show(
          context,
          message: AppLocalizations.of(context)!.taskCreatedToast,
        );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  Future<void> _updateTask({
    required String taskId,
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? deadline,
    DateTime? startDate,
    List<String>? assignees,
    List<String>? labels,
    double? estimatedHours,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final response = await ref
          .read(apiServiceProvider)
          .updateTask(
            taskId: taskId,
            title: title,
            description: description ?? '',
            priority: priority,
            status: status,
            deadline: deadline,
            assignees: assignees ?? [],
            labels: labels ?? [],
            estimatedHours: estimatedHours,
            attachments: attachments,
          );
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.updateObject,
        {
          'id': taskId,
          'type': 'task',
          'data': {
            ...response,
            'title': title,
            'description': description,
            'priority': priority,
            'status': status,
            'deadline': deadline?.toIso8601String(),
            'startDate': startDate?.toIso8601String(),
            'assignees': assignees ?? [],
            'labels': labels ?? [],
            if (attachments != null) 'attachments': attachments,
          },
        },
        shouldSaveBackend: false,
      );
      if (mounted)
        AppToast.show(
          context,
          message: AppLocalizations.of(context)!.taskUpdatedToast,
        );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  void _broadcastTaskStatus(String taskId, String status) {
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.updateObject,
      {
        'id': taskId,
        'type': 'task',
        'data': {'status': status},
      },
      shouldSaveBackend: false,
    );
  }

  Future<void> _moveTask(String taskId, String status) async {
    final current = _scene(
      ref.read(whiteboardProvider).operations,
      AppLocalizations.of(context)!,
    ).tasks.where((t) => t['id'] == taskId).firstOrNull;
    final oldStatus = current?['status'] as String?;
    if (oldStatus == status) return;

    _broadcastTaskStatus(taskId, status);
    try {
      await ref
          .read(apiServiceProvider)
          .moveTask(taskId: taskId, status: status, boardId: widget.boardId);
    } catch (e) {
      if (oldStatus != null) _broadcastTaskStatus(taskId, oldStatus);
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await ref.read(apiServiceProvider).deleteTask(taskId);
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.deleteObject,
        {'id': taskId, 'type': 'task'},
        shouldSaveBackend: false,
      );
      if (mounted)
        AppToast.show(
          context,
          message: AppLocalizations.of(context)!.taskDeletedToast,
        );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  // ===== Whiteboard Operations & Pagination =====

  String _getActivePageId(_Scene scene) {
    if (scene.pages.isEmpty) return 'page-1';
    final idx = _currentPageIndex.clamp(0, scene.pages.length - 1);
    return scene.pages[idx]['id'] as String;
  }

  void _onPanStart(Offset point, _Scene scene) {
    if (_tool == _WhiteboardTool.hand || _tool == _WhiteboardTool.select)
      return;
    final pageId = _getActivePageId(scene);

    if (_tool == _WhiteboardTool.eraser) {
      _eraseAtPoint(point, scene, pageId);
      return;
    }

    if (_tool == _WhiteboardTool.rectangle ||
        _tool == _WhiteboardTool.circle ||
        _tool == _WhiteboardTool.arrow) {
      setState(() {
        _shapeStart = point;
        _shapeCurrent = point;
      });
      return;
    }

    if (_tool == _WhiteboardTool.text) {
      _promptAddText(point, pageId);
      return;
    }

    if (_tool == _WhiteboardTool.note) {
      _promptAddStickyNote(point, pageId);
      return;
    }

    if (_tool == _WhiteboardTool.pen) {
      _strokeId = 'stroke-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _points = [point];
      });
    }
  }

  void _onPanUpdate(Offset point, _Scene scene) {
    final pageId = _getActivePageId(scene);

    if (_tool == _WhiteboardTool.eraser) {
      _eraseAtPoint(point, scene, pageId);
      return;
    }

    if (_tool == _WhiteboardTool.rectangle ||
        _tool == _WhiteboardTool.circle ||
        _tool == _WhiteboardTool.arrow) {
      setState(() {
        _shapeCurrent = point;
      });
      return;
    }

    if (_tool == _WhiteboardTool.pen && _strokeId != null) {
      setState(() {
        _points.add(point);
      });
    }
  }

  void _onPanEnd(_Scene scene) {
    final pageId = _getActivePageId(scene);

    if (_tool == _WhiteboardTool.pen &&
        _strokeId != null &&
        _points.isNotEmpty) {
      final flatPoints = <double>[];
      for (final p in _points) {
        flatPoints.add(p.dx);
        flatPoints.add(p.dy);
      }
      final opId = _strokeId!;
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.createObject,
        {
          'id': opId,
          'type': 'stroke',
          'data': {
            'points': flatPoints,
            'color': _color.toARGB32(),
            'width': _strokeWidth,
            'tool': _tool.name,
            'pageId': pageId,
          },
        },
        shouldSaveBackend: true,
      );
      _localActionHistory.add(opId);
      _strokeId = null;
      setState(() {
        _points = [];
      });
    }

    if ((_tool == _WhiteboardTool.rectangle ||
            _tool == _WhiteboardTool.circle ||
            _tool == _WhiteboardTool.arrow) &&
        _shapeStart != null &&
        _shapeCurrent != null) {
      final shapeId = 'shape-${DateTime.now().millisecondsSinceEpoch}';
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.createObject,
        {
          'id': shapeId,
          'type': 'shape',
          'data': {
            'shapeType': _tool.name,
            'startX': _shapeStart!.dx,
            'startY': _shapeStart!.dy,
            'endX': _shapeCurrent!.dx,
            'endY': _shapeCurrent!.dy,
            'color': _color.toARGB32(),
            'width': _strokeWidth,
            'pageId': pageId,
          },
        },
        shouldSaveBackend: true,
      );
      _localActionHistory.add(shapeId);
      setState(() {
        _shapeStart = null;
        _shapeCurrent = null;
      });
    }
  }

  void _eraseAtPoint(Offset point, _Scene scene, String pageId) {
    // Check strokes on current page
    for (final s in scene.strokes) {
      if ((s['pageId'] ?? 'page-1') != pageId) continue;
      final pts = s['points'] as List?;
      if (pts == null || pts.length < 2) continue;
      for (var i = 0; i < pts.length - 1; i += 2) {
        final sx = (pts[i] as num).toDouble();
        final sy = (pts[i + 1] as num).toDouble();
        final dist = (point - Offset(sx, sy)).distance;
        if (dist < 18.0) {
          final id = s['id'] as String;
          ref.read(whiteboardProvider.notifier).createOperation(
            OperationType.deleteObject,
            {'id': id, 'type': 'stroke'},
            shouldSaveBackend: true,
          );
          return;
        }
      }
    }

    // Check shapes on current page
    for (final shape in scene.shapes) {
      if ((shape['pageId'] ?? 'page-1') != pageId) continue;
      final sx = (shape['startX'] as num?)?.toDouble() ?? 0;
      final sy = (shape['startY'] as num?)?.toDouble() ?? 0;
      final ex = (shape['endX'] as num?)?.toDouble() ?? 0;
      final ey = (shape['endY'] as num?)?.toDouble() ?? 0;
      final rect = Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)).inflate(12);
      if (rect.contains(point)) {
        final id = shape['id'] as String;
        ref.read(whiteboardProvider.notifier).createOperation(
          OperationType.deleteObject,
          {'id': id, 'type': 'shape'},
          shouldSaveBackend: true,
        );
        return;
      }
    }
  }

  void _undo(_Scene scene) {
    if (_localActionHistory.isEmpty) return;
    final lastId = _localActionHistory.removeLast();
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.deleteObject,
      {'id': lastId, 'type': 'any'},
      shouldSaveBackend: true,
    );
  }

  void _confirmClearAll(AppLocalizations l10n, _Scene scene) {
    final pageId = _getActivePageId(scene);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              l10n.clearAll,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(l10n.clearCanvasConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Delete only items on this page
              for (final s in scene.strokes) {
                if ((s['pageId'] ?? 'page-1') == pageId) {
                  ref.read(whiteboardProvider.notifier).createOperation(
                    OperationType.deleteObject,
                    {'id': s['id'], 'type': 'stroke'},
                    shouldSaveBackend: true,
                  );
                }
              }
              for (final sh in scene.shapes) {
                if ((sh['pageId'] ?? 'page-1') == pageId) {
                  ref.read(whiteboardProvider.notifier).createOperation(
                    OperationType.deleteObject,
                    {'id': sh['id'], 'type': 'shape'},
                    shouldSaveBackend: true,
                  );
                }
              }
              for (final t in scene.texts) {
                if ((t['pageId'] ?? 'page-1') == pageId) {
                  ref.read(whiteboardProvider.notifier).createOperation(
                    OperationType.deleteObject,
                    {'id': t['id'], 'type': 'text'},
                    shouldSaveBackend: true,
                  );
                }
              }
              for (final n in scene.notes) {
                if ((n['pageId'] ?? 'page-1') == pageId) {
                  ref.read(whiteboardProvider.notifier).createOperation(
                    OperationType.deleteObject,
                    {'id': n['id'], 'type': 'sticky_note'},
                    shouldSaveBackend: true,
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
  }

  void _promptAddText(Offset point, String pageId) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.addTextTitle,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterTextHint,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                final id = 'text-${DateTime.now().millisecondsSinceEpoch}';
                ref.read(whiteboardProvider.notifier).createOperation(
                  OperationType.createObject,
                  {
                    'id': id,
                    'type': 'text',
                    'data': {
                      'text': val,
                      'x': point.dx,
                      'y': point.dy,
                      'color': _color.toARGB32(),
                      'pageId': pageId,
                    },
                  },
                  shouldSaveBackend: true,
                );
                _localActionHistory.add(id);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(AppLocalizations.of(context)!.addAction),
          ),
        ],
      ),
    );
  }

  void _promptAddStickyNote(Offset point, String pageId) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.addStickyNoteTitle,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterNoteHint,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                final id = 'note-${DateTime.now().millisecondsSinceEpoch}';
                ref.read(whiteboardProvider.notifier).createOperation(
                  OperationType.createObject,
                  {
                    'id': id,
                    'type': 'sticky_note',
                    'data': {
                      'text': val,
                      'x': point.dx,
                      'y': point.dy,
                      'pageId': pageId,
                    },
                  },
                  shouldSaveBackend: true,
                );
                _localActionHistory.add(id);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(AppLocalizations.of(context)!.pasteNote),
          ),
        ],
      ),
    );
  }

  // ===== Real Voice Controls (1.1: Bỏ toàn bộ toast thông báo mic/loa) =====

  Future<void> _toggleMic() async {
    final nextState = !_voice;
    final notifier = ref.read(whiteboardProvider.notifier);
    final webrtc = notifier.webrtc;

    if (nextState) {
      try {
        final success = await webrtc?.startAudioStream() ?? true;
        if (!success) {
          if (mounted)
            context.showErrorSnackBar(
              AppLocalizations.of(context)!.micPermissionDenied,
            );
          return;
        }
        notifier.updateMicStatus(false);
        setState(() => _voice = true);
      } catch (e) {
        if (mounted)
          context.showErrorSnackBar(
            AppLocalizations.of(context)!.micError(e.toString()),
          );
      }
    } else {
      await webrtc?.stopAudioStream();
      notifier.updateMicStatus(true);
      setState(() => _voice = false);
    }
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    final notifier = ref.read(whiteboardProvider.notifier);
    for (final renderer in notifier.remoteAudio.renderers) {
      renderer.muted = !_speakerOn;
    }
  }

  void _confirmLeaveCall(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.leaveRoom,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(l10n.leaveRoomConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(whiteboardProvider.notifier)
                  .webrtc
                  ?.stopAudioStream();
              ref.read(whiteboardProvider.notifier).updateMicStatus(true);
              if (!mounted) return;
              _leave();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(l10n.leaveRoom),
          ),
        ],
      ),
    );
  }

  // ===== Discussion Notes Methods =====

  void _postDiscussionNote() {
    final text = _discussionNoteController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authStateProvider).user;
    final noteId = 'dnote-${DateTime.now().millisecondsSinceEpoch}';
    final noteData = {
      'text': text,
      'authorId': user?.id ?? 'self',
      'authorName': user?.name?.isNotEmpty == true
          ? user!.name!
          : (user?.email ?? AppLocalizations.of(context)!.you),
      'createdAt': DateTime.now().toIso8601String(),
    };
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.createObject,
      {'id': noteId, 'type': 'discussion_note', 'data': noteData},
      shouldSaveBackend: true,
    );
    _discussionNoteController.clear();
    _noteFocus.requestFocus();
    _scrollNotesToEnd();
  }

  void _deleteDiscussionNote(String noteId) {
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.deleteObject,
      {'id': noteId, 'type': 'discussion_note'},
      shouldSaveBackend: true,
    );
  }

  // ===== Pagination Actions (Image 3) =====

  void _addNewPage(AppLocalizations l10n, _Scene scene) {
    final newPageId = 'page-${DateTime.now().millisecondsSinceEpoch}';
    final pageNum = scene.pages.length + 1;
    final pageName = '${l10n.pageTitlePrefix} $pageNum';

    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.createObject,
      {
        'id': newPageId,
        'type': 'whiteboard_page',
        'data': {
          'id': newPageId,
          'name': pageName,
          'index': scene.pages.length,
          'createdAt': DateTime.now().toIso8601String(),
        },
      },
      shouldSaveBackend: true,
    );

    setState(() {
      _currentPageIndex = scene.pages.length;
    });
  }

  void _renameCurrentPage(AppLocalizations l10n, _Scene scene) {
    if (scene.pages.isEmpty) return;
    final idx = _currentPageIndex.clamp(0, scene.pages.length - 1);
    final currentPage = scene.pages[idx];
    final currentName =
        currentPage['name'] as String? ?? '${l10n.pageTitlePrefix} 1';
    final pageId = currentPage['id'] as String;

    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.renamePage,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.enterPageName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                AppToast.show(context, message: l10n.pageNameEmpty);
                return;
              }
              final isDuplicate = scene.pages.any(
                (p) =>
                    p['id'] != pageId &&
                    (p['name'] as String?).toString().toLowerCase() ==
                        newName.toLowerCase(),
              );
              if (isDuplicate) {
                AppToast.show(context, message: l10n.pageNameExists);
                return;
              }
              Navigator.of(ctx).pop();
              ref.read(whiteboardProvider.notifier).createOperation(
                OperationType.updateObject,
                {
                  'id': pageId,
                  'type': 'whiteboard_page',
                  'data': {'name': newName},
                },
                shouldSaveBackend: true,
              );
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCurrentPage(AppLocalizations l10n, _Scene scene) {
    if (scene.pages.length <= 1) {
      AppToast.show(context, message: l10n.cannotDeleteLastPage);
      return;
    }
    final idx = _currentPageIndex.clamp(0, scene.pages.length - 1);
    final pageId = scene.pages[idx]['id'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              l10n.deletePage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(l10n.deletePageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(whiteboardProvider.notifier).createOperation(
                OperationType.deleteObject,
                {'id': pageId, 'type': 'whiteboard_page'},
                shouldSaveBackend: true,
              );
              setState(() {
                _currentPageIndex = math.max(0, _currentPageIndex - 1);
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(l10n.deletePage),
          ),
        ],
      ),
    );
  }

  // ===== Assignee Name Resolution (2.2: Không bao giờ hiện UUID) =====

  String _resolveAssigneeName(
    String idOrName,
    Map<String, dynamic> task,
    AppLocalizations l10n,
  ) {
    final trimmed = idOrName.trim();
    if (trimmed.isEmpty) return l10n.unassigned;

    // 1. Check task's own assignee_list
    final assigneeList = task['assignee_list'] as List?;
    if (assigneeList != null) {
      for (final item in assigneeList) {
        if (item is Map) {
          final id = item['id']?.toString();
          final name = item['name']?.toString();
          if (id == trimmed && name != null && name.isNotEmpty) {
            return name;
          }
        }
      }
    }

    // 2. Check _members loaded from board
    for (final m in _members) {
      final mId = m['id']?.toString();
      final mName = m['name']?.toString();
      if (mId == trimmed && mName != null && mName.isNotEmpty) {
        return mName;
      }
    }

    // 3. Check current user
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser != null && currentUser.id == trimmed) {
      if (currentUser.name?.isNotEmpty == true) return currentUser.name!;
    }

    // 4. If it's already a regular name (not a UUID)
    final isUuid =
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(trimmed) ||
        RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(trimmed);
    if (!isUuid && trimmed.length < 30) {
      return trimmed;
    }

    // 5. Unresolved UUID: fallback to localized unknown
    return l10n.unknownUser;
  }

  String? _resolveAssigneeAvatar(String id, Map<String, dynamic> task) {
    final trimmed = id.trim();
    final assigneeList = task['assignee_list'] as List?;
    if (assigneeList != null) {
      for (final item in assigneeList) {
        if (item is Map && item['id']?.toString() == trimmed) {
          final avatar = item['avatar']?.toString();
          if (avatar != null && avatar.isNotEmpty) return avatar;
        }
      }
    }
    for (final m in _members) {
      if ((m['user_id'] ?? m['id'])?.toString() == trimmed) {
        final avatar = m['avatar']?.toString();
        if (avatar != null && avatar.isNotEmpty) return avatar;
      }
    }
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser != null && currentUser.id == trimmed) {
      return currentUser.avatar;
    }
    return null;
  }

  DateTime? _getTaskStartDate(Map<String, dynamic> task) {
    if (task['startDate'] != null) {
      return DateTime.tryParse(task['startDate'].toString());
    }
    if (task['start_date'] != null) {
      return DateTime.tryParse(task['start_date'].toString());
    }
    final desc = task['description'] as String?;
    if (desc != null && desc.contains('<!--start_date:')) {
      final match = RegExp(r'<!--start_date:([^>]+)-->').firstMatch(desc);
      if (match != null) {
        final s = match.group(1);
        if (s != null) return DateTime.tryParse(s.trim());
      }
    }
    if (task['created_at'] != null) {
      return DateTime.tryParse(task['created_at'].toString());
    }
    return null;
  }

  static final _checklistLine = RegExp(
    r'^\s*-\s*\[([ xX])\].*$',
    multiLine: true,
  );

  ({int done, int total}) _checklistProgress(String? raw) {
    final items = _checklistLine.allMatches(raw ?? '').toList();
    final done = items.where((m) => m.group(1)!.toLowerCase() == 'x').length;
    return (done: done, total: items.length);
  }

  String _getCleanDescription(String? raw) {
    if (raw == null) return '';
    var clean = raw.replaceAll(RegExp(r'<!--start_date:[^>]+-->'), '');
    clean = clean.replaceAll(_checklistLine, '');
    clean = clean.replaceAll(RegExp(r'<!--[^>]*-->'), '');
    clean = clean.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<Map<String, dynamic>> _filterTasks(
    Iterable<Map<String, dynamic>> tasks,
  ) {
    final q = _taskSearchQuery.toLowerCase();
    if (q.isEmpty) return tasks.toList();
    return tasks.where((t) {
      final title = (t['title'] as String? ?? '').toLowerCase();
      final desc = _getCleanDescription(
        t['description'] as String?,
      ).toLowerCase();
      final labels = List<String>.from(
        t['labels'] ?? [],
      ).join(' ').toLowerCase();
      return title.contains(q) || desc.contains(q) || labels.contains(q);
    }).toList();
  }

  _Scene _scene(List<Operation> operations, AppLocalizations l10n) {
    final strokes = <Map<String, dynamic>>[];
    final shapes = <Map<String, dynamic>>[];
    final notes = <Map<String, dynamic>>[];
    final texts = <Map<String, dynamic>>[];
    final discussionNotes = <Map<String, dynamic>>[];
    final tasks = <Map<String, dynamic>>[];
    final pages = <Map<String, dynamic>>[];
    final taskOps = <Operation>[];

    for (final op in operations) {
      if (op.payload['type'] == 'task') {
        taskOps.add(op);
        continue;
      }
      if (op.type == OperationType.deleteObject &&
          (op.payload['objectType'] == 'all' || op.payload['type'] == 'all')) {
        strokes.clear();
        shapes.clear();
        notes.clear();
        texts.clear();
        continue;
      }

      final id = op.payload['id'] as String?;
      final type = op.payload['type'] as String?;
      if (id == null || type == null) continue;

      if (op.type == OperationType.deleteObject) {
        strokes.removeWhere((item) => item['id'] == id);
        shapes.removeWhere((item) => item['id'] == id);
        notes.removeWhere((item) => item['id'] == id);
        texts.removeWhere((item) => item['id'] == id);
        discussionNotes.removeWhere((item) => item['id'] == id);
        pages.removeWhere((item) => item['id'] == id);
        continue;
      }

      final data = {
        'id': id,
        ...Map<String, dynamic>.from(op.payload['data'] ?? {}),
      };
      switch (type) {
        case 'stroke':
          strokes.removeWhere((item) => item['id'] == id);
          strokes.add(data);
          break;
        case 'shape':
          shapes.removeWhere((item) => item['id'] == id);
          shapes.add(data);
          break;
        case 'sticky_note':
          notes.removeWhere((item) => item['id'] == id);
          notes.add(data);
          break;
        case 'text':
          texts.removeWhere((item) => item['id'] == id);
          texts.add(data);
          break;
        case 'discussion_note':
          discussionNotes.removeWhere((item) => item['id'] == id);
          discussionNotes.add(data);
          break;
        case 'whiteboard_page':
          pages.removeWhere((item) => item['id'] == id);
          pages.add(data);
          break;
      }
    }

    taskOps.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (final op in taskOps) {
      final id = op.payload['id'] as String?;
      if (id == null) continue;
      final index = tasks.indexWhere((t) => t['id'] == id);
      if (op.type == OperationType.deleteObject) {
        if (index >= 0) tasks.removeAt(index);
        continue;
      }
      final data = Map<String, dynamic>.from(op.payload['data'] ?? {});
      if (op.type == OperationType.createObject) {
        final task = {'id': id, ...data};
        if (index >= 0) {
          tasks[index] = task;
        } else {
          tasks.add(task);
        }
      } else if (index >= 0) {
        tasks[index] = {...tasks[index], ...data, 'id': id};
      }
    }

    if (pages.isEmpty) {
      pages.add({
        'id': 'page-1',
        'name': '${l10n.pageTitlePrefix} 1',
        'index': 0,
      });
    }

    return _Scene(
      strokes: strokes,
      shapes: shapes,
      notes: notes,
      texts: texts,
      discussionNotes: discussionNotes,
      tasks: tasks,
      pages: pages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(whiteboardProvider);
    final user = ref.watch(authStateProvider).user;
    final selfName = user?.name?.isNotEmpty == true
        ? user!.name!
        : (user?.email ?? l10n.you);
    _syncWaveAnimation(
      (_voice && state.localSpeaking) ||
          state.peers.any((p) => p.isSpeaking == true && p.isMuted != true),
    );
    final scene = _scene(state.operations, l10n);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1280;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark
          ? const Color(0xFF13131A)
          : const Color(0xFFF7F8FC),
      drawer: isMobile
          ? Drawer(child: _buildLeftSidebar(selfName, isDark, state, l10n))
          : null,
      endDrawer: !isDesktop
          ? Drawer(
              width: 320,
              child: SafeArea(
                child: _buildRightVoicePanel(
                  selfName,
                  isDark,
                  scene,
                  state,
                  l10n,
                  isDrawer: true,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================== LEFT SIDEBAR (Desktop & Tablet) ====================
            if (!isMobile) _buildLeftSidebar(selfName, isDark, state, l10n),

            // ==================== MAIN CONTENT AREA ====================
            Expanded(
              child: Column(
                children: [
                  // Top App Bar / Search Bar
                  _buildTopSearchBar(isDark, l10n, isMobile, isDesktop, state),

                  // Body: Whiteboard (Image 1 & 3) or Kanban (Image 2)
                  Expanded(
                    child: _page == _BoardPage.canvas
                        ? _buildWhiteboardView(scene, isDark, l10n)
                        : _buildKanbanView(scene, isDark, l10n),
                  ),
                ],
              ),
            ),

            // ==================== RIGHT VOICE MEETING PANEL (Image 1 & 2) ====================
            // 1.2: Appears on BOTH Kanban and Whiteboard screens (docked only on Desktop >= 1280)
            if (!_isVoicePanelCollapsed && isDesktop)
              _buildRightVoicePanel(
                selfName,
                isDark,
                scene,
                state,
                l10n,
                isDrawer: false,
              ),
          ],
        ),
      ),
      // Floating button on Tablet/Mobile opens endDrawer; on Desktop expands docked panel
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              backgroundColor: const Color(0xFF5B4CF0),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.people_alt_outlined, size: 18),
              label: Text(l10n.roomMembersTitle(1 + state.peers.length)),
            )
          : (_isVoicePanelCollapsed
                ? FloatingActionButton.extended(
                    onPressed: () =>
                        setState(() => _isVoicePanelCollapsed = false),
                    backgroundColor: const Color(0xFF5B4CF0),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.people_alt_outlined, size: 18),
                    label: Text(l10n.roomMembersTitle(1 + state.peers.length)),
                  )
                : null),
    );
  }

  // ==================== TOP SEARCH BAR ====================
  void _leave() {
    final board = ref.read(currentBoardProvider).value;
    if (board != null) {
      context.go('/workspace/${board.workspaceId}/boards');
    } else {
      context.go('/workspaces');
    }
  }

  Widget _buildTopSearchBar(
    bool isDark,
    AppLocalizations l10n,
    bool isMobile,
    bool isDesktop,
    WhiteboardState state,
  ) {
    final board = ref.watch(currentBoardProvider).value;
    final boardTitle = board?.name.isNotEmpty == true
        ? board!.name
        : l10n.boards;
    return LayoutBuilder(
      builder: (context, constraints) => _buildTopBarContent(
        isDark: isDark,
        l10n: l10n,
        isMobile: isMobile,
        isDesktop: isDesktop,
        state: state,
        boardTitle: boardTitle,
        compact: isMobile || constraints.maxWidth < 900,
      ),
    );
  }

  Widget _buildTopBarContent({
    required bool isDark,
    required AppLocalizations l10n,
    required bool isMobile,
    required bool isDesktop,
    required WhiteboardState state,
    required String boardTitle,
    required bool compact,
  }) {
    return Container(
      height: 58,
      padding: EdgeInsets.only(left: 6, right: isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFEDF2F7),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.boards,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: _leave,
          ),
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                boardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                ),
              ),
            ),
          const SizedBox(width: 12),

          // Search Input
          if (_page != _BoardPage.tasks)
            const Spacer()
          else
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262636)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B3B4F)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: l10n.searchPlaceholder,
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) =>
                            setState(() => _taskSearchQuery = val.trim()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 10),

          // Nút "Họp nhanh P2P" (Toggle mic directly, no toast)
          Tooltip(
            message: l10n.quickMeetP2P,
            child: InkWell(
              onTap: _toggleMic,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                decoration: BoxDecoration(
                  color: _voice
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _voice
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _voice
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 6),
                      Text(
                        l10n.quickMeetP2P,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _voice
                              ? const Color(0xFF047857)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Nút "+ Tạo mới"
          if (compact)
            IconButton.filled(
              onPressed: () => _openTask(null),
              tooltip: l10n.createNewAction,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF5B4CF0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
            )
          else
            FilledButton.icon(
              onPressed: () => _openTask(null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                l10n.createNewAction,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B4CF0),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: isDark ? l10n.themeLight : l10n.themeDark,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          if (!isDesktop && !isMobile) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.roomMembersTitle(1 + state.peers.length),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 20,
                    color: Color(0xFF5B4CF0),
                  ),
                  if (state.peers.isNotEmpty)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== LEFT SIDEBAR ====================
  Widget _buildLeftSidebar(
    String selfName,
    bool isDark,
    WhiteboardState state,
    AppLocalizations l10n,
  ) {
    final width = _isSidebarCollapsed ? 76.0 : 256.0;
    final onlineCount = state.peers.where((p) => p.connected).length + 1;
    final hasVoiceLive = _voice || state.peers.any((p) => !p.isMuted);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181824) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFEDF2F7),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Header
          Container(
            height: 58,
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 16 : 18,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4CF0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hub_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PeerTask',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.first_page_rounded, size: 18),
                    color: const Color(0xFF94A3B8),
                    onPressed: () => setState(() => _isSidebarCollapsed = true),
                  ),
                ],
              ],
            ),
          ),

          if (_isSidebarCollapsed)
            Center(
              child: IconButton(
                tooltip: AppLocalizations.of(context)!.expandSidebar,
                icon: const Icon(Icons.last_page_rounded, size: 20),
                onPressed: () => setState(() => _isSidebarCollapsed = false),
              ),
            ),
          const SizedBox(height: 8),

          // Menu điều hướng bên trái
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarNavItem(
                  id: 'tasks',
                  icon: Icons.view_kanban_outlined,
                  label: l10n.boardView,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _activeNavId = 'tasks';
                      _page = _BoardPage.tasks;
                    });
                  },
                ),
                _buildSidebarNavItem(
                  id: 'whiteboard',
                  icon: Icons.draw_outlined,
                  label: l10n.canvasView,
                  badgeColor: const Color(0xFF10B981),
                  badgeText: hasVoiceLive ? l10n.voiceLive : null,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _activeNavId = 'whiteboard';
                      _page = _BoardPage.canvas;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Trạng thái online & Voice Live
                if (!_isSidebarCollapsed) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF222230)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2E2E3E)
                            : const Color(0xFFEDF2F7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            l10n.onlinePeople(onlineCount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasVoiceLive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.voiceLive,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // User Profile & Language/Theme controls at bottom left
          _buildUserProfileBottom(selfName, isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required String id,
    required IconData icon,
    required String label,
    String? badgeText,
    Color? badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isActive = _activeNavId == id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: _isSidebarCollapsed ? label : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF5B4CF0) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                  ),
                  if (badgeText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            badgeColor ??
                            (isActive
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileBottom(
    String selfName,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : const Color(0xFFFAFBFD),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFEDF2F7),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: AppLocalizations.of(context)!.accountAndSettings,
        offset: const Offset(0, -180),
        onSelected: (val) {
          if (val == 'profile') {
            showDialog(
              context: context,
              builder: (_) => const EditProfileDialog(),
            );
          } else if (val == 'settings') {
            context.push('/settings');
          } else if (val == 'password') {
            showDialog(
              context: context,
              builder: (_) => const ChangePasswordDialog(),
            );
          } else if (val == 'logout') {
            ref.read(authStateProvider.notifier).logout();
            context.go('/login');
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 18),
                const SizedBox(width: 10),
                Text(l10n.profile),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, size: 18),
                const SizedBox(width: 10),
                Text(l10n.settingsTitle),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'password',
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 18),
                const SizedBox(width: 10),
                Text(l10n.changePassword),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.logout,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      name: selfName,
                      imageUrl: ref.watch(authStateProvider).user?.avatar,
                      size: 34,
                      maxInitials: 1,
                      backgroundColor: const Color(0xFF5B4CF0),
                      foregroundColor: Colors.white,
                      fontSize: 13,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selfName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WHITEBOARD CANVAS VIEW ====================
  Widget _buildWhiteboardView(
    _Scene scene,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final activePageId = _getActivePageId(scene);

    // Filter content on active page
    final pageStrokes = scene.strokes
        .where((s) => (s['pageId'] ?? 'page-1') == activePageId)
        .toList();
    final pageShapes = scene.shapes
        .where((sh) => (sh['pageId'] ?? 'page-1') == activePageId)
        .toList();
    final pageNotes = scene.notes
        .where((n) => (n['pageId'] ?? 'page-1') == activePageId)
        .toList();
    final pageTexts = scene.texts
        .where((t) => (t['pageId'] ?? 'page-1') == activePageId)
        .toList();

    return Stack(
      children: [
        // Canvas Drawing Area
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (d) => _onPanStart(d.localPosition, scene),
            onPanUpdate: (d) => _onPanUpdate(d.localPosition, scene),
            onPanEnd: (_) => _onPanEnd(scene),
            child: Container(
              color: isDark ? const Color(0xFF12121A) : const Color(0xFFF9F8FD),
              child: CustomPaint(
                painter: _WhiteboardCanvasPainter(
                  strokes: pageStrokes,
                  shapes: pageShapes,
                  notes: pageNotes,
                  texts: pageTexts,
                  livePoints: _points,
                  liveColor: _color,
                  liveWidth: _strokeWidth,
                  liveShapeType:
                      (_tool == _WhiteboardTool.rectangle ||
                          _tool == _WhiteboardTool.circle ||
                          _tool == _WhiteboardTool.arrow)
                      ? _tool.name
                      : null,
                  shapeStart: _shapeStart,
                  shapeCurrent: _shapeCurrent,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),

        // 1.3: Floating Top Canvas Toolbar (Xóa BẢN VẼ #04, Kiến trúc WebRTC Mesh và dấu +, dồn công cụ lên trước)
        Positioned(
          top: 14,
          left: 20,
          right: 20,
          child: _buildWhiteboardTopToolbar(isDark, l10n, scene),
        ),

        // ẢNH 3: Thanh phân trang sát đáy canvas (‹ Page 1 › + Add page)
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: _buildWhiteboardPaginationBar(isDark, l10n, scene),
        ),
      ],
    );
  }

  // 1.3: Top Toolbar centered and evenly spaced without title label
  Widget _buildWhiteboardTopToolbar(
    bool isDark,
    AppLocalizations l10n,
    _Scene scene,
  ) {
    return Center(
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drawing Tools
              _buildToolIcon(
                Icons.near_me_outlined,
                l10n.toolSelect,
                _WhiteboardTool.select,
              ),
              _buildToolIcon(
                Icons.pan_tool_outlined,
                l10n.toolHand,
                _WhiteboardTool.hand,
              ),
              _buildToolIcon(
                Icons.edit_outlined,
                l10n.toolPen,
                _WhiteboardTool.pen,
              ),
              _buildToolIcon(
                Icons.cleaning_services_outlined,
                l10n.toolEraser,
                _WhiteboardTool.eraser,
              ),
              _buildToolIcon(
                Icons.crop_square_rounded,
                l10n.toolRectangle,
                _WhiteboardTool.rectangle,
              ),
              _buildToolIcon(
                Icons.circle_outlined,
                l10n.toolCircle,
                _WhiteboardTool.circle,
              ),
              _buildToolIcon(
                Icons.arrow_forward_rounded,
                l10n.toolArrow,
                _WhiteboardTool.arrow,
              ),
              _buildToolIcon(
                Icons.sticky_note_2_outlined,
                l10n.toolStickyNote,
                _WhiteboardTool.note,
              ),
              _buildToolIcon(
                Icons.title_rounded,
                l10n.toolText,
                _WhiteboardTool.text,
              ),
              _buildToolIcon(
                Icons.view_kanban_outlined,
                l10n.toolKanban,
                _WhiteboardTool.kanban,
                isKanbanBtn: true,
              ),
              _buildToolbarVerticalDivider(isDark),

              // Undo / Clear all
              Tooltip(
                message: l10n.undoTooltip,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.undo_rounded, size: 17),
                  onPressed: () => _undo(scene),
                ),
              ),
              Tooltip(
                message: l10n.clearAll,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  onPressed: () => _confirmClearAll(l10n, scene),
                ),
              ),
              _buildToolbarVerticalDivider(isDark),

              // Color Palette (5 colors)
              for (final swatch in const [
                Color(0xFF5B4CF0), // Purple
                Color(0xFF10B981), // Mint
                Color(0xFFF59E0B), // Yellow
                Color(0xFFEF4444), // Coral/Red
                Color(0xFF1E293B), // Black
              ]) ...[
                GestureDetector(
                  onTap: () => setState(() => _color = swatch),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == swatch
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: _color == swatch
                          ? [
                              BoxShadow(
                                color: swatch.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
              _buildToolbarVerticalDivider(isDark),

              // Stroke Widths (1px, 2px, 4px)
              _buildStrokeWidthBtn(1.0, '1px'),
              _buildStrokeWidthBtn(2.0, '2px'),
              _buildStrokeWidthBtn(4.0, '4px'),
            ],
          ),
        ),
      ),
    );
  }

  // ẢNH 3: Thanh phân trang đáy canvas (‹ Page 1 › + Add page)
  Widget _buildWhiteboardPaginationBar(
    bool isDark,
    AppLocalizations l10n,
    _Scene scene,
  ) {
    final pages = scene.pages;
    final totalPages = pages.length;
    final safeIndex = _currentPageIndex.clamp(0, totalPages - 1);
    final currentPage = pages[safeIndex];
    final pageName =
        currentPage['name'] as String? ??
        '${l10n.pageTitlePrefix} ${safeIndex + 1}';

    return Center(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous Page Button ‹
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context)!.previousPage,
                onPressed: safeIndex > 0
                    ? () => setState(() => _currentPageIndex = safeIndex - 1)
                    : null,
              ),
              const SizedBox(width: 4),

              // Page Name with menu to jump or rename
              PopupMenuButton<String>(
                tooltip: AppLocalizations.of(context)!.pageListRename,
                onSelected: (val) {
                  if (val == 'rename') {
                    _renameCurrentPage(l10n, scene);
                  } else if (val == 'delete') {
                    _confirmDeleteCurrentPage(l10n, scene);
                  } else if (val.startsWith('jump_')) {
                    final idx =
                        int.tryParse(val.replaceFirst('jump_', '')) ?? 0;
                    setState(() => _currentPageIndex = idx);
                  }
                },
                itemBuilder: (ctx) => [
                  for (var i = 0; i < pages.length; i++)
                    PopupMenuItem(
                      value: 'jump_$i',
                      child: Row(
                        children: [
                          Icon(
                            i == safeIndex
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: i == safeIndex
                                ? const Color(0xFF5B4CF0)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pages[i]['name'] as String? ??
                                '${l10n.pageTitlePrefix} ${i + 1}',
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.renamePage),
                      ],
                    ),
                  ),
                  if (totalPages > 1)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.deletePage,
                            style: const TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pageName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Next Page Button ›
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context)!.nextPage,
                onPressed: safeIndex < totalPages - 1
                    ? () => setState(() => _currentPageIndex = safeIndex + 1)
                    : null,
              ),
              const SizedBox(width: 6),

              // + Add page Button
              FilledButton.tonal(
                onPressed: () => _addNewPage(l10n, scene),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF3E8FF),
                  foregroundColor: const Color(0xFF7C3AED),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      l10n.addPage,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolIcon(
    IconData icon,
    String tooltip,
    _WhiteboardTool toolType, {
    bool isKanbanBtn = false,
  }) {
    final isSelected = _tool == toolType;

    if (isKanbanBtn) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.tonal(
          onPressed: () {
            setState(() => _tool = toolType);
            _openTask(null);
          },
          style: FilledButton.styleFrom(
            backgroundColor: isSelected
                ? const Color(0xFF5B4CF0)
                : const Color(0xFFF1F5F9),
            foregroundColor: isSelected
                ? Colors.white
                : const Color(0xFF5B4CF0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.addKanbanCard,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _tool = toolType),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B4CF0) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeWidthBtn(double w, String label) {
    final isSelected = _strokeWidth == w;
    return GestureDetector(
      onTap: () => setState(() => _strokeWidth = w),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B4CF0).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B4CF0) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? const Color(0xFF5B4CF0)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarVerticalDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      width: 1,
      height: 20,
      color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
    );
  }

  // ==================== RIGHT VOICE MEETING PANEL ====================
  // 1.2: Appears on both Kanban and Whiteboard screens
  Widget _buildRightVoicePanel(
    String selfName,
    bool isDark,
    _Scene scene,
    WhiteboardState state,
    AppLocalizations l10n, {
    bool isDrawer = false,
  }) {
    final membersCount = 1 + state.peers.length;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181824) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFEDF2F7),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header starts directly from Room Members count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.roomMembersTitle(membersCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isDrawer
                      ? AppLocalizations.of(context)!.closePanel
                      : AppLocalizations.of(context)!.collapsePanel,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isDrawer
                        ? Icons.close_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    if (isDrawer) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _isVoicePanelCollapsed = true);
                    }
                  },
                ),
              ],
            ),
          ),

          // Real Member List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Current User (Self)
                _buildVoiceMemberRow(
                  name: selfName,
                  roleBadge: AppLocalizations.of(context)!.hostBadge,
                  subtitle: _voice
                      ? (state.localSpeaking
                            ? l10n.speaking
                            : AppLocalizations.of(context)!.micOn)
                      : AppLocalizations.of(context)!.micOff,
                  isSpeaking: _voice && state.localSpeaking,
                  isMuted: !_voice,
                  avatarUrl: ref.watch(authStateProvider).user?.avatar,
                  avatarColor: const Color(0xFF5B4CF0),
                  isDark: isDark,
                ),

                // Connected Peers
                for (final peer in state.peers) ...[
                  _buildPeerVoiceRow(peer, isDark),
                ],
                const SizedBox(height: 14),

                // Ghi chú thảo luận nhanh
                _buildQuickDiscussionNotes(scene, isDark, l10n),
              ],
            ),
          ),

          // 1.1: Call Controls (No toasts on mic/speaker click)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A2A3C)
                      : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mic Button
                IconButton(
                  tooltip: _voice
                      ? AppLocalizations.of(context)!.muteMic
                      : AppLocalizations.of(context)!.unmuteMic,
                  style: IconButton.styleFrom(
                    backgroundColor: _voice
                        ? const Color(0xFF5B4CF0)
                        : const Color(0xFFF1F5F9),
                    foregroundColor: _voice
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                  icon: Icon(
                    _voice ? Icons.mic_rounded : Icons.mic_off_rounded,
                    size: 18,
                  ),
                  onPressed: _toggleMic,
                ),
                // Speaker Button
                IconButton(
                  tooltip: _speakerOn
                      ? AppLocalizations.of(context)!.muteAudio
                      : AppLocalizations.of(context)!.unmuteAudio,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  icon: Icon(
                    _speakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 18,
                  ),
                  onPressed: _toggleSpeaker,
                ),
                // Distinct Red End Call Button
                IconButton(
                  tooltip: l10n.leaveRoom,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                  icon: const Icon(Icons.call_end_rounded, size: 18),
                  onPressed: () => _confirmLeaveCall(l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerVoiceRow(dynamic peer, bool isDark) {
    String peerName = AppLocalizations.of(context)!.member;
    final peerUserId = peer.userId as String?;
    final match = _members.firstWhere(
      (m) => (m['user_id'] ?? m['id']) == peerUserId,
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty && match['name'] != null) {
      peerName = match['name'] as String;
    } else if (peer.socketId != null && (peer.socketId as String).isNotEmpty) {
      peerName =
          'Node ${(peer.socketId as String).substring(0, math.min(4, (peer.socketId as String).length))}';
    }

    final isMuted = peer.isMuted == true;
    final isSpeaking = peer.isSpeaking == true && !isMuted;

    return _buildVoiceMemberRow(
      name: peerName,
      roleBadge: AppLocalizations.of(context)!.peerBadge,
      subtitle: isMuted
          ? AppLocalizations.of(context)!.micOff
          : (isSpeaking
                ? AppLocalizations.of(context)!.speaking
                : AppLocalizations.of(context)!.listening),
      isSpeaking: isSpeaking,
      isMuted: isMuted,
      avatarUrl: (peer.avatar as String?) ?? match['avatar'] as String?,
      avatarColor: const Color(0xFF8B5CF6),
      isDark: isDark,
    );
  }

  Widget _buildVoiceMemberRow({
    required String name,
    required String roleBadge,
    required String subtitle,
    required bool isSpeaking,
    required bool isMuted,
    String? avatarUrl,
    required Color avatarColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20202E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: name,
            imageUrl: avatarUrl,
            size: 30,
            maxInitials: 1,
            backgroundColor: avatarColor,
            foregroundColor: Colors.white,
            fontSize: 11,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4CF0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleBadge,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B4CF0),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (isSpeaking) ...[
            AnimatedBuilder(
              animation: _waveAnimController,
              builder: (context, _) {
                final v = _waveAnimController.value;
                return Row(
                  children: [
                    Container(
                      width: 2.5,
                      height: 6 + 10 * v,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4CF0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 2.5,
                      height: 16 - 10 * v,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4CF0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 2.5,
                      height: 8 + 8 * v,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4CF0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
              size: 16,
              color: isMuted
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
          ],
        ],
      ),
    );
  }

  void _syncWaveAnimation(bool anyoneSpeaking) {
    if (anyoneSpeaking && !_waveAnimController.isAnimating) {
      _waveAnimController.repeat(reverse: true);
    } else if (!anyoneSpeaking && _waveAnimController.isAnimating) {
      _waveAnimController.stop();
    }
  }

  void _scrollNotesToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_notesScroll.hasClients) return;
      _notesScroll.animateTo(
        _notesScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  // Quick discussion notes widget
  Widget _buildQuickDiscussionNotes(
    _Scene scene,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final user = ref.watch(authStateProvider).user;
    final currentUserId = user?.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222230) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.quickDiscussionNotes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Notes List
          if (scene.discussionNotes.length != _shownNoteCount) ...[
            Builder(
              builder: (_) {
                _shownNoteCount = scene.discussionNotes.length;
                _scrollNotesToEnd();
                return const SizedBox.shrink();
              },
            ),
          ],
          if (scene.discussionNotes.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.noDiscussionNotes,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ),
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                controller: _notesScroll,
                shrinkWrap: true,
                itemCount: scene.discussionNotes.length,
                itemBuilder: (ctx, i) {
                  final note = scene.discussionNotes[i];
                  final noteId = note['id'] as String;
                  final text = note['text'] as String? ?? '';
                  final author =
                      note['authorName'] as String? ??
                      AppLocalizations.of(context)!.member;
                  final authorId = note['authorId'] as String?;
                  final canDelete =
                      authorId == currentUserId || authorId == 'self';
                  final authorAvatar = canDelete
                      ? ref.watch(authStateProvider).user?.avatar
                      : _members
                                .where(
                                  (m) => (m['user_id'] ?? m['id']) == authorId,
                                )
                                .firstOrNull?['avatar']
                            as String?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2E2E3E)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            UserAvatar(
                              name: author,
                              imageUrl: authorAvatar,
                              size: 16,
                              maxInitials: 1,
                              backgroundColor: const Color(0xFF5B4CF0),
                              foregroundColor: Colors.white,
                              fontSize: 8,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                author,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (canDelete)
                              InkWell(
                                onTap: () => _deleteDiscussionNote(noteId),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text,
                          style: const TextStyle(fontSize: 11.5, height: 1.3),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Input textarea & Send button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter):
                        _postDiscussionNote,
                    const SingleActivator(LogicalKeyboardKey.numpadEnter):
                        _postDiscussionNote,
                  },
                  child: TextField(
                    controller: _discussionNoteController,
                    focusNode: _noteFocus,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: l10n.typeDiscussionNote,
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A24)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF2E2E3E)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _postDiscussionNote(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _postDiscussionNote,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4CF0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  l10n.post,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== KANBAN BOARD VIEW (Image 2) ====================
  Widget _buildKanbanView(_Scene scene, bool isDark, AppLocalizations l10n) {
    if (_tasksLoading && scene.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    return _buildKanbanColumnsArea(scene, isDark, l10n);
  }

  // ==================== KANBAN COLUMNS ====================
  Widget _buildKanbanColumnsArea(
    _Scene scene,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final allFiltered = _filterTasks(scene.tasks);

    final todoTasks = allFiltered.where((t) => t['status'] == 'todo').toList();
    final doingTasks = allFiltered
        .where((t) => t['status'] == 'doing')
        .toList();
    final reviewTasks = allFiltered
        .where((t) => t['status'] == 'review')
        .toList();
    final doneTasks = allFiltered.where((t) => t['status'] == 'done').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Minimum width per column is 280px to avoid squeezing on tablet / smaller screens
        const totalGaps = 42.0; // 14 * 3
        final availableWidth = constraints.maxWidth - 32; // 16 * 2 padding
        final colWidth = math.max(280.0, (availableWidth - totalGaps) / 4);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: constraints.maxHeight - 32,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: colWidth,
                  child: _buildSingleKanbanColumn(
                    status: 'todo',
                    title: l10n.columnTodo,
                    countBadge: '${todoTasks.length}',
                    accentColor: const Color(0xFF5B4CF0),
                    tasks: todoTasks,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: colWidth,
                  child: _buildSingleKanbanColumn(
                    status: 'doing',
                    title: l10n.columnDoing,
                    countBadge: '${doingTasks.length}',
                    accentColor: const Color(0xFFF59E0B),
                    tasks: doingTasks,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: colWidth,
                  child: _buildSingleKanbanColumn(
                    status: 'review',
                    title: l10n.columnReview,
                    countBadge: '${reviewTasks.length}',
                    accentColor: const Color(0xFF3B82F6),
                    tasks: reviewTasks,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: colWidth,
                  child: _buildSingleKanbanColumn(
                    status: 'done',
                    title: l10n.columnDone,
                    countBadge: '${doneTasks.length}',
                    accentColor: const Color(0xFF10B981),
                    tasks: doneTasks,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleKanbanColumn({
    required String status,
    required String title,
    required String countBadge,
    required Color accentColor,
    required List<Map<String, dynamic>> tasks,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _moveTask(d.data, status),
      builder: (context, candidate, rejected) {
        return Container(
          decoration: BoxDecoration(
            color: candidate.isNotEmpty
                ? const Color(0xFF5B4CF0).withValues(alpha: 0.08)
                : (isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: candidate.isNotEmpty
                  ? const Color(0xFF5B4CF0)
                  : (isDark
                        ? const Color(0xFF2E2E3E)
                        : const Color(0xFFE2E8F0)),
              width: candidate.isNotEmpty ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Column Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        countBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.addNewCard,
                      onPressed: () => _openTask(null, status: status),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Scrollable Task Cards List
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noTasks,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final taskId = task['id'] as String? ?? 't-$index';

                          return Draggable<String>(
                            data: taskId,
                            feedback: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 260,
                                ),
                                child: _buildKanbanTaskCard(task, isDark, l10n),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: _buildKanbanTaskCard(task, isDark, l10n),
                            ),
                            child: _buildKanbanTaskCard(task, isDark, l10n),
                          );
                        },
                      ),
              ),

              // "+ Thêm thẻ mới" button at bottom
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () => _openTask(null, status: status),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Color(0xFF5B4CF0),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.addNewCard,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5B4CF0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== TASK CARD (2.2: Hiển thị tên người phụ trách thật, không hiện UUID) ====================
  Widget _buildKanbanTaskCard(
    Map<String, dynamic> task,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final title =
        task['title'] as String? ?? AppLocalizations.of(context)!.newTaskTitle;
    final desc = _getCleanDescription(task['description'] as String?);
    final checklist = _checklistProgress(task['description'] as String?);
    final attachmentCount = (task['attachments'] as List?)?.length ?? 0;
    final priority = task['priority'] as String? ?? 'medium';
    final labels = List<String>.from(task['labels'] ?? []);
    final startDate = _getTaskStartDate(task);
    DateTime? dueDate;
    if (task['deadline'] != null) {
      dueDate = DateTime.tryParse(task['deadline'].toString());
    }

    // 2.2: Resolve assignees names properly without printing UUIDs
    final assigneeIds = List<String>.from(task['assignees'] ?? []);
    String assigneeDisplay = l10n.unassigned;
    String fullAssigneeTooltip = '';
    String? firstAssigneeName;
    String? firstAssigneeAvatar;

    if (assigneeIds.isNotEmpty) {
      final names = assigneeIds
          .map((id) => _resolveAssigneeName(id, task, l10n))
          .toList();
      firstAssigneeName = names.first;
      firstAssigneeAvatar = _resolveAssigneeAvatar(assigneeIds.first, task);
      fullAssigneeTooltip = names.join(', ');
      if (names.length <= 2) {
        assigneeDisplay = names.join(', ');
      } else {
        assigneeDisplay = '${names[0]}, ${names[1]} +${names.length - 2}';
      }
    }

    // Format dates dd/MM/yyyy
    String dateDisplay = l10n.noDueDate;
    if (startDate != null && dueDate != null) {
      dateDisplay = '${_formatDate(startDate)} → ${_formatDate(dueDate)}';
    } else if (dueDate != null) {
      dateDisplay = '${l10n.dateTo} ${_formatDate(dueDate)}';
    } else if (startDate != null) {
      dateDisplay = '${l10n.dateFrom} ${_formatDate(startDate)}';
    }

    return GestureDetector(
      onTap: () => _openTask(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242436) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF33334A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Purple dot + Task Title (Ví dụ: TASK_01)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B4CF0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Chip độ ưu tiên (Cờ + chữ: Khẩn cấp, Cao, Trung bình, Thấp)
            _buildPriorityBadge(priority, l10n),
            const SizedBox(height: 8),

            // Row 3: Các nhãn bo tròn nhiều màu (Web, Backend...)
            if (labels.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: labels.map((lbl) => _buildLabelChip(lbl)).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Row 4: Người phụ trách (Icon người + tên)
            Tooltip(
              message: fullAssigneeTooltip.isNotEmpty
                  ? fullAssigneeTooltip
                  : assigneeDisplay,
              child: Row(
                children: [
                  if (firstAssigneeName != null)
                    UserAvatar(
                      name: firstAssigneeName,
                      imageUrl: firstAssigneeAvatar,
                      size: 18,
                      maxInitials: 1,
                      fontSize: 9,
                    )
                  else
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assigneeDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Row 5: Ngày (Icon lịch + start_date -> due_date dạng dd/MM/yyyy)
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            if (checklist.total > 0 || attachmentCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (checklist.total > 0) ...[
                    Icon(
                      Icons.checklist_rounded,
                      size: 15,
                      color: checklist.done == checklist.total
                          ? const Color(0xFF10B981)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${checklist.done}/${checklist.total}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: checklist.done == checklist.total
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (attachmentCount > 0) ...[
                    const Icon(
                      Icons.image_outlined,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$attachmentCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Row 6: Mô tả ngắn gọn
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Widget _buildPriorityBadge(String priority, AppLocalizations l10n) {
    Color bg;
    Color fg;
    String label;

    switch (priority) {
      case 'urgent':
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFE11D48);
        label = l10n.priorityBadgeUrgent;
        break;
      case 'high':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFEA580C);
        label = l10n.priorityBadgeHigh;
        break;
      case 'low':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = l10n.priorityBadgeLow;
        break;
      case 'medium':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = l10n.priorityBadgeMedium;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 13, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);

    if (label.toLowerCase().contains('backend')) {
      bg = const Color(0xFFF5F3FF);
      fg = const Color(0xFF6D28D9);
    } else if (label.toLowerCase().contains('design') ||
        label.toLowerCase().contains('ui')) {
      bg = const Color(0xFFFDF2F8);
      fg = const Color(0xFFBE185D);
    } else if (label.toLowerCase().contains('frontend')) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
    } else if (label.toLowerCase().contains('sync') ||
        label.toLowerCase().contains('p2p')) {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ==================== SCENE & WHITEBOARD PAINTER ====================

class _Scene {
  final List<Map<String, dynamic>> strokes;
  final List<Map<String, dynamic>> shapes;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> texts;
  final List<Map<String, dynamic>> discussionNotes;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> pages;

  const _Scene({
    required this.strokes,
    required this.shapes,
    required this.notes,
    required this.texts,
    required this.discussionNotes,
    required this.tasks,
    required this.pages,
  });
}

class _WhiteboardCanvasPainter extends CustomPainter {
  final List<Map<String, dynamic>> strokes;
  final List<Map<String, dynamic>> shapes;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> texts;
  final List<Offset> livePoints;
  final Color liveColor;
  final double liveWidth;
  final String? liveShapeType;
  final Offset? shapeStart;
  final Offset? shapeCurrent;
  final bool isDark;

  const _WhiteboardCanvasPainter({
    required this.strokes,
    required this.shapes,
    required this.notes,
    required this.texts,
    required this.livePoints,
    required this.liveColor,
    required this.liveWidth,
    this.liveShapeType,
    this.shapeStart,
    this.shapeCurrent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid dot background
    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFCBD5E1))
          .withValues(alpha: 0.4);
    const gap = 28.0;
    for (var y = 0.0; y < size.height; y += gap) {
      for (var x = 0.0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 0.8, gridPaint);
      }
    }

    // Render strokes
    for (final stroke in strokes) {
      final raw = stroke['points'] as List?;
      if (raw == null || raw.length < 4) continue;
      final path = Path();
      path.moveTo((raw[0] as num).toDouble(), (raw[1] as num).toDouble());
      for (var i = 2; i < raw.length - 1; i += 2) {
        path.lineTo((raw[i] as num).toDouble(), (raw[i + 1] as num).toDouble());
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Color((stroke['color'] as num?)?.toInt() ?? 0xFF5B4CF0)
          ..strokeWidth = (stroke['width'] as num?)?.toDouble() ?? 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Render shapes (rectangle, circle, arrow)
    for (final shape in shapes) {
      _drawShape(
        canvas,
        shape['shapeType'] as String? ?? 'rectangle',
        Offset(
          (shape['startX'] as num).toDouble(),
          (shape['startY'] as num).toDouble(),
        ),
        Offset(
          (shape['endX'] as num).toDouble(),
          (shape['endY'] as num).toDouble(),
        ),
        Color((shape['color'] as num?)?.toInt() ?? 0xFF5B4CF0),
        (shape['width'] as num?)?.toDouble() ?? 2.0,
      );
    }

    // Render text items
    for (final t in texts) {
      final text = t['text'] as String? ?? '';
      final x = (t['x'] as num?)?.toDouble() ?? 50.0;
      final y = (t['y'] as num?)?.toDouble() ?? 50.0;
      final c = Color((t['color'] as num?)?.toInt() ?? 0xFF1E293B);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x, y));
    }

    // Render sticky notes
    for (final n in notes) {
      final text = n['text'] as String? ?? '';
      final x = (n['x'] as num?)?.toDouble() ?? 100.0;
      final y = (n['y'] as num?)?.toDouble() ?? 100.0;

      final rect = Rect.fromLTWH(x, y, 160, 100);
      final notePaint = Paint()..color = const Color(0xFFFEF3C7);
      final borderPaint = Paint()
        ..color = const Color(0xFFFDE68A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        notePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF78350F),
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 4,
      )..layout(maxWidth: 140);
      textPainter.paint(canvas, Offset(x + 10, y + 10));
    }

    // Render live stroke
    if (livePoints.length > 1) {
      final livePath = Path();
      livePath.moveTo(livePoints[0].dx, livePoints[0].dy);
      for (var i = 1; i < livePoints.length; i++) {
        livePath.lineTo(livePoints[i].dx, livePoints[i].dy);
      }
      canvas.drawPath(
        livePath,
        Paint()
          ..color = liveColor
          ..strokeWidth = liveWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Render live shape preview
    if (liveShapeType != null && shapeStart != null && shapeCurrent != null) {
      _drawShape(
        canvas,
        liveShapeType!,
        shapeStart!,
        shapeCurrent!,
        liveColor,
        liveWidth,
      );
    }
  }

  void _drawShape(
    Canvas canvas,
    String type,
    Offset start,
    Offset end,
    Color color,
    double width,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (type == 'rectangle') {
      canvas.drawRect(Rect.fromPoints(start, end), paint);
    } else if (type == 'circle') {
      final rect = Rect.fromPoints(start, end);
      canvas.drawOval(rect, paint);
    } else if (type == 'arrow') {
      canvas.drawLine(start, end, paint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      const arrowSize = 14.0;
      final arrowAngle = math.pi / 6;

      final p1 = Offset(
        end.dx - arrowSize * math.cos(angle - arrowAngle),
        end.dy - arrowSize * math.sin(angle - arrowAngle),
      );
      final p2 = Offset(
        end.dx - arrowSize * math.cos(angle + arrowAngle),
        end.dy - arrowSize * math.sin(angle + arrowAngle),
      );
      final arrowPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(
        arrowPath,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardCanvasPainter oldDelegate) => true;
}
