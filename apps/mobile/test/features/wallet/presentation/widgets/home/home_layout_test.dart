import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/balance_hero.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/home_action_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/section_header.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/transaction_list.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../../../../shared/test_app.dart';

/// Sets a 320 pt wide screen.
void _narrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void _largeText(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _home() => wrapForTest(
  Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BalanceHeroView(
            amount: const AsyncData(
              BalanceAmount(prefix: 'R\$', digits: '128.908,47', value: 1),
            ),
            mode: 'fiat',
            isHidden: false,
            variation: const AsyncData(-12.07),
            onToggleVisibility: () {},
            onCycleMode: () {},
            showPendingPix: true,
            onPendingPixTap: () {},
          ),
          HomeActionRow(
            onSend: () {},
            onReceive: () {},
            onSwap: () {},
            onMore: () {},
          ),
          SectionHeader(
            onAction: () {},
            title: 'Ativos',
            actionDescription: 'Ver mais',
          ),
          AssetRowView(
            asset: Asset.depix,
            onTap: () {},
            // Production trailing parts fit their fixed-width box the same
            // way.
            trailing: const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('R\$ 428.314,12'),
                    ChangeChip(percentage: -2.25),
                  ],
                ),
              ),
            ),
          ),
          AssetTransactionItem(
            icon: Asset.btc.iconPath,
            title: 'Bitcoin',
            balance: '0.00123456 BTC',
            value: 'R\$ 128.314,12',
            fiatValue: 128314.12,
            status: 'Sem saldo',
            isHidden: false,
          ),
          HomeTransactionItem(
            icon: Asset.lbtc.iconPath,
            title: 'Enviou BTC L2 para um endereço longo',
            subtitle: 'Confirmado',
            value: '-7.806.073 sats',
            time: '21/10/2026 13:09',
            isVisible: false,
            transaction: Transaction(
              id: 'tx',
              amount: BigInt.from(7806073),
              blockchain: Blockchain.liquid,
              asset: Asset.lbtc,
              type: TransactionType.send,
              status: TransactionStatus.confirmed,
              createdAt: DateTime(2026, 10, 21, 13, 9),
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('the home and holdings widgets fit a 320 pt screen', (
    tester,
  ) async {
    _narrowScreen(tester);
    await tester.pumpWidget(_home());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the home and holdings widgets fit a 320 pt screen at 200% '
      'text', (tester) async {
    _narrowScreen(tester);
    _largeText(tester, 2);
    await tester.pumpWidget(_home());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
