import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/swap_audit_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

import '../../../shared/database_test_helpers.dart';

/// Pins the cross-wallet isolation contract: rows written under one
/// walletId must not appear in another walletId's scoped queries, even
/// when the two wallets share the same drift database.
void main() {
  late AppDatabase db;
  late AppLoggerService logger;

  setUp(() {
    db = buildInMemoryDatabase();
    logger = AppLoggerService();
  });

  tearDown(() async {
    await db.close();
  });

  SwapAuditRepository auditFor(String walletId) {
    return SwapAuditRepositoryImpl(db, logger, FakeWalletIdService(walletId));
  }

  test(
    'a swap recorded under wallet-A is invisible to wallet-B queries',
    () async {
      final auditA = auditFor('wallet-A');
      await auditA.recordCompleted(
        provider: 'breez',
        direction: 'lbtc_to_btc',
        sendAsset: 'LBTC',
        receiveAsset: 'BTC',
        sendAmount: BigInt.from(100000),
        receiveAmount: BigInt.from(99500),
        txId: 'btc-tx-A',
      );

      // Wallet B sees nothing.
      expect(await db.getAllSwaps(walletId: 'wallet-B'), isEmpty);
      expect(await db.getSwapsCount(walletId: 'wallet-B'), 0);

      // Wallet A sees its row.
      expect(await db.getAllSwaps(walletId: 'wallet-A'), hasLength(1));
      expect(await db.getSwapsCount(walletId: 'wallet-A'), 1);

      // The on-disk row count is 1 (not duplicated across queries).
      final allRows = await db.select(db.swaps).get();
      expect(allRows, hasLength(1));
    },
  );

  test(
    'idempotency on (provider, txId) is scoped per wallet — same '
    'txId in two wallets produces two distinct rows',
    () async {
      final auditA = auditFor('wallet-A');
      final auditB = auditFor('wallet-B');

      await auditA.recordCompleted(
        provider: 'breez',
        direction: 'lbtc_to_btc',
        sendAsset: 'LBTC',
        receiveAsset: 'BTC',
        sendAmount: BigInt.from(100000),
        receiveAmount: BigInt.from(99500),
        txId: 'tx-1',
      );
      await auditB.recordCompleted(
        provider: 'breez',
        direction: 'lbtc_to_btc',
        sendAsset: 'LBTC',
        receiveAsset: 'BTC',
        sendAmount: BigInt.from(100000),
        receiveAmount: BigInt.from(99500),
        txId: 'tx-1',
      );

      expect(await db.getAllSwaps(walletId: 'wallet-A'), hasLength(1));
      expect(await db.getAllSwaps(walletId: 'wallet-B'), hasLength(1));
      expect(await db.select(db.swaps).get(), hasLength(2));
    },
  );

  test(
    'pre-walletId rows (sentinel "unknown") are invisible to active '
    'wallet queries but remain on disk',
    () async {
      // Simulate a v10 row that landed before the walletId migration:
      // the migration backfilled walletId='unknown' for those.
      await db.into(db.swaps).insert(
        SwapsCompanion.insert(
          sendAsset: 'LBTC',
          receiveAsset: 'BTC',
          sendAmount: BigInt.from(100000),
          receiveAmount: BigInt.from(99500),
        ),
      );

      // The newly-imported wallet doesn't see the legacy row.
      expect(await db.getAllSwaps(walletId: 'wallet-fresh'), isEmpty);

      // But the row is still on disk for audit recoverability.
      expect(await db.select(db.swaps).get(), hasLength(1));
      expect(
        (await db.select(db.swaps).get()).single.walletId,
        'unknown',
      );
    },
  );

  test(
    'findPendingPegInByDepositAddress is scoped per wallet',
    () async {
      final auditA = auditFor('wallet-A');
      await auditA.recordPending(
        provider: 'breez',
        direction: 'btc_to_lbtc',
        sendAsset: 'BTC',
        receiveAsset: 'LBTC',
        sendAmount: BigInt.from(50000),
        receiveAmount: BigInt.from(49500),
        metadata: {'depositAddress': 'bc1qshared'},
      );

      // Wallet B uses the same Breez address by coincidence — it must NOT
      // hit wallet A's pending row.
      final foundForB = await db.findPendingPegInByDepositAddress(
        walletId: 'wallet-B',
        provider: 'breez',
        depositAddress: 'bc1qshared',
      );
      expect(foundForB, isNull);

      final foundForA = await db.findPendingPegInByDepositAddress(
        walletId: 'wallet-A',
        provider: 'breez',
        depositAddress: 'bc1qshared',
      );
      expect(foundForA, isNotNull);
    },
  );

  test('walletId clear → next id triggers a fresh scope', () async {
    final fakeService = FakeWalletIdService('wallet-old');
    final audit = SwapAuditRepositoryImpl(db, logger, fakeService);

    final oldId =
        (await audit.recordPending(
          provider: 'breez',
          direction: 'lbtc_to_btc',
          sendAsset: 'LBTC',
          receiveAsset: 'BTC',
          sendAmount: BigInt.from(100),
          receiveAmount: BigInt.from(95),
        )).getRight().getOrElse(() => -1);
    expect(oldId, greaterThan(0));

    // Simulate deleteWallet wiping the walletId. A subsequent call returns
    // the new sentinel id and writes under that new scope.
    await fakeService.clear();

    await audit.recordCompleted(
      provider: 'breez',
      direction: 'lbtc_to_btc',
      sendAsset: 'LBTC',
      receiveAsset: 'BTC',
      sendAmount: BigInt.from(100),
      receiveAmount: BigInt.from(95),
      txId: 'after-wipe',
    );

    expect(await db.getAllSwaps(walletId: 'wallet-old'), hasLength(1));
    expect(
      await db.getAllSwaps(walletId: 'wallet-test-cleared'),
      hasLength(1),
    );
  });
}
