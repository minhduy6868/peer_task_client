import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/ui/theme/app_colors.dart';
import 'package:peertask/l10n/app_localizations.dart';
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

      // Check for errors in authState
      final authState = ref.read(authStateProvider);
      if (authState.error != null && mounted) {
        context.showErrorSnackBar(authState.error!);
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          // Left Side - Decorative Panel (only on wide screens)
          if (isWideScreen)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1a1a2e),
                      const Color(0xFF16213e),
                      const Color(0xFF0f3460),
                      AppColors.primaryDark,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated circles background
                    Positioned(
                      top: -100,
                      left: -100,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -150,
                      right: -100,
                      child: Container(
                        width: 500,
                        height: 500,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accent.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: screenHeight * 0.3,
                      left: 100,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accentPurple.withOpacity(0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                'assets/logo_peer.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.dashboard_customize_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Title
                            Text(
                              _isRegisterMode ? l10n.startYourAdventure : l10n.signInToAdventure,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.collaborativeDescription,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Features
                            _buildFeature(Icons.people_outline, l10n.realTimeCollaboration),
                            const SizedBox(height: 16),
                            _buildFeature(Icons.security_outlined, l10n.secureP2P),
                            const SizedBox(height: 16),
                            _buildFeature(Icons.devices_outlined, l10n.crossPlatform),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Right Side - Form Panel
          Expanded(
            flex: isWideScreen ? 4 : 1,
            child: Container(
              color: Colors.white,
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
                            // Mobile Logo (only show on small screens)
                            if (!isWideScreen) ...[
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
                                    'assets/logo_peer.png',
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
                              SizedBox(height: isTablet ? 32 : 24),
                            ],
                            
                            // Title
                            Text(
                              _isRegisterMode ? l10n.signUpTitle : l10n.signInTitle,
                              style: TextStyle(
                                fontSize: isWideScreen ? 32 : (isTablet ? 30 : 26),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 1,
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
                              style: TextStyle(fontSize: isTablet ? 16 : 15),
                              validator: ValidatorsL10n.email(context),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
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
                            
                            // Divider
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    l10n.orContinueWith,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Social Login Buttons (placeholder)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: null, // Disabled for now
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      foregroundColor: AppColors.textPrimary,
                                      textStyle: const TextStyle(
                                        inherit: true,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    icon: Icon(Icons.g_mobiledata, color: AppColors.textPrimary, size: 24),
                                    label: Text(l10n.google),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: null, // Disabled for now
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      foregroundColor: AppColors.textPrimary,
                                      textStyle: const TextStyle(
                                        inherit: true,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    icon: Icon(Icons.facebook, color: AppColors.textPrimary, size: 20),
                                    label: const Text('Facebook'),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Divider
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
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
                                  'Continue Offline',
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
                            
                            const SizedBox(height: 24),
                            
                            // Toggle Mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
  
  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
