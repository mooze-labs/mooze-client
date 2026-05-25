import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

Transaction _tx({
  required String id,
  required int amount,
  required Blockchain blockchain,
  required Asset asset,
  required TransactionType type,
  DateTime? createdAt,
  String? sendTxId,
  String? receiveTxId,
  Asset? fromAsset,
  Asset? toAsset,
  int? sentAmount,
}) =>
    Transaction(
      id: id,
      amount: BigInt.from(amount),
      blockchain: blockchain,
      asset: asset,
      type: type,
      status: TransactionStatus.confirmed,
      createdAt: createdAt ?? DateTime.now(),
      sendTxId: sendTxId,
      receiveTxId: receiveTxId,
      fromAsset: fromAsset,
      toAsset: toAsset,
      sentAmount: sentAmount == null ? null : BigInt.from(sentAmount),
    );

Transaction _unifiedSwap({
  required String id,
  required int sentAmount,
  required Asset fromAsset,
  required Asset toAsset,
  DateTime? createdAt,
  String? sendTxId,
  String? receiveTxId,
}) =>
    _tx(
      id: id,
      amount: sentAmount,
      blockchain: toAsset == Asset.btc ? Blockchain.bitcoin : Blockchain.liquid,
      asset: toAsset,
      type: TransactionType.swap,
      createdAt: createdAt,
      sendTxId: sendTxId,
      receiveTxId: receiveTxId,
      fromAsset: fromAsset,
      toAsset: toAsset,
      sentAmount: sentAmount,
    );

// `SharedPreferences.getInstance()` caches the singleton across the
// test process — so `setMockInitialValues` only takes effect on the
// very first call and later tests see stale state. We clear + manually
// re-seed inside the helper to keep every test hermetic.
Future<ProviderContainer> _containerWithEmptyPrefs() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

Future<ProviderContainer> _containerWithSeededPrefs(
  Map<String, Object> initial,
) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  for (final entry in initial.entries) {
    final value = entry.value;
    if (value is String) await prefs.setString(entry.key, value);
    if (value is int) await prefs.setInt(entry.key, value);
    if (value is bool) await prefs.setBool(entry.key, value);
    if (value is double) await prefs.setDouble(entry.key, value);
    if (value is List<String>) await prefs.setStringList(entry.key, value);
  }
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PendingSwapsNotifier', () {
    late ProviderContainer container;
    late PendingSwapsNotifier notifier;

    setUp(() async {
      container = await _containerWithEmptyPrefs();
      notifier = container.read(pendingSwapsProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('start inserts a new pending swap in `preparing` phase', () {
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );

      final state = container.read(pendingSwapsProvider);
      expect(state, hasLength(1));
      expect(state.single.localId, id);
      expect(state.single.phase, PendingSwapPhase.preparing);
      expect(state.single.isPegOut, isTrue);
    });

    test('phase transitions: preparing → broadcasting → broadcasted', () {
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );

      notifier.markBroadcasting(id);
      expect(container.read(pendingSwapsProvider).single.phase,
          PendingSwapPhase.broadcasting);

      notifier.markBroadcasted(
        id,
        breezSwapId: 'swapId123',
        breezTxId: 'aa' * 32,
      );
      final after = container.read(pendingSwapsProvider).single;
      expect(after.phase, PendingSwapPhase.broadcasted);
      expect(after.breezSwapId, 'swapId123');
      expect(after.breezTxId, 'aa' * 32);
    });

    test('reconcileWith drops swaps when both legs of a unified row are paired',
        () {
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );
      notifier.markBroadcasted(id, breezSwapId: 'swapId123');

      notifier.reconcileWith([
        _unifiedSwap(
          id: 'swapId123',
          sentAmount: 49000,
          fromAsset: Asset.lbtc,
          toAsset: Asset.btc,
          sendTxId: 'lbtcSendId',
          receiveTxId: 'btcReceiveId',
        ),
      ]);

      expect(container.read(pendingSwapsProvider), isEmpty);
    });

    test('reconcileWith drops swap when sendTxId on a paired unified row matches',
        () {
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(60000),
        estimatedReceivedAmount: BigInt.from(58000),
      );
      notifier.markBroadcasted(id, breezTxId: 'bb' * 32);

      notifier.reconcileWith([
        _unifiedSwap(
          id: 'someUnifiedId',
          sentAmount: 58000,
          fromAsset: Asset.lbtc,
          toAsset: Asset.btc,
          sendTxId: 'bb' * 32,
          receiveTxId: 'aa' * 32,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), isEmpty);
    });

    test(
        'reconcileWith falls back to amount + time matching against a paired '
        'unified swap row when no ids were captured', () {
      // Simulates `markBroadcasted` never landing (SDK errored after
      // lockup, etc.). The optimistic row has no swap id; once the
      // unifier eventually produces the fully-paired swap row, the
      // amount + time fallback drops the optimistic.
      notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(70000),
        estimatedReceivedAmount: BigInt.from(67000),
      );
      final pendingCreatedAt =
          container.read(pendingSwapsProvider).single.createdAt;

      notifier.reconcileWith([
        _unifiedSwap(
          id: 'unifiedFallback',
          sentAmount: 70000,
          fromAsset: Asset.lbtc,
          toAsset: Asset.btc,
          sendTxId: 'lbtcSend',
          receiveTxId: 'btcReceive',
          createdAt: pendingCreatedAt.add(const Duration(seconds: 30)),
        ),
        // Same shape, but a historical row from a previous swap —
        // must be ignored by the "must be after pending" guard.
        _unifiedSwap(
          id: 'unrelatedSwap',
          sentAmount: 70000,
          fromAsset: Asset.lbtc,
          toAsset: Asset.btc,
          sendTxId: 'oldSend',
          receiveTxId: 'oldReceive',
          createdAt: pendingCreatedAt.subtract(const Duration(days: 5)),
        ),
      ]);

      expect(container.read(pendingSwapsProvider), isEmpty);
    });

    test(
        'reconcileWith does NOT drop on a partial unified row (sendTxId set, '
        'receiveTxId null) — the destination leg hasn\'t landed yet', () {
      // The unifier produces a "partial" unified swap row when only
      // the send leg is observed (anchor present, claim still
      // pending). That partial row tells the unifier's story but not
      // the user's — the destination funds haven't actually arrived
      // yet, so the optimistic row must stay.
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
      );
      notifier.markBroadcasted(id, breezTxId: 'cc' * 32);

      notifier.reconcileWith([
        _unifiedSwap(
          id: 'wCaunaTNZaHv',
          sentAmount: 28000,
          fromAsset: Asset.btc,
          toAsset: Asset.lbtc,
          sendTxId: 'cc' * 32,
          // receiveTxId intentionally null — the LBTC claim hasn't
          // landed yet.
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
    });

    test(
        'reconcileWith does NOT match a historical LBTC receive from a '
        'previous swap (regression: new peg-in for similar amount used to '
        'collapse into the prior session\'s claim)', () {
      // Simulates the wallet's persisted history containing an LBTC
      // receive from a previous test peg-in. A brand-new peg-in for
      // a similar amount used to falsely match that historical
      // receive the instant the home list rendered, retiring the
      // optimistic row immediately and leaving the user with a bare
      // "BTC sent pending" row.
      final yesterday = DateTime.now().subtract(const Duration(hours: 6));
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
      );
      notifier.markBroadcasted(id, breezTxId: 'cc' * 32);

      notifier.reconcileWith([
        // Historical LBTC receive from a previous peg-in — similar
        // amount, within ±12h of "now", but BEFORE the optimistic
        // was created. Must NOT trigger reconciliation.
        _tx(
          id: 'prevLbtcClaim',
          amount: 27379,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: yesterday,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
    });

    test(
        'reconcileWith drops on a real LBTC receive landing after the pending '
        'was created (peg-in success case)', () {
      notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
      );
      final pendingCreatedAt =
          container.read(pendingSwapsProvider).single.createdAt;

      notifier.reconcileWith([
        _tx(
          id: 'realLbtcClaim',
          amount: 27379,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: pendingCreatedAt.add(const Duration(minutes: 40)),
        ),
      ]);

      expect(container.read(pendingSwapsProvider), isEmpty);
    });

    test('reconcileWith does NOT drop pending peg-in on a raw BDK send leg',
        () {
      // This is the asymmetry vs peg-out: for peg-in the BDK send tx
      // surfaces in the persisted list long before the LBTC claim
      // arrives. If reconciliation dropped on the raw send leg the
      // user would lose the swap context for the rest of the swap.
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
      );
      notifier.markBroadcasted(id, breezTxId: 'cc' * 32);

      notifier.reconcileWith([
        // Raw BDK send leg with the captured txid — but no unified
        // swap row yet.
        _tx(
          id: 'cc' * 32,
          amount: 28000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
      expect(container.read(pendingSwapsProvider).single.phase,
          PendingSwapPhase.broadcasted);
    });

    test('reconcileWith drops pending peg-in when unified swap row arrives',
        () {
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
      );
      notifier.markBroadcasted(id, breezTxId: 'cc' * 32);

      notifier.reconcileWith([
        // Raw BDK send leg still in the list…
        _tx(
          id: 'cc' * 32,
          amount: 28000,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.send,
        ),
        // …plus the unifier's paired row. This one matches the
        // pending swap by `sendTxId` and direction.
        _unifiedSwap(
          id: 'wCaunaTNZaHv', // Breez anchor id
          sentAmount: 28000,
          fromAsset: Asset.btc,
          toAsset: Asset.lbtc,
          sendTxId: 'cc' * 32,
          receiveTxId: 'dd' * 32,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), isEmpty);
    });

    test('reconcileWith does NOT drop peg-out optimistic row on a raw LWK send',
        () {
      // Symmetric guard: a raw LBTC send leg arriving without the
      // unified swap row must not retire the optimistic peg-out.
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );
      notifier.markBroadcasted(id, breezTxId: 'ee' * 32);

      notifier.reconcileWith([
        _tx(
          id: 'ee' * 32,
          amount: 50000,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.send,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
    });

    test(
        'reconcileWith does NOT cross-match peg-in optimistic vs peg-out swap '
        'row (or vice versa)', () {
      notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
      );

      notifier.reconcileWith([
        // Unified swap row but going the OTHER way (LBTC → BTC).
        // Direction mismatch — must NOT reconcile.
        _unifiedSwap(
          id: 'oppositeDirection',
          sentAmount: 28000,
          fromAsset: Asset.lbtc,
          toAsset: Asset.btc,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
    });

    test('reconcileWith does NOT drop unrelated transactions', () {
      notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );

      // Persisted list has only an unrelated incoming BTC tx.
      notifier.reconcileWith([
        _tx(
          id: 'unrelated',
          amount: 12345,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
    });

    test('markFailed transitions to failed phase and keeps row briefly', () {
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );
      notifier.markFailed(id, error: 'fee too low');

      final s = container.read(pendingSwapsProvider).single;
      expect(s.phase, PendingSwapPhase.failed);
      expect(s.errorMessage, 'fee too low');
      // Auto-evict timing is covered by the Future.delayed in the
      // notifier; we don't assert wall-clock removal here to keep
      // the test fast and deterministic.
    });

    test('failed rows survive reconcileWith (they have their own eviction)',
        () {
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );
      notifier.markFailed(id, error: 'boom');

      notifier.reconcileWith([
        _tx(
          id: 'unrelated',
          amount: 1,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
      expect(container.read(pendingSwapsProvider).single.phase,
          PendingSwapPhase.failed);
    });

    test('markRefundable flips phase + persists the swap address', () {
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(3000),
        estimatedReceivedAmount: BigInt.from(2900),
      );
      notifier.markBroadcasted(id, breezTxId: 'aa' * 32);

      notifier.markRefundable(id, swapAddress: 'bc1qSwapLockup...');

      final s = container.read(pendingSwapsProvider).single;
      expect(s.phase, PendingSwapPhase.refundable);
      expect(s.swapAddress, 'bc1qSwapLockup...');
    });

    test('refundable rows are NOT retired by destination-credit events', () {
      // Optimistic peg-in goes refundable (no LBTC ever arrived).
      // Even if some unrelated LBTC receive matches by amount, the
      // refundable branch in reconcileWith ignores destination credits.
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(3000),
        estimatedReceivedAmount: BigInt.from(2900),
      );
      notifier.markRefundable(id);
      final created = container.read(pendingSwapsProvider).single.createdAt;

      notifier.reconcileWith([
        // A destination-side LBTC receive that would normally retire
        // a `broadcasted` row — must NOT retire this refundable one.
        _tx(
          id: 'unrelatedLbtcCredit',
          amount: 2900,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: created.add(const Duration(seconds: 60)),
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
      expect(container.read(pendingSwapsProvider).single.phase,
          PendingSwapPhase.refundable);
    });

    test('refundable peg-in is retired when refund BTC lands back', () {
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(3000),
        estimatedReceivedAmount: BigInt.from(2900),
      );
      notifier.markRefundable(id);
      final created = container.read(pendingSwapsProvider).single.createdAt;

      notifier.reconcileWith([
        // Refund credit arrives back on the source chain (BTC), close
        // to the original sent amount minus Boltz's refund fee. The
        // 30 % tolerance covers small-amount edge cases like 3 000 sats.
        _tx(
          id: 'refundBtcTxId',
          amount: 2500,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: created.add(const Duration(minutes: 5)),
        ),
      ]);

      expect(container.read(pendingSwapsProvider), isEmpty);
    });

    test('refundable peg-out is retired when refund LBTC lands back', () {
      // Mirror of the peg-in test, source chain = Liquid.
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );
      notifier.markRefundable(id);
      final created = container.read(pendingSwapsProvider).single.createdAt;

      notifier.reconcileWith([
        _tx(
          id: 'refundLbtcTxId',
          amount: 49500,
          blockchain: Blockchain.liquid,
          asset: Asset.lbtc,
          type: TransactionType.receive,
          createdAt: created.add(const Duration(minutes: 2)),
        ),
      ]);

      expect(container.read(pendingSwapsProvider), isEmpty);
    });

    test('refundable row does NOT retire on a historical source credit', () {
      // Defensive: an old BTC receive from a previous transaction
      // shouldn't be mistaken for a refund.
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(3000),
        estimatedReceivedAmount: BigInt.from(2900),
      );
      notifier.markRefundable(id);
      final created = container.read(pendingSwapsProvider).single.createdAt;

      notifier.reconcileWith([
        _tx(
          id: 'oldBtcReceive',
          amount: 2800,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          type: TransactionType.receive,
          createdAt: created.subtract(const Duration(hours: 2)),
        ),
      ]);

      expect(container.read(pendingSwapsProvider), hasLength(1));
      expect(container.read(pendingSwapsProvider).single.phase,
          PendingSwapPhase.refundable);
    });

    test('peg-in flag is set when fromAsset=btc and toAsset=lbtc', () {
      final id = notifier.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49500),
      );
      final s = container
          .read(pendingSwapsProvider)
          .firstWhere((p) => p.localId == id);
      expect(s.isPegIn, isTrue);
      expect(s.isPegOut, isFalse);
    });
  });

  group('PendingSwap JSON round-trip', () {
    test('toJson / fromJson preserves every field', () {
      final original = PendingSwap(
        localId: 'pending_123_0',
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
        destination: 'bc1q...',
        phase: PendingSwapPhase.broadcasted,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1717000000000),
        breezSwapId: 'wCaunaTNZaHv',
        breezTxId: 'aa' * 32,
        errorMessage: null,
      );

      final round = PendingSwap.fromJson(original.toJson());

      expect(round.localId, original.localId);
      expect(round.fromAsset, original.fromAsset);
      expect(round.toAsset, original.toAsset);
      expect(round.sentAmount, original.sentAmount);
      expect(round.estimatedReceivedAmount, original.estimatedReceivedAmount);
      expect(round.destination, original.destination);
      expect(round.phase, original.phase);
      expect(round.createdAt, original.createdAt);
      expect(round.breezSwapId, original.breezSwapId);
      expect(round.breezTxId, original.breezTxId);
      expect(round.errorMessage, original.errorMessage);
    });
  });

  group('PendingSwapsNotifier persistence', () {
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    test('start persists; a fresh notifier reads it back (hot-restart sim)',
        () async {
      // Session A: create a pending swap, capture the serialised blob.
      final containerA = await _containerWithEmptyPrefs();
      final notifierA = containerA.read(pendingSwapsProvider.notifier);
      final id = notifierA.start(
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
      );
      notifierA.markBroadcasted(
        id,
        breezSwapId: 'wCaunaTNZaHv',
        breezTxId: 'aa' * 32,
      );

      final prefsAfterA = await SharedPreferences.getInstance();
      final blob = prefsAfterA.getString('pending_swaps_v1');
      expect(blob, isNotNull);
      containerA.dispose();

      // Session B: simulates hot restart — new container, same prefs
      // backing store. The pending row should hydrate before any
      // mutation happens.
      final containerB = await _containerWithSeededPrefs({
        'pending_swaps_v1': blob!,
      });
      final restored = containerB.read(pendingSwapsProvider);
      expect(restored, hasLength(1));
      expect(restored.single.localId, id);
      expect(restored.single.breezSwapId, 'wCaunaTNZaHv');
      expect(restored.single.phase, PendingSwapPhase.broadcasted);
      containerB.dispose();
    });

    test('clear wipes the key entirely (no empty "[]" lingering)', () async {
      final container = await _containerWithEmptyPrefs();
      final notifier = container.read(pendingSwapsProvider.notifier);
      final id = notifier.start(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        sentAmount: BigInt.from(50000),
        estimatedReceivedAmount: BigInt.from(49000),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pending_swaps_v1'), isNotNull);

      notifier.clear(id);
      expect(prefs.getString('pending_swaps_v1'), isNull);
      container.dispose();
    });

    test('corrupt blob is dropped silently — fresh container starts empty',
        () async {
      final container = await _containerWithSeededPrefs({
        'pending_swaps_v1': 'not-valid-json',
      });
      expect(container.read(pendingSwapsProvider), isEmpty);
      // And the corrupt key was cleaned up so the next persist
      // doesn't have to fight with it.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pending_swaps_v1'), isNull);
      container.dispose();
    });

    test('rows past _maxAge are filtered on load', () async {
      // Hand-craft a 7-hour-old persisted row (older than the 6h
      // ceiling). It should not survive the load filter.
      final stale = PendingSwap(
        localId: 'stale_row',
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
        destination: null,
        phase: PendingSwapPhase.broadcasted,
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      );
      final fresh = PendingSwap(
        localId: 'fresh_row',
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        sentAmount: BigInt.from(28000),
        estimatedReceivedAmount: BigInt.from(27400),
        destination: null,
        phase: PendingSwapPhase.broadcasted,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      // Hand-roll the persisted JSON the same way the notifier would.
      final blob =
          '[${stale.toJsonString()},${fresh.toJsonString()}]';

      final container = await _containerWithSeededPrefs({
        'pending_swaps_v1': blob,
      });

      final loaded = container.read(pendingSwapsProvider);
      expect(loaded, hasLength(1));
      expect(loaded.single.localId, 'fresh_row');
      container.dispose();
    });
  });
}

/// Tiny extension only used inside this test file to keep the
/// hand-crafted blob in the "_maxAge filter" test readable.
extension on PendingSwap {
  String toJsonString() {
    final m = toJson();
    final entries = m.entries.map((e) {
      final v = e.value;
      if (v == null) return '"${e.key}":null';
      if (v is String) return '"${e.key}":"${v.replaceAll('"', r'\"')}"';
      return '"${e.key}":$v';
    }).join(',');
    return '{$entries}';
  }
}
