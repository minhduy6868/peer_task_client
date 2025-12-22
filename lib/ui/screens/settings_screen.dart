import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../services/cloudinary_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/change_password_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      try {
        // Read image as bytes
        final bytes = await image.readAsBytes();
        final fileName = image.name;

        // 1. Upload to Cloudinary first
        final cloudinary = CloudinaryService();
        final avatarUrl = await cloudinary.uploadImage(
          imageBytes: bytes,
          fileName: fileName,
          folder: 'avatars',
        );

        print('✅ Avatar uploaded to Cloudinary: $avatarUrl');

        // 2. Update profile with Cloudinary URL
        final api = ref.read(apiServiceProvider);
        await api.updateProfile(
          name: ref.read(authStateProvider).user?.name,
          avatar: avatarUrl,
        );

        // 3. Refresh user data
        final response = await api.getCurrentUser();
        print('🔄 User data after avatar upload: $response');
        ref.read(authStateProvider.notifier).updateUser(response);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Avatar updated successfully'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Failed to upload avatar: $e'),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to pick image: $e'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Widget _buildAvatarImage(String avatar) {
    // Load directly from Cloudinary URL
    return Image.network(
      avatar,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
    );
  }

  Widget _buildFallbackAvatar() {
    final user = ref.read(authStateProvider).user;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user?.name?.substring(0, 1).toUpperCase() ?? 
          user?.email.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(languageProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Beautiful Header with Avatar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                          AppColors.accent,
                        ],
                      ),
                    ),
                  ),
                  // Decorative Circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Profile Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar with Edit Button
                          Stack(
                            children: [
                              Hero(
                                tag: 'user-avatar',
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: user?.avatar != null && user!.avatar!.isNotEmpty
                                      ? ClipOval(
                                          child: _buildAvatarImage(user.avatar!),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.9),
                                                Colors.white.withOpacity(0.7),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              user?.name?.substring(0, 1).toUpperCase() ?? 
                                              user?.email.substring(0, 1).toUpperCase() ?? 'U',
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              // Camera Button
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: _isUploadingAvatar
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : Icon(
                                            Icons.camera_alt_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Email
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            inherit: true,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  inherit: true,
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
      ),
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
