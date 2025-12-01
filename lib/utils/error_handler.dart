import 'package:flutter/material.dart';
import 'package:peertask/ui/widgets/app_toast.dart';
import 'package:peertask/l10n/app_localizations.dart';

class ErrorHandler {
  /// Handle and display errors with localized messages
  static void handle(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    bool showToast = true,
    VoidCallback? onRetry,
  }) {
    final l10n = AppLocalizations.of(context);
    final errorMessage = _getErrorMessage(l10n, error, customMessage);

    if (showToast) {
      AppToast.show(
        context,
        message: errorMessage,
        type: ToastType.error,
        duration: const Duration(seconds: 4),
        actionLabel: onRetry != null ? l10n?.retry : null,
        onAction: onRetry,
      );
    }

    // Log error for debugging
    debugPrint('❌ Error: $error');
    if (error is Error) {
      debugPrint('Stack trace: ${error.stackTrace}');
    }
  }

  /// Get localized error message
  static String _getErrorMessage(
    AppLocalizations? l10n,
    dynamic error,
    String? customMessage,
  ) {
    if (customMessage != null) return customMessage;

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network')) {
      return l10n?.networkError ?? 'Network error. Please check your connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return l10n?.timeoutError ?? 'Request timeout. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('invalid credentials')) {
      return l10n?.invalidCredentials ?? 'Invalid email or password';
    }

    // Permission errors
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return l10n?.permissionDenied ?? 'You don\'t have permission to perform this action';
    }

    // Not found errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return l10n?.notFound ?? 'Resource not found';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('server error')) {
      return l10n?.serverError ?? 'Server error. Please try again later.';
    }

    // Validation errors
    if (errorString.contains('validation')) {
      return l10n?.validationError ?? 'Invalid input. Please check your data.';
    }

    // Connection errors
    if (errorString.contains('connection refused') ||
        errorString.contains('connection reset')) {
      return l10n?.connectionError ?? 'Connection failed. Please try again.';
    }

    // Default error message
    return l10n?.unknownError ?? 'An unexpected error occurred. Please try again.';
  }

  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    AppToast.show(
      context,
      message: message,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show warning message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    AppToast.show(
      context,
      message: message,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    AppToast.show(
      context,
      message: message,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Safe async operation with error handling
  static Future<T?> safeAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = false,
    bool showSuccessToast = false,
    String? successMessage,
    VoidCallback? onError,
  }) async {
    try {
      if (showLoading && context.mounted) {
        // Show loading indicator
      }

      final result = await operation();

      if (showSuccessToast && context.mounted) {
        ErrorHandler.showSuccess(
          context,
          successMessage ?? 'Operation completed successfully',
        );
      }

      return result;
    } catch (e) {
      if (context.mounted) {
        handle(context, e, customMessage: errorMessage);
      }
      onError?.call();
      return null;
    } finally {
      if (showLoading && context.mounted) {
        // Hide loading indicator
      }
    }
  }

  /// Validate form with error display
  static bool validateForm(
    BuildContext context,
    GlobalKey<FormState> formKey, {
    String? errorMessage,
  }) {
    if (!formKey.currentState!.validate()) {
      if (errorMessage != null) {
        showWarning(context, errorMessage);
      }
      return false;
    }
    return true;
  }
}
