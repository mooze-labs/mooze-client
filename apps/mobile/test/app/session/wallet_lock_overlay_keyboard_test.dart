import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/app/session/widgets/privacy_shield_overlay.dart';
import 'package:mooze_mobile/app/session/widgets/wallet_lock_overlay.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  /// A screen with a text field, under the global cover, as in the app: the
  /// cover sits above the screen and the screen stays mounted.
  Widget host({required bool showCover, required FocusNode field}) {
    return MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Theme(
        data: AppTheme.darkTheme(context),
        child: Stack(
          children: [
            child!,
            WalletLockOverlay(
              showCover: showCover,
              showAuthentication: false,
              onAuthenticated: () {},
            ),
          ],
        ),
      ),
      home: Scaffold(body: TextField(focusNode: field)),
    );
  }

  // The keyboard is a system window above the app, so the cover cannot
  // paint over it. While a field of the screen below keeps the focus, the
  // keyboard stays open over the cover and opens again when the app
  // returns.
  testWidgets('the cover closes the keyboard of the screen below', (
    tester,
  ) async {
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(host(showCover: false, field: field));
    await tester.showKeyboard(find.byType(TextField));
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(host(showCover: true, field: field));
    await tester.pump();

    expect(find.byType(PrivacyShieldOverlay), findsOneWidget);
    expect(field.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('without the cover, the keyboard stays as the screen left it', (
    tester,
  ) async {
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(host(showCover: false, field: field));
    await tester.showKeyboard(find.byType(TextField));

    await tester.pumpWidget(host(showCover: false, field: field));
    await tester.pump();

    expect(field.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
