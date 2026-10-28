import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_icon_hero.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_row.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

Widget _sparkline(List<double> values, {Object? revealId}) => wrapForTest(
  Scaffold(
    body: Center(
      child: Sparkline(values: values, color: Colors.green, revealId: revealId),
    ),
  ),
);

/// The painter of the sparkline. Its class is private, so the test reads
/// its fields dynamically.
dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.descendant(
        of: find.byType(Sparkline),
        matching: find.byType(CustomPaint),
      ),
    )
    .painter;

double _reveal(WidgetTester tester) => _painter(tester).reveal as double;

double _firstPoint(WidgetTester tester) =>
    (_painter(tester).points as List<double>).first;

void main() {
  group('Sparkline', () {
    testWidgets('draws from left to right on the first show', (tester) async {
      await tester.pumpWidget(_sparkline([1, 2, 3], revealId: 'reveal-a'));
      expect(_reveal(tester), 0);

      await tester.pump(Motion.durationEmphasis ~/ 2);
      expect(_reveal(tester), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(_reveal(tester), 1);
    });

    testWidgets('a later show in the same session skips the reveal', (
      tester,
    ) async {
      await tester.pumpWidget(_sparkline([1, 2, 3], revealId: 'reveal-b'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_sparkline([1, 2, 3], revealId: 'reveal-b'));
      expect(_reveal(tester), 1);
    });

    testWidgets('reduced motion shows the full line at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_sparkline([1, 2, 3], revealId: 'reveal-c'));
      expect(_reveal(tester), 1);
    });

    testWidgets('new values morph the line', (tester) async {
      await tester.pumpWidget(_sparkline([1, 2, 3]));
      expect(_firstPoint(tester), 0);

      await tester.pumpWidget(_sparkline([3, 2, 1]));
      await tester.pump(Motion.durationEmphasis ~/ 2);
      expect(_firstPoint(tester), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(_firstPoint(tester), 1);
    });

    testWidgets('reduced motion swaps to new values at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_sparkline([1, 2, 3]));
      await tester.pumpWidget(_sparkline([3, 2, 1]));
      await tester.pump();
      expect(_firstPoint(tester), 1);
    });
  });

  group('AssetRowView', () {
    testWidgets('the trailing part has the same width in every row', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: Column(
              children: [
                AssetRowView(
                  asset: Asset.btc,
                  onTap: () {},
                  trailing: const Text('R\$ 428.314,12'),
                ),
                AssetRowView(
                  asset: Asset.usdt,
                  onTap: () {},
                  trailing: const Text('R\$ 5,37'),
                ),
              ],
            ),
          ),
        ),
      );

      // The switcher box holds the trailing part. Equal boxes keep the
      // sparklines of all rows in one column.
      final boxes = find.descendant(
        of: find.byType(AssetRowView),
        matching: find.byType(AnimatedSwitcher),
      );
      expect(
        tester.getSize(boxes.at(0)).width,
        tester.getSize(boxes.at(1)).width,
      );
      expect(
        tester.getTopLeft(boxes.at(0)).dx,
        tester.getTopLeft(boxes.at(1)).dx,
      );
    });
  });

  group('Asset icon Hero', () {
    Widget detail() => const Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: AssetIconHero(asset: Asset.btc, size: 22),
      ),
    );

    Widget home() => wrapForTest(
      Builder(
        builder: (context) => Scaffold(
          body: AssetRowView(
            asset: Asset.btc,
            trailing: const SizedBox(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => detail()),
              );
            },
          ),
        ),
      ),
    );

    testWidgets('the row icon is a Hero with the shared tag', (tester) async {
      await tester.pumpWidget(home());

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, assetIconHeroTag(Asset.btc));
      expect(tester.widget<HeroMode>(find.byType(HeroMode)).enabled, isTrue);
    });

    testWidgets('the icon flies to the detail screen', (tester) async {
      await tester.pumpWidget(home());
      await tester.tap(find.byType(AssetRowView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // During the flight the icon size is between the row size and the
      // app bar size.
      final size = tester.getSize(find.byType(SvgPicture).last);
      expect(size.width, inExclusiveRange(22, AssetRowView.iconSize));

      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion turns the flight off', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(home());
      expect(tester.widget<HeroMode>(find.byType(HeroMode)).enabled, isFalse);

      await tester.tap(find.byType(AssetRowView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (final element in find.byType(SvgPicture).evaluate()) {
        final width = (element.renderObject! as RenderBox).size.width;
        expect(width, anyOf(22, AssetRowView.iconSize));
      }

      await tester.pumpAndSettle();
    });
  });
}
