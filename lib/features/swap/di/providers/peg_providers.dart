import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/wallet/di/providers/swap_audit_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';

import '../../data/datasources/sideswap.dart';
import '../../data/repositories/drift_peg_store.dart';
import '../../data/repositories/peg_repository_impl.dart';
import '../../data/repositories/peg_wallet_impl.dart';
import '../../domain/entities/peg.dart';
import '../../domain/repositories/peg_repository.dart';
import '../../domain/repositories/peg_wallet.dart';
import '../../domain/usecases/peg_orchestrator.dart';
import '../../domain/usecases/peg_tracker.dart';

const String _sideswapApiKey = String.fromEnvironment(
  'SIDESWAP_API_KEY',
  defaultValue:
      '5c85504bf60e13e0d58614cb9ed86cb2c163cfa402fb3a9e63cf76c7a7af46a1',
);

final pegSideswapApiProvider = Provider<SideswapApi>((ref) {
  final api = SideswapApi();
  ref.onDispose(api.dispose);
  return api;
});

final pegSideswapServiceProvider = Provider<SideswapService>((ref) {
  final api = ref.watch(pegSideswapApiProvider);
  final service = SideswapService(api: api, apiKey: _sideswapApiKey);
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

final pegRepositoryProvider = Provider<PegRepository>((ref) {
  return PegRepositoryImpl(
    sideswapService: ref.watch(pegSideswapServiceProvider),
  );
});

final pegLimitsProvider = FutureProvider<PegServerLimits?>((ref) async {
  final result = await ref.watch(pegRepositoryProvider).getLimits().run();
  return result.toNullable();
});

final pegWalletProvider = FutureProvider<PegWallet?>((ref) async {
  final controllerEither = await ref.watch(walletControllerProvider.future);
  final controller = controllerEither.toNullable();
  if (controller == null) return null;

  return PegWalletImpl(
    walletController: controller,
    liquidService: ref.watch(liquidWalletServiceProvider),
    mnemonicStore: ref.read(mnemonicStoreProvider),
  );
});

/// Persistence + restart recovery, scoped to the active wallet.
final pegStoreProvider = FutureProvider<DriftPegStore>((ref) async {
  final walletId = await ref.watch(walletIdProvider.future);
  return DriftPegStore(
    database: ref.read(appDatabaseProvider),
    walletId: walletId,
    audit: ref.read(swapAuditRepositoryProvider),
  );
});

/// Drives a peg from quote through funding.
final pegOrchestratorProvider = FutureProvider<PegOrchestrator?>((ref) async {
  final wallet = await ref.watch(pegWalletProvider.future);
  if (wallet == null) return null;
  final store = await ref.watch(pegStoreProvider.future);

  return PegOrchestrator(
    repository: ref.watch(pegRepositoryProvider),
    wallet: wallet,
    store: store,
  );
});

/// Long-lived status poller. `keepAlive` by construction (a plain [Provider]),
/// so it survives the swap screen being disposed.
final pegTrackerProvider = FutureProvider<PegTracker>((ref) async {
  final store = await ref.watch(pegStoreProvider.future);
  final tracker = PegTracker(
    repository: ref.watch(pegRepositoryProvider),
    store: store,
    recoverySource: store,
  );
  ref.onDispose(tracker.dispose);
  unawaited(tracker.restore().catchError((Object _) {}));
  return tracker;
});

/// Live view of in-flight pegs for the UI.
final activePegsProvider = StreamProvider<List<TrackedPeg>>((ref) async* {
  final tracker = await ref.watch(pegTrackerProvider.future);
  yield tracker.current;
  yield* tracker.pegs;
});
