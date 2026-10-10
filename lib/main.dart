import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'providers/language_provider.dart';
import 'services/storage_service.dart';
import 'services/config_service.dart';
import 'ui/screens/landing_screen.dart';
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
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize storage
  final storage = StorageService();
  await storage.init();
  
  // Initialize config service (sẽ load URL từ Firebase)
  final configService = ConfigService();
  await configService.init();
  
  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        configServiceProvider.overrideWithValue(configService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  GoRouter? _router;

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final locale = ref.watch(languageProvider);

    // Only the first boot replaces the app. Login also sets isLoading, and
    // swapping the router then keeps the old redirect, so a successful
    // login stays on this page until a full reload.
    if (_router == null && authState.isLoading) {
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

    _router ??= GoRouter(
      initialLocation: _getInitialLocation(ref),
      overridePlatformDefaultLocation: _browserLocation() != null,
      refreshListenable: _AuthStateNotifier(ref),
      redirect: (context, state) {
        final current = ref.read(authStateProvider);
        if (current.isLoading) return null;
        final isAuthenticated = current.isAuthenticated;
        final path = state.matchedLocation;
        
        // If authenticated and on login page, redirect to workspaces
        if (isAuthenticated && (path == '/login' || path == '/')) {
          final storage = ref.read(storageServiceProvider);
          final lastWorkspaceId = storage.getLastWorkspace();
          if (lastWorkspaceId != null) {
            return '/workspace/$lastWorkspaceId/boards';
          }
          return '/workspaces';
        }

        if (path == '/' ||
            path == '/login' ||
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

        // Allow workspace and board routes for authenticated users
        if (isAuthenticated && 
            (path.startsWith('/workspace/') || 
             path.startsWith('/board/') ||
             path == '/workspaces')) {
          return null;
        }

        // Require auth for other routes
        if (!isAuthenticated) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
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
      routerConfig: _router!,
    );
  }

  String? _browserLocation() {
    if (!kIsWeb) return null;
    final fragment = Uri.base.fragment;
    if (fragment.isEmpty || fragment == '/') return null;
    return fragment.startsWith('/') ? fragment : '/$fragment';
  }

  String _getInitialLocation(WidgetRef ref) {
    final browser = _browserLocation();
    if (browser != null) return browser;
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      final storage = ref.read(storageServiceProvider);
      final lastWorkspaceId = storage.getLastWorkspace();
      if (lastWorkspaceId != null) {
        return '/workspace/$lastWorkspaceId/boards';
      }
      return '/workspaces';
    }
    return '/';
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
