import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_monitor_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_config.dart';

enum WalletDataState { idle, loading, refreshing, success, error }

class WalletDataStatus {
  final WalletDataState state;
  final String? errorMessage;
  final DateTime? lastSync;
  final bool isInitialLoad;
  final bool hasLiquidSyncFailed;
  final bool hasBdkSyncFailed;

  const WalletDataStatus({
    required this.state,
    this.errorMessage,
    this.lastSync,
    this.isInitialLoad = false,
    this.hasLiquidSyncFailed = false,
    this.hasBdkSyncFailed = false,
  });

  bool get isLoading => state == WalletDataState.loading;
  bool get isRefreshing => state == WalletDataState.refreshing;
  bool get isLoadingOrRefreshing => isLoading || isRefreshing;
  bool get hasError => state == WalletDataState.error;
  bool get isSuccess => state == WalletDataState.success;

  WalletDataStatus copyWith({
    WalletDataState? state,
    String? errorMessage,
    DateTime? lastSync,
    bool? isInitialLoad,
    bool? hasLiquidSyncFailed,
    bool? hasBdkSyncFailed,
  }) {
    return WalletDataStatus(
      state: state ?? this.state,
      errorMessage: errorMessage,
      lastSync: lastSync ?? this.lastSync,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      hasLiquidSyncFailed: hasLiquidSyncFailed ?? this.hasLiquidSyncFailed,
      hasBdkSyncFailed: hasBdkSyncFailed ?? this.hasBdkSyncFailed,
    );
  }
}

class WalletDataManager extends StateNotifier<WalletDataStatus> {
  final Ref ref;
  Timer? _periodicSyncTimer;
  Completer<void>? _currentSyncCompleter;
  int _dataSourceRetryCount = 0;
  static const int _maxDataSourceRetries = 5;
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  WalletDataManager(this.ref)
    : super(const WalletDataStatus(state: WalletDataState.idle));

  Future<void> initializeWallet() async {
    if (state.isLoadingOrRefreshing) {
      debugPrint(
        '[WalletDataManager] Initialization already in progress, ignoring',
      );
      return;
    }

    debugPrint('[WalletDataManager] Initializing wallet...');

    state = state.copyWith(state: WalletDataState.loading, isInitialLoad: true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      final bdkResult = await ref.read(bdkDatasourceProvider.future);

      bool hasValidDataSource = false;
      bool liquidAvailable = false;
      bool bdkAvailable = false;

      liquidResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] Liquid datasource not available: $error',
          );
          state = state.copyWith(hasLiquidSyncFailed: true);
        },
        (success) {
          debugPrint('[WalletDataManager] Liquid datasource available');
          hasValidDataSource = true;
          liquidAvailable = true;
        },
      );

      bdkResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] BDK datasource not available: $error',
          );
          state = state.copyWith(hasBdkSyncFailed: true);
        },
        (success) {
          debugPrint('[WalletDataManager] BDK datasource available');
          hasValidDataSource = true;
          bdkAvailable = true;
        },
      );

      if (!hasValidDataSource) {
        debugPrint(
          '[WalletDataManager] No datasource available (attempt ${_dataSourceRetryCount + 1}/$_maxDataSourceRetries)',
        );

        if (_dataSourceRetryCount < _maxDataSourceRetries) {
          _dataSourceRetryCount++;
          final retryDelay = _initialRetryDelay * _dataSourceRetryCount;

          debugPrint(
            '[WalletDataManager] Trying to recreate datasources in ${retryDelay.inSeconds}s...',
          );

          state = state.copyWith(
            state: WalletDataState.error,
            errorMessage:
                'Trying to reconnect datasources ($_dataSourceRetryCount/$_maxDataSourceRetries)...',
            isInitialLoad: false,
          );

          await Future.delayed(retryDelay);

          ref.invalidate(liquidDataSourceProvider);
          ref.invalidate(bdkDatasourceProvider);

          return await initializeWallet();
        } else {
          _dataSourceRetryCount = 0;
          throw Exception(
            'No datasource available after $_maxDataSourceRetries attempts. '
            'Check your connection and try again.',
          );
        }
      }

      _dataSourceRetryCount = 0;

      await Future.delayed(Duration.zero);

      final syncFutures = <Future<void>>[];

      if (liquidAvailable) {
        liquidResult.fold((_) {}, (datasource) {
          syncFutures.add(
            Future.delayed(Duration.zero).then(
              (_) => datasource
                  .sync()
                  .then((_) {
                    debugPrint(
                      '[WalletDataManager] Sync Liquid inicial concluído',
                    );
                  })
                  .catchError((e) {
                    debugPrint(
                      '[WalletDataManager] Erro no sync Liquid inicial: $e',
                    );
                  }),
            ),
          );
        });
      }

      // Sync BDK
      if (bdkAvailable) {
        bdkResult.fold((_) {}, (datasource) {
          debugPrint('[WalletDataManager] Sincronizando BDK (inicial)...');
          syncFutures.add(
            Future.delayed(Duration.zero).then(
              (_) => datasource
                  .sync()
                  .then((_) {
                    debugPrint(
                      '[WalletDataManager] Sync BDK inicial concluído',
                    );
                  })
                  .catchError((e) {
                    debugPrint(
                      '[WalletDataManager] Erro no sync BDK inicial: $e',
                    );
                  }),
            ),
          );
        });
      }

      if (syncFutures.isNotEmpty) {
        debugPrint(
          '[WalletDataManager] Aguardando ${syncFutures.length} sync(s) concluir...',
        );
        await Future.wait(syncFutures);
        debugPrint('[WalletDataManager] Todos os syncs iniciais concluídos!');
      }

      debugPrint('[WalletDataManager] Invalidating providers after sync...');
      _invalidateDataProviders();

      debugPrint('[WalletDataManager] Fetching balances after sync...');
      await _loadInitialData();

      _startPeriodicSync();

      state = state.copyWith(
        state: WalletDataState.success,
        lastSync: DateTime.now(),
        isInitialLoad: false,
      );

      debugPrint('[WalletDataManager] Wallet initialized successfully');

      // Async auth check (non-blocking) - moved to end as per priority restructure
      Future.delayed(Duration.zero, () {
        debugPrint('[WalletDataManager] Starting background auth check...');
        ref
            .read(ensureAuthSessionProvider.future)
            .then((ensured) {
              if (ensured) {
                debugPrint(
                  '[WalletDataManager] Authentication session ensured',
                );
              }
            })
            .catchError((e) {
              debugPrint(
                '[WalletDataManager] Warning: Auth background failed (not critical for wallet): $e',
              );
            });
      });
    } catch (error) {
      debugPrint('[WalletDataManager] Erro na inicialização: $error');

      state = state.copyWith(
        state: WalletDataState.error,
        errorMessage: error.toString(),
        isInitialLoad: false,
      );
    }
  }

  void resetState() {
    WalletSyncLogger.debug('[WalletDataManager] Resetting full state...');
    state = const WalletDataStatus(state: WalletDataState.idle);
    _periodicSyncTimer?.cancel();
    _currentSyncCompleter?.complete();
    _currentSyncCompleter = null;
    _dataSourceRetryCount = 0;
  }

  void notifyDataSourceRecovered(String dataSourceType) {
    WalletSyncLogger.debug(
      '[WalletDataManager] Datasource $dataSourceType recovered',
    );

    if (dataSourceType == 'liquid') {
      state = state.copyWith(
        hasLiquidSyncFailed: false,
        errorMessage: state.hasBdkSyncFailed ? state.errorMessage : null,
      );
    } else if (dataSourceType == 'bdk') {
      state = state.copyWith(
        hasBdkSyncFailed: false,
        errorMessage: state.hasLiquidSyncFailed ? state.errorMessage : null,
      );
    }

    if (!state.hasLiquidSyncFailed &&
        !state.hasBdkSyncFailed &&
        state.hasError) {
      WalletSyncLogger.info(
        '[WalletDataManager] All datasources recovered, reinitializing...',
      );
      initializeWallet();
    }
  }

  void notifyLiquidSyncFailed(String error) {
    WalletSyncLogger.error('[WalletDataManager] Liquid sync failed: $error');

    state = state.copyWith(
      hasLiquidSyncFailed: true,
      errorMessage: 'Liquid sync failed: $error',
    );
  }

  void notifyBdkSyncFailed(String error) {
    debugPrint('[WalletDataManager] BDK sync failed: $error');

    state = state.copyWith(
      hasBdkSyncFailed: true,
      errorMessage: 'BDK sync failed: $error',
    );
  }

  Future<void> retryDataSourceConnection() async {
    debugPrint(
      '[WalletDataManager] Manual attempt to reconnect datasources...',
    );

    _dataSourceRetryCount = 0;

    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(breezClientProvider);

    await Future.delayed(const Duration(milliseconds: 500));

    await initializeWallet();
  }

  Future<void> refreshWalletData() async {
    if (_currentSyncCompleter != null) {
      debugPrint('[WalletDataManager] Sync already in progress, waiting...');
      await _currentSyncCompleter!.future;
      return;
    }

    _currentSyncCompleter = Completer<void>();

    try {
      debugPrint('[WalletDataManager] Starting manual refresh...');
      state = state.copyWith(state: WalletDataState.refreshing);

      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      final bdkResult = await ref.read(bdkDatasourceProvider.future);

      bool hasValidDataSource = false;
      bool liquidFailed = false;
      bool bdkFailed = false;

      liquidResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] ⚠️ Liquid datasource error during refresh: $error',
          );
          liquidFailed = true;
        },
        (success) {
          debugPrint('[WalletDataManager] Liquid datasource available');
          hasValidDataSource = true;
        },
      );

      bdkResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] ⚠️ BDK datasource error during refresh: $error',
          );
          bdkFailed = true;
        },
        (success) {
          debugPrint('[WalletDataManager] BDK datasource available');
          hasValidDataSource = true;
        },
      );

      if (!hasValidDataSource) {
        debugPrint(
          '[WalletDataManager] No datasource available during refresh',
        );

        state = state.copyWith(
          state: WalletDataState.error,
          errorMessage: 'Datasources not available. Trying to reconnect...',
          hasLiquidSyncFailed: liquidFailed,
          hasBdkSyncFailed: bdkFailed,
        );

        debugPrint('[WalletDataManager] Trying to reinitialize datasources...');

        ref.invalidate(liquidDataSourceProvider);
        ref.invalidate(bdkDatasourceProvider);

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            debugPrint('[WalletDataManager] Trying full reinitialization...');
            initializeWallet();
          }
        });

        return;
      }

      debugPrint('[WalletDataManager] Sincronizando datasources...');
      final syncFutures = <Future<void>>[];

      liquidResult.fold(
        (_) => debugPrint(
          '[WalletDataManager] ⏭Skipping Liquid sync (with error)',
        ),
        (datasource) {
          debugPrint('[WalletDataManager] Sincronizando Liquid...');

          syncFutures.add(
            datasource.sync().catchError((e) {
              debugPrint('[WalletDataManager] Erro ao sincronizar Liquid: $e');
            }),
          );
        },
      );

      bdkResult.fold(
        (_) => debugPrint('[WalletDataManager] Skipping BDK sync (with error)'),
        (datasource) {
          debugPrint('[WalletDataManager] Sincronizando BDK...');
          syncFutures.add(
            datasource.sync().catchError((e) {
              debugPrint('[WalletDataManager] Erro ao sincronizar BDK: $e');
            }),
          );
        },
      );

      await Future.wait(syncFutures);
      debugPrint('[WalletDataManager] Datasources sincronizados');

      // Rescan onchain swaps to detect additional funds sent to already used addresses
      // await _rescanOnchainSwaps();

      await _invalidateAndRefreshAllProviders();

      await _syncPendingTransactions();

      debugPrint(
        '[WalletDataManager] Forcing cache refresh after pending sync',
      );
      await ref.read(transactionHistoryCacheProvider.notifier).refresh();

      state = state.copyWith(
        state: WalletDataState.success,
        lastSync: DateTime.now(),
        hasLiquidSyncFailed: liquidFailed,
        hasBdkSyncFailed: bdkFailed,
      );

      debugPrint('[WalletDataManager] Manual refresh completed');
    } catch (error) {
      debugPrint('[WalletDataManager] Erro no refresh manual: $error');
      state = state.copyWith(
        state: WalletDataState.error,
        errorMessage: error.toString(),
      );
    } finally {
      _currentSyncCompleter?.complete();
      _currentSyncCompleter = null;
    }
  }

  Future<void> _syncPendingTransactions() async {
    try {
      debugPrint('[WalletDataManager] Pending sync triggered');
      final monitorService = ref.read(transactionMonitorServiceProvider);
      await monitorService.syncPendingTransactions();
      debugPrint('[WalletDataManager] Pending sync completed');
    } catch (e) {
      debugPrint('[WalletDataManager] Error syncing pending: $e');
    }
  }

  // /// Onchain swap rescan to detect additional funds sent to already used addresses.
  // /// This allows refundable transactions to be correctly detected.
  // ///
  // /// According to Breez SDK documentation:
  // /// "If users inadvertently send additional funds to a previously used swap address,
  // /// the SDK will not automatically recognize it. Use this method to manually scan
  // /// all historical swap addresses and update their onchain status."
  // Future<void> _rescanOnchainSwaps() async {
  //   try {
  //     debugPrint('[WalletDataManager] 🔍 Starting onchain swaps rescan...');

  //     final breezClient = await ref.read(breezClientProvider.future);

  //     await breezClient.fold(
  //       (error) {
  //         debugPrint('[WalletDataManager] Breez client not available for rescan: $error');
  //         return Future<void>.value();
  //       },
  //       (client) async {
  //         try {
  //           await client.rescanOnchainSwaps();
  //           debugPrint('[WalletDataManager] Onchain swaps rescan completed successfully');
  //         } catch (e) {
  //           debugPrint('[WalletDataManager] Error during swaps rescan: $e');
  //         }
  //       },
  //     );
  //   } catch (e) {
  //     debugPrint('[WalletDataManager] Error trying to rescan swaps: $e');
  //   }
  // }

  void _invalidateDataProviders() {
    debugPrint(
      '[WalletDataManager] Invalidating data providers (keeping datasources)...',
    );

    ref.invalidate(walletRepositoryProvider);

    ref.invalidate(transactionControllerProvider);
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(transactionHistoryCacheProvider);

    ref.invalidate(balanceControllerProvider);
    ref.invalidate(allBalancesProvider);
    ref.invalidate(balanceCacheProvider);

    final allAssets = ref.read(allAssetsProvider);
    for (final asset in allAssets) {
      ref.invalidate(balanceProvider(asset));
    }

    ref.invalidate(walletHoldingsProvider);
    ref.invalidate(walletHoldingsWithBalanceProvider);
    ref.invalidate(totalWalletValueProvider);
    ref.invalidate(totalWalletBitcoinProvider);
    ref.invalidate(totalWalletSatoshisProvider);
    ref.invalidate(totalWalletVariationProvider);

    ref.invalidate(assetPriceHistoryCacheProvider);
  }

  void invalidateAllWalletProviders() {
    ref.invalidate(mnemonicProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(breezClientProvider);

    _invalidateDataProviders();
  }

  Future<void> _loadInitialData() async {
    final favoriteAssets = ref.read(favoriteAssetsProvider);

    // NOTE: Breez SDK already syncs automatically when connecting (in breezClientProvider)
    // So we no longer need to call sync() here

    // NOTE: Providers have already been invalidated by _invalidateDataProviders() before calling this method
    // No need to invalidate again here

    // Give the UI a breather before starting heavy operations
    await Future.delayed(Duration.zero);

    // Fetch transactions (to populate history)
    final transactionCacheNotifier = ref.read(
      transactionHistoryCacheProvider.notifier,
    );

    debugPrint('[WalletDataManager] Fetching transactions...');
    await transactionCacheNotifier.fetchTransactionsInitial();
    debugPrint('[WalletDataManager] Transactions loaded');

    // Give the UI another breather before fetching balances
    await Future.delayed(Duration.zero);

    // Fetch balances (Breez already synced at connection time)
    debugPrint('[WalletDataManager] Fetching balances...');
    final balanceCacheNotifier = ref.read(balanceCacheProvider.notifier);
    final balanceLoadingFutures =
        favoriteAssets.map((asset) {
          return balanceCacheNotifier.fetchBalanceInitial(asset);
        }).toList();

    final assetCacheNotifier = ref.read(
      assetPriceHistoryCacheProvider.notifier,
    );
    final priceFutures =
        favoriteAssets.map((asset) {
          return assetCacheNotifier.fetchAssetPriceHistoryInitial(asset);
        }).toList();

    await Future.wait([...balanceLoadingFutures, ...priceFutures]);

    debugPrint('[WalletDataManager] Balances and prices loaded successfully!');
  }

  Future<void> _invalidateAndRefreshAllProviders() async {
    _invalidateDataProviders();

    final favoriteAssets = ref.read(favoriteAssetsProvider);

    await Future.wait([
      ref.read(transactionHistoryCacheProvider.notifier).refresh(),
      ref.read(assetPriceHistoryCacheProvider.notifier).refresh(favoriteAssets),
      ref.read(balanceCacheProvider.notifier).refresh(favoriteAssets),
    ]);
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    const syncInterval = Duration(minutes: 1);

    _periodicSyncTimer = Timer.periodic(syncInterval, (timer) {
      _performPeriodicSync();
    });

    debugPrint(
      '[WalletDataManager] Periodic sync started (${syncInterval.inMinutes} min) - next sync in ${syncInterval.inMinutes} minute(s)',
    );
  }

  Future<void> _performPeriodicSync() async {
    if (state.isLoadingOrRefreshing) {
      debugPrint(
        '[WalletDataManager] Sync already in progress, skipping periodic sync',
      );
      return;
    }

    debugPrint('[WalletDataManager] Running periodic sync...');

    await refreshWalletData();

    debugPrint('[WalletDataManager] Periodic sync completed');
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    debugPrint('[WalletDataManager] Periodic sync stopped');
  }

  /// Forces a manual onchain swaps rescan.
  /// Use this if you suspect funds were sent to a previously used swap address.
  // Future<void> forceRescanOnchainSwaps() async {
  //   debugPrint('[WalletDataManager] Manual rescan requested by user');
  //   await _rescanOnchainSwaps();

  //   // After rescan, update transactions
  //   debugPrint('[WalletDataManager] Updating transaction cache after rescan...');
  //   await ref.read(transactionHistoryCacheProvider.notifier).refresh();
  //   debugPrint('[WalletDataManager] Manual rescan completed');
  // }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    _currentSyncCompleter?.complete();
    super.dispose();
  }
}

final walletDataManagerProvider =
    StateNotifierProvider<WalletDataManager, WalletDataStatus>((ref) {
      final manager = WalletDataManager(ref);

      if (WalletSyncConfig.isAutoResetEnabled) {
        ref.onDispose(() {
          WalletSyncLogger.debug(
            '[WalletDataManagerProvider] Hot reload detected - resetting state',
          );
        });
      }

      return manager;
    });

final isLoadingDataProvider = Provider<bool>((ref) {
  return ref.watch(walletDataManagerProvider).isLoading;
});

final isRefreshingDataProvider = Provider<bool>((ref) {
  return ref.watch(walletDataManagerProvider).isRefreshing;
});

final hasSyncFailuresProvider = Provider<bool>((ref) {
  final status = ref.watch(walletDataManagerProvider);
  return status.hasLiquidSyncFailed ||
      status.hasBdkSyncFailed ||
      status.hasError;
});

final syncFailureDetailsProvider = Provider<String?>((ref) {
  return ref.watch(walletDataManagerProvider).errorMessage;
});

final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(walletDataManagerProvider).lastSync;
});

final forceResetWalletDataProvider = Provider<void>((ref) {
  if (!WalletSyncConfig.isAutoResetEnabled) {
    return;
  }

  ref.read(walletDataManagerProvider.notifier).resetState();

  Timer(const Duration(milliseconds: 1000), () {
    final currentState = ref.read(walletDataManagerProvider);
    if (currentState.state == WalletDataState.idle) {
      WalletSyncLogger.debug('[ForceReset] Reinitializing after reset...');
      ref.read(walletDataManagerProvider.notifier).initializeWallet();
    }
  });
});
