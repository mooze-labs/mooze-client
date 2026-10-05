import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/domain/entities/asset.dart' as v2_asset;
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart' as v2_sync;
import 'package:mooze_mobile/features/wallet/di/providers/balance_snapshot_store_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/balance_snapshot_store.dart';
import 'package:mooze_mobile/features/wallet/presentation/controllers/balance_controller.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Legacy `BalanceController` factory — kept while consumers still
/// invoke it. The controller itself wraps the legacy WalletRepository;
/// this is part of the surface migrated in a later Stage 3 step.
final balanceControllerProvider =
    FutureProvider.autoDispose<Either<WalletError, BalanceController>>((
      ref,
    ) async {
      final wallet = await ref.watch(walletRepositoryProvider.future);
      return wallet.flatMap((w) => Either.right(BalanceController(w)));
    });

/// All-asset balance map.
///
/// Sourced from V2 `walletRepositoryProvider.balanceMap()` so the home
/// screen sees Breez-Liquid–held assets (USDT, DePix, L-BTC) even when
/// the legacy `walletRepositoryProvider` failed to wire its Breez
/// client (which can happen if the legacy `mnemonicProvider` riverpod
/// cache holds a stale `None` from a pre-import boot).
///
/// Returns `Map<legacy.Asset, BigInt>` — same shape consumers expect.
/// Drop this adapter once `wallet_holdings_provider` and the home
/// balance widget read V2 entities natively.
// Cache-first, stale-while-revalidate. No `.autoDispose` so the last balance
// map survives screen exits. The provider:
//   1. Loads the wallet-scoped persisted snapshot first and shows it
//      immediately — including while services are still connecting and while
//      the device is offline — so balances never flash 0.00 on startup.
//   2. Fetches fresh balances once the V2 repository is ready and persists a
//      write-through snapshot on every *completed sync*.
//   3. On a failed/partial fetch, returns the last known snapshot instead of
//      an empty map, so a sync error can never replace a real balance with 0.
// Consumers use `skipLoadingOnRefresh: true`, so the cached value stays on
// screen across every background re-run until fresh data arrives.
final allBalancesProvider = FutureProvider<Map<Asset, BigInt>>((ref) async {
  final logger = ref.read(appLoggerProvider);
  final store = ref.read(balanceSnapshotStoreProvider);

  // Wallet-scoped cache namespace. Read fresh each run: after a delete/import
  // the walletId rotates (and `walletIdProvider` is invalidated by those
  // flows), so this provider re-binds to the new wallet's snapshot and can
  // never surface a previous wallet's balances. See the cleanup hooks in
  // `buildWalletCleanupHooks`, which also wipe every persisted snapshot.
  final walletId = await ref.watch(walletIdProvider.future);
  final BalanceSnapshot? snapshot = await store.load(walletId);
  final Map<Asset, BigInt>? cached = snapshot?.balances;

  // React to V2 sync completions WITHOUT triggering a re-run during the first
  // frame. `ref.listen` doesn't fire on initial subscribe; it only fires when
  // sync forward-progresses past the last-seen timestamp, so we refresh
  // exactly once per completed sync.
  ref.listen<AsyncValue<v2_sync.SyncState>>(
    v2.syncStateProvider,
    (prev, next) {
      final prevTs = prev?.valueOrNull?.lastSuccessAt;
      final nextTs = next.valueOrNull?.lastSuccessAt;
      if (nextTs == null) return;
      if (nextTs == prevTs) return;
      ref.invalidateSelf();
    },
  );

  // If the wallet services aren't ready yet, show the cached snapshot
  // immediately instead of blocking on connect. Watching the repository
  // provider registers a dependency, so this provider re-runs automatically
  // once the repo resolves — at which point the live fetch below executes.
  final repoAsync = ref.watch(v2.walletRepositoryProvider);
  if (repoAsync.isLoading && cached != null) {
    logger.info('AllBalancesProvider',
        'Repo warming — serving cached snapshot (${cached.length} assets)');
    return cached;
  }

  final sw = Stopwatch()..start();
  final repo = await ref.watch(v2.walletRepositoryProvider.future);

  // Map legacy Asset → V2 Asset, fan out via balanceMap, then map back.
  final v2Assets = Asset.values.map(_legacyToV2Asset).toList();
  final result = await repo.balanceMap(v2Assets);
  sw.stop();

  // Has a sync actually completed this session? A connected-but-unsynced read
  // returns all-zeros from each service's empty in-memory cache — that is NOT
  // an authoritative snapshot and must never overwrite a good one.
  final synced =
      ref.read(v2.syncStateProvider).valueOrNull?.lastSuccessAt != null;

  return result.fold<Map<Asset, BigInt>>(
    (failure) {
      logger.critical(
        'AllBalancesProvider',
        'V2 balanceMap failed: ${failure.message}',
        error: failure,
      );
      // Never surface zero on failure: keep showing the last known snapshot.
      // The next successful sync tick refreshes silently.
      return cached ?? <Asset, BigInt>{};
    },
    (v2Map) {
      final fresh = <Asset, BigInt>{};
      for (final entry in v2Map.entries) {
        fresh[_v2ToLegacyAsset(entry.key)] = entry.value;
      }

      // Pre-sync read (services just connected): prefer the cached snapshot so
      // we never flash zeros before the first sync of this session lands.
      if (!synced) return cached ?? fresh;

      // Snapshot-poisoning guard. `balanceMap` collapses "asset unavailable"
      // and "asset genuinely zero" into the same `BigInt.zero`, so a partial
      // sync (e.g. Bitcoin backend down while Liquid/Lightning are up) would
      // otherwise persist BTC=0 over a real cached balance. Merge instead of
      // replace: trust a fresh value only for assets whose resolution chain
      // was authoritative this sync; keep the cached value for the rest.
      final syncedChains = _authoritativeChains(ref);
      final merged = mergeBalances(
        cached: cached,
        fresh: fresh,
        syncedChains: syncedChains,
      );

      // Only persist when at least one chain was authoritative this sync. A
      // sync that completes with zero authoritative chains (see the
      // orchestrator "vacuous success" note below) carries no fresh truth —
      // leave the existing snapshot untouched.
      if (syncedChains.isNotEmpty) {
        unawaited(store.save(
          walletId,
          BalanceSnapshot(balances: merged, savedAt: DateTime.now()),
        ));
        logger.info(
          'AllBalancesProvider',
          'Persisted merged snapshot (${merged.length} assets, '
              'chains=${syncedChains.map((c) => c.name).join(",")}) '
              'in ${sw.elapsedMilliseconds}ms',
        );
      }
      return merged;
    },
  );
});

/// Chains whose freshly-fetched balance is authoritative this sync — i.e.
/// currently `connected` AND having completed at least one successful sync
/// this session ([SyncState.firstSyncedChains]).
///
/// Both conditions are required (requirement: "operational AND successfully
/// synchronized"):
///   - NOT connected → `_fetchPerChainSnapshots` skips the service and the
///     repository reports `0` for its assets. Trusting that would zero a
///     cached balance during a backend outage.
///   - connected but never synced → the service's in-memory balance is still
///     empty (`0`) until its first sync lands. Trusting that would zero a
///     cached balance during the cold-connect window.
Set<ChainId> _authoritativeChains(Ref ref) {
  final state = ref.read(v2.syncStateProvider).valueOrNull;
  if (state == null) return const <ChainId>{};
  return authoritativeChainsOf(state);
}

/// Pure form of [_authoritativeChains]: the chains whose fresh balances may be
/// trusted given a [SyncState] — those that are currently `connected` AND have
/// completed at least one successful sync this session.
@visibleForTesting
Set<ChainId> authoritativeChainsOf(v2_sync.SyncState state) {
  final connected = state.perChain.entries
      .where((e) => e.value == ServiceLifecycle.connected)
      .map((e) => e.key)
      .toSet();
  return connected.intersection(state.firstSyncedChains);
}

/// Merges freshly-fetched [fresh] balances onto the last [cached] snapshot.
///
/// Snapshot-poisoning guard: a fresh value is trusted only when at least one
/// of the asset's resolution chains is in [syncedChains] (chains that were
/// operational AND successfully synchronized this sync). For an asset whose
/// chains were ALL unavailable/unsynced this sync, the cached value is
/// preserved — a transient backend outage can never zero a known balance.
/// When no cached value exists yet, the fresh value seeds the entry regardless
/// (so the asset still appears on first run / brand-new wallet).
///
/// A genuine reduction to zero IS persisted when the asset's chain is in
/// [syncedChains]: there the service returned a real `0` for a synchronized
/// chain and we trust it (e.g. the user spent the whole balance).
@visibleForTesting
Map<Asset, BigInt> mergeBalances({
  required Map<Asset, BigInt>? cached,
  required Map<Asset, BigInt> fresh,
  required Set<ChainId> syncedChains,
}) {
  final merged = <Asset, BigInt>{...?cached};
  fresh.forEach((asset, value) {
    final trusted =
        _legacyToV2Asset(asset).resolutionChains.any(syncedChains.contains);
    if (trusted) {
      merged[asset] = value;
    } else {
      // Chain not authoritative this sync — keep the cached value, but seed
      // the entry from `fresh` if we have nothing cached for it yet.
      merged.putIfAbsent(asset, () => value);
    }
  });
  return merged;
}

/// Single-asset balance lookup. Wraps [allBalancesProvider]; behaviour
/// preserved bit-for-bit so existing call sites (legacy controllers,
/// per-asset widgets) keep working without change.
final balanceProvider =
    FutureProvider.family<Either<WalletError, BigInt>, Asset>((
  ref,
  Asset asset,
) async {
  final allBalances = await ref.watch(allBalancesProvider.future);
  final balance = allBalances[asset] ?? BigInt.zero;
  return Either.right(balance);
});

v2_asset.Asset _legacyToV2Asset(Asset a) => switch (a) {
      Asset.btc => v2_asset.Asset.btc,
      Asset.lbtc => v2_asset.Asset.lbtc,
      Asset.usdt => v2_asset.Asset.usdt,
      Asset.depix => v2_asset.Asset.depix,
    };

Asset _v2ToLegacyAsset(v2_asset.Asset a) => switch (a) {
      v2_asset.Asset.btc => Asset.btc,
      v2_asset.Asset.lbtc => Asset.lbtc,
      v2_asset.Asset.usdt => Asset.usdt,
      v2_asset.Asset.depix => Asset.depix,
    };
