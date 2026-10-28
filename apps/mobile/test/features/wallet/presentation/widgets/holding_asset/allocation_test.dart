import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/allocation_bar.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

const _segments = [
  AllocationSegment(share: 0.75, color: Colors.pink),
  AllocationSegment(share: 0.25, color: Colors.grey),
];

Widget _bar() => wrapForTest(
  const Scaffold(
    body: Center(
      child: SizedBox(width: 302, child: AllocationBar(segments: _segments)),
    ),
  ),
);

/// Width factor of the reveal clip around the bar.
double _reveal(WidgetTester tester) => tester
    .widget<Align>(
      find.descendant(
        of: find.byType(AllocationBar),
        matching: find.byWidgetPredicate(
          (widget) => widget is Align && widget.widthFactor != null,
        ),
      ),
    )
    .widthFactor!;

void main() {
  setUp(AllocationBar.resetSession);

  group('AllocationBar', () {
    testWidgets('segment widths follow the shares', (tester) async {
      await tester.pumpWidget(_bar());
      await tester.pumpAndSettle();

      final segments = find.descendant(
        of: find.byType(AllocationBar),
        matching: find.byType(AnimatedContainer),
      );
      // 302 pt minus one gap leaves the usable width for the segments.
      const usable = 302 - AllocationBar.gap;
      expect(
        tester.getSize(segments.at(0)).width,
        closeTo(usable * 0.75, 0.01),
      );
      expect(
        tester.getSize(segments.at(1)).width,
        closeTo(usable * 0.25, 0.01),
      );
    });

    testWidgets('the first show draws the bar from left to right', (
      tester,
    ) async {
      await tester.pumpWidget(_bar());
      expect(_reveal(tester), 0);

      await tester.pump(Motion.durationChartDraw ~/ 2);
      expect(_reveal(tester), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(_reveal(tester), 1);
    });

    testWidgets('a later show in the same session skips the draw', (
      tester,
    ) async {
      await tester.pumpWidget(_bar());
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_bar());
      expect(_reveal(tester), 1);
    });

    testWidgets('reduced motion shows the full bar at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_bar());
      expect(_reveal(tester), 1);
    });

    testWidgets('the largest holding uses the brand color', (tester) async {
      late Color first;
      late Color second;
      late Color primary;
      await tester.pumpWidget(
        wrapForTest(
          Builder(
            builder: (context) {
              first = allocationColor(context, 0);
              second = allocationColor(context, 1);
              primary = Theme.of(context).colorScheme.primary;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(first, primary);
      expect(second, isNot(primary));
    });
  });

  group('Minimum segment width', () {
    test('a tiny share stays visible', () {
      final widths = AllocationBar.widthsFor([0.967, 0.032, 0.001], 300);
      expect(widths[1], greaterThanOrEqualTo(AllocationBar.minSegment));
      expect(widths[2], AllocationBar.minSegment);
      expect(
        widths.fold<double>(0, (sum, width) => sum + width),
        closeTo(300, 0.01),
      );
    });

    test('shares above the minimum keep their proportion', () {
      final widths = AllocationBar.widthsFor([0.6, 0.4], 300);
      expect(widths[0], closeTo(180, 0.01));
      expect(widths[1], closeTo(120, 0.01));
    });
  });

  group('AllocationLegend', () {
    Widget legend({required bool hidden}) => wrapForTest(
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: AllocationLegend(
              isHidden: hidden,
              entries: const [
                AllocationEntry(
                  label: 'DePix',
                  share: 0.967,
                  color: Colors.pink,
                ),
                AllocationEntry(label: 'BTC', share: 0.032, color: Colors.grey),
                AllocationEntry(
                  label: 'BTC L2',
                  share: 0.001,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('shows each label with its share', (tester) async {
      await tester.pumpWidget(legend(hidden: false));
      expect(find.text('DePix'), findsOneWidget);
      expect(find.text('96,7%'), findsOneWidget);
      expect(find.text('3,2%'), findsOneWidget);
      expect(find.text('0,1%'), findsOneWidget);
    });

    testWidgets('aligns the shares of one column on the right', (tester) async {
      await tester.pumpWidget(legend(hidden: false));
      // Entries 1 and 3 share the first column.
      final first = tester.getTopRight(find.text('96,7%')).dx;
      final third = tester.getTopRight(find.text('0,1%')).dx;
      expect(first, closeTo(third, 0.01));
    });

    testWidgets('masks the shares when the balance is hidden', (tester) async {
      await tester.pumpWidget(legend(hidden: true));
      expect(find.text('96,7%'), findsNothing);
      expect(find.text('•••'), findsNWidgets(3));
      expect(find.text('DePix'), findsOneWidget);
    });
  });

  group('Holding row', () {
    testWidgets('shows the ticker under the name and the amount under the '
        'value', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: AssetTransactionItem(
              icon: Asset.btc.iconPath,
              title: 'Bitcoin',
              ticker: 'BTC',
              balance: '67.234 sats',
              value: 'R\$ 288,36',
              fiatValue: 288.36,
              isHidden: false,
            ),
          ),
        ),
      );

      final name = tester.getTopLeft(find.text('Bitcoin'));
      final ticker = tester.getTopLeft(find.text('BTC'));
      final value = tester.getTopRight(find.text('R\$ 288,36'));
      final amount = tester.getTopRight(find.text('67.234 sats'));
      expect(ticker.dx, name.dx);
      expect(ticker.dy, greaterThan(name.dy));
      expect(amount.dx, closeTo(value.dx, 0.5));
      expect(amount.dy, greaterThan(value.dy));
    });
  });
}
