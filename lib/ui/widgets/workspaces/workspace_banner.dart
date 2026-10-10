import 'package:flutter/material.dart';

class WorkspaceBanner extends StatelessWidget {
  final VoidCallback onCreateWorkspace;
  final VoidCallback onShowGuide;

  const WorkspaceBanner({
    super.key,
    required this.onCreateWorkspace,
    required this.onShowGuide,
  });

  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 550;
        final isNarrow = constraints.maxWidth < 820;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEDE9FE), // Soft Lavender
                Color(0xFFF3E8FF), // Light Violet
                Color(0xFFFDFBF7), // Warm tone fade
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFE9D5FF).withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background subtle ambient shapes
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : (isNarrow ? 22 : 32),
                    vertical: isMobile ? 20 : (isNarrow ? 24 : 28),
                  ),
                  child: Row(
                    children: [
                      // Left copy & CTA
                      Expanded(
                        flex: isNarrow ? 1 : 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tạo workspace mới để bắt đầu',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Text(
                                'Sắp xếp công việc, cộng tác cùng nhóm và theo dõi tiến độ dễ dàng hơn.',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: onCreateWorkspace,
                                  icon: const Icon(Icons.add_rounded, size: 17),
                                  label: const Text(
                                    'Tạo workspace',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryPurple,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 16 : 20,
                                      vertical: isMobile ? 12 : 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: onShowGuide,
                                  icon: const Icon(Icons.menu_book_rounded, size: 17),
                                  label: const Text(
                                    'Xem hướng dẫn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textDark,
                                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 16 : 20,
                                      vertical: isMobile ? 12 : 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right Illustration Graphic (Visible on Desktop / Wide Tablet)
                      if (!isNarrow) ...[
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 9,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildTeamworkGraphic(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Composite Teamwork Illustration matching the visual in the reference
  Widget _buildTeamworkGraphic() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 150),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background floating card (Kanban preview)
          Positioned(
            right: 12,
            bottom: 10,
            child: Container(
              width: 195,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: primaryPurple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 7,
                              width: 55,
                              decoration: BoxDecoration(
                                color: textDark.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 5,
                              width: 80,
                              decoration: BoxDecoration(
                                color: textMuted.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 11, color: Color(0xFF16A34A)),
                            SizedBox(width: 3),
                            Text('Done', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '100%',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Team Avatars & Collaboration Cluster
          Positioned(
            left: 10,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 62,
                    height: 24,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          child: _avatarBubble('👩‍💻', const Color(0xFFFCE7F3)),
                        ),
                        Positioned(
                          left: 18,
                          child: _avatarBubble('👨‍💼', const Color(0xFFEDE9FE)),
                        ),
                        Positioned(
                          left: 36,
                          child: _avatarBubble('👩‍🔬', const Color(0xFFFEF3C7)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'P2P Sync',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating checkmark badge
          Positioned(
            right: 32,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primaryPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarBubble(String emoji, Color bg) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
