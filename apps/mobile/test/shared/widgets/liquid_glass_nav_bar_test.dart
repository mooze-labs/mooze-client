import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/bottom_nav_bar/custom_bottom_nav_bar.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import 'motion/motion_test_helpers.dart';

/// Renders the bar as the shell does, over a tappable page.
Widget _host({
  required int currentIndex,
  ValueChanged<int>? onTap,
  ValueNotifier<double>? pagePosition,
  VoidCallback? onPageTap,
  Brightness brightness = Brightness.dark,
}) {
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
        data: brightness == Brightness.dark
            ? AppTheme.darkTheme(context)
            : AppTheme.lightTheme(context),
        child: Scaffold(
          extendBody: true,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPageTap,
            child: const SizedBox.expand(),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
            pagePosition: pagePosition,
          ),
        ),
      ),
    ),
  );
}

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Rect _capsule(WidgetTester tester) => tester.getRect(find.byType(LiquidGlass));

/// Center of tab [index] inside the capsule.
double _slotCenter(WidgetTester tester, int index) {
  final capsule = _capsule(tester);
  final inner = capsule.width - CustomBottomNavBar.inset * 2;
  final slot = inner / 5;
  return capsule.left + CustomBottomNavBar.inset + (index + 0.5) * slot;
}

Rect _lens(WidgetTester tester) => tester.getRect(find.byType(GlassLens));

void main() {
  group('Floating capsule', () {
    testWidgets('floats above the bottom edge with side margins', (
      tester,
    ) async {
      _screen(tester, const Size(393, 852));
      await tester.pumpWidget(_host(currentIndex: 0));

      final capsule = _capsule(tester);
      expect(capsule.height, CustomBottomNavBar.capsuleHeight);
      expect(capsule.left, CustomBottomNavBar.sideMargin);
      expect(capsule.right, 393 - CustomBottomNavBar.sideMargin);
      expect(capsule.bottom, lessThan(852));
    });

    testWidgets('keeps a readable width on tablets', (tester) async {
      _screen(tester, const Size(1024, 1366));
      await tester.pumpWidget(_host(currentIndex: 0));

      final capsule = _capsule(tester);
      expect(capsule.width, CustomBottomNavBar.maxCapsuleWidth);
      expect(capsule.center.dx, 512);
    });

    testWidgets('blurs the content behind it', (tester) async {
      await tester.pumpWidget(_host(currentIndex: 0));

      expect(
        find.descendant(
          of: find.byType(LiquidGlass),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('taps beside the capsule reach the page', (tester) async {
      _screen(tester, const Size(393, 852));
      final tabs = <int>[];
      var pageTaps = 0;
      await tester.pumpWidget(
        _host(currentIndex: 0, onTap: tabs.add, onPageTap: () => pageTaps++),
      );

      final capsule = _capsule(tester);
      // In the side margin, at the height of the capsule.
      await tester.tapAt(Offset(4, capsule.center.dy));

      expect(pageTaps, 1);
      expect(tabs, isEmpty);
    });

    testWidgets('fits a 320 pt screen at 200% text', (tester) async {
      _screen(tester, const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_host(currentIndex: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the light glass', (tester) async {
      await tester.pumpWidget(
        _host(currentIndex: 0, brightness: Brightness.light),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GlassLens), findsOneWidget);
    });
  });

  group('Selected lens', () {
    testWidgets('slides to a tapped tab and stretches on the way', (
      tester,
    ) async {
      await tester.pumpWidget(_host(currentIndex: 0));
      final restWidth = _lens(tester).width;
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 0), 0.5));

      await tester.pumpWidget(_host(currentIndex: 3));
      await tester.pump(Motion.durationSlow ~/ 2);

      final moving = _lens(tester);
      expect(
        moving.center.dx,
        inExclusiveRange(_slotCenter(tester, 0), _slotCenter(tester, 3)),
      );
      expect(moving.width, greaterThan(restWidth));

      await tester.pumpAndSettle();
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 3), 0.5));
      expect(_lens(tester).width, closeTo(restWidth, 0.01));
    });

    testWidgets('reduced motion moves the lens at once, without stretch', (
      tester,
    ) async {
      reduceMotion(tester);
      await tester.pumpWidget(_host(currentIndex: 0));
      final restWidth = _lens(tester).width;

      await tester.pumpWidget(_host(currentIndex: 3));
      await tester.pump();

      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 3), 0.5));
      expect(_lens(tester).width, closeTo(restWidth, 0.01));
    });

    testWidgets('follows the finger during a swipe between pages', (
      tester,
    ) async {
      final page = ValueNotifier<double>(0);
      addTearDown(page.dispose);
      await tester.pumpWidget(_host(currentIndex: 0, pagePosition: page));
      final restWidth = _lens(tester).width;

      page.value = 0.5;
      await tester.pump();
      final halfway = (_slotCenter(tester, 0) + _slotCenter(tester, 1)) / 2;
      expect(_lens(tester).center.dx, closeTo(halfway, 0.5));
      expect(_lens(tester).width, greaterThan(restWidth));

      // The swipe settles on the next page, then the shell selects it.
      page.value = 1;
      await tester.pump();
      await tester.pumpWidget(_host(currentIndex: 1, pagePosition: page));
      await tester.pump();
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 1), 0.5));
      expect(_lens(tester).width, closeTo(restWidth, 0.01));
    });

    testWidgets('a tap jump is animated, not followed', (tester) async {
      final page = ValueNotifier<double>(0);
      addTearDown(page.dispose);
      await tester.pumpWidget(_host(currentIndex: 0, pagePosition: page));

      // A tap makes the shell jump the pager to a whole page.
      page.value = 4;
      await tester.pumpWidget(_host(currentIndex: 4, pagePosition: page));
      await tester.pump(Motion.durationSlow ~/ 2);

      expect(
        _lens(tester).center.dx,
        inExclusiveRange(_slotCenter(tester, 0), _slotCenter(tester, 4)),
      );
      await tester.pumpAndSettle();
    });
  });

  group('Semantics', () {
    testWidgets('every tab has a label and the selected one is marked', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(currentIndex: 2));

      for (final label in ['Início', 'Ativos', 'Pix', 'Swap', 'Menu']) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pix')),
        matchesSemantics(
          label: 'Pix',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });
  });
}
