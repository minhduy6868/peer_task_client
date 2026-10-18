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
    final narrow = width < 600;

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
          SizedBox(width: narrow ? 8 : 14),
          const ShellLanguageMenu(),
          SizedBox(width: narrow ? 8 : 14),
          ShellAccountMenu(
            user: user,
            onOpenSettings: onOpenSettings,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }
}
