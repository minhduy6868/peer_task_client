import 'package:flutter/material.dart';
import 'package:peertask/models/workspace/workspace.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/models/board/board.dart';
import 'package:peertask/l10n/app_localizations.dart';

class DashboardSidebar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabSelected;
  final Workspace? workspace;
  final VoidCallback onWorkspaceTap;
  final VoidCallback onCreateBoard;
  final List<Board> boards;
  final String? selectedBoardId;
  final ValueChanged<String>? onSelectBoard;
  final User? user;
  final VoidCallback onSettingsTap;
  final VoidCallback? onBrandTap;
  final bool isCompact;

  const DashboardSidebar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.workspace,
    required this.onWorkspaceTap,
    required this.onCreateBoard,
    this.boards = const [],
    this.selectedBoardId,
    this.onSelectBoard,
    this.user,
    required this.onSettingsTap,
    this.onBrandTap,
    this.isCompact = false,
  });

  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color primarySubtle = Color(0xFFEDE9FE);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = isCompact ? 72.0 : 240.0;
    final userName = user?.name?.isNotEmpty == true
        ? user!.name!
        : (user?.email?.split('@').first ?? '');
    final userEmail = user?.email ?? '';
    final userInitials = userName.trim().split(' ').map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join();

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Brand Logo + PeerTask + Tagline
            InkWell(
              onTap: onBrandTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.fromLTRB(isCompact ? 14 : 18, 16, isCompact ? 14 : 18, 18),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
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
                    if (!isCompact) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'PeerTask',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.tagline,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Navigation Items (Notice: Project name "Điện Toán Đám Mây" is removed!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: l10n.homeNav,
                    isActive: currentTab == 0,
                    isCompact: isCompact,
                    onTap: () => onTabSelected(0),
                  ),
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: l10n.boards,
                    isActive: currentTab == 1,
                    isCompact: isCompact,
                    onTap: () => onTabSelected(1),
                  ),
                  _NavItem(
                    icon: Icons.check_box_outlined,
                    label: l10n.tasks,
                    isActive: currentTab == 2,
                    isCompact: isCompact,
                    onTap: () => onTabSelected(2),
                  ),
                  _NavItem(
                    icon: Icons.group_outlined,
                    label: l10n.members,
                    isActive: currentTab == 3,
                    isCompact: isCompact,
                    onTap: () => onTabSelected(3),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: l10n.settings,
                    isActive: currentTab == 4,
                    isCompact: isCompact,
                    onTap: () => onTabSelected(4),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Profile Card
            Padding(
              padding: EdgeInsets.all(isCompact ? 8 : 12),
              child: InkWell(
                onTap: onSettingsTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEDE9FE),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Center(
                          child: Text(
                            userInitials.isNotEmpty ? userInitials : 'D',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      l10n.activeStatus,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF16A34A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCompact;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeBg = Color(0xFFEDE9FE);
    const activeColor = Color(0xFF6366F1);
    const idleColor = Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: isCompact ? label : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFFF1F5F9),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 12),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : idleColor,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? activeColor : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
