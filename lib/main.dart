import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_providers.dart';
import 'providers/language_provider.dart';
import 'services/storage_service.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/forgot_password_screen.dart';
import 'ui/screens/reset_password_screen.dart';
import 'ui/screens/workspaces_screen.dart';
import 'ui/screens/boards_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/hybrid_board_screen.dart';

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

    final router = GoRouter(
      refreshListenable: _AuthStateNotifier(ref),
      redirect: (context, state) {
        final isAuthenticated = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        if (isAuthenticated && isLoggingIn) {
          return '/workspaces';
        }

        return null;
      },
      routes: [
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
          path: '/workspaces',
          builder: (context, state) => const WorkspacesScreen(),
        ),
        GoRoute(
          path: '/workspace/:id/boards',
          builder: (context, state) {
            final workspaceId = state.pathParameters['id']!;
            return BoardsScreen(workspaceId: workspaceId);
          },
        ),
        GoRoute(
          path: '/board/:id',
          builder: (context, state) {
            final boardId = state.pathParameters['id']!;
            return HybridBoardScreen(boardId: boardId);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      initialLocation: authState.isAuthenticated ? '/workspaces' : '/login',
    );

    return MaterialApp.router(
      title: 'PeerTask',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      locale: locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    );
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
