import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/bottom_nav_bar/custom_bottom_nav_bar.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Renders the navigation bar at the bottom of a page, as the shell does.
Widget host({required int currentIndex, required ValueChanged<int> onTap}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: Builder(
      builder: (context) => Theme(
        data: AppTheme.darkTheme(context),
        child: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the Pix tab shows its label when selected', (tester) async {
    await tester.pumpWidget(host(currentIndex: 2, onTap: (_) {}));

    expect(find.text('Pix'), findsOneWidget);
  });

  testWidgets('the Pix label stays hidden on the other tabs', (tester) async {
    await tester.pumpWidget(host(currentIndex: 0, onTap: (_) {}));

    expect(find.text('Pix'), findsNothing);
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('the Pix label sits in the same row as the other labels', (
    tester,
  ) async {
    // "Menu" has no accent, so the test font draws it with the same line
    // height as "Pix".
    await tester.pumpWidget(host(currentIndex: 4, onTap: (_) {}));
    final menuLabel = tester.getRect(find.text('Menu'));

    await tester.pumpWidget(host(currentIndex: 2, onTap: (_) {}));
    // The new label grows in under the icon. Measure the final row.
    await tester.pumpAndSettle();
    final pixLabel = tester.getRect(find.text('Pix'));

    expect(pixLabel.center.dy, menuLabel.center.dy);
  });

  testWidgets('a long label stays on one line with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(host(currentIndex: 0, onTap: (_) {}));

    expect(tester.takeException(), isNull);
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('a tap on the Pix label opens the Pix tab', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(host(currentIndex: 2, onTap: taps.add));

    await tester.tap(find.text('Pix'));

    expect(taps, [2]);
  });
}
