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
  // void _showCreateBoardDialog() {
  //   final nameController = TextEditingController();
  //   final descController = TextEditingController();
    void _showCreateBoardDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.9,
          ),
          child: IntrinsicHeight(
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F7FA), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề + icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 12 : 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Create New Board',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Board Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Board Name',
                        hintText: 'Enter a creative name...',
                        prefixIcon: const Icon(Icons.label_outline, color: Color(0xFF667EEA)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2)),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'What is this board about?',
                        prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF667EEA)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2)),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Nút Cancel + Create
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;

                              try {
                                final api = ref.read(apiServiceProvider);
                                await api.createBoard(
                                  workspaceId: widget.workspaceId,
                                  name: name,
                                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Board "$name" created successfully!'),
                                      backgroundColor: const Color(0xFF43E97B),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('📋 My Boards', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: canCreateBoard
          ? MediaQuery.of(context).size.width > 600
              ? FloatingActionButton.extended(
                  onPressed: _showCreateBoardDialog,
                  backgroundColor: const Color(0xFF667EEA),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text('New Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  elevation: 8,
                )
              : FloatingActionButton(
                  onPressed: _showCreateBoardDialog,
                  backgroundColor: const Color(0xFF667EEA),
                  child: const Icon(Icons.add, color: Colors.white),
                  elevation: 8,
                )
          : null,
      body: boardsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF667EEA)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Loading boards...', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: MediaQuery.of(context).size.width > 600 ? 64 : 48, color: Colors.red),
                  SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
                  Text('Oops! Something went wrong', 
                    style: TextStyle(fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width > 600 ? 8 : 6),
                  Text('$error', 
                    style: TextStyle(color: Colors.grey, fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (boards) {
          if (boards.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 48 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.dashboard_customize, size: MediaQuery.of(context).size.width > 600 ? 64 : 48, color: Colors.white),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 16),
                      Text(
                        canCreateBoard 
                          ? '🎨 Ready to Create?'
                          : '📋 No Boards Yet',
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.width > 600 ? 12 : 8),
                      Text(
                        canCreateBoard 
                          ? 'Create your first board and start collaborating!'
                          : 'Ask your workspace admin to add you to a board.',
                        style: TextStyle(color: Colors.grey, fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14),
                        textAlign: TextAlign.center,
                      ),
                      if (canCreateBoard) ...[
                        SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),
                        ElevatedButton.icon(
                          onPressed: _showCreateBoardDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 24,
                              vertical: MediaQuery.of(context).size.width > 600 ? 16 : 12,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                          ),
                          icon: Icon(Icons.add_circle_outline, size: MediaQuery.of(context).size.width > 600 ? 24 : 20),
                          label: Text('Create Board', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Icon(Icons.grid_view, size: MediaQuery.of(context).size.width > 600 ? 28 : 24, color: const Color(0xFF667EEA)),
                      SizedBox(width: MediaQuery.of(context).size.width > 600 ? 12 : 8),
                      Expanded(
                        child: Text(
                          '${boards.length} Board${boards.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.of(context).size.width > 900 
                        ? 350 
                        : (MediaQuery.of(context).size.width > 600 ? 300 : double.infinity),
                    crossAxisSpacing: MediaQuery.of(context).size.width > 600 ? 20 : 16,
                    mainAxisSpacing: MediaQuery.of(context).size.width > 600 ? 20 : 16,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.4 : 1.3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final board = boards[index];
                      final gradients = [
                        [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                        [const Color(0xFFF093FB), const Color(0xFFF5576C)],
                        [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
                        [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
                        [const Color(0xFFFA709A), const Color(0xFFFEE140)],
                        [const Color(0xFF30CFD0), const Color(0xFF330867)],
                      ];
                      final gradient = gradients[index % gradients.length];
                      
                      return _BoardCard(
                        board: board,
                        gradient: gradient,
                        onTap: () => context.go('/board/${board.id}'),
                        onSettings: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (context) => BoardSettingsDialog(
                              boardId: board.id,
                              boardName: board.name,
                              boardDescription: board.description,
                            ),
                          );
                          
                          if ((result == 'deleted' || result == true) && mounted) {
                            ref.invalidate(workspaceBoardsProvider(widget.workspaceId));
                          }
                        },
                      );
                    },
                    childCount: boards.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
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

class _BoardCard extends StatefulWidget {
  final Board board;
  final List<Color> gradient;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const _BoardCard({
    required this.board,
    required this.gradient,
    required this.onTap,
    required this.onSettings,
  });

  @override
  State<_BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<_BoardCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: widget.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient[0].withOpacity(_isHovered ? 0.5 : 0.3),
                  blurRadius: _isHovered ? 25 : 15,
                  spreadRadius: _isHovered ? 3 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // Settings button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onSettings,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.settings, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Board icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.dashboard_customize, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      
                      // Board name
                      Text(
                        widget.board.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Description
                      if (widget.board.description != null && widget.board.description!.isNotEmpty)
                        Text(
                          widget.board.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const Spacer(),
                      
                      // Badges and date
                      Row(
                        children: [
                          if (widget.board.isBoardOwner == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Owner',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.board.isBoardOwner == true && widget.board.permission != null)
                            const SizedBox(width: 6),
                          if (widget.board.permission != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.board.permission == 'edit' ? Icons.edit : Icons.visibility,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.board.permission == 'edit' ? 'Editor' : 'Viewer',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(widget.board.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
