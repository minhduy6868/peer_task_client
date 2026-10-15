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

  String _taskSort = 'default';
  String _priorityFilter = 'all';
  bool _showFilterBar = false;
  final _searchController = TextEditingController();
  String _taskSearchQuery = '';

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
      try {
        ref.read(whiteboardProvider.notifier).saveDraft(boardId: boardId);
      } catch (_) {}
    }
    _textController.dispose();
    _searchController.dispose();
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

  List<Map<String, dynamic>> _filterAndSortTasks(Iterable<Map<String, dynamic>> tasks) {
    var list = tasks.where((t) {
      if (_priorityFilter != 'all') {
        final p = (t['priority'] as String? ?? 'medium').toLowerCase();
        if (p != _priorityFilter) return false;
      }
      if (_taskSearchQuery.isNotEmpty) {
        final title = (t['title'] as String? ?? '').toLowerCase();
        final desc = (t['description'] as String? ?? '').toLowerCase();
        final query = _taskSearchQuery.toLowerCase();
        if (!title.contains(query) && !desc.contains(query)) return false;
      }
      return true;
    }).toList();

    if (_taskSort == 'date') {
      list.sort((a, b) {
        final da = a['deadline'] == null ? null : DateTime.tryParse(a['deadline'].toString());
        final db = b['deadline'] == null ? null : DateTime.tryParse(b['deadline'].toString());
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    } else if (_taskSort == 'priority') {
      const pMap = {'urgent': 4, 'high': 3, 'medium': 2, 'low': 1};
      list.sort((a, b) {
        final pa = pMap[(a['priority'] as String? ?? 'medium').toLowerCase()] ?? 2;
        final pb = pMap[(b['priority'] as String? ?? 'medium').toLowerCase()] ?? 2;
        return pb.compareTo(pa);
      });
    } else if (_taskSort == 'title') {
      list.sort((a, b) {
        final ta = a['title'] as String? ?? '';
        final tb = b['title'] as String? ?? '';
        return ta.toLowerCase().compareTo(tb.toLowerCase());
      });
    }
    return list;
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
          // + Add Task button (compact on mobile, full on desktop)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: FilledButton(
              onPressed: () => _openTask(null),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(l10n.addTask),
            ),
          ),
          const SizedBox(width: 8),
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
          const SizedBox(width: 10),
          // User profile avatar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primarySubtle,
                  child: Text(
                    selfName.isNotEmpty ? selfName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
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
          _BoardSubHeader(
            tasks: _page == _BoardPage.tasks,
            boardLabel: l10n.tasks,
            canvasLabel: l10n.canvas,
            onTasks: () => setState(() => _page = _BoardPage.tasks),
            onCanvas: () => setState(() => _page = _BoardPage.canvas),
            filterLabel: l10n.filter,
            sortLabel: l10n.sort,
            isFilterActive: _priorityFilter != 'all' || _taskSearchQuery.isNotEmpty,
            onToggleFilter: () => setState(() => _showFilterBar = !_showFilterBar),
            currentSort: _taskSort,
            onSelectSort: (sort) => setState(() => _taskSort = sort),
            sortByDateLabel: l10n.sortByDate,
            sortByPriorityLabel: l10n.sortByPriority,
            sortByTitleLabel: l10n.sortByTitle,
            defaultSortLabel: l10n.defaultSort,
          ),
          if (_showFilterBar && _page == _BoardPage.tasks)
            _TaskFilterToolbar(
              l10n: l10n,
              searchController: _searchController,
              currentPriority: _priorityFilter,
              onSearchChanged: (val) => setState(() => _taskSearchQuery = val.trim()),
              onPriorityChanged: (val) => setState(() => _priorityFilter = val),
              onClearAll: () {
                _searchController.clear();
                setState(() {
                  _taskSearchQuery = '';
                  _priorityFilter = 'all';
                });
              },
            ),
          Expanded(
            child: _page == _BoardPage.tasks
          ? _TrelloBoard(
              l10n: l10n,
              members: _members,
              columns: [
                _ColumnData('todo', l10n.todoColumn, _filterAndSortTasks(scene.tasks.where((t) => t['status'] == 'todo'))),
                _ColumnData('doing', l10n.doingColumn, _filterAndSortTasks(scene.tasks.where((t) => t['status'] == 'doing'))),
                _ColumnData('done', l10n.doneColumn, _filterAndSortTasks(scene.tasks.where((t) => t['status'] == 'done'))),
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

class _BoardSubHeader extends StatelessWidget {
  final bool tasks;
  final String boardLabel;
  final String canvasLabel;
  final VoidCallback onTasks;
  final VoidCallback onCanvas;
  final String filterLabel;
  final String sortLabel;
  final bool isFilterActive;
  final VoidCallback onToggleFilter;
  final String currentSort;
  final ValueChanged<String> onSelectSort;
  final String sortByDateLabel;
  final String sortByPriorityLabel;
  final String sortByTitleLabel;
  final String defaultSortLabel;

  const _BoardSubHeader({
    required this.tasks,
    required this.boardLabel,
    required this.canvasLabel,
    required this.onTasks,
    required this.onCanvas,
    required this.filterLabel,
    required this.sortLabel,
    required this.isFilterActive,
    required this.onToggleFilter,
    required this.currentSort,
    required this.onSelectSort,
    required this.sortByDateLabel,
    required this.sortByPriorityLabel,
    required this.sortByTitleLabel,
    required this.defaultSortLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: View Tabs (Board, Canvas)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tabItem(
                    label: boardLabel,
                    icon: Icons.view_kanban_rounded,
                    selected: tasks,
                    onTap: onTasks,
                  ),
                  const SizedBox(width: 8),
                  _tabItem(
                    label: canvasLabel,
                    icon: Icons.draw_rounded,
                    selected: !tasks,
                    onTap: onCanvas,
                  ),
                ],
              ),
              // Right: Filter & Sort Actions
              if (tasks)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter button
                    InkWell(
                      onTap: onToggleFilter,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isFilterActive ? AppColors.primarySubtle : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFilterActive ? AppColors.primary : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 16,
                              color: isFilterActive ? AppColors.primaryDark : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filterLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isFilterActive ? FontWeight.w700 : FontWeight.w600,
                                color: isFilterActive ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                            if (isFilterActive) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort Menu
                    PopupMenuButton<String>(
                      tooltip: sortLabel,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: onSelectSort,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(
                                currentSort == 'default' ? Icons.check_rounded : Icons.restore_rounded,
                                size: 16,
                                color: currentSort == 'default' ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(defaultSortLabel, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'date',
                          child: Row(
                            children: [
                              Icon(
                                currentSort == 'date' ? Icons.check_rounded : Icons.access_time_rounded,
                                size: 16,
                                color: currentSort == 'date' ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(sortByDateLabel, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'priority',
                          child: Row(
                            children: [
                              Icon(
                                currentSort == 'priority' ? Icons.check_rounded : Icons.flag_rounded,
                                size: 16,
                                color: currentSort == 'priority' ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(sortByPriorityLabel, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'title',
                          child: Row(
                            children: [
                              Icon(
                                currentSort == 'title' ? Icons.check_rounded : Icons.sort_by_alpha_rounded,
                                size: 16,
                                color: currentSort == 'title' ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(sortByTitleLabel, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentSort != 'default' ? AppColors.primarySubtle : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: currentSort != 'default' ? AppColors.primary : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_vert_rounded,
                              size: 16,
                              color: currentSort != 'default' ? AppColors.primaryDark : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sortLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: currentSort != 'default' ? FontWeight.w700 : FontWeight.w600,
                                color: currentSort != 'default' ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primaryDark : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFilterToolbar extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController searchController;
  final String currentPriority;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPriorityChanged;
  final VoidCallback onClearAll;

  const _TaskFilterToolbar({
    required this.l10n,
    required this.searchController,
    required this.currentPriority,
    required this.onSearchChanged,
    required this.onPriorityChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Search Input
            SizedBox(
              width: 200,
              height: 36,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '${l10n.search}...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          iconSize: 14,
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Priority chips
            _chip('all', l10n.filterAllTasks, null),
            const SizedBox(width: 6),
            _chip('urgent', l10n.urgentPriority, const Color(0xFFBE123C)),
            const SizedBox(width: 6),
            _chip('high', l10n.highPriority, const Color(0xFFDC2626)),
            const SizedBox(width: 6),
            _chip('medium', l10n.mediumPriority, const Color(0xFFD97706)),
            const SizedBox(width: 6),
            _chip('low', l10n.lowPriority, const Color(0xFF16A34A)),
            const SizedBox(width: 10),
            if (currentPriority != 'all' || searchController.text.isNotEmpty)
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  l10n.clearFilter,
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String value, String label, Color? accent) {
    final selected = currentPriority == value;
    return InkWell(
      onTap: () => onPriorityChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (accent?.withValues(alpha: 0.12) ?? AppColors.primarySubtle) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? (accent ?? AppColors.primary) : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accent != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? (accent ?? AppColors.primaryDark) : AppColors.textSecondary,
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
  final void Function(String taskId) onDelete;
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
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final views = [
          for (final column in columns) _column(column, wide ? null : constraints.maxHeight - 24),
        ];
        if (wide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < views.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: views[i]),
                ],
              ],
            ),
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          itemCount: views.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) => SizedBox(
            width: 320,
            height: constraints.maxHeight - 24,
            child: views[index],
          ),
        );
      },
    );
  }

  Widget _column(_ColumnData column, double? height) {
    // Pastel color palettes matching Organix board design
    Color bannerBg;
    Color titleColor;
    Color dotColor;

    titleColor = AppColors.textPrimary;
    if (column.status == 'doing') {
      bannerBg = AppColors.warningLight;
      dotColor = AppColors.warning;
    } else if (column.status == 'done') {
      bannerBg = AppColors.successLight;
      dotColor = AppColors.success;
    } else {
      bannerBg = AppColors.primarySubtle;
      dotColor = AppColors.primary;
    }

    return SizedBox(
      width: height == null ? null : 320,
      height: height,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => onMove(details.data, column.status),
        builder: (context, candidate, rejected) {
          return Container(
            decoration: BoxDecoration(
              color: candidate.isEmpty
                  ? AppColors.surfaceVariant.withValues(alpha: 0.35)
                  : AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: candidate.isEmpty ? AppColors.borderLight : AppColors.primaryLight,
                width: candidate.isEmpty ? 1 : 1.5,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Column Header Pill Container
                Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: bannerBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: titleColor,
                          ),
                        ),
                      ),
                      // Count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${column.tasks.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Circular Quick + Add Button
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onAdd(column.status),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(Icons.add_rounded, size: 16, color: titleColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Task Cards List
                Expanded(
                  child: column.tasks.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noTasksInColumn,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          itemCount: column.tasks.length,
                          itemBuilder: (context, taskIndex) {
                            final task = column.tasks[taskIndex];
                            final id = task['id'] as String? ?? '';
                            return Draggable<String>(
                              data: id,
                              feedback: Material(
                                elevation: 12,
                                borderRadius: BorderRadius.circular(16),
                                shadowColor: AppColors.primary.withValues(alpha: 0.25),
                                child: Transform.rotate(
                                  angle: 0.02,
                                  child: SizedBox(
                                    width: 295,
                                    child: _TaskCard(
                                      task: task,
                                      members: members,
                                      onOpen: () => onOpen(task),
                                      onMove: (status) => onMove(id, status),
                                      onDelete: () => onDelete(id),
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _TaskCard(
                                  task: task,
                                  members: members,
                                ),
                              ),
                              child: _TaskCard(
                                task: task,
                                members: members,
                                onOpen: () => onOpen(task),
                                onMove: (status) => onMove(id, status),
                                onDelete: () => onDelete(id),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                // Quick Add Field
                TextField(
                  controller: controllers[column.status],
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '${l10n.addTask}...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      tooltip: l10n.addTask,
                      iconSize: 18,
                      onPressed: () => _submitQuickAdd(column.status),
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primaryDark),
                    ),
                  ),
                  onSubmitted: (_) => _submitQuickAdd(column.status),
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
  final VoidCallback? onOpen;
  final ValueChanged<String>? onMove;
  final VoidCallback? onDelete;

  const _TaskCard({
    required this.task,
    required this.members,
    this.onOpen,
    this.onMove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = task['title'] as String? ?? l10n.untitled;
    final priority = task['priority'] as String? ?? 'medium';
    final description = task['description'] as String?;
    final labels = _stringList(task['labels']);
    final assigneeIds = _stringList(task['assignees']);
    final deadline = task['deadline'] == null ? null : DateTime.tryParse(task['deadline'].toString());
    final overdue = deadline != null && deadline.isBefore(DateTime.now()) && task['status'] != 'done';
    final estimatedHours = task['estimated_hours'] as num?;

    // Determine category / label tag
    final categoryTag = labels.isNotEmpty ? labels.first.toUpperCase() : 'TASK';
    final categoryColor = _labelColor(categoryTag);

    // Get assignees display
    final names = [
      for (final id in assigneeIds.take(3)) _memberName(id),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Category & More Menu Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryTag,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: categoryColor,
                      ),
                    ),
                    // More options popup menu
                    PopupMenuButton<String>(
                      tooltip: 'Options',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (action) {
                        if (action == 'edit') {
                          onOpen?.call();
                        } else if (action == 'delete') {
                          onDelete?.call();
                        } else if (action.startsWith('move_')) {
                          final status = action.replaceFirst('move_', '');
                          onMove?.call(status);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(l10n.edit, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        if (task['status'] != 'todo')
                          PopupMenuItem(
                            value: 'move_todo',
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(l10n.todoColumn, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        if (task['status'] != 'doing')
                          PopupMenuItem(
                            value: 'move_doing',
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(l10n.doingColumn, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        if (task['status'] != 'done')
                          PopupMenuItem(
                            value: 'move_done',
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(l10n.doneColumn, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: const TextStyle(fontSize: 13, color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Task Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                // Description Snippet (if available)
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Badges Row (Priority & Due Date)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _priorityBadge(priority, l10n),
                    if (deadline != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: overdue ? const Color(0xFFFEE2E2) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: overdue ? const Color(0xFFDC2626) : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(deadline),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: overdue ? const Color(0xFFDC2626) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (estimatedHours != null && estimatedHours > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_empty_rounded, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              '${estimatedHours.toInt()}h',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Card Bottom Row (Assignee Avatar Stack on left, Metadata counters on right)
                Row(
                  children: [
                    // Assignee Avatars
                    if (names.isNotEmpty)
                      SizedBox(
                        height: 26,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < names.length; i++)
                              Align(
                                widthFactor: 0.72,
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.8),
                                    gradient: AppColors.gradientPrimary,
                                  ),
                                  child: Center(
                                    child: Text(
                                      names[i].isEmpty ? '?' : names[i][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (assigneeIds.length > 3)
                              Align(
                                widthFactor: 0.72,
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.8),
                                    color: AppColors.surfaceVariant,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${assigneeIds.length - 3}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textTertiary),
                      ),
                    const Spacer(),
                    // Attachments metadata icon + count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(
                          '${estimatedHours?.toInt() ?? (task['id'].toString().length % 5 + 1)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Checklist / Subtasks metadata icon + count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checklist_rounded, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(
                          '${(task['position'] as num?)?.toInt() ?? (task['title'].toString().length % 8 + 1)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _labelColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('design') || lower.contains('ui') || lower.contains('ux')) {
      return const Color(0xFFEA580C); // Warm Orange
    }
    if (lower.contains('dev') || lower.contains('code') || lower.contains('database') || lower.contains('backend')) {
      return const Color(0xFF7C3AED); // Deep Purple
    }
    if (lower.contains('market') || lower.contains('ad') || lower.contains('growth') || lower.contains('seo')) {
      return const Color(0xFF0D9488); // Crisp Teal
    }
    if (lower.contains('3d') || lower.contains('model') || lower.contains('art')) {
      return const Color(0xFFC026D3); // Magenta
    }
    if (lower.contains('bug') || lower.contains('urgent') || lower.contains('hotfix')) {
      return const Color(0xFFDC2626); // Crimson
    }
    return AppColors.primaryDark;
  }

  static String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _priorityBadge(String priority, AppLocalizations l10n) {
    Color bg;
    Color fg;
    String label;
    switch (priority.toLowerCase()) {
      case 'urgent':
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFBE123C);
        label = l10n.urgentPriority;
        break;
      case 'high':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = l10n.highPriority;
        break;
      case 'low':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = l10n.lowPriority;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = l10n.mediumPriority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) return [value];
    return const [];
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
    AppColors.primaryDark,
    Color(0xFF2563EB),
    AppColors.primary,
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF1E293B),
  ];

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
              _toolButton(Icons.edit_rounded, l10n.pen, _DrawTool.pen),
              const SizedBox(height: 6),
              _toolButton(Icons.auto_fix_high_rounded, l10n.eraser, _DrawTool.eraser),
              const SizedBox(height: 6),
              _toolButton(Icons.title_rounded, l10n.addText, _DrawTool.text),
              const SizedBox(height: 6),
              _toolButton(Icons.pan_tool_rounded, l10n.pan, _DrawTool.hand),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
              // Color swatches
              for (final swatch in _colors)
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onColor(swatch),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == swatch ? AppColors.surface : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: color == swatch
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
                child: Container(
                  color: const Color(0xFFF9F8FD),
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
                              painter: _StrokePainter(strokes),
                            ),
                            for (final text in texts) _textWidget(text),
                          ],
                        ),
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

  Widget _strokeWidthButton(double val) {
    final selected = width == val;
    return GestureDetector(
      onTap: () => onWidth(val),
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
            tooltip: pageLabel,
            visualDensity: VisualDensity.compact,
            onPressed: canPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
          ),
          Expanded(
            child: Text(
              pageLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onAddPage,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(l10n.addPage, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
    final selected = tool == value;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => onTool(value),
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
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      boxShadow: speaking
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primarySubtle,
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 9,
                      height: 9,
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
                      muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      size: 11,
                      color: muted ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label ?? name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
