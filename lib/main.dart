import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'providers/language_provider.dart';
import 'services/storage_service.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/forgot_password_screen.dart';
import 'ui/screens/reset_password_screen.dart';
import 'ui/screens/workspace_selection_screen.dart';
import 'ui/screens/workspace_home_screen.dart';
import 'ui/screens/board_screen.dart';
import 'ui/screens/offline_username_screen.dart';
import 'ui/screens/offline_boards_screen.dart';
import 'ui/screens/offline_board_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  final storage = StorageService();
  await storage.init();
  
  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final locale = ref.watch(languageProvider);

    // Show loading screen while checking auth
    if (authState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final router = GoRouter(
      initialLocation: _getInitialLocation(ref),
      refreshListenable: _AuthStateNotifier(ref),
      redirect: (context, state) {
        final isAuthenticated = authState.isAuthenticated;
        final path = state.matchedLocation;
        
        // Allow public routes
        if (path == '/login' || 
            path == '/forgot-password' || 
            path.startsWith('/reset-password')) {
          return null;
        }

        // Allow offline routes without auth
        if (path == '/offline-username' ||
            path == '/offline-boards' ||
            path.startsWith('/offline-board/')) {
          return null;
        }

        // Require auth for other routes
        if (!isAuthenticated) {
          return '/login';
        }

        // Redirect root to workspaces or last workspace
        if (path == '/' || path == '/login') {
          final storage = ref.read(storageServiceProvider);
          final lastWorkspaceId = storage.getLastWorkspace();
          if (lastWorkspaceId != null) {
            return '/workspace/$lastWorkspaceId/boards';
          }
          return '/workspaces';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WorkspaceSelectionScreen(),
        ),
        GoRoute(
          path: '/workspaces',
          builder: (context, state) => const WorkspaceSelectionScreen(),
        ),
        GoRoute(
          path: '/workspace/:id/boards',
          builder: (context, state) {
            final workspaceId = state.pathParameters['id']!;
            return WorkspaceHomeScreen(workspaceId: workspaceId);
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            return ResetPasswordScreen(token: token);
          },
        ),
        GoRoute(
          path: '/board/:id',
          builder: (context, state) {
            final boardId = state.pathParameters['id']!;
            return BoardScreen(boardId: boardId);
          },
        ),
        GoRoute(
          path: '/offline-username',
          builder: (context, state) => const OfflineUsernameScreen(),
        ),
        GoRoute(
          path: '/offline-boards',
          builder: (context, state) => const OfflineBoardsScreen(),
        ),
        GoRoute(
          path: '/offline-board/:id',
          builder: (context, state) {
            final boardId = state.pathParameters['id']!;
            return OfflineBoardScreen(boardId: boardId);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'PeerTask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      routerConfig: router,
    );
  }

  String _getInitialLocation(WidgetRef ref) {
    // Always start from login screen
    return '/login';
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  final WidgetRef ref;

  _AuthStateNotifier(this.ref) {
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}
