import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/providers/app_database_provider.dart';
import '../lwk/providers/datasource_provider.dart';
import '../bdk/providers/datasource_provider.dart';
import '../breez/providers.dart';
import '../../key_management/providers/mnemonic_provider.dart';
import '../../key_management/providers/has_pin_provider.dart';
import '../../authentication/providers/ensure_auth_session_provider.dart';

/// Wallet boot phases
enum BootPhase {
  idle,
  initializingDatabase,
  loadingCachedData,
  authenticating,
  initializingDatasources,
  syncing,
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
  });

  bool get isCompleted => phase == BootPhase.completed;
  bool get hasError => phase == BootPhase.error;
  bool get isBooting =>
      phase != BootPhase.idle &&
      phase != BootPhase.completed &&
      phase != BootPhase.error;

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

  BootOrchestrator(this.ref) : super(const BootState());

  /// Starts the boot process
  Future<void> startBoot() async {
    if (_hasStarted && state.isBooting) {
      debugPrint('[BootOrchestrator] Boot already in progress, waiting...');
      await _bootCompleter?.future;
      return;
    }

    _hasStarted = true;
    _bootCompleter = Completer<void>();

    state = state.copyWith(
      phase: BootPhase.initializingDatabase,
      message: 'Inicializando banco de dados...',
      startTime: DateTime.now(),
    );

    try {
      // Phase 1: Verify mnemonic and PIN
      debugPrint('[BootOrchestrator] Phase 1: Verifying credentials...');
      final canProceed = await _verifyCredentials();
      if (!canProceed) {
        debugPrint('[BootOrchestrator] Credentials not available, waiting...');
        state = state.copyWith(
          phase: BootPhase.idle,
          message: 'Aguardando credenciais...',
        );
        _bootCompleter?.complete();
        return;
      }

      // Phase 2: Initialize database
      debugPrint('[BootOrchestrator] Phase 2: Initializing database...');
      await _initializeDatabase();

      // Phase 3: Load cached data (non-blocking)
      debugPrint('[BootOrchestrator] Phase 3: Loading cache...');
      state = state.copyWith(
        phase: BootPhase.loadingCachedData,
        message: 'Carregando dados salvos...',
      );

      // Phase 4: API Authentication (parallel, non-blocking datasources)
      debugPrint('[BootOrchestrator] Phase 4: Authenticating...');
      state = state.copyWith(
        phase: BootPhase.authenticating,
        message: 'Autenticando...',
      );
      _authenticateAsync();

      // Phase 5: Initialize datasources in parallel
      debugPrint('[BootOrchestrator] Phase 5: Initializing datasources...');
      state = state.copyWith(
        phase: BootPhase.initializingDatasources,
        message: 'Conectando às blockchains...',
      );
      await _initializeDatasourcesParallel();

      // Phase 6: Initial sync
      debugPrint('[BootOrchestrator] Phase 6: Syncing...');
      state = state.copyWith(
        phase: BootPhase.syncing,
        message: 'Sincronizando carteira...',
      );
      await _performInitialSync();

      // Boot complete
      debugPrint(
        '[BootOrchestrator] Boot complete in ${state.bootDuration?.inMilliseconds}ms',
      );
      state = state.copyWith(
        phase: BootPhase.completed,
        message: 'Carteira pronta',
        completedTime: DateTime.now(),
      );

      _bootCompleter?.complete();
    } catch (e, stack) {
      debugPrint('[BootOrchestrator] Boot error: $e\n$stack');
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
      final mnemonicOption = await ref.read(mnemonicProvider.future);
      final hasMnemonic = mnemonicOption.isSome();

      if (!hasMnemonic) {
        return false;
      }

      final hasPin = await ref.read(hasPinProvider.future);
      return hasPin;
    } catch (e) {
      debugPrint('[BootOrchestrator] Error verifying credentials: $e');
      return false;
    }
  }

  /// Initializes the database
  Future<void> _initializeDatabase() async {
    try {
      // AppDatabase is lazily initialized by the provider
      // Here we ensure it's ready before continuing
      final db = ref.read(appDatabaseProvider);

      // Force a simple operation to ensure the DB is ready
      await db.getAllSwaps();

      state = state.copyWith(isDatabaseReady: true);
      debugPrint('[BootOrchestrator] Database initialized');
    } catch (e) {
      debugPrint('[BootOrchestrator] Error initializing database: $e');
      // Don't fail boot because of database, just log
      state = state.copyWith(isDatabaseReady: false);
    }
  }

  /// Authenticates with API in background
  Future<void> _authenticateAsync() async {
    try {
      final isAuthenticated = await ref.read(ensureAuthSessionProvider.future);
      state = state.copyWith(isAuthReady: isAuthenticated);
      debugPrint('[BootOrchestrator] Authentication: $isAuthenticated');
    } catch (e) {
      debugPrint('[BootOrchestrator] Authentication error (non-critical): $e');
      state = state.copyWith(isAuthReady: false);
    }
  }

  /// Initializes datasources in parallel using isolates when possible
  Future<void> _initializeDatasourcesParallel() async {
    final results = await Future.wait([
      _initializeLiquidDatasource(),
      _initializeBdkDatasource(),
      _initializeBreezClient(),
    ]);

    final liquidOk = results[0];
    final bdkOk = results[1];
    final breezOk = results[2];

    debugPrint(
      '[BootOrchestrator] Datasources: Liquid=$liquidOk, BDK=$bdkOk, Breez=$breezOk',
    );

    if (!liquidOk && !bdkOk) {
      throw Exception('No datasource available. Check your connection.');
    }
  }

  Future<bool> _initializeLiquidDatasource() async {
    try {
      final result = await ref.read(liquidDataSourceProvider.future);
      final isOk = result.isRight();
      state = state.copyWith(isLiquidReady: isOk);

      if (!isOk) {
        result.fold(
          (error) => debugPrint('[BootOrchestrator] Liquid error: $error'),
          (_) {},
        );
      }

      return isOk;
    } catch (e) {
      debugPrint('[BootOrchestrator] Error initializing Liquid: $e');
      state = state.copyWith(isLiquidReady: false);
      return false;
    }
  }

  Future<bool> _initializeBdkDatasource() async {
    try {
      final result = await ref.read(bdkDatasourceProvider.future);
      final isOk = result.isRight();
      state = state.copyWith(isBdkReady: isOk);

      if (!isOk) {
        result.fold(
          (error) => debugPrint('[BootOrchestrator] BDK error: $error'),
          (_) {},
        );
      }

      return isOk;
    } catch (e) {
      debugPrint('[BootOrchestrator] Error initializing BDK: $e');
      state = state.copyWith(isBdkReady: false);
      return false;
    }
  }

  Future<bool> _initializeBreezClient() async {
    try {
      final result = await ref.read(breezClientProvider.future);
      final isOk = result.isRight();
      state = state.copyWith(isBreezReady: isOk);

      if (!isOk) {
        result.fold(
          (error) => debugPrint('[BootOrchestrator] Breez error: $error'),
          (_) {},
        );
      }

      return isOk;
    } catch (e) {
      debugPrint('[BootOrchestrator] Error initializing Breez: $e');
      state = state.copyWith(isBreezReady: false);
      return false;
    }
  }

  /// Executes initial sync using isolates
  Future<void> _performInitialSync() async {
    final syncFutures = <Future<void>>[];

    // Liquid sync in isolate
    if (state.isLiquidReady) {
      final liquidResult = await ref.read(liquidDataSourceProvider.future);
      liquidResult.fold((_) {}, (datasource) {
        syncFutures.add(_syncLiquidInIsolate(datasource));
      });
    }

    // BDK sync in isolate
    if (state.isBdkReady) {
      final bdkResult = await ref.read(bdkDatasourceProvider.future);
      bdkResult.fold((_) {}, (datasource) {
        syncFutures.add(_syncBdkInIsolate(datasource));
      });
    }

    if (syncFutures.isNotEmpty) {
      await Future.wait(syncFutures);
      debugPrint('[BootOrchestrator] Initial sync complete');
    }
  }

  /// Liquid sync in separate isolate
  Future<void> _syncLiquidInIsolate(dynamic datasource) async {
    try {
      debugPrint('[BootOrchestrator] Starting Liquid sync in isolate...');

      await Isolate.run(() async {
        // Note: Datasource cannot be passed directly to isolate
        // We need to rebuild the connection inside the isolate
        // For now, we do sync in main isolate but non-blocking
      });

      // For now, normal sync (move to full isolate later)
      await datasource.sync();

      debugPrint('[BootOrchestrator] Liquid sync completed');
    } catch (e) {
      debugPrint('[BootOrchestrator] Liquid sync error: $e');
    }
  }

  /// BDK sync in separate isolate
  Future<void> _syncBdkInIsolate(dynamic datasource) async {
    try {
      debugPrint('[BootOrchestrator] Starting BDK sync...');

      // BDK sync - for now in main isolate
      await datasource.sync();

      debugPrint('[BootOrchestrator] BDK sync completed');
    } catch (e) {
      debugPrint('[BootOrchestrator] BDK sync error: $e');
    }
  }

  /// Forces a boot retry
  Future<void> retryBoot() async {
    debugPrint('[BootOrchestrator] Boot retry requested');

    // Invalidate providers to force recreation
    ref.invalidate(liquidDataSourceProvider);
    ref.invalidate(bdkDatasourceProvider);
    ref.invalidate(breezClientProvider);

    state = const BootState();
    _hasStarted = false;

    await Future.delayed(const Duration(milliseconds: 500));
    await startBoot();
  }

  /// Complete state reset
  void reset() {
    debugPrint('[BootOrchestrator] State reset');
    state = const BootState();
    _hasStarted = false;
    _bootCompleter = null;
  }

  @override
  void dispose() {
    _bootCompleter?.complete();
    super.dispose();
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
