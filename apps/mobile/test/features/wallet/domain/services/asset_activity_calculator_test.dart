import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/services/asset_activity_calculator.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

Transaction _tx({
  required String id,
  required int amount,
  required Asset asset,
  required TransactionType type,
  Blockchain blockchain = Blockchain.bitcoin,
  TransactionStatus status = TransactionStatus.confirmed,
  required DateTime createdAt,
  Asset? fromAsset,
  Asset? toAsset,
  int? sentAmount,
  int? receivedAmount,
}) => Transaction(
  id: id,
  amount: BigInt.from(amount),
  blockchain: blockchain,
  asset: asset,
  type: type,
  status: status,
  createdAt: createdAt,
  fromAsset: fromAsset,
  toAsset: toAsset,
  sentAmount: sentAmount == null ? null : BigInt.from(sentAmount),
  receivedAmount: receivedAmount == null ? null : BigInt.from(receivedAmount),
);

void main() {
  group('AssetActivityCalculator.filterForAsset', () {
    test('keeps headline-asset rows and swaps touching the asset on any leg',
        () {
      final txs = [
        _tx(
          id: 'recv-btc',
          amount: 100,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: DateTime(2024, 1, 1),
        ),
        _tx(
          id: 'recv-usdt',
          amount: 200,
          asset: Asset.usdt,
          type: TransactionType.receive,
          createdAt: DateTime(2024, 1, 2),
        ),
        // Peg-out: L-BTC -> BTC. Headline asset btc, fromAsset lbtc.
        _tx(
          id: 'peg-out',
          amount: 50,
          asset: Asset.btc,
          type: TransactionType.swap,
          createdAt: DateTime(2024, 1, 3),
          fromAsset: Asset.lbtc,
          toAsset: Asset.btc,
          sentAmount: 55,
          receivedAmount: 50,
        ),
      ];

      final btc = AssetActivityCalculator.filterForAsset(Asset.btc, txs);
      expect(btc.map((t) => t.id), ['recv-btc', 'peg-out']);

      // The peg-out also belongs to L-BTC via its fromAsset leg.
      final lbtc = AssetActivityCalculator.filterForAsset(Asset.lbtc, txs);
      expect(lbtc.map((t) => t.id), ['peg-out']);
    });
  });

  group('AssetActivityCalculator.summarize', () {
    test('returns an empty summary when no transaction involves the asset',
        () {
      final summary = AssetActivityCalculator.summarize(
        asset: Asset.btc,
        transactions: [
          _tx(
            id: 'usdt',
            amount: 10,
            asset: Asset.usdt,
            type: TransactionType.receive,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );

      expect(summary.hasActivity, isFalse);
      expect(summary.transactionCount, 0);
      expect(summary.totalReceived, BigInt.zero);
      expect(summary.totalVolume, BigInt.zero);
      expect(summary.firstActivity, isNull);
      expect(summary.lastActivity, isNull);
    });

    test('aggregates received, sent, volume, largest legs and timeline', () {
      final txs = [
        _tx(
          id: 'r1',
          amount: 30,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: DateTime(2024, 3, 12, 9),
        ),
        _tx(
          id: 'r2',
          amount: 80,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: DateTime(2024, 4, 1, 10),
        ),
        _tx(
          id: 's1',
          amount: 50,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: DateTime(2024, 5, 20, 18, 42),
        ),
      ];

      final s = AssetActivityCalculator.summarize(
        asset: Asset.btc,
        transactions: txs,
      );

      expect(s.transactionCount, 3);
      expect(s.totalReceived, BigInt.from(110));
      expect(s.totalSent, BigInt.from(50));
      expect(s.totalVolume, BigInt.from(160));
      expect(s.largestReceive, BigInt.from(80));
      expect(s.largestSend, BigInt.from(50));
      expect(s.firstActivity, DateTime(2024, 3, 12, 9));
      expect(s.lastActivity, DateTime(2024, 5, 20, 18, 42));
    });

    test('counts swap legs toward the matching asset using per-leg amounts',
        () {
      // BTC -> L-BTC peg-in: L-BTC receives 95, BTC sends 100.
      final pegIn = _tx(
        id: 'peg-in',
        amount: 95,
        asset: Asset.lbtc,
        type: TransactionType.swap,
        createdAt: DateTime(2024, 2, 1),
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: 100,
        receivedAmount: 95,
      );

      final lbtc = AssetActivityCalculator.summarize(
        asset: Asset.lbtc,
        transactions: [pegIn],
      );
      expect(lbtc.totalReceived, BigInt.from(95));
      expect(lbtc.totalSent, BigInt.zero);

      final btc = AssetActivityCalculator.summarize(
        asset: Asset.btc,
        transactions: [pegIn],
      );
      expect(btc.totalSent, BigInt.from(100));
      expect(btc.totalReceived, BigInt.zero);
    });

    test('excludes failed transactions from monetary totals but keeps them in '
        'the count and timeline', () {
      final txs = [
        _tx(
          id: 'ok',
          amount: 40,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: DateTime(2024, 6, 1),
        ),
        _tx(
          id: 'failed',
          amount: 999,
          asset: Asset.btc,
          type: TransactionType.send,
          status: TransactionStatus.failed,
          createdAt: DateTime(2024, 6, 5),
        ),
      ];

      final s = AssetActivityCalculator.summarize(
        asset: Asset.btc,
        transactions: txs,
      );

      expect(s.transactionCount, 2);
      expect(s.totalSent, BigInt.zero);
      expect(s.totalReceived, BigInt.from(40));
      expect(s.lastActivity, DateTime(2024, 6, 5));
    });

    test('ignores redeposit and unknown rows in value aggregates', () {
      final txs = [
        _tx(
          id: 'redeposit',
          amount: 7,
          asset: Asset.lbtc,
          type: TransactionType.redeposit,
          blockchain: Blockchain.liquid,
          createdAt: DateTime(2024, 7, 1),
        ),
        _tx(
          id: 'unknown',
          amount: 3,
          asset: Asset.lbtc,
          type: TransactionType.unknown,
          blockchain: Blockchain.liquid,
          createdAt: DateTime(2024, 7, 2),
        ),
      ];

      final s = AssetActivityCalculator.summarize(
        asset: Asset.lbtc,
        transactions: txs,
      );

      expect(s.transactionCount, 2);
      expect(s.totalReceived, BigInt.zero);
      expect(s.totalSent, BigInt.zero);
      expect(s.totalVolume, BigInt.zero);
    });
  });
}
