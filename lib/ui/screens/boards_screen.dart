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

class BoardsScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const BoardsScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

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
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F7FA), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white,
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(
                greeting: l10n.welcome,
                name: greetingName,
                workspaceName: workspaceName ?? '',
                boardsLabel: l10n.myBoards,
                searchController: _searchController,
                searchHint: l10n.searchBoards,
                onSearch: (value) => setState(() => _query = value),
              ),
              Expanded(
                child: visible.isEmpty
                    ? _EmptyBoards(
                        canCreate: canCreateBoard && boards.isEmpty,
                        onCreate: _showCreateBoardDialog,
                        title: boards.isEmpty ? l10n.myBoards : l10n.searchBoards,
                        action: l10n.createBoard,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final board = visible[index];
                          return _BoardCard(
                            board: board,
                            accent: _boardAccents[index % _boardAccents.length],
                            onTap: () => context.go('/board/${board.id}'),
                            onSettings: () async {
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
                              }
                            },
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
  final String boardsLabel;
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearch;

  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.workspaceName,
    required this.boardsLabel,
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
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          if (workspaceName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              workspaceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          Text(boardsLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
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
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const _BoardCard({
    required this.board,
    required this.accent,
    required this.onTap,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        board.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary),
                      ),
                      if (board.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          board.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(onPressed: onSettings, icon: const Icon(Icons.more_horiz)),
            ],
          ),
        ),
      ),
    );
  }
}

