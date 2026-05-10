import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/domain/entities/asset.dart' as v2_asset;
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
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
final allBalancesProvider = FutureProvider.autoDispose<Map<Asset, BigInt>>((
  ref,
) async {
  final logger = ref.read(appLoggerProvider);

  // React to V2 sync settling. We only refetch when sync transitions back
  // to `cooling` (the post-cycle state) — earlier we keyed on
  // `lastSuccessAt` directly, which made the provider rebuild while
  // chains were still mid-sync (each `sync.chain.ok` doesn't change
  // `lastSuccessAt`, but the subscriber fires on every `valueOrNull`
  // tick during boot before the orchestrator finishes its first round).
  // Result: balanceMap fan-out (3 SDK FFI calls) was running 2× during
  // boot. Now it runs at most once per settled cycle.
  ref.watch(v2.syncStateProvider.select((async) {
    final s = async.valueOrNull;
    if (s == null) return null;
    if (s.phase != SyncPhase.cooling) return null;
    return s.lastSuccessAt;
  }));

  logger.info('AllBalancesProvider', 'Waiting for V2 wallet repository...');
  final repo = await ref.watch(v2.walletRepositoryProvider.future);

  logger.info('AllBalancesProvider', 'V2 repository ready, fetching balances');

  // Map legacy Asset → V2 Asset, fan out via balanceMap, then map back.
  final v2Assets = Asset.values.map(_legacyToV2Asset).toList();
  final result = await repo.balanceMap(v2Assets);

  return result.fold<Map<Asset, BigInt>>(
    (failure) {
      logger.critical(
        'AllBalancesProvider',
        'V2 balanceMap failed: ${failure.message}',
        error: failure,
      );
      // Empty map preserves legacy "show 0" behaviour rather than
      // throwing — UI renders 0 for every asset and the next sync
      // tick refreshes silently.
      return <Asset, BigInt>{};
    },
    (v2Map) {
      final legacyMap = <Asset, BigInt>{};
      for (final entry in v2Map.entries) {
        final legacyAsset = _v2ToLegacyAsset(entry.key);
        legacyMap[legacyAsset] = entry.value;
        logger.debug(
          'AllBalancesProvider',
          '${legacyAsset.ticker}: ${entry.value}',
        );
      }
      logger.info(
        'AllBalancesProvider',
        'Loaded ${legacyMap.length} asset balance(s) from V2',
      );
      return legacyMap;
    },
  );
});

/// Single-asset balance lookup. Wraps [allBalancesProvider]; behaviour
/// preserved bit-for-bit so existing call sites (legacy controllers,
/// per-asset widgets) keep working without change.
final balanceProvider = FutureProvider.autoDispose
    .family<Either<WalletError, BigInt>, Asset>((ref, Asset asset) async {
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
