import 'package:flutter/material.dart';
import '../../utils/error_handler.dart';
import '../../l10n/app_localizations.dart';

/// Demo screen to test ErrorHandler functionality
class ErrorHandlerDemo extends StatelessWidget {
  const ErrorHandlerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handler Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Toast Types',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () {
                ErrorHandler.showSuccess(
                  context,
                  l10n.taskSavedSuccess,
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Show Success'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: () {
                ErrorHandler.handle(
                  context,
                  Exception('Test error message'),
                  customMessage: l10n.taskSaveError,
                );
              },
              icon: const Icon(Icons.error),
              label: const Text('Show Error'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: () {
                ErrorHandler.showWarning(
                  context,
                  l10n.taskTitleRequired,
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Show Warning'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: () {
                ErrorHandler.showInfo(
                  context,
                  l10n.pleaseWait,
                );
              },
              icon: const Icon(Icons.info),
              label: const Text('Show Info'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Error Types',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {
                ErrorHandler.handle(
                  context,
                  Exception('SocketException: Failed host lookup'),
                );
              },
              child: const Text('Network Error'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                ErrorHandler.handle(
                  context,
                  Exception('TimeoutException: Request timeout'),
                );
              },
              child: const Text('Timeout Error'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                ErrorHandler.handle(
                  context,
                  Exception('401: Unauthorized'),
                );
              },
              child: const Text('Auth Error'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                ErrorHandler.handle(
                  context,
                  Exception('500: Internal server error'),
                );
              },
              child: const Text('Server Error'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                ErrorHandler.handle(
                  context,
                  Exception('Unknown error occurred'),
                );
              },
              child: const Text('Unknown Error'),
            ),
            
            const SizedBox(height: 32),
            Text(
              'With Retry Action',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () {
                ErrorHandler.handle(
                  context,
                  Exception('Network connection failed'),
                  onRetry: () {
                    ErrorHandler.showInfo(context, 'Retrying...');
                  },
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Error with Retry'),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Safe Async Operation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () async {
                await ErrorHandler.safeAsync(
                  context,
                  () async {
                    // Simulate API call
                    await Future.delayed(const Duration(seconds: 1));
                    throw Exception('Network error');
                  },
                  errorMessage: l10n.taskSaveError,
                  showSuccess: false,
                );
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Test Safe Async'),
            ),
          ],
        ),
      ),
    );
  }
}
