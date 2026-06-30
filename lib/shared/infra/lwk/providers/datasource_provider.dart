import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart' as v2;
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/infra/lwk/liquid_wallet_service_impl.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/wallet.dart';

/// V2 BRIDGE — exposes the legacy [LiquidDataSource] shape but shares the
/// underlying `lwk.Wallet` handle owned by the V2 [LiquidWalletServiceImpl].
///
/// Prior to this change the legacy provider built its own `lwk.Wallet`
/// (sharing the `${appDocs}/lwk-db` working directory with the V2 service),
/// which produced silent SQLite contention on every wallet read. The V2
/// service is now the single owner; the legacy `WalletRepositoryImpl`
/// and the address explorer call through the same handle.
final liquidDataSourceProvider =
    FutureProvider<Either<String, LiquidDataSource>>((ref) async {
  final service =
      ref.watch(liquidWalletServiceProvider) as LiquidWalletServiceImpl;
  final database = ref.read(appDatabaseProvider);

  // Stale-reference invalidation — symmetric with `breezClientProvider`.
  // The same delete + re-import flow that produced
  // "Liquid SDK instance is not running" on the Breez side would produce
  // an equivalent LWK-side stale handle (an `lwk.Wallet` whose underlying
  // electrum client was torn down by `LiquidWalletServiceImpl.disconnect`)
  // the next time send/swap touched the legacy `LiquidWallet` wrapper.
  // Self-invalidate on `connected → !connected` so the legacy
  // `walletRepositoryProvider` re-resolves and picks up the new wallet
  // handle on the next read.
  ServiceLifecycle? lastSeen;
  final lifecycleSub = service.state.listen((s) {
    final prev = lastSeen;
    lastSeen = s.lifecycle;
    if (prev == ServiceLifecycle.connected &&
        s.lifecycle != ServiceLifecycle.connected) {
      // Deferred to next microtask — see breez/providers/client_provider.dart
      // for why synchronous `ref.invalidateSelf()` inside a stream
      // listener causes the provider's wait loop to capture a
      // transient disconnected state and return Left after the 6/30s
      // timeout on the very next read.
      Future.microtask(() {
        try {
          ref.invalidateSelf();
        } catch (_) {}
      });
    }
  });
  ref.onDispose(lifecycleSub.cancel);

  LiquidDataSource build(Wallet wallet) => LiquidDataSource(
        wallet: wallet,
        electrumUrl: service.currentElectrumUrl,
        network: _toLwkNetwork(),
        validateDomain: service.validateDomain,
        descriptor: '',
        dbPath: '',
        database: database,
        ref: ref,
      );

  if (service.currentState.isOperational && service.sdkClient != null) {
    return Right(build(service.sdkClient!));
  }

  await for (final s in service.state) {
    if (s.lifecycle == ServiceLifecycle.errored) {
      return Left(s.failure?.message ?? 'lwk connect failed');
    }
    if (s.isOperational && service.sdkClient != null) {
      return Right(build(service.sdkClient!));
    }
  }
  return const Left('lwk service stream closed without operational state');
});

/// Maps the V2 app network to the LWK enum. Mainnet is the only path
/// production builds exercise; testnet/regtest fall through to LWK's
/// testnet enum (same as V2 `LiquidWalletServiceImpl._toLwkNetwork`).
Network _toLwkNetwork() {
  switch (v2.AppNetwork.mainnet) {
    case v2.AppNetwork.mainnet:
      return Network.mainnet;
    case v2.AppNetwork.testnet:
    case v2.AppNetwork.regtest:
      return Network.testnet;
  }
}
