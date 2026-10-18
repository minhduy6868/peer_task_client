import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/providers/language_provider.dart';
import 'package:peertask/ui/screens/landing_screen.dart';
import 'package:peertask/ui/theme/app_theme.dart';
import 'package:peertask/ui/widgets/app_language_switcher.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Locale locale) {
    return ProviderScope(
      overrides: [
        languageProvider.overrideWith((ref) => FakeLanguageNotifier(locale)),
      ],
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LandingScreen(),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size, Locale locale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(app(locale));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  void expectNoException(WidgetTester tester, String reason) {
    expect(tester.takeException(), isNull, reason: reason);
  }

  testWidgets('landing lays out on phone and desktop', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const sizes = [Size(320, 640), Size(390, 844), Size(1280, 800), Size(1440, 900)];
    for (final size in sizes) {
      await pumpAt(tester, size, const Locale('en'));
      expect(find.text('The board your team actually finishes'), findsOneWidget);
      expectNoException(tester, '$size');
      await tester.drag(find.byKey(const Key('landing-scroll')), const Offset(0, -700));
      await tester.pump();
      expect(find.text('One place for the work'), findsOneWidget);
      expectNoException(tester, 'scrolled $size');
    }
  });

  testWidgets('landing renders Vietnamese copy', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAt(tester, const Size(320, 640), const Locale('vi'));
    expect(find.text('Làm việc nhóm dễ dàng hơn, cùng nhau hiệu quả hơn'), findsOneWidget);
    expect(find.text('Mọi công việc trong một không gian'), findsOneWidget);
    expectNoException(tester, 'vi');
  });

  testWidgets('feature chips scroll to the feature block', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAt(tester, const Size(1280, 800), const Locale('en'));
    await tester.tap(find.byKey(const Key('landing-chip-0')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Task columns'), findsWidgets);
    expectNoException(tester, 'chip');
  });

  testWidgets('landing renders language switcher in navigation bar and footer', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAt(tester, const Size(1280, 800), const Locale('vi'));
    expect(find.byType(AppLanguageSwitcher), findsWidgets);
    expect(find.text('VI'), findsWidgets);
    expectNoException(tester, 'switcher');
  });
}
