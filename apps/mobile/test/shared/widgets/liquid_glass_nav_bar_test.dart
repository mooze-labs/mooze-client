import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// The bar as the shell drives it: a tab from [CustomBottomNavBar.onTap]
/// jumps [page] to it and becomes the selected tab. [taps] records them.
Widget _shell({
  required List<int> taps,
  ValueNotifier<double>? page,
  int initial = 0,
}) {
  var index = initial;
  return StatefulBuilder(
    builder: (context, setState) => _host(
      currentIndex: index,
      pagePosition: page,
      onTap: (tab) {
        taps.add(tab);
        page?.value = tab.toDouble();
        setState(() => index = tab);
      },
    ),
  );
}

/// Width of one tab.
double _slot(WidgetTester tester) =>
    (_capsule(tester).width - CustomBottomNavBar.inset * 2) / 5;

/// Starts a touch on tab [index] and moves past the drag slop, so the drag
/// on the capsule has started.
Future<TestGesture> _grab(WidgetTester tester, int index) async {
  final gesture = await tester.startGesture(
    Offset(_slotCenter(tester, index), _capsule(tester).center.dy),
  );
  await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
  await tester.pump();
  return gesture;
}

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

  group('Capsule drag', () {
    testWidgets('the lens follows the finger, stretches, and lights the tab '
        'under it', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(_shell(taps: taps));
      final restWidth = _lens(tester).width;
      final slot = _slot(tester);

      final gesture = await _grab(tester, 0);
      await gesture.moveBy(Offset(slot * 1.5, 0));
      await tester.pump();

      // Halfway between the second and the third tab, give or take the slop.
      final halfway = (_slotCenter(tester, 1) + _slotCenter(tester, 2)) / 2;
      expect(_lens(tester).center.dx, closeTo(halfway, kTouchSlop + 1));
      expect(_lens(tester).width, greaterThan(restWidth));
      expect(taps, isEmpty);

      await gesture.moveBy(Offset(slot * 0.5, 0));
      await tester.pump();
      // On a tab, the lens is round again, and that tab shows its label.
      expect(
        _lens(tester).center.dx,
        closeTo(_slotCenter(tester, 2), kTouchSlop + 1),
      );
      expect(find.text('Pix'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, [2]);
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 2), 0.5));
      expect(_lens(tester).width, closeTo(restWidth, 0.01));
    });

    testWidgets('a slow short drag springs back to the selected tab', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(_shell(taps: taps, initial: 1));

      final gesture = await _grab(tester, 1);
      await gesture.moveBy(Offset(_slot(tester) * 0.2, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump(Motion.durationEmphasis ~/ 2);
      // On the way back.
      expect(_lens(tester).center.dx, greaterThan(_slotCenter(tester, 1)));

      await tester.pumpAndSettle();
      expect(taps, isEmpty);
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 1), 0.5));
    });

    testWidgets('a flick moves on after a short drag, in both directions', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(_shell(taps: taps, initial: 2));

      /// Flicks from tab [from] by 50 pt in [direction], at about 1250 pt/s.
      /// Past the slop, that is less than half a tab of travel.
      Future<void> flick(int from, double direction) async {
        final gesture = await tester.startGesture(
          Offset(_slotCenter(tester, from), _capsule(tester).center.dy),
        );
        for (var i = 1; i <= 5; i++) {
          await gesture.moveBy(
            Offset(10 * direction, 0),
            timeStamp: Duration(milliseconds: 8 * i),
          );
        }
        await gesture.up(timeStamp: const Duration(milliseconds: 48));
        await tester.pumpAndSettle();
      }

      expect(50 - kTouchSlop, lessThan(_slot(tester) / 2));
      await flick(2, 1);
      expect(taps.last, greaterThan(2));

      final from = taps.last;
      await flick(from, -1);
      expect(taps.last, lessThan(from));
      expect(
        _lens(tester).center.dx,
        closeTo(_slotCenter(tester, taps.last), 0.5),
      );
    });

    testWidgets('the lens presses against the end of the capsule', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(_shell(taps: taps));
      final capsule = _capsule(tester);

      final gesture = await _grab(tester, 0);
      await gesture.moveBy(Offset(-_slot(tester) * 2, 0));
      await tester.pump();
      final lens = _lens(tester);
      expect(lens.left, greaterThanOrEqualTo(capsule.left));
      expect(lens.right, lessThan(capsule.right));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, isEmpty);
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 0), 0.5));
    });

    testWidgets('the page jump that follows the release does not cut the '
        'spring', (tester) async {
      final taps = <int>[];
      final page = ValueNotifier<double>(0);
      addTearDown(page.dispose);
      await tester.pumpWidget(_shell(taps: taps, page: page));

      final gesture = await _grab(tester, 0);
      await gesture.moveBy(Offset(_slot(tester) * 2.6, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(taps, [3]);
      expect(page.value, 3);

      await tester.pump(const Duration(milliseconds: 32));
      // Still springing toward the tab, not jumped there.
      expect(
        (_lens(tester).center.dx - _slotCenter(tester, 3)).abs(),
        greaterThan(0.5),
      );
      await tester.pumpAndSettle();
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 3), 0.5));
    });

    testWidgets('each tab crossed plays one selection click', (tester) async {
      var clicks = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') clicks++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(_shell(taps: []));

      final gesture = await _grab(tester, 0);
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(Offset(_slot(tester) * 0.5, 0));
        await tester.pump();
      }
      expect(clicks, 3);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a vertical drag leaves the bar alone', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(_shell(taps: taps, initial: 1));
      final before = _lens(tester);

      await tester.dragFrom(
        Offset(_slotCenter(tester, 1), _capsule(tester).center.dy),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(taps, isEmpty);
      expect(_lens(tester), before);
    });

    testWidgets('a tap still opens its tab and keeps the lens animation', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(_shell(taps: taps));

      await tester.tap(find.text('Início'));
      await tester.tapAt(
        Offset(_slotCenter(tester, 4), _capsule(tester).center.dy),
      );
      // One frame starts the lens move, then it runs.
      await tester.pump();
      await tester.pump(Motion.durationSlow ~/ 2);
      expect(taps, [0, 4]);
      expect(
        _lens(tester).center.dx,
        inExclusiveRange(_slotCenter(tester, 0), _slotCenter(tester, 4)),
      );
      await tester.pumpAndSettle();
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 4), 0.5));
    });

    testWidgets('reduced motion follows the finger and lands at once', (
      tester,
    ) async {
      reduceMotion(tester);
      final taps = <int>[];
      await tester.pumpWidget(_shell(taps: taps));
      final restWidth = _lens(tester).width;

      final gesture = await _grab(tester, 0);
      await gesture.moveBy(Offset(_slot(tester) * 1.8, 0));
      await tester.pump();
      expect(_lens(tester).width, closeTo(restWidth, 0.01));

      await gesture.up();
      await tester.pump();
      expect(taps, [2]);
      expect(_lens(tester).center.dx, closeTo(_slotCenter(tester, 2), 0.5));
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
