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

  WalletDataManager(this.ref)
    : super(const WalletDataStatus(state: WalletDataState.idle));

  Future<void> initializeWallet() async {
    if (state.isLoadingOrRefreshing) return;

    debugPrint('[WalletDataManager] Inicializando carteira...');

    state = state.copyWith(state: WalletDataState.loading, isInitialLoad: true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      final bdkResult = await ref.read(bdkDatasourceProvider.future);

      bool hasValidDataSource = false;

      liquidResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] Liquid datasource não disponível: $error',
          );
          state = state.copyWith(hasLiquidSyncFailed: true);
        },
        (success) {
          debugPrint('[WalletDataManager] Liquid datasource disponível');
          hasValidDataSource = true;
        },
      );

      bdkResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] BDK datasource não disponível: $error',
          );
          state = state.copyWith(hasBdkSyncFailed: true);
        },
        (success) {
          debugPrint('[WalletDataManager] BDK datasource disponível');
          hasValidDataSource = true;
        },
      );

      if (!hasValidDataSource) {
        throw Exception('Nenhum datasource disponível para inicialização');
      }

      if (hasValidDataSource) {
        await _loadInitialData();
      } else {
        await _loadPartialData();
      }

      _startPeriodicSync();

      state = state.copyWith(
        state: WalletDataState.success,
        lastSync: DateTime.now(),
        isInitialLoad: false,
      );

      debugPrint('[WalletDataManager] Carteira inicializada com sucesso');
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
    WalletSyncLogger.debug('[WalletDataManager] Resetando estado completo...');
    state = const WalletDataStatus(state: WalletDataState.idle);
    _periodicSyncTimer?.cancel();
    _currentSyncCompleter?.complete();
    _currentSyncCompleter = null;
  }

  void notifyDataSourceRecovered(String dataSourceType) {
    WalletSyncLogger.debug(
      '[WalletDataManager] Datasource $dataSourceType recuperado',
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
        '[WalletDataManager] Todos os datasources recuperados, reinicializando...',
      );
      initializeWallet();
    }
  }

  void notifyLiquidSyncFailed(String error) {
    WalletSyncLogger.error('[WalletDataManager] Liquid sync falhou: $error');

    state = state.copyWith(
      hasLiquidSyncFailed: true,
      errorMessage: 'Liquid sync failed: $error',
    );
  }

  void notifyBdkSyncFailed(String error) {
    debugPrint('[WalletDataManager] BDK sync falhou: $error');

    state = state.copyWith(
      hasBdkSyncFailed: true,
      errorMessage: 'BDK sync failed: $error',
    );
  }

  Future<void> _loadPartialData() async {
    debugPrint('[WalletDataManager] Carregando dados parciais...');

    try {
      final favoriteAssets = ref.read(favoriteAssetsProvider);

      final availableBalances = <String>[];

      for (final asset in favoriteAssets) {
        try {
          final balanceResult = await ref.read(balanceProvider(asset).future);
          balanceResult.fold(
            (error) => debugPrint(
              '[WalletDataManager] Ativo ${asset.ticker} indisponível: $error',
            ),
            (value) {
              availableBalances.add(asset.ticker);
              debugPrint(
                '[WalletDataManager] Ativo ${asset.ticker} disponível: $value',
              );
            },
          );
        } catch (e) {
          debugPrint(
            '[WalletDataManager] Erro ao testar ativo ${asset.ticker}: $e',
          );
        }
      }

      try {
        await ref
            .read(transactionHistoryCacheProvider.notifier)
            .fetchTransactionsInitial();
        debugPrint('[WalletDataManager] Transações carregadas com sucesso');
      } catch (e) {
        debugPrint('[WalletDataManager] Erro ao carregar transações: $e');
      }

      debugPrint(
        '[WalletDataManager] Dados parciais carregados: ${availableBalances.length} ativos disponíveis',
      );
    } catch (error) {
      debugPrint('[WalletDataManager] Erro ao carregar dados parciais: $error');
      rethrow;
    }
  }

  Future<void> refreshWalletData() async {
    if (_currentSyncCompleter != null) {
      debugPrint('[WalletDataManager] Sync já em progresso, aguardando...');
      await _currentSyncCompleter!.future;
      return;
    }

    _currentSyncCompleter = Completer<void>();

    try {
      debugPrint('[WalletDataManager] Iniciando refresh manual...');
      state = state.copyWith(state: WalletDataState.refreshing);

      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      final bdkResult = await ref.read(bdkDatasourceProvider.future);

      bool hasValidDataSource = false;
      bool liquidFailed = false;
      bool bdkFailed = false;

      liquidResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] ⚠️ Liquid datasource com erro durante refresh: $error',
          );
          liquidFailed = true;
        },
        (success) {
          debugPrint('[WalletDataManager] ✅ Liquid datasource disponível');
          hasValidDataSource = true;
        },
      );

      bdkResult.fold(
        (error) {
          debugPrint(
            '[WalletDataManager] ⚠️ BDK datasource com erro durante refresh: $error',
          );
          bdkFailed = true;
        },
        (success) {
          debugPrint('[WalletDataManager] ✅ BDK datasource disponível');
          hasValidDataSource = true;
        },
      );

      if (!hasValidDataSource) {
        debugPrint(
          '[WalletDataManager] ❌ Nenhum datasource disponível, abortando refresh',
        );
        state = state.copyWith(
          state: WalletDataState.error,
          errorMessage: 'Datasources não disponíveis',
          hasLiquidSyncFailed: liquidFailed,
          hasBdkSyncFailed: bdkFailed,
        );

        debugPrint(
          '[WalletDataManager] ⏭️ Pulando sincronização de transações pendentes',
        );
        return;
      }

      await _invalidateAndRefreshAllProviders();

      await _syncPendingTransactions();

      debugPrint(
        '[WalletDataManager] Forçando refresh do cache após sync de pendentes',
      );
      await ref.read(transactionHistoryCacheProvider.notifier).refresh();

      state = state.copyWith(
        state: WalletDataState.success,
        lastSync: DateTime.now(),
        hasLiquidSyncFailed: liquidFailed,
        hasBdkSyncFailed: bdkFailed,
      );

      debugPrint('[WalletDataManager] Refresh manual concluído');
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
      debugPrint('[WalletDataManager] Sincronização de pendentes disparada');
      final monitorService = ref.read(transactionMonitorServiceProvider);
      await monitorService.syncPendingTransactions();
      debugPrint('[WalletDataManager] Sincronização de pendentes concluída');
    } catch (e) {
      debugPrint('[WalletDataManager] Erro ao sincronizar pendentes: $e');
    }
  }

  void invalidateAllWalletProviders() {
    debugPrint(
      '[WalletDataManager] Invalidando todos os providers da carteira...',
    );

    ref.invalidate(mnemonicProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(breezClientProvider);
    ref.invalidate(walletRepositoryProvider);

    ref.invalidate(transactionControllerProvider);
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(transactionHistoryCacheProvider);

    ref.invalidate(balanceControllerProvider);
    ref.invalidate(allBalancesProvider);

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

  Future<void> _loadInitialData() async {
    final favoriteAssets = ref.read(favoriteAssetsProvider);

    final balanceLoadingFutures =
        favoriteAssets.map((asset) {
          return ref
              .read(balanceProvider(asset).future)
              .then((balance) {
                balance.fold(
                  (error) => debugPrint(
                    '[WalletDataManager] Erro ao carregar saldo $asset: $error',
                  ),
                  (value) => debugPrint(
                    '[WalletDataManager] Saldo $asset carregado: $value',
                  ),
                );
              })
              .catchError((error) {
                debugPrint(
                  '[WalletDataManager] Exceção ao carregar saldo $asset: $error',
                );
              });
        }).toList();

    final transactionCacheNotifier = ref.read(
      transactionHistoryCacheProvider.notifier,
    );
    final transactionFuture =
        transactionCacheNotifier.fetchTransactionsInitial();

    final assetCacheNotifier = ref.read(
      assetPriceHistoryCacheProvider.notifier,
    );
    final priceFutures =
        favoriteAssets.map((asset) {
          return assetCacheNotifier.fetchAssetPriceHistoryInitial(asset);
        }).toList();

    await Future.wait([
      ...balanceLoadingFutures,
      transactionFuture,
      ...priceFutures,
    ]);
  }

  Future<void> _invalidateAndRefreshAllProviders() async {
    invalidateAllWalletProviders();

    final favoriteAssets = ref.read(favoriteAssetsProvider);

    await Future.wait([
      ref.read(transactionHistoryCacheProvider.notifier).refresh(),
      ref.read(assetPriceHistoryCacheProvider.notifier).refresh(favoriteAssets),
    ]);
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    const syncInterval = Duration(minutes: 1);
    _periodicSyncTimer = Timer.periodic(syncInterval, (timer) {
      _performPeriodicSync();
    });

    debugPrint(
      '[WalletDataManager] Sync periódico iniciado (${syncInterval.inMinutes} min)',
    );
  }

  Future<void> _performPeriodicSync() async {
    if (state.isLoadingOrRefreshing) {
      debugPrint(
        '[WalletDataManager] Sync já em andamento, pulando sync periódico',
      );
      return;
    }

    debugPrint('[WalletDataManager] Executando sync periódico...');

    await refreshWalletData();

    debugPrint('[WalletDataManager] Sync periódico concluído');
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    debugPrint('[WalletDataManager] Sync periódico parado');
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    _currentSyncCompleter?.complete();
    super.dispose();
  }
}

final walletDataManagerProvider = StateNotifierProvider<
  WalletDataManager,
  WalletDataStatus
>((ref) {
  final manager = WalletDataManager(ref);

  if (WalletSyncConfig.isAutoResetEnabled) {
    ref.onDispose(() {
      WalletSyncLogger.debug(
        '[WalletDataManagerProvider] Hot reload detectado - resetando estado',
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
      WalletSyncLogger.debug('[ForceReset] Reinicializando após reset...');
      ref.read(walletDataManagerProvider.notifier).initializeWallet();
    }
  });
});
