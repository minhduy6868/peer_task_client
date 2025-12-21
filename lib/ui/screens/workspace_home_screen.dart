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

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(_currentTabProvider);
    final workspace = ref.watch(_currentWorkspaceProvider);
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    final screens = <Widget>[
      BoardsScreen(workspaceId: widget.workspaceId),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: l10n.boards,
                  isSelected: currentTab == 0,
                  onTap: () => ref.read(_currentTabProvider.notifier).state = 0,
                ),
                _NavItem(
                  isWorkspace: true,
                  workspaceName: workspace?.name ?? '',
                  workspaceLabel: l10n.workspaces,
                  isSelected: false,
                  onTap: _showWorkspaceMenu,
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: authState.user?.name?.substring(0, 1).toUpperCase() ?? 
                         authState.user?.email.substring(0, 1).toUpperCase() ?? 'U',
                  isAvatar: true,
                  avatarLabel: l10n.profile,
                  isSelected: currentTab == 1,
                  onTap: () => ref.read(_currentTabProvider.notifier).state = 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final IconData? selectedIcon;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isWorkspace;
  final String? workspaceName;
  final String? workspaceLabel;
  final bool isAvatar;
  final String? avatarLabel;

  const _NavItem({
    this.icon,
    this.selectedIcon,
    this.label,
    required this.isSelected,
    required this.onTap,
    this.isWorkspace = false,
    this.workspaceName,
    this.workspaceLabel,
    this.isAvatar = false,
    this.avatarLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isWorkspace) {
      final firstLetter = workspaceName?.isNotEmpty == true 
          ? workspaceName![0].toUpperCase() 
          : 'W';
      
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workspaceLabel ?? 'Workspace',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isAvatar) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.gradientPrimary : null,
                  color: isSelected ? null : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label ?? 'U',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                avatarLabel ?? 'Profile',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label ?? '',
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
