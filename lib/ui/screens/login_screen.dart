import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/ui/theme/app_colors.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/utils/apk_download.dart';
import 'package:peertask/utils/error_display.dart';
import 'package:peertask/utils/validators_l10n.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _downloadApk() async {
    final opened = await launchAndroidApkDownload();
    if (!opened && mounted) {
      context.showErrorSnackBar(AppLocalizations.of(context)!.downloadAndroidAppFailed);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final authNotifier = ref.read(authStateProvider.notifier);

    try {
      if (_isRegisterMode) {
        await authNotifier.register(email, password, name.isEmpty ? null : name);
      } else {
        await authNotifier.login(email, password);
      }

      if (!mounted) return;

      // Check for errors in authState
      final authState = ref.read(authStateProvider);
      if (authState.error != null) {
        context.showErrorSnackBar(authState.error!);
      } else if (authState.isAuthenticated) {
        final storage = ref.read(storageServiceProvider);
        final lastWorkspaceId = storage.getLastWorkspace();
        if (lastWorkspaceId != null && lastWorkspaceId.isNotEmpty) {
          context.go('/workspace/$lastWorkspaceId/boards');
        } else {
          context.go('/workspaces');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          // Right Side - Form Panel
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.background,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWideScreen ? 60 : (isTablet ? 40 : 24),
                      vertical: isWideScreen ? 40 : (isTablet ? 32 : 24),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 450 : (isTablet ? 400 : double.infinity),
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                                child: Container(
                                  height: isTablet ? 100 : 80,
                                  width: isTablet ? 100 : 80,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientPrimary,
                                    borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                                    boxShadow: AppColors.elegantCardShadow,
                                  ),
                                  padding: EdgeInsets.all(isTablet ? 22 : 18),
                                  child: Image.asset(
                                    'assets/images/logo_peer.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.dashboard_customize_rounded,
                                        size: isTablet ? 50 : 40,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                            // Title
                            Text(
                              _isRegisterMode ? l10n.signUp : l10n.signIn,
                              style: TextStyle(
                                fontSize: isWideScreen ? 32 : (isTablet ? 30 : 26),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: isTablet ? 10 : 8),
                            Text(
                              _isRegisterMode ? l10n.signUpSubtitle : l10n.signInSubtitle,
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: isWideScreen ? 32 : (isTablet ? 28 : 24)),
                            
                            // Error Message
                            if (authState.error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        authState.error!,
                                        style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: l10n.emailPlaceholder,
                                hintStyle: TextStyle(fontSize: isTablet ? 15 : 14),
                                prefixIcon: Icon(
                                  Icons.email_outlined, 
                                  color: AppColors.textSecondary, 
                                  size: isTablet ? 22 : 20,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF7F8FA),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 22 : 20,
                                  vertical: isTablet ? 20 : 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.error, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.error, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(fontSize: isTablet ? 16 : 15),
                              validator: ValidatorsL10n.email(context),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              textInputAction: _isRegisterMode ? TextInputAction.next : TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_isRegisterMode && !authState.isLoading) {
                                  _submit();
                                }
                              },
                              decoration: InputDecoration(
                                hintText: l10n.passwordPlaceholder,
                                prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF7F8FA),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.error, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.error, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 15),
                              validator: _isRegisterMode 
                                ? ValidatorsL10n.password(context)
                                : ValidatorsL10n.required(context),
                            ),
                            
                            // Name Field (Register mode)
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!authState.isLoading) {
                                    _submit();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: l10n.namePlaceholder,
                                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F8FA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Submit Button
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isRegisterMode ? l10n.signUp : l10n.signIn,
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    l10n.orContinueWith,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: AppColors.border)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Continue Offline Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: authState.isLoading
                                    ? null
                                    : () {
                                        context.go('/offline-username');
                                      },
                                icon: const Icon(Icons.offline_bolt_rounded),
                                label: Text(
                                  l10n.continueOffline,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondary,
                                  side: BorderSide(color: AppColors.secondary, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            
                            if (kIsWeb) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: authState.isLoading ? null : _downloadApk,
                                  icon: const Icon(Icons.android_rounded),
                                  label: Text(
                                    l10n.downloadAndroidApp,
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryDark,
                                    side: const BorderSide(color: AppColors.primaryDark, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            
                            // Toggle Mode
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _isRegisterMode ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isRegisterMode = !_isRegisterMode;
                                            _formKey.currentState?.reset();
                                          });
                                        },
                                  style: TextButton.styleFrom(
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    foregroundColor: AppColors.primary,
                                    disabledForegroundColor: AppColors.textTertiary,
                                  ),
                                  child: Text(_isRegisterMode ? l10n.signIn : l10n.signUp),
                                ),
                              ],
                            ),
                            
                            // Terms (Register mode)
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.byRegistering,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
