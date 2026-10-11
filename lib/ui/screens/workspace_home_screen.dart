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
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    final screens = <Widget>[
      BoardsScreen(workspaceId: widget.workspaceId),
      const SettingsScreen(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 960;
    final boardsItem = _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: l10n.boards,
      isSelected: currentTab == 0,
      onTap: () => ref.read(_currentTabProvider.notifier).state = 0,
    );
    final workspaceItem = _NavItem(
      isWorkspace: true,
      workspaceName: workspace?.name ?? '',
      workspaceLabel: l10n.workspaces,
      isSelected: false,
      onTap: _showWorkspaceMenu,
    );
    final profileItem = _NavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: authState.user?.name?.substring(0, 1).toUpperCase() ??
          authState.user?.email.substring(0, 1).toUpperCase() ??
          'U',
      isAvatar: true,
      avatarLabel: l10n.profile,
      isSelected: currentTab == 1,
      onTap: () => ref.read(_currentTabProvider.notifier).state = 1,
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 84,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _BrandMark(onTap: _navigateToHome),
                    const SizedBox(height: 14),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 12),
                    workspaceItem,
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 12),
                    boardsItem,
                    const Spacer(),
                    profileItem,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Expanded(child: IndexedStack(index: currentTab, children: screens)),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                boardsItem,
                workspaceItem,
                profileItem,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatefulWidget {
  final VoidCallback? onTap;

  const _BrandMark({super.key, this.onTap});

  @override
  State<_BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<_BrandMark> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'PeerTask',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _isHovered ? 0.45 : 0.28),
                  blurRadius: _isHovered ? 12 : 10,
                  offset: Offset(0, _isHovered ? 4 : 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.diversity_3_rounded,
                color: Colors.white,
                size: 22,
              ),
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
      final name = workspaceName?.isNotEmpty == true ? workspaceName! : (workspaceLabel ?? 'Workspace');
      
      return Tooltip(
        message: name,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 68,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.unfold_more_rounded,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isAvatar) {
      return Tooltip(
        message: avatarLabel ?? 'Profile',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySubtle : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.gradientPrimary : null,
                        color: isSelected ? null : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primaryLight : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label ?? 'U',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  avatarLabel ?? 'Profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? AppColors.primaryDark : AppColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: label ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
