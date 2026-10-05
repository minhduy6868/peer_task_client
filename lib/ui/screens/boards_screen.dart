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

class BoardsScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const BoardsScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  Future<void> _openBoardSettings(Board board) async {
    final result = await showDialog(
      context: context,
      builder: (context) => BoardSettingsDialog(
        boardId: board.id,
        boardName: board.name,
        boardDescription: board.description,
      ),
    );
    if ((result == 'deleted' || result == true) && mounted) {
      ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
      ref.invalidate(workspaceBoardSummaryProvider(widget.workspaceId));
      ref.invalidate(myWorkspaceTasksProvider(widget.workspaceId));
    }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canCreateBoard
          ? FloatingActionButton.extended(
              onPressed: _showCreateBoardDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(l10n.newBoard, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              elevation: 1,
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
          final query = _query.trim().toLowerCase();
          final visible = query.isEmpty
              ? boards
              : boards.where((board) {
                  final name = board.name.toLowerCase();
                  final description = board.description?.toLowerCase() ?? '';
                  return name.contains(query) || description.contains(query);
                }).toList();
          final summary = ref.watch(workspaceBoardSummaryProvider(widget.workspaceId)).valueOrNull ?? const {};
          final workAsync = ref.watch(myWorkspaceTasksProvider(widget.workspaceId));
          final work = (workAsync.valueOrNull ?? const <_WorkItem>[])
              .where((item) {
                if (query.isEmpty) return true;
                return item.title.toLowerCase().contains(query) || item.boardName.toLowerCase().contains(query);
              })
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(
                greeting: l10n.welcome,
                name: greetingName,
                workspaceName: workspaceName ?? '',
                searchController: _searchController,
                searchHint: l10n.searchBoards,
                onSearch: (value) => setState(() => _query = value),
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
                    final boardPanel = visible.isEmpty
                        ? _EmptyBoards(
                            canCreate: canCreateBoard && boards.isEmpty,
                            onCreate: _showCreateBoardDialog,
                            title: boards.isEmpty ? l10n.myBoards : l10n.searchBoards,
                            action: l10n.createBoard,
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: wide ? 2 : 1,
                              mainAxisExtent: 168,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final board = visible[index];
                              return _BoardCard(
                                board: board,
                                accent: _boardAccents[index % _boardAccents.length],
                                counts: summary[board.id] ?? const _BoardCounts(),
                                onTap: () => context.go('/board/${board.id}'),
                                onSettings: () => _openBoardSettings(board),
                              );
                            },
                          );
                    if (!wide) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          workPanel,
                          const SizedBox(height: 20),
                          Text(l10n.myBoards, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (visible.isEmpty)
                            SizedBox(height: 220, child: boardPanel)
                          else
                            ...[
                              for (var i = 0; i < visible.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                SizedBox(
                                  height: 168,
                                  child: _BoardCard(
                                    board: visible[i],
                                    accent: _boardAccents[i % _boardAccents.length],
                                    counts: summary[visible[i].id] ?? const _BoardCounts(),
                                    onTap: () => context.go('/board/${visible[i].id}'),
                                    onSettings: () => _openBoardSettings(visible[i]),
                                  ),
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
                          SizedBox(width: 340, child: workPanel),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.myBoards, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
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
    final padding = isLargeScreen ? 24.0 : 16.0;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverToBoxAdapter(
              child: Container(width: 150, height: 28, color: Colors.white),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isLargeScreen ? 350 : double.infinity,
                crossAxisSpacing: isLargeScreen ? 20 : 16,
                mainAxisSpacing: isLargeScreen ? 20 : 16,
                childAspectRatio: isLargeScreen ? 1.4 : 1.3,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                childCount: 6,
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
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearch;

  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.workspaceName,
    required this.searchController,
    required this.searchHint,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: AppColors.textPrimary),
          ),
          if (workspaceName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              workspaceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _EmptyBoards extends StatelessWidget {
  final bool canCreate;
  final VoidCallback onCreate;
  final String title;
  final String action;

  const _EmptyBoards({
    required this.canCreate,
    required this.onCreate,
    required this.title,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dashboard_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            if (canCreate) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onCreate, child: Text(action)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final Board board;
  final Color accent;
  final _BoardCounts counts;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const _BoardCard({
    required this.board,
    required this.accent,
    required this.counts,
    required this.onTap,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = counts.total == 0 ? 0.0 : counts.done / counts.total;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              board.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          IconButton(
                            onPressed: onSettings,
                            icon: const Icon(Icons.more_horiz, size: 18),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      if (board.description?.isNotEmpty == true)
                        Text(
                          board.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.border,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _CountChip(label: l10n.todo, count: counts.todo),
                          _CountChip(label: l10n.inProgress, count: counts.doing),
                          _CountChip(label: l10n.done, count: counts.done, tone: _ChipTone.done),
                          if (counts.overdue > 0)
                            _CountChip(label: l10n.overdue, count: counts.overdue, tone: _ChipTone.alert),
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
    );
  }
}

enum _ChipTone { plain, done, alert }

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final _ChipTone tone;

  const _CountChip({required this.label, required this.count, this.tone = _ChipTone.plain});

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _ChipTone.done => AppColors.success,
      _ChipTone.alert => AppColors.error,
      _ChipTone.plain => AppColors.textSecondary,
    };
    final background = switch (tone) {
      _ChipTone.done => AppColors.successLight,
      _ChipTone.alert => AppColors.errorLight,
      _ChipTone.plain => AppColors.primarySubtle,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
      child: Text(
        '$label $count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
            ? TextButton(onPressed: onRetry, child: Text(l10n.retry))
            : items.isEmpty
                ? Text(l10n.nothingAssigned, style: const TextStyle(color: AppColors.textSecondary, height: 1.4))
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _WorkRow(item: items[i], onOpen: () => onOpen(items[i].boardId)),
                      ],
                    ],
                  );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.yourWork, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (scroll) Expanded(child: SingleChildScrollView(child: body)) else body,
      ],
    );
  }
}

class _WorkSkeleton extends StatelessWidget {
  const _WorkSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ],
      ],
    );
  }
}

class _WorkRow extends StatelessWidget {
  final _WorkItem item;
  final VoidCallback onOpen;

  const _WorkRow({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              Container(width: 3, height: 36, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? l10n.untitled : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.boardName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (priorityLabel != null)
                    Text(priorityLabel, style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (dueText != null)
                    Text(
                      item.isOverdue ? '${l10n.overdue} $dueText' : dueText,
                      style: TextStyle(
                        color: item.isOverdue ? AppColors.error : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
}

