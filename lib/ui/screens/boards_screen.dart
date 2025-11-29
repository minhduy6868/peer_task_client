import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/models/board/board.dart';
import '../dialogs/board_settings_dialog.dart';

final workspaceBoardsProvider = FutureProvider.family<List<Board>, String>((ref, workspaceId) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getWorkspaceBoards(workspaceId);
});

final currentWorkspaceRoleProvider = FutureProvider.family<String?, String>((ref, workspaceId) async {
  final api = ref.watch(apiServiceProvider);
  final workspace = await api.getWorkspace(workspaceId);
  return workspace.role; // Returns 'owner', 'editor', or 'viewer'
});

class BoardsScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const BoardsScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  void _showCreateBoardDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Board Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.createBoard(
                    workspaceId: widget.workspaceId,
                    name: name,
                    description: descController.text.trim().isEmpty 
                      ? null 
                      : descController.text.trim(),
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    // Refresh the boards list
                    ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                  }
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
    final boardsAsync = ref.watch(workspaceBoardsProvider(widget.workspaceId));
    final roleAsync = ref.watch(currentWorkspaceRoleProvider(widget.workspaceId));

    // Check if user can create boards (owner or editor)
    final canCreateBoard = roleAsync.maybeWhen(
      data: (role) => role == 'owner' || role == 'editor',
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boards'),
      ),
      floatingActionButton: canCreateBoard
          ? FloatingActionButton(
              onPressed: _showCreateBoardDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: boardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (boards) {
          if (boards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(canCreateBoard 
                    ? 'No boards yet. Create one to get started!'
                    : 'No boards available. Ask workspace admin to add you to a board.'),
                  if (canCreateBoard) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showCreateBoardDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Board'),
                    ),
                  ],
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: boards.length,
            itemBuilder: (context, index) {
              final board = boards[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    context.go('/board/${board.id}');
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (context) => BoardSettingsDialog(
                                boardId: board.id,
                                boardName: board.name,
                                boardDescription: board.description,
                              ),
                            );
                            
                            if (result == 'deleted' && mounted) {
                              ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                            } else if (result == true && mounted) {
                              ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.dashboard, size: 32),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        board.name,
                                        style: Theme.of(context).textTheme.titleLarge,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (board.isBoardOwner == true) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                              ),
                                              child: const Text(
                                                'Owner',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.purple,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          if (board.permission != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: board.permission == 'edit'
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: board.permission == 'edit'
                                                      ? Colors.green.withOpacity(0.3)
                                                      : Colors.blue.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    board.permission == 'edit' ? Icons.edit : Icons.visibility,
                                                    size: 10,
                                                    color: board.permission == 'edit' ? Colors.green : Colors.blue,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    board.permission == 'edit' ? 'Edit' : 'View',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: board.permission == 'edit' ? Colors.green : Colors.blue,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40), // Space for settings button
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (board.description != null)
                              Text(
                                board.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (board.description != null)
                              const SizedBox(height: 8),
                            const Spacer(),
                            Text(
                              'Created ${_formatDate(board.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
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
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return 'just now';
    }
  }
}
