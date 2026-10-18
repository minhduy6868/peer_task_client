import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../app_shell_style.dart';

class WorkspaceSidebar extends StatelessWidget {
  final String activeItem;
  final ValueChanged<String> onSelectItem;
  final bool isCompact;

  const WorkspaceSidebar({
    super.key,
    required this.activeItem,
    required this.onSelectItem,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: isCompact
          ? AppShellStyle.sidebarCompactWidth
          : AppShellStyle.sidebarWidth,
      decoration: AppShellStyle.sidebarDecoration,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShellStyle.brand(
              tagline: l10n.tagline,
              compact: isCompact,
              onTap: () => onSelectItem('workspaces'),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12),
              child: AppShellStyle.navItem(
                icon: Icons.grid_view_rounded,
                label: l10n.workspaces,
                active: activeItem == 'workspaces',
                compact: isCompact,
                onTap: () => onSelectItem('workspaces'),
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 10 : 12,
                0,
                isCompact ? 10 : 12,
                16,
              ),
              child: AppShellStyle.navItem(
                icon: Icons.help_outline_rounded,
                label: l10n.helpNav,
                active: activeItem == 'help',
                compact: isCompact,
                onTap: () => onSelectItem('help'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
