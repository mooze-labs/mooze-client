import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/bottom_nav_bar/custom_bottom_nav_bar.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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

  group('the Pix mark', () {
    Finder mark() => find.byWidgetPredicate(
      (w) =>
          w is SvgPicture &&
          w.bytesLoader is SvgAssetLoader &&
          (w.bytesLoader as SvgAssetLoader).assetName ==
              'assets/icons/menu/navigation/pix.svg',
    );

    /// How much of the brand orb around the mark shows.
    double orb(WidgetTester tester) => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).shape == BoxShape.circle,
                ),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    ColorFilter? markColor(WidgetTester tester) =>
        tester.widget<SvgPicture>(mark()).colorFilter;

    Color brand(WidgetTester tester) =>
        tester.element(mark()).colors.primaryColor;

    testWidgets('sits white in the brand orb off its tab', (tester) async {
      await tester.pumpWidget(host(currentIndex: 0, onTap: (_) {}));
      await tester.pumpAndSettle();

      expect(orb(tester), 1);
      expect(
        markColor(tester),
        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    });

    testWidgets('on its tab, stays alone in the brand color, clear of the '
        'edge of the lens: the orb shrinks and fades', (tester) async {
      await tester.pumpWidget(host(currentIndex: 0, onTap: (_) {}));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(currentIndex: 2, onTap: (_) {}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(orb(tester), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(orb(tester), 0);
      expect(
        markColor(tester),
        ColorFilter.mode(brand(tester), BlendMode.srcIn),
      );
      final lens = tester.getRect(find.byType(GlassLens));
      final pix = tester.getRect(mark());
      expect(pix.top - lens.top, greaterThanOrEqualTo(4));
      expect(lens.contains(pix.center), isTrue);
    });

    testWidgets('with reduced motion, the orb goes at once', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(host(currentIndex: 0, onTap: (_) {}));
      await tester.pumpWidget(host(currentIndex: 2, onTap: (_) {}));
      await tester.pump();

      expect(orb(tester), 0);
    });
  });

  testWidgets('a tap on the Pix label opens the Pix tab', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(host(currentIndex: 2, onTap: taps.add));

    await tester.tap(find.text('Pix'));

    expect(taps, [2]);
  });
}
