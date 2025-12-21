import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/language_provider.dart';
import 'offline_board_screen.dart';
import 'package:uuid/uuid.dart';
import '../../services/storage_service.dart';
import '../theme/app_colors.dart';

/// Screen to create or select offline boards
class OfflineBoardsScreen extends ConsumerStatefulWidget {
  const OfflineBoardsScreen({super.key});

  @override
  ConsumerState<OfflineBoardsScreen> createState() => _OfflineBoardsScreenState();
}

class _OfflineBoardsScreenState extends ConsumerState<OfflineBoardsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _createNewBoard() {
    final boardId = const Uuid().v4();
    final boardName = 'Board ${DateTime.now().hour}:${DateTime.now().minute}';

    // Save board state to storage immediately
    final storage = StorageService();
    storage.saveBoardState(boardId, {
      'name': boardName,
      'createdAt': DateTime.now().toIso8601String(),
      'tasks': [],
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            OfflineBoardScreen(boardId: boardId, boardName: boardName),
      ),
    );
  }

  void _showJoinBoardDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 8-character board code:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              maxLength: 8,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'XXXXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the board creator to share their code.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim().toUpperCase();
              if (code.length == 8) {
                Navigator.pop(context);
                _openBoardFromCode(code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code must be exactly 8 characters'),
                  ),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _openBoardFromCode(String code) {
    final storage = StorageService();
    print('🔍 Searching for board with code: $code');

    // Check if board exists locally first
    String? existingBoardId = storage.getBoardIdByCode(code);
    
    if (existingBoardId != null) {
      // Board exists - open it
      final boardState = storage.getBoardState(existingBoardId);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OfflineBoardScreen(
            boardId: existingBoardId,
            boardName: boardState?['name'] as String? ?? 'Shared Board',
          ),
        ),
      );
      return;
    }

    // Board doesn't exist - create it with code as UUID prefix
    // This ensures both devices use SAME boardId for P2P discovery
    final boardId = '${code.toLowerCase()}-0000-0000-0000-000000000000';
    
    storage.saveBoardState(boardId, {
      'name': 'Joined Board',
      'createdAt': DateTime.now().toIso8601String(),
      'tasks': [],
      'columns': ['To Do', 'In Progress', 'Done'],
    });

    print('✅ Created board: $boardId');
    print('🔄 Will connect to peer with same board code via P2P');

    // Navigate - P2P will discover peer automatically
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OfflineBoardScreen(
          boardId: boardId,
          boardName: 'Joined Board',
        ),
      ),
    );
  }

  void _showChangeNameDialog() {
    final storage = StorageService();
    final currentName = storage.getOfflineUsername() ?? 'Guest';
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Your Name'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Enter your name...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty && name.length <= 20) {
                await storage.saveOfflineUsername(name);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final username = storage.getOfflineUsername() ?? 'Guest';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with gradient
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => _showExitConfirmDialog(context),
            ),
            actions: [
              // Username chip
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: _showChangeNameDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : 'G',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            size: 13,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Offline Boards',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.accentPurple,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -40,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Icon
                    Positioned(
                      top: 50,
                      right: 30,
                      child: Icon(
                        Icons.cloud_off_rounded,
                        size: 50,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card with glassmorphism effect
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primarySubtle, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Works Without Internet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Share boards with nearby devices using P2P connection on the same WiFi network.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Cards
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Create Board Card
                      Expanded(
                        child: _ActionCard(
                          onTap: _createNewBoard,
                          icon: Icons.add_rounded,
                          title: 'Create Board',
                          subtitle: 'Start a new board',
                          gradientColors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Join Board Card
                      Expanded(
                        child: _ActionCard(
                          onTap: _showJoinBoardDialog,
                          icon: Icons.group_add_rounded,
                          title: 'Join Board',
                          subtitle: 'Enter share code',
                          gradientColors: [
                            AppColors.success,
                            AppColors.accentTeal,
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Features Section
                  Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ModernFeatureCard(
                    icon: Icons.brush_rounded,
                    iconColor: AppColors.accentPurple,
                    title: 'Freehand Drawing',
                    description:
                        'Sketch ideas with pen, eraser, and text tools',
                  ),
                  const SizedBox(height: 12),
                  _ModernFeatureCard(
                    icon: Icons.view_kanban_rounded,
                    iconColor: AppColors.primary,
                    title: 'Kanban Board',
                    description: 'Organize tasks in TODO, DOING, DONE columns',
                  ),
                  const SizedBox(height: 12),
                  _ModernFeatureCard(
                    icon: Icons.share_rounded,
                    iconColor: AppColors.success,
                    title: 'P2P Sharing',
                    description: 'Share with 8-character codes on same network',
                  ),
                  const SizedBox(height: 12),
                  _ModernFeatureCard(
                    icon: Icons.save_rounded,
                    iconColor: AppColors.warning,
                    title: 'Auto Save',
                    description: 'All changes saved automatically to device',
                  ),

                  const SizedBox(height: 32),

                  // Exit button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showExitConfirmDialog(context),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: AppColors.textSecondary,
                      ),
                      label: Text(
                        'Back to Login',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Exit Offline Mode'),
          ],
        ),
        content: const Text(
          'Are you sure you want to go back to the login screen?\n\n'
          'Your offline boards will be saved and available when you return.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear offline username
              final storage = StorageService();
              storage.clearOfflineUsername();
              Navigator.pop(context); // Close dialog
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _ActionCard({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ModernFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
