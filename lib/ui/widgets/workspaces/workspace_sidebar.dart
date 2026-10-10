import 'package:flutter/material.dart';

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

  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primarySubtle = Color(0xFFF3E8FF);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFF1E9DC);

  @override
  Widget build(BuildContext context) {
    final width = isCompact ? 72.0 : 230.0;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.diversity_3_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'PeerTask',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),

          // Main Navigation Items - Only Workspaces
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12),
              children: [
                _buildNavItem(
                  id: 'workspaces',
                  icon: Icons.grid_view_rounded,
                  label: 'Workspaces',
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 8),

          // Bottom Section - Only Help
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12),
            child: Column(
              children: [
                _buildNavItem(
                  id: 'help',
                  icon: Icons.help_outline_rounded,
                  label: 'Trợ giúp',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String id,
    required IconData icon,
    required String label,
  }) {
    final isActive = activeItem == id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: isCompact ? label : '',
        child: InkWell(
          onTap: () => onSelectItem(id),
          borderRadius: BorderRadius.circular(10),
          hoverColor: primarySubtle.withValues(alpha: 0.6),
          child: Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 12),
            decoration: BoxDecoration(
              color: isActive ? primarySubtle : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? primaryPurple : textMuted,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? primaryPurple : textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
