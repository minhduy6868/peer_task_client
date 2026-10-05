import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/error_display.dart';
import '../../utils/validators_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../dialogs/join_workspace_dialog.dart';

class WorkspaceSelectionScreen extends ConsumerStatefulWidget {
  const WorkspaceSelectionScreen({super.key});

  @override
  ConsumerState<WorkspaceSelectionScreen> createState() => _WorkspaceSelectionScreenState();
}

class _WorkspaceSelectionScreenState extends ConsumerState<WorkspaceSelectionScreen> {
  String _getRoleDisplay(String? role, AppLocalizations l10n) {
    switch (role) {
      case 'owner':
        return l10n.owner;
      case 'editor':
        return l10n.editor;
      case 'viewer':
        return l10n.viewer;
      default:
        return l10n.member;
    }
  }

  void _showCreateWorkspaceDialog() {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.createWorkspace),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.enterWorkspaceName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.workspaces_rounded),
            ),
            validator: ValidatorsL10n.workspaceName(context),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final name = controller.text.trim();
              try {
                await ref.read(workspacesProvider.notifier).createWorkspace(name);
                if (mounted) {
                  Navigator.pop(context);
                  // Wait a bit and refresh
                  await Future.delayed(const Duration(milliseconds: 300));
                  ref.invalidate(workspacesProvider);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  context.showErrorSnackBar(e);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinWorkspaceDialog() async {
    final token = await showDialog<String>(
      context: context,
      builder: (context) => const JoinWorkspaceDialog(),
    );
    if (token == null || !mounted) return;

    try {
      final workspaceId = await ref.read(apiServiceProvider).joinWorkspace(token);
      ref.invalidate(workspacesProvider);
      if (!mounted) return;
      if (workspaceId != null) {
        context.go('/workspace/$workspaceId/boards');
      }
      context.showSuccessMessage(AppLocalizations.of(context)!.joinedSuccessfully);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(workspacesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(l10n.workspaces),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: l10n.logout,
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
          
          // Content
          workspacesAsync.when(
            loading: () => SliverToBoxAdapter(
              child: _buildLoadingSkeleton(),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: ErrorDisplay.buildErrorWidget(
                error,
                retryLabel: l10n.retry,
                onRetry: () => ref.invalidate(workspacesProvider),
              ),
            ),
            data: (workspaces) {
              if (workspaces.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.workspaces_outlined,
                              size: 28,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.welcome,
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.createOrJoinWorkspace,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showCreateWorkspaceDialog,
                                icon: const Icon(Icons.add_rounded, size: 22),
                                label: Text(l10n.createWorkspace),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showJoinWorkspaceDialog,
                                icon: const Icon(Icons.group_add_rounded, size: 22),
                                label: Text(l10n.joinWorkspace),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                sliver: SliverList.separated(
                  itemCount: workspaces.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildWorkspaceCard(workspaces[index]),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: _showJoinWorkspaceDialog,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            icon: const Icon(Icons.group_add_rounded),
            label: Text(l10n.joinWorkspace),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _showCreateWorkspaceDialog,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.createWorkspace),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(workspace) {
    final initial = workspace.name.isEmpty ? '?' : workspace.name.substring(0, 1).toUpperCase();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final storage = ref.read(storageServiceProvider);
          await storage.saveLastWorkspace(workspace.id);
          context.go('/workspace/${workspace.id}/boards');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  workspace.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getRoleDisplay(workspace.role, AppLocalizations.of(context)!),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
