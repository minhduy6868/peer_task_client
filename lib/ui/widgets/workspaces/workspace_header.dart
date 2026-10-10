import 'package:flutter/material.dart';
import '../../../models/user/user.dart';

class WorkspaceHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final User? user;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMobileDrawer;

  const WorkspaceHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.user,
    required this.onOpenNotifications,
    required this.onOpenSettings,
    required this.onLogout,
    this.onOpenMobileDrawer,
  });

  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFF1E9DC);
  static const Color inputBg = Color(0xFFFBF8F3);

  @override
  Widget build(BuildContext context) {
    final displayName = (user?.name?.trim().isNotEmpty == true)
        ? user!.name!.trim()
        : (user?.email.split('@').first.isNotEmpty == true
            ? user!.email.split('@').first
            : 'Thắm');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isSmall = constraints.maxWidth < 420;

        return Container(
          height: 68,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Mobile Drawer Hamburger Button
              if (onOpenMobileDrawer != null) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: textDark),
                  onPressed: onOpenMobileDrawer,
                  tooltip: 'Menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 6),
              ],

              // Search Field
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: const TextStyle(fontSize: 13, color: textDark),
                        decoration: InputDecoration(
                          hintText: isSmall ? 'Tìm kiếm...' : 'Tìm workspace, bảng, nhiệm vụ...',
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: textMuted,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: textMuted),
                                  onPressed: () {
                                    searchController.clear();
                                    onSearchChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Notifications Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onOpenNotifications,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: textDark,
                      size: 21,
                    ),
                    tooltip: 'Thông báo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    hoverColor: const Color(0xFFF3E8FF),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              // User Profile Dropdown
              PopupMenuButton<String>(
                tooltip: 'Tài khoản',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: borderColor),
                ),
                onSelected: (value) {
                  if (value == 'settings') {
                    onOpenSettings();
                  } else if (value == 'logout') {
                    onLogout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textDark,
                          ),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 18, color: textMuted),
                        SizedBox(width: 10),
                        Text('Cài đặt tài khoản', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),
                ],
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFEDE9FE),
                          backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                          child: user?.avatar == null
                              ? Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                        // Only show name and chevron on tablet/desktop
                        if (!isMobile) ...[
                          const SizedBox(width: 7),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: textMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
