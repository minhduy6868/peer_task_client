import 'package:flutter/material.dart';
import '../../../models/workspace/workspace.dart';

class WorkspaceCardStyle {
  final Color backgroundColor;
  final Color iconContainerColor;
  final Color iconColor;
  final IconData icon;

  const WorkspaceCardStyle({
    required this.backgroundColorColor,
    required this.iconContainerColor,
    required this.iconColor,
    required this.icon,
  }) : backgroundColor = backgroundColorColor;

  final Color backgroundColorColor;
}

class WorkspaceCard extends StatefulWidget {
  final Workspace workspace;
  final int cardIndex;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback onSettings;
  final VoidCallback onCopyInvite;
  final VoidCallback onDelete;
  final bool isListView;
  final int boardsCount;
  final int tasksCount;

  const WorkspaceCard({
    super.key,
    required this.workspace,
    required this.cardIndex,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
    required this.onSettings,
    required this.onCopyInvite,
    required this.onDelete,
    this.isListView = false,
    this.boardsCount = 0,
    this.tasksCount = 0,
  });

  @override
  State<WorkspaceCard> createState() => _WorkspaceCardState();
}

class _WorkspaceCardState extends State<WorkspaceCard> {
  bool _isHovered = false;

  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFF1E9DC);

  // 4 Pastel Themes matching the reference image cards
  static const List<WorkspaceCardStyle> _styles = [
    WorkspaceCardStyle(
      backgroundColorColor: Color(0xFFEEF2FF), // Soft Indigo
      iconContainerColor: Color(0xFFE0E7FF),
      iconColor: Color(0xFF6366F1),
      icon: Icons.code_rounded,
    ),
    WorkspaceCardStyle(
      backgroundColorColor: Color(0xFFFFEDD5), // Soft Peach/Orange
      iconContainerColor: Color(0xFFFED7AA),
      iconColor: Color(0xFFEA580C),
      icon: Icons.format_list_bulleted_rounded,
    ),
    WorkspaceCardStyle(
      backgroundColorColor: Color(0xFFDCFCE7), // Soft Mint
      iconContainerColor: Color(0xFFBBF7D0),
      iconColor: Color(0xFF16A34A),
      icon: Icons.eco_rounded,
    ),
    WorkspaceCardStyle(
      backgroundColorColor: Color(0xFFFCE7F3), // Soft Rose
      iconContainerColor: Color(0xFFFBCFE8),
      iconColor: Color(0xFFDB2777),
      icon: Icons.groups_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final style = _styles[widget.cardIndex % _styles.length];

    if (widget.isListView) {
      return _buildListCard(style);
    }
    return _buildGridCard(style);
  }

  Widget _buildGridCard(WorkspaceCardStyle style) {
    final roleText = _getRoleText(widget.workspace.role);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: _isHovered ? (Matrix4.identity()..translate(0, -3)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? primaryPurple.withValues(alpha: 0.4) : borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? primaryPurple.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Pastel Header Banner
                Container(
                  height: 110,
                  width: double.infinity,
                  color: style.backgroundColor,
                  child: Stack(
                    children: [
                      // Center Pastel Icon
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: style.iconContainerColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            style.icon,
                            color: style.iconColor,
                            size: 26,
                          ),
                        ),
                      ),

                      // Top-Left Favorite Star Button
                      Positioned(
                        top: 8,
                        left: 8,
                        child: InkWell(
                          onTap: widget.onToggleFavorite,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: widget.isFavorite ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),

                      // Top-Right Three-Dots Menu
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildActionMenu(),
                      ),
                    ],
                  ),
                ),

                // Card Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.workspace.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Description or Role
                      Text(
                        'Vai trò: $roleText',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),

                      // Members Avatar Stack
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 24,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  child: _buildAvatarCircle('👩', const Color(0xFFFCE7F3)),
                                ),
                                Positioned(
                                  left: 18,
                                  child: _buildAvatarCircle('👨', const Color(0xFFEDE9FE)),
                                ),
                                Positioned(
                                  left: 36,
                                  child: _buildAvatarCircle('🧑', const Color(0xFFDCFCE7)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '+1',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Divider(height: 1, color: Color(0xFFF1E9DC)),
                      const SizedBox(height: 10),

                      // Metadata stats footer (Boards and Tasks)
                      Row(
                        children: [
                          const Icon(Icons.folder_outlined, size: 15, color: textMuted),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.boardsCount} bảng',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.check_circle_outline_rounded, size: 15, color: textMuted),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.tasksCount} nhiệm vụ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
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

  Widget _buildListCard(WorkspaceCardStyle style) {
    final roleText = _getRoleText(widget.workspace.role);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isHovered ? primaryPurple.withValues(alpha: 0.4) : borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.05 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: style.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(style.icon, color: style.iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Title and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workspace.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Vai trò: $roleText',
                          style: const TextStyle(fontSize: 12, color: textMuted),
                        ),
                        if (isNarrow) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.folder_outlined, size: 13, color: textMuted),
                              const SizedBox(width: 3),
                              Text('${widget.boardsCount} bảng', style: const TextStyle(fontSize: 11.5, color: textMuted)),
                              const SizedBox(width: 10),
                              const Icon(Icons.check_circle_outline_rounded, size: 13, color: textMuted),
                              const SizedBox(width: 3),
                              Text('${widget.tasksCount} nhiệm vụ', style: const TextStyle(fontSize: 11.5, color: textMuted)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Counts on wide screen
                  if (!isNarrow) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_outlined, size: 15, color: textMuted),
                        const SizedBox(width: 4),
                        Text('${widget.boardsCount} bảng', style: const TextStyle(fontSize: 12, color: textMuted)),
                        const SizedBox(width: 16),
                        const Icon(Icons.check_circle_outline_rounded, size: 15, color: textMuted),
                        const SizedBox(width: 4),
                        Text('${widget.tasksCount} nhiệm vụ', style: const TextStyle(fontSize: 12, color: textMuted)),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Favorite Star
                  IconButton(
                    icon: Icon(
                      widget.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: widget.isFavorite ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: widget.onToggleFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),

                  // Action Menu
                  _buildActionMenu(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarCircle(String emoji, Color bg) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 18, color: textDark),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: borderColor),
      ),
      onSelected: (val) {
        if (val == 'open') widget.onTap();
        if (val == 'settings') widget.onSettings();
        if (val == 'invite') widget.onCopyInvite();
        if (val == 'delete') widget.onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 16, color: primaryPurple),
              SizedBox(width: 8),
              Text('Mở workspace', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'invite',
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 16, color: textMuted),
              SizedBox(width: 8),
              Text('Sao chép mã mời', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 16, color: textMuted),
              SizedBox(width: 8),
              Text('Cài đặt', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Rời / Xóa', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'owner':
        return 'Chủ sở hữu';
      case 'editor':
        return 'Người chỉnh sửa';
      case 'viewer':
        return 'Người xem';
      default:
        return 'Thành viên';
    }
  }
}
