import 'package:flutter/material.dart';

/// Shared chrome for the signed-in shell (workspace list and workspace pages)
/// so the sidebar, header and search box look identical across routes.
abstract final class AppShellStyle {
  static const Color primary = Color(0xFF6366F1);
  static const Color primarySubtle = Color(0xFFEDE9FE);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  static const double sidebarWidth = 240;
  static const double sidebarCompactWidth = 72;
  static const double headerHeight = 64;
  static const double navItemHeight = 44;
  static const double searchHeight = 40;

  static const BoxDecoration sidebarDecoration = BoxDecoration(
    color: surface,
    border: Border(right: BorderSide(color: divider, width: 1.5)),
  );

  static const BoxDecoration headerDecoration = BoxDecoration(
    color: surface,
    border: Border(bottom: BorderSide(color: divider, width: 1.5)),
  );

  static BoxDecoration get searchDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: border),
  );

  static EdgeInsets headerPadding(double width) =>
      EdgeInsets.only(left: width < 600 ? 12 : 24, right: 12);

  static Widget brand({
    required String tagline,
    required bool compact,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 74,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.diversity_3_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PeerTask',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget navItem({
    required IconData icon,
    required String label,
    required bool active,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: compact ? label : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: divider,
          child: Container(
            height: navItemHeight,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
            decoration: BoxDecoration(
              color: active ? primarySubtle : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: active ? primary : textMuted),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? primary : textBody,
                      ),
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
