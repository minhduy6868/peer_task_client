import 'package:flutter/material.dart';

enum WorkspaceFilterType {
  all,
  mine,
  shared,
  favorite,
}

enum WorkspaceSortOrder {
  newest,
  oldest,
  nameAsc,
}

class WorkspaceFilters extends StatelessWidget {
  final WorkspaceFilterType selectedFilter;
  final ValueChanged<WorkspaceFilterType> onFilterChanged;
  final int allCount;
  final int mineCount;
  final int sharedCount;
  final int favoriteCount;

  final bool isGridView;
  final ValueChanged<bool> onToggleView;

  final WorkspaceSortOrder selectedSort;
  final ValueChanged<WorkspaceSortOrder> onSortChanged;

  const WorkspaceFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.allCount,
    required this.mineCount,
    required this.sharedCount,
    required this.favoriteCount,
    required this.isGridView,
    required this.onToggleView,
    required this.selectedSort,
    required this.onSortChanged,
  });

  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFF1E9DC);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        return Column(
          children: [
            Row(
              children: [
                // Tabs on the left
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab(
                          type: WorkspaceFilterType.all,
                          label: 'Tất cả ($allCount)',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          type: WorkspaceFilterType.mine,
                          label: 'Của tôi ($mineCount)',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          type: WorkspaceFilterType.shared,
                          label: 'Được chia sẻ ($sharedCount)',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          type: WorkspaceFilterType.favorite,
                          label: 'Yêu thích ($favoriteCount)',
                        ),
                      ],
                    ),
                  ),
                ),

                if (!isNarrow) ...[
                  const SizedBox(width: 16),
                  _buildRightControls(),
                ],
              ],
            ),

            if (isNarrow) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRightControls(),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterTab({
    required WorkspaceFilterType type,
    required String label,
  }) {
    final isActive = selectedFilter == type;

    return InkWell(
      onTap: () => onFilterChanged(type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? primaryPurple : borderColor,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryPurple.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildRightControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Toggle Buttons (Grid vs List)
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewButton(
                icon: Icons.grid_view_rounded,
                isActive: isGridView,
                tooltip: 'Dạng lưới',
                onTap: () => onToggleView(true),
              ),
              _buildViewButton(
                icon: Icons.format_list_bulleted_rounded,
                isActive: !isGridView,
                tooltip: 'Dạng danh sách',
                onTap: () => onToggleView(false),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Sort Dropdown
        PopupMenuButton<WorkspaceSortOrder>(
          tooltip: 'Sắp xếp',
          initialValue: selectedSort,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: borderColor),
          ),
          onSelected: onSortChanged,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: WorkspaceSortOrder.newest,
              child: Text('Mới nhất', style: TextStyle(fontSize: 13)),
            ),
            const PopupMenuItem(
              value: WorkspaceSortOrder.oldest,
              child: Text('Cũ nhất', style: TextStyle(fontSize: 13)),
            ),
            const PopupMenuItem(
              value: WorkspaceSortOrder.nameAsc,
              child: Text('Tên (A-Z)', style: TextStyle(fontSize: 13)),
            ),
          ],
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.swap_vert_rounded,
                  size: 18,
                  color: textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  _getSortLabel(selectedSort),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEDE9FE) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? primaryPurple : textMuted,
          ),
        ),
      ),
    );
  }

  String _getSortLabel(WorkspaceSortOrder sort) {
    switch (sort) {
      case WorkspaceSortOrder.newest:
        return 'Mới nhất';
      case WorkspaceSortOrder.oldest:
        return 'Cũ nhất';
      case WorkspaceSortOrder.nameAsc:
        return 'Tên (A-Z)';
    }
  }
}
