import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_history_entries.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pix_send_fakes.dart';

PixWithdrawalRecord _send(
  String id, {
  PixFundingStatus funding = PixFundingStatus.sent,
  PixWithdrawalStatus? lastStatus,
  DateTime? at,
}) {
  return PixWithdrawalRecord(
    id: id,
    createdAt: at ?? testStart,
    payoutAmountInCents: 4590,
    depositAmountInCents: 4689,
    depositAmountSats: 4689000000,
    depositAddress: 'lq1qqdeposit',
    expiresAt: testStart.add(const Duration(minutes: 30)),
    maskedKey: 'a***@exemplo.com.br',
    fundingStatus: funding,
    lastStatus: lastStatus,
  );
}

PixDeposit _deposit(String id, DepositStatus status, {DateTime? at}) {
  return PixDeposit(
    depositId: id,
    pixKey: 'chave',
    asset: Asset.depix,
    amountInCents: 10000,
    network: 'liquid',
    status: status,
    createdAt: at ?? testStart,
  );
}

void main() {
  group('a send in the history', () {
    PixTransactionStatus? statusOf(PixWithdrawalRecord record) =>
        pixTransactionFromWithdrawal(record)?.status;

    test('reads the result of the provider', () {
      expect(
        statusOf(_send('w', lastStatus: PixWithdrawalStatus.sent)),
        PixTransactionStatus.completed,
      );
      expect(
        statusOf(_send('w', lastStatus: PixWithdrawalStatus.refunded)),
        PixTransactionStatus.failed,
      );
      // An error can still end in a refund, so it is not over.
      expect(
        statusOf(_send('w', lastStatus: PixWithdrawalStatus.error)),
        PixTransactionStatus.pending,
      );
      expect(statusOf(_send('w')), PixTransactionStatus.pending);
    });

    test('shows the payout to the masked key', () {
      final tx = pixTransactionFromWithdrawal(_send('w-1'))!;

      expect(tx.kind, PixTransactionKind.sent);
      expect(tx.amountInCents, 4590);
      expect(tx.counterpartyName, 'a***@exemplo.com.br');
      expect(tx.id, 'w-1');
    });

    test('a send that never left the wallet is not listed', () {
      expect(
        pixTransactionFromWithdrawal(
          _send('w', funding: PixFundingStatus.notSent),
        ),
        isNull,
      );
    });
  });

  group('a deposit in the history', () {
    test('reads the deposit status', () {
      PixTransactionStatus statusOf(DepositStatus status) =>
          pixTransactionFromDeposit(_deposit('d', status)).status;

      expect(statusOf(DepositStatus.finished), PixTransactionStatus.completed);
      expect(statusOf(DepositStatus.expired), PixTransactionStatus.failed);
      expect(statusOf(DepositStatus.refunded), PixTransactionStatus.failed);
      expect(statusOf(DepositStatus.pending), PixTransactionStatus.pending);
      expect(statusOf(DepositStatus.depixSent), PixTransactionStatus.pending);
    });

    test('is money in, named by the asset', () {
      final tx = pixTransactionFromDeposit(
        _deposit('d-1', DepositStatus.finished),
      );

      expect(tx.kind, PixTransactionKind.deposit);
      expect(tx.direction, PixTransactionDirection.incoming);
      expect(tx.amountInCents, 10000);
      expect(tx.counterpartyName, Asset.depix.ticker);
    });
  });

  test('the history mixes sends and deposits, newest first', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PixWithdrawalRecordStore(prefs);
    await store.save(
      _send(
        'w-old',
        lastStatus: PixWithdrawalStatus.sent,
        at: DateTime.utc(2026, 11, 1),
      ),
    );
    await store.save(
      _send(
        'w-new',
        lastStatus: PixWithdrawalStatus.sent,
        at: DateTime.utc(2026, 11, 4),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pixWithdrawalRepositoryProvider.overrideWithValue(
          FakeWithdrawalRepository(),
        ),
        pixDepositHistoryProvider.overrideWith(
          (ref) async => Right([
            _deposit(
              'd-mid',
              DepositStatus.finished,
              at: DateTime.utc(2026, 11, 2),
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    // The screen keeps the list alive while it loads.
    container.listen(pixHubTransactionsProvider, (_, _) {});

    final history = await container.read(pixHubTransactionsProvider.future);

    expect(history.map((tx) => tx.id), ['w-new', 'd-mid', 'w-old']);
  });
}
