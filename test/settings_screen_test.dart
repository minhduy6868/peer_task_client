import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/providers/language_provider.dart';
import 'package:peertask/services/api_service.dart';
import 'package:peertask/services/storage_service.dart';
import 'package:peertask/ui/dialogs/edit_profile_dialog.dart';
import 'package:peertask/ui/screens/settings_screen.dart';
import 'package:peertask/ui/theme/app_theme.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(super.ref, User user) {
    state = AuthState(user: user, accessToken: 'dummy-token');
  }
}

class FakeLanguageNotifier extends StateNotifier<Locale> implements LanguageNotifier {
  FakeLanguageNotifier(super.initial);

  @override
  Future<void> setLanguage(String code) async {
    state = Locale(code);
  }

  @override
  void toggleLanguage() {
    state = Locale(state.languageCode == 'en' ? 'vi' : 'en');
  }
}

class FakeStorageService extends Fake implements StorageService {
  @override
  String? getAuthToken() => 'dummy-token';
  @override
  Map<String, dynamic>? getUser() => {
        'id': 'user-123',
        'email': 'alex@example.com',
        'name': 'Alex Rivera',
      };
  @override
  Future<void> saveUser(Map<String, dynamic> user) async {}
}

class FakeApiService extends Fake implements ApiService {
  @override
  String? get accessToken => 'dummy-token';
  @override
  String? get refreshToken => null;
  @override
  Future<void> loadTokens() async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    return {'id': 'user-123', 'email': 'alex@example.com', 'name': 'Alex Rivera'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = User(
    id: 'user-123',
    email: 'alex@example.com',
    name: 'Alex Rivera',
    avatar: null,
  );

  Widget createTestWidget({required Widget child, Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(FakeStorageService()),
        apiServiceProvider.overrideWithValue(FakeApiService()),
        authStateProvider.overrideWith((ref) => MockAuthNotifier(ref, testUser)),
        languageProvider.overrideWith((ref) => FakeLanguageNotifier(locale)),
      ],
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('SettingsScreen lays out on 320px phone without overflow in EN and VI', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in [const Locale('en'), const Locale('vi')]) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(createTestWidget(child: const SettingsScreen(), locale: locale));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final err = tester.takeException();
      expect(err, isNull, reason: 'Overflow or error in locale $locale: $err');
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
    }
  });

  testWidgets('EditProfileDialog displays properly without overflow', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in [const Locale('en'), const Locale('vi')]) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: Center(
              child: EditProfileDialog(),
            ),
          ),
          locale: locale,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final err = tester.takeException();
      expect(err, isNull, reason: 'Overflow or error in dialog locale $locale: $err');
      expect(find.byType(EditProfileDialog), findsOneWidget);
    }
  });
}
