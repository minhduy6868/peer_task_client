import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../utils/error_display.dart';
import '../../utils/validators_l10n.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.forgotPassword(email: _emailController.text.trim());
      
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _emailSent ? _buildSuccessView(l10n) : _buildFormView(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.createNewPassword,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.resetEmailHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.email,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: ValidatorsL10n.email(context),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.sendResetLink),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.backToLogin),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(AppLocalizations l10n) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.emailSent,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.resetEmailSent,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backToLogin),
        ),
      ],
    );
  }
}
