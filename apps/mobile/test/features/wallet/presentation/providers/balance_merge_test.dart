import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

SyncState _syncState({
  required Map<ChainId, ServiceLifecycle> perChain,
  required Set<ChainId> firstSynced,
}) =>
    SyncState(
      phase: SyncPhase.cooling,
      perChain: perChain,
      lastSuccessAt: DateTime.fromMillisecondsSinceEpoch(1),
      firstSyncedChains: firstSynced,
    );

/// 0.5 BTC in satoshis.
final btcHalf = BigInt.from(50000000);
// Token amounts use the 1e8-scaled integer form (matching balanceMap output).
final usdt1000 = BigInt.from(1000) * BigInt.from(100000000);
final usdt1200 = BigInt.from(1200) * BigInt.from(100000000);

void main() {
  group('mergeBalances — snapshot-poisoning guard', () {
    test(
        'partial sync: Bitcoin down, Liquid/Lightning up — keeps cached BTC, '
        'updates USDT', () {
      // Existing snapshot: BTC=0.5, USDT=1000.
      final cached = {Asset.btc: btcHalf, Asset.usdt: usdt1000};

      // New sync: BTC unavailable (balanceMap zero-fills it), USDT=1200.
      final fresh = {
        Asset.btc: BigInt.zero,
        Asset.usdt: usdt1200,
        Asset.lbtc: BigInt.zero,
        Asset.depix: BigInt.zero,
      };

      // Bitcoin chain NOT connected; Liquid + Lightning connected.
      final merged = mergeBalances(
        cached: cached,
        fresh: fresh,
        syncedChains: {ChainId.liquid, ChainId.lightning},
      );

      // SAFE outcome: BTC preserved at 0.5, USDT updated to 1200.
      expect(merged[Asset.btc], btcHalf,
          reason: 'Bitcoin offline → cached balance must survive');
      expect(merged[Asset.usdt], usdt1200,
          reason: 'Liquid/Lightning online → USDT updates');
    });

    test('genuine spend-to-zero: Bitcoin connected and returns 0 — persists 0',
        () {
      final cached = {Asset.btc: btcHalf};
      final fresh = {Asset.btc: BigInt.zero};

      final merged = mergeBalances(
        cached: cached,
        fresh: fresh,
        syncedChains: {ChainId.bitcoin},
      );

      expect(merged[Asset.btc], BigInt.zero,
          reason: 'Bitcoin connected → a real zero must be trusted');
    });

    test('chain flapping: offline → online → offline preserves cached value',
        () {
      // 1. First online sync seeds the snapshot.
      var snapshot = mergeBalances(
        cached: null,
        fresh: {Asset.btc: btcHalf},
        syncedChains: {ChainId.bitcoin},
      );
      expect(snapshot[Asset.btc], btcHalf);

      // 2. Bitcoin goes offline; balanceMap reports 0. Cached must survive.
      snapshot = mergeBalances(
        cached: snapshot,
        fresh: {Asset.btc: BigInt.zero},
        syncedChains: const {},
      );
      expect(snapshot[Asset.btc], btcHalf,
          reason: 'offline period must not zero a known balance');

      // 3. Bitcoin reconnects and reports the real balance again.
      snapshot = mergeBalances(
        cached: snapshot,
        fresh: {Asset.btc: btcHalf},
        syncedChains: {ChainId.bitcoin},
      );
      expect(snapshot[Asset.btc], btcHalf);
    });

    test('asset trusted when ANY one of its resolution chains is connected',
        () {
      // USDT resolves on [lightning, liquid]; only Liquid connected this sync.
      final merged = mergeBalances(
        cached: {Asset.usdt: usdt1000},
        fresh: {Asset.usdt: usdt1200},
        syncedChains: {ChainId.liquid},
      );
      expect(merged[Asset.usdt], usdt1200);
    });

    test('no chains connected with a cached snapshot — every asset preserved',
        () {
      final cached = {Asset.btc: btcHalf, Asset.usdt: usdt1000};
      final merged = mergeBalances(
        cached: cached,
        fresh: {Asset.btc: BigInt.zero, Asset.usdt: BigInt.zero},
        syncedChains: const {},
      );
      expect(merged[Asset.btc], btcHalf);
      expect(merged[Asset.usdt], usdt1000);
    });

    test(
        'no cached value + offline chain — fresh seeds the entry so it still '
        'appears', () {
      final merged = mergeBalances(
        cached: null,
        fresh: {Asset.btc: BigInt.zero},
        syncedChains: const {},
      );
      expect(merged.containsKey(Asset.btc), isTrue);
      expect(merged[Asset.btc], BigInt.zero);
    });

    test('does not drop cached assets that are absent from the fresh map', () {
      // Defensive: if a fresh fetch omits an asset entirely, the cached value
      // must remain (merge starts from a copy of cached).
      final merged = mergeBalances(
        cached: {Asset.btc: btcHalf, Asset.depix: usdt1000},
        fresh: {Asset.btc: btcHalf},
        syncedChains: {ChainId.bitcoin},
      );
      expect(merged[Asset.depix], usdt1000);
    });
  });

  group('authoritativeChainsOf — "operational AND successfully synchronized"',
      () {
    test('connected AND synced this session → trusted', () {
      final trusted = authoritativeChainsOf(_syncState(
        perChain: {
          ChainId.bitcoin: ServiceLifecycle.connected,
          ChainId.liquid: ServiceLifecycle.connected,
        },
        firstSynced: {ChainId.bitcoin, ChainId.liquid},
      ));
      expect(trusted, {ChainId.bitcoin, ChainId.liquid});
    });

    test('connected but NOT yet synced (cold-connect window) → excluded', () {
      final trusted = authoritativeChainsOf(_syncState(
        perChain: {
          ChainId.bitcoin: ServiceLifecycle.connected,
          ChainId.liquid: ServiceLifecycle.connected,
        },
        firstSynced: {ChainId.liquid}, // bitcoin connected but never synced
      ));
      expect(trusted, {ChainId.liquid},
          reason: 'a connected-but-unsynced chain reads 0 and must not be '
              'trusted to overwrite a cached balance');
    });

    test('synced earlier but now disconnected → excluded', () {
      final trusted = authoritativeChainsOf(_syncState(
        perChain: {
          ChainId.bitcoin: ServiceLifecycle.disconnected,
          ChainId.liquid: ServiceLifecycle.connected,
        },
        firstSynced: {ChainId.bitcoin, ChainId.liquid},
      ));
      expect(trusted, {ChainId.liquid},
          reason: 'a now-offline chain is skipped by the repo and reads 0');
    });

    test('errored chain → excluded', () {
      final trusted = authoritativeChainsOf(_syncState(
        perChain: {ChainId.bitcoin: ServiceLifecycle.errored},
        firstSynced: {ChainId.bitcoin},
      ));
      expect(trusted, isEmpty);
    });
  });
}
