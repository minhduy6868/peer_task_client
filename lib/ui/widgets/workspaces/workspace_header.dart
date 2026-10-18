import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user/user.dart';
import '../app_shell_style.dart';
import '../dashboard/dashboard_top_bar.dart';

class WorkspaceHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final User? user;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMobileDrawer;

  const WorkspaceHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.user,
    required this.onOpenSettings,
    required this.onLogout,
    this.onOpenMobileDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      height: AppShellStyle.headerHeight,
      padding: AppShellStyle.headerPadding(width),
      decoration: AppShellStyle.headerDecoration,
      child: Row(
        children: [
          if (onOpenMobileDrawer != null) ...[
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppShellStyle.textDark,
              ),
              onPressed: onOpenMobileDrawer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShellSearchField(
                controller: searchController,
                onChanged: onSearchChanged,
                hintText: l10n.searchWorkspacesHint,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const ShellLanguageMenu(),
          const SizedBox(width: 14),
          PopupMenuButton<String>(
            tooltip: l10n.accountAndSettings,
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'settings') onOpenSettings();
              if (value == 'logout') onLogout();
            },
            itemBuilder: (context) => [
              if (user != null)
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user!.name?.trim().isNotEmpty == true)
                        Text(
                          user!.name!.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppShellStyle.textDark,
                          ),
                        ),
                      Text(
                        user!.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppShellStyle.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: AppShellStyle.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.accountAndSettings,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.logout,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: ShellAvatar(user: user),
          ),
        ],
      ),
    );
  }
}
