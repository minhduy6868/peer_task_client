import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/providers/language_provider.dart';
import '../app_shell_style.dart';
import '../user_avatar.dart';

class DashboardTopBar extends StatelessWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;
  final VoidCallback? onBrandTap;
  final VoidCallback? onBack;
  final String? title;
  final User? user;

  const DashboardTopBar({
    super.key,
    this.searchController,
    this.onSearch,
    this.onProfileTap,
    this.onLogout,
    this.onBrandTap,
    this.onBack,
    this.title,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      height: AppShellStyle.headerHeight,
      padding: AppShellStyle.headerPadding(width),
      decoration: AppShellStyle.headerDecoration,
      child: Row(
        children: [
          if (onBack != null)
            Tooltip(
              message: l10n.workspaces,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: AppShellStyle.searchHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: AppShellStyle.searchDecoration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: AppShellStyle.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.workspaces,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppShellStyle.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null && title!.isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppShellStyle.textDark,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (searchController != null)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: ShellSearchField(
                        controller: searchController!,
                        onChanged: onSearch,
                        hintText: '${l10n.search}...',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const ShellLanguageMenu(),
          const SizedBox(width: 14),
          if (onLogout != null)
            ShellAccountMenu(
              user: user,
              onOpenSettings: onProfileTap ?? () {},
              onLogout: onLogout!,
            )
          else
            ShellAvatar(user: user, onTap: onProfileTap),
        ],
      ),
    );
  }
}

class ShellSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const ShellSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        height: AppShellStyle.searchHeight,
        decoration: AppShellStyle.searchDecoration,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppShellStyle.textDark),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppShellStyle.textHint,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 19,
              color: AppShellStyle.textHint,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class ShellLanguageMenu extends ConsumerWidget {
  const ShellLanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVietnamese = ref.watch(languageProvider).languageCode == 'vi';
    final compact = MediaQuery.sizeOf(context).width < 600;

    PopupMenuItem<String> item(String code, String flag, String label) {
      final selected = (code == 'vi') == isVietnamese;
      return PopupMenuItem(
        value: code,
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppShellStyle.primary
                    : AppShellStyle.textDark,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Language',
      onSelected: (code) =>
          ref.read(languageProvider.notifier).setLanguage(code),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        item('vi', '🇻🇳', 'Tiếng Việt'),
        item('en', '🇬🇧', 'English'),
      ],
      child: Container(
        height: AppShellStyle.searchHeight,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        decoration: AppShellStyle.searchDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 17,
              color: AppShellStyle.textMuted,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                isVietnamese ? 'Tiếng Việt' : 'English',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppShellStyle.textBody,
                ),
              ),
            ],
            if (compact) ...[
              const SizedBox(width: 4),
              Text(
                isVietnamese ? 'VI' : 'EN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppShellStyle.textBody,
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppShellStyle.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShellAvatar extends StatelessWidget {
  final User? user;
  final VoidCallback? onTap;

  const ShellAvatar({super.key, this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : (user?.email ?? '');

    final circle = UserAvatar(
      name: name,
      imageUrl: user?.avatar,
      size: 38,
      fontSize: 14,
      gradient: const LinearGradient(
        colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppShellStyle.primary.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    if (onTap == null) return circle;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: circle,
    );
  }
}

/// Avatar button opening a menu with the user's identity, settings and logout.
class ShellAccountMenu extends StatelessWidget {
  final User? user;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  const ShellAccountMenu({
    super.key,
    this.user,
    required this.onOpenSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.accountAndSettings,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'settings') onOpenSettings();
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        if (user != null) ...[
          PopupMenuItem(
            enabled: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user!.name?.trim().isNotEmpty == true)
                    Text(
                      user!.name!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppShellStyle.textDark,
                      ),
                    ),
                  Text(
                    user!.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppShellStyle.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                size: 18,
                color: AppShellStyle.textMuted,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.accountAndSettings,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.logout,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: ShellAvatar(user: user),
    );
  }
}
