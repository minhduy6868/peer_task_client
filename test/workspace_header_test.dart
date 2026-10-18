import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/providers/language_provider.dart';
import 'package:peertask/ui/widgets/dashboard/dashboard_top_bar.dart';
import 'package:peertask/ui/widgets/workspaces/workspace_header.dart';

class _FakeLanguageNotifier extends StateNotifier<Locale>
    implements LanguageNotifier {
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
  testWidgets('WorkspaceHeader fits phones and exposes logout', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    var loggedOut = false;

    for (final locale in const [Locale('en'), Locale('vi')]) {
      for (final size in const [
        Size(320, 640),
        Size(390, 844),
        Size(1280, 800),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              languageProvider.overrideWith(
                (ref) => _FakeLanguageNotifier(locale),
              ),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: WorkspaceHeader(
                  searchController: TextEditingController(),
                  onSearchChanged: (_) {},
                  user: const User(
                    id: 'u1',
                    email: 'an.nguyen@example.com',
                    name: 'An Nguyen',
                  ),
                  onOpenSettings: () {},
                  onLogout: () => loggedOut = true,
                  onOpenMobileDrawer: size.width < 960 ? () {} : null,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$locale $size');

        final language = tester.getRect(find.byType(ShellLanguageMenu));
        final account = tester.getRect(find.byType(ShellAccountMenu));
        expect(language.overlaps(account), isFalse, reason: '$locale $size');
        expect(
          account.right,
          lessThanOrEqualTo(size.width),
          reason: '$locale $size',
        );
      }
    }

    await tester.tap(find.byType(ShellAccountMenu));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'account menu');
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });
}
