import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/infra/bdk/bitcoin_wallet_service_impl.dart';
import 'package:mooze_mobile/shared/infra/bdk/wallet.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

/// V2 BRIDGE — exposes the legacy [BdkDataSource] shape but shares the
/// underlying `bdk.Wallet` handle owned by the V2 [BitcoinWalletServiceImpl].
///
/// Prior to this change the legacy provider built its own `bdk.Wallet`,
/// which meant **two** BDK wallet instances existed in the same process
/// alongside the V2 service — burning a duplicate setup pass on every
/// cold boot and racing for BDK's internal state on writes. The V2
/// service is now the single owner; the legacy `WalletRepositoryImpl`
/// and the address explorer call through the same handle.
final bdkDatasourceProvider =
    FutureProvider<Either<String, BdkDataSource>>((ref) async {
  // Wait for the V2 boot pipeline to bring the Bitcoin service to an
  // operational lifecycle. `appStateProvider` reaches `ready` ONLY after
  // boot's `connectingServices` phase resolved (which is when the BDK
  // wallet + Electrum blockchain handles are constructed). We also
  // listen to the service's own state stream so a later re-connect (e.g.
  // after `node_settings.save()`) is observed transparently.
  final service =
      ref.watch(bitcoinWalletServiceProvider) as BitcoinWalletServiceImpl;
  final database = ref.read(appDatabaseProvider);

  // Stale-reference invalidation — symmetric with `breezClientProvider`
  // and `liquidDataSourceProvider`. BDK address derivation tolerates a
  // disconnected blockchain handle (it's offline-capable), which is why
  // the Liquid receive bug surfaced first — but any operation that
  // actually touches Electrum (broadcast, fee fetch, sync) after a
  // delete + re-import would see the same stale-handle behaviour. The
  // listener invalidates this provider on `connected → !connected` so
  // the legacy `walletRepositoryProvider` re-resolves with the new
  // BDK wallet + Electrum blockchain on the next read.
  ServiceLifecycle? lastSeen;
  final lifecycleSub = service.state.listen((s) {
    final prev = lastSeen;
    lastSeen = s.lifecycle;
    if (prev == ServiceLifecycle.connected &&
        s.lifecycle != ServiceLifecycle.connected) {
      // Deferred — see breez/providers/client_provider.dart for the
      // re-entrant-invalidation rationale.
      Future.microtask(() {
        try {
          ref.invalidateSelf();
        } catch (_) {}
      });
    }
  });
  ref.onDispose(lifecycleSub.cancel);

  // If already operational, return immediately.
  if (service.currentState.isOperational &&
      service.sdkClient != null &&
      service.sdkBlockchain != null) {
    return Right(BdkDataSource(
      wallet: service.sdkClient!,
      blockchain: service.sdkBlockchain!,
      ref: ref,
      database: database,
    ));
  }

  // Otherwise wait for the first operational emission.
  await for (final s in service.state) {
    if (s.lifecycle == ServiceLifecycle.errored) {
      final msg = s.failure?.message ?? 'bdk connect failed';
      return Left(msg);
    }
    if (s.isOperational &&
        service.sdkClient != null &&
        service.sdkBlockchain != null) {
      return Right(BdkDataSource(
        wallet: service.sdkClient!,
        blockchain: service.sdkBlockchain!,
        ref: ref,
        database: database,
      ));
    }
  }
  return const Left('bdk service stream closed without operational state');
});
