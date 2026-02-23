import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/providers/app_database_provider.dart';
import '../lwk/providers/datasource_provider.dart';
import '../bdk/providers/datasource_provider.dart';
import '../breez/providers.dart';
import '../sync/wallet_data_manager.dart';
import '../../key_management/providers/mnemonic_provider.dart';
import '../../key_management/providers/has_pin_provider.dart';
import '../../authentication/providers/ensure_auth_session_provider.dart';
import '../../../services/app_logger_service.dart';
import '../../../services/log_config.dart';
import '../../../services/providers/app_logger_provider.dart';
import '../sync/sync_stream_controller.dart';

/// Wallet boot phases
enum BootPhase {
  idle,
  initializingDatabase,
  loadingCachedData,
  authenticating,
  initializingDatasources,
  showingUI,
  syncingBackground,
  completed,
  error,
}

/// Wallet boot state
class BootState {
  final BootPhase phase;
  final String? message;
  final String? errorMessage;
  final bool isDatabaseReady;
  final bool isLiquidReady;
  final bool isBdkReady;
  final bool isBreezReady;
  final bool isAuthReady;
  final DateTime? startTime;
  final DateTime? completedTime;
  final Map<String, bool> datasourceSyncStatus;

  const BootState({
    this.phase = BootPhase.idle,
    this.message,
    this.errorMessage,
    this.isDatabaseReady = false,
    this.isLiquidReady = false,
    this.isBdkReady = false,
    this.isBreezReady = false,
    this.isAuthReady = false,
    this.startTime,
    this.completedTime,
    this.datasourceSyncStatus = const {},
  });

  bool get isCompleted => phase == BootPhase.completed;
  bool get hasError => phase == BootPhase.error;
  bool get isBooting =>
      phase != BootPhase.idle &&
      phase != BootPhase.completed &&
      phase != BootPhase.error;

  /// Returns true if UI can be shown (cache loaded, datasources initializing/syncing)
  bool get canShowUI =>
      phase == BootPhase.showingUI ||
      phase == BootPhase.syncingBackground ||
      phase == BootPhase.completed;

  /// Returns true if at least one datasource is ready
  /// (allows displaying partial data in the UI)
  bool get hasAnyDatasource => isLiquidReady || isBdkReady;

  /// Returns true if all critical datasources are ready
  bool get allDatasourcesReady => isLiquidReady && isBdkReady;

  Duration? get bootDuration {
    if (startTime == null) return null;
    final endTime = completedTime ?? DateTime.now();
    return endTime.difference(startTime!);
  }

  BootState copyWith({
    BootPhase? phase,
    String? message,
    String? errorMessage,
    bool? isDatabaseReady,
    bool? isLiquidReady,
    bool? isBdkReady,
    bool? isBreezReady,
    bool? isAuthReady,
    DateTime? startTime,
    DateTime? completedTime,
    Map<String, bool>? datasourceSyncStatus,
  }) {
    return BootState(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      errorMessage: errorMessage,
      isDatabaseReady: isDatabaseReady ?? this.isDatabaseReady,
      isLiquidReady: isLiquidReady ?? this.isLiquidReady,
      isBdkReady: isBdkReady ?? this.isBdkReady,
      isBreezReady: isBreezReady ?? this.isBreezReady,
      isAuthReady: isAuthReady ?? this.isAuthReady,
      startTime: startTime ?? this.startTime,
      completedTime: completedTime ?? this.completedTime,
      datasourceSyncStatus: datasourceSyncStatus ?? this.datasourceSyncStatus,
    );
  }

  @override
  String toString() {
    return 'BootState(phase: $phase, liquid: $isLiquidReady, bdk: $isBdkReady, breez: $isBreezReady)';
  }
}

/// Wallet boot process orchestrator
///
/// Manages initialization in phases:
/// 1. Initialize database
/// 2. Load cached data (to display immediately)
/// 3. Authenticate with API
/// 4. Initialize datasources (LWK, BDK, Breez) in parallel
/// 5. Sync with blockchain
/// 6. Update UI with fresh data
class BootOrchestrator extends StateNotifier<BootState> {
  final Ref ref;
  bool _hasStarted = false;
  Completer<void>? _bootCompleter;
  late final AppLoggerService _logger;
  StreamSubscription<SyncProgress>? _syncSubscription;

  BootOrchestrator(this.ref) : super(const BootState()) {
    _logger = ref.read(appLoggerProvider);
    _listenToSyncProgress();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    if (_bootCompleter != null && !_bootCompleter!.isCompleted) {
      _bootCompleter!.complete();
    }
    super.dispose();
  }

  void _listenToSyncProgress() {
    final syncStream = ref.read(syncStreamProvider);

    _syncSubscription = syncStream.stream.listen((progress) {
      _logger.debug(
        'BootOrchestrator',
        'Sync progress: ${progress.datasource} - ${progress.status}',
      );

      if (progress.status == SyncStatus.completed) {
        _markDatasourceComplete(progress.datasource);
      } else if (progress.status == SyncStatus.error) {
        _logger.warning(
          'BootOrchestrator',
          '${progress.datasource} sync failed: ${progress.errorMessage}',
        );
      }
    });
  }

  /// Marca um datasource como completado
  void _markDatasourceComplete(String datasource) {
    final updated = Map<String, bool>.from(state.datasourceSyncStatus);
    updated[datasource.toLowerCase()] = true;

    state = state.copyWith(datasourceSyncStatus: updated);

    _logger.debug(
      'BootOrchestrator',
      '$datasource sync completed. Status: $updated',
    );

    // Se todos completaram, marca boot como completed
    if (updated.values.every((completed) => completed == true)) {
      _logger.info(
        'BootOrchestrator',
        'All datasources synced - boot completed',
      );

      state = state.copyWith(
        phase: BootPhase.completed,
        completedTime: DateTime.now(),
        message: 'Sincronização completa',
      );

      if (!_bootCompleter!.isCompleted) {
        _bootCompleter!.complete();
      }
    }
  }

  /// Starts the boot process
  Future<void> startBoot() async {
    if (_hasStarted && state.isBooting) {
      _logger.warning(
        'BootOrchestrator',
        'Boot already in progress, waiting...',
      );
      await _bootCompleter?.future;
      return;
    }

    _hasStarted = true;
    _bootCompleter = Completer<void>();

    _logger.info('BootOrchestrator', 'Starting wallet boot process');

    state = state.copyWith(
      phase: BootPhase.initializingDatabase,
      message: 'Inicializando banco de dados...',
      startTime: DateTime.now(),
    );

    try {
      // Phase 1: Verify mnemonic and PIN
      _logger.debug('BootOrchestrator', 'Phase 1: Verifying credentials...');
      final canProceed = await _verifyCredentials();
      if (!canProceed) {
        _logger.warning(
          'BootOrchestrator',
          'Credentials not available, boot paused',
        );
        state = state.copyWith(
          phase: BootPhase.idle,
          message: 'Aguardando credenciais...',
        );
        _bootCompleter?.complete();
        return;
      }
      _logger.info('BootOrchestrator', 'Credentials verified successfully');

      // Phase 2: Initialize database
      _logger.info('BootOrchestrator', 'Phase 2: Initializing database...');
      await _initializeDatabase();

      // Phase 3: Load cached data (non-blocking)
      _logger.debug('BootOrchestrator', 'Phase 3: Loading cached data...');
      state = state.copyWith(
        phase: BootPhase.loadingCachedData,
        message: 'Carregando dados salvos...',
      );

      // Phase 4: API Authentication (parallel, non-blocking datasources)
      _logger.info('BootOrchestrator', 'Phase 4: Authenticating with API...');
      state = state.copyWith(
        phase: BootPhase.authenticating,
        message: 'Autenticando...',
      );
      _authenticateAsync();

      // Phase 5: Initialize datasources in parallel
      _logger.info(
        'BootOrchestrator',
        'Phase 5: Initializing datasources in parallel...',
      );
      state = state.copyWith(
        phase: BootPhase.initializingDatasources,
        message: 'Conectando às blockchains...',
      );
      await _initializeDatasourcesParallel();

      // Phase 6: Show UI with cached data
      _logger.info('BootOrchestrator', 'Phase 6: Ready to show UI...');
      state = state.copyWith(
        phase: BootPhase.showingUI,
        message: 'Carregando carteira...',
      );

      // Phase 7: Start background sync (non-blocking)
      _logger.info('BootOrchestrator', 'Phase 7: Starting background sync...');
      state = state.copyWith(
        phase: BootPhase.syncingBackground,
        message: 'Sincronizando em segundo plano...',
        datasourceSyncStatus: {'liquid': false, 'bdk': false, 'breez': false},
      );
      _startBackgroundSync();

      // Initialize WalletDataManager to load cached data
      _logger.debug(
        'BootOrchestrator',
        'Initializing WalletDataManager with cached data...',
      );
      ref
          .read(walletDataManagerProvider.notifier)
          .initializeWallet(skipInitialSync: true);

      // Don't complete boot here - wait for sync completion via listener
      _logger.info(
        'BootOrchestrator',
        'Boot UI ready, syncing in background...',
      );
    } catch (e, stack) {
      _logger.critical(
        'BootOrchestrator',
        'Boot failed with exception',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        phase: BootPhase.error,
        errorMessage: e.toString(),
      );
      _bootCompleter?.completeError(e);
    }
  }

  /// Verifies if mnemonic and PIN are available
  Future<bool> _verifyCredentials() async {
    try {
      _logger.debug('BootOrchestrator', 'Checking mnemonic availability...');
      final mnemonicOption = await ref.read(mnemonicProvider.future);
      final hasMnemonic = mnemonicOption.isSome();

      if (!hasMnemonic) {
        _logger.warning('BootOrchestrator', 'Mnemonic not found');
        return false;
      }

      _logger.debug('BootOrchestrator', 'Checking PIN availability...');
      final hasPin = await ref.read(hasPinProvider.future);

      if (!hasPin) {
        _logger.warning('BootOrchestrator', 'PIN not found');
      }

      return hasPin;
    } catch (e, stackTrace) {
      _logger.error(
        'BootOrchestrator',
        'Error verifying credentials',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Initializes the database
  Future<void> _initializeDatabase() async {
    debugPrint('[BootOrchestrator] _initializeDatabase() STARTED');
    try {
      // AppDatabase is lazily initialized by the provider
      // Here we ensure it's ready before continuing
      debugPrint('[BootOrchestrator] Getting database from provider...');
      final db = ref.read(appDatabaseProvider);
      debugPrint('[BootOrchestrator] Database obtained: ${db.hashCode}');

      // Force a simple operation to ensure the DB is ready
      debugPrint('[BootOrchestrator] Testing database with getAllSwaps...');
      await db.getAllSwaps();
      debugPrint('[BootOrchestrator] Database test successful');

      // Initialize logger with database
      debugPrint('[BootOrchestrator] Creating logger instance...');
      final logger = AppLoggerService();
      debugPrint('[BootOrchestrator] Calling logger.initialize...');
      await logger.initialize(
        db,
        config: kDebugMode ? LogConfig.development : LogConfig.production,
      );
      debugPrint('[BootOrchestrator] Logger initialized successfully');

      state = state.copyWith(isDatabaseReady: true);
      debugPrint('[BootOrchestrator] Database initialized');
      logger.info(
        'BootOrchestrator',
        'Database and logger initialized successfully',
      );
    } catch (e, stackTrace) {
      debugPrint('[BootOrchestrator] Error initializing database: $e');
      debugPrint('[BootOrchestrator] StackTrace: $stackTrace');
      // Don't fail boot because of database, just log
      state = state.copyWith(isDatabaseReady: false);
    }
  }

  /// Authenticates with API in background
  Future<void> _authenticateAsync() async {
    try {
      _logger.debug('BootOrchestrator', 'Starting API authentication...');
      final isAuthenticated = await ref.read(ensureAuthSessionProvider.future);
      state = state.copyWith(isAuthReady: isAuthenticated);

      if (isAuthenticated) {
        _logger.info('BootOrchestrator', 'API authentication successful');
      } else {
        _logger.warning('BootOrchestrator', 'API authentication failed');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'BootOrchestrator',
        'Authentication error (non-critical)',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isAuthReady: false);
    }
  }

  /// Initializes datasources in parallel using isolates when possible
  Future<void> _initializeDatasourcesParallel() async {
    _logger.debug(
      'BootOrchestrator',
      'Starting parallel datasource initialization...',
    );

    final results = await Future.wait([
      _initializeLiquidDatasource(),
      _initializeBdkDatasource(),
      _initializeBreezClient(),
    ]);

    final liquidOk = results[0];
    final bdkOk = results[1];
    final breezOk = results[2];

    _logger.info(
      'BootOrchestrator',
      'Datasources initialized - Liquid: $liquidOk, BDK: $bdkOk, Breez: $breezOk',
    );

    if (!liquidOk && !bdkOk) {
      _logger.error(
        'BootOrchestrator',
        'No datasource available. Check your connection.',
      );
      throw Exception('No datasource available. Check your connection.');
    }
  }

  Future<bool> _initializeLiquidDatasource() async {
    try {
      _logger.debug('BootOrchestrator', 'Initializing Liquid datasource...');
      final result = await ref.read(liquidDataSourceProvider.future);
      final isOk = result.isRight();
      state = state.copyWith(isLiquidReady: isOk);

      if (isOk) {
        _logger.info('BootOrchestrator', 'Liquid datasource ready');
      } else {
        result.fold(
          (error) => _logger.error(
            'BootOrchestrator',
            'Liquid datasource failed',
            error: error,
          ),
          (_) {},
        );
      }

      return isOk;
    } catch (e, stackTrace) {
      _logger.error(
        'BootOrchestrator',
        'Error initializing Liquid datasource',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isLiquidReady: false);
      return false;
    }
  }

  Future<bool> _initializeBdkDatasource() async {
    try {
      _logger.debug('BootOrchestrator', 'Initializing BDK datasource...');
      final result = await ref.read(bdkDatasourceProvider.future);
      final isOk = result.isRight();
      state = state.copyWith(isBdkReady: isOk);

      if (isOk) {
        _logger.info('BootOrchestrator', 'BDK datasource ready');
      } else {
        result.fold(
          (error) => _logger.error(
            'BootOrchestrator',
            'BDK datasource failed',
            error: error,
          ),
          (_) {},
        );
      }

      return isOk;
    } catch (e, stackTrace) {
      _logger.error(
        'BootOrchestrator',
        'Error initializing BDK datasource',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isBdkReady: false);
      return false;
    }
  }

  Future<bool> _initializeBreezClient() async {
    try {
      _logger.debug('BootOrchestrator', 'Initializing Breez client...');
      final result = await ref.read(breezClientProvider.future);
      final isOk = result.isRight();
      state = state.copyWith(isBreezReady: isOk);

      if (isOk) {
        _logger.info('BootOrchestrator', 'Breez client ready');
      } else {
        result.fold(
          (error) => _logger.error(
            'BootOrchestrator',
            'Breez client failed',
            error: error,
          ),
          (_) {},
        );
      }

      return isOk;
    } catch (e, stackTrace) {
      _logger.error(
        'BootOrchestrator',
        'Error initializing Breez client',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isBreezReady: false);
      return false;
    }
  }

  void _startBackgroundSync() {
    _logger.info(
      'BootOrchestrator',
      'Starting background sync for all datasources',
    );

    // Sync Liquid
    if (state.isLiquidReady) {
      _syncLiquidInBackground();
    }

    // Sync BDK
    if (state.isBdkReady) {
      _syncBdkInBackground();
    }

    // Sync Breez
    if (state.isBreezReady) {
      _syncBreezInBackground();
    }

    _logger.info('BootOrchestrator', 'All background syncs initiated');
  }

  void _syncLiquidInBackground() {
    ref.read(liquidDataSourceProvider).whenData((either) {
      either.fold(
        (error) {
          _logger.error(
            'BootOrchestrator',
            'Liquid datasource not available: $error',
          );
        },
        (datasource) {
          _logger.debug('BootOrchestrator', 'Starting Liquid background sync');
          datasource.syncInBackground(); // Fire and forget
        },
      );
    });
  }

  void _syncBdkInBackground() {
    ref.read(bdkDatasourceProvider).whenData((either) {
      either.fold(
        (error) {
          _logger.error(
            'BootOrchestrator',
            'BDK datasource not available: $error',
          );
        },
        (datasource) {
          _logger.debug('BootOrchestrator', 'Starting BDK background sync');
          datasource.syncInBackground(); // Fire and forget
        },
      );
    });
  }

  void _syncBreezInBackground() {
    ref.read(breezClientProvider).whenData((either) {
      either.fold(
        (error) {
          _logger.error(
            'BootOrchestrator',
            'Breez client not available: $error',
          );
        },
        (client) {
          _logger.debug(
            'BootOrchestrator',
            'Breez sync handled by client provider',
          );
        },
      );
    });
  }

  /// Forces a boot retry
  Future<void> retryBoot() async {
    _logger.warning(
      'BootOrchestrator',
      'Boot retry requested, invalidating providers...',
    );

    // Invalidate providers to force recreation
    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(breezClientProvider);

    state = const BootState();
    _hasStarted = false;

    await Future.delayed(const Duration(milliseconds: 500));
    _logger.info('BootOrchestrator', 'Restarting boot process...');
    await startBoot();
  }

  /// Complete state reset
  void reset() {
    _logger.info('BootOrchestrator', 'Resetting boot orchestrator state');
    state = const BootState();
    _hasStarted = false;
    _bootCompleter = null;
  }
}

/// Boot orchestrator provider
final bootOrchestratorProvider =
    StateNotifierProvider<BootOrchestrator, BootState>((ref) {
      final orchestrator = BootOrchestrator(ref);

      ref.onDispose(() {
        debugPrint('[BootOrchestratorProvider] Disposing');
      });

      return orchestrator;
    });

/// Provider to check if boot is complete
final isBootCompleteProvider = Provider<bool>((ref) {
  return ref.watch(bootOrchestratorProvider).isCompleted;
});

/// Provider to check if UI can be shown
final canShowUIProvider = Provider<bool>((ref) {
  return ref.watch(bootOrchestratorProvider).canShowUI;
});

/// Provider to check if any datasource is available
final hasAnyDatasourceProvider = Provider<bool>((ref) {
  return ref.watch(bootOrchestratorProvider).hasAnyDatasource;
});

/// Provider to get current boot phase
final bootPhaseProvider = Provider<BootPhase>((ref) {
  return ref.watch(bootOrchestratorProvider).phase;
});

/// Provider to get boot error message
final bootErrorProvider = Provider<String?>((ref) {
  return ref.watch(bootOrchestratorProvider).errorMessage;
});
