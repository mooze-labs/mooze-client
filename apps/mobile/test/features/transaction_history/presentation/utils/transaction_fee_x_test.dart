import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/utils/transaction_fee_x.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Builds a minimal [Transaction] for fee-presentation tests. Only the
/// fields that affect [TransactionFeeX] (type, blockchain, `feesSat`) carry
/// meaning here; the rest are filled with inert defaults.
Transaction _tx({
  required Blockchain blockchain,
  required Asset asset,
  required TransactionType type,
  BigInt? feesSat,
}) =>
    Transaction(
      id: 'tx',
      amount: BigInt.from(100000),
      blockchain: blockchain,
      asset: asset,
      type: type,
      status: TransactionStatus.confirmed,
      createdAt: DateTime(2026, 1, 1),
      feesSat: feesSat,
    );

void main() {
  group('TransactionFeeX.totalFeeSat', () {
    test('on-chain Bitcoin send exposes the mining fee', () {
      final tx = _tx(
        blockchain: Blockchain.bitcoin,
        asset: Asset.btc,
        type: TransactionType.send,
        feesSat: BigInt.from(450),
      );
      expect(tx.totalFeeSat, BigInt.from(450));
      expect(tx.hasDisplayableFee, isTrue);
    });

    test('on-chain Bitcoin receive exposes the mining fee', () {
      final tx = _tx(
        blockchain: Blockchain.bitcoin,
        asset: Asset.btc,
        type: TransactionType.receive,
        feesSat: BigInt.from(120),
      );
      expect(tx.totalFeeSat, BigInt.from(120));
    });

    test('Lightning payment exposes the routing fee', () {
      final tx = _tx(
        blockchain: Blockchain.lightning,
        asset: Asset.lbtc,
        type: TransactionType.send,
        feesSat: BigInt.from(7),
      );
      expect(tx.totalFeeSat, BigInt.from(7));
    });

    test('Liquid transaction exposes the Liquid network fee', () {
      final tx = _tx(
        blockchain: Blockchain.liquid,
        asset: Asset.lbtc,
        type: TransactionType.send,
        feesSat: BigInt.from(26),
      );
      expect(tx.totalFeeSat, BigInt.from(26));
    });

    test('swap exposes the aggregated total fee', () {
      final tx = _tx(
        blockchain: Blockchain.liquid,
        asset: Asset.lbtc,
        type: TransactionType.swap,
        feesSat: BigInt.from(3200),
      );
      expect(tx.totalFeeSat, BigInt.from(3200));
    });

    test('peg-in (submarine, receive) exposes the total operation fee', () {
      final tx = _tx(
        blockchain: Blockchain.bitcoin,
        asset: Asset.btc,
        type: TransactionType.submarine,
        feesSat: BigInt.from(1500),
      );
      expect(tx.totalFeeSat, BigInt.from(1500));
    });

    test('peg-out (submarine, send) exposes the total operation fee', () {
      final tx = _tx(
        blockchain: Blockchain.bitcoin,
        asset: Asset.btc,
        type: TransactionType.submarine,
        feesSat: BigInt.from(2100),
      );
      expect(tx.totalFeeSat, BigInt.from(2100));
    });

    test('a one-sat fee is preserved (boundary)', () {
      final tx = _tx(
        blockchain: Blockchain.lightning,
        asset: Asset.lbtc,
        type: TransactionType.send,
        feesSat: BigInt.one,
      );
      expect(tx.totalFeeSat, BigInt.one);
    });

    group('hidden fee section', () {
      // No fee information and a zero fee both collapse to `null` so the
      // UI omits the section rather than showing a misleading "0 sats".
      test('null fee → null (no SDK fee data)', () {
        final tx = _tx(
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          feesSat: null,
        );
        expect(tx.totalFeeSat, isNull);
        expect(tx.hasDisplayableFee, isFalse);
      });

      test('zero fee → null', () {
        final tx = _tx(
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          feesSat: BigInt.zero,
        );
        expect(tx.totalFeeSat, isNull);
        expect(tx.hasDisplayableFee, isFalse);
      });

      test('negative fee → null (defensive)', () {
        final tx = _tx(
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          feesSat: BigInt.from(-10),
        );
        expect(tx.totalFeeSat, isNull);
      });
    });
  });
}
