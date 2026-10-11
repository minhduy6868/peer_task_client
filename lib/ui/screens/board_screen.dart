import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../../models/operation/operation.dart';
import '../../models/peer/peer.dart';
import '../../models/task_model.dart';
import '../../providers/app_providers.dart';
import '../../utils/error_display.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_toast.dart';
import '../widgets/task_dialog.dart';

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.isNotEmpty) {
    final trimmed = value.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return [trimmed];
  }
  return const [];
}

({
  String? cleanDescription,
  int checklistTotal,
  int checklistDone,
}) _parseCardDescription(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return (cleanDescription: null, checklistTotal: 0, checklistDone: 0);
  }
  int total = 0;
  int done = 0;
  final notesLines = <String>[];
  final lines = raw.replaceAll('\r', '').split('\n');
  final checkRegex = RegExp(r'^\s*-\s*\[([ xX])\]\s*(.*)$');

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('<!--') && trimmed.endsWith('-->')) {
      continue;
    }
    final match = checkRegex.firstMatch(line);
    if (match != null) {
      total++;
      if (match.group(1)!.toLowerCase() == 'x') {
        done++;
      }
      continue;
    }
    if (trimmed.isNotEmpty) {
      notesLines.add(trimmed);
    }
  }

  final notes = notesLines.join(' ').trim();
  return (
    cleanDescription: notes.isEmpty ? null : notes,
    checklistTotal: total,
    checklistDone: done,
  );
}

enum _BoardPage { tasks, canvas }

enum _DrawTool { pen, eraser, text, hand }

/// Trello board for tasks, Canva page for drawing.
class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  _BoardPage _page = _BoardPage.tasks;
  _DrawTool _tool = _DrawTool.pen;
  Color _color = AppColors.primaryDark;
  double _width = 3;
  final double _textSize = 20;
  bool _voice = false;
  String _canvasPageId = 'default';

  final _textController = TextEditingController();
  final Map<String, TextEditingController> _quickAdd = {
    'todo': TextEditingController(),
    'doing': TextEditingController(),
    'done': TextEditingController(),
  };

  List<Offset> _points = [];
  String? _strokeId;
  bool _isDrawing = false;
  Offset? _currentDrawPoint;
  List<Map<String, dynamic>> _members = [];
  String? _currentBoardId;

  @override
  void initState() {
    super.initState();
    _currentBoardId = widget.boardId;
    _initBoard();
  }

  @override
  void didUpdateWidget(BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boardId == widget.boardId) return;
    ref.read(whiteboardProvider.notifier).disconnect();
    _currentBoardId = widget.boardId;
    _members = [];
    _initBoard();
  }

  @override
  void dispose() {
    final boardId = _currentBoardId;
    if (boardId != null) {
      ref.read(whiteboardProvider.notifier).saveDraft(boardId: boardId);
    }
    _textController.dispose();
    for (final controller in _quickAdd.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initBoard() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    ref.read(currentBoardIdProvider.notifier).state = widget.boardId;
    try {
      final restored = await ref
          .read(whiteboardProvider.notifier)
          .connectToBoard(widget.boardId);
      if (mounted && restored > 0) {
        AppToast.show(
          context,
          message: AppLocalizations.of(context)!.draftRestored,
          type: ToastType.success,
        );
      }
    } catch (e) {
      await ref.read(whiteboardProvider.notifier).restoreDraft(widget.boardId);
      if (mounted) context.showErrorSnackBar(e);
    }
    if (!mounted) return;
    await _loadMembers();
    await _loadTasks();
  }

  Future<void> _loadMembers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final board = await api.getBoard(widget.boardId);
      List<Map<String, dynamic>> rows = [];
      try {
        rows = await api.getWorkspaceMembers(board.workspaceId);
      } catch (e) {
        debugPrint('Workspace members failed: $e');
      }
      if (rows.isEmpty) {
        rows = await api.getBoardMembers(widget.boardId);
      }
      final seen = <String>{};
      final members = <Map<String, dynamic>>[];
      for (final member in rows) {
        final id = (member['user_id'] ?? member['id'])?.toString();
        if (id == null || id.isEmpty || !seen.add(id)) continue;
        members.add({
          'id': id,
          'name': member['name'],
          'email': member['email'],
        });
      }
      final user = ref.read(authStateProvider).user;
      if (user != null && seen.add(user.id)) {
        members.insert(0, {
          'id': user.id,
          'name': user.name,
          'email': user.email,
        });
      }
      if (!mounted) return;
      setState(() => _members = members);
    } catch (e) {
      debugPrint('Board members failed: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await ref.read(apiServiceProvider).getBoardTasks(widget.boardId);
      final notifier = ref.read(whiteboardProvider.notifier);
      for (final task in tasks) {
        notifier.receiveOperation(Operation(
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
              'assignees': task['assignees'] ?? [],
              'assignee_list': task['assignee_list'] ?? [],
              'deadline': task['deadline'],
              'labels': task['labels'],
              'position': task['position'],
              'created_by': task['created_by'],
              'creator_name': task['creator_name'],
            },
          },
        ));
      }
    } catch (e) {
      debugPrint('Load tasks failed: $e');
    }
  }

  String _displayName() {
    final user = ref.read(authStateProvider).user;
    if (user?.name?.isNotEmpty == true) return user!.name!;
    return user?.email ?? 'Unknown';
  }

  Future<void> _createTask({
    required String title,
    String status = 'todo',
    String? description,
    String priority = 'medium',
    DateTime? deadline,
    List<String>? assignees,
    List<String>? labels,
    double? estimatedHours,
  }) async {
    try {
      final response = await ref.read(apiServiceProvider).createTask(
            boardId: widget.boardId,
            title: title,
            description: description,
            status: status,
            priority: priority,
            deadline: deadline,
            assignees: assignees,
            labels: labels,
            estimatedHours: estimatedHours,
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
          },
        },
        shouldSaveBackend: false,
      );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  Future<void> _moveTask(String taskId, String status) async {
    try {
      final response = await ref.read(apiServiceProvider).moveTask(
            taskId: taskId,
            status: status,
            boardId: widget.boardId,
          );
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.updateObject,
        {'id': taskId, 'type': 'task', 'data': response},
        shouldSaveBackend: false,
      );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.showConfirm(
      context,
      title: l10n.deleteTask,
      message: l10n.deleteTaskConfirm,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
      isDanger: true,
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiServiceProvider).deleteTask(taskId);
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.deleteObject,
        {'id': taskId, 'type': 'task'},
        shouldSaveBackend: false,
      );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  Future<void> _openTask(Map<String, dynamic>? existing, {String status = 'todo'}) async {
    if (_members.isEmpty) await _loadMembers();
    TaskModel? model;
    if (existing != null) {
      model = TaskModel(
        id: existing['id'] as String? ?? '',
        boardId: widget.boardId,
        title: existing['title'] as String? ?? '',
        description: existing['description'] as String?,
        status: existing['status'] as String? ?? status,
        priority: existing['priority'] as String? ?? 'medium',
        assignees: _stringList(existing['assignees']),
        assigneeList: const [],
        labels: _stringList(existing['labels']),
        deadline: existing['deadline'] != null
            ? DateTime.tryParse(existing['deadline'].toString())
            : null,
        position: (existing['position'] as num?)?.toInt() ?? 0,
        createdBy: existing['created_by'] as String? ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaskDialog(
        existingTask: model,
        initialStatus: status,
        boardMembers: _members,
        onDelete: existing == null ? null : () => _deleteTask(existing['id'] as String),
        onSave: ({
          required String title,
          String? description,
          required String priority,
          required String status,
          DateTime? deadline,
          List<String>? assignees,
          List<String>? labels,
          double? estimatedHours,
        }) async {
          if (existing == null) {
            await _createTask(
              title: title,
              description: description,
              status: status,
              priority: priority,
              deadline: deadline,
              assignees: assignees,
              labels: labels,
              estimatedHours: estimatedHours,
            );
            return;
          }
          final taskId = existing['id'] as String;
          try {
            final response = await ref.read(apiServiceProvider).updateTask(
                  taskId: taskId,
                  title: title,
                  description: description,
                  assignees: assignees ?? [],
                  priority: priority,
                  status: status,
                  deadline: deadline,
                  labels: labels ?? [],
                  estimatedHours: estimatedHours,
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
                  'status': status,
                  'priority': priority,
                  'assignees': assignees ?? _stringList(response['assignees']),
                  'labels': labels ?? _stringList(response['labels']),
                  'deadline': deadline?.toIso8601String() ?? response['deadline'],
                },
              },
              shouldSaveBackend: false,
            );
          } catch (e) {
            if (mounted && context.mounted) context.showErrorSnackBar(e);
          }
        },
      ),
    );
  }

  void _panStart(Offset point) {
    if (_tool == _DrawTool.text || _tool == _DrawTool.hand) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final eraser = _tool == _DrawTool.eraser;
    _strokeId = 'stroke-$now';
    _points = [point];
    setState(() {
      _isDrawing = true;
      _currentDrawPoint = point;
    });
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.createObject,
      {
        'id': _strokeId,
        'type': 'stroke',
        'data': _strokeData(eraser),
      },
      shouldSaveBackend: true,
    );
    _broadcastCursor(point, drawing: true);
  }

  void _panUpdate(Offset point) {
    if (_strokeId == null || _tool == _DrawTool.text) return;
    setState(() {
      _points.add(point);
      _currentDrawPoint = point;
    });
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.updateObject,
      {
        'id': _strokeId,
        'type': 'stroke',
        'data': _strokeData(_tool == _DrawTool.eraser),
      },
      shouldSaveBackend: false,
    );
    _broadcastCursor(point, drawing: true);
  }

  void _panEnd() {
    if (_strokeId == null) return;
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.updateObject,
      {
        'id': _strokeId,
        'type': 'stroke',
        'data': _strokeData(_tool == _DrawTool.eraser),
      },
      shouldSaveBackend: true,
    );
    _broadcastCursor(null, drawing: false);
    setState(() {
      _strokeId = null;
      _points = [];
      _isDrawing = false;
      _currentDrawPoint = null;
    });
  }

  void _broadcastCursor(Offset? point, {required bool drawing}) {
    final user = ref.read(authStateProvider).user;
    final uId = user?.id ?? 'unknown';
    final uName = _displayName();
    if (!drawing) {
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.deleteObject,
        {
          'id': 'cursor-$uId',
          'type': 'cursor',
        },
        shouldSaveBackend: false,
      );
      return;
    }
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.updateObject,
      {
        'id': 'cursor-$uId',
        'type': 'cursor',
        'data': {
          'userId': uId,
          'userName': uName,
          'x': point?.dx ?? 0,
          'y': point?.dy ?? 0,
          'drawing': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'pageId': _activePageId(),
        },
      },
      shouldSaveBackend: false,
    );
  }

  Map<String, dynamic> _strokeData(bool eraser) {
    final paint = eraser ? Colors.white : _color;
    final currentUser = ref.read(authStateProvider).user;
    final uId = currentUser?.id ?? 'unknown';
    final uName = _displayName();
    return {
      'points': _points.expand((p) => [p.dx, p.dy]).toList(),
      'color': paint.toARGB32(),
      'width': eraser ? _width * 4 : _width,
      'actor': uId,
      'actorName': uName,
      'userId': uId,
      'userName': uName,
      'isEraser': eraser,
      'pageId': _activePageId(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _addText(Offset position) async {
    _textController.clear();
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addText),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.enterText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.addText)),
        ],
      ),
    );
    if (ok != true || _textController.text.trim().isEmpty) return;
    final id = 'text-${DateTime.now().millisecondsSinceEpoch}';
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.createObject,
      {
        'id': id,
        'type': 'text',
        'data': {
          'text': _textController.text.trim(),
          'position': [position.dx, position.dy],
          'color': _color.toARGB32(),
          'fontSize': _textSize,
          'actorName': _displayName(),
          'pageId': _activePageId(),
        },
      },
      shouldSaveBackend: true,
    );
  }

  Future<void> _toggleVoice() async {
    if (_voice) {
      ref.read(whiteboardProvider.notifier).webrtc?.stopAudioStream();
      ref.read(whiteboardProvider.notifier).updateMicStatus(true);
      setState(() => _voice = false);
      return;
    }
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }
    final ok = await ref.read(whiteboardProvider.notifier).webrtc?.startAudioStream() ?? false;
    if (!ok) {
      if (mounted) context.showErrorSnackBar('Microphone unavailable');
      return;
    }
    ref.read(whiteboardProvider.notifier).updateMicStatus(false);
    setState(() => _voice = true);
  }

  void _leave() {
    final board = ref.read(currentBoardProvider).value;
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (board != null) {
      context.go('/workspace/${board.workspaceId}/boards');
    } else {
      context.go('/workspaces');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(whiteboardProvider);
    final board = ref.watch(currentBoardProvider).value;
    final scene = _scene(state.operations);
    final title = board?.name.isNotEmpty == true ? board!.name : l10n.boards;
    final user = ref.watch(authStateProvider).user;
    final selfName = user?.name?.isNotEmpty == true ? user!.name! : (user?.email ?? l10n.you);
    final pageId = _activePageId(scene);
    final canvasPages = scene.pages.isEmpty
        ? [
            {'id': 'default', 'name': '${l10n.pageLabel} 1', 'index': 0},
          ]
        : scene.pages;
    final pageIndex = canvasPages.indexWhere((page) => page['id'] == pageId);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const _RemoteAudioMount(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: _leave,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard_rounded, size: 16, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          // Member count chip
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Material(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _showMembers(l10n, selfName),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined, size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 5),
                      Text(
                        '${_members.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Voice call status pill
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Material(
              color: _voice ? const Color(0xFFDCFCE7) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _toggleVoice,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _voice ? const Color(0xFF86EFAC) : AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_voice) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(
                        _voice ? Icons.mic_rounded : Icons.mic_off_rounded,
                        size: 16,
                        color: _voice ? const Color(0xFF16A34A) : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
            ),
            child: Row(
              children: [
                _PageSwitch(
                  tasks: _page == _BoardPage.tasks,
                  tasksLabel: l10n.tasks,
                  canvasLabel: l10n.canvas,
                  onTasks: () => setState(() => _page = _BoardPage.tasks),
                  onCanvas: () => setState(() => _page = _BoardPage.canvas),
                ),
                const SizedBox(width: 14),
                Container(width: 1, height: 22, color: const Color(0xFFE5E7EB)),
                const SizedBox(width: 14),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PresenceAvatar(
                          name: selfName,
                          label: l10n.you,
                          muted: !_voice,
                          speaking: _voice && state.localSpeaking,
                          online: true,
                          onTap: () => AppToast.show(context, message: selfName),
                        ),
                        for (final peer in state.peers.take(4))
                          _PresenceAvatar(
                            name: peer.userName?.isNotEmpty == true ? peer.userName! : peer.userId,
                            muted: peer.isMuted,
                            speaking: peer.isSpeaking && !peer.isMuted,
                            online: peer.connected,
                            onTap: () => AppToast.show(
                              context,
                              message: peer.userName?.isNotEmpty == true ? peer.userName! : peer.userId,
                            ),
                          ),
                        if (state.peers.length > 4)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: () => _showMembers(l10n, selfName),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Text(
                                    '+${state.peers.length - 4}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _page == _BoardPage.tasks
          ? _TrelloBoard(
              l10n: l10n,
              members: _members,
              columns: [
                _ColumnData('todo', l10n.todo, scene.tasks.where((t) => t['status'] == 'todo')),
                _ColumnData('doing', l10n.doing, scene.tasks.where((t) => t['status'] == 'doing')),
                _ColumnData('done', l10n.done, scene.tasks.where((t) => t['status'] == 'done')),
              ],
              controllers: _quickAdd,
              onQuickAdd: (status, title) => _createTask(title: title, status: status),
              onOpen: (task) => _openTask(task),
              onAdd: (status) => _openTask(null, status: status),
              onMove: _moveTask,
            )
          : _CanvaPage(
              l10n: l10n,
              tool: _tool,
              color: _color,
              width: _width,
              strokes: scene.strokes.where((item) => _onPage(item, pageId, scene.pages)).toList(),
              texts: scene.texts.where((item) => _onPage(item, pageId, scene.pages)).toList(),
              pageLabel: canvasPages[pageIndex < 0 ? 0 : pageIndex]['name'] as String? ?? l10n.pageLabel,
              canPrevious: pageIndex > 0,
              canNext: pageIndex >= 0 && pageIndex < canvasPages.length - 1,
              onPrevious: () => _shiftCanvasPage(-1),
              onNext: () => _shiftCanvasPage(1),
              onAddPage: () => _addCanvasPage(l10n),
              onTool: (tool) => setState(() => _tool = tool),
              onColor: (color) => setState(() => _color = color),
              onWidth: (value) => setState(() => _width = value),
              onPanStart: _panStart,
              onPanUpdate: _panUpdate,
              onPanEnd: _panEnd,
              onTap: (point) {
                if (_tool == _DrawTool.text) _addText(point);
              },
              currentUserId: user?.id ?? 'unknown',
              currentUserName: selfName,
              activeCursors: scene.activeCursors,
              localDrawing: _isDrawing,
              localPoint: _currentDrawPoint,
            ),
          ),
        ],
      ),
    );
  }

  String _activePageId([_Scene? scene]) {
    final pages = (scene ?? _scene(ref.read(whiteboardProvider).operations)).pages;
    if (pages.isEmpty) return 'default';
    if (pages.any((page) => page['id'] == _canvasPageId)) return _canvasPageId;
    return pages.first['id'] as String? ?? 'default';
  }

  bool _onPage(Map<String, dynamic> item, String pageId, List<Map<String, dynamic>> pages) {
    final first = pages.isEmpty ? 'default' : pages.first['id'] as String? ?? 'default';
    final id = item['pageId'] as String?;
    if (id == null || id.isEmpty) return pageId == first;
    return id == pageId;
  }

  void _shiftCanvasPage(int delta) {
    final scene = _scene(ref.read(whiteboardProvider).operations);
    final pages = scene.pages.isEmpty
        ? <Map<String, dynamic>>[
            {'id': 'default'},
          ]
        : scene.pages;
    final ids = pages.map((page) => page['id'] as String).toList();
    final current = ids.contains(_canvasPageId) ? _canvasPageId : ids.first;
    final next = ids.indexOf(current) + delta;
    if (next < 0 || next >= ids.length) return;
    setState(() => _canvasPageId = ids[next]);
  }

  void _addCanvasPage(AppLocalizations l10n) {
    final notifier = ref.read(whiteboardProvider.notifier);
    final scene = _scene(ref.read(whiteboardProvider).operations);
    var count = scene.pages.length;
    if (count == 0) {
      notifier.createOperation(OperationType.createObject, {
        'id': 'default',
        'type': 'page',
        'data': {'name': '${l10n.pageLabel} 1', 'index': 0},
      });
      count = 1;
    }
    final id = 'page-${DateTime.now().millisecondsSinceEpoch}';
    notifier.createOperation(OperationType.createObject, {
      'id': id,
      'type': 'page',
      'data': {'name': '${l10n.pageLabel} ${count + 1}', 'index': count},
    });
    setState(() => _canvasPageId = id);
  }

  void _showMembers(AppLocalizations l10n, String selfName) {
    final user = ref.read(authStateProvider).user;
    final peers = ref.read(whiteboardProvider).peers;
    final speaking = ref.read(whiteboardProvider).localSpeaking;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _MemberSheet(
        l10n: l10n,
        members: _members,
        peers: peers,
        selfId: user?.id,
        selfName: selfName,
        selfMuted: !_voice,
        selfSpeaking: _voice && speaking,
      ),
    );
  }

  _Scene _scene(List<Operation> operations) {
    final strokes = <Map<String, dynamic>>[];
    final texts = <Map<String, dynamic>>[];
    final tasks = <Map<String, dynamic>>[];
    final pages = <Map<String, dynamic>>[];
    final cursors = <String, Map<String, dynamic>>{};
    for (final op in operations) {
      final id = op.payload['id'] as String?;
      final type = op.payload['type'] as String?;
      if (id == null || type == null) continue;
      if (op.type == OperationType.deleteObject) {
        strokes.removeWhere((item) => item['id'] == id);
        texts.removeWhere((item) => item['id'] == id);
        tasks.removeWhere((item) => item['id'] == id);
        pages.removeWhere((item) => item['id'] == id);
        cursors.remove(id);
        if (id.startsWith('cursor-')) {
          cursors.remove(id.replaceFirst('cursor-', ''));
        }
        continue;
      }
      final data = {'id': id, ...Map<String, dynamic>.from(op.payload['data'] ?? {})};
      if (type == 'stroke') {
        strokes.removeWhere((item) => item['id'] == id);
        strokes.add(data);
      } else if (type == 'cursor') {
        final uId = (data['userId'] ?? op.actor).toString();
        if (data['drawing'] == true) {
          cursors[uId] = data;
        } else {
          cursors.remove(uId);
        }
      } else if (type == 'text') {
        texts.removeWhere((item) => item['id'] == id);
        texts.add(data);
      } else if (type == 'task') {
        tasks.removeWhere((item) => item['id'] == id);
        tasks.add(data);
      } else if (type == 'page') {
        pages.removeWhere((item) => item['id'] == id);
        pages.add(data);
      }
    }
    pages.sort((a, b) => ((a['index'] as num?) ?? 0).compareTo((b['index'] as num?) ?? 0));
    return _Scene(strokes, texts, tasks, pages, cursors);
  }
}

class _Scene {
  final List<Map<String, dynamic>> strokes;
  final List<Map<String, dynamic>> texts;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> pages;
  final Map<String, Map<String, dynamic>> activeCursors;
  const _Scene(this.strokes, this.texts, this.tasks, this.pages, [this.activeCursors = const {}]);
}

class _ColumnData {
  final String status;
  final String title;
  final List<Map<String, dynamic>> tasks;
  _ColumnData(this.status, this.title, Iterable<Map<String, dynamic>> tasks)
      : tasks = tasks.toList();
}

class _PageSwitch extends StatelessWidget {
  final bool tasks;
  final String tasksLabel;
  final String canvasLabel;
  final VoidCallback onTasks;
  final VoidCallback onCanvas;

  const _PageSwitch({
    required this.tasks,
    required this.tasksLabel,
    required this.canvasLabel,
    required this.onTasks,
    required this.onCanvas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(tasksLabel, Icons.view_kanban_rounded, tasks, onTasks),
          const SizedBox(width: 2),
          _chip(canvasLabel, Icons.draw_rounded, !tasks, onCanvas),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrelloBoard extends StatelessWidget {
  final AppLocalizations l10n;
  final List<_ColumnData> columns;
  final Map<String, TextEditingController> controllers;
  final void Function(String status, String title) onQuickAdd;
  final void Function(Map<String, dynamic> task) onOpen;
  final void Function(String status) onAdd;
  final void Function(String taskId, String status) onMove;
  final List<Map<String, dynamic>> members;

  const _TrelloBoard({
    required this.l10n,
    required this.columns,
    required this.members,
    required this.controllers,
    required this.onQuickAdd,
    required this.onOpen,
    required this.onAdd,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final views = [
          for (final column in columns) _column(column, wide ? null : constraints.maxHeight - 32),
        ];
        if (wide) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < views.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: views[i]),
                ],
              ],
            ),
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          itemCount: views.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) => SizedBox(
            width: 310,
            height: constraints.maxHeight - 32,
            child: views[index],
          ),
        );
      },
    );
  }

  Widget _column(_ColumnData column, double? height) {
    Color dotColor;
    if (column.status == 'todo') {
      dotColor = const Color(0xFF8B7CFF);
    } else if (column.status == 'doing') {
      dotColor = const Color(0xFF3B82F6);
    } else {
      dotColor = const Color(0xFF10B981);
    }

    return SizedBox(
      width: height == null ? null : 310,
      height: height,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => onMove(details.data, column.status),
        builder: (context, candidate, rejected) {
          return Container(
            decoration: BoxDecoration(
              color: candidate.isEmpty ? const Color(0xFFF8F7FD) : const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: candidate.isEmpty ? const Color(0xFFE9E5F5) : const Color(0xFF8B7CFF),
                width: candidate.isEmpty ? 1 : 1.5,
              ),
            ),
            child: Column(
              children: [
                // Column Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          column.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          '${column.tasks.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.addTask,
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onAdd(column.status),
                        icon: const Icon(Icons.add_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Task Cards
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: column.tasks.length,
                    itemBuilder: (context, taskIndex) {
                      final task = column.tasks[taskIndex];
                      final id = task['id'] as String? ?? '';
                      return Draggable<String>(
                        data: id,
                        feedback: Material(
                          elevation: 10,
                          borderRadius: BorderRadius.circular(12),
                          shadowColor: const Color(0xFF8B7CFF).withValues(alpha: 0.25),
                          child: Transform.rotate(
                            angle: 0.03,
                            child: SizedBox(
                              width: 280,
                              child: _TaskCard(task: task, members: members),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _TaskCard(task: task, members: members),
                        ),
                        child: _TaskCard(
                          task: task,
                          members: members,
                          onTap: () => onOpen(task),
                        ),
                      );
                    },
                  ),
                ),
                // Quick Add Field
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: controllers[column.status],
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.addTask,
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF8B7CFF), width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        tooltip: l10n.addTask,
                        iconSize: 18,
                        onPressed: () => _submitQuickAdd(column.status),
                        icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF8B7CFF)),
                      ),
                    ),
                    onSubmitted: (_) => _submitQuickAdd(column.status),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitQuickAdd(String status) {
    final title = controllers[status]?.text.trim() ?? '';
    if (title.isEmpty) return;
    controllers[status]?.clear();
    onQuickAdd(status, title);
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> members;
  final VoidCallback? onTap;

  const _TaskCard({required this.task, required this.members, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final priority = task['priority'] as String? ?? 'medium';
    final rawDescription = task['description'] as String?;
    final cardData = _parseCardDescription(rawDescription);
    final labels = _stringList(task['labels']);
    final assigneeIds = _stringList(task['assignees']);
    final deadline = task['deadline'] == null
        ? null
        : DateTime.tryParse(task['deadline'].toString());
    final overdue = deadline != null &&
        deadline.isBefore(DateTime.now()) &&
        task['status'] != 'done';
    final names = [
      for (final id in assigneeIds.take(3)) _memberName(id),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (labels.isNotEmpty) ...[
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      for (final label in labels.take(4))
                        _buildLabelBadge(label),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  task['title'] as String? ?? l10n.untitled,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                if (cardData.cleanDescription != null &&
                    cardData.cleanDescription!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      cardData.cleanDescription!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _priorityBadge(priority),
                    if (cardData.checklistTotal > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardData.checklistDone ==
                                  cardData.checklistTotal
                              ? const Color(0xFFDEF7EC)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cardData.checklistDone ==
                                      cardData.checklistTotal
                                  ? Icons.check_circle_rounded
                                  : Icons.check_box_outlined,
                              size: 11,
                              color: cardData.checklistDone ==
                                      cardData.checklistTotal
                                  ? const Color(0xFF03543F)
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${cardData.checklistDone}/${cardData.checklistTotal}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: cardData.checklistDone ==
                                        cardData.checklistTotal
                                    ? const Color(0xFF03543F)
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (deadline != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: overdue
                              ? AppColors.error.withValues(alpha: 0.1)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: overdue
                                  ? AppColors.error
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${deadline.day}/${deadline.month}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: overdue
                                    ? AppColors.error
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    for (var i = 0; i < names.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: const Color(0xFF5B4AD4),
                        child: Text(
                          names[i].isEmpty ? '?' : names[i][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildLabelBadge(String label) {
    final lower = label.toLowerCase();
    Color bg;
    Color fg;
    if (lower.contains('bug')) {
      bg = const Color(0xFFFADBD8);
      fg = const Color(0xFF991B1B);
    } else if (lower.contains('approval')) {
      bg = const Color(0xFFFDE8E8);
      fg = const Color(0xFF9F1239);
    } else if (lower.contains('yellow')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF854D0E);
    } else if (lower.contains('green')) {
      bg = const Color(0xFFDEF7EC);
      fg = const Color(0xFF03543F);
    } else if (lower.contains('review')) {
      bg = const Color(0xFFE1EFFE);
      fg = const Color(0xFF1E429F);
    } else if (lower.contains('purple')) {
      bg = const Color(0xFFEDEBFE);
      fg = const Color(0xFF5521B5);
    } else {
      bg = const Color(0xFFEDE9FE);
      fg = const Color(0xFF5B4AD4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color bg;
    Color fg;
    IconData icon = Icons.flag_rounded;
    switch (priority) {
      case 'urgent':
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
      case 'high':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 'low':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      default:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF5B4AD4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: fg),
          const SizedBox(width: 3),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _memberName(String id) {
    for (final member in members) {
      if (member['id']?.toString() == id) {
        final name = member['name']?.toString();
        if (name != null && name.isNotEmpty) return name;
        return member['email']?.toString() ?? '';
      }
    }
    return '';
  }
}

class _CanvaPage extends StatefulWidget {
  final AppLocalizations l10n;
  final _DrawTool tool;
  final Color color;
  final double width;
  final List<Map<String, dynamic>> strokes;
  final List<Map<String, dynamic>> texts;
  final String pageLabel;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onAddPage;
  final ValueChanged<_DrawTool> onTool;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onWidth;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;
  final ValueChanged<Offset> onTap;
  final String currentUserId;
  final String currentUserName;
  final Map<String, Map<String, dynamic>> activeCursors;
  final bool localDrawing;
  final Offset? localPoint;

  const _CanvaPage({
    required this.l10n,
    required this.tool,
    required this.color,
    required this.width,
    required this.strokes,
    required this.texts,
    required this.pageLabel,
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
    required this.onAddPage,
    required this.onTool,
    required this.onColor,
    required this.onWidth,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTap,
    required this.currentUserId,
    required this.currentUserName,
    required this.activeCursors,
    required this.localDrawing,
    required this.localPoint,
  });

  static const _colors = [
    AppColors.primaryDark,
    Color(0xFF2563EB),
    AppColors.primary,
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF1E293B),
  ];

  @override
  State<_CanvaPage> createState() => _CanvaPageState();
}

class _CanvaPageState extends State<_CanvaPage> {
  bool _showAuthorTags = true;
  bool _isLegendExpanded = true;

  Color _getAuthorColor(String? id, String? name) {
    const palette = [
      Color(0xFF5B4AD4), // Indigo
      Color(0xFF0D9488), // Teal
      Color(0xFFE11D48), // Rose
      Color(0xFFD97706), // Amber
      Color(0xFF2563EB), // Blue
      Color(0xFF7C3AED), // Violet
      Color(0xFF059669), // Emerald
      Color(0xFFEA580C), // Orange
    ];
    final key = (id != null && id.isNotEmpty && id != 'unknown')
        ? id
        : ((name != null && name.isNotEmpty) ? name : 'guest');
    final hash = key.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return palette[hash % palette.length];
  }

  Map<String, String> _getContributors() {
    final map = <String, String>{};
    if (widget.currentUserId.isNotEmpty && widget.currentUserId != 'unknown') {
      map[widget.currentUserId] = widget.currentUserName;
    }
    for (final s in widget.strokes) {
      final id = (s['userId'] ?? s['actor'])?.toString() ?? '';
      final name = (s['userName'] ?? s['actorName'])?.toString() ?? '';
      if (name.isNotEmpty && name != 'unknown') {
        map[id.isNotEmpty ? id : name] = name;
      }
    }
    for (final t in widget.texts) {
      final name = (t['actorName'] ?? t['userName'])?.toString() ?? '';
      if (name.isNotEmpty && name != 'unknown') {
        map[name] = name;
      }
    }
    for (final c in widget.activeCursors.values) {
      final id = (c['userId'])?.toString() ?? '';
      final name = (c['userName'] ?? c['name'])?.toString() ?? '';
      if (name.isNotEmpty && name != 'unknown') {
        map[id.isNotEmpty ? id : name] = name;
      }
    }
    return map;
  }

  List<Widget> _buildLiveAuthorTags() {
    if (!_showAuthorTags) return [];
    final tags = <Widget>[];

    // 1. Local user live drawing tag
    if (widget.localDrawing && widget.localPoint != null) {
      final localColor = _getAuthorColor(widget.currentUserId, widget.currentUserName);
      tags.add(
        Positioned(
          left: widget.localPoint!.dx + 12,
          top: (widget.localPoint!.dy - 28) < 0 ? widget.localPoint!.dy + 10 : widget.localPoint!.dy - 28,
          child: IgnorePointer(
            child: _authorTagPill(
              name: widget.currentUserName.isNotEmpty ? widget.currentUserName : 'You',
              color: localColor,
            ),
          ),
        ),
      );
    }

    // 2. Remote peers currently drawing (active cursors)
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final entry in widget.activeCursors.entries) {
      final c = entry.value;
      final peerId = (c['userId'] ?? entry.key).toString();
      if (peerId == widget.currentUserId) continue;
      if (c['drawing'] != true) continue;
      if (c['x'] == null || c['y'] == null) continue;
      final ts = (c['timestamp'] as num?)?.toInt();
      if (ts != null && (now - ts) > 1500) continue;

      final peerName = (c['userName'] ?? c['name'] ?? 'Peer').toString();
      final peerColor = _getAuthorColor(peerId, peerName);
      final px = (c['x'] as num).toDouble();
      final py = (c['y'] as num).toDouble();

      tags.add(
        Positioned(
          left: px + 12,
          top: (py - 28) < 0 ? py + 10 : py - 28,
          child: IgnorePointer(
            child: _authorTagPill(
              name: peerName,
              color: peerColor,
            ),
          ),
        ),
      );
    }

    return tags;
  }

  Widget _authorTagPill({required String name, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.edit_rounded,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    final contributors = _getContributors();
    return Material(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _isLegendExpanded = !_isLegendExpanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(10),
                bottom: Radius.circular(_isLegendExpanded ? 0 : 10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textPrimary),
                    const SizedBox(width: 6),
                    const Text(
                      'Người vẽ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${contributors.length}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _isLegendExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_isLegendExpanded) ...[
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hiện nhãn khi vẽ',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 20,
                      width: 32,
                      child: Transform.scale(
                        scale: 0.65,
                        child: Switch(
                          value: _showAuthorTags,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _showAuthorTags = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contributors.isEmpty)
                        const Text(
                          'Chưa có nét vẽ',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textTertiary),
                        ),
                      for (final entry in contributors.entries) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getAuthorColor(entry.key, entry.value),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  entry.value + (entry.key == widget.currentUserId ? ' (Bạn)' : ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Studio White Left Toolbar
        Container(
          width: 68,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.borderLight)),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            children: [
              _toolButton(Icons.edit_rounded, widget.l10n.pen, _DrawTool.pen),
              const SizedBox(height: 6),
              _toolButton(Icons.auto_fix_high_rounded, widget.l10n.eraser, _DrawTool.eraser),
              const SizedBox(height: 6),
              _toolButton(Icons.title_rounded, widget.l10n.addText, _DrawTool.text),
              const SizedBox(height: 6),
              _toolButton(Icons.pan_tool_rounded, widget.l10n.pan, _DrawTool.hand),
              const SizedBox(height: 6),
              // Author tag toggle button on toolbar
              IconButton(
                tooltip: _showAuthorTags ? 'Ẩn nhãn khi vẽ' : 'Hiện nhãn khi vẽ',
                onPressed: () => setState(() => _showAuthorTags = !_showAuthorTags),
                icon: Icon(
                  _showAuthorTags ? Icons.label_rounded : Icons.label_off_rounded,
                  size: 20,
                  color: _showAuthorTags ? AppColors.primaryDark : AppColors.textSecondary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _showAuthorTags ? AppColors.primarySubtle : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
              // Color swatches
              for (final swatch in _CanvaPage._colors)
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onColor(swatch),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color == swatch ? AppColors.surface : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: widget.color == swatch
                            ? [
                                BoxShadow(
                                  color: swatch.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
              // Stroke width quick buttons
              _strokeWidthButton(2),
              _strokeWidthButton(5),
              _strokeWidthButton(10),
            ],
          ),
        ),
        // Interactive Canvas Workspace
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      color: const Color(0xFFF9F8FD),
                      child: InteractiveViewer(
                        minScale: 0.4,
                        maxScale: 3,
                        panEnabled: widget.tool == _DrawTool.hand,
                        boundaryMargin: const EdgeInsets.all(800),
                        child: GestureDetector(
                          onTapUp: (details) => widget.onTap(details.localPosition),
                          onPanStart: widget.tool == _DrawTool.pen || widget.tool == _DrawTool.eraser
                              ? (details) => widget.onPanStart(details.localPosition)
                              : null,
                          onPanUpdate: widget.tool == _DrawTool.pen || widget.tool == _DrawTool.eraser
                              ? (details) => widget.onPanUpdate(details.localPosition)
                              : null,
                          onPanEnd: widget.tool == _DrawTool.pen || widget.tool == _DrawTool.eraser
                              ? (_) => widget.onPanEnd()
                              : null,
                          child: Container(
                            width: 2400,
                            height: 1600,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Stack(
                              children: [
                                const Positioned.fill(
                                  child: CustomPaint(painter: _CanvasGridPainter()),
                                ),
                                CustomPaint(
                                  size: const Size(2400, 1600),
                                  painter: _StrokePainter(widget.strokes),
                                ),
                                for (final text in widget.texts) _textWidget(text),
                                ..._buildLiveAuthorTags(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Floating Legend Card in top-right of canvas viewport
                    Positioned(
                      top: 14,
                      right: 14,
                      child: _buildLegendCard(),
                    ),
                  ],
                ),
              ),
              _pageBar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _strokeWidthButton(double val) {
    final selected = widget.width == val;
    return GestureDetector(
      onTap: () => widget.onWidth(val),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        height: 28,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 24,
          height: val,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryDark : AppColors.textTertiary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  Widget _pageBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: widget.pageLabel,
            visualDensity: VisualDensity.compact,
            onPressed: widget.canPrevious ? widget.onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
          ),
          Expanded(
            child: Text(
              widget.pageLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: widget.canNext ? widget.onNext : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: widget.onAddPage,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(widget.l10n.addPage, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primarySubtle,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String tooltip, _DrawTool value) {
    final selected = widget.tool == value;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => widget.onTool(value),
      icon: Icon(
        icon,
        size: 20,
        color: selected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
      style: IconButton.styleFrom(
        backgroundColor: selected ? AppColors.primarySubtle : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _textWidget(Map<String, dynamic> text) {
    final position = text['position'] as List?;
    final dx = position != null && position.isNotEmpty ? (position[0] as num).toDouble() : 40.0;
    final dy = position != null && position.length > 1 ? (position[1] as num).toDouble() : 40.0;
    return Positioned(
      left: dx,
      top: dy,
      child: Text(
        text['text'] as String? ?? '',
        style: TextStyle(
          color: Color((text['color'] as num?)?.toInt() ?? 0xFF172B4D),
          fontSize: (text['fontSize'] as num?)?.toDouble() ?? 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CanvasGridPainter extends CustomPainter {
  const _CanvasGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCBD5E1).withValues(alpha: 0.45);
    const gap = 32.0;
    for (var y = 0.0; y < size.height; y += gap) {
      for (var x = 0.0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) => false;
}

class _StrokePainter extends CustomPainter {
  final List<Map<String, dynamic>> strokes;
  const _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
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
          ..color = Color((stroke['color'] as num?)?.toInt() ?? 0xFF172B4D)
          ..strokeWidth = (stroke['width'] as num?)?.toDouble() ?? 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}

class _PresenceAvatar extends StatelessWidget {
  final String name;
  final String? label;
  final bool muted;
  final bool speaking;
  final bool online;
  final VoidCallback onTap;

  const _PresenceAvatar({
    required this.name,
    this.label,
    required this.muted,
    required this.speaking,
    required this.online,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = label ?? name;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: speaking
            ? AppColors.primarySubtle.withValues(alpha: 0.5)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: speaking ? AppColors.primary : const Color(0xFFE5E7EB),
                width: speaking ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: speaking ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.primarySubtle,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: online ? AppColors.success : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Text(
                  displayName,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 13,
                  color: muted ? const Color(0xFF9CA3AF) : AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberSheet extends StatelessWidget {
  final AppLocalizations l10n;
  final List<Map<String, dynamic>> members;
  final List<Peer> peers;
  final String? selfId;
  final String selfName;
  final bool selfMuted;
  final bool selfSpeaking;

  const _MemberSheet({
    required this.l10n,
    required this.members,
    required this.peers,
    required this.selfId,
    required this.selfName,
    required this.selfMuted,
    required this.selfSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_MemberRow>[];
    final seen = <String>{};
    if (selfId != null) {
      seen.add(selfId!);
      rows.add(_MemberRow(selfName, true, selfMuted, selfSpeaking, true));
    }
    for (final member in members) {
      final id = member['id']?.toString();
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      final peer = _peer(id);
      final online = peer != null;
      rows.add(_MemberRow(
        member['name']?.toString().isNotEmpty == true
            ? member['name'].toString()
            : (member['email']?.toString() ?? id),
        online,
        peer?.isMuted ?? true,
        (peer?.isSpeaking ?? false) && peer?.isMuted == false,
        false,
      ));
    }
    for (final peer in peers) {
      if (seen.contains(peer.userId)) continue;
      rows.add(_MemberRow(
        peer.userName?.isNotEmpty == true ? peer.userName! : peer.userId,
        true,
        peer.isMuted,
        peer.isSpeaking && !peer.isMuted,
        false,
      ));
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                Text(
                  l10n.members,
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${rows.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final row = rows[index];
                final status = row.speaking
                    ? l10n.speaking
                    : (row.online ? l10n.online : l10n.offline);
                final initial = row.name.isEmpty ? '?' : row.name.characters.first.toUpperCase();
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primarySubtle,
                        child: Text(
                          initial,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: row.online ? AppColors.success : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    row.you ? '${row.name} (${l10n.you})' : row.name,
                    style: TextStyle(fontWeight: row.you ? FontWeight.w700 : FontWeight.w600),
                  ),
                  subtitle: Text(
                    status,
                    style: TextStyle(
                      color: row.speaking
                          ? AppColors.primaryDark
                          : (row.online ? AppColors.success : AppColors.textTertiary),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    row.online ? (row.muted ? Icons.mic_off_rounded : Icons.mic_rounded) : Icons.cloud_off_rounded,
                    size: 18,
                    color: row.speaking
                        ? AppColors.primary
                        : (row.online ? (row.muted ? AppColors.error : AppColors.success) : AppColors.textTertiary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Peer? _peer(String id) {
    for (final peer in peers) {
      if (peer.userId == id) return peer;
    }
    return null;
  }
}

class _MemberRow {
  final String name;
  final bool online;
  final bool muted;
  final bool speaking;
  final bool you;
  const _MemberRow(this.name, this.online, this.muted, this.speaking, this.you);
}

class _RemoteAudioMount extends ConsumerWidget {
  const _RemoteAudioMount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final output = ref.read(whiteboardProvider.notifier).remoteAudio;
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: output,
        builder: (context, _) {
          if (output.renderers.isEmpty) return const SizedBox.shrink();
          return SizedBox(
            height: 1,
            child: Row(
              children: [
                for (final renderer in output.renderers)
                  SizedBox(width: 1, height: 1, child: RTCVideoView(renderer)),
              ],
            ),
          );
        },
      ),
    );
  }
}
