import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/workspace/workspace.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'workspace_settings_dialog.dart';

import '../../utils/error_display.dart';
class WorkspaceMenuDialog extends ConsumerWidget {
  final Workspace workspace;
  final VoidCallback? onWorkspaceChanged;
  final VoidCallback? onWorkspaceLeft;
  final VoidCallback? onWorkspaceDeleted;

  const WorkspaceMenuDialog({
    super.key,
    required this.workspace,
    this.onWorkspaceChanged,
    this.onWorkspaceLeft,
    this.onWorkspaceDeleted,
  });

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Viewer';
      default:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = workspace.role == 'owner';
    final storage = ref.read(storageServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workspace Info
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      workspace.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.role}: ${_getRoleDisplayName(workspace.role)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // Menu Options
            _MenuOption(
              icon: Icons.info_outline,
              label: l10n.workspaceInfo,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => WorkspaceSettingsDialog(
                    workspaceId: workspace.id,
                    workspaceName: workspace.name,
                    userRole: workspace.role,
                  ),
                );
              },
            ),
            _MenuOption(
              icon: Icons.people_outline,
              label: l10n.members,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => WorkspaceSettingsDialog(
                    workspaceId: workspace.id,
                    workspaceName: workspace.name,
                    userRole: workspace.role,
                  ),
                );
              },
            ),
            const Divider(),
            _MenuOption(
              icon: Icons.swap_horiz,
              label: l10n.changeWorkspace,
              onTap: () {
                Navigator.pop(context);
                onWorkspaceChanged?.call();
              },
            ),
            _MenuOption(
              icon: Icons.add_circle_outline,
              label: l10n.createWorkspace,
              onTap: () {
                Navigator.pop(context);
                context.push('/workspaces');
              },
            ),
            _MenuOption(
              icon: Icons.login,
              label: l10n.joinWorkspace,
              onTap: () {
                Navigator.pop(context);
                context.push('/workspaces');
              },
            ),
            if (!isOwner)
              _MenuOption(
                icon: Icons.exit_to_app,
                label: l10n.leaveWorkspace,
                color: Colors.orange,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.leaveWorkspace),
                      content: Text(l10n.leaveWorkspaceConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: Text(l10n.leaveWorkspace),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      final api = ref.read(apiServiceProvider);
                      final authState = ref.read(authStateProvider);
                      await api.removeWorkspaceMember(
                        workspaceId: workspace.id,
                        userId: authState.user!.id,
                      );
                      
                      storage.saveLastWorkspace(null);
                      Navigator.pop(context);
                      onWorkspaceLeft?.call();
                    } catch (e) {
                      if (context.mounted) {
                        context.showErrorSnackBar(e);
                      }
                    }
                  }
                },
              ),
            if (isOwner)
              _MenuOption(
                icon: Icons.delete_outline,
                label: l10n.deleteWorkspace,
                color: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deleteWorkspace),
                      content: Text(l10n.deleteWorkspaceConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      final api = ref.read(apiServiceProvider);
                      await api.deleteWorkspace(workspace.id);
                      
                      storage.saveLastWorkspace(null);
                      Navigator.pop(context);
                      onWorkspaceDeleted?.call();
                    } catch (e) {
                      if (context.mounted) {
                        context.showErrorSnackBar(e);
                      }
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color ?? Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
