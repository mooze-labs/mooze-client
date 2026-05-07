import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_state.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/features/boot/domain/boot_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_monitor_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class ImportMessage {
  final String text;
  final bool isCompleted;
  final bool hasError;
  final bool isRetry;

  const ImportMessage({
    required this.text,
    this.isCompleted = false,
    this.hasError = false,
    this.isRetry = false,
  });
}

class WalletImportLoadingScreen extends ConsumerStatefulWidget {
  const WalletImportLoadingScreen({super.key});

  @override
  ConsumerState<WalletImportLoadingScreen> createState() =>
      _WalletImportLoadingScreenState();
}

class _WalletImportLoadingScreenState
    extends ConsumerState<WalletImportLoadingScreen>
    with TickerProviderStateMixin {
  final List<ImportMessage> _messages = [];
  int _currentMessageIndex = -1;
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasInitialized = false;
  bool _isHandlingSuccess = false;

  // Phase 2.3.3: V2 boot/sync state tracking. The legacy
  // per-datasource completion set is gone — V2 has one merged
  // `AppPhase.ready` signal that covers boot + first sync. We still
  // track per-chain sync transitions to render the same "synced X"
  // messages users expect.
  //
  // `_shownBootPhases` is the boot-phase analogue of `_completedChains`:
  // the boot orchestrator emits each `BootPhase` exactly once on the
  // forward path, but `bootStateProvider` re-delivers the same state to
  // late subscribers. Guarding by phase prevents a duplicate "Loading
  // credentials..." line when the listener attaches mid-boot.
  final _completedChains = <String>{};
  final _shownBootPhases = <BootPhase>{};
  bool _bootStartTriggered = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _checkBounceController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _orbitalController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkBounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _orbitalController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startImportProcess();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _checkBounceController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _orbitalController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Render a one-line message for the current `BootPhase`. The boot
  /// orchestrator walks linearly through the forward phases — every
  /// transition is interesting to the user, especially on first import
  /// where each phase can take seconds (FFI init, Electrum connect,
  /// Breez authentication). Renders one message per distinct phase
  /// seen; idempotent across re-emits.
  void _trackBootPhase(BootState state) {
    final phase = state.phase;
    if (_shownBootPhases.contains(phase)) return;
    _shownBootPhases.add(phase);

    final t = AppLocalizations.of(context);
    final String? label = switch (phase) {
      BootPhase.initializingPlatform => t.wallet_import_phase_platform,
      BootPhase.initializingDatabase => t.wallet_import_phase_database,
      BootPhase.loadingCredentials => t.wallet_import_phase_credentials,
      BootPhase.connectingServices => t.wallet_import_phase_connecting,
      BootPhase.authenticatingSession => t.wallet_import_phase_authenticating,
      // ready / needsSetup / error / idle don't get their own line —
      // the post-boot sequence (`_handleAllSyncsCompleted`) and the
      // error-state listener cover those terminal transitions.
      _ => null,
    };
    if (label == null) return;
    // ignore: unawaited_futures
    _showMessage(label);
  }

  /// Phase 2.3.3: per-chain sync event monitoring is now driven by
  /// `ref.listen<AsyncValue<SyncState>>(syncStateProvider, ...)` in
  /// `build()`. When a chain transitions from `connecting` →
  /// `connected`, we render its "synced X" message; when all three
  /// chains report `connected` we run the post-sync sequence.
  ///
  /// Idempotent — `_completedChains` guards against duplicate emits
  /// when `syncStateProvider` re-emits the same state (e.g. on every
  /// periodic tick after first-sync).
  void _trackChainSyncProgress(SyncState state) {
    final t = AppLocalizations.of(context);
    state.perChain.forEach((chain, lifecycle) {
      if (lifecycle == ServiceLifecycle.connected &&
          !_completedChains.contains(chain.name)) {
        _completedChains.add(chain.name);
        // ignore: unawaited_futures
        _showMessage(
          t.wallet_import_msg_synced(_getChainName(chain.name)),
        );
      }
    });
    // The "all chains connected" condition is observable from the
    // perChain map but no longer drives flow control — the
    // `appStateProvider.phase == AppPhase.ready` listener in `build()`
    // is the canonical "wallet is ready" signal (it covers boot
    // completion + sync start, equivalent to legacy "all sync events
    // received").
  }

  String _getChainName(String chain) {
    final t = AppLocalizations.of(context);
    switch (chain) {
      case 'liquid':
        return t.wallet_import_datasource_liquid;
      case 'bitcoin':
      case 'bdk':
        return t.wallet_import_datasource_bitcoin;
      case 'lightning':
      case 'breez':
        return t.wallet_import_datasource_lightning;
      default:
        return chain;
    }
  }

  Future<void> _handleAllSyncsCompleted() async {
    if (_isCompleted || _isHandlingSuccess) return;

    setState(() => _isHandlingSuccess = true);

    if (!mounted) return;
    final t = AppLocalizations.of(context);

    await _showMessage(t.wallet_import_msg_loading_balances);

    await _refreshBalances();

    await _showMessage(t.wallet_import_msg_loading_transactions);
    // Removed a 500 ms `Future.delayed` here. There was nothing to wait for —
    // the previous `_refreshBalances()` already awaited `allBalancesProvider`
    // and the `markExistingTransactionsAsKnown` call below reads
    // `transactionHistoryProvider` which has its own awaited load.
    final transactionMonitor = ref.read(transactionMonitorServiceProvider);
    await transactionMonitor.markExistingTransactionsAsKnown();

    await _showMessage(t.wallet_import_msg_completed, isCompleted: true);
    await _checkBounceController.forward();

    transactionMonitor.finishImporting();

    setState(() => _isCompleted = true);

    if (mounted) {
      context.go("/home");
    }
  }

  /// Phase 2.3.3: post-sync UI refresh routes through V2
  /// `RefreshWalletUseCase`. Failure is silently swallowed —
  /// `_handleAllSyncsCompleted` is best-effort UI polish; the
  /// orchestrator's tx stream + balance providers re-emit on actual
  /// state changes.
  Future<void> _refreshBalances() async {
    try {
      final useCase = await ref.read(refreshWalletProvider.future);
      await useCase(strategy: SyncStrategy.light);
    } catch (_) {
      // Swallowed by design.
    }
  }

  /// Phase 2.3.3: kick the V2 `AppLifecycleController.start()` once.
  /// The controller drives `BootOrchestrator.start()` then
  /// `SyncOrchestrator.start()`. Boot phase transitions surface in
  /// `bootStateProvider`; per-chain sync transitions surface in
  /// `syncStateProvider`. Both are watched via `ref.listen` in
  /// `build()` to drive the message stream — no need to chain `await`
  /// calls here.
  Future<void> _startImportProcess() async {
    if (_bootStartTriggered) return;
    _bootStartTriggered = true;
    try {
      _progressController.forward();

      final transactionMonitor = ref.read(transactionMonitorServiceProvider);
      transactionMonitor.startImporting();

      if (!mounted) return;

      // Mark `_hasInitialized` immediately so the error listener in
      // `build()` arms (it gates on this flag to avoid surfacing
      // pre-start `AppPhase.error` from a previous run). We no longer
      // pre-emit hardcoded "processing/verifying/initializing" lines —
      // every progress message now reflects an actual orchestrator
      // transition driven by `bootStateProvider` / `syncStateProvider`.
      setState(() => _hasInitialized = true);

      // The lifecycle controller is single-flighted — concurrent
      // `start()` calls coalesce into one boot. We don't await the
      // result here because the message stream is event-driven via
      // `ref.listen`; the `start()` call returns when boot completes
      // (or fails), at which point `appStateProvider` already emitted
      // `AppPhase.ready` (or `AppPhase.error`).
      final controller =
          await ref.read(appLifecycleControllerProvider.future);
      await controller.start();
    } catch (e) {
      if (!mounted) return;
      final errorMsg = _getErrorMessage(e);
      await _showMessage(errorMsg, hasError: true);
      setState(() {
        _hasError = true;
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> _showMessage(
    String text, {
    bool isCompleted = false,
    bool hasError = false,
    bool isRetry = false,
  }) async {
    if (_currentMessageIndex >= 0 && _currentMessageIndex < _messages.length) {
      setState(() {
        _messages[_currentMessageIndex] = ImportMessage(
          text: _messages[_currentMessageIndex].text,
          isCompleted: true,
          hasError: _messages[_currentMessageIndex].hasError,
          isRetry: _messages[_currentMessageIndex].isRetry,
        );
      });
    }

    setState(() {
      _messages.add(
        ImportMessage(
          text: text,
          isCompleted: isCompleted,
          hasError: hasError,
          isRetry: isRetry,
        ),
      );
      _currentMessageIndex = _messages.length - 1;
    });

    // Drive the entry animations without awaiting their 600 ms completion.
    // Previously this method awaited Future.wait of both controllers, which
    // gated the entire import flow on each message's animation finishing —
    // ~600 ms × 6 messages = ~3.6 s of pure animation wait sitting on top
    // of real import work. The user perceived this as a freeze because
    // the orbital/particle/glow animations on the same Ticker provider
    // stuttered while the import thread was both doing heavy crypto/FFI
    // work AND awaiting the message animation. The animations are still
    // visually present — they just no longer block the next step of the
    // import pipeline. Mirrors V2's `_BootProgressScreen` which renders
    // messages reactively from a stream and never waits on animations.
    _fadeController.reset();
    _slideController.reset();
    unawaited(_fadeController.forward());
    unawaited(_slideController.forward());
  }

  String _getErrorMessage(dynamic error) {
    final t = AppLocalizations.of(context);
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('tentando reconectar') ||
        errorStr.contains('tentativas')) {
      return t.wallet_import_error_reconnecting;
    } else if (errorStr.contains('mnemonic')) {
      return t.wallet_import_error_load_data;
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return t.wallet_import_error_connection;
    } else if (errorStr.contains('datasource')) {
      return t.wallet_import_error_servers;
    } else if (errorStr.contains('nenhum datasource')) {
      return t.wallet_import_error_servers_unavailable;
    }

    return t.wallet_import_error_generic;
  }

  String _getUserFriendlyErrorMessage(String? errorMessage) {
    final t = AppLocalizations.of(context);
    if (errorMessage == null) return t.wallet_import_error_occurred;

    final errorStr = errorMessage.toLowerCase();

    if (errorStr.contains('tentando reconectar') ||
        errorStr.contains('tentativas')) {
      final match = RegExp(r'\((\d+)/(\d+)\)').firstMatch(errorMessage);
      if (match != null) {
        return t.wallet_import_error_reconnecting_count(
          match.group(1) ?? '',
          match.group(2) ?? '',
        );
      }
      return t.wallet_import_error_reconnecting_servers;
    } else if (errorStr.contains('nenhum datasource')) {
      return t.wallet_import_error_no_connection;
    } else if (errorStr.contains('datasource')) {
      return t.wallet_import_error_servers_long;
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return t.wallet_import_error_internet;
    } else if (errorStr.contains('mnemonic')) {
      return t.wallet_import_error_wallet_data;
    }

    return errorMessage;
  }

  void _retry() {
    setState(() {
      _messages.clear();
      _currentMessageIndex = -1;
      _hasError = false;
      _errorMessage = null;
      _isCompleted = false;
      _hasInitialized = false;
      _isHandlingSuccess = false;
    });
    _progressController.reset();
    _startImportProcess();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Phase 2.3.3: error tracking via V2 `appStateProvider`. Boot
    // failures surface as `AppPhase.error` with `state.failure`
    // populated; UI shows a retry-capable error card.
    ref.listen<AsyncValue<AppState>>(appStateProvider, (previous, next) async {
      final state = next.valueOrNull;
      if (state == null) return;
      if (state.phase == AppPhase.error &&
          _hasInitialized &&
          !_hasError &&
          !_isCompleted) {
        final errorMsg =
            state.failure?.message ?? t.wallet_import_error_unknown;
        await _showMessage(_getErrorMessage(errorMsg), hasError: true);
        setState(() {
          _hasError = true;
          _errorMessage = _getUserFriendlyErrorMessage(errorMsg);
        });
      }
    });

    // Phase 2.3.3: granular boot-phase progress. The boot orchestrator
    // emits a distinct `BootPhase` for each step
    // (initializingPlatform → initializingDatabase → loadingCredentials
    // → connectingServices → authenticatingSession → ready). Surfacing
    // each phase to the user matters most on first import where each
    // step can take seconds (FFI init, Electrum connect, Breez auth).
    ref.listen<AsyncValue<BootState>>(bootStateProvider, (previous, next) {
      final bootState = next.valueOrNull;
      if (bootState == null) return;
      _trackBootPhase(bootState);
    });

    // Phase 2.3.3: per-chain "synced X" messages from V2
    // `syncStateProvider`. When all three operational chains report
    // `connected` AND the orchestrator is in `cooling`/`idle` (sync
    // tick has completed at least once), trigger the post-sync
    // sequence.
    ref.listen<AsyncValue<SyncState>>(syncStateProvider, (previous, next) {
      final syncState = next.valueOrNull;
      if (syncState == null) return;
      _trackChainSyncProgress(syncState);
    });

    // Phase 2.3.3: when V2 reports `AppPhase.ready`, run the
    // post-boot sequence (tx-monitor priming + completion message +
    // navigation to home). Idempotent via `_isHandlingSuccess`.
    ref.listen<AsyncValue<AppState>>(appStateProvider, (previous, next) {
      final state = next.valueOrNull;
      if (state?.phase == AppPhase.ready &&
          !_isHandlingSuccess &&
          !_isCompleted) {
        _handleAllSyncsCompleted();
      }
    });

    return AnimatedOpacity(
      opacity: _isCompleted ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            ...List.generate(20, (index) => _buildParticle(index)),

            if (!_hasError) _buildOrbitalAnimation(),

            if (!_hasError) _buildProgressBar(),

            Positioned(
              left: 24,
              bottom: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _messages.length; i++)
                    _buildMessageItem(_messages[i], i),
                ],
              ),
            ),

            if (_hasError)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.cloud_off_outlined,
                          color: Theme.of(context).colorScheme.error,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _errorMessage ?? t.wallet_import_error_occurred,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _retry,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            t.common_retry,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.surface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: [0.0, 0.4, 0.5, 0.6, 1.0],
                begin: Alignment(-1.0 + (_progressController.value * 2), 0),
                end: Alignment(1.0 + (_progressController.value * 2), 0),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrbitalAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _orbitalController,
          _pulseController,
          _glowController,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200 + (_glowController.value * 20),
                height: 200 + (_glowController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.1 * _glowController.value,
                      ),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: _orbitalController.value * 2 * math.pi,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: -_orbitalController.value * 2 * math.pi * 1.5,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 40 + (_pulseController.value * 10),
                height: 40 + (_pulseController.value * 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.15 + (_pulseController.value * 0.1),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.4 + (_pulseController.value * 0.2),
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.2 * _pulseController.value,
                      ),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final startX = random.nextDouble();
    final startY = random.nextDouble();
    final duration = 3000 + random.nextInt(4000);
    final size = 2.0 + random.nextDouble() * 3;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: duration),
      builder: (context, double value, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * startX,
          top: MediaQuery.of(context).size.height * (startY - value * 0.3) % 1,
          child: Opacity(
            opacity: (0.3 + (math.sin(value * math.pi * 2) * 0.3)).clamp(
              0.0,
              0.6,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(ImportMessage message, int index) {
    final isCurrentMessage = index == _currentMessageIndex;

    final isRetryMessage = message.isRetry;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _slideController]),
      builder: (context, child) {
        final fadeValue = isCurrentMessage ? _fadeController.value : 1.0;
        final slideValue = isCurrentMessage ? _slideController.value : 1.0;
        final offset = (1 - slideValue) * 20.0;

        return Opacity(
          opacity: fadeValue * (message.hasError ? 1.0 : 0.85),
          child: Transform.translate(
            offset: Offset(-offset, 0),
            child: IntrinsicWidth(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      message.hasError
                          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
                          : isRetryMessage
                          ? context.appColors.warning.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        message.hasError
                            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
                            : isRetryMessage
                            ? context.appColors.warning.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isCompleted && !message.hasError) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(
                                      alpha: 0.3 * value,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.surface,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ] else if (isRetryMessage) ...[
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.appColors.warning.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ] else if (!message.hasError) ...[
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        message.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              message.hasError
                                  ? Theme.of(context).colorScheme.error
                                  : isRetryMessage
                                  ? context.appColors.warning
                                  : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              message.isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
