import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_monitor_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/boot/boot_orchestrator.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_event_stream.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/key_management/providers/pin_store_provider.dart';
import 'package:mooze_mobile/shared/key_management/providers/has_pin_provider.dart';
import 'package:mooze_mobile/shared/key_management/store/mnemonic_store_impl.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/authentication/providers/session_manager_service_provider.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/user/services/user_level_storage_service.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';
import 'package:mooze_mobile/features/swap/presentation/providers/swap_controller.dart';
import 'package:mooze_mobile/features/swap/di/providers/swap_repository_provider.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_config.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  StreamSubscription<SyncProgress>? _syncSubscription;
  int _dataSourceRetryCount = 0;
  static const int _maxDataSourceRetries = 5;
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  AppLoggerService get _logger => ref.read(appLoggerProvider);

  WalletDataManager(this.ref)
    : super(const WalletDataStatus(state: WalletDataState.idle)) {
    _listenToSyncProgress();
    _listenToTransactionEvents();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _transactionSubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _currentSyncCompleter?.complete();
    super.dispose();
  }

  StreamSubscription<TransactionEvent>? _transactionSubscription;

  void _listenToTransactionEvents() {
    final syncStream = ref.read(syncStreamProvider);

    _transactionSubscription = syncStream.transactionStream.listen((event) {
      _logger.info(
        'WalletDataManager',
        'Transaction event: ${event.eventType} for ${event.txId} on ${event.blockchain}',
      );

      _handleTransactionEvent(event);
    });
  }

  void _handleTransactionEvent(TransactionEvent event) {
    try {
      switch (event.eventType) {
        case TransactionEventType.newTransaction:
          _logger.info(
            'WalletDataManager',
            'New transaction received: ${event.txId} (${event.blockchain})',
          );

          ref.invalidate(transactionHistoryProvider);

          // TODO: Mostrar notificação de nova transação
          // if (event.newStatus == 'receive') {
          //   showNewTransactionNotification(event.txId);
          // }
          break;

        case TransactionEventType.statusChanged:
          _logger.info(
            'WalletDataManager',
            'Transaction status changed: ${event.txId} (${event.oldStatus} -> ${event.newStatus})',
          );

          ref.invalidate(transactionHistoryProvider);

          // TODO: Mostrar notificação de mudança de status
          // if (event.newStatus == 'confirmed') {
          //   showTransactionConfirmedNotification(event.txId);
          // }
          break;

        case TransactionEventType.confirmationsChanged:
          _logger.debug(
            'WalletDataManager',
            'Transaction confirmations changed: ${event.txId} (${event.oldConfirmations} -> ${event.newConfirmations})',
          );

          if ((event.newConfirmations ?? 0) >= 6) {
            ref.invalidate(transactionHistoryProvider);
          }
          break;
      }
    } catch (e, stack) {
      _logger.error(
        'WalletDataManager',
        'Error handling transaction event: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _listenToSyncProgress() {
    final syncStream = ref.read(syncStreamProvider);

    _syncSubscription = syncStream.stream.listen((progress) {
      _logger.debug(
        'WalletDataManager',
        'Sync progress: ${progress.datasource} - ${progress.status}',
      );

      switch (progress.status) {
        case SyncStatus.syncing:
          _logger.info(
            'WalletDataManager',
            '${progress.datasource} sync started',
          );
          state = state.copyWith(state: WalletDataState.refreshing);
          break;

        case SyncStatus.completed:
          _logger.info(
            'WalletDataManager',
            '${progress.datasource} sync completed',
          );

          _refreshProvidersAfterSync();

          _updateSyncMetadata(progress.datasource);
          break;

        case SyncStatus.error:
          _logger.error(
            'WalletDataManager',
            '${progress.datasource} sync failed: ${progress.errorMessage}',
          );
          break;

        default:
          break;
      }
    });
  }

  Future<void> _updateSyncMetadata(String datasource) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final transactionCount = await db.getTransactionCount();

      await db.updateSyncMetadata(
        datasource: datasource.toLowerCase(),
        lastSyncTime: DateTime.now(),
        transactionCount: transactionCount,
        syncStatus: 'completed',
      );

      _logger.debug(
        'WalletDataManager',
        'Updated sync metadata for $datasource',
      );
    } catch (e, stack) {
      _logger.error(
        'WalletDataManager',
        'Failed to update sync metadata: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _refreshProvidersAfterSync() {
    try {
      _logger.debug(
        'WalletDataManager',
        'Sync completed - providers will fetch fresh data on next access',
      );

      state = state.copyWith(lastSync: DateTime.now());

      _logger.debug('WalletDataManager', 'Sync timestamp updated');
    } catch (e) {
      _logger.warning('WalletDataManager', 'Error updating sync timestamp: $e');
    }
  }

  /// Initializes the wallet
  ///
  /// [skipInitialSync] - If true, skips the initial blockchain sync.
  /// This should be set to true when BootOrchestrator has already performed the initial sync.
  /// [runSyncInBackground] - If true, runs the sync in background without waiting.
  /// This is useful during wallet import to not block the UI.
  Future<void> initializeWallet({
    bool skipInitialSync = false,
    bool runSyncInBackground = false,
  }) async {
    if (state.isLoadingOrRefreshing) {
      _logger.warning(
        'WalletDataManager',
        'Initialization already in progress, ignoring',
      );
      _startPeriodicSync();
      return;
    }

    _logger.info(
      'WalletDataManager',
      'Starting wallet initialization... (skipInitialSync: $skipInitialSync, runSyncInBackground: $runSyncInBackground)',
    );

    if (skipInitialSync) {
      _logger.info(
        'WalletDataManager',
        'Skipping full initialization - boot is managing sync',
      );

      _startPeriodicSync();

      state = state.copyWith(
        state: WalletDataState.success,
        isInitialLoad: false,
        lastSync: DateTime.now(),
      );

      _logger.info(
        'WalletDataManager',
        'WalletDataManager ready - providers will load on demand',
      );

      return;
    }

    state = state.copyWith(state: WalletDataState.loading, isInitialLoad: true);

    try {
      _logger.debug('WalletDataManager', 'Verifying mnemonic availability...');
      final mnemonicOption = await ref.read(mnemonicProvider.future);

      if (mnemonicOption.isNone()) {
        _logger.error(
          'WalletDataManager',
          'Cannot initialize wallet: Mnemonic is not available',
        );
        state = state.copyWith(
          state: WalletDataState.error,
          errorMessage:
              'Mnemonic not available. Please import or create a wallet first.',
        );
        return;
      }

      _logger.info('WalletDataManager', 'Mnemonic verified and available');

      await Future.delayed(const Duration(milliseconds: 500));

      _logger.debug('WalletDataManager', 'Checking datasource availability...');
      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      final bdkResult = await ref.read(bdkDatasourceProvider.future);

      bool hasValidDataSource = false;
      bool liquidAvailable = false;
      bool bdkAvailable = false;

      liquidResult.fold(
        (error) {
          _logger.error(
            'WalletDataManager',
            'Liquid datasource not available',
            error: error,
          );
          state = state.copyWith(hasLiquidSyncFailed: true);
        },
        (success) {
          _logger.info('WalletDataManager', 'Liquid datasource available');
          hasValidDataSource = true;
          liquidAvailable = true;
        },
      );

      bdkResult.fold(
        (error) {
          _logger.error(
            'WalletDataManager',
            'BDK datasource not available',
            error: error,
          );
          state = state.copyWith(hasBdkSyncFailed: true);
        },
        (success) {
          _logger.info('WalletDataManager', 'BDK datasource available');
          hasValidDataSource = true;
          bdkAvailable = true;
        },
      );

      if (!hasValidDataSource) {
        _logger.warning(
          'WalletDataManager',
          'No datasource available (attempt ${_dataSourceRetryCount + 1}/$_maxDataSourceRetries)',
        );

        if (_dataSourceRetryCount < _maxDataSourceRetries) {
          _dataSourceRetryCount++;
          final retryDelay = _initialRetryDelay * _dataSourceRetryCount;

          _logger.info(
            'WalletDataManager',
            'Retrying datasource recreation in ${retryDelay.inSeconds}s...',
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
          final stackTrace = StackTrace.current;
          _logger.critical(
            'WalletDataManager',
            'Failed to initialize datasources after $_maxDataSourceRetries attempts',
            stackTrace: stackTrace,
          );
          throw Exception(
            'No datasource available after $_maxDataSourceRetries attempts. '
            'Check your connection and try again.',
          );
        }
      }

      _dataSourceRetryCount = 0;

      _logger.info(
        'WalletDataManager',
        'Verificando se deve fazer sync... skipInitialSync: $skipInitialSync',
      );

      if (!skipInitialSync) {
        _logger.info(
          'WalletDataManager',
          'ENTRANDO no bloco de sync (skipInitialSync é false)',
        );
        await Future.delayed(Duration.zero);

        final syncFutures = <Future<void>>[];

        _logger.debug(
          'WalletDataManager',
          'liquidAvailable: $liquidAvailable, bdkAvailable: $bdkAvailable',
        );

        if (liquidAvailable) {
          liquidResult.fold((_) {}, (datasource) {
            _logger.debug(
              'WalletDataManager',
              'Starting Liquid initial sync...',
            );
            syncFutures.add(
              Future.delayed(Duration.zero).then(
                (_) => datasource
                    .sync()
                    .then((_) {
                      _logger.info(
                        'WalletDataManager',
                        'Liquid initial sync completed',
                      );
                    })
                    .catchError((e) {
                      _logger.error(
                        'WalletDataManager',
                        'Liquid initial sync failed',
                        error: e,
                      );
                    }),
              ),
            );
          });
        } else {
          _logger.debug(
            'WalletDataManager',
            'Liquid não disponível - pulando sync',
          );
        }

        // Sync BDK
        if (bdkAvailable) {
          bdkResult.fold((_) {}, (datasource) {
            _logger.debug('WalletDataManager', 'Starting BDK initial sync...');
            syncFutures.add(
              Future.delayed(Duration.zero).then(
                (_) => datasource
                    .sync()
                    .then((_) {
                      _logger.info(
                        'WalletDataManager',
                        'BDK initial sync completed',
                      );
                    })
                    .catchError((e) {
                      _logger.error(
                        'WalletDataManager',
                        'BDK initial sync failed',
                        error: e,
                      );
                    }),
              ),
            );
          });
        } else {
          _logger.debug(
            'WalletDataManager',
            'BDK não disponível - pulando sync',
          );
        }

        _logger.debug(
          'WalletDataManager',
          'Total de syncs agendados: ${syncFutures.length}',
        );

        if (syncFutures.isNotEmpty) {
          _logger.info(
            'WalletDataManager',
            'Waiting for ${syncFutures.length} sync(s) to complete...',
          );

          if (runSyncInBackground) {
            _logger.info(
              'WalletDataManager',
              'Running syncs in background (non-blocking)...',
            );
            // Fire and forget - don't wait for sync to complete
            Future.wait(syncFutures)
                .then((_) async {
                  _logger.info(
                    'WalletDataManager',
                    'Background syncs completed, refreshing cache...',
                  );
                  // Invalidate providers and refresh cache after background sync completes
                  await _invalidateAndRefreshAllProviders();
                })
                .catchError((e) {
                  _logger.error(
                    'WalletDataManager',
                    'Background sync failed',
                    error: e,
                  );
                });
          } else {
            await Future.wait(syncFutures);
            _logger.info('WalletDataManager', 'All initial syncs completed');
          }
        }
      } else {
        _logger.info(
          'WalletDataManager',
          'Skipping initial sync (already done by BootOrchestrator)',
        );
      }

      // Only invalidate and load if not running sync in background
      if (!runSyncInBackground || skipInitialSync) {
        _logger.debug(
          'WalletDataManager',
          'Invalidating data providers after sync...',
        );
        _invalidateDataProviders();

        _logger.debug(
          'WalletDataManager',
          'Loading initial data after sync...',
        );
        await _loadInitialData();
      } else {
        _logger.info(
          'WalletDataManager',
          'Skipping initial data load (sync running in background)',
        );
      }

      _startPeriodicSync();

      state = state.copyWith(
        state: WalletDataState.success,
        lastSync: DateTime.now(),
        isInitialLoad: false,
      );

      _logger.info('WalletDataManager', 'Wallet initialized successfully');

      // Async auth check (non-blocking) - moved to end as per priority restructure
      Future.delayed(Duration.zero, () {
        _logger.debug(
          'WalletDataManager',
          'Starting background authentication check...',
        );
        ref
            .read(ensureAuthSessionProvider.future)
            .then((ensured) {
              if (ensured) {
                _logger.info(
                  'WalletDataManager',
                  'Authentication session verified',
                );
              } else {
                _logger.warning(
                  'WalletDataManager',
                  'Authentication session not ensured',
                );
              }
            })
            .catchError((e) {
              _logger.warning(
                'WalletDataManager',
                'Auth background check failed (not critical)',
                error: e,
              );
            });
      });
    } catch (error, stackTrace) {
      _logger.error(
        'WalletDataManager',
        'Wallet initialization failed',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        state: WalletDataState.error,
        errorMessage: error.toString(),
        isInitialLoad: false,
      );
    }
  }

  void resetState() {
    _logger.info('WalletDataManager', 'Resetting wallet data manager state...');
    state = const WalletDataStatus(state: WalletDataState.idle);
    _periodicSyncTimer?.cancel();
    _currentSyncCompleter?.complete();
    _currentSyncCompleter = null;
    _dataSourceRetryCount = 0;

    // Invalidate mnemonic to ensure fresh data on next initialization
    ref.invalidate(mnemonicProvider);

    _logger.debug('WalletDataManager', 'State reset completed');
  }

  void notifyDataSourceRecovered(String dataSourceType) {
    _logger.info('WalletDataManager', 'Datasource $dataSourceType recovered');

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
      _logger.info(
        'WalletDataManager',
        'All datasources recovered, reinitializing wallet...',
      );
      initializeWallet();
    }
  }

  void notifyLiquidSyncFailed(String error) {
    _logger.error('WalletDataManager', 'Liquid sync failed', error: error);

    state = state.copyWith(
      hasLiquidSyncFailed: true,
      errorMessage: 'Liquid sync failed: $error',
    );
  }

  void notifyBdkSyncFailed(String error) {
    _logger.error('WalletDataManager', 'BDK sync failed', error: error);

    state = state.copyWith(
      hasBdkSyncFailed: true,
      errorMessage: 'BDK sync failed: $error',
    );
  }

  Future<void> retryDataSourceConnection() async {
    _logger.info(
      'WalletDataManager',
      'Manual datasource reconnection attempt...',
    );

    _dataSourceRetryCount = 0;

    // CRITICAL: Invalidate mnemonic first to ensure fresh data
    ref.invalidate(mnemonicProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(breezClientProvider);

    await Future.delayed(const Duration(milliseconds: 500));

    await initializeWallet();
  }

  Future<void> refreshWalletData() async {
    if (_currentSyncCompleter != null) {
      _logger.debug(
        'WalletDataManager',
        'Sync already in progress, waiting...',
      );
      await _currentSyncCompleter!.future;
      return;
    }

    _currentSyncCompleter = Completer<void>();

    try {
      _logger.info(
        'WalletDataManager',
        'Starting manual wallet data refresh...',
      );
      state = state.copyWith(state: WalletDataState.refreshing);

      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      final bdkResult = await ref.read(bdkDatasourceProvider.future);

      bool hasValidDataSource = false;
      bool liquidFailed = false;
      bool bdkFailed = false;

      liquidResult.fold(
        (error) {
          _logger.warning(
            'WalletDataManager',
            '⚠️ Liquid datasource error during refresh',
            error: error,
          );
          liquidFailed = true;
        },
        (success) {
          _logger.debug(
            'WalletDataManager',
            'Liquid datasource available for refresh',
          );
          hasValidDataSource = true;
        },
      );

      bdkResult.fold(
        (error) {
          _logger.warning(
            'WalletDataManager',
            'BDK datasource error during refresh',
            error: error,
          );
          bdkFailed = true;
        },
        (success) {
          _logger.debug(
            'WalletDataManager',
            'BDK datasource available for refresh',
          );
          hasValidDataSource = true;
        },
      );

      if (!hasValidDataSource) {
        _logger.error(
          'WalletDataManager',
          'No datasource available during refresh',
        );

        state = state.copyWith(
          state: WalletDataState.error,
          errorMessage: 'Datasources not available. Trying to reconnect...',
          hasLiquidSyncFailed: liquidFailed,
          hasBdkSyncFailed: bdkFailed,
        );

        _logger.info(
          'WalletDataManager',
          'Attempting to reinitialize datasources...',
        );

        ref.invalidate(liquidDataSourceProvider);
        ref.invalidate(bdkDatasourceProvider);

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            debugPrint('[WalletDataManager] Trying full reinitialization...');
            initializeWallet();
          }
        });

        // Complete the sync completer before returning
        _currentSyncCompleter?.complete();
        _currentSyncCompleter = null;

        return;
      }

      debugPrint('[WalletDataManager] Sincronizando datasources...');
      final syncFutures = <Future<void>>[];

      liquidResult.fold(
        (_) => debugPrint(
          '[WalletDataManager] ⏭Skipping Liquid sync (with error)',
        ),
        (datasource) {
          _logger.info('WalletDataManager', 'Syncing Liquid during refresh...');

          syncFutures.add(
            datasource.sync().catchError((e) {
              _logger.error(
                'WalletDataManager',
                'Error syncing Liquid during refresh',
                error: e,
              );
            }),
          );
        },
      );

      bdkResult.fold(
        (_) => _logger.debug(
          'WalletDataManager',
          'Skipping BDK sync (with error)',
        ),
        (datasource) {
          _logger.info('WalletDataManager', 'Syncing BDK during refresh...');
          syncFutures.add(
            datasource.sync().catchError((e) {
              _logger.error(
                'WalletDataManager',
                'Error syncing BDK during refresh',
                error: e,
              );
            }),
          );
        },
      );

      await Future.wait(syncFutures);
      _logger.info('WalletDataManager', 'Datasources synced successfully');

      // Rescan onchain swaps to detect additional funds sent to already used addresses
      await _rescanOnchainSwapsAndCheckRefundables();

      await _invalidateAndRefreshAllProviders();

      await _syncPendingTransactions();

      _logger.debug(
        'WalletDataManager',
        'Forcing cache refresh after pending sync',
      );
      await ref.read(transactionHistoryCacheProvider.notifier).refresh();

      state = state.copyWith(
        state: WalletDataState.success,
        lastSync: DateTime.now(),
        hasLiquidSyncFailed: liquidFailed,
        hasBdkSyncFailed: bdkFailed,
      );

      _logger.info(
        'WalletDataManager',
        'Manual refresh completed successfully',
      );
    } catch (error, stackTrace) {
      _logger.error(
        'WalletDataManager',
        'Manual refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
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
      _logger.debug('WalletDataManager', 'Syncing pending transactions...');
      final monitorService = ref.read(transactionMonitorServiceProvider);
      await monitorService.syncPendingTransactions();
      _logger.info('WalletDataManager', 'Pending transactions synced');
    } catch (e, stackTrace) {
      _logger.error(
        'WalletDataManager',
        'Error syncing pending transactions',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Rescans onchain swaps and checks for refundable transactions.
  ///
  /// This detects additional funds sent to already used swap addresses and
  /// identifies transactions that can be refunded.
  Future<void> _rescanOnchainSwapsAndCheckRefundables() async {
    try {
      _logger.info('WalletDataManager', '🔍 Starting onchain swaps rescan...');

      final breezClient = await ref.read(breezClientProvider.future);

      await breezClient.fold(
        (error) {
          _logger.error(
            'WalletDataManager',
            'Breez client not available for rescan',
            error: error,
          );
          return Future<void>.value();
        },
        (client) async {
          try {
            // Rescan onchain swaps
            await client.rescanOnchainSwaps();
            _logger.info(
              'WalletDataManager',
              'Onchain swaps rescan completed successfully',
            );

            // Check for refundable swaps
            final refundables = await client.listRefundables();
            _logger.info(
              'WalletDataManager',
              '📋 Found ${refundables.length} refundable swap(s)',
            );

            if (refundables.isNotEmpty) {
              _logger.warning(
                'WalletDataManager',
                '⚠️ Refundable swaps detected:',
              );
              for (var refundable in refundables) {
                _logger.warning(
                  'WalletDataManager',
                  '  - Address: ${refundable.swapAddress}, Amount: ${refundable.amountSat} sats',
                );
              }
            }
          } catch (e, stackTrace) {
            _logger.error(
              'WalletDataManager',
              'Error during swaps rescan',
              error: e,
              stackTrace: stackTrace,
            );
          }
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'WalletDataManager',
        'Error trying to rescan swaps',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _invalidateDataProviders() {
    _logger.debug(
      'WalletDataManager',
      'Invalidating data providers (keeping datasources and cache state)...',
    );

    ref.invalidate(walletRepositoryProvider);

    // Invalidate data fetching providers
    ref.invalidate(transactionControllerProvider);
    ref.invalidate(transactionHistoryProvider);
    // DON'T invalidate transactionHistoryCacheProvider - it holds the cache state!
    // Instead, we'll call refresh() on it after to update with new data

    ref.invalidate(balanceControllerProvider);
    ref.invalidate(allBalancesProvider);
    // DON'T invalidate balanceCacheProvider - it holds the cache state!

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

    // DON'T invalidate assetPriceHistoryCacheProvider - it holds the cache state!
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
    _logger.info(
      'WalletDataManager',
      'Refreshing all data providers after sync...',
    );

    _invalidateDataProviders();

    final favoriteAssets = ref.read(favoriteAssetsProvider);

    _logger.debug(
      'WalletDataManager',
      'Calling refresh() on cache providers to update with new data...',
    );

    await Future.wait([
      ref.read(transactionHistoryCacheProvider.notifier).refresh(),
      ref.read(assetPriceHistoryCacheProvider.notifier).refresh(favoriteAssets),
      ref.read(balanceCacheProvider.notifier).refresh(favoriteAssets),
    ]);

    _logger.info(
      'WalletDataManager',
      'All cache providers refreshed successfully',
    );
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    const syncInterval = Duration(minutes: 1);

    _periodicSyncTimer = Timer.periodic(syncInterval, (timer) {
      debugPrint(
        '[WalletDataManager] ⏰ Timer disparou - chamando _performPeriodicSync()',
      );
      _performPeriodicSync();
    });

    _logger.info(
      'WalletDataManager',
      'Periodic sync started (${syncInterval.inMinutes} min) - next sync in ${syncInterval.inMinutes} minute(s)',
    );
    debugPrint(
      '[WalletDataManager] ✅ Periodic sync Timer configurado (${syncInterval.inMinutes} min)',
    );
  }

  Future<void> _performPeriodicSync() async {
    _logger.info('WalletDataManager', '🔄 Iniciando sync periódico...');

    _logger.debug(
      'WalletDataManager',
      'Estado atual: ${state.state}, isLoading: ${state.isLoading}, isRefreshing: ${state.isRefreshing}, _currentSyncCompleter: ${_currentSyncCompleter != null}',
    );

    // Check if there's actually a sync in progress using the completer
    if (_currentSyncCompleter != null) {
      _logger.debug(
        'WalletDataManager',
        'Sync em progresso (_currentSyncCompleter ativo), pulando sync periódico',
      );
      return;
    }

    // If state is stuck in refreshing but no completer, reset it
    if (state.isLoadingOrRefreshing) {
      _logger.warning(
        'WalletDataManager',
        'Estado preso em ${state.state} sem sync ativo, resetando para success',
      );
      state = state.copyWith(state: WalletDataState.success);
    }

    _logger.info('WalletDataManager', '🔄 Executando sync periódico...');

    await refreshWalletData();

    debugPrint('[WalletDataManager] Periodic sync completed');
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    debugPrint('[WalletDataManager] Periodic sync stopped');
  }

  /// Deletes the entire wallet and all associated data.
  ///
  /// This method performs a complete cleanup including:
  /// - Resetting wallet state
  /// - Invalidating all providers
  /// - Deleting secure storage data (mnemonic, JWT tokens)
  /// - Removing blockchain data directories
  /// - Clearing user verification level
  /// - Deleting PIN
  ///
  /// Returns true if deletion was successful, false otherwise.
  Future<bool> deleteWallet() async {
    try {
      // 1. FIRST: Reset wallet data manager state to stop all operations
      _logger.info('WalletDataManager', 'Step 1: Resetting wallet state...');
      resetState();
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. SECOND: Invalidate all wallet-related providers BEFORE deleting data
      _logger.info(
        'WalletDataManager',
        'Step 2: Invalidating all wallet providers...',
      );

      // Invalidate mnemonic FIRST - this is critical
      ref.invalidate(mnemonicProvider);

      // Invalidate datasources that depend on mnemonic
      ref.invalidate(bdkDatasourceProvider);
      ref.invalidate(liquidDataSourceProvider);
      ref.invalidate(breezClientProvider);

      await Future.delayed(const Duration(milliseconds: 500));

      // 3. THIRD: Delete mnemonic and auth data from secure storage
      _logger.info(
        'WalletDataManager',
        'Step 3: Deleting secure storage data...',
      );
      final secureStorage = SecureStorageProvider.instance;
      await secureStorage.delete(key: mnemonicKey);
      await secureStorage.delete(key: 'jwt');
      await secureStorage.delete(key: 'refresh_token');

      // 4. FOURTH: Invalidate auth-related providers
      _logger.info(
        'WalletDataManager',
        'Step 4: Invalidating auth providers...',
      );
      ref.invalidate(sessionManagerServiceProvider);
      ref.invalidate(authenticatedClientProvider);
      ref.invalidate(ensureAuthSessionProvider);
      ref.invalidate(userDataProvider);

      await Future.delayed(const Duration(milliseconds: 300));

      // 5. FIFTH: Delete blockchain data directories
      _logger.info(
        'WalletDataManager',
        'Step 5: Deleting blockchain directories...',
      );
      try {
        final workingDir = await getApplicationDocumentsDirectory();
        final breezDir = Directory("${workingDir.path}/mooze");
        if (await breezDir.exists()) {
          await breezDir.delete(recursive: true);
          _logger.info('WalletDataManager', 'Breez directory deleted');
        }
      } catch (e) {
        _logger.warning(
          'WalletDataManager',
          'Error deleting Breez directory',
          error: e,
        );
      }

      try {
        final localDir = await getApplicationSupportDirectory();
        final lwkDir = Directory("${localDir.path}/lwk-db");
        if (await lwkDir.exists()) {
          await lwkDir.delete(recursive: true);
          _logger.info('WalletDataManager', 'LWK directory deleted');
        }
      } catch (e) {
        _logger.warning(
          'WalletDataManager',
          'Error deleting LWK directory',
          error: e,
        );
      }

      // 6. SIXTH: Clear user verification level
      _logger.info(
        'WalletDataManager',
        'Step 6: Clearing user verification...',
      );
      final prefs = await SharedPreferences.getInstance();
      final userLevelStorage = UserLevelStorageService(prefs);
      await userLevelStorage.clearVerificationLevel();

      // 7. SEVENTH: Delete PIN
      _logger.info('WalletDataManager', 'Step 7: Deleting PIN...');
      final pinStore = ref.read(pinStoreProvider);
      await pinStore.deletePin().run();

      // 8. EIGHTH: Invalidate remaining providers
      _logger.info(
        'WalletDataManager',
        'Step 8: Invalidating remaining providers...',
      );

      // Wrap all invalidations in a single try-catch to prevent cascade errors
      try {
        // Only invalidate non-autoDispose providers that don't auto-reconnect
        ref.invalidate(hasPinProvider);

        // Skip wallet repository and transaction providers as they may try to reconnect
        // ref.invalidate(walletRepositoryProvider); // SKIP - may trigger reconnection
        // ref.invalidate(transactionControllerProvider); // SKIP - depends on wallet
        // ref.invalidate(transactionHistoryProvider); // SKIP - depends on wallet

        // Invalidate swap/websocket providers (best effort)
        try {
          ref.invalidate(swapControllerProvider);
          ref.invalidate(sideswapServiceProvider);
          ref.invalidate(sideswapApiProvider);
        } catch (_) {
          // Ignore errors from swap providers
        }

        // Note: Skip balance and wallet display providers as they depend on wallet repository
        // which may trigger reconnection attempts. They will be cleaned up automatically
        // when the user navigates away from the app.

        // Only invalidate cache providers (safe to invalidate)
        ref.invalidate(assetPriceHistoryCacheProvider);
        ref.invalidate(transactionHistoryCacheProvider);
        ref.invalidate(balanceCacheProvider);
      } catch (e) {
        _logger.warning(
          'WalletDataManager',
          'Error invalidating providers during wallet deletion (non-critical, continuing...)',
          error: e,
        );
      }

      // 9. FINAL: Wait for cleanup to complete
      _logger.info('WalletDataManager', 'Step 9: Finalizing cleanup...');
      await Future.delayed(const Duration(milliseconds: 500));

      _logger.info(
        'WalletDataManager',
        '✅ Wallet deletion completed successfully',
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'WalletDataManager',
        'Error during wallet deletion',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
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
