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
import '../theme/app_text_styles.dart';

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

class _WorkItem {
  final String id;
  final String title;
  final String boardId;
  final String boardName;
  final String status;
  final String? priority;
  final DateTime? deadline;

  const _WorkItem({
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

final myWorkspaceTasksProvider = FutureProvider.autoDispose.family<List<_WorkItem>, String>((ref, workspaceId) async {
  final rows = await ref.watch(apiServiceProvider).getMyTasks(workspaceId: workspaceId, open: true, limit: 8);
  return [
    for (final row in rows)
      if (row['id'] is String && row['board_id'] is String)
        _WorkItem(
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

class BoardsScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const BoardsScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  BoardFilter _filter = BoardFilter.all;
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

  @override
  void dispose() {
    _searchController.dispose();
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

            if (query.isNotEmpty) {
              final name = board.name.toLowerCase();
              final description = board.description?.toLowerCase() ?? '';
              if (!name.contains(query) && !description.contains(query)) return false;
            }
            return true;
          }).toList();

          final summary = ref.watch(workspaceBoardSummaryProvider(widget.workspaceId)).valueOrNull ?? const {};
          final workAsync = ref.watch(myWorkspaceTasksProvider(widget.workspaceId));
          final work = (workAsync.valueOrNull ?? const <_WorkItem>[])
              .where((item) {
                if (query.isEmpty) return true;
                return item.title.toLowerCase().contains(query) || item.boardName.toLowerCase().contains(query);
              })
              .toList();
          final totalDone = summary.values.fold<int>(0, (sum, c) => sum + c.done);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                totalWork: work.length,
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
                countAll: countAll,
                countOwner: countOwner,
                countEditor: countEditor,
                countViewer: countViewer,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final workPanel = _YourWorkPanel(
                      loading: workAsync.isLoading && !workAsync.hasValue,
                      failed: workAsync.hasError,
                      items: work,
                      scroll: wide,
                      onRetry: () => ref.invalidate(myWorkspaceTasksProvider(widget.workspaceId)),
                      onOpen: (boardId) => context.go('/board/$boardId'),
                    );
                    final hasFilterOrQuery = _filter != BoardFilter.all || query.isNotEmpty;
                    final showAddCard = canCreateBoard && !hasFilterOrQuery;
                    final boardCount = visible.length + (showAddCard ? 1 : 0);

                    final boardPanel = visible.isEmpty && !showAddCard
                        ? _EmptyBoards(
                            canCreate: canCreateBoard && !hasFilterOrQuery,
                            onCreate: hasFilterOrQuery
                                ? () {
                                    setState(() {
                                      _query = '';
                                      _searchController.clear();
                                      _filter = BoardFilter.all;
                                    });
                                  }
                                : _showCreateBoardDialog,
                            title: hasFilterOrQuery ? l10n.noBoardsMatchingFilter : l10n.noBoardsYet,
                            subtitle: hasFilterOrQuery ? l10n.clearFilter : null,
                            action: hasFilterOrQuery ? l10n.clearFilter : l10n.createBoard,
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: wide ? 2 : 1,
                              mainAxisExtent: 205,
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
                                onSettings: () => _openBoardSettings(board),
                                onOpenMembers: () => _openBoardMembers(board),
                              );
                            },
                          );
                    if (!wide) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        children: [
                          if (visible.isEmpty && !showAddCard)
                            SizedBox(height: 240, child: boardPanel)
                          else ...[
                              for (var i = 0; i < visible.length; i++) ...[
                                if (i > 0) const SizedBox(height: 14),
                                SizedBox(
                                  height: 232,
                                  child: _BoardCard(
                                    board: visible[i],
                                    accent: _boardAccents[i % _boardAccents.length],
                                    counts: summary[visible[i].id] ?? const _BoardCounts(),
                                    workspaceRole: role,
                                    onTap: () => context.go('/board/${visible[i].id}'),
                                    onSettings: () => _openBoardSettings(visible[i]),
                                    onOpenMembers: () => _openBoardMembers(visible[i]),
                                  ),
                                ),
                              ],
                              if (showAddCard) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 150,
                                  child: _NewBoardCard(onTap: _showCreateBoardDialog),
                                ),
                              ],
                            ],
                        ],
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 350, child: workPanel),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySubtle,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.dashboard_rounded, size: 18, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.myBoards,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySubtle,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${visible.length}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(child: boardPanel),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
                childAspectRatio: 1.5,
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
            child: Container(
              padding: EdgeInsets.all(isWide ? 20 : 16),
              decoration: BoxDecoration(
                gradient: AppColors.gradientSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.7)),
                boxShadow: AppColors.elegantCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workspaceName.isEmpty ? l10n.boards : workspaceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.screenTitle.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.boards,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (canCreate) ...[
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: onCreateBoard,
                          child: Text(l10n.newBoard),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 360 : double.infinity),
                      child: _buildSearchBox(l10n),
                    ),
                  ),
                ],
              ),
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

  Widget _buildWelcomeInfo(BuildContext context, AppLocalizations l10n, {required bool isWide}) {
    final cleanGreeting = greeting.endsWith('!') ? greeting : '$greeting!';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.waving_hand_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    cleanGreeting,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isWide ? 26 : 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                l10n.workspaceOverview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsAndAction(AppLocalizations l10n, {required bool isWide}) {
    if (!isWide) {
      return Row(
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
        if (canCreate)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCreateBoard,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.newBoard,
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
              child: Text(
                subtitle ?? l10n.createFirstBoard,
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
                        const Icon(Icons.add_rounded, color: Colors.white, size: 18),
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
  final VoidCallback onSettings;
  final VoidCallback onOpenMembers;

  const _BoardCard({
    required this.board,
    required this.accent,
    required this.counts,
    this.workspaceRole,
    required this.onTap,
    required this.onSettings,
    required this.onOpenMembers,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? widget.accent.withValues(alpha: 0.45) : AppColors.border,
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
                              icon: const Icon(Icons.more_horiz_rounded, size: 18),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tooltip: l10n.boardSettings,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'members',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(l10n.boardMembers, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'settings',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.settings_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Text(l10n.boardSettings, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'members') {
                                  widget.onOpenMembers();
                                } else if (value == 'settings') {
                                  widget.onSettings();
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

class _YourWorkPanel extends StatelessWidget {
  final bool loading;
  final bool failed;
  final bool scroll;
  final List<_WorkItem> items;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpen;

  const _YourWorkPanel({
    required this.loading,
    required this.failed,
    required this.scroll,
    required this.items,
    required this.onRetry,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = loading
        ? const _WorkSkeleton()
        : failed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10n.retry),
                  ),
                ),
              )
            : items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySubtle,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.allCaughtUp,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.nothingAssigned,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _WorkRow(item: items[i], onOpen: () => onOpen(items[i].boardId)),
                      ],
                    ],
                  );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.elegantCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.yourWork,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: items.isEmpty ? AppColors.surfaceVariant : AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: items.isEmpty ? AppColors.textTertiary : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          if (scroll) Expanded(child: SingleChildScrollView(child: body)) else body,
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.quickTipsBody,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkSkeleton extends StatelessWidget {
  const _WorkSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkRow extends StatefulWidget {
  final _WorkItem item;
  final VoidCallback onOpen;

  const _WorkRow({required this.item, required this.onOpen});

  @override
  State<_WorkRow> createState() => _WorkRowState();
}

class _WorkRowState extends State<_WorkRow> {
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
      'doing' => AppColors.primaryDark,
      'done' => AppColors.success,
      _ => AppColors.textSecondary,
    };
    final priorityLabel = switch (item.priority) {
      'urgent' => l10n.urgent,
      'high' => l10n.highPriority,
      _ => null,
    };
    final due = item.deadline?.toLocal();
    final dueText = due == null ? null : '${due.day.toString().padLeft(2, '0')}/${due.month.toString().padLeft(2, '0')}';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceHover.withValues(alpha: 0.5) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? AppColors.primary.withValues(alpha: 0.4) : AppColors.borderLight,
            width: _isHovered ? 1.2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onOpen,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 38,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.isEmpty ? l10n.untitled : item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: _isHovered ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.dashboard_outlined, size: 11, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.boardName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (priorityLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          priorityLabel,
                          style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (dueText != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: item.isOverdue ? AppColors.error : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.isOverdue ? '${l10n.overdue} $dueText' : dueText,
                              style: TextStyle(
                                color: item.isOverdue ? AppColors.error : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (_isHovered) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

