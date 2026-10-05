import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/utils/peg_evidence.dart';
import 'package:mooze_mobile/features/wallet/presentation/utils/swap_unifier.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final _t0 = DateTime.utc(2026, 8, 19, 12);

String _txid(String seed) => seed.padRight(64, '0');

final _btcSendId = _txid('aa');
final _lbtcRecvId = _txid('bb');
final _lbtcSendId = _txid('cc');
final _btcRecvId = _txid('dd');
final _strangerId = _txid('ee');

Transaction _tx({
  required String id,
  required int amount,
  required Blockchain blockchain,
  required Asset asset,
  required TransactionType type,
  TransactionStatus status = TransactionStatus.confirmed,
  DateTime? createdAt,
  String? destination,
}) => Transaction(
  id: id,
  amount: BigInt.from(amount),
  blockchain: blockchain,
  asset: asset,
  type: type,
  status: status,
  createdAt: createdAt ?? _t0,
  destination: destination,
);

PegRecord _record({
  String orderId = 'order-1',
  bool isPegIn = true,
  int amountSat = 100000,
  String status = pegEvidenceStatusPending,
  String? depositAddress,
  String? fundingTxId,
  String? payoutTxId,
}) => PegRecord(
  orderId: orderId,
  isPegIn: isPegIn,
  amountSat: BigInt.from(amountSat),
  createdAt: _t0,
  status: status,
  depositAddress: depositAddress,
  payoutAddress: 'lq1our-address',
  fundingTxId: fundingTxId,
  payoutTxId: payoutTxId,
);

/// A clean peg-in pair: BTC send out, L-BTC receive back, ~2% fee, 5 min apart.
/// Inside the existing ±10% / 30 min heuristic window, so the join pairs it
/// with or without evidence — which is what lets us compare the two.
List<Transaction> _pegInPair() => [
  _tx(
    id: _btcSendId,
    amount: 100000,
    blockchain: Blockchain.bitcoin,
    asset: Asset.btc,
    type: TransactionType.send,
    destination: 'bc1sideswap-deposit',
  ),
  _tx(
    id: _lbtcRecvId,
    amount: 98000,
    blockchain: Blockchain.liquid,
    asset: Asset.lbtc,
    type: TransactionType.receive,
    createdAt: _t0.add(const Duration(minutes: 5)),
  ),
];

List<Transaction> _pegOutPair() => [
  _tx(
    id: _lbtcSendId,
    amount: 100000,
    blockchain: Blockchain.liquid,
    asset: Asset.lbtc,
    type: TransactionType.send,
    destination: 'lq1sideswap-deposit',
  ),
  _tx(
    id: _btcRecvId,
    amount: 98000,
    blockchain: Blockchain.bitcoin,
    asset: Asset.btc,
    type: TransactionType.receive,
    createdAt: _t0.add(const Duration(minutes: 5)),
  ),
];

Transaction _onlySwap(List<Transaction> rows) =>
    rows.singleWhere((t) => t.type == TransactionType.swap);

void main() {
  group('PegEvidence.validatePair', () {
    test('confirms when both legs match one order', () {
      final ev = PegEvidence([
        _record(fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
      ]);

      final check = ev.validatePair(
        sendTxId: _btcSendId,
        receiveTxId: _lbtcRecvId,
        isPegIn: true,
      );

      expect(check.isConfirmed, isTrue);
      expect(check.record?.orderId, 'order-1');
    });

    test('rejects legs that belong to two different orders', () {
      final ev = PegEvidence([
        _record(orderId: 'order-1', fundingTxId: _btcSendId),
        _record(orderId: 'order-2', payoutTxId: _lbtcRecvId),
      ]);

      final check = ev.validatePair(
        sendTxId: _btcSendId,
        receiveTxId: _lbtcRecvId,
        isPegIn: true,
      );

      expect(check.isRejected, isTrue);
      expect(check.reason, contains('different orders'));
    });

    test('rejects a direction that contradicts the record', () {
      final ev = PegEvidence([
        _record(isPegIn: false, fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
      ]);

      final check = ev.validatePair(
        sendTxId: _btcSendId,
        receiveTxId: _lbtcRecvId,
        isPegIn: true,
      );

      expect(check.isRejected, isTrue);
      expect(check.reason, contains('peg-out'));
    });

    test('rejects inverted legs', () {
      final ev = PegEvidence([
        _record(fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
      ]);

      final check = ev.validatePair(
        sendTxId: _lbtcRecvId,
        receiveTxId: _btcSendId,
        isPegIn: true,
      );

      expect(check.isRejected, isTrue);
      expect(check.reason, contains('swapped'));
    });

    test('rejects a pair built around a failed order', () {
      final ev = PegEvidence([
        _record(
          fundingTxId: _btcSendId,
          status: pegEvidenceStatusFailed,
        ),
      ]);

      final check = ev.validatePair(
        sendTxId: _btcSendId,
        receiveTxId: _strangerId,
        isPegIn: true,
      );

      expect(check.isRejected, isTrue);
      expect(check.reason, contains('failed'));
    });

    test('rejects a pair built around a below-minimum order', () {
      final ev = PegEvidence([
        _record(
          fundingTxId: _btcSendId,
          status: pegEvidenceStatusInsufficientAmount,
        ),
      ]);

      expect(
        ev
            .validatePair(
              sendTxId: _btcSendId,
              receiveTxId: _strangerId,
              isPegIn: true,
            )
            .isRejected,
        isTrue,
      );
    });

    test('confirms via deposit address when the funding txid was not recorded',
        () {
      final ev = PegEvidence([
        _record(depositAddress: 'bc1sideswap-deposit'),
      ]);

      final check = ev.validatePair(
        sendTxId: _btcSendId,
        receiveTxId: _lbtcRecvId,
        isPegIn: true,
        sendDestination: 'bc1sideswap-deposit',
      );

      expect(check.isConfirmed, isTrue);
    });

    test('abstains when no record mentions either leg', () {
      final ev = PegEvidence([_record(fundingTxId: _txid('99'))]);

      final check = ev.validatePair(
        sendTxId: _btcSendId,
        receiveTxId: _lbtcRecvId,
        isPegIn: true,
      );

      expect(check.isAbstain, isTrue);
    });

    test('abstains when there are no records at all', () {
      expect(
        PegEvidence.empty()
            .validatePair(
              sendTxId: _btcSendId,
              receiveTxId: _lbtcRecvId,
              isPegIn: true,
            )
            .isAbstain,
        isTrue,
      );
    });
  });

  group('PegRecord', () {
    test('joinableRecords excludes unpaid and half-recorded orders', () {
      final ev = PegEvidence([
        _record(orderId: 'ok', fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
        _record(orderId: 'half', fundingTxId: _txid('11')),
        _record(
          orderId: 'failed',
          fundingTxId: _txid('22'),
          payoutTxId: _txid('33'),
          status: pegEvidenceStatusFailed,
        ),
      ]);

      expect(ev.joinableRecords.map((r) => r.orderId), ['ok']);
    });

    test('legFor distinguishes funding from payout', () {
      final r = _record(fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId);

      expect(r.legFor(_btcSendId), PegLeg.funding);
      expect(r.legFor(_lbtcRecvId), PegLeg.payout);
      expect(r.legFor(_strangerId), isNull);
    });
  });

  group('unifyPegSwaps with evidence', () {
    test('joins a peg-in by exact txid, bypassing the heuristics', () {
      final out = unifyPegSwaps(
        _pegInPair(),
        evidence: PegEvidence([
          _record(fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
        ]),
      );

      final swap = _onlySwap(out);
      expect(out, hasLength(1));
      expect(swap.fromAsset, Asset.btc);
      expect(swap.toAsset, Asset.lbtc);
      expect(swap.sendTxId, _btcSendId);
      expect(swap.receiveTxId, _lbtcRecvId);
      expect(swap.sentAmount, BigInt.from(100000));
      expect(swap.receivedAmount, BigInt.from(98000));
      expect(swap.sendBlockchain, Blockchain.bitcoin);
      expect(swap.receiveBlockchain, Blockchain.liquid);
    });

    test('joins a peg-out by exact txid with the right direction', () {
      final out = unifyPegSwaps(
        _pegOutPair(),
        evidence: PegEvidence([
          _record(
            isPegIn: false,
            fundingTxId: _lbtcSendId,
            payoutTxId: _btcRecvId,
          ),
        ]),
      );

      final swap = _onlySwap(out);
      expect(swap.fromAsset, Asset.lbtc);
      expect(swap.toAsset, Asset.btc);
      expect(swap.sendTxId, _lbtcSendId);
      expect(swap.receiveTxId, _btcRecvId);
      expect(swap.sendBlockchain, Blockchain.liquid);
      expect(swap.receiveBlockchain, Blockchain.bitcoin);
    });

    test(
      'exact-txid join beats a closer-looking heuristic candidate',
      () {
        // An unrelated L-BTC receive that also sits inside the ±10% / 30 min
        // window. `_findFallbackCounterpart` returns the FIRST candidate in
        // bucket order, not the closest — so whichever row the stream happens
        // to deliver first wins the pairing. Here the decoy is delivered
        // first, and the heuristic mispairs.
        final pair = _pegInPair();
        final decoy = _tx(
          id: _strangerId,
          amount: 99000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: _t0.add(const Duration(minutes: 1)),
        );
        final input = [pair.first, decoy, pair.last];

        final heuristicOnly = unifyPegSwaps(input);
        expect(
          _onlySwap(heuristicOnly).receiveTxId,
          _strangerId,
          reason: 'baseline: the heuristic picks the decoy',
        );

        final out = unifyPegSwaps(
          input,
          evidence: PegEvidence([
            _record(fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
          ]),
        );

        final swap = _onlySwap(out);
        expect(swap.receiveTxId, _lbtcRecvId);
        // The decoy survives as its own untouched row.
        expect(
          out.where((t) => t.id == _strangerId),
          hasLength(1),
        );
      },
    );

    test('rejects a pairing the records contradict — the false-positive case',
        () {
      // An unrelated BTC withdrawal and L-BTC deposit that happen to sit in
      // the window. Local records show the BTC send funded a peg that FAILED,
      // so the L-BTC receive cannot be its counterpart.
      final out = unifyPegSwaps(
        _pegInPair(),
        evidence: PegEvidence([
          _record(
            fundingTxId: _btcSendId,
            status: pegEvidenceStatusFailed,
          ),
        ]),
      );

      expect(
        out.where((t) => t.type == TransactionType.swap),
        isEmpty,
        reason: 'no swap row may be invented for a failed peg',
      );
      expect(out.map((t) => t.id), containsAll([_btcSendId, _lbtcRecvId]));
    });

    test('rejects a pairing that mixes two different orders', () {
      final out = unifyPegSwaps(
        _pegInPair(),
        evidence: PegEvidence([
          _record(orderId: 'a', fundingTxId: _btcSendId),
          _record(orderId: 'b', payoutTxId: _lbtcRecvId),
        ]),
      );

      expect(out.where((t) => t.type == TransactionType.swap), isEmpty);
      expect(out, hasLength(2));
    });

    test('rejects a direction the records contradict', () {
      final out = unifyPegSwaps(
        _pegInPair(),
        evidence: PegEvidence([
          // Records say this txid funded a peg-OUT; the join infers peg-in.
          _record(isPegIn: false, fundingTxId: _btcSendId),
        ]),
      );

      expect(out.where((t) => t.type == TransactionType.swap), isEmpty);
    });
  });

  group('fallback: behaviour must be identical without local data', () {
    void expectIdentical(List<Transaction> input, String reason) {
      final withNull = unifyPegSwaps(input);
      final withEmpty = unifyPegSwaps(input, evidence: PegEvidence.empty());
      final unrelated = unifyPegSwaps(
        input,
        // Records exist but mention nothing in this list — a peg from before
        // the transactions being grouped here.
        evidence: PegEvidence([
          _record(orderId: 'other', fundingTxId: _txid('77'), payoutTxId: _txid('88')),
        ]),
      );

      String key(List<Transaction> rows) => rows
          .map(
            (t) => '${t.id}|${t.type.name}|${t.fromAsset}|${t.toAsset}|'
                '${t.sendTxId}|${t.receiveTxId}|${t.amount}',
          )
          .join(';');

      expect(key(withEmpty), key(withNull), reason: '$reason (empty)');
      expect(key(unrelated), key(withNull), reason: '$reason (unrelated)');
    }

    test('peg-in pair groups the same way', () {
      expectIdentical(_pegInPair(), 'peg-in');
      expect(
        unifyPegSwaps(_pegInPair(), evidence: PegEvidence.empty())
            .where((t) => t.type == TransactionType.swap),
        hasLength(1),
        reason: 'heuristic still groups it',
      );
    });

    test('peg-out pair groups the same way', () {
      expectIdentical(_pegOutPair(), 'peg-out');
    });

    test('unrelated single send is left alone', () {
      expectIdentical([
        _tx(
          id: _btcSendId,
          amount: 100000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
        ),
      ], 'lone send');
    });

    test('empty list short-circuits', () {
      final input = <Transaction>[];
      expect(identical(unifyPegSwaps(input, evidence: PegEvidence.empty()), input),
          isTrue);
    });
  });

  group('non-peg swaps are untouched', () {
    test('an in-Liquid asset swap row passes through unchanged', () {
      // LBTC → DePix in ONE transaction: already classified upstream by the
      // LWK mapper. The validation layer must not look at it.
      final assetSwap = Transaction(
        id: _txid('f1'),
        amount: BigInt.from(50000),
        blockchain: Blockchain.liquid,
        asset: Asset.lbtc,
        type: TransactionType.swap,
        status: TransactionStatus.confirmed,
        createdAt: _t0,
        fromAsset: Asset.lbtc,
        toAsset: Asset.depix,
        sentAmount: BigInt.from(50000),
        receivedAmount: BigInt.from(3000),
      );

      final ev = PegEvidence([
        _record(fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
      ]);

      final out = unifyPegSwaps([assetSwap], evidence: ev);

      expect(out, hasLength(1));
      expect(out.single.id, assetSwap.id);
      expect(out.single.toAsset, Asset.depix);
      expect(out.single.isPegSwap, isFalse);
    });

    test('an ordinary send and receive on the same chain stay separate', () {
      final rows = [
        _tx(
          id: _txid('f2'),
          amount: 100000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.send,
        ),
        _tx(
          id: _txid('f3'),
          amount: 98000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: _t0.add(const Duration(minutes: 2)),
        ),
      ];

      final out = unifyPegSwaps(
        rows,
        evidence: PegEvidence([
          _record(fundingTxId: _btcSendId, payoutTxId: _lbtcRecvId),
        ]),
      );

      expect(out.where((t) => t.type == TransactionType.swap), isEmpty);
      expect(out, hasLength(2));
    });

    test('a peg-in record does not group an unrelated L-BTC asset transfer', () {
      final rows = [
        _tx(
          id: _btcSendId,
          amount: 100000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
        ),
        _tx(
          id: _txid('f4'),
          amount: 98000,
          blockchain: Blockchain.liquid,
          asset: Asset.depix,
          type: TransactionType.receive,
          createdAt: _t0.add(const Duration(minutes: 5)),
        ),
      ];

      final out = unifyPegSwaps(
        rows,
        evidence: PegEvidence([_record(fundingTxId: _btcSendId)]),
      );

      // DePix is not L-BTC, so it was never a peg candidate to begin with.
      expect(out.where((t) => t.type == TransactionType.swap), isEmpty);
    });
  });
}
