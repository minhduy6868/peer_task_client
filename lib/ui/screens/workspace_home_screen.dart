import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/workspace/workspace.dart';
import '../../models/board/board.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/error_display.dart';
import '../../utils/validators_l10n.dart';
import '../dialogs/workspace_menu_dialog.dart';
import '../widgets/dashboard/dashboard_sidebar.dart';
import '../widgets/dashboard/dashboard_top_bar.dart';
import '../widgets/dashboard/dashboard_center_view.dart';
import '../widgets/app_shell_style.dart';
import 'boards_screen.dart';
import 'workspace_members_screen.dart';
import 'project_settings_screen.dart';

final _currentTabProvider = StateProvider<int>((ref) => 0);
final _currentWorkspaceProvider = StateProvider<Workspace?>((ref) => null);
final _selectedBoardIdProvider = StateProvider<String?>((ref) => null);

class WorkspaceHomeScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceHomeScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceHomeScreen> createState() => _WorkspaceHomeScreenState();
}

class _WorkspaceHomeScreenState extends ConsumerState<WorkspaceHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspace() async {
    try {
      final api = ref.read(apiServiceProvider);
      final workspace = await api.getWorkspace(widget.workspaceId);
      ref.read(_currentWorkspaceProvider.notifier).state = workspace;

      // Save last workspace to auto-open next time
      final storage = ref.read(storageServiceProvider);
      await storage.saveLastWorkspace(widget.workspaceId);
    } catch (e) {
      debugPrint('Error loading workspace: $e');
    }
  }

  void _showWorkspaceMenu() {
    final workspace = ref.read(_currentWorkspaceProvider);
    if (workspace == null) return;

    showDialog(
      context: context,
      builder: (context) => WorkspaceMenuDialog(
        workspace: workspace,
        onWorkspaceChanged: () {
          context.go('/workspaces');
        },
        onWorkspaceLeft: () {
          context.go('/workspaces');
        },
        onWorkspaceDeleted: () {
          context.go('/workspaces');
        },
      ),
    );
  }

  void _navigateToHome() {
    ref.read(_currentTabProvider.notifier).state = 0;
    try {
      context.go('/workspaces');
    } catch (_) {}
  }

  void _logout() {
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Color(0xFF6366F1),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dialogL10n.createNewBoard,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: dialogL10n.boardName,
                        hintText: dialogL10n.enterBoardName,
                        prefixIcon: const Icon(Icons.label_outline_rounded, color: Color(0xFF6366F1)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                      ),
                      validator: ValidatorsL10n.required(context),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: dialogL10n.boardDescription,
                        hintText: dialogL10n.boardDescriptionOptional,
                        prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF6366F1)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(dialogL10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
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
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(dialogL10n.create, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
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
    final currentTab = ref.watch(_currentTabProvider);
    final workspace = ref.watch(_currentWorkspaceProvider);
    final authState = ref.watch(authStateProvider);
    final boardsAsync = ref.watch(workspaceBoardsProvider(widget.workspaceId));
    final boards = boardsAsync.valueOrNull ?? const <Board>[];
    final selectedBoardId = ref.watch(_selectedBoardIdProvider);

    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 960;

    final tasksAsync = ref.watch(myWorkspaceTasksProvider(widget.workspaceId));
    final myTasks = tasksAsync.valueOrNull;
    final dashboardTasks = myTasks?.map((t) => DashboardTaskData(
      id: t.id,
      boardId: t.boardId,
      title: t.title,
      projectName: t.boardName.isNotEmpty ? 'Dự án: ${t.boardName}' : (workspace?.name ?? ''),
      deadline: t.deadline != null
          ? 'Hạn: ${t.deadline!.day.toString().padLeft(2, '0')}/${t.deadline!.month.toString().padLeft(2, '0')}/${t.deadline!.year}'
          : 'Không có hạn',
      status: t.status,
    )).toList();

    final summaryAsync = ref.watch(workspaceBoardSummaryProvider(widget.workspaceId));
    final summaryMap = summaryAsync.valueOrNull;
    final boardSummaries = summaryMap?.map((k, v) => MapEntry(
      k,
      DashboardBoardCounts(
        todo: v.todo,
        doing: v.doing,
        done: v.done,
        overdue: v.overdue,
      ),
    ));

    // Center Dashboard View
    final dashboardView = DashboardCenterView(
      user: authState.user,
      workspace: workspace,
      boards: boards,
      tasks: dashboardTasks,
      boardSummaries: boardSummaries,
      onCreateBoard: _showCreateBoardDialog,
      onViewAllBoards: () => ref.read(_currentTabProvider.notifier).state = 1,
      onViewAllTasks: () => ref.read(_currentTabProvider.notifier).state = 2,
      onOpenBoard: (boardId) {
        context.go('/board/$boardId');
      },
      onOpenTask: (task) {
        final boardId = task.boardId ?? (boards.isNotEmpty ? boards.first.id : null);
        if (boardId != null) context.go('/board/$boardId');
      },
    );

    // Screen stack depending on selected tab
    Widget activeContent;
    switch (currentTab) {
      case 0:
        activeContent = dashboardView;
        break;
      case 1:
        activeContent = BoardsScreen(workspaceId: widget.workspaceId, initialTab: 0);
        break;
      case 2:
        activeContent = BoardsScreen(workspaceId: widget.workspaceId, initialTab: 1);
        break;
      case 3:
        activeContent = WorkspaceMembersScreen(workspaceId: widget.workspaceId);
        break;
      case 4:
        activeContent = ProjectSettingsScreen(workspaceId: widget.workspaceId);
        break;
      default:
        activeContent = dashboardView;
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppShellStyle.background,
        body: Row(
          children: [
            // Left Sidebar (full-height matching mockup)
            DashboardSidebar(
              currentTab: currentTab,
              onTabSelected: (index) {
                ref.read(_currentTabProvider.notifier).state = index;
              },
              workspace: workspace,
              onWorkspaceTap: _showWorkspaceMenu,
              onCreateBoard: _showCreateBoardDialog,
              boards: boards,
              selectedBoardId: selectedBoardId,
              onSelectBoard: (id) {
                ref.read(_selectedBoardIdProvider.notifier).state = id;
                ref.read(_currentTabProvider.notifier).state = 1;
              },
              user: authState.user,
              onSettingsTap: () => context.push('/settings'),
              onBrandTap: _navigateToHome,
            ),

            // Main Area with top bar and scrollable content
            Expanded(
              child: Column(
                children: [
                  DashboardTopBar(
                    onProfileTap: () => context.push('/settings'),
                    onLogout: _logout,
                    onBrandTap: _navigateToHome,
                    onBack: _navigateToHome,
                    title: workspace?.name,
                    user: authState.user,
                  ),
                  Expanded(child: activeContent),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet View (< 960px)
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppShellStyle.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: AppShellStyle.headerHeight,
        shape: const Border(bottom: BorderSide(color: AppShellStyle.divider, width: 1.5)),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.diversity_3_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
              workspace?.name ?? 'PeerTask',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            ),
          ],
        ),
        titleSpacing: 4,
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.workspaces,
            icon: const Icon(Icons.apps_rounded, color: Color(0xFF64748B)),
            onPressed: _navigateToHome,
          ),
          const ShellLanguageMenu(),
          const SizedBox(width: 8),
          ShellAccountMenu(
            user: authState.user,
            onOpenSettings: () => context.push('/settings'),
            onLogout: _logout,
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: DashboardSidebar(
          currentTab: currentTab,
          onTabSelected: (index) {
            Navigator.pop(context);
            ref.read(_currentTabProvider.notifier).state = index;
          },
          workspace: workspace,
          onWorkspaceTap: () {
            Navigator.pop(context);
            _showWorkspaceMenu();
          },
          onCreateBoard: () {
            Navigator.pop(context);
            _showCreateBoardDialog();
          },
          boards: boards,
          selectedBoardId: selectedBoardId,
          onSelectBoard: (id) {
            Navigator.pop(context);
            ref.read(_selectedBoardIdProvider.notifier).state = id;
            ref.read(_currentTabProvider.notifier).state = 1;
          },
          user: authState.user,
          onSettingsTap: () {
            Navigator.pop(context);
            context.push('/settings');
          },
          onBrandTap: _navigateToHome,
        ),
      ),
      body: activeContent,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: currentTab > 2 ? 0 : currentTab,
            onDestinationSelected: (idx) {
              ref.read(_currentTabProvider.notifier).state = idx == 2 ? 4 : idx;
            },
            backgroundColor: Colors.white,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: AppLocalizations.of(context)!.homeNav,
              ),
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard_rounded),
                label: AppLocalizations.of(context)!.boards,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: AppLocalizations.of(context)!.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
