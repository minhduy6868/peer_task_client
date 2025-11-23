import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peertask/providers/app_providers.dart';

class WorkspacesScreen extends ConsumerStatefulWidget {
  const WorkspacesScreen({super.key});

  @override
  ConsumerState<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends ConsumerState<WorkspacesScreen> {
  void _showCreateWorkspaceDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workspace'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Workspace Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  await ref.read(workspacesProvider.notifier).createWorkspace(name);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(workspacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: workspacesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(workspacesProvider.notifier).loadWorkspaces();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (workspaces) {
          if (workspaces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspaces, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No workspaces yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateWorkspaceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Workspace'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: workspaces.length,
            itemBuilder: (context, index) {
              final workspace = workspaces[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.workspaces),
                  ),
                  title: Text(workspace.name),
                  subtitle: Text('Role: ${workspace.role ?? 'member'}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go('/workspace/${workspace.id}/boards');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateWorkspaceDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
