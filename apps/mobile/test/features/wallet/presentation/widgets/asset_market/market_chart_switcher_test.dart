import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_chart.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

void main() {
  const skeleton = ValueKey('loading');
  const chart = ValueKey('chart');

  /// The switcher on the state with [key].
  Widget switcher(Key key) => wrapForTest(
    Center(
      child: MarketChartSwitcher(
        child: SizedBox(key: key, width: 300, height: MarketChart.height),
      ),
    ),
  );

  /// Opacity of the state with [key], or null when it is gone.
  double? opacityOf(WidgetTester tester, Key key) {
    final fade = find.ancestor(
      of: find.byKey(key),
      matching: find.byType(FadeTransition),
    );
    if (fade.evaluate().isEmpty) return null;
    return tester.widget<FadeTransition>(fade.first).opacity.value;
  }

  testWidgets('the old state fades out before the new one fades in', (
    tester,
  ) async {
    await tester.pumpWidget(switcher(skeleton));
    await tester.pumpWidget(switcher(chart));

    const step = Duration(milliseconds: 10);
    var fading = false;
    for (var time = Duration.zero; time <= Motion.durationBase; time += step) {
      final old = opacityOf(tester, skeleton) ?? 0;
      final next = opacityOf(tester, chart)!;
      expect(old == 0 || next == 0, isTrue, reason: 'at $time: $old, $next');
      if (old > 0 && old < 1) fading = true;
      await tester.pump(step);
    }

    expect(fading, isTrue);
    expect(find.byKey(skeleton), findsNothing);
    expect(opacityOf(tester, chart), 1);
  });

  testWidgets('the new state starts to show within the switch', (tester) async {
    await tester.pumpWidget(switcher(skeleton));
    await tester.pumpWidget(switcher(chart));

    await tester.pump(Motion.durationBase * 0.7);
    expect(opacityOf(tester, chart), inExclusiveRange(0, 1));
  });

  testWidgets('with reduced motion, the state changes at once', (tester) async {
    reduceMotion(tester);
    await tester.pumpWidget(switcher(skeleton));
    await tester.pumpWidget(switcher(chart));
    await tester.pump();

    expect(find.byKey(skeleton), findsNothing);
    expect(opacityOf(tester, chart), 1);
  });
}
