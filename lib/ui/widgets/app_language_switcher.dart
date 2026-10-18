import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Reusable language switcher button that lets users switch between
/// Vietnamese and English across public and authenticated screens.
class AppLanguageSwitcher extends ConsumerStatefulWidget {
  const AppLanguageSwitcher({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  ConsumerState<AppLanguageSwitcher> createState() => _AppLanguageSwitcherState();
}

class _AppLanguageSwitcherState extends ConsumerState<AppLanguageSwitcher> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);
    final isVi = currentLocale.languageCode == 'vi';
    final l10n = AppLocalizations.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        tooltip: l10n?.language ?? (isVi ? 'Ngôn ngữ' : 'Language'),
        initialValue: currentLocale.languageCode,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        elevation: 6,
        offset: const Offset(0, 40),
        onSelected: (code) {
          if (code != currentLocale.languageCode) {
            ref.read(languageProvider.notifier).setLanguage(code);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'vi',
            height: 42,
            child: Row(
              children: [
                const Text('🇻🇳', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tiếng Việt',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isVi ? FontWeight.w700 : FontWeight.w500,
                      color: isVi ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isVi)
                  const Icon(Icons.check_rounded, size: 18, color: AppColors.primaryDark),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'en',
            height: 42,
            child: Row(
              children: [
                const Text('🇬🇧', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'English',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: !isVi ? FontWeight.w700 : FontWeight.w500,
                      color: !isVi ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!isVi)
                  const Icon(Icons.check_rounded, size: 18, color: AppColors.primaryDark),
              ],
            ),
          ),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceHover : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? AppColors.primaryLight : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isVi ? '🇻🇳' : '🇬🇧', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                isVi ? 'VI' : 'EN',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
