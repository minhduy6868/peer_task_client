import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/models/board/board.dart';
import '../../utils/error_display.dart';
import '../../utils/validators_l10n.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/board_settings_dialog.dart';
import '../theme/app_colors.dart';

const _boardAccents = [
  AppColors.primary,
  AppColors.accentTeal,
  AppColors.primaryDark,
  AppColors.warning,
];

final _workspaceNameProvider = FutureProvider.family<String, String>((ref, workspaceId) async {
  final workspace = await ref.watch(apiServiceProvider).getWorkspace(workspaceId);
  return workspace.name;
});

final workspaceBoardsProvider = FutureProvider.family<List<Board>, String>((ref, workspaceId) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getWorkspaceBoards(workspaceId);
});

final currentWorkspaceRoleProvider = FutureProvider.family<String?, String>((ref, workspaceId) async {
  final api = ref.watch(apiServiceProvider);
  final workspace = await api.getWorkspace(workspaceId);
  return workspace.role; // Returns 'owner', 'editor', or 'viewer'
});

class _BoardCounts {
  final int todo;
  final int doing;
  final int done;
  final int overdue;

  const _BoardCounts({this.todo = 0, this.doing = 0, this.done = 0, this.overdue = 0});

  int get total => todo + doing + done;
}

int _asCount(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

final workspaceBoardSummaryProvider = FutureProvider.autoDispose.family<Map<String, _BoardCounts>, String>((ref, workspaceId) async {
  final rows = await ref.watch(apiServiceProvider).getWorkspaceBoardSummary(workspaceId);
  return {
    for (final row in rows)
      if (row['board_id'] is String)
        row['board_id'] as String: _BoardCounts(
          todo: _asCount(row['todo_count']),
          doing: _asCount(row['doing_count']),
          done: _asCount(row['done_count']),
          overdue: _asCount(row['overdue_count']),
        ),
  };
});

class WorkItem {
  final String id;
  final String title;
  final String boardId;
  final String boardName;
  final String status;
  final String? priority;
  final DateTime? deadline;

  const WorkItem({
    required this.id,
    required this.title,
    required this.boardId,
    required this.boardName,
    required this.status,
    this.priority,
    this.deadline,
  });

  bool get isOverdue => deadline != null && deadline!.isBefore(DateTime.now());
}

final myWorkspaceTasksProvider = FutureProvider.autoDispose.family<List<WorkItem>, String>((ref, workspaceId) async {
  final rows = await ref.watch(apiServiceProvider).getMyTasks(workspaceId: workspaceId, open: false, limit: 50);
  return [
    for (final row in rows)
      if (row['id'] is String && row['board_id'] is String)
        WorkItem(
          id: row['id'] as String,
          title: (row['title'] as String?)?.trim().isNotEmpty == true ? row['title'] as String : '',
          boardId: row['board_id'] as String,
          boardName: (row['board_name'] as String?) ?? '',
          status: (row['status'] as String?) ?? 'todo',
          priority: row['priority'] as String?,
          deadline: row['deadline'] == null ? null : DateTime.tryParse(row['deadline'].toString()),
        ),
  ];
});

enum BoardFilter { all, owner, editor, viewer }
enum BoardStatusFilter { all, active, completed }
enum BoardSortBy { recent, name }

class BoardsScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  final int initialTab; // 0: Boards, 1: Tasks

  const BoardsScreen({
    super.key,
    required this.workspaceId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  BoardFilter _filter = BoardFilter.all;
  BoardStatusFilter _statusFilter = BoardStatusFilter.all;
  BoardSortBy _sortBy = BoardSortBy.recent;

  // Task-specific filter states
  final _taskSearchController = TextEditingController();
  String _taskQuery = '';
  String _taskStatus = 'all'; // all, doing, todo, done, overdue
  String? _taskBoardId;
  String? _taskPriority;
  String _taskSortBy = 'deadline'; // deadline, priority, title

  late int _activeTab; // 0: Boards, 1: Tasks

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant BoardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _activeTab = widget.initialTab;
    }
  }

  Future<void> _openBoardSettings(Board board, {int initialTabIndex = 0}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => BoardSettingsDialog(
        boardId: board.id,
        boardName: board.name,
        boardDescription: board.description,
        workspaceId: widget.workspaceId,
        initialTabIndex: initialTabIndex,
      ),
    );
    if ((result == 'deleted' || result == true) && mounted) {
      ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
      ref.invalidate(workspaceBoardSummaryProvider(widget.workspaceId));
      ref.invalidate(myWorkspaceTasksProvider(widget.workspaceId));
      ref.invalidate(boardMembersProvider(board.id));
    }
  }

  Future<void> _openBoardMembers(Board board) async {
    await _openBoardSettings(board, initialTabIndex: 1);
  }

  void _showRenameBoardDialog(Board board) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: board.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.renameBoard,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.boardName,
                  hintText: l10n.enterBoardName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: ValidatorsL10n.required(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newName = controller.text.trim();
              Navigator.pop(dialogContext);
              if (newName == board.name) return;
              try {
                final api = ref.read(apiServiceProvider);
                await api.updateBoard(boardId: board.id, name: newName);
                if (mounted) {
                  ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                  ErrorHandler.showSuccess(context, 'Đã đổi tên bảng thành "$newName"');
                }
              } catch (e) {
                if (mounted) context.showErrorSnackBar(e);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditDescriptionDialog(Board board) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: board.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.editDescription,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: TextFormField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.boardDescription,
            hintText: l10n.boardDescriptionOptional,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDesc = controller.text.trim();
              Navigator.pop(dialogContext);
              try {
                final api = ref.read(apiServiceProvider);
                await api.updateBoard(boardId: board.id, description: newDesc.isEmpty ? null : newDesc);
                if (mounted) {
                  ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                  ErrorHandler.showSuccess(context, 'Đã cập nhật mô tả bảng');
                }
              } catch (e) {
                if (mounted) context.showErrorSnackBar(e);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showArchiveBoardDialog(Board board) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.archive_outlined, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.archiveBoard,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.archiveBoardConfirm,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ErrorHandler.showSuccess(context, 'Đã lưu trữ bảng "${board.name}"');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.archiveBoard),
          ),
        ],
      ),
    );
  }

  void _showDeleteBoardDialog(Board board) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.deleteBoard,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa bảng "${board.name}" không? Tất cả công việc trong bảng sẽ bị xóa vĩnh viễn.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteBoard(board.id);
                if (mounted) {
                  ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                  ref.invalidate(workspaceBoardSummaryProvider(widget.workspaceId));
                  ref.invalidate(myWorkspaceTasksProvider(widget.workspaceId));
                  ErrorHandler.showSuccess(context, 'Đã xóa bảng "${board.name}"');
                }
              } catch (e) {
                if (mounted) context.showErrorSnackBar(e);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _taskSearchController.dispose();
    super.dispose();
  }

  void _showCreateBoardDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.9,
          ),
          child: IntrinsicHeight(
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề + icon
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 12 : 8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primaryDark,
                              size: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              dialogL10n.createNewBoard,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Board Name
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: dialogL10n.boardName,
                          hintText: dialogL10n.enterBoardName,
                          prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        ),
                        validator: ValidatorsL10n.required(context),
                        autofocus: true,
                      ),
                      const SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: dialogL10n.boardDescription,
                          hintText: dialogL10n.boardDescriptionOptional,
                          prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Nút Cancel + Create
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(dialogL10n.cancel, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                final name = nameController.text.trim();
                                try {
                                  final api = ref.read(apiServiceProvider);
                                  await api.createBoard(
                                    workspaceId: widget.workspaceId,
                                    name: name,
                                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                                    ref.invalidate(workspaceBoardSummaryProvider(widget.workspaceId));
                                    ref.invalidate(myWorkspaceTasksProvider(widget.workspaceId));
                                    final l10n = AppLocalizations.of(context);
                                    ErrorHandler.showSuccess(
                                      context,
                                      l10n?.boardCreatedSuccess(name) ?? 'Board "$name" created successfully!',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    context.showErrorSnackBar(e);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(dialogL10n.create, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(workspaceBoardsProvider(widget.workspaceId));
    final roleAsync = ref.watch(currentWorkspaceRoleProvider(widget.workspaceId));
    final workspaceName = ref.watch(_workspaceNameProvider(widget.workspaceId)).value;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).user;
    final greetingName = user?.name?.isNotEmpty == true ? user!.name! : (user?.email ?? '');

    // Check if user can create boards (owner or editor)
    final canCreateBoard = roleAsync.maybeWhen(
      data: (role) => role == 'owner' || role == 'editor',
      orElse: () => false,
    );
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: (!isDesktop && canCreateBoard)
          ? FloatingActionButton.extended(
              onPressed: _showCreateBoardDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(l10n.newBoard, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              elevation: 2,
            )
          : null,
      body: boardsAsync.when(
        loading: () => _buildLoadingSkeleton(context),
        error: (error, stack) => ErrorDisplay.buildErrorWidget(
          error,
          retryLabel: AppLocalizations.of(context)!.retry,
          onRetry: () {
            ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
            ref.invalidate(workspaceBoardSummaryProvider(widget.workspaceId));
            ref.invalidate(myWorkspaceTasksProvider(widget.workspaceId));
          },
        ),
        data: (boards) {
          final role = roleAsync.valueOrNull;
          final isWorkspaceOwner = role == 'owner';
          final countAll = boards.length;
          final countOwner = boards.where((b) => b.isBoardOwner == true || isWorkspaceOwner).length;
          final countEditor = boards.where((b) {
            final isOwn = b.isBoardOwner == true || isWorkspaceOwner;
            return !isOwn && (b.permission == 'edit' || (b.permission == null && role == 'editor'));
          }).length;
          final countViewer = boards.where((b) {
            final isOwn = b.isBoardOwner == true || isWorkspaceOwner;
            final isEd = b.permission == 'edit' || (b.permission == null && role == 'editor');
            return !isOwn && !isEd && (b.permission == 'view' || role == 'viewer');
          }).length;

          final summary = ref.watch(workspaceBoardSummaryProvider(widget.workspaceId)).valueOrNull ?? const {};
          final query = _query.trim().toLowerCase();
          final visible = boards.where((board) {
            final isOwn = board.isBoardOwner == true || isWorkspaceOwner;
            final isEd = !isOwn && (board.permission == 'edit' || (board.permission == null && role == 'editor'));
            final isVi = !isOwn && !isEd && (board.permission == 'view' || role == 'viewer');

            final matchesFilter = switch (_filter) {
              BoardFilter.all => true,
              BoardFilter.owner => isOwn,
              BoardFilter.editor => isEd,
              BoardFilter.viewer => isVi,
            };
            if (!matchesFilter) return false;

            // Status filter
            final bCounts = summary[board.id] ?? const _BoardCounts();
            final isCompleted = bCounts.total > 0 && bCounts.done == bCounts.total;
            final matchesStatus = switch (_statusFilter) {
              BoardStatusFilter.all => true,
              BoardStatusFilter.active => !isCompleted,
              BoardStatusFilter.completed => isCompleted,
            };
            if (!matchesStatus) return false;

            if (query.isNotEmpty) {
              final name = board.name.toLowerCase();
              final description = board.description?.toLowerCase() ?? '';
              if (!name.contains(query) && !description.contains(query)) return false;
            }
            return true;
          }).toList();

          // Sắp xếp
          if (_sortBy == BoardSortBy.name) {
            visible.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else {
            // Sắp xếp theo cập nhật gần nhất
            visible.sort((a, b) {
              final aDate = a.updatedAt ?? a.createdAt;
              final bDate = b.updatedAt ?? b.createdAt;
              if (aDate != null && bDate != null) {
                return bDate.compareTo(aDate);
              }
              return 0;
            });
          }

          final workAsync = ref.watch(myWorkspaceTasksProvider(widget.workspaceId));
          final rawWork = workAsync.valueOrNull ?? const <WorkItem>[];
          final work = rawWork;
          final totalDone = summary.values.fold<int>(0, (sum, c) => sum + c.done);

          final taskDoingCount = rawWork.where((t) => t.status == 'doing').length;
          final taskTodoCount = rawWork.where((t) => t.status == 'todo').length;
          final taskDoneCount = rawWork.where((t) => t.status == 'done').length;
          final taskOverdueCount = rawWork.where((t) => t.isOverdue).length;

          final taskQuery = _taskQuery.trim().toLowerCase();
          final filteredTasks = rawWork.where((item) {
            if (taskQuery.isNotEmpty) {
              if (!item.title.toLowerCase().contains(taskQuery) &&
                  !item.boardName.toLowerCase().contains(taskQuery)) {
                return false;
              }
            }
            if (_taskStatus == 'doing' && item.status != 'doing') return false;
            if (_taskStatus == 'todo' && item.status != 'todo') return false;
            if (_taskStatus == 'done' && item.status != 'done') return false;
            if (_taskStatus == 'overdue' && !item.isOverdue) return false;

            if (_taskBoardId != null && item.boardId != _taskBoardId) return false;

            if (_taskPriority != null) {
              if (_taskPriority == 'high' && item.priority != 'high' && item.priority != 'urgent') {
                return false;
              }
              if (_taskPriority == 'medium' && item.priority != 'medium') return false;
              if (_taskPriority == 'low' && item.priority != 'low') return false;
            }
            return true;
          }).toList();

          if (_taskSortBy == 'priority') {
            final pWeights = {'urgent': 3, 'high': 3, 'medium': 2, 'low': 1};
            filteredTasks.sort((a, b) {
              final aw = pWeights[a.priority] ?? 0;
              final bw = pWeights[b.priority] ?? 0;
              return bw.compareTo(aw);
            });
          } else if (_taskSortBy == 'title') {
            filteredTasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          } else {
            filteredTasks.sort((a, b) {
              if (a.deadline == null && b.deadline == null) return 0;
              if (a.deadline == null) return 1;
              if (b.deadline == null) return -1;
              return a.deadline!.compareTo(b.deadline!);
            });
          }

          final paddingH = isDesktop ? 28.0 : 16.0;

          // Top Segmented Button separating Boards and Tasks
          final topSegmentSwitcher = Container(
            padding: EdgeInsets.fromLTRB(paddingH, 12, paddingH, 6),
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    icon: const Icon(Icons.dashboard_rounded, size: 16),
                    label: Text(
                      '${l10n.workBoards} (${visible.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                    label: Text(
                      '${l10n.yourTasks} (${rawWork.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
                selected: {_activeTab},
                onSelectionChanged: (selected) {
                  setState(() => _activeTab = selected.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primarySubtle,
                  selectedForegroundColor: AppColors.primaryDark,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topSegmentSwitcher,
              if (_activeTab == 0) ...[
                // ===== PHẦN 1: BẢNG LÀM VIỆC (BOARDS) =====
                _HomeHeader(
                  greeting: l10n.welcome,
                  name: greetingName,
                  workspaceName: workspaceName ?? '',
                  role: role != null
                      ? (role == 'owner'
                          ? l10n.owner
                          : (role == 'editor'
                              ? l10n.editor
                              : (role == 'viewer' ? l10n.viewer : role)))
                      : null,
                  totalBoards: boards.length,
                  totalWork: rawWork.length,
                  totalDone: totalDone,
                  canCreate: canCreateBoard,
                  onCreateBoard: _showCreateBoardDialog,
                  searchController: _searchController,
                  searchHint: l10n.searchBoards,
                  query: _query,
                  onSearch: (value) => setState(() => _query = value),
                  onClearSearch: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  selectedFilter: _filter,
                  onSelectFilter: (f) => setState(() => _filter = f),
                  statusFilter: _statusFilter,
                  onSelectStatusFilter: (s) => setState(() => _statusFilter = s),
                  sortBy: _sortBy,
                  onSelectSortBy: (s) => setState(() => _sortBy = s),
                  countAll: countAll,
                  countOwner: countOwner,
                  countEditor: countEditor,
                  countViewer: countViewer,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720;
                      final extraWide = constraints.maxWidth >= 1200;
                      final hasFilterOrQuery = _filter != BoardFilter.all || _statusFilter != BoardStatusFilter.all || query.isNotEmpty;
                      final showAddCard = canCreateBoard && !hasFilterOrQuery;
                      final boardCount = visible.length + (showAddCard ? 1 : 0);

                      if (visible.isEmpty && !showAddCard) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(paddingH, 0, paddingH, 16),
                          child: _EmptyBoards(
                            canCreate: hasFilterOrQuery || canCreateBoard,
                            onCreate: hasFilterOrQuery
                                ? () {
                                    setState(() {
                                      _query = '';
                                      _searchController.clear();
                                      _filter = BoardFilter.all;
                                      _statusFilter = BoardStatusFilter.all;
                                      _sortBy = BoardSortBy.recent;
                                    });
                                  }
                                : _showCreateBoardDialog,
                            title: hasFilterOrQuery ? l10n.noBoardsMatchingFilter : l10n.noBoardsYet,
                            subtitle: hasFilterOrQuery ? l10n.clearFilter : null,
                            action: hasFilterOrQuery ? l10n.clearFilter : l10n.createBoard,
                          ),
                        );
                      }

                      if (!wide) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(paddingH, 0, paddingH, 16),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: boardCount,
                            itemBuilder: (context, index) {
                              if (showAddCard && index == visible.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SizedBox(
                                    height: 180,
                                    child: _NewBoardCard(onTap: _showCreateBoardDialog),
                                  ),
                                );
                              }
                              final board = visible[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  height: 224,
                                  child: _BoardCard(
                                    board: board,
                                    accent: _boardAccents[index % _boardAccents.length],
                                    counts: summary[board.id] ?? const _BoardCounts(),
                                    workspaceRole: role,
                                    onTap: () => context.go('/board/${board.id}'),
                                    onRename: () => _showRenameBoardDialog(board),
                                    onEditDesc: () => _showEditDescriptionDialog(board),
                                    onOpenMembers: () => _openBoardMembers(board),
                                    onArchive: () => _showArchiveBoardDialog(board),
                                    onDelete: () => _showDeleteBoardDialog(board),
                                    onSettings: () => _openBoardSettings(board),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.fromLTRB(paddingH, 0, paddingH, 16),
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: extraWide ? 3 : 2,
                            mainAxisExtent: 215,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: boardCount,
                          itemBuilder: (context, index) {
                            if (showAddCard && index == visible.length) {
                              return _NewBoardCard(onTap: _showCreateBoardDialog);
                            }
                            final board = visible[index];
                            return _BoardCard(
                              board: board,
                              accent: _boardAccents[index % _boardAccents.length],
                              counts: summary[board.id] ?? const _BoardCounts(),
                              workspaceRole: role,
                              onTap: () => context.go('/board/${board.id}'),
                              onRename: () => _showRenameBoardDialog(board),
                              onEditDesc: () => _showEditDescriptionDialog(board),
                              onOpenMembers: () => _openBoardMembers(board),
                              onArchive: () => _showArchiveBoardDialog(board),
                              onDelete: () => _showDeleteBoardDialog(board),
                              onSettings: () => _openBoardSettings(board),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // ===== PHẦN 2: CÔNG VIỆC CỦA BẠN (TASKS) =====
                _TasksHeader(
                  greeting: l10n.welcome,
                  name: greetingName,
                  workspaceName: workspaceName ?? '',
                  role: role != null
                      ? (role == 'owner'
                          ? l10n.owner
                          : (role == 'editor'
                              ? l10n.editor
                              : (role == 'viewer' ? l10n.viewer : role)))
                      : null,
                  totalTasks: rawWork.length,
                  doingCount: taskDoingCount,
                  todoCount: taskTodoCount,
                  doneCount: taskDoneCount,
                  overdueCount: taskOverdueCount,
                  searchController: _taskSearchController,
                  searchHint: 'Tìm kiếm công việc theo tiêu đề hoặc bảng...',
                  query: _taskQuery,
                  onSearch: (value) => setState(() => _taskQuery = value),
                  onClearSearch: () {
                    _taskSearchController.clear();
                    setState(() => _taskQuery = '');
                  },
                  statusFilter: _taskStatus,
                  onSelectStatusFilter: (s) => setState(() => _taskStatus = s),
                  priorityFilter: _taskPriority,
                  onSelectPriorityFilter: (p) => setState(() => _taskPriority = p),
                  sortBy: _taskSortBy,
                  onSelectSortBy: (s) => setState(() => _taskSortBy = s),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(paddingH, 0, paddingH, 16),
                    child: _TasksPanel(
                      loading: workAsync.isLoading && !workAsync.hasValue,
                      failed: workAsync.hasError,
                      items: filteredTasks,
                      onRetry: () => ref.invalidate(myWorkspaceTasksProvider(widget.workspaceId)),
                      onClearFilter: () {
                        setState(() {
                          _taskQuery = '';
                          _taskSearchController.clear();
                          _taskStatus = 'all';
                          _taskPriority = null;
                          _taskSortBy = 'deadline';
                        });
                      },
                      onOpen: (boardId) => context.go('/board/$boardId'),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),

    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final padding = isLargeScreen ? 28.0 : 16.0;

    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverToBoxAdapter(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isLargeScreen ? 400 : double.infinity,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 232,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                childCount: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String workspaceName;
  final String? role;
  final int totalBoards;
  final int totalWork;
  final int totalDone;
  final bool canCreate;
  final VoidCallback onCreateBoard;
  final TextEditingController searchController;
  final String searchHint;
  final String query;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final BoardFilter selectedFilter;
  final ValueChanged<BoardFilter> onSelectFilter;
  final BoardStatusFilter statusFilter;
  final ValueChanged<BoardStatusFilter> onSelectStatusFilter;
  final BoardSortBy sortBy;
  final ValueChanged<BoardSortBy> onSelectSortBy;
  final int countAll;
  final int countOwner;
  final int countEditor;
  final int countViewer;

  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.workspaceName,
    this.role,
    required this.totalBoards,
    required this.totalWork,
    required this.totalDone,
    required this.canCreate,
    required this.onCreateBoard,
    required this.searchController,
    required this.searchHint,
    required this.query,
    required this.onSearch,
    required this.onClearSearch,
    required this.selectedFilter,
    required this.onSelectFilter,
    required this.statusFilter,
    required this.onSelectStatusFilter,
    required this.sortBy,
    required this.onSelectSortBy,
    required this.countAll,
    required this.countOwner,
    required this.countEditor,
    required this.countViewer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;
          final paddingH = constraints.maxWidth >= 960 ? 28.0 : 16.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(paddingH, 16, paddingH, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner: Title, Subtitle, Standout Create Button, Stats
                Container(
                  padding: EdgeInsets.all(isWide ? 22 : 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFFAF7FF), Color(0xFFF3EDFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                    boxShadow: AppColors.elegantCardShadow,
                  ),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildWelcomeInfo(context, l10n, isWide: true),
                            ),
                            const SizedBox(width: 20),
                            _buildStatsAndAction(l10n, isWide: true),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeInfo(context, l10n, isWide: false),
                            const SizedBox(height: 14),
                            _buildStatsAndAction(l10n, isWide: false),
                          ],
                        ),
                ),
                const SizedBox(height: 14),

                // Search & Filter Toolbar: Name search + Role filter + Status filter + Sort
                if (isWide)
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: _buildSearchBox(l10n),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChipsRow(l10n),
                              const SizedBox(width: 10),
                              _buildStatusFilterButton(l10n),
                              const SizedBox(width: 8),
                              _buildSortButton(l10n),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBox(l10n),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChipsRow(l10n),
                            const SizedBox(width: 10),
                            _buildStatusFilterButton(l10n),
                            const SizedBox(width: 8),
                            _buildSortButton(l10n),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBox(AppLocalizations l10n) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  tooltip: l10n.clearSearch,
                  onPressed: onClearSearch,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilterChip(
          label: l10n.filterAll,
          count: countAll,
          isSelected: selectedFilter == BoardFilter.all,
          onTap: () => onSelectFilter(BoardFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: l10n.filterOwner,
          count: countOwner,
          isSelected: selectedFilter == BoardFilter.owner,
          onTap: () => onSelectFilter(BoardFilter.owner),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: l10n.filterEditor,
          count: countEditor,
          isSelected: selectedFilter == BoardFilter.editor,
          onTap: () => onSelectFilter(BoardFilter.editor),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: l10n.filterViewer,
          count: countViewer,
          isSelected: selectedFilter == BoardFilter.viewer,
          onTap: () => onSelectFilter(BoardFilter.viewer),
        ),
      ],
    );
  }

  Widget _buildStatusFilterButton(AppLocalizations l10n) {
    final isFilteringStatus = statusFilter != BoardStatusFilter.all;
    final label = switch (statusFilter) {
      BoardStatusFilter.all => l10n.filterAllStatus,
      BoardStatusFilter.active => l10n.filterActive,
      BoardStatusFilter.completed => l10n.filterCompleted,
    };

    return PopupMenuButton<BoardStatusFilter>(
      tooltip: 'Lọc trạng thái dự án',
      initialValue: statusFilter,
      onSelected: onSelectStatusFilter,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: isFilteringStatus ? AppColors.primarySubtle : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFilteringStatus ? AppColors.primary : AppColors.border,
            width: isFilteringStatus ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 14,
              color: isFilteringStatus ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isFilteringStatus ? FontWeight.w700 : FontWeight.w500,
                color: isFilteringStatus ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isFilteringStatus ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: BoardStatusFilter.all,
          child: Text(l10n.filterAllStatus, style: const TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: BoardStatusFilter.active,
          child: Text(l10n.filterActive, style: const TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: BoardStatusFilter.completed,
          child: Text(l10n.filterCompleted, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildSortButton(AppLocalizations l10n) {
    final label = sortBy == BoardSortBy.recent ? l10n.sortByRecent : l10n.sortByName;

    return PopupMenuButton<BoardSortBy>(
      tooltip: 'Sắp xếp danh sách',
      initialValue: sortBy,
      onSelected: onSelectSortBy,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: BoardSortBy.recent,
          child: Text(l10n.sortByRecent, style: const TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: BoardSortBy.name,
          child: Text(l10n.sortByName, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildWelcomeInfo(BuildContext context, AppLocalizations l10n, {required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top tags: Brand + User chip + Workspace + Role
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!isWide)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    try {
                      context.go('/workspaces');
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diversity_3_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'PeerTask',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (name.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8.5,
                      backgroundColor: AppColors.primarySubtle,
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (workspaceName.isNotEmpty) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    try {
                      context.go('/workspaces');
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business_center_outlined, size: 13, color: AppColors.primary),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            workspaceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (role != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 11, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      role!,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // ① Tiêu đề: Bảng làm việc
        Text(
          l10n.workBoards,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isWide ? 26 : 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        // ① Mô tả ngắn: Quản lý và theo dõi các dự án của bạn.
        Text(
          l10n.workBoardsDesc,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsAndAction(AppLocalizations l10n, {required bool isWide}) {
    final createBtn = canCreate
        ? ElevatedButton.icon(
            onPressed: onCreateBoard,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: Text(
              l10n.createNewBoard,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.primary.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : const SizedBox.shrink();

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canCreate) ...[
            createBtn,
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  icon: Icons.dashboard_rounded,
                  iconColor: AppColors.primary,
                  value: '$totalBoards',
                  label: l10n.boards,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricPill(
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: AppColors.warning,
                  value: '$totalWork',
                  label: l10n.yourWork,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricPill(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  value: '$totalDone',
                  label: l10n.done,
                  isCompact: true,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetricPill(
          icon: Icons.dashboard_rounded,
          iconColor: AppColors.primary,
          value: '$totalBoards',
          label: l10n.boards,
        ),
        _MetricPill(
          icon: Icons.assignment_turned_in_rounded,
          iconColor: AppColors.warning,
          value: '$totalWork',
          label: l10n.yourWork,
        ),
        _MetricPill(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          value: '$totalDone',
          label: l10n.done,
        ),
        createBtn,
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isCompact;

  const _MetricPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 4.5 : 5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: isCompact ? 13 : 14, color: iconColor),
          ),
          SizedBox(width: isCompact ? 6 : 8),
          if (isCompact)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String workspaceName;
  final String? role;
  final int totalTasks;
  final int doingCount;
  final int todoCount;
  final int doneCount;
  final int overdueCount;
  final TextEditingController searchController;
  final String searchHint;
  final String query;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final String statusFilter;
  final ValueChanged<String> onSelectStatusFilter;
  final String? priorityFilter;
  final ValueChanged<String?> onSelectPriorityFilter;
  final String sortBy;
  final ValueChanged<String> onSelectSortBy;

  const _TasksHeader({
    required this.greeting,
    required this.name,
    required this.workspaceName,
    this.role,
    required this.totalTasks,
    required this.doingCount,
    required this.todoCount,
    required this.doneCount,
    required this.overdueCount,
    required this.searchController,
    required this.searchHint,
    required this.query,
    required this.onSearch,
    required this.onClearSearch,
    required this.statusFilter,
    required this.onSelectStatusFilter,
    required this.priorityFilter,
    required this.onSelectPriorityFilter,
    required this.sortBy,
    required this.onSelectSortBy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;
          final paddingH = constraints.maxWidth >= 960 ? 28.0 : 16.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(paddingH, 16, paddingH, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner
                Container(
                  padding: EdgeInsets.all(isWide ? 22 : 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFFAF7FF), Color(0xFFF3EDFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                    boxShadow: AppColors.elegantCardShadow,
                  ),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildWelcomeInfo(context, l10n, isWide: true)),
                            const SizedBox(width: 20),
                            _buildStats(l10n, isWide: true),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeInfo(context, l10n, isWide: false),
                            const SizedBox(height: 14),
                            _buildStats(l10n, isWide: false),
                          ],
                        ),
                ),
                const SizedBox(height: 14),

                // Search & Filter Toolbar
                if (isWide)
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: _buildSearchBox(l10n),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusChipsRow(l10n),
                              const SizedBox(width: 10),
                              _buildPriorityFilterButton(l10n),
                              const SizedBox(width: 8),
                              _buildSortButton(l10n),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBox(l10n),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChipsRow(l10n),
                            const SizedBox(width: 10),
                            _buildPriorityFilterButton(l10n),
                            const SizedBox(width: 8),
                            _buildSortButton(l10n),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBox(AppLocalizations l10n) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  tooltip: l10n.clearSearch,
                  onPressed: onClearSearch,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStatusChipsRow(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilterChip(
          label: l10n.filterAll,
          count: totalTasks,
          isSelected: statusFilter == 'all',
          onTap: () => onSelectStatusFilter('all'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: l10n.inProgress,
          count: doingCount,
          isSelected: statusFilter == 'doing',
          onTap: () => onSelectStatusFilter('doing'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: l10n.todo,
          count: todoCount,
          isSelected: statusFilter == 'todo',
          onTap: () => onSelectStatusFilter('todo'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: l10n.done,
          count: doneCount,
          isSelected: statusFilter == 'done',
          onTap: () => onSelectStatusFilter('done'),
        ),
        if (overdueCount > 0) ...[
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.overdue,
            count: overdueCount,
            isSelected: statusFilter == 'overdue',
            onTap: () => onSelectStatusFilter('overdue'),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityFilterButton(AppLocalizations l10n) {
    final isFilteringPriority = priorityFilter != null;
    final label = switch (priorityFilter) {
      'high' => l10n.highPriority,
      'medium' => l10n.mediumPriority,
      'low' => l10n.lowPriority,
      _ => 'Mức ưu tiên',
    };

    return PopupMenuButton<String?>(
      tooltip: 'Lọc theo độ ưu tiên',
      initialValue: priorityFilter,
      onSelected: onSelectPriorityFilter,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: isFilteringPriority ? AppColors.primarySubtle : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFilteringPriority ? AppColors.primary : AppColors.border,
            width: isFilteringPriority ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 14,
              color: isFilteringPriority ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isFilteringPriority ? FontWeight.w700 : FontWeight.w500,
                color: isFilteringPriority ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isFilteringPriority ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('Tất cả độ ưu tiên', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem<String?>(
          value: 'high',
          child: Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text(l10n.highPriority, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem<String?>(
          value: 'medium',
          child: Row(
            children: [
              const Icon(Icons.remove_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(l10n.mediumPriority, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem<String?>(
          value: 'low',
          child: Row(
            children: [
              const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Text(l10n.lowPriority, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortButton(AppLocalizations l10n) {
    final label = switch (sortBy) {
      'priority' => 'Ưu tiên',
      'title' => 'Tên việc',
      _ => 'Hạn chót',
    };

    return PopupMenuButton<String>(
      tooltip: 'Sắp xếp công việc',
      initialValue: sortBy,
      onSelected: onSelectSortBy,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'deadline',
          child: Text('Hạn chót gần nhất', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'priority',
          child: Text('Mức độ ưu tiên', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'title',
          child: Text('Tên công việc (A-Z)', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildWelcomeInfo(BuildContext context, AppLocalizations l10n, {required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top tags: Brand + User chip + Workspace + Role
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!isWide)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    try {
                      context.go('/workspaces');
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diversity_3_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'PeerTask',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (name.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8.5,
                      backgroundColor: AppColors.primarySubtle,
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (workspaceName.isNotEmpty) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    try {
                      context.go('/workspaces');
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business_center_outlined, size: 13, color: AppColors.primary),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            workspaceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (role != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 11, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      role!,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Tiêu đề: Công việc của bạn
        Text(
          l10n.yourTasks,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isWide ? 26 : 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        // Mô tả ngắn: Xem và quản lý tất cả nhiệm vụ được giao cho bạn.
        Text(
          l10n.yourTasksDesc,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(AppLocalizations l10n, {required bool isWide}) {
    if (!isWide) {
      return Row(
        children: [
          Expanded(
            child: _MetricPill(
              icon: Icons.flash_on_rounded,
              iconColor: AppColors.primary,
              value: '$doingCount',
              label: l10n.inProgress,
              isCompact: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricPill(
              icon: Icons.checklist_rtl_rounded,
              iconColor: const Color(0xFF6366F1),
              value: '$todoCount',
              label: l10n.todo,
              isCompact: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricPill(
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.success,
              value: '$doneCount',
              label: l10n.done,
              isCompact: true,
            ),
          ),
          if (overdueCount > 0) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _MetricPill(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.error,
                value: '$overdueCount',
                label: l10n.overdue,
                isCompact: true,
              ),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetricPill(
          icon: Icons.flash_on_rounded,
          iconColor: AppColors.primary,
          value: '$doingCount',
          label: l10n.inProgress,
        ),
        _MetricPill(
          icon: Icons.checklist_rtl_rounded,
          iconColor: const Color(0xFF6366F1),
          value: '$todoCount',
          label: l10n.todo,
        ),
        _MetricPill(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          value: '$doneCount',
          label: l10n.done,
        ),
        if (overdueCount > 0)
          _MetricPill(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.error,
            value: '$overdueCount',
            label: l10n.overdue,
          ),
      ],
    );
  }
}

class _NewBoardCard extends StatefulWidget {
  final VoidCallback onTap;

  const _NewBoardCard({required this.onTap});

  @override
  State<_NewBoardCard> createState() => _NewBoardCardState();
}

class _NewBoardCardState extends State<_NewBoardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primarySubtle.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? AppColors.primary : AppColors.border,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered ? AppColors.hoverShadow : AppColors.elegantCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isHovered ? AppColors.gradientPrimary : null,
                      color: _isHovered ? null : AppColors.primarySubtle,
                      shape: BoxShape.circle,
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 26,
                        color: _isHovered ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.createNewBoard,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isHovered ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createBoardCardDesc,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBoards extends StatelessWidget {
  final bool canCreate;
  final VoidCallback onCreate;
  final String title;
  final String? subtitle;
  final String action;

  const _EmptyBoards({
    required this.canCreate,
    required this.onCreate,
    required this.title,
    this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.elegantCardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: subtitle != null
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onCreate,
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      l10n.createFirstBoard,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
            ),
            if (canCreate) ...[
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCreate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          action == l10n.clearFilter ? Icons.filter_alt_off_rounded : Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          action,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends ConsumerStatefulWidget {
  final Board board;
  final Color accent;
  final _BoardCounts counts;
  final String? workspaceRole;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onEditDesc;
  final VoidCallback onOpenMembers;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onSettings;

  const _BoardCard({
    required this.board,
    required this.accent,
    required this.counts,
    this.workspaceRole,
    required this.onTap,
    required this.onRename,
    required this.onEditDesc,
    required this.onOpenMembers,
    required this.onArchive,
    required this.onDelete,
    required this.onSettings,
  });

  @override
  ConsumerState<_BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends ConsumerState<_BoardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = widget.counts.total == 0 ? 0.0 : widget.counts.done / widget.counts.total;
    final isOwner = widget.board.isBoardOwner == true || widget.workspaceRole == 'owner';
    final canManageMembers = isOwner || widget.workspaceRole == 'editor';
    final membersAsync = ref.watch(boardMembersProvider(widget.board.id));
    final members = membersAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.accent.withValues(alpha: 0.55)
                : AppColors.border,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered ? AppColors.hoverShadow : AppColors.elegantCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent gradient stripe on top
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accent,
                        widget.accent.withValues(alpha: 0.65),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header: Icon + Title + Role Badge + Settings Popup Menu
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: widget.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.view_kanban_rounded,
                                color: widget.accent,
                                size: 20,
                              ),
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
                                          widget.board.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _RoleBadge(
                                        isOwner: isOwner,
                                        permission: widget.board.permission,
                                        workspaceRole: widget.workspaceRole,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  if (widget.board.description?.isNotEmpty == true)
                                    Text(
                                      widget.board.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    )
                                  else
                                    Text(
                                      l10n.openBoardHint,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz_rounded, size: 20),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tooltip: l10n.boardSettings,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context) => [
                                if (canManageMembers)
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.renameBoard,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (canManageMembers)
                                  PopupMenuItem(
                                    value: 'edit_desc',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.description_outlined, size: 16, color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.editDescription,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'members',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.manageMembers,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canManageMembers)
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.archive_outlined, size: 16, color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.archiveBoard,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (isOwner)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.deleteBoard,
                                            style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'rename':
                                    widget.onRename();
                                    break;
                                  case 'edit_desc':
                                    widget.onEditDesc();
                                    break;
                                  case 'members':
                                    widget.onOpenMembers();
                                    break;
                                  case 'archive':
                                    widget.onArchive();
                                    break;
                                  case 'delete':
                                    widget.onDelete();
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Members Section
                        _BoardMembersRow(
                          members: members,
                          canManage: canManageMembers,
                          onManage: widget.onOpenMembers,
                        ),
                        const Spacer(),

                        // Progress Section
                        Row(
                          children: [
                            Text(
                              '${widget.counts.total} ${l10n.tasks.toLowerCase()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (widget.counts.overdue > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.error),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${widget.counts.overdue} ${l10n.overdue.toLowerCase()}',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: widget.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: AppColors.borderLight,
                            color: widget.accent,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Bottom Row: Status Chips & Hover Arrow
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _CountChip(
                                    label: l10n.todo,
                                    count: widget.counts.todo,
                                    icon: Icons.radio_button_unchecked,
                                  ),
                                  _CountChip(
                                    label: l10n.inProgress,
                                    count: widget.counts.doing,
                                    tone: _ChipTone.doing,
                                    icon: Icons.timelapse_rounded,
                                  ),
                                  _CountChip(
                                    label: l10n.done,
                                    count: widget.counts.done,
                                    tone: _ChipTone.done,
                                    icon: Icons.check_circle_rounded,
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              transform: Matrix4.translationValues(_isHovered ? 2 : 0, 0, 0),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: _isHovered ? widget.accent : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySubtle : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primaryDark : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isOwner;
  final String? permission;
  final String? workspaceRole;

  const _RoleBadge({
    required this.isOwner,
    this.permission,
    this.workspaceRole,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditor = !isOwner && (permission == 'edit' || (permission == null && workspaceRole == 'editor'));
    final isViewer = !isOwner && !isEditor && (permission == 'view' || workspaceRole == 'viewer');

    final (label, icon, textColor, bgColor, borderColor) = switch (true) {
      _ when isOwner => (
        l10n.owner,
        Icons.workspace_premium_rounded,
        AppColors.primaryDark,
        AppColors.primarySubtle,
        AppColors.primaryLight.withValues(alpha: 0.5),
      ),
      _ when isEditor => (
        l10n.editor,
        Icons.edit_rounded,
        AppColors.accentTeal,
        const Color(0xFFE6FFFA),
        const Color(0xFF99F6E4),
      ),
      _ when isViewer => (
        l10n.viewer,
        Icons.visibility_rounded,
        AppColors.textSecondary,
        AppColors.surfaceVariant,
        AppColors.border,
      ),
      _ => (
        l10n.member,
        Icons.person_rounded,
        AppColors.textSecondary,
        AppColors.surfaceVariant,
        AppColors.border,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardMembersRow extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final bool canManage;
  final VoidCallback onManage;

  const _BoardMembersRow({
    required this.members,
    required this.canManage,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = members.isEmpty ? 1 : members.length;
    final displayMembers = members.take(3).toList();
    final remaining = members.length - 3;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onManage,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (displayMembers.isNotEmpty) ...[
                SizedBox(
                  height: 18,
                  width: (displayMembers.length * 13.0) + 7.0,
                  child: Stack(
                    children: [
                      for (var i = 0; i < displayMembers.length; i++)
                        Positioned(
                          left: i * 13.0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primarySubtle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                ((displayMembers[i]['name'] ?? displayMembers[i]['email'] ?? 'U') as String)
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (remaining > 0) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
              ] else ...[
                const Icon(Icons.people_outline_rounded, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
              ],
              Text(
                count == 1 ? l10n.oneMember : l10n.membersCount(count),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChipTone { plain, doing, done, alert }

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final _ChipTone tone;
  final IconData? icon;

  const _CountChip({
    required this.label,
    required this.count,
    this.tone = _ChipTone.plain,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _ChipTone.done => AppColors.success,
      _ChipTone.alert => AppColors.error,
      _ChipTone.doing => AppColors.primaryDark,
      _ChipTone.plain => AppColors.textSecondary,
    };
    final background = switch (tone) {
      _ChipTone.done => AppColors.successLight,
      _ChipTone.alert => AppColors.errorLight,
      _ChipTone.doing => AppColors.primarySubtle,
      _ChipTone.plain => AppColors.surfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9.5, color: color),
            const SizedBox(width: 3.5),
          ],
          Text(
            '$label $count',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _TasksPanel extends StatelessWidget {
  final bool loading;
  final bool failed;
  final List<WorkItem> items;
  final VoidCallback onRetry;
  final VoidCallback onClearFilter;
  final ValueChanged<String> onOpen;

  const _TasksPanel({
    required this.loading,
    required this.failed,
    required this.items,
    required this.onRetry,
    required this.onClearFilter,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return const _TasksSkeleton();
    }

    if (failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Không thể tải danh sách công việc',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.elegantCardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.allCaughtUp,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.nothingAssigned,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onClearFilter,
                  icon: const Icon(Icons.filter_list_off_rounded, size: 16),
                  label: Text(l10n.clearFilter),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primaryLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _TaskFullCard(
          item: item,
          onOpen: () => onOpen(item.boardId),
        );
      },
    );
  }
}

class _TasksSkeleton extends StatelessWidget {
  const _TasksSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: ListView.separated(
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _TaskFullCard extends StatefulWidget {
  final WorkItem item;
  final VoidCallback onOpen;

  const _TaskFullCard({
    required this.item,
    required this.onOpen,
  });

  @override
  State<_TaskFullCard> createState() => _TaskFullCardState();
}

class _TaskFullCardState extends State<_TaskFullCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final l10n = AppLocalizations.of(context)!;

    final statusLabel = switch (item.status) {
      'doing' => l10n.inProgress,
      'done' => l10n.done,
      _ => l10n.todo,
    };
    final statusColor = switch (item.status) {
      'doing' => AppColors.primary,
      'done' => AppColors.success,
      _ => const Color(0xFF6366F1), // indigo
    };
    final statusIcon = switch (item.status) {
      'doing' => Icons.pending_outlined,
      'done' => Icons.check_circle_rounded,
      _ => Icons.radio_button_unchecked_rounded,
    };

    final priorityLabel = switch (item.priority) {
      'urgent' => l10n.urgent,
      'high' => l10n.highPriority,
      'medium' => l10n.mediumPriority,
      'low' => l10n.lowPriority,
      _ => null,
    };
    final priorityColor = switch (item.priority) {
      'urgent' || 'high' => AppColors.error,
      'medium' => AppColors.warning,
      'low' => const Color(0xFF0EA5E9),
      _ => AppColors.textSecondary,
    };

    final due = item.deadline?.toLocal();
    final dueText = due == null
        ? null
        : '${due.day.toString().padLeft(2, '0')}/${due.month.toString().padLeft(2, '0')}/${due.year}';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered ? AppColors.hoverShadow : AppColors.elegantCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onOpen,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status accent strip
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags row: Board badge + Status badge + Priority badge
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Board Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.dashboard_outlined, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.boardName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      statusLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Priority Badge
                            if (priorityLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flag_rounded, size: 11, color: priorityColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      priorityLabel,
                                      style: TextStyle(
                                        color: priorityColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          item.title.isEmpty ? l10n.untitled : item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: _isHovered ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),

                        // Deadline info if present
                        if (dueText != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: item.isOverdue ? AppColors.error : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isOverdue ? 'Quá hạn ($dueText)' : 'Hạn: $dueText',
                                style: TextStyle(
                                  color: item.isOverdue ? AppColors.error : AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: item.isOverdue ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Open Kanban board action button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isHovered ? AppColors.primary : AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mở bảng',
                          style: TextStyle(
                            color: _isHovered ? Colors.white : AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: _isHovered ? Colors.white : AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

