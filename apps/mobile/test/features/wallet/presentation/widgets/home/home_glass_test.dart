import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/home_action_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/transaction_list.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';

import '../../../../../shared/test_app.dart';

Widget _screen(Widget child) => ProviderScope(
  child: wrapForTest(
    Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  ),
);

Widget _transactions({required bool glass}) => _screen(
  SuccessfulTransactionList(
    transactions: [
      Transaction(
        id: 'a',
        amount: BigInt.from(1000),
        blockchain: Blockchain.liquid,
        asset: Asset.lbtc,
        type: TransactionType.receive,
        status: TransactionStatus.confirmed,
        createdAt: DateTime.now(),
      ),
    ],
    isVisible: false,
    groupByDate: false,
    glass: glass,
  ),
);

/// Ring colors of the direction badges on the row icons.
List<Color> _badgeRings(WidgetTester tester) => [
  for (final widget in tester.widgetList<Container>(find.byType(Container)))
    if (widget.decoration case BoxDecoration(
      shape: BoxShape.circle,
      border: final Border border,
    ))
      border.top.color,
];

void main() {
  group('Action row', () {
    testWidgets('the circles are glass without a backdrop blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          HomeActionRow(
            onSend: () {},
            onReceive: () {},
            onSwap: () {},
            onMore: () {},
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(HomeActionButton),
          matching: find.byType(LiquidGlass),
        ),
        findsNWidgets(4),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('a tap on a glass circle runs the action', (tester) async {
      var sends = 0;
      await tester.pumpWidget(
        _screen(
          HomeActionRow(onSend: () => sends++, onReceive: () {}, onSwap: () {}),
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(LiquidGlass).first,
          matching: find.byType(InkWell),
        ),
      );
      expect(sends, 1);
    });
  });

  group('Transaction panels', () {
    testWidgets('the home preview draws the rows on glass', (tester) async {
      await tester.pumpWidget(_transactions(glass: true));

      expect(find.byType(GlassPanel), findsOneWidget);
      expect(find.byType(AppPanel), findsNothing);
    });

    testWidgets('other screens keep the plain panel', (tester) async {
      await tester.pumpWidget(_transactions(glass: false));

      expect(find.byType(AppPanel), findsOneWidget);
      expect(find.byType(GlassPanel), findsNothing);
    });

    testWidgets('the loading and empty lists follow the glass flag', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          const Column(
            children: [
              LoadingTransactionList(glass: true),
              EmptyTransactionList(glass: true),
            ],
          ),
        ),
      );
      expect(find.byType(GlassPanel), findsNWidgets(2));

      await tester.pumpWidget(
        _screen(
          const Column(
            children: [LoadingTransactionList(), EmptyTransactionList()],
          ),
        ),
      );
      expect(find.byType(GlassPanel), findsNothing);
      expect(find.byType(AppPanel), findsNWidgets(2));
    });
  });

  group('Badge ring', () {
    testWidgets('takes the tone of the glass', (tester) async {
      await tester.pumpWidget(_transactions(glass: true));

      final row = tester.element(find.byType(HomeTransactionItem));
      final tone = GlassPanel.maybeToneOf(row);
      expect(tone, isNotNull);
      expect(tone, isNot(AppSurfaces.panel(row).color));
      expect(_badgeRings(tester), [tone]);
    });

    testWidgets('keeps the panel color in a plain panel', (tester) async {
      await tester.pumpWidget(_transactions(glass: false));

      final row = tester.element(find.byType(HomeTransactionItem));
      expect(GlassPanel.maybeToneOf(row), isNull);
      expect(_badgeRings(tester), [AppSurfaces.panel(row).color]);
    });
  });
}
