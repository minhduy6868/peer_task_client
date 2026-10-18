import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/providers/language_provider.dart';
import 'package:peertask/ui/screens/login_screen.dart';
import 'package:peertask/ui/theme/app_theme.dart';

class _FakeLanguageNotifier extends StateNotifier<Locale> implements LanguageNotifier {
  _FakeLanguageNotifier(super.initial);

  @override
  Future<void> setLanguage(String code) async {
    state = Locale(code);
  }

  @override
  void toggleLanguage() {
    state = Locale(state.languageCode == 'en' ? 'vi' : 'en');
  }
}

void main() {
  Widget buildSubject({Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        languageProvider.overrideWith((ref) => _FakeLanguageNotifier(locale)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders Sign In mode correctly', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Verify Title & Subtitle
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Welcome back! Please sign in to continue'), findsOneWidget);

    // Verify fields
    expect(find.text('Your email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Remember me & Forgot Password
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);

    // Verify Secondary actions
    expect(find.text('Continue offline'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
  });

  testWidgets('LoginScreen toggles between Sign In and Sign Up mode', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Tap footer Sign Up button to switch to Register mode
    final signUpButton = find.byKey(const Key('auth-toggle-mode-button'));
    expect(signUpButton, findsOneWidget);
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    // Now in Register mode
    expect(find.text('Create your account to get started'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Your Name (optional)'), findsOneWidget);
    expect(find.text('I agree to the Terms of Service and Privacy Policy'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);

    // Tap footer Sign In button to switch back
    final signInButton = find.byKey(const Key('auth-toggle-mode-button'));
    expect(signInButton, findsOneWidget);
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    // Back to Sign In mode
    expect(find.text('Welcome back! Please sign in to continue'), findsOneWidget);
    expect(find.text('Confirm Password'), findsNothing);
  });

  testWidgets('LoginScreen validates email and password fields', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Tap Sign In button without entering credentials
    final primaryButton = find.byKey(const Key('auth-submit-button'));
    expect(primaryButton, findsOneWidget);
    await tester.ensureVisible(primaryButton);
    await tester.tap(primaryButton);
    await tester.pumpAndSettle();

    // Validation errors should appear
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('Typing email does not trigger premature password error before submit', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Type in email field
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'vv');
    await tester.pump();

    // Password error should NOT be visible
    expect(find.text('This field is required'), findsNothing);
    expect(find.text('Password is required'), findsNothing);
  });
}
