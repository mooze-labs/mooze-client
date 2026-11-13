import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_history_entries.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_transaction_tile.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// The status of a row of the hub history must read as on the screen the
/// row opens: the deposit details and the Pix history for a deposit, the
/// send result for a send. A pending deposit read "Em processamento" in the
/// hub and "Pagamento Pendente" everywhere else.

final _start = DateTime(2026, 11, 13, 14, 32);

PixDeposit _deposit(DepositStatus status) => PixDeposit(
  depositId: 'd',
  pixKey: 'chave',
  asset: Asset.depix,
  amountInCents: 10000,
  network: 'liquid',
  status: status,
  createdAt: _start,
);

PixWithdrawalRecord _send(PixWithdrawalStatus? lastStatus) =>
    PixWithdrawalRecord(
      id: 'w',
      createdAt: _start,
      payoutAmountInCents: 4590,
      depositAmountInCents: 4689,
      depositAmountSats: 4689000000,
      depositAddress: 'lq1qqdeposit',
      expiresAt: _start.add(const Duration(minutes: 30)),
      maskedKey: 'a***@exemplo.com.br',
      fundingStatus: PixFundingStatus.sent,
      lastStatus: lastStatus,
    );

Future<void> _pump(WidgetTester tester, PixTransaction transaction) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Theme(
          data: AppTheme.darkTheme(context),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PixTransactionTile(transaction: transaction),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The text of the status chip of the row, or null without a chip.
String? _chipText(WidgetTester tester) {
  final chip = find.byType(PixStatusChip);
  if (chip.evaluate().isEmpty) return null;
  return tester
      .widget<Text>(find.descendant(of: chip, matching: find.byType(Text)))
      .data;
}

AppLocalizations _t(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(PixTransactionTile)));

void main() {
  testWidgets('a pending deposit reads "Pagamento Pendente", as in the Pix '
      'history', (tester) async {
    await _pump(
      tester,
      pixTransactionFromDeposit(_deposit(DepositStatus.pending)),
    );

    expect(_chipText(tester), 'Pagamento Pendente');
    expect(find.text('Em processamento'), findsNothing);
  });

  testWidgets('a deposit under bank review reads "Revisão bancária"', (
    tester,
  ) async {
    await _pump(
      tester,
      pixTransactionFromDeposit(_deposit(DepositStatus.underReview)),
    );

    expect(_chipText(tester), 'Revisão bancária');
  });

  // Every status that shows a chip reads as the deposit details.
  for (final status in DepositStatus.values) {
    testWidgets('a ${status.name} deposit reads as its details', (
      tester,
    ) async {
      final transaction = pixTransactionFromDeposit(_deposit(status));
      await _pump(tester, transaction);

      if (transaction.status == PixTransactionStatus.completed) {
        expect(_chipText(tester), isNull);
        return;
      }
      final context = tester.element(find.byType(PixTransactionTile));
      expect(_chipText(tester), status.localizedLabel(context));
    });
  }

  testWidgets('a send being paid out reads "Enviando o Pix", as its result', (
    tester,
  ) async {
    await _pump(
      tester,
      pixTransactionFromWithdrawal(_send(PixWithdrawalStatus.sending))!,
    );

    expect(_chipText(tester), 'Enviando o Pix');
    expect(find.text('Em processamento'), findsNothing);
  });

  // A send with no status read yet reads "Consultando…", as its result.
  for (final status in <PixWithdrawalStatus?>[
    null,
    ...PixWithdrawalStatus.values,
  ]) {
    testWidgets('a send with status ${status?.name} reads as its result', (
      tester,
    ) async {
      final transaction = pixTransactionFromWithdrawal(_send(status))!;
      await _pump(tester, transaction);

      if (transaction.status == PixTransactionStatus.completed) {
        expect(_chipText(tester), isNull);
        return;
      }
      expect(_chipText(tester), pixWithdrawalStatusLabel(_t(tester), status));
    });
  }

  // The detailed labels are longer than the old ones. The chip sits under
  // the amount, and a long chip must not scale the amount down with it.
  final longLabels = <String, (PixTransaction, PixTransaction, String)>{
    'Pagamento estornado': (
      pixTransactionFromDeposit(_deposit(DepositStatus.finished)),
      pixTransactionFromDeposit(_deposit(DepositStatus.refunded)),
      '100,00',
    ),
    'Aguardando o depósito': (
      pixTransactionFromWithdrawal(_send(PixWithdrawalStatus.sent))!,
      pixTransactionFromWithdrawal(_send(PixWithdrawalStatus.unsent))!,
      '45,90',
    ),
  };
  for (final MapEntry(key: label, value: (done, withChip, amount))
      in longLabels.entries) {
    testWidgets('"$label" never shrinks the amount on a narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _pump(tester, done);
      final alone = tester.getRect(find.textContaining(amount)).width;

      await _pump(tester, withChip);
      expect(_chipText(tester), label);
      final beside = tester.getRect(find.textContaining(amount)).width;

      expect(beside, closeTo(alone, 0.01));
      expect(tester.takeException(), isNull);
    });
  }
}
