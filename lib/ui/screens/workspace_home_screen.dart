import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/workspace/workspace.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../dialogs/workspace_menu_dialog.dart';
import 'boards_screen.dart';
import 'settings_screen.dart';

final _currentTabProvider = StateProvider<int>((ref) => 0);
final _currentWorkspaceProvider = StateProvider<Workspace?>((ref) => null);

class WorkspaceHomeScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceHomeScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceHomeScreen> createState() => _WorkspaceHomeScreenState();
}

class _WorkspaceHomeScreenState extends ConsumerState<WorkspaceHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadWorkspace();
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

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(_currentTabProvider);
    final workspace = ref.watch(_currentWorkspaceProvider);
    final l10n = AppLocalizations.of(context)!;

    final screens = <Widget>[
      BoardsScreen(workspaceId: widget.workspaceId),
      const SettingsScreen(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final workspaceName = workspace?.name.isNotEmpty == true
        ? workspace!.name
        : l10n.workspaces;
    void showBoards() => ref.read(_currentTabProvider.notifier).state = 0;
    void showSettings() => ref.read(_currentTabProvider.notifier).state = 1;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 256,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.diversity_3_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'PeerTask',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RailRow(
                        label: workspaceName,
                        selected: false,
                        onTap: _showWorkspaceMenu,
                      ),
                      const SizedBox(height: 8),
                      _RailRow(
                        label: l10n.boards,
                        selected: currentTab == 0,
                        onTap: showBoards,
                      ),
                      const Spacer(),
                      _RailRow(
                        label: l10n.settings,
                        selected: currentTab == 1,
                        onTap: showSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: IndexedStack(index: currentTab, children: screens)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.workspaces,
          onPressed: _navigateToHome,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(workspaceName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: currentTab == 0 ? showSettings : showBoards,
            child: Text(currentTab == 0 ? l10n.settings : l10n.boards),
          ),
        ],
      ),
      body: IndexedStack(index: currentTab, children: screens),
    );
  }
}

class _RailRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySubtle : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.gradientPrimary : null,
                  color: selected ? null : AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label.isEmpty ? '?' : label.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section.copyWith(
                    color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

