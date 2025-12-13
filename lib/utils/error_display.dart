import 'package:flutter/material.dart';
import '../models/api_error.dart';
import '../ui/widgets/app_toast.dart';

/// Utilities for displaying errors in UI
class ErrorDisplay {
  /// Show error as SnackBar
  static void showSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final message = _getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Show error as Dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    List<Widget>? actions,
  }) async {
    final message = _getErrorMessage(error);
    final errorTitle = title ?? _getErrorTitle(error);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getErrorIcon(error),
                color: _getErrorColor(error),
              ),
              const SizedBox(width: 12),
              Text(errorTitle),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (error is ApiError && error.fieldErrors != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...error.fieldErrors!.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
          actions: actions ?? [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show error with retry option
  static Future<bool> showRetryDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String retryLabel = 'Thử lại',
    String cancelLabel = 'Hủy',
  }) async {
    final message = _getErrorMessage(error);
    final errorTitle = title ?? _getErrorTitle(error);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: _getErrorColor(error),
              ),
              const SizedBox(width: 12),
              Text(errorTitle),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(retryLabel),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Create an error widget for inline display
  static Widget buildErrorWidget(
    dynamic error, {
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    final message = _getErrorMessage(error);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(error),
              size: 64,
              color: _getErrorColor(error).withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(error),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    if (error is ApiError) {
      return error.userMessage;
    }
    if (error is String) {
      return error;
    }
    return error.toString();
  }

  /// Get error title
  static String _getErrorTitle(dynamic error) {
    if (error is ApiError) {
      if (error.isNetworkError || error.isTimeoutError) {
        return 'Lỗi kết nối';
      }
      if (error.isUnauthorized) {
        return 'Chưa xác thực';
      }
      if (error.isForbidden) {
        return 'Không có quyền';
      }
      if (error.isNotFound) {
        return 'Không tìm thấy';
      }
      if (error.isValidationError) {
        return 'Dữ liệu không hợp lệ';
      }
      if (error.isServerError) {
        return 'Lỗi máy chủ';
      }
    }
    return 'Đã xảy ra lỗi';
  }

  /// Get error icon
  static IconData _getErrorIcon(dynamic error) {
    if (error is ApiError) {
      if (error.isNetworkError || error.isTimeoutError) {
        return Icons.wifi_off;
      }
      if (error.isUnauthorized) {
        return Icons.lock_outline;
      }
      if (error.isForbidden) {
        return Icons.block;
      }
      if (error.isNotFound) {
        return Icons.search_off;
      }
      if (error.isValidationError) {
        return Icons.warning_amber;
      }
      if (error.isServerError) {
        return Icons.cloud_off;
      }
    }
    return Icons.error_outline;
  }

  /// Get error color
  static Color _getErrorColor(dynamic error) {
    if (error is ApiError) {
      if (error.isNetworkError || error.isTimeoutError) {
        return Colors.orange;
      }
      if (error.isValidationError) {
        return Colors.amber;
      }
      if (error.isUnauthorized || error.isForbidden) {
        return Colors.red[700]!;
      }
    }
    return Colors.red;
  }
}

/// Error Banner Widget - can be placed at top of screen
class ErrorBanner extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final message = ErrorDisplay._getErrorMessage(error);
    final color = ErrorDisplay._getErrorColor(error);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ErrorDisplay._getErrorIcon(error),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              iconSize: 20,
              color: color,
              onPressed: onRetry,
              tooltip: 'Thử lại',
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: color,
              onPressed: onDismiss,
              tooltip: 'Đóng',
            ),
        ],
      ),
    );
  }
}

/// Extension for easy error display from any widget
extension ErrorDisplayExtension on BuildContext {
  /// Show error as SnackBar
  void showErrorSnackBar(dynamic error, {SnackBarAction? action}) {
    ErrorDisplay.showSnackBar(this, error, action: action);
  }

  /// Show error as Dialog
  Future<void> showErrorDialog(dynamic error, {String? title}) {
    return ErrorDisplay.showErrorDialog(this, error, title: title);
  }

  /// Show error with retry option
  Future<bool> showRetryDialog(dynamic error, {String? title}) {
    return ErrorDisplay.showRetryDialog(this, error, title: title);
  }
  
  /// Show success message
  void showSuccessMessage(String message, {Duration? duration}) {
    AppToast.show(
      this,
      message: message,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show warning message
  void showWarningMessage(String message, {Duration? duration}) {
    AppToast.show(
      this,
      message: message,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show info message
  void showInfoMessage(String message, {Duration? duration}) {
    AppToast.show(
      this,
      message: message,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}

/// Legacy ErrorHandler class for backward compatibility
/// Deprecated: Use ErrorDisplay or context extensions instead
@Deprecated('Use ErrorDisplay or context extensions instead')
class ErrorHandler {
  static void handle(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    bool showToast = true,
    VoidCallback? onRetry,
  }) {
    if (customMessage != null) {
      context.showErrorSnackBar(customMessage);
    } else {
      context.showErrorSnackBar(error);
    }
  }

  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    context.showSuccessMessage(message, duration: duration);
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    context.showWarningMessage(message, duration: duration);
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    context.showInfoMessage(message, duration: duration);
  }

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
      final result = await operation();
      if (showSuccessToast && context.mounted) {
        context.showSuccessMessage(successMessage ?? 'Operation completed successfully');
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(errorMessage ?? e);
      }
      onError?.call();
      return null;
    }
  }

  static bool validateForm(
    BuildContext context,
    GlobalKey<FormState> formKey, {
    String? errorMessage,
  }) {
    if (!formKey.currentState!.validate()) {
      if (errorMessage != null) {
        context.showWarningMessage(errorMessage);
      }
      return false;
    }
    return true;
  }
}
