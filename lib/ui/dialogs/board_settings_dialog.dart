import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class BoardSettingsDialog extends ConsumerStatefulWidget {
  final String boardId;
  final String boardName;
  final String? boardDescription;

  const BoardSettingsDialog({
    super.key,
    required this.boardId,
    required this.boardName,
    this.boardDescription,
  });

  @override
  ConsumerState<BoardSettingsDialog> createState() => _BoardSettingsDialogState();
}

class _BoardSettingsDialogState extends ConsumerState<BoardSettingsDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.settings),
                const SizedBox(width: 8),
                Text(
                  'Board Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
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
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.info_outline),
                        label: Text('General'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people),
                        label: Text('Members'),
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
          boardId: widget.boardId,
          boardName: widget.boardName,
          boardDescription: widget.boardDescription,
        );
      case 1:
        return _MembersTab(boardId: widget.boardId);
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }
}

class _GeneralTab extends ConsumerStatefulWidget {
  final String boardId;
  final String boardName;
  final String? boardDescription;

  const _GeneralTab({
    required this.boardId,
    required this.boardName,
    this.boardDescription,
  });

  @override
  ConsumerState<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<_GeneralTab> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.boardName);
    _descController = TextEditingController(text: widget.boardDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Board Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              try {
                final api = ref.read(apiServiceProvider);
                await api.updateBoard(
                  boardId: widget.boardId,
                  name: name,
                  description: _descController.text.trim().isEmpty 
                    ? null 
                    : _descController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Board updated')),
                  );
                  Navigator.pop(context, true);
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
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Danger Zone',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Board'),
                content: const Text(
                  'Are you sure? This will delete all tasks and data. This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteBoard(widget.boardId);
                if (mounted) {
                  Navigator.pop(context, 'deleted');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Board deleted')),
                  );
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
          icon: const Icon(Icons.delete_forever),
          label: const Text('Delete Board'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends ConsumerStatefulWidget {
  final String boardId;

  const _MembersTab({required this.boardId});

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _workspaceId;

  @override
  void initState() {
    super.initState();
    _loadBoardInfo();
  }

  Future<void> _loadBoardInfo() async {
    try {
      final api = ref.read(apiServiceProvider);
      final board = await api.getBoard(widget.boardId);
      if (mounted) {
        setState(() {
          _workspaceId = board.workspaceId;
        });
        await _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading board info: $e')),
        );
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final members = await api.getBoardMembers(widget.boardId);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _workspaceId != null ? _showAddMemberDialog : null,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Collaborator'),
          ),
        ),
        Expanded(
          child: _members.isEmpty
              ? const Center(child: Text('No collaborators yet'))
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isBoardOwner = member['is_board_owner'] == true;
                    final workspaceRole = member['workspace_role'];
                    
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
                      subtitle: Row(
                        children: [
                          Text(member['email']),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: workspaceRole == 'owner'
                                  ? Colors.purple.withOpacity(0.1)
                                  : workspaceRole == 'editor'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'WS: $workspaceRole',
                              style: TextStyle(
                                fontSize: 9,
                                color: workspaceRole == 'owner'
                                    ? Colors.purple
                                    : workspaceRole == 'editor'
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBoardOwner) ...[
                            const Chip(
                              label: Text('Owner'),
                              backgroundColor: Colors.purple,
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Chip(
                            label: Text(member['permission']),
                            backgroundColor: member['permission'] == 'edit'
                                ? Colors.green.shade100
                                : Colors.blue.shade100,
                          ),
                          if (!isBoardOwner) ...[
                            const SizedBox(width: 8),
                            PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Permission'),
                              ),
                              const PopupMenuItem(
                                value: 'view',
                                child: Text('View Permission'),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove'),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'remove') {
                                await _removeMember(member['user_id']);
                              } else {
                                await _updatePermission(member['user_id'], value.toString());
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

  Future<void> _showAddMemberDialog() async {
    if (_workspaceId == null) return;
    
    try {
      print('Loading workspace members for workspace: $_workspaceId');
      final api = ref.read(apiServiceProvider);
      
      // Get workspace members
      final workspaceMembers = await api.getWorkspaceMembers(_workspaceId!);
      print('Loaded ${workspaceMembers.length} workspace members');
      
      // Filter out members already in board
      final memberIds = _members.map((m) => m['user_id']).toSet();
      print('Current board member IDs: $memberIds');
      final availableMembers = workspaceMembers
          .where((m) => !memberIds.contains(m['user_id']))
          .toList();
      print('Available members to add: ${availableMembers.length}');
      
      if (!mounted) return;
      
      if (availableMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All workspace members are already in this board')),
        );
        return;
      }
      
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => _AddMemberDialog(members: availableMembers),
      );
      
      if (result != null && mounted) {
        await _addMember(result['userId']!, result['permission']!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addMember(String userId, String permission) async {
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
                Text('Adding member to board...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      print('Adding member $userId with permission $permission to board ${widget.boardId}');
      final api = ref.read(apiServiceProvider);
      print('API baseUrl: ${api.baseUrl}');
      print('Making POST request to: ${api.baseUrl}/boards/${widget.boardId}/members');
      print('Request body: {"userId": "$userId", "permission": "$permission"}');
      
      await api.addBoardMember(
        boardId: widget.boardId,
        userId: userId,
        permission: permission,
      );
      print('Add board member API call completed successfully');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error adding member: $e');
      print('Stack trace: $stackTrace');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updatePermission(String userId, String newPermission) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateBoardMemberPermission(
        boardId: widget.boardId,
        userId: userId,
        permission: newPermission,
      );
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.removeBoardMember(
        boardId: widget.boardId,
        userId: userId,
      );
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// Dialog to add member to board
class _AddMemberDialog extends StatefulWidget {
  final List<Map<String, dynamic>> members;

  const _AddMemberDialog({required this.members});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  String? _selectedUserId;
  String _permission = 'view';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Collaborator'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select member:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedUserId,
              hint: const Text('Choose a member'),
              items: widget.members.map((member) {
                final role = member['role'] ?? 'viewer';
                final roleColor = role == 'owner' 
                    ? Colors.purple 
                    : role == 'editor' 
                        ? Colors.blue 
                        : Colors.grey;
                
                return DropdownMenuItem<String>(
                  value: member['user_id'],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          (member['name'] ?? member['email'])
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              member['name'] ?? 'No name',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    member['email'],
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: roleColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: roleColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUserId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Permission:'),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: [
                const ButtonSegment(
                  value: 'view',
                  label: Text('View Only'),
                  icon: Icon(Icons.visibility),
                ),
                ButtonSegment(
                  value: 'edit',
                  label: const Text('Can Edit'),
                  icon: const Icon(Icons.edit),
                ),
              ],
              selected: {_permission},
              onSelectionChanged: (Set<String> selected) {
                setState(() => _permission = selected.first);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedUserId == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'userId': _selectedUserId!,
                    'permission': _permission,
                  });
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
