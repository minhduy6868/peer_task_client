import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/providers/language_provider.dart';

class DashboardTopBar extends ConsumerWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBrandTap;
  final VoidCallback? onBack;
  final String? title;
  final User? user;

  const DashboardTopBar({
    super.key,
    this.searchController,
    this.onSearch,
    this.onProfileTap,
    this.onBrandTap,
    this.onBack,
    this.title,
    this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(languageProvider);
    final isVietnamese = currentLocale.languageCode == 'vi';

    final userName = user?.name?.isNotEmpty == true
        ? user!.name!
        : (user?.email?.split('@').first ?? '');
    final userInitials = userName.trim().split(' ').map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: Colors.transparent,
      child: Row(
        children: [
          if (onBack != null)
            Tooltip(
              message: l10n.workspaces,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        l10n.workspaces,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ),
          ],
          const Spacer(),

          // Search Box (Pill-shaped, clean modern input matching mockup)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: '${l10n.search}...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Language Selector Dropdown
          PopupMenuButton<String>(
            tooltip: 'Language',
            onSelected: (code) {
              ref.read(languageProvider.notifier).setLanguage(code);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'vi',
                child: Row(
                  children: [
                    const Text('🇻🇳', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Tiếng Việt',
                      style: TextStyle(
                        fontWeight: isVietnamese ? FontWeight.w700 : FontWeight.w500,
                        color: isVietnamese ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇬🇧', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: TextStyle(
                        fontWeight: !isVietnamese ? FontWeight.w700 : FontWeight.w500,
                        color: !isVietnamese ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 17, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    isVietnamese ? 'Tiếng Việt' : 'English',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // (Notification Bell removed according to user's requirement: "Bỏ thông báo: Xóa biểu tượng chuông thông báo ở góc trên bên phải.")

          // User Avatar
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userInitials.isNotEmpty ? userInitials : 'D',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
