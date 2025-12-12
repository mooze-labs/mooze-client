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
        '[WalletDataManager] Inicialização já em andamento, ignorando',
      );
      return;
    }

    debugPrint('[WalletDataManager] Inicializando carteira...');

    state = state.copyWith(state: WalletDataState.loading, isInitialLoad: true);

    try {
      debugPrint('[WalletDataManager] Garantindo sessão de autenticação...');

      bool sessionEnsured = false;
      int attempts = 0;
      const maxAttempts = 3;

      while (!sessionEnsured && attempts < maxAttempts) {
        attempts++;
        debugPrint(
          '[WalletDataManager] Tentativa $attempts/$maxAttempts de garantir sessão...',
        );

        try {
          if (attempts > 1) {
            ref.invalidate(ensureAuthSessionProvider);
            await Future.delayed(Duration(seconds: attempts));
          }

          sessionEnsured = await ref.read(ensureAuthSessionProvider.future);

          if (sessionEnsured) {
            debugPrint(
              '[WalletDataManager] Sessão JWT garantida na tentativa $attempts',
            );
            break;
          } else {
            debugPrint(
              '[WalletDataManager] Sessão não garantida na tentativa $attempts',
            );
          }
        } catch (authError) {
          debugPrint(
            '[WalletDataManager] Erro na tentativa $attempts: $authError',
          );

          await Future.delayed(Duration(seconds: 2));

          if (attempts >= maxAttempts) {
            debugPrint(
              '[WalletDataManager] Máximo de tentativas atingido, continuando sem sessão...',
            );
            debugPrint(
              '[WalletDataManager]  Verifique os badges de status no topo da tela para mais informações',
            );
          }
        }
      }

      if (!sessionEnsured) {
        debugPrint(
          '[WalletDataManager] Inicializando sem sessão autenticada - algumas funcionalidades podem não funcionar',
        );
      }

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
        debugPrint(
          '[WalletDataManager] Nenhum datasource disponível (tentativa ${_dataSourceRetryCount + 1}/$_maxDataSourceRetries)',
        );

        if (_dataSourceRetryCount < _maxDataSourceRetries) {
          _dataSourceRetryCount++;
          final retryDelay = _initialRetryDelay * _dataSourceRetryCount;

          debugPrint(
            '[WalletDataManager] Tentando recriar datasources em ${retryDelay.inSeconds}s...',
          );

          state = state.copyWith(
            state: WalletDataState.error,
            errorMessage:
                'Tentando reconectar datasources ($_dataSourceRetryCount/$_maxDataSourceRetries)...',
            isInitialLoad: false,
          );

          await Future.delayed(retryDelay);

          ref.invalidate(liquidDataSourceProvider);
          ref.invalidate(bdkDatasourceProvider);

          return await initializeWallet();
        } else {
          _dataSourceRetryCount = 0;
          throw Exception(
            'Nenhum datasource disponível após $_maxDataSourceRetries tentativas. '
            'Verifique sua conexão e tente novamente.',
          );
        }
      }

      _dataSourceRetryCount = 0;

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
    _dataSourceRetryCount = 0;
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

  Future<void> retryDataSourceConnection() async {
    debugPrint(
      '[WalletDataManager] Tentativa manual de reconexão de datasources...',
    );

    _dataSourceRetryCount = 0;

    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(breezClientProvider);

    await Future.delayed(const Duration(milliseconds: 500));

    await initializeWallet();
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
          '[WalletDataManager] Nenhum datasource disponível durante refresh',
        );

        state = state.copyWith(
          state: WalletDataState.error,
          errorMessage: 'Datasources não disponíveis. Tentando reconectar...',
          hasLiquidSyncFailed: liquidFailed,
          hasBdkSyncFailed: bdkFailed,
        );

        debugPrint('[WalletDataManager] Tentando reinicializar datasources...');

        ref.invalidate(liquidDataSourceProvider);
        ref.invalidate(bdkDatasourceProvider);

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            debugPrint(
              '[WalletDataManager] Tentando reinicialização completa...',
            );
            initializeWallet();
          }
        });

        return;
      }

      debugPrint('[WalletDataManager] Sincronizando datasources...');
      final syncFutures = <Future<void>>[];

      liquidResult.fold(
        (_) => debugPrint(
          '[WalletDataManager] ⏭Pulando sync do Liquid (com erro)',
        ),
        (datasource) {
          debugPrint('[WalletDataManager] Sincronizando Liquid...');
          syncFutures.add(
            datasource.sync().catchError((e) {
              debugPrint('[WalletDataManager] Erro ao sincronizar Liquid: $e');
              return Future.value();
            }),
          );
        },
      );

      bdkResult.fold(
        (_) => debugPrint('[WalletDataManager] Pulando sync do BDK (com erro)'),
        (datasource) {
          debugPrint('[WalletDataManager] Sincronizando BDK...');
          syncFutures.add(
            datasource.sync().catchError((e) {
              debugPrint('[WalletDataManager] Erro ao sincronizar BDK: $e');
              return Future.value();
            }),
          );
        },
      );

      await Future.wait(syncFutures);
      debugPrint('[WalletDataManager] Datasources sincronizados');

      // Rescan onchain swaps para detectar fundos adicionais em endereços já usados
      // await _rescanOnchainSwaps();

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

  // /// Rescan de swaps onchain para detectar fundos adicionais enviados para endereços já usados.
  // /// Isso permite que transações refundable sejam detectadas corretamente.
  // ///
  // /// De acordo com a documentação do Breez SDK:
  // /// "Se usuários inadvertidamente enviam fundos adicionais para um endereço de swap já usado,
  // /// o SDK não reconhecerá automaticamente. Use este método para escanear manualmente
  // /// todos os endereços de swap históricos e atualizar seu status onchain."
  // Future<void> _rescanOnchainSwaps() async {
  //   try {
  //     debugPrint('[WalletDataManager] 🔍 Iniciando rescan de onchain swaps...');

  //     final breezClient = await ref.read(breezClientProvider.future);

  //     await breezClient.fold(
  //       (error) {
  //         debugPrint('[WalletDataManager] Breez client não disponível para rescan: $error');
  //         return Future<void>.value();
  //       },
  //       (client) async {
  //         try {
  //           await client.rescanOnchainSwaps();
  //           debugPrint('[WalletDataManager] Rescan de swaps onchain completado com sucesso');
  //         } catch (e) {
  //           debugPrint('[WalletDataManager] Erro durante rescan de swaps: $e');
  //         }
  //       },
  //     );
  //   } catch (e) {
  //     debugPrint('[WalletDataManager] Erro ao tentar rescan de swaps: $e');
  //   }
  // }

  void _invalidateDataProviders() {
    debugPrint(
      '[WalletDataManager] Invalidando providers de dados (mantendo datasources)...',
    );

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

  void invalidateAllWalletProviders() {
    ref.invalidate(mnemonicProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(breezClientProvider);

    _invalidateDataProviders();
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
    _invalidateDataProviders();

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
      '[WalletDataManager] Sync periódico iniciado (${syncInterval.inMinutes} min) - próximo sync em ${syncInterval.inMinutes} minuto(s)',
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

  /// Força um rescan manual de swaps onchain.
  /// Use isso se suspeitar que fundos foram enviados para um endereço de swap já usado.
  // Future<void> forceRescanOnchainSwaps() async {
  //   debugPrint('[WalletDataManager] Rescan manual solicitado pelo usuário');
  //   await _rescanOnchainSwaps();

  //   // Após rescan, atualiza as transações
  //   debugPrint('[WalletDataManager] Atualizando cache de transações após rescan...');
  //   await ref.read(transactionHistoryCacheProvider.notifier).refresh();
  //   debugPrint('[WalletDataManager] Rescan manual concluído');
  // }

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
