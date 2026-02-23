import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';
import 'package:mutex/mutex.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
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

/// Encapsulates all wallet synchronization logic
/// Protected by a Mutex to ensure only one sync operation runs at a time
///
/// ## Architecture Pattern (Mutex as Guard)
///
/// This class acts as a **synchronized resource** protected by `WalletDataManager._syncMutex`.
///
/// The pattern follows this model:
/// 1. `WalletSynchronizer` contains all sync operations (`performLightSync`, `performFullSync`)
/// 2. `WalletDataManager` protects access to the synchronizer using `Mutex.protect()`
/// 3. The Mutex ensures only ONE sync operation executes globally at any time

class WalletSynchronizer {
  final Ref ref;
  WalletDataManager? _manager;

  WalletSynchronizer(this.ref);

  void setManager(WalletDataManager manager) {
    _manager = manager;
  }

  AppLoggerService get _logger => ref.read(appLoggerProvider);
  WalletDataManager get _stateManager => _manager!;

  /// Performs a lightweight sync that only updates:
  /// - New transactions
  /// - Current balances
  /// - Asset prices
  Future<void> performLightSync() async {
    _logger.info('WalletSynchronizer', ' STARTING LIGHT SYNC ');

    try {
      // Ensure transaction listener is active
      if (_stateManager._transactionSubscription == null) {
        debugPrint(
          '[WalletSynchronizer] Transaction listener was null, reconfiguring...',
        );
        _stateManager._listenToTransactionEvents();
      }

      // Step 1: Sync blockchains to fetch new transactions
      _logger.info(
        'WalletSynchronizer',
        'Step 1: Syncing blockchains for new transactions...',
      );

      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      final bdkResult = await ref.read(bdkDatasourceProvider.future);

      final syncFutures = <Future<void>>[];

      liquidResult.fold(
        (_) => _logger.debug(
          'WalletSynchronizer',
          'Skipping Liquid sync (datasource unavailable)',
        ),
        (datasource) {
          _logger.debug('WalletSynchronizer', 'Syncing Liquid...');
          syncFutures.add(
            datasource.sync().catchError((e) {
              _logger.warning(
                'WalletSynchronizer',
                'Liquid sync failed during light sync',
                error: e,
              );
            }),
          );
        },
      );

      bdkResult.fold(
        (_) => _logger.debug(
          'WalletSynchronizer',
          'Skipping BDK sync (datasource unavailable)',
        ),
        (datasource) {
          _logger.debug('WalletSynchronizer', 'Syncing BDK...');
          syncFutures.add(
            datasource.sync().catchError((e) {
              _logger.warning(
                'WalletSynchronizer',
                'BDK sync failed during light sync',
                error: e,
              );
            }),
          );
        },
      );

      await Future.wait(syncFutures);

      // Step 2: Refresh cache providers
      _logger.info(
        'WalletSynchronizer',
        'Step 2: Refreshing cache providers...',
      );

      await ref.read(transactionHistoryCacheProvider.notifier).refresh();

      final mainAssets = [Asset.lbtc, Asset.btc, Asset.usdt, Asset.depix];

      // CRITICAL: Invalidate allBalancesProvider FIRST to force fresh data fetch from blockchain
      ref.invalidate(allBalancesProvider);

      await ref.read(balanceCacheProvider.notifier).refresh(mainAssets);

      // Step 3: Invalidate computed providers
      ref.invalidate(cachedTransactionHistoryProvider);
      ref.invalidate(cachedBalanceProvider);
      ref.invalidate(walletHoldingsProvider);
      ref.invalidate(walletHoldingsWithBalanceProvider);

      // Step 4: Trigger UI refresh
      ref.read(dataRefreshTriggerProvider.notifier).triggerRefresh();

      _logger.info('WalletSynchronizer', 'LIGHT SYNC COMPLETED SUCCESSFULLY');
    } catch (error, stackTrace) {
      _logger.error(
        'WalletSynchronizer',
        'Lightweight sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw error;
    }
  }

  /// Performs a complete wallet synchronization including:
  /// - Full blockchain sync for all datasources
  /// - Onchain swaps rescan
  /// - All provider invalidation and refresh
  /// - Pending transactions sync
  Future<void> performFullSync() async {
    _logger.info(
      'WalletSynchronizer',
      'Starting full wallet synchronization...',
    );

    _stateManager.updateState(
      _stateManager.getCurrentState().copyWith(
        state: WalletDataState.refreshing,
      ),
    );

    final liquidResult = await ref.read(liquidDataSourceProvider.future);
    final bdkResult = await ref.read(bdkDatasourceProvider.future);

    bool hasValidDataSource = false;
    bool liquidFailed = false;
    bool bdkFailed = false;

    liquidResult.fold(
      (error) {
        _logger.warning(
          'WalletSynchronizer',
          'Liquid datasource error during refresh',
          error: error,
        );
        liquidFailed = true;
      },
      (success) {
        _logger.debug(
          'WalletSynchronizer',
          'Liquid datasource available for refresh',
        );
        hasValidDataSource = true;
      },
    );

    bdkResult.fold(
      (error) {
        _logger.warning(
          'WalletSynchronizer',
          'BDK datasource error during refresh',
          error: error,
        );
        bdkFailed = true;
      },
      (success) {
        _logger.debug(
          'WalletSynchronizer',
          'BDK datasource available for refresh',
        );
        hasValidDataSource = true;
      },
    );

    if (!hasValidDataSource) {
      _logger.error(
        'WalletSynchronizer',
        'No datasource available during refresh',
      );

      _stateManager.updateState(
        _stateManager.getCurrentState().copyWith(
          state: WalletDataState.error,
          errorMessage: 'Datasources not available. Trying to reconnect...',
          hasLiquidSyncFailed: liquidFailed,
          hasBdkSyncFailed: bdkFailed,
        ),
      );

      _logger.info(
        'WalletSynchronizer',
        'Attempting to reinitialize datasources...',
      );

      ref.invalidate(liquidDataSourceProvider);
      ref.invalidate(bdkDatasourceProvider);

      Future.delayed(const Duration(seconds: 3), () {
        if (_stateManager.mounted) {
          debugPrint('[WalletSynchronizer] Trying full reinitialization...');
          _stateManager.initializeWallet();
        }
      });

      return;
    }

    debugPrint('[WalletSynchronizer] Sincronizando datasources...');
    final syncFutures = <Future<void>>[];

    liquidResult.fold(
      (_) =>
          debugPrint('[WalletSynchronizer] ⏭Skipping Liquid sync (with error)'),
      (datasource) {
        _logger.info('WalletSynchronizer', 'Syncing Liquid during refresh...');

        syncFutures.add(
          datasource.sync().catchError((e) {
            _logger.error(
              'WalletSynchronizer',
              'Error syncing Liquid during refresh',
              error: e,
            );
          }),
        );
      },
    );

    bdkResult.fold(
      (_) =>
          _logger.debug('WalletSynchronizer', 'Skipping BDK sync (with error)'),
      (datasource) {
        _logger.info('WalletSynchronizer', 'Syncing BDK during refresh...');
        syncFutures.add(
          datasource.sync().catchError((e) {
            _logger.error(
              'WalletSynchronizer',
              'Error syncing BDK during refresh',
              error: e,
            );
          }),
        );
      },
    );

    await Future.wait(syncFutures);
    _logger.info('WalletSynchronizer', 'Datasources synced successfully');

    // Rescan onchain swaps to detect additional funds
    await _stateManager._rescanOnchainSwapsAndCheckRefundables();

    await _stateManager._invalidateAndRefreshAllProviders();

    await _stateManager._syncPendingTransactions();

    _logger.debug(
      'WalletSynchronizer',
      'Forcing cache refresh after pending sync',
    );
    await ref.read(transactionHistoryCacheProvider.notifier).refresh();

    _stateManager.updateState(
      _stateManager.getCurrentState().copyWith(
        state: WalletDataState.success,
        lastSync: DateTime.now(),
        hasLiquidSyncFailed: liquidFailed,
        hasBdkSyncFailed: bdkFailed,
      ),
    );

    _logger.info('WalletSynchronizer', 'Full sync completed successfully');
  }
}

class WalletDataManager extends StateNotifier<WalletDataStatus> {
  final Ref ref;
  Timer? _periodicSyncTimer;
  late final WalletSynchronizer _synchronizer;
  final _syncMutex = Mutex();
  StreamSubscription<SyncProgress>? _syncSubscription;
  int _dataSourceRetryCount = 0;
  static const int _maxDataSourceRetries = 5;
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  AppLoggerService get _logger => ref.read(appLoggerProvider);

  /// Returns true if there's a sync operation in progress
  bool get isSyncing => _syncMutex.isLocked;

  /// Public method to refresh UI after a transaction is sent or swapped.
  /// This should be called by repositories after broadcasting a transaction
  /// to immediately update balances and transaction history.
  void refreshAfterTransaction() {
    _logger.info(
      'WalletDataManager',
      'Manual refresh triggered after transaction sent/swapped',
    );
    _refreshAfterTransactionEvent();
  }

  /// Updates the state - callable by WalletSynchronizer
  void updateState(WalletDataStatus newState) {
    state = newState;
  }

  /// Gets current state - callable by WalletSynchronizer
  WalletDataStatus getCurrentState() {
    return state;
  }

  WalletDataManager(this.ref)
    : super(const WalletDataStatus(state: WalletDataState.idle)) {
    _synchronizer = WalletSynchronizer(ref);
    _synchronizer.setManager(this);
    debugPrint('[WalletDataManager] Constructor called, setting up listeners');
    _listenToSyncProgress();
    _listenToTransactionEvents();
    debugPrint('[WalletDataManager] Constructor completed');
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _transactionSubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  StreamSubscription<TransactionEvent>? _transactionSubscription;
  int _transactionEventCount = 0;

  void _listenToTransactionEvents() {
    // Cancel any existing subscription first
    _transactionSubscription?.cancel();
    _transactionEventCount = 0;

    final syncStream = ref.read(syncStreamProvider);

    debugPrint('[WalletDataManager] Setting up transaction event listener');
    debugPrint(
      '[WalletDataManager] SyncStreamController hashCode: ${syncStream.hashCode}',
    );
    debugPrint('[WalletDataManager] Instance ID should match emission logs');
    debugPrint('[WalletDataManager] Creating subscription...');

    _transactionSubscription = syncStream.transactionStream.listen(
      (event) {
        _transactionEventCount++;
        debugPrint(
          '[WalletDataManager] LISTENER CALLED #$_transactionEventCount! Event: ${event.txId}',
        );
        debugPrint(
          '[WalletDataManager] Received transaction event in listener! (controller: ${syncStream.hashCode})',
        );

        // Ignore test events
        if (event.txId == 'test-event') {
          debugPrint('[WalletDataManager] Test event received and ignored');
          return;
        }

        _logger.info(
          'WalletDataManager',
          'Transaction event: ${event.eventType} for ${event.txId} on ${event.blockchain}',
        );

        _handleTransactionEvent(event);
      },
      onError: (error, stackTrace) {
        debugPrint('[WalletDataManager] Error in transaction listener: $error');
        _logger.error(
          'WalletDataManager',
          'Error in transaction event listener',
          error: error,
          stackTrace: stackTrace,
        );
      },
      onDone: () {
        debugPrint(
          '[WalletDataManager] Transaction event stream closed (controller: ${syncStream.hashCode})',
        );
      },
      cancelOnError: false,
    );

    debugPrint(
      '[WalletDataManager] Subscription object created: ${_transactionSubscription != null}',
    );
    debugPrint(
      '[WalletDataManager] Transaction event listener configured successfully',
    );
    debugPrint(
      '[WalletDataManager] Subscription is active: ${_transactionSubscription != null && !_transactionSubscription!.isPaused}',
    );
    debugPrint(
      '[WalletDataManager] Ready to receive events on controller ${syncStream.hashCode}',
    );

    // Test emission to verify listener is working - with delay to ensure listener is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      debugPrint(
        '[WalletDataManager] Emitting test event to verify listener...',
      );
      syncStream.emitTransactionEvent(
        TransactionEvent(
          txId: 'test-event',
          eventType: TransactionEventType.statusChanged,
          blockchain: 'test',
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _handleTransactionEvent(TransactionEvent event) {
    // Ignore test events
    if (event.txId == 'test-event' || event.blockchain == 'test') {
      debugPrint('[WalletDataManager] Test event received and ignored');
      return;
    }

    try {
      // Log the event for monitoring purposes
      _logger.info(
        'WalletDataManager',
        'Transaction event received: ${event.eventType} for ${event.txId} (${event.blockchain})',
      );

      switch (event.eventType) {
        case TransactionEventType.newTransaction:
          _logger.info(
            'WalletDataManager',
            'NEW TRANSACTION DETECTED: ${event.txId}',
          );

          // Trigger immediate refresh for new transactions
          // This ensures UI updates as soon as transaction is detected
          _refreshAfterTransactionEvent();
          break;

        case TransactionEventType.statusChanged:
          _logger.info(
            'WalletDataManager',
            'Transaction status changed: ${event.txId} (${event.oldStatus} -> ${event.newStatus})',
          );

          // Also refresh on status changes (e.g., pending -> confirmed)
          _refreshAfterTransactionEvent();
          break;

        case TransactionEventType.confirmationsChanged:
          _logger.debug(
            'WalletDataManager',
            'Transaction confirmations changed: ${event.txId} (${event.oldConfirmations} -> ${event.newConfirmations})',
          );
          // No need to refresh on every confirmation count change
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

  // Lightweight refresh triggered by transaction events
  // Does NOT do blockchain sync (already done), just updates caches and UI
  void _refreshAfterTransactionEvent() {
    const String _refreshTag = '[REFRESH AFTER TRANSACTION]';

    Future.microtask(() async {
      try {
        debugPrint('$_refreshTag Microtask INICIADA!');

        _logger.info(
          'WalletDataManager',
          '$_refreshTag  Refreshing caches after transaction event...',
        );

        await ref.read(transactionHistoryCacheProvider.notifier).refresh();

        final mainAssets = [Asset.lbtc, Asset.btc, Asset.usdt, Asset.depix];

        ref.invalidate(allBalancesProvider);

        await ref.read(balanceCacheProvider.notifier).refresh(mainAssets);
        debugPrint('$_refreshTag Balances refreshed!');

        debugPrint('$_refreshTag Invalidating providers to force UI update...');
        ref.invalidate(cachedTransactionHistoryProvider);
        ref.invalidate(cachedBalanceProvider);
        ref.invalidate(walletHoldingsProvider);
        ref.invalidate(walletHoldingsWithBalanceProvider);
        debugPrint('$_refreshTag Providers invalidated!');

        debugPrint('$_refreshTag Triggering refresh notifier...');
        ref.read(dataRefreshTriggerProvider.notifier).triggerRefresh();
        debugPrint('$_refreshTag Refresh notifier triggered!');

        debugPrint(
          '$_refreshTag ⏳ Waiting 100ms before checking pending transactions...',
        );
        await Future.delayed(const Duration(milliseconds: 100));

        debugPrint('$_refreshTag Syncing pending transactions...');
        await _syncPendingTransactions();
        debugPrint('$_refreshTag Pending transactions synced!');

        _logger.info(
          'WalletDataManager',
          '$_refreshTag Event-triggered refresh completed',
        );
        debugPrint('$_refreshTag EVENT-TRIGGERED REFRESH COMPLETO!');
      } catch (e, stack) {
        debugPrint('$_refreshTag ERRO no event-triggered refresh: $e');
        _logger.error(
          'WalletDataManager',
          '$_refreshTag Error in event-triggered refresh: $e',
          error: e,
          stackTrace: stack,
        );
      }
    });
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
            'BDK not available - skipping sync',
          );
        }

        _logger.debug(
          'WalletDataManager',
          'Total syncs : ${syncFutures.length}',
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

  /// Performs a lightweight sync that only updates:
  /// - New transactions
  /// - Current balances
  /// - Asset prices
  ///
  /// This is much faster than a full sync and should be used for periodic updates.
  Future<void> lightSync() async {
    return _syncMutex.protect(() => _synchronizer.performLightSync());
  }

  /// Performs a complete wallet synchronization including:
  /// - Full blockchain sync for all datasources
  /// - Onchain swaps rescan
  /// - All provider invalidation and refresh
  /// - Pending transactions sync
  ///
  /// This is a heavy operation and should only be called manually by the user.
  Future<void> fullSyncWalletData() async {
    return _syncMutex.protect(() => _synchronizer.performFullSync());
  }

  /// Alias for backward compatibility - uses light sync by default
  /// For pull-to-refresh and similar user interactions.
  /// For full blockchain sync, use fullSyncWalletData() instead.
  Future<void> refreshWalletData() async {
    return lightSync();
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
      _logger.info('WalletDataManager', 'Starting onchain swaps rescan...');

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
              'Found ${refundables.length} refundable swap(s)',
            );

            if (refundables.isNotEmpty) {
              _logger.warning(
                'WalletDataManager',
                'Refundable swaps detected:',
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
    // Validate that there's no sync currently in progress before starting periodic sync
    if (isSyncing) {
      _logger.warning(
        'WalletDataManager',
        'Cannot start periodic sync: sync already in progress',
      );
      return;
    }

    _periodicSyncTimer?.cancel();
    const syncInterval = Duration(seconds: 40);

    _periodicSyncTimer = Timer.periodic(syncInterval, (timer) {
      debugPrint(
        '[WalletDataManager] Timer disparou - chamando _performPeriodicSync()',
      );
      _performPeriodicSync();
    });

    _logger.info(
      'WalletDataManager',
      'Periodic sync started (${syncInterval.inMinutes} min) - next sync in ${syncInterval.inMinutes} minute(s)',
    );
    debugPrint(
      '[WalletDataManager] Periodic sync Timer configurado (${syncInterval.inMinutes} min)',
    );
  }

  Future<void> _performPeriodicSync() async {
    _logger.info('WalletDataManager', ' Starting light periodic sync...');

    _logger.debug(
      'WalletDataManager',
      'Current state: ${state.state}, isLoading: ${state.isLoading}, isRefreshing: ${state.isRefreshing}, isSyncing: $isSyncing',
    );

    // Check if there's actually a sync in progress using the mutex
    if (isSyncing) {
      _logger.debug(
        'WalletDataManager',
        'Sync in progress (mutex locked), skipping periodic sync',
      );
      return;
    }

    // If state is stuck in refreshing but no completer, reset it
    if (state.isLoadingOrRefreshing) {
      _logger.warning(
        'WalletDataManager',
        'State stuck in ${state.state} without active sync, resetting to success',
      );
      state = state.copyWith(state: WalletDataState.success);
    }

    _logger.info('WalletDataManager', 'Starting light periodic sync...');

    await lightSync();

    debugPrint('[WalletDataManager] Periodic light sync completed');
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
      // Set wallet deletion flag to prevent any new Breez connections
      ref.read(setWalletDeletionFlagProvider(true));

      // 1. FIRST: Reset wallet data manager state and stop periodic sync
      _logger.info(
        'WalletDataManager',
        'Step 1: Resetting wallet state and stopping periodic sync...',
      );
      resetState();
      stopPeriodicSync(); // Stop any ongoing periodic sync
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. SECOND: Explicitly disconnect Breez SDK BEFORE invalidating providers
      // This is CRITICAL to release file locks on the database
      _logger.info(
        'WalletDataManager',
        'Step 2: Explicitly disconnecting Breez SDK...',
      );
      try {
        await ref.read(disconnectBreezClientProvider.future);
        _logger.info('WalletDataManager', 'Breez SDK disconnected');
      } catch (e) {
        _logger.warning(
          'WalletDataManager',
          'Error disconnecting Breez SDK (continuing anyway): $e',
        );
      }

      // Wait for disconnect to fully complete and release file locks
      await Future.delayed(const Duration(milliseconds: 1000));

      // 3. THIRD: Delete mnemonic FIRST - this prevents providers from reconnecting
      // when they are invalidated (Riverpod auto-recreates providers with active listeners)
      _logger.info(
        'WalletDataManager',
        'Step 3: Deleting mnemonic from secure storage FIRST...',
      );
      final secureStorage = SecureStorageProvider.instance;
      await secureStorage.delete(key: mnemonicKey);
      _logger.info('WalletDataManager', 'Mnemonic deleted');

      // Small delay to ensure secure storage write is complete
      await Future.delayed(const Duration(milliseconds: 300));

      // 4. FOURTH: Invalidate all wallet-related providers AFTER deleting mnemonic
      // When these providers try to recreate, they will fail because mnemonic is gone
      _logger.info(
        'WalletDataManager',
        'Step 4: Invalidating all wallet providers...',
      );

      ref.invalidate(mnemonicProvider);
      ref.invalidate(seedProvider);

      // Invalidate datasources that depend on mnemonic
      ref.invalidate(bdkDatasourceProvider);
      ref.invalidate(liquidDataSourceProvider);

      // Invalidate Breez provider (should already be disconnected, and won't reconnect without mnemonic)
      ref.invalidate(breezClientProvider);

      // Wait for providers to fully invalidate
      _logger.debug(
        'WalletDataManager',
        'Waiting 500ms for providers to invalidate...',
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. FIFTH: Delete auth data from secure storage
      _logger.info(
        'WalletDataManager',
        'Step 5: Deleting auth data from secure storage...',
      );
      await secureStorage.delete(key: 'jwt');
      await secureStorage.delete(key: 'refresh_token');

      // 6. SIXTH: Invalidate auth-related providers
      _logger.info(
        'WalletDataManager',
        'Step 6: Invalidating auth providers...',
      );
      ref.invalidate(sessionManagerServiceProvider);
      ref.invalidate(authenticatedClientProvider);
      ref.invalidate(ensureAuthSessionProvider);
      ref.invalidate(userDataProvider);

      await Future.delayed(const Duration(milliseconds: 300));

      // 7. SEVENTH: Delete blockchain data directories with retry logic
      _logger.info(
        'WalletDataManager',
        'Step 7: Deleting blockchain directories...',
      );

      // Delete Breez directory with multiple retry attempts
      try {
        final workingDir = await getApplicationDocumentsDirectory();
        final breezDir = Directory("${workingDir.path}/mooze");

        if (await breezDir.exists()) {
          _logger.debug(
            'WalletDataManager',
            'Breez directory exists at: ${breezDir.path}',
          );

          bool deleted = false;
          const maxAttempts = 4;

          for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
              _logger.debug(
                'WalletDataManager',
                'Deleting Breez directory (attempt $attempt/$maxAttempts)...',
              );

              await breezDir.delete(recursive: true);

              _logger.info(
                'WalletDataManager',
                'Breez directory deleted successfully',
              );
              deleted = true;
              break;
            } catch (e) {
              if (attempt < maxAttempts) {
                final delay = Duration(milliseconds: 500 * attempt);
                _logger.debug(
                  'WalletDataManager',
                  'Delete attempt $attempt failed, retrying in ${delay.inMilliseconds}ms: $e',
                );
                await Future.delayed(delay);
              } else {
                _logger.warning(
                  'WalletDataManager',
                  'Failed to delete Breez directory after $maxAttempts attempts: $e',
                );
              }
            }
          }

          if (!deleted) {
            _logger.warning(
              'WalletDataManager',
              'Could not delete Breez directory - may need manual cleanup',
            );
          }
        } else {
          _logger.debug('WalletDataManager', 'Breez directory does not exist');
        }
      } catch (e) {
        _logger.error(
          'WalletDataManager',
          'Error accessing Breez directory',
          error: e,
        );
      }

      // Delete LWK directory with retry logic (similar to Breez)
      try {
        final localDir = await getApplicationSupportDirectory();
        final lwkDir = Directory("${localDir.path}/lwk-db");

        if (await lwkDir.exists()) {
          _logger.debug(
            'WalletDataManager',
            'LWK directory exists at: ${lwkDir.path}',
          );

          bool deleted = false;
          const maxAttempts = 4;

          for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
              _logger.debug(
                'WalletDataManager',
                'Deleting LWK directory (attempt $attempt/$maxAttempts)...',
              );

              await lwkDir.delete(recursive: true);

              _logger.info(
                'WalletDataManager',
                'LWK directory deleted successfully',
              );
              deleted = true;
              break;
            } catch (e) {
              if (attempt < maxAttempts) {
                final delay = Duration(milliseconds: 500 * attempt);
                _logger.debug(
                  'WalletDataManager',
                  'LWK delete attempt $attempt failed, retrying in ${delay.inMilliseconds}ms: $e',
                );
                await Future.delayed(delay);
              } else {
                _logger.warning(
                  'WalletDataManager',
                  'Failed to delete LWK directory after $maxAttempts attempts: $e',
                );
              }
            }
          }

          if (!deleted) {
            _logger.warning(
              'WalletDataManager',
              'Could not delete LWK directory - may need manual cleanup',
            );
          }
        } else {
          _logger.debug('WalletDataManager', 'LWK directory does not exist');
        }
      } catch (e) {
        _logger.error(
          'WalletDataManager',
          'Error accessing LWK directory',
          error: e,
        );
      }

      // 8. EIGHTH: Clear user verification level
      _logger.info(
        'WalletDataManager',
        'Step 8: Clearing user verification...',
      );
      final prefs = await SharedPreferences.getInstance();
      final userLevelStorage = UserLevelStorageService(prefs);
      await userLevelStorage.clearVerificationLevel();

      // 9. NINTH: Delete PIN
      _logger.info('WalletDataManager', 'Step 9: Deleting PIN...');
      final pinStore = ref.read(pinStoreProvider);
      await pinStore.deletePin().run();

      // 10. TENTH: Invalidate remaining providers
      _logger.info(
        'WalletDataManager',
        'Step 10: Invalidating remaining providers...',
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

      // 11. FINAL: Wait for cleanup to complete
      _logger.info('WalletDataManager', 'Step 11: Finalizing cleanup...');
      await Future.delayed(const Duration(milliseconds: 500));

      _logger.info(
        'WalletDataManager',
        'Wallet deletion completed successfully',
      );

      // Reset wallet deletion flag (not strictly needed since mnemonic is gone,
      // but good for cleanup in case app doesn't restart)
      ref.read(setWalletDeletionFlagProvider(false));

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'WalletDataManager',
        'Error during wallet deletion',
        error: e,
        stackTrace: stackTrace,
      );

      // Reset wallet deletion flag on error
      ref.read(setWalletDeletionFlagProvider(false));

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

  /// Cleans blockchain directories (Breez and LWK) to prepare for wallet import or recovery
  /// This should be called BEFORE importing a new wallet to avoid database conflicts
  ///
  /// Returns true if cleanup was successful, false otherwise
  Future<bool> cleanBreezDirectory() async {
    try {
      _logger.info(
        'WalletDataManager',
        'Cleaning blockchain directories for wallet import...',
      );

      bool breezCleaned = true;
      bool lwkCleaned = true;

      // Clean Breez directory
      try {
        final workingDir = await getApplicationDocumentsDirectory();
        final breezDir = Directory("${workingDir.path}/mooze");

        if (await breezDir.exists()) {
          _logger.debug(
            'WalletDataManager',
            'Breez directory exists at: ${breezDir.path}',
          );

          const maxAttempts = 5;
          bool deleted = false;

          for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
              _logger.debug(
                'WalletDataManager',
                'Deleting Breez directory (attempt $attempt/$maxAttempts)...',
              );

              await breezDir.delete(recursive: true);

              _logger.info(
                'WalletDataManager',
                'Breez directory deleted successfully',
              );
              deleted = true;
              break;
            } catch (e) {
              if (attempt < maxAttempts) {
                final delay = Duration(milliseconds: 500 * attempt);
                _logger.debug(
                  'WalletDataManager',
                  'Breez delete attempt $attempt failed, retrying in ${delay.inMilliseconds}ms: $e',
                );
                await Future.delayed(delay);
              } else {
                _logger.error(
                  'WalletDataManager',
                  'Failed to delete Breez directory after $maxAttempts attempts: $e',
                );
              }
            }
          }

          breezCleaned = deleted;
        } else {
          _logger.debug(
            'WalletDataManager',
            'Breez directory does not exist, nothing to clean',
          );
        }
      } catch (e) {
        _logger.error(
          'WalletDataManager',
          'Error cleaning Breez directory',
          error: e,
        );
        breezCleaned = false;
      }

      // Clean LWK directory
      try {
        final localDir = await getApplicationSupportDirectory();
        final lwkDir = Directory("${localDir.path}/lwk-db");

        if (await lwkDir.exists()) {
          _logger.debug(
            'WalletDataManager',
            'LWK directory exists at: ${lwkDir.path}',
          );

          const maxAttempts = 5;
          bool deleted = false;

          for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
              _logger.debug(
                'WalletDataManager',
                'Deleting LWK directory (attempt $attempt/$maxAttempts)...',
              );

              await lwkDir.delete(recursive: true);

              _logger.info(
                'WalletDataManager',
                'LWK directory deleted successfully',
              );
              deleted = true;
              break;
            } catch (e) {
              if (attempt < maxAttempts) {
                final delay = Duration(milliseconds: 500 * attempt);
                _logger.debug(
                  'WalletDataManager',
                  'LWK delete attempt $attempt failed, retrying in ${delay.inMilliseconds}ms: $e',
                );
                await Future.delayed(delay);
              } else {
                _logger.error(
                  'WalletDataManager',
                  'Failed to delete LWK directory after $maxAttempts attempts: $e',
                );
              }
            }
          }

          lwkCleaned = deleted;
        } else {
          _logger.debug(
            'WalletDataManager',
            'LWK directory does not exist, nothing to clean',
          );
        }
      } catch (e) {
        _logger.error(
          'WalletDataManager',
          'Error cleaning LWK directory',
          error: e,
        );
        lwkCleaned = false;
      }

      // Wait for filesystem to sync if any directory was deleted
      if (breezCleaned || lwkCleaned) {
        await Future.delayed(Duration(milliseconds: 500));
      }

      final success = breezCleaned && lwkCleaned;
      if (success) {
        _logger.info(
          'WalletDataManager',
          'All blockchain directories cleaned successfully',
        );
      } else {
        _logger.warning(
          'WalletDataManager',
          'Partial cleanup - Breez: $breezCleaned, LWK: $lwkCleaned',
        );
      }

      return success;
    } catch (e, stackTrace) {
      _logger.error(
        'WalletDataManager',
        'Error cleaning blockchain directories',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
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

final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(walletDataManagerProvider.notifier).isSyncing;
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

/// Provider to clean Breez directory before importing a new wallet
/// This should be called BEFORE saving a new mnemonic to avoid database conflicts
final cleanBreezDirectoryProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final manager = ref.read(walletDataManagerProvider.notifier);
  return await manager.cleanBreezDirectory();
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

/// Notifier for triggering UI updates without showing loading state
/// This is used when new data is available and we want the UI to refresh
/// without going through the loading phase
class DataRefreshNotifier extends StateNotifier<int> {
  DataRefreshNotifier() : super(0);

  /// Triggers a UI update by incrementing the counter
  void triggerRefresh() {
    state = state + 1;
    debugPrint('[DataRefreshNotifier] Trigger fired: state = $state');
  }
}

/// Provider that notifies UI components when data should be refreshed
/// without showing loading indicators
final dataRefreshTriggerProvider =
    StateNotifierProvider<DataRefreshNotifier, int>((ref) {
      return DataRefreshNotifier();
    });
