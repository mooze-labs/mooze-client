import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_catalog.dart';
import '../../domain/entities/balance.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/repositories/secure_credential_store.dart';
import '../../domain/repositories/transaction_store.dart';
import '../../domain/repositories/wallet_directory_guard.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/services/bitcoin_wallet_service.dart';
import '../../domain/services/lightning_wallet_service.dart';
import '../../domain/services/liquid_wallet_service.dart';
import '../../domain/services/platform_initializer.dart';
import '../../domain/services/session_authenticator.dart';
import '../../features/boot/data/boot_orchestrator_impl.dart';
import '../../features/boot/domain/boot_orchestrator.dart';
import '../../features/boot/domain/boot_state.dart';
import '../../features/sync/data/sync_orchestrator_impl.dart';
import '../../features/sync/domain/sync_config.dart';
import '../../features/sync/domain/sync_orchestrator.dart';
import '../../features/sync/domain/sync_state.dart';
import '../../features/wallet/data/v2/wallet_repository_impl.dart';
import '../../features/wallet/domain/usecases/delete_wallet.dart';
import '../../features/wallet/domain/usecases/import_wallet.dart';
import '../../features/wallet/domain/usecases/refresh_wallet.dart';
import '../../infra/auth/session_authenticator_impl.dart';
import '../../infra/bdk/bitcoin_wallet_service_impl.dart';
import '../../infra/breez/lightning_wallet_service_impl.dart';
import '../../infra/db/transaction_database.dart';
import '../../infra/fs/wallet_directory_guard_impl.dart';
import '../../infra/lwk/liquid_wallet_service_impl.dart';
import '../../infra/platform/platform_initializer_impl.dart';
import '../../infra/storage/asset_catalog_impl.dart';
import '../../infra/storage/secure_credential_store_impl.dart';
import '../../infra/storage/transaction_store_impl.dart';
import '../../shared/clock/clock.dart';
import '../../shared/logging/structured_logger.dart';
import '../lifecycle/app_lifecycle_controller.dart';
import '../lifecycle/app_lifecycle_controller_impl.dart';
import '../lifecycle/app_state.dart';

// ─────────────────────────────────────────── primitives

final clockProvider = Provider<Clock>((_) => const SystemClock());

final loggerProvider = Provider<StructuredLogger>((_) {
  return ConsoleStructuredLogger();
});

final platformInitializerProvider = Provider<PlatformInitializer>(
  (_) => PlatformInitializerImpl(),
);

final walletDirectoryGuardProvider = Provider<WalletDirectoryGuard>(
  (_) => WalletDirectoryGuardImpl(),
);

// ─────────────────────────────────────────── DB / storage

/// Owned by Riverpod. Opens the SQLite file lazily on first read and is
/// disposed when the provider is invalidated.
final transactionDatabaseProvider = FutureProvider<TransactionDatabase>(
  (ref) async {
    final db = await TransactionDatabase.open();
    ref.onDispose(db.close);
    return db;
  },
);

final transactionStoreProvider = FutureProvider<TransactionStore>((ref) async {
  final db = await ref.watch(transactionDatabaseProvider.future);
  final store = SqliteTransactionStore(db);
  ref.onDispose(store.dispose);
  return store;
});

final secureCredentialStoreProvider = Provider<SecureCredentialStore>(
  (_) => FlutterSecureCredentialStore(),
);

// ─────────────────────────────────────────── chain services

final liquidWalletServiceProvider = Provider<LiquidWalletService>((ref) {
  final s = LiquidWalletServiceImpl(
    directoryGuard: ref.read(walletDirectoryGuardProvider),
    logger: ref.read(loggerProvider),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(s.dispose);
  return s;
});

final bitcoinWalletServiceProvider = Provider<BitcoinWalletService>((ref) {
  final s = BitcoinWalletServiceImpl(
    logger: ref.read(loggerProvider),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(s.dispose);
  return s;
});

final lightningWalletServiceProvider = Provider<LightningWalletService>((ref) {
  final s = LightningWalletServiceImpl(
    directoryGuard: ref.read(walletDirectoryGuardProvider),
    logger: ref.read(loggerProvider),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(s.dispose);
  return s;
});

// ─────────────────────────────────────────── session

final sessionAuthenticatorProvider = Provider<SessionAuthenticator>((ref) {
  return NoOpSessionAuthenticator(ref.read(loggerProvider));
});

// ─────────────────────────────────────────── orchestrators

final syncConfigProvider = Provider<SyncConfig>((_) => const SyncConfig());

final bootOrchestratorProvider =
    FutureProvider<BootOrchestrator>((ref) async {
  final txStore = await ref.watch(transactionStoreProvider.future);
  final o = BootOrchestratorImpl(
    platformInitializer: ref.read(platformInitializerProvider),
    credentialStore: ref.read(secureCredentialStoreProvider),
    transactionStore: txStore,
    liquid: ref.read(liquidWalletServiceProvider),
    bitcoin: ref.read(bitcoinWalletServiceProvider),
    lightning: ref.read(lightningWalletServiceProvider),
    session: ref.read(sessionAuthenticatorProvider),
    logger: ref.read(loggerProvider),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(o.dispose);
  return o;
});

final syncOrchestratorProvider =
    FutureProvider<SyncOrchestrator>((ref) async {
  final txStore = await ref.watch(transactionStoreProvider.future);
  final o = SyncOrchestratorImpl(
    liquid: ref.read(liquidWalletServiceProvider),
    bitcoin: ref.read(bitcoinWalletServiceProvider),
    lightning: ref.read(lightningWalletServiceProvider),
    transactionStore: txStore,
    config: ref.read(syncConfigProvider),
    logger: ref.read(loggerProvider),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(o.dispose);
  return o;
});

final deleteWalletUseCaseProvider =
    FutureProvider<DeleteWalletUseCase>((ref) async {
  final boot = await ref.watch(bootOrchestratorProvider.future);
  final sync = await ref.watch(syncOrchestratorProvider.future);
  final txStore = await ref.watch(transactionStoreProvider.future);
  return DeleteWalletUseCase(
    boot: boot,
    sync: sync,
    credentials: ref.read(secureCredentialStoreProvider),
    transactionStore: txStore,
    directoryGuard: ref.read(walletDirectoryGuardProvider),
    workingDirs: const ['lwk-db', 'breez'],
    logger: ref.read(loggerProvider),
  );
});

final appLifecycleControllerProvider =
    FutureProvider<AppLifecycleController>((ref) async {
  final boot = await ref.watch(bootOrchestratorProvider.future);
  final sync = await ref.watch(syncOrchestratorProvider.future);
  final delete = await ref.watch(deleteWalletUseCaseProvider.future);
  final c = AppLifecycleControllerImpl(
    boot: boot,
    sync: sync,
    deleteWallet: delete,
    logger: ref.read(loggerProvider),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(c.dispose);
  return c;
});

// ─────────────────────────────────────────── presentation surfaces
//
// These StreamProviders return the orchestrator's stream directly — no
// async* generator wrapping. The ReplayValueStream already replays the
// cached value on subscribe, so the StreamProvider's first emission is
// the current state. No yield/yield* overhead, no microtask churn.

final appStateProvider = StreamProvider<AppState>((ref) {
  final controllerAsync = ref.watch(appLifecycleControllerProvider);
  return controllerAsync.when(
    loading: () => const Stream<AppState>.empty(),
    error: (e, st) => Stream<AppState>.error(e, st),
    data: (c) => c.state,
  );
});

final bootStateProvider = StreamProvider<BootState>((ref) {
  final bootAsync = ref.watch(bootOrchestratorProvider);
  return bootAsync.when(
    loading: () => const Stream<BootState>.empty(),
    error: (e, st) => Stream<BootState>.error(e, st),
    data: (b) => b.state,
  );
});

final syncStateProvider = StreamProvider<SyncState>((ref) {
  final syncAsync = ref.watch(syncOrchestratorProvider);
  return syncAsync.when(
    loading: () => const Stream<SyncState>.empty(),
    error: (e, st) => Stream<SyncState>.error(e, st),
    data: (s) => s.state,
  );
});

// ─────────────────────────────────────────── wallet repository + use cases

final walletRepositoryProvider =
    FutureProvider<WalletRepository>((ref) async {
  final txStore = await ref.watch(transactionStoreProvider.future);
  // Wire the orchestrator's merged tx-event stream into the repo so
  // `watchBalanceFor` debouncedly re-emits whenever a tx changes. The repo
  // does NOT depend on the orchestrator structurally — the stream is
  // optional — so test harnesses can construct the repo without the
  // orchestrator.
  final orchestrator = await ref.watch(syncOrchestratorProvider.future);
  return WalletRepositoryImpl(
    transactionStore: txStore,
    liquid: ref.read(liquidWalletServiceProvider),
    bitcoin: ref.read(bitcoinWalletServiceProvider),
    lightning: ref.read(lightningWalletServiceProvider),
    clock: ref.read(clockProvider),
    balanceTriggerStream: orchestrator.transactions,
  );
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>(
  (ref) async* {
    final repo = await ref.watch(walletRepositoryProvider.future);
    yield* repo.watchTransactions();
  },
);

final balanceProvider = FutureProvider<Balance>((ref) async {
  final repo = await ref.watch(walletRepositoryProvider.future);
  final r = await repo.aggregateBalance();
  return r.getOrElse((_) => Balance.empty());
});

final refreshWalletProvider = FutureProvider<RefreshWalletUseCase>((ref) async {
  final sync = await ref.watch(syncOrchestratorProvider.future);
  return RefreshWalletUseCase(sync);
});

final importWalletUseCaseProvider = Provider<ImportWalletUseCase>((ref) {
  return ImportWalletUseCase(ref.read(secureCredentialStoreProvider));
});

// ─────────────────────────────────────────── asset catalog + favourites

/// Static catalog of supported assets. Stable across boots.
final assetCatalogProvider = Provider<AssetCatalog>(
  (_) => const StaticAssetCatalog(),
);

/// `[Asset.btc, Asset.usdt, Asset.depix, Asset.lbtc]` — read by widgets that
/// render every asset row.
final allAssetsProviderV2 = Provider<List<Asset>>(
  (ref) => ref.watch(assetCatalogProvider).allAssets,
);

/// `[Asset.btc, Asset.usdt, Asset.depix]` — assets that need fast quote
/// preloads. Mirrors legacy `assetsForQuotesProvider`.
final assetsForQuotesProviderV2 = Provider<List<Asset>>(
  (ref) => ref.watch(assetCatalogProvider).assetsForQuotes,
);

/// SharedPreferences-backed favourites store.
final favouriteAssetsStoreProvider = Provider<FavouriteAssetsStore>(
  (_) => SharedPreferencesFavouriteAssetsStore(),
);

/// User-pinned favourites (max 2). Loads from disk on first read; persists
/// on every `setFavourites`. Mirrors legacy `favoriteAssetsProvider`'s
/// behaviour bit-for-bit so existing users keep their pins after migration.
final favouriteAssetsProviderV2 =
    StateNotifierProvider<FavouriteAssetsNotifier, List<Asset>>((ref) {
  return FavouriteAssetsNotifier(ref.read(favouriteAssetsStoreProvider));
});

class FavouriteAssetsNotifier extends StateNotifier<List<Asset>> {
  FavouriteAssetsNotifier(this._store) : super(const []) {
    _hydrate();
  }

  final FavouriteAssetsStore _store;

  Future<void> _hydrate() async {
    final loaded = await _store.load();
    if (mounted) state = loaded;
  }

  /// Toggle a single asset; clamps to `maxFavourites` (2 by default) using
  /// "drop-oldest" semantics — same as legacy.
  Future<void> toggleFavourite(Asset asset) async {
    final current = state;
    final next = current.contains(asset)
        ? current.where((a) => a != asset).toList()
        : (current.length < 2 ? [...current, asset] : [current[1], asset]);
    state = next;
    await _store.save(next);
  }

  Future<void> setFavourites(List<Asset> next) async {
    final clipped = next.take(2).toList();
    state = clipped;
    await _store.save(clipped);
  }
}

final isFavouriteAssetProviderV2 = Provider.family<bool, Asset>(
  (ref, asset) => ref.watch(favouriteAssetsProviderV2).contains(asset),
);

// ─────────────────────────────────────────── per-asset balance providers

/// Bulk per-asset balance map for ALL catalog assets. Replaces legacy
/// `allBalancesProvider`. Single fan-out per emission — services are hit at
/// most once per refresh, never N-times-per-asset.
///
/// `StreamProvider` so widgets receive updates on every orchestrator tx
/// event without manually calling refresh; debounced inside
/// `WalletRepositoryImpl.watchBalanceFor`'s machinery via the orchestrator
/// stream's natural cadence (the repo does its own debounce per asset, but
/// the bulk view here re-fans-out on every event — acceptable because each
/// fan-out is bounded and the orchestrator's tx stream is itself produced
/// only after `transactionStore.upsert` completes).
final allAssetBalancesProviderV2 =
    StreamProvider<Map<Asset, BigInt>>((ref) async* {
  final repo = await ref.watch(walletRepositoryProvider.future);
  final assets = ref.watch(allAssetsProviderV2);
  final orchestrator = await ref.watch(syncOrchestratorProvider.future);

  Future<Map<Asset, BigInt>> snapshot() async {
    final r = await repo.balanceMap(assets);
    return r.getOrElse((_) => {for (final a in assets) a: BigInt.zero});
  }

  yield await snapshot();
  // Re-emit on every orchestrator tx event. Coalesce 200ms bursts.
  final debounced = orchestrator.transactions.transform(
    _DebounceTransformer<TransactionEvent>(const Duration(milliseconds: 200)),
  );
  await for (final _ in debounced) {
    yield await snapshot();
  }
});

/// Per-asset balance stream. Backed by [WalletRepository.watchBalanceFor],
/// which debounces internally and shares the orchestrator's tx event stream.
/// Replaces legacy `balanceProvider(Asset)`.
final balanceForAssetProviderV2 =
    StreamProvider.family<BigInt, Asset>((ref, asset) async* {
  final repo = await ref.watch(walletRepositoryProvider.future);
  yield* repo.watchBalanceFor(asset);
});

// ─────────────────────────────────────────── helpers

/// Coalesces a burst of upstream events into one downstream event after the
/// burst settles. Used to throttle orchestrator tx events when fanning out
/// to all-asset balance fetches.
class _DebounceTransformer<T> extends StreamTransformerBase<T, T> {
  _DebounceTransformer(this.duration);
  final Duration duration;

  @override
  Stream<T> bind(Stream<T> source) {
    final controller = StreamController<T>();
    Timer? timer;
    T? pending;
    var hasPending = false;
    StreamSubscription<T>? sub;

    void flush() {
      if (hasPending && !controller.isClosed) {
        controller.add(pending as T);
        hasPending = false;
        pending = null;
      }
    }

    controller.onListen = () {
      sub = source.listen(
        (event) {
          pending = event;
          hasPending = true;
          timer?.cancel();
          timer = Timer(duration, flush);
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          flush();
          controller.close();
        },
      );
    };
    controller.onCancel = () async {
      timer?.cancel();
      await sub?.cancel();
    };
    return controller.stream;
  }
}
