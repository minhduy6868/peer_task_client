import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/change_password_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(languageProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with User Profile
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.settings,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.accent.withOpacity(0.05),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                    child: Row(
                      children: [
                        // Avatar with Network Image Support
                        user?.avatar != null && user!.avatar!.isNotEmpty
                            ? Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.elegantCardShadow,
                                  image: DecorationImage(
                                    image: NetworkImage(user.avatar!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.elegantCardShadow,
                                ),
                                child: Center(
                                  child: Text(
                                    user?.name?.substring(0, 1).toUpperCase() ?? 
                                    user?.email.substring(0, 1).toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Settings
                  _ModernSettingsSection(
                    title: l10n.language,
                    icon: Icons.language_rounded,
                    children: [
                      _ModernLanguageTile(
                        title: l10n.english,
                        locale: const Locale('en'),
                        currentLocale: currentLocale,
                        icon: Icons.flag_circle_rounded,
                        onTap: () => ref.read(languageProvider.notifier).setLanguage('en'),
                      ),
                      const Divider(height: 1, indent: 60),
                      _ModernLanguageTile(
                        title: l10n.vietnamese,
                        locale: const Locale('vi'),
                        currentLocale: currentLocale,
                        icon: Icons.flag_circle_rounded,
                        onTap: () => ref.read(languageProvider.notifier).setLanguage('vi'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Account Settings
                  _ModernSettingsSection(
                    title: l10n.profile,
                    icon: Icons.account_circle_rounded,
                    children: [
                      _ModernListTile(
                        leading: Icons.edit_rounded,
                        title: '${l10n.edit} ${l10n.profile}',
                        trailing: Icons.chevron_right_rounded,
                        onTap: () async {
                          await showDialog<bool>(
                            context: context,
                            builder: (context) => const EditProfileDialog(),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      _ModernListTile(
                        leading: Icons.lock_rounded,
                        title: 'Change Password',
                        trailing: Icons.chevron_right_rounded,
                        onTap: () async {
                          await showDialog<bool>(
                            context: context,
                            builder: (context) => const ChangePasswordDialog(),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // App Info
                  _ModernSettingsSection(
                    title: l10n.about,
                    icon: Icons.info_rounded,
                    children: [
                      _ModernListTile(
                        leading: Icons.app_settings_alt_rounded,
                        title: l10n.appTitle,
                        subtitle: 'Version 1.0.0',
                        onTap: null,
                      ),
                      const Divider(height: 1, indent: 60),
                      _ModernListTile(
                        leading: Icons.privacy_tip_rounded,
                        title: 'Privacy Policy',
                        trailing: Icons.chevron_right_rounded,
                        onTap: () {
                          // TODO: Show privacy policy
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      _ModernListTile(
                        leading: Icons.article_rounded,
                        title: 'Terms of Service',
                        trailing: Icons.chevron_right_rounded,
                        onTap: () {
                          // TODO: Show terms
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error,
                          AppColors.error.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(authStateProvider.notifier).logout();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 22),
                      label: Text(
                        l10n.logout,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ModernSettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ModernListTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String? subtitle;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _ModernListTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          leading,
          size: 22,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: trailing != null
          ? Icon(
              trailing,
              color: AppColors.textTertiary,
              size: 20,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _ModernLanguageTile extends StatelessWidget {
  final String title;
  final Locale locale;
  final Locale currentLocale;
  final IconData icon;
  final VoidCallback onTap;

  const _ModernLanguageTile({
    required this.title,
    required this.locale,
    required this.currentLocale,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            )
          : Icon(
              Icons.radio_button_unchecked_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
