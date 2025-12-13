import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../utils/error_display.dart';

class WorkspaceSettingsDialog extends ConsumerStatefulWidget {
  final String workspaceId;
  final String workspaceName;
  final String? userRole;

  const WorkspaceSettingsDialog({
    super.key,
    required this.workspaceId,
    required this.workspaceName,
    this.userRole,
  });

  @override
  ConsumerState<WorkspaceSettingsDialog> createState() => _WorkspaceSettingsDialogState();
}

class _WorkspaceSettingsDialogState extends ConsumerState<WorkspaceSettingsDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.settings_rounded),
                const SizedBox(width: 8),
                Text(
                  l10n.workspaceSettings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.info_outline_rounded),
                        label: Text(l10n.general),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.people),
                        label: Text(l10n.members),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.link_rounded),
                        label: Text(l10n.invites),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _GeneralTab(
          workspaceId: widget.workspaceId,
          workspaceName: widget.workspaceName,
          userRole: widget.userRole,
        );
      case 1:
        return _MembersTab(
          workspaceId: widget.workspaceId,
          userRole: widget.userRole,
        );
      case 2:
        return _InvitesTab(
          workspaceId: widget.workspaceId,
          userRole: widget.userRole,
        );
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }
}

class _GeneralTab extends ConsumerStatefulWidget {
  final String workspaceId;
  final String workspaceName;
  final String? userRole;

  const _GeneralTab({
    required this.workspaceId,
    required this.workspaceName,
    this.userRole,
  });

  @override
  ConsumerState<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<_GeneralTab> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workspaceName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.userRole == 'owner' || widget.userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.workspaceName,
            border: const OutlineInputBorder(),
          ),
          enabled: _canEdit,
        ),
        const SizedBox(height: 16),
        if (_canEdit) ...[
          ElevatedButton.icon(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty && name != widget.workspaceName) {
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.updateWorkspace(
                    workspaceId: widget.workspaceId,
                    name: name,
                  );
                  if (mounted) {
                    context.showSuccessMessage(l10n.workspaceUpdated);
                    ref.invalidate(workspacesProvider);
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    context.showErrorSnackBar(e);
                  }
                }
              }
            },
            icon: const Icon(Icons.save_rounded),
            label: Text(l10n.saveChanges),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
        ],
        if (widget.userRole == 'owner') ...[
          Text(
            l10n.dangerZone,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final l10nDialog = AppLocalizations.of(context)!;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10nDialog.deleteWorkspace),
                  content: Text(l10nDialog.deleteAllData),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10nDialog.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10nDialog.delete),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.deleteWorkspace(widget.workspaceId);
                  if (mounted) {
                    ref.invalidate(workspacesProvider);
                    Navigator.pop(context);
                    context.showSuccessMessage(l10n.workspaceDeleted);
                  }
                } catch (e) {
                  if (mounted) {
                    context.showErrorSnackBar(e);
                  }
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: Text(l10n.deleteWorkspace),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }
}

class _MembersTab extends ConsumerStatefulWidget {
  final String workspaceId;
  final String? userRole;

  const _MembersTab({
    required this.workspaceId,
    this.userRole,
  });

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

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
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final members = await api.getWorkspaceMembers(widget.workspaceId);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        context.showErrorSnackBar(e);
      }
    }
  }

  bool get _canManageMembers => widget.userRole == 'owner';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_canManageMembers)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                final l10n = AppLocalizations.of(context)!;
                context.showInfoMessage(l10n.useInviteLinkToAdd);
              },
              icon: const Icon(Icons.person_add_rounded),
              label: Text(l10n.addMember),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              final isOwner = member['role'] == 'owner';
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (member['name'] ?? member['email'])
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                  ),
                ),
                title: Text(member['name'] ?? member['email']),
                subtitle: Text(member['email']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(_getRoleDisplayName(member['role'])),
                      backgroundColor: isOwner
                          ? Colors.purple.shade100
                          : member['role'] == 'editor'
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                    ),
                    if (_canManageMembers && !isOwner) ...[
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        itemBuilder: (context) {
                          final menuL10n = AppLocalizations.of(context)!;
                          return [
                            const PopupMenuItem(
                              value: 'editor',
                              child: Text('Make Editor'),
                            ),
                            const PopupMenuItem(
                              value: 'viewer',
                              child: Text('Make Viewer'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(menuL10n.remove),
                            ),
                          ];
                        },
                        onSelected: (value) async {
                          if (value == 'remove') {
                            await _removeMember(member['user_id']);
                          } else {
                            await _updateRole(member['user_id'], value.toString());
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateRole(String userId, String newRole) async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating role...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      print('Updating role for user $userId to $newRole in workspace ${widget.workspaceId}');
      final api = ref.read(apiServiceProvider);
      print('API baseUrl: ${api.baseUrl}');
      print('Making PUT request to: ${api.baseUrl}/workspaces/${widget.workspaceId}/members/$userId');
      print('Request body: {"role": "$newRole"}');
      
      await api.updateWorkspaceMemberRole(
        workspaceId: widget.workspaceId,
        userId: userId,
        role: newRole,
      );
      print('Role update API call completed successfully');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      await _loadMembers();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        context.showSuccessMessage(l10n.roleUpdated);
      }
    } catch (e, stackTrace) {
      print('Error updating role: $e');
      print('Stack trace: $stackTrace');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Removing member...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      print('Removing user $userId from workspace ${widget.workspaceId}');
      final api = ref.read(apiServiceProvider);
      await api.removeWorkspaceMember(
        workspaceId: widget.workspaceId,
        userId: userId,
      );
      print('Remove member API call completed');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      await _loadMembers();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        context.showSuccessMessage(l10n.memberRemoved);
      }
    } catch (e) {
      print('Error removing member: $e');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }
}

class _InvitesTab extends ConsumerStatefulWidget {
  final String workspaceId;
  final String? userRole;

  const _InvitesTab({
    required this.workspaceId,
    this.userRole,
  });

  @override
  ConsumerState<_InvitesTab> createState() => _InvitesTabState();
}

class _InvitesTabState extends ConsumerState<_InvitesTab> {
  List<Map<String, dynamic>> _invites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final invites = await api.getInviteLinks(widget.workspaceId);
      if (mounted) {
        setState(() {
          _invites = invites;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool get _canManageInvites => widget.userRole == 'owner';

  Future<void> _createInviteLink() async {
    if (!mounted) return;
    
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.createInviteLink(
        workspaceId: widget.workspaceId,
        maxUses: 10,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      if (mounted) {
        await _loadInvites();
        
        // Show invite link dialog with QR code
        // Try multiple possible keys from API response
        final token = result['token'] as String? ?? 
                     result['inviteLink'] as String? ?? 
                     result['id'] as String? ??
                     '';
        
        if (token.isEmpty) {
          if (mounted) {
            context.showWarningMessage('Failed to extract invite code from response');
          }
          return;
        }
        
        showDialog(
          context: context,
          builder: (dialogContext) {
            final inviteL10n = AppLocalizations.of(dialogContext)!;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inviteL10n.inviteCodeCreated,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inviteL10n.shareCodeToInvite,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (token.isNotEmpty) ...[
                            // Info Banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.info.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: AppColors.info,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      inviteL10n.scanQROrCopy,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.info,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // QR Code
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                                child: QrImageView(
                                  data: token,
                                  version: QrVersions.auto,
                                  size: 220.0,
                                  backgroundColor: Colors.white,
                                  eyeStyle: QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppColors.primary,
                                  ),
                                  dataModuleStyle: QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppColors.border,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppColors.border,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Token text
                            Text(
                              'Invite Code:',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.05),
                                    AppColors.secondary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: SelectableText(
                                token,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Copy button with gradient
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: token));
                                  final inviteL10n = AppLocalizations.of(dialogContext)!;
                                  ErrorHandler.showSuccess(dialogContext, inviteL10n.codeCopied);
                                },
                                icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
                                label: Text(
                                  inviteL10n.copyCode,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Close button
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                inviteL10n.close,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }

  void _showInviteDetails(String inviteId) {
    if (!mounted) return;
    
    final inviteL10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.surface.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.link_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite Link',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inviteL10n.shareCodeToInvite,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.info,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                inviteL10n.scanQROrCopy,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // QR Code
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: QrImageView(
                            data: inviteId,
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primary,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Token text
                      Text(
                        'Invite Code:',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.05),
                              AppColors.secondary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: SelectableText(
                          inviteId,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Copy button with gradient
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: inviteId));
                            ErrorHandler.showSuccess(dialogContext, inviteL10n.codeCopied);
                          },
                          icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
                          label: Text(
                            inviteL10n.copyCode,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Close button
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          inviteL10n.close,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_canManageInvites)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _createInviteLink,
              icon: const Icon(Icons.add_link),
              label: Text(l10n.createInviteLink),
            ),
          ),
        Expanded(
          child: _invites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noActiveInvites,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _invites.length,
                  itemBuilder: (context, index) {
                    final invite = _invites[index];
                    final expiresAtStr = invite['expires_at'] as String?;
                    final expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : DateTime.now();
                    final isExpired = expiresAt.isBefore(DateTime.now());
                    final inviteId = invite['id']?.toString() ?? 'unknown';
                    final inviteCode = inviteId.length > 8 ? inviteId.substring(0, 8) : inviteId;
                    final uses = invite['uses']?.toString() ?? '0';
                    final maxUses = invite['max_uses']?.toString() ?? '0';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpired 
                                ? AppColors.error.withOpacity(0.3)
                                : AppColors.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isExpired ? null : () => _showInviteDetails(inviteId),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: isExpired 
                                          ? LinearGradient(
                                              colors: [
                                                AppColors.error.withOpacity(0.2),
                                                AppColors.error.withOpacity(0.1),
                                              ],
                                            )
                                          : AppColors.gradientPrimary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isExpired ? Icons.link_off_rounded : Icons.link_rounded,
                                      color: isExpired ? AppColors.error : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${l10n.invite} #$inviteCode',
                                              style: AppTextStyles.titleMedium.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isExpired 
                                                    ? AppColors.textSecondary
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            if (isExpired) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  l10n.expired,
                                                  style: AppTextStyles.labelSmall.copyWith(
                                                    color: AppColors.error,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.people_outline_rounded,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Uses: $uses/$maxUses',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isExpired
                                                  ? l10n.expired
                                                  : 'Expires: ${_formatDate(expiresAt)}',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: isExpired 
                                                    ? AppColors.error
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Actions
                                  if (_canManageInvites) ...[
                                    if (!isExpired)
                                      IconButton(
                                        icon: Icon(
                                          Icons.qr_code_rounded,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: 'View QR Code',
                                        onPressed: () => _showInviteDetails(inviteId),
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        try {
                                          final api = ref.read(apiServiceProvider);
                                          await api.revokeInviteLink(
                                            workspaceId: widget.workspaceId,
                                            inviteId: invite['id'],
                                          );
                                          await _loadInvites();
                                          if (mounted) {
                                            final l10nMsg = AppLocalizations.of(context)!;
                                            context.showSuccessMessage(l10nMsg.inviteRevoked);
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            context.showErrorSnackBar(e);
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
