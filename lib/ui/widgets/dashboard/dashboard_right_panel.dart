import 'package:flutter/material.dart';
import 'package:peertask/l10n/app_localizations.dart';

class DashboardRightPanel extends StatelessWidget {
  final VoidCallback? onViewAllActivities;
  final VoidCallback? onViewAllMembers;

  const DashboardRightPanel({
    super.key,
    this.onViewAllActivities,
    this.onViewAllMembers,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 290,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Section 1: Lịch hôm nay
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF1E293B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.todaySchedule,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Padding(
            padding: EdgeInsets.only(left: 26),
            child: Text(
              'Thứ 3, 10/10/2026',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 14),

          _buildScheduleItem(
            time: '09:00',
            icon: Icons.videocam_outlined,
            title: 'Họp nhóm dự án',
            room: 'Phòng họp 1',
          ),
          const SizedBox(height: 12),
          _buildScheduleItem(
            time: '11:30',
            icon: Icons.code_rounded,
            title: 'Review code',
            room: 'Team Dev',
          ),
          const SizedBox(height: 12),
          _buildScheduleItem(
            time: '15:00',
            icon: Icons.description_outlined,
            title: 'Báo cáo tiến độ',
            room: 'Phòng họp 2',
          ),
          const SizedBox(height: 12),
          _buildScheduleItem(
            time: '17:00',
            icon: Icons.school_outlined,
            title: 'Training công nghệ mới',
            room: 'Online',
          ),

          const SizedBox(height: 28),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          // Section 2: Hoạt động gần đây
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.recentActivity,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onViewAllActivities,
                child: Text(
                  l10n.viewAll,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildActivityItem(
            initial: 'N',
            avatarBg: const Color(0xFFE0F2FE),
            avatarFg: const Color(0xFF0284C7),
            userName: 'Nguyễn Văn',
            action: 'đã hoàn thành',
            target: 'Tạo API sản phẩm',
            time: '2 giờ trước',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            initial: 'T',
            avatarBg: const Color(0xFFDCFCE7),
            avatarFg: const Color(0xFF16A34A),
            userName: 'Trần Thị',
            action: 'đã thêm một công việc',
            target: 'Sửa lỗi hiển thị giỏ hàng',
            time: '3 giờ trước',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            initial: 'M',
            avatarBg: const Color(0xFFEDE9FE),
            avatarFg: const Color(0xFF7C3AED),
            userName: 'Meo Meo',
            action: 'đã cập nhật bảng',
            target: 'Web Bán Hàng E-commerce',
            time: '5 giờ trước',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            initial: 'L',
            avatarBg: const Color(0xFFF3E8FF),
            avatarFg: const Color(0xFF9333EA),
            userName: 'Lê Minh',
            action: 'đã hoàn thành',
            target: 'Thiết kế database',
            time: '1 ngày trước',
          ),

          const SizedBox(height: 28),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          // Section 3: Thành viên dự án
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 18, color: Color(0xFF1E293B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.projectMembers,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onViewAllMembers,
                child: Text(
                  l10n.viewAll,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildMemberItem(
            initial: 'N',
            avatarBg: const Color(0xFFE0F2FE),
            avatarFg: const Color(0xFF0284C7),
            name: 'Hoàng Nam (Bạn)',
            role: 'Front-end Developer',
            isOnline: true,
          ),
          const SizedBox(height: 12),
          _buildMemberItem(
            initial: 'N',
            avatarBg: const Color(0xFFE0F2FE),
            avatarFg: const Color(0xFF0284C7),
            name: 'Nguyễn Văn',
            role: 'Back-end Developer',
            isOnline: true,
          ),
          const SizedBox(height: 12),
          _buildMemberItem(
            initial: 'T',
            avatarBg: const Color(0xFFFEE2E2),
            avatarFg: const Color(0xFFDC2626),
            name: 'Trần Thị',
            role: 'UI/UX Designer',
            isOnline: true,
          ),
          const SizedBox(height: 12),
          _buildMemberItem(
            initial: 'L',
            avatarBg: const Color(0xFFF3E8FF),
            avatarFg: const Color(0xFF9333EA),
            name: 'Lê Minh',
            role: 'Tester',
            isOnline: false,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required IconData icon,
    required String title,
    required String room,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                room,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String initial,
    required Color avatarBg,
    required Color avatarFg,
    required String userName,
    required String action,
    required String target,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: avatarFg,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                  children: [
                    TextSpan(
                      text: '$userName ',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    TextSpan(text: '$action '),
                    TextSpan(
                      text: '"$target"',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem({
    required String initial,
    required Color avatarBg,
    required Color avatarFg,
    required String name,
    required String role,
    required bool isOnline,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: avatarFg,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
