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
import '../widgets/app_dialog.dart';
import '../widgets/app_toast.dart';
import '../widgets/task_dialog.dart';

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
  Color _color = const Color(0xFF172B4D);
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
      final members = await ref.read(apiServiceProvider).getBoardMembers(widget.boardId);
      if (!mounted) return;
      setState(() {
        _members = members
            .map((member) => {
                  'id': member['user_id'] ?? member['id'],
                  'name': member['name'],
                  'email': member['email'],
                })
            .toList();
      });
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
  }) async {
    try {
      final response = await ref.read(apiServiceProvider).createTask(
            boardId: widget.boardId,
            title: title,
            description: description,
            status: status,
            priority: priority,
          );
      ref.read(whiteboardProvider.notifier).createOperation(
        OperationType.createObject,
        {'id': response['id'], 'type': 'task', 'data': response},
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
    TaskModel? model;
    if (existing != null) {
      model = TaskModel(
        id: existing['id'] as String? ?? '',
        boardId: widget.boardId,
        title: existing['title'] as String? ?? '',
        description: existing['description'] as String?,
        status: existing['status'] as String? ?? status,
        priority: existing['priority'] as String? ?? 'medium',
        assignees: (existing['assignees'] as List?)?.map((e) => e.toString()).toList() ?? [],
        assigneeList: const [],
        labels: (existing['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
        position: (existing['position'] as num?)?.toInt() ?? 0,
        createdBy: existing['created_by'] as String? ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => TaskDialog(
        existingTask: model,
        initialStatus: status,
        boardMembers: _members,
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
            );
            return;
          }
          final taskId = existing['id'] as String;
          final response = await ref.read(apiServiceProvider).updateTask(
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
          ref.read(whiteboardProvider.notifier).createOperation(
            OperationType.updateObject,
            {'id': taskId, 'type': 'task', 'data': response},
            shouldSaveBackend: false,
          );
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
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.createObject,
      {
        'id': _strokeId,
        'type': 'stroke',
        'data': _strokeData(eraser),
      },
      shouldSaveBackend: true,
    );
  }

  void _panUpdate(Offset point) {
    if (_strokeId == null || _tool == _DrawTool.text) return;
    setState(() => _points.add(point));
    ref.read(whiteboardProvider.notifier).createOperation(
      OperationType.updateObject,
      {
        'id': _strokeId,
        'type': 'stroke',
        'data': _strokeData(_tool == _DrawTool.eraser),
      },
      shouldSaveBackend: false,
    );
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
    _strokeId = null;
    _points = [];
  }

  Map<String, dynamic> _strokeData(bool eraser) {
    final paint = eraser ? Colors.white : _color;
    return {
      'points': _points.expand((p) => [p.dx, p.dy]).toList(),
      'color': paint.toARGB32(),
      'width': eraser ? _width * 4 : _width,
      'actor': ref.read(authStateProvider).user?.id ?? 'unknown',
      'actorName': _displayName(),
      'isEraser': eraser,
      'pageId': _activePageId(),
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
      backgroundColor: _page == _BoardPage.tasks
          ? const Color(0xFFF1F2F4)
          : AppColors.surface,
      bottomNavigationBar: const _RemoteAudioMount(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _leave),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          _PageSwitch(
            tasks: _page == _BoardPage.tasks,
            tasksLabel: l10n.tasks,
            canvasLabel: l10n.canvas,
            onTasks: () => setState(() => _page = _BoardPage.tasks),
            onCanvas: () => setState(() => _page = _BoardPage.canvas),
          ),
          IconButton(
            tooltip: l10n.members,
            onPressed: () => _showMembers(l10n, selfName),
            icon: const Icon(Icons.group_outlined),
          ),
          IconButton(
            tooltip: _voice ? 'Mute' : 'Call',
            onPressed: _toggleVoice,
            icon: Icon(_voice ? Icons.mic_rounded : Icons.mic_off_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _PresenceBar(
            selfName: selfName,
            selfMuted: !_voice,
            selfSpeaking: _voice && state.localSpeaking,
            peers: state.peers,
            youLabel: l10n.you,
            onName: (name) => AppToast.show(context, message: name),
          ),
          Expanded(
            child: _page == _BoardPage.tasks
          ? _TrelloBoard(
              l10n: l10n,
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
              onDelete: _deleteTask,
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
    for (final op in operations) {
      final id = op.payload['id'] as String?;
      final type = op.payload['type'] as String?;
      if (id == null || type == null) continue;
      if (op.type == OperationType.deleteObject) {
        strokes.removeWhere((item) => item['id'] == id);
        texts.removeWhere((item) => item['id'] == id);
        tasks.removeWhere((item) => item['id'] == id);
        pages.removeWhere((item) => item['id'] == id);
        continue;
      }
      final data = {'id': id, ...Map<String, dynamic>.from(op.payload['data'] ?? {})};
      if (type == 'stroke') {
        strokes.removeWhere((item) => item['id'] == id);
        strokes.add(data);
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
    return _Scene(strokes, texts, tasks, pages);
  }
}

class _Scene {
  final List<Map<String, dynamic>> strokes;
  final List<Map<String, dynamic>> texts;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> pages;
  const _Scene(this.strokes, this.texts, this.tasks, this.pages);
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
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(tasksLabel, tasks, onTasks),
          _chip(canvasLabel, !tasks, onCanvas),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryDark : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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
  final void Function(String taskId) onDelete;

  const _TrelloBoard({
    required this.l10n,
    required this.columns,
    required this.controllers,
    required this.onQuickAdd,
    required this.onOpen,
    required this.onAdd,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: columns.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final column = columns[index];
        return SizedBox(
          width: 300,
          height: constraints.maxHeight - 32,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) => onMove(details.data, column.status),
            builder: (context, candidate, rejected) {
              return Container(
                decoration: BoxDecoration(
                  color: candidate.isEmpty
                      ? const Color(0xFFEBECF0)
                      : const Color(0xFFD6E4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${column.title}  ${column.tasks.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF172B4D),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.addTask,
                            onPressed: () => onAdd(column.status),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: column.tasks.length,
                        itemBuilder: (context, taskIndex) {
                          final task = column.tasks[taskIndex];
                          final id = task['id'] as String? ?? '';
                          return LongPressDraggable<String>(
                            data: id,
                            feedback: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(width: 280, child: _TaskCard(task: task)),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: _TaskCard(task: task),
                            ),
                            child: _TaskCard(
                              task: task,
                              onTap: () => onOpen(task),
                              onDelete: () => onDelete(id),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: controllers[column.status],
                        decoration: InputDecoration(
                          hintText: l10n.addTask,
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (value) {
                          final title = value.trim();
                          if (title.isEmpty) return;
                          controllers[column.status]?.clear();
                          onQuickAdd(column.status, title);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TaskCard({required this.task, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final priority = task['priority'] as String? ?? 'medium';
    final description = task['description'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: _priorityColor(priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String? ?? 'Untitled',
                        style: const TextStyle(
                          color: Color(0xFF172B4D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null && description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: const Icon(Icons.close, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }
}

class _CanvaPage extends StatelessWidget {
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
  });

  static const _colors = [
    Color(0xFF172B4D),
    Color(0xFFEF4444),
    Color(0xFF4A90E2),
    Color(0xFF48BB78),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _toolButton(Icons.edit, l10n.pen, _DrawTool.pen),
              _toolButton(Icons.auto_fix_high, l10n.eraser, _DrawTool.eraser),
              _toolButton(Icons.title, l10n.addText, _DrawTool.text),
              _toolButton(Icons.back_hand, l10n.pan, _DrawTool.hand),
              const Spacer(),
              for (final swatch in _colors)
                GestureDetector(
                  onTap: () => onColor(swatch),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == swatch ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: 120,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: width,
                    min: 1,
                    max: 16,
                    onChanged: onWidth,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
            minScale: 0.4,
            maxScale: 3,
            panEnabled: tool == _DrawTool.hand,
            boundaryMargin: const EdgeInsets.all(800),
            child: GestureDetector(
              onTapUp: (details) => onTap(details.localPosition),
              onPanStart: tool == _DrawTool.pen || tool == _DrawTool.eraser
                  ? (details) => onPanStart(details.localPosition)
                  : null,
              onPanUpdate: tool == _DrawTool.pen || tool == _DrawTool.eraser
                  ? (details) => onPanUpdate(details.localPosition)
                  : null,
              onPanEnd: tool == _DrawTool.pen || tool == _DrawTool.eraser
                  ? (_) => onPanEnd()
                  : null,
              child: Container(
                width: 2400,
                height: 1600,
                color: Colors.white,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(2400, 1600),
                      painter: _StrokePainter(strokes),
                    ),
                    for (final text in texts) _textWidget(text),
                  ],
                ),
              ),
            ),
          ),
              ),
              _pageBar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pageBar() {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: pageLabel,
              onPressed: canPrevious ? onPrevious : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                pageLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: canNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton.icon(
              onPressed: onAddPage,
              icon: const Icon(Icons.add),
              label: Text(l10n.addPage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String tooltip, _DrawTool value) {
    final selected = tool == value;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => onTool(value),
      icon: Icon(icon, color: selected ? Colors.white : Colors.white70),
      style: IconButton.styleFrom(
        backgroundColor: selected ? AppColors.primary : Colors.transparent,
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

class _PresenceBar extends StatelessWidget {
  final String selfName;
  final bool selfMuted;
  final bool selfSpeaking;
  final List<Peer> peers;
  final String youLabel;
  final ValueChanged<String> onName;

  const _PresenceBar({
    required this.selfName,
    required this.selfMuted,
    required this.selfSpeaking,
    required this.peers,
    required this.youLabel,
    required this.onName,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: 72,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _PresenceAvatar(
              name: selfName,
              label: youLabel,
              muted: selfMuted,
              speaking: selfSpeaking,
              online: true,
              onTap: () => onName(selfName),
            ),
            for (final peer in peers)
              _PresenceAvatar(
                name: peer.userName?.isNotEmpty == true ? peer.userName! : peer.userId,
                muted: peer.isMuted,
                speaking: peer.isSpeaking && !peer.isMuted,
                online: peer.connected,
                onTap: () => onName(
                  peer.userName?.isNotEmpty == true ? peer.userName! : peer.userId,
                ),
              ),
          ],
        ),
      ),
    );
  }
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
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: speaking ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFD6E4FF),
                      child: Text(initial, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: online ? AppColors.success : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -2,
                    bottom: -2,
                    child: Icon(
                      muted ? Icons.mic_off : Icons.mic,
                      size: 12,
                      color: muted ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label ?? name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ],
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.members, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = rows[index];
                final status = row.speaking
                    ? l10n.speaking
                    : (row.online ? l10n.online : l10n.offline);
                return ListTile(
                  leading: Icon(
                    row.online ? (row.muted ? Icons.mic_off : Icons.mic) : Icons.person_outline,
                    color: row.speaking
                        ? AppColors.primary
                        : (row.online ? AppColors.success : Colors.grey),
                  ),
                  title: Text(row.you ? '${row.name} (${l10n.you})' : row.name),
                  subtitle: Text(status),
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
    return ListenableBuilder(
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
    );
  }
}
