import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/motion/animated_amount.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../test_app.dart';
import 'motion_test_helpers.dart';

Widget _amount(String text, double value, {Object? mode}) => wrapForTest(
  Scaffold(
    body: Center(
      child: AnimatedAmount(text: text, value: value, mode: mode),
    ),
  ),
);

/// Slide transitions inside the amount. The page route has its own.
final _amountSlides = find.descendant(
  of: find.byType(AnimatedAmount),
  matching: find.byType(SlideTransition),
);

Offset _slideOf(WidgetTester tester, String text) {
  final slide = tester.widget<SlideTransition>(
    find.ancestor(of: find.text(text), matching: _amountSlides).first,
  );
  return slide.position.value;
}

void main() {
  group('Motion tokens', () {
    test('the staggered home entrance fits the entrance budget', () {
      expect(
        Motion.staggeredEntrance(5),
        lessThanOrEqualTo(Motion.entranceBudget),
      );
    });
  });

  group('AnimatedAmount', () {
    testWidgets('shows the first value without animation', (tester) async {
      await tester.pumpWidget(_amount('R\$ 10,00', 10));

      expect(find.text('R\$ 10,00'), findsOneWidget);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('R\$ 10,00'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1.0);
    });

    testWidgets('an increase slides the new value up from below', (
      tester,
    ) async {
      await tester.pumpWidget(_amount('10', 10));
      await tester.pumpWidget(_amount('11', 11));
      await tester.pump(Motion.durationBase ~/ 2);

      // Both values show during the change.
      expect(find.text('10'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(_slideOf(tester, '11').dy, greaterThan(0));
      expect(_slideOf(tester, '10').dy, lessThan(0));

      await tester.pump(Motion.numberChangeInterval);
      expect(find.text('10'), findsNothing);
      expect(find.text('11'), findsOneWidget);
    });

    testWidgets('a decrease slides the new value down from above', (
      tester,
    ) async {
      await tester.pumpWidget(_amount('11', 11));
      await tester.pumpWidget(_amount('10', 10));
      await tester.pump(Motion.durationBase ~/ 2);

      expect(_slideOf(tester, '10').dy, lessThan(0));
      expect(_slideOf(tester, '11').dy, greaterThan(0));

      await tester.pump(Motion.numberChangeInterval);
    });

    testWidgets('animates at most once per interval and shows the latest '
        'value', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_amount('10', 10));
      await tester.pumpWidget(_amount('11', 11));
      await tester.pump(const Duration(milliseconds: 100));

      // Two more updates inside the interval.
      await tester.pumpWidget(_amount('12', 12));
      await tester.pumpWidget(_amount('13', 13));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('12'), findsNothing);
      expect(find.text('13'), findsNothing);
      // Screen readers get the latest value at once.
      expect(find.bySemanticsLabel('13'), findsOneWidget);

      await tester.pump(Motion.numberChangeInterval);
      await tester.pump(Motion.durationBase);

      expect(find.text('12'), findsNothing);
      expect(find.text('13'), findsOneWidget);

      await tester.pump(Motion.numberChangeInterval);
      semantics.dispose();
    });

    testWidgets('a mode change cross-fades at once, without a slide', (
      tester,
    ) async {
      await tester.pumpWidget(_amount('10', 10, mode: 'fiat'));
      await tester.pumpWidget(_amount('11', 11, mode: 'fiat'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(_amount('0.0001', 0.0001, mode: 'btc'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('0.0001'), findsOneWidget);
      expect(
        find.ancestor(of: find.text('0.0001'), matching: _amountSlides),
        findsNothing,
      );

      await tester.pump(Motion.numberChangeInterval);
    });

    testWidgets('reduced motion changes the text at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_amount('10', 10));
      await tester.pumpWidget(_amount('11', 11));
      await tester.pump();

      expect(find.text('10'), findsNothing);
      expect(find.text('11'), findsOneWidget);

      // No interval with reduced motion: the next value shows at once too.
      await tester.pumpWidget(_amount('12', 12));
      await tester.pump();
      expect(find.text('12'), findsOneWidget);
    });
  });

  group('PressScale', () {
    Widget host(VoidCallback onPressed) => wrapForTest(
      Scaffold(
        body: Center(
          child: PressScale(
            child: ElevatedButton(
              onPressed: onPressed,
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );

    double scaleOf(WidgetTester tester) =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    testWidgets('scales down while pressed and keeps the tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(() => taps++));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Go')),
      );
      await tester.pump(Motion.durationPress);
      expect(scaleOf(tester), Motion.pressScale);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scaleOf(tester), 1.0);
      expect(taps, 1);
    });

    testWidgets('reduced motion keeps the scale at 1', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(host(() {}));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Go')),
      );
      await tester.pump(Motion.durationPress);
      expect(scaleOf(tester), 1.0);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('staggeredAnimation', () {
    testWidgets('starts each section one stagger step later', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: Motion.staggeredEntrance(5),
      );
      addTearDown(controller.dispose);
      final first = staggeredAnimation(controller, 0);
      final last = staggeredAnimation(controller, 4);
      final total = controller.duration!.inMicroseconds;

      controller.value = (Motion.staggerStep * 4).inMicroseconds / total;
      expect(first.value, greaterThan(0));
      expect(last.value, 0);

      controller.value = 1;
      expect(first.value, 1);
      expect(last.value, 1);
    });
  });
}
