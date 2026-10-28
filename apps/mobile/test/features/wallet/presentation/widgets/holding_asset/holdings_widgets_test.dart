import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/values_to_receive_card.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/home_action_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/section_header.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

/// Currency without storage access.
class _FakeCurrency extends StateNotifier<Currency>
    implements CurrencyNotifier {
  _FakeCurrency() : super(Currency.brl);

  @override
  String get icon => 'R\$';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _row({
  required bool hidden,
  String value = 'R\$ 1.234,56',
  String status = '',
}) => wrapForTest(
  Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AssetTransactionItem(
        icon: Asset.btc.iconPath,
        title: 'Bitcoin',
        balance: '0.0012 BTC',
        value: value,
        fiatValue: 1234.56,
        status: status,
        isHidden: hidden,
      ),
    ),
  ),
);

void main() {
  group('AssetTransactionItem', () {
    testWidgets('hide cross-fades the amounts and the mask', (tester) async {
      await tester.pumpWidget(_row(hidden: false));
      await tester.pumpWidget(_row(hidden: true));
      await tester.pump(Motion.durationFast ~/ 2);

      expect(find.text('0.0012 BTC'), findsOneWidget);
      expect(find.text(holdingMask), findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(find.text('0.0012 BTC'), findsNothing);
      expect(find.text('R\$ 1.234,56'), findsNothing);
      expect(find.text(holdingMask), findsNWidgets(2));
    });

    testWidgets('reduced motion hides the amounts at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_row(hidden: false));
      await tester.pumpWidget(_row(hidden: true));
      await tester.pump();

      expect(find.text('0.0012 BTC'), findsNothing);
      expect(find.text(holdingMask), findsNWidgets(2));
    });

    testWidgets('a hidden balance hides the status too', (tester) async {
      await tester.pumpWidget(_row(hidden: true, status: 'Sem saldo'));
      expect(find.text('Sem saldo'), findsNothing);
    });

    testWidgets('the status uses the secondary text color', (tester) async {
      await tester.pumpWidget(_row(hidden: false, status: 'Sem saldo'));
      final status = tester.widget<Text>(find.text('Sem saldo'));
      expect(status.style?.color, AppExtraColors.dark.textSecondary);
    });

    testWidgets('a new fiat value animates', (tester) async {
      await tester.pumpWidget(_row(hidden: false));
      await tester.pumpWidget(_row(hidden: false, value: 'R\$ 1.300,00'));
      await tester.pump(Motion.durationBase ~/ 2);

      expect(find.text('R\$ 1.234,56'), findsOneWidget);
      expect(find.text('R\$ 1.300,00'), findsOneWidget);

      await tester.pump(Motion.numberChangeInterval);
    });
  });

  group('HomeActionRow', () {
    testWidgets('without onMore shows three actions', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: HomeActionRow(onSend: () {}, onReceive: () {}, onSwap: () {}),
          ),
        ),
      );
      expect(find.byType(HomeActionButton), findsNWidgets(3));
      expect(find.text('Mais'), findsNothing);
    });

    testWidgets('with onMore shows four actions', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: HomeActionRow(
              onSend: () {},
              onReceive: () {},
              onSwap: () {},
              onMore: () {},
            ),
          ),
        ),
      );
      expect(find.byType(HomeActionButton), findsNWidgets(4));
      expect(find.text('Mais'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('without an action shows only the title', (tester) async {
      await tester.pumpWidget(
        wrapForTest(const Scaffold(body: SectionHeader(title: 'Ativos'))),
      );
      expect(find.text('Ativos'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('ValuesToReceiveCard', () {
    Widget card() => ProviderScope(
      overrides: [
        valuesToReceiveProvider.overrideWith(
          (ref) async => right([
            const AssetToReceive(
              asset: Asset.depix,
              valueInCents: 5000,
              formattedValue: 'R\$ 50,00',
              displayValue: 50,
            ),
          ]),
        ),
        totalValueToReceiveProvider.overrideWith((ref) async => 50),
        currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
      ],
      child: wrapForTest(const Scaffold(body: ValuesToReceiveCard())),
    );

    double iconOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byIcon(Icons.schedule_rounded),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    testWidgets('the icon pulses when the card appears and then stops', (
      tester,
    ) async {
      await tester.pumpWidget(card());
      await tester.pump();
      await tester.pump();
      expect(find.text('R\$ 50,00'), findsOneWidget);

      await tester.pump(Motion.durationCelebrate ~/ 2);
      expect(iconOpacity(tester), lessThan(1));

      // The pulse ends, so the screen settles. An endless loop would time
      // out here.
      await tester.pumpAndSettle();
      expect(iconOpacity(tester), 1);
    });

    testWidgets('reduced motion keeps the icon still', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(card());
      await tester.pump();
      await tester.pump();

      await tester.pump(Motion.durationCelebrate ~/ 2);
      expect(iconOpacity(tester), 1);
    });
  });
}
