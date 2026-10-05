import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/utils/swap_unifier.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

Transaction _tx({
  required String id,
  required int amount,
  required Blockchain blockchain,
  required Asset asset,
  required TransactionType type,
  TransactionStatus status = TransactionStatus.confirmed,
  required DateTime createdAt,
  Asset? fromAsset,
  Asset? toAsset,
  int? sentAmount,
  int? receivedAmount,
  String? destination,
}) =>
    Transaction(
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
      receivedAmount:
          receivedAmount == null ? null : BigInt.from(receivedAmount),
      destination: destination,
    );

void main() {
  group('unifyPegSwaps', () {
    test('collapses Breez peg-in cluster from the field log into one row', () {
      // Mirrors the exact transactions the user pasted: anchor +
      // BDK send + dual-rail Liquid claim + an unrelated prior funding
      // receive.
      final claimAt = DateTime(2026, 5, 22, 19, 53, 10);
      final sendAt = DateTime(2026, 5, 22, 19, 51, 6);
      final anchorAt = DateTime(2026, 5, 22, 19, 33, 54);
      final priorAt = DateTime(2026, 5, 22, 19, 31, 32);

      final input = [
        _tx(
          id: 'd7cb7047e856be5f0a9160b1024cf70aa064355a6a313390b524a1a8a3d99b80',
          amount: 27379,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: claimAt,
        ),
        _tx(
          id: 'd7cb7047e856be5f0a9160b1024cf70aa064355a6a313390b524a1a8a3d99b80',
          amount: 27379,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: claimAt,
        ),
        _tx(
          id: 'e6f7f6f5c25c8f79f9cf745f3bfbf9e179e3f666f7907ec0305ea134c064df5e',
          amount: 28000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: sendAt,
        ),
        _tx(
          id: 'wCaunaTNZaHv',
          amount: 27379,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          status: TransactionStatus.pending,
          createdAt: anchorAt,
        ),
        _tx(
          id: 'a71edf04994ced6eb765c08fe69542d9ef8366395839cc66df5d5f654c7ac102',
          amount: 28000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: priorAt,
        ),
      ];

      final out = unifyPegSwaps(input);

      // 1 unified swap + 1 prior funding receive = 2 rows total.
      expect(out, hasLength(2));

      final swap = out.firstWhere((t) => t.type == TransactionType.swap);
      expect(swap.id, 'wCaunaTNZaHv');
      expect(swap.swapDirection, SwapDirection.pegIn);
      expect(swap.fromAsset, Asset.btc);
      expect(swap.toAsset, Asset.lbtc);
      expect(swap.sentAmount, BigInt.from(28000));
      expect(swap.receivedAmount, BigInt.from(27379));
      expect(swap.sendBlockchain, Blockchain.bitcoin);
      expect(swap.receiveBlockchain, Blockchain.liquid);
      expect(
        swap.sendTxId,
        'e6f7f6f5c25c8f79f9cf745f3bfbf9e179e3f666f7907ec0305ea134c064df5e',
      );
      expect(
        swap.receiveTxId,
        'd7cb7047e856be5f0a9160b1024cf70aa064355a6a313390b524a1a8a3d99b80',
      );
      expect(swap.btcTransactionIds, hasLength(1));
      expect(swap.lbtcTransactionIds, hasLength(1));
      // The anchor itself (recorded when the swap was created) is
      // earlier than either chain-side leg here, so it sets the
      // unified row's timestamp.
      expect(swap.createdAt, anchorAt);

      // The unrelated prior funding tx stays in history.
      final remaining = out.firstWhere((t) => t.type != TransactionType.swap);
      expect(
        remaining.id,
        'a71edf04994ced6eb765c08fe69542d9ef8366395839cc66df5d5f654c7ac102',
      );
    });

    test('collapses peg-out (LBTC send + BTC receive) when anchor present', () {
      final t0 = DateTime(2026, 4, 1, 12, 0, 0);

      final input = [
        _tx(
          id: 'pegOutAnchorId',
          amount: 50000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.send,
          status: TransactionStatus.pending,
          createdAt: t0,
        ),
        _tx(
          id: 'aa' * 32,
          amount: 50000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.send,
          createdAt: t0.add(const Duration(minutes: 1)),
        ),
        _tx(
          id: 'bb' * 32,
          amount: 49000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: t0.add(const Duration(minutes: 20)),
        ),
      ];

      final out = unifyPegSwaps(input);

      expect(out, hasLength(1));
      final swap = out.single;
      expect(swap.type, TransactionType.swap);
      expect(swap.swapDirection, SwapDirection.pegOut);
      expect(swap.fromAsset, Asset.lbtc);
      expect(swap.toAsset, Asset.btc);
      expect(swap.sentAmount, BigInt.from(50000));
      expect(swap.receivedAmount, BigInt.from(49000));
      expect(swap.sendTxId, 'aa' * 32);
      expect(swap.receiveTxId, 'bb' * 32);
    });

    test('falls back to amount/time pairing when no Breez anchor is present',
        () {
      final t0 = DateTime(2026, 4, 1, 12, 0, 0);

      final input = [
        _tx(
          id: 'cc' * 32,
          amount: 100000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: t0,
        ),
        _tx(
          id: 'dd' * 32,
          amount: 99500,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: t0.add(const Duration(minutes: 30)),
        ),
      ];

      final out = unifyPegSwaps(input);

      expect(out, hasLength(1));
      expect(out.single.type, TransactionType.swap);
      expect(out.single.fromAsset, Asset.btc);
      expect(out.single.toAsset, Asset.lbtc);
    });

    test('passes through pre-formed asset swaps (e.g. LBTC → DePix)', () {
      final t0 = DateTime(2026, 4, 1, 12, 0, 0);
      final existing = _tx(
        id: 'b1fdb2b67d2e1e1e58317f424484e03ba99395bcfaa91310683847a59ff669cd',
        amount: 340,
        blockchain: Blockchain.liquid,
        asset: Asset.lbtc,
        type: TransactionType.swap,
        createdAt: t0,
        fromAsset: Asset.lbtc,
        toAsset: Asset.depix,
        sentAmount: 340,
        receivedAmount: 99967895,
      );

      final out = unifyPegSwaps([existing]);

      expect(out, hasLength(1));
      expect(out.single.id, existing.id);
      expect(out.single.fromAsset, Asset.lbtc);
      expect(out.single.toAsset, Asset.depix);
    });

    test('does not pair sub-25k-sat sends as fallback swaps', () {
      final t0 = DateTime(2026, 4, 1, 12, 0, 0);

      final input = [
        _tx(
          id: 'tinyBtcSend',
          amount: 1000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: t0,
        ),
        _tx(
          id: 'tinyLbtcReceive',
          amount: 1000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: t0.add(const Duration(minutes: 1)),
        ),
      ];

      final out = unifyPegSwaps(input);

      expect(out, hasLength(2));
      expect(out.any((t) => t.type == TransactionType.swap), isFalse);
    });

    test('keeps unified row pending while either leg is still pending', () {
      final t0 = DateTime(2026, 4, 1, 12, 0, 0);

      final input = [
        _tx(
          id: 'anchorPending',
          amount: 30000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          status: TransactionStatus.pending,
          createdAt: t0,
        ),
        _tx(
          id: 'ee' * 32,
          amount: 30500,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: t0.add(const Duration(minutes: 5)),
        ),
        _tx(
          id: 'ff' * 32,
          amount: 30000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          status: TransactionStatus.pending,
          createdAt: t0.add(const Duration(minutes: 20)),
        ),
      ];

      final out = unifyPegSwaps(input);

      expect(out, hasLength(1));
      expect(out.single.status, TransactionStatus.pending);
    });

    test('returns the input List by reference when no pegs are present', () {
      final t0 = DateTime(2026, 4, 1, 12, 0, 0);
      final input = <Transaction>[
        _tx(
          id: 'aa' * 32,
          amount: 5000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: t0,
        ),
        _tx(
          id: 'bb' * 32,
          amount: 1500,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.send,
          createdAt: t0.add(const Duration(minutes: 5)),
        ),
      ];

      // The fast path is the perf-critical contract: identical
      // reference means Riverpod listeners short-circuit.
      expect(identical(unifyPegSwaps(input), input), isTrue);
    });

    test('pairs a refunded peg-in (BTC send + BTC receive) into a refund row',
        () {
      // Mirrors the user's screenshot: 3 153-sat BDK send to a Boltz
      // lockup followed ~9h later by a 2 802-sat refund credit back
      // to the wallet. With nothing else in the list, the unifier
      // should collapse them into a single same-asset swap row.
      final sendAt = DateTime(2026, 5, 23, 4, 10);
      final refundAt = DateTime(2026, 5, 23, 13, 45);

      final input = [
        _tx(
          id: 'aa' * 32,
          amount: 3153,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: sendAt,
        ),
        _tx(
          id: 'bb' * 32,
          amount: 2802,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: refundAt,
        ),
      ];

      final out = unifyPegSwaps(input);

      expect(out, hasLength(1));
      final refund = out.single;
      expect(refund.type, TransactionType.swap);
      expect(refund.fromAsset, Asset.btc);
      expect(refund.toAsset, Asset.btc); // same-asset = refund signal
      expect(refund.sentAmount, BigInt.from(3153));
      expect(refund.receivedAmount, BigInt.from(2802));
      expect(refund.sendTxId, 'aa' * 32);
      expect(refund.receiveTxId, 'bb' * 32);
      expect(refund.sendBlockchain, Blockchain.bitcoin);
      expect(refund.receiveBlockchain, Blockchain.bitcoin);
    });

    test('refund detection ignores a receive that is LARGER than the send',
        () {
      // A receive >= send is not a refund (Boltz always deducts a
      // fee); it's a coincidentally-timed unrelated incoming tx.
      final sendAt = DateTime(2026, 5, 23, 4, 10);
      final out = unifyPegSwaps([
        _tx(
          id: 'aa' * 32,
          amount: 3000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: sendAt,
        ),
        _tx(
          id: 'bb' * 32,
          amount: 5000, // larger — definitely not a refund
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: sendAt.add(const Duration(hours: 2)),
        ),
      ]);
      expect(out, hasLength(2));
      expect(out.every((t) => t.type != TransactionType.swap), isTrue);
    });

    test('refund detection requires receive AFTER send', () {
      // A BTC receive that arrived before the send can't be the
      // refund of that send — it's the user's funding tx (the one
      // that paid for the lockup in the first place).
      final sendAt = DateTime(2026, 5, 23, 4, 10);
      final out = unifyPegSwaps([
        _tx(
          id: 'aa' * 32,
          amount: 3000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: sendAt,
        ),
        _tx(
          id: 'bb' * 32,
          amount: 2800,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: sendAt.subtract(const Duration(hours: 1)),
        ),
      ]);
      expect(out, hasLength(2));
      expect(out.every((t) => t.type != TransactionType.swap), isTrue);
    });

    test(
        'successful cross-chain peg-in takes precedence over refund detection',
        () {
      // If both a refunded peg-in (BTC→BTC) and a successful peg-in
      // (BTC→LBTC) could be inferred from the same send, the
      // successful one wins because cross-chain pairing runs first.
      final t0 = DateTime(2026, 5, 23, 4, 0);
      final out = unifyPegSwaps([
        _tx(
          id: 'aa' * 32,
          amount: 50000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
          createdAt: t0,
        ),
        _tx(
          id: 'bb' * 32,
          amount: 49500,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: t0.add(const Duration(minutes: 30)),
        ),
        // A BTC receive of a refund-like amount that would otherwise
        // also pair with the send — must lose to the LBTC match.
        _tx(
          id: 'cc' * 32,
          amount: 48000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: t0.add(const Duration(hours: 1)),
        ),
      ]);
      expect(out, hasLength(2)); // unified peg + unrelated BTC receive
      final swap = out.firstWhere((t) => t.type == TransactionType.swap);
      expect(swap.toAsset, Asset.lbtc); // cross-chain success, not refund
      expect(swap.fromAsset, Asset.btc);
    });

    test(
        'L-BTC send + smaller L-BTC receive is NEVER classified as a refund',
        () {
      final sendAt = DateTime(2026, 5, 23, 4, 10);
      final out = unifyPegSwaps([
        _tx(
          id: 'aa' * 32,
          amount: 50000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.send,
          createdAt: sendAt,
        ),
        _tx(
          id: 'bb' * 32,
          amount: 47500,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: sendAt.add(const Duration(hours: 4)),
        ),
      ]);
      expect(out, hasLength(2));
      expect(out.every((t) => t.type != TransactionType.swap), isTrue);
      expect(
        out.every((t) => !(t.fromAsset == Asset.lbtc && t.toAsset == Asset.lbtc)),
        isTrue,
        reason: 'No L-BTC same-asset refund row should ever be emitted.',
      );
    });

    test('isPegSwap getter is false for asset-swap rows (LBTC → DePix)', () {
      final t0 = DateTime(2026, 4, 1, 12, 0, 0);
      final assetSwap = _tx(
        id: 'assetSwap',
        amount: 340,
        blockchain: Blockchain.liquid,
        asset: Asset.lbtc,
        type: TransactionType.swap,
        createdAt: t0,
        fromAsset: Asset.lbtc,
        toAsset: Asset.depix,
        sentAmount: 340,
        receivedAmount: 99967895,
      );

      expect(assetSwap.isPegSwap, isFalse);
      expect(assetSwap.swapDirection, isNull);
      expect(assetSwap.btcTransactionIds, isEmpty);
      expect(assetSwap.lbtcTransactionIds, isEmpty);
    });
  });
}
