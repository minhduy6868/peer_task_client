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
import '../widgets/auth/auth_card.dart';
import '../widgets/auth/auth_header.dart';
import '../widgets/auth/auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialRegisterMode;

  const LoginScreen({
    super.key,
    this.initialRegisterMode = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late bool _isRegisterMode;
  bool _rememberMe = true;
  bool _agreeToTerms = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegisterMode;
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRegisterMode != widget.initialRegisterMode) {
      setState(() {
        _isRegisterMode = widget.initialRegisterMode;
        _submitted = false;
        _formKey.currentState?.reset();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (_isRegisterMode && !_agreeToTerms) {
      context.showErrorSnackBar(l10n.termsAgreementRequired);
      return;
    }

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

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFFA0AEC0),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF8490A8),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9E5F2), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9E5F2), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }

  Widget _buildTermsCheckbox(AppLocalizations l10n) {
    final text = l10n.termsAgreement;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final term1 = isVi ? 'Điều khoản dịch vụ' : 'Terms of Service';
    final term2 = isVi ? 'Chính sách quyền riêng tư' : 'Privacy Policy';

    final spans = <InlineSpan>[];
    if (text.contains(term1) && text.contains(term2)) {
      final part1 = text.substring(0, text.indexOf(term1));
      final after1 = text.substring(text.indexOf(term1) + term1.length);
      final part2 = after1.substring(0, after1.indexOf(term2));
      final part3 = after1.substring(after1.indexOf(term2) + term2.length);

      spans.add(TextSpan(text: part1, style: const TextStyle(color: Color(0xFF4A5568))));
      spans.add(TextSpan(text: term1, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)));
      spans.add(TextSpan(text: part2, style: const TextStyle(color: Color(0xFF4A5568))));
      spans.add(TextSpan(text: term2, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)));
      if (part3.isNotEmpty) {
        spans.add(TextSpan(text: part3, style: const TextStyle(color: Color(0xFF4A5568))));
      }
    } else {
      spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFF4A5568))));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return AuthLayout(
      child: AuthCard(
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AuthHeader(
                title: _isRegisterMode ? l10n.signUp : l10n.signIn,
                subtitle: _isRegisterMode ? l10n.signUpSubtitle : l10n.signInSubtitle,
              ),
              const SizedBox(height: 24),

              // Server Error Alert Banner
              if (authState.error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2D2140),
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  hintText: l10n.emailPlaceholder,
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                validator: ValidatorsL10n.email(context),
              ),
              const SizedBox(height: 14),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: _isRegisterMode ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_isRegisterMode && !authState.isLoading) {
                    _submit();
                  }
                },
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2D2140),
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  hintText: l10n.password,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF8490A8),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: _isRegisterMode
                    ? ValidatorsL10n.password(context)
                    : ValidatorsL10n.required(context),
              ),

              // Sign Up additional fields
              if (_isRegisterMode) ...[
                const SizedBox(height: 14),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D2140),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: l10n.confirmPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF8490A8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: ValidatorsL10n.confirmPassword(
                    context,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 14),

                // Name Field (optional)
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!authState.isLoading) {
                      _submit();
                    }
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D2140),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: l10n.namePlaceholder,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Terms of Service Agreement Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                        activeColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                        child: _buildTermsCheckbox(l10n),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),

                // Sign In: Remember me + Forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              activeColor: const Color(0xFF7C3AED),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              child: Text(
                                l10n.rememberMe,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2D2140),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              context.push('/forgot-password');
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFF7C3AED),
                      ),
                      child: Text(
                        l10n.forgotPassword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),

              // Primary Action Button (Sign In / Sign Up)
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('auth-submit-button'),
                    onTap: authState.isLoading ? null : _submit,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Divider "Or continue with"
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Color(0xFFE9E5F2), thickness: 1),
                  ),
                  Flexible(
                    flex: 3,
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      l10n.orContinueWith,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8490A8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ),
                  const Expanded(
                    child: Divider(color: Color(0xFFE9E5F2), thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Secondary: Continue Offline
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          context.go('/offline-username');
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                        l10n.continueOffline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2140),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ),

              // Secondary: Download Android App (Web only)
              if (kIsWeb) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _downloadApk,
                    icon: const Icon(
                      Icons.android_rounded,
                      size: 20,
                      color: Color(0xFF7C3AED),
                    ),
                    label: Text(
                      l10n.downloadAndroidApp,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2140),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Footer: Switch Mode (Don't have an account? Sign Up / Already have an account? Sign In)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _isRegisterMode ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8490A8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    key: const Key('auth-toggle-mode-button'),
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              _submitted = false;
                              _formKey.currentState?.reset();
                              _confirmPasswordController.clear();
                            });
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF7C3AED),
                    ),
                    child: Text(
                      _isRegisterMode ? l10n.signIn : l10n.signUp,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
