import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_state.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/features/boot/domain/boot_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
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

  late AnimationController _checkBounceController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _orbitalController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

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

  /// Per-chain sync progress messaging (2026-05-24 redesign).
  ///
  /// Previously this method watched `state.perChain[chain] ==
  /// ServiceLifecycle.connected`, but that lifecycle flips to
  /// `connected` during BOOT — the moment each SDK handle is alive,
  /// well before its first network sync returns. The visible
  /// consequence was all three "synced X" lines firing simultaneously
  /// the instant boot finished, so the user perceived the loading
  /// screen as "going too fast" without actually reflecting the
  /// per-chain network work.
  ///
  /// The orchestrator now exposes a separate signal,
  /// `SyncState.firstSyncedChains`, which is populated as each chain
  /// finishes its first sync cycle (success OR failure). Iterating
  /// THIS set gives one message per chain at the moment that chain
  /// actually has fresh data sitting in the store.
  ///
  /// Idempotent — `_completedChains` guards against duplicate emits
  /// when `syncStateProvider` re-emits the same state on subsequent
  /// periodic ticks.
  void _trackChainSyncProgress(SyncState state) {
    final t = AppLocalizations.of(context);
    for (final chain in state.firstSyncedChains) {
      if (_completedChains.contains(chain.name)) continue;
      _completedChains.add(chain.name);
      // ignore: unawaited_futures
      _showMessage(
        t.wallet_import_msg_synced(_getChainName(chain.name)),
      );
    }

    // Import-screen navigation gate. The cold-start path bypasses this
    // screen entirely (SplashScreen routes straight to /home on
    // AppPhase.ready), so the gate here only affects the import flow:
    // we hold the splash + animations until the chain whose data the
    // user is most likely to look for first has settled.
    //
    // Gate condition (2026-05-24): wait specifically for Lightning
    // (Breez). Rationale: Breez is the source of Liquid asset swaps,
    // which is the data the user typically wants to see immediately
    // after importing — Liquid native (LWK) txs and Bitcoin (BDK) txs
    // surface fine via progressive hydration once the home mounts.
    // If Lightning fails, its entry still lands in `firstSyncedChains`
    // (the orchestrator counts a failure as "we got an answer"), so
    // the gate releases.
    //
    // Belt-and-suspenders: also release on `phase == cooling`
    // (everything settled) or `lastError` (all chains hard-failed) so
    // we never strand the user if Lightning hangs in a non-timeout
    // state.
    final appState = ref.read(appStateProvider).valueOrNull;
    final lightningSettled =
        state.firstSyncedChains.contains(ChainId.lightning);
    final allSettled = state.phase == SyncPhase.cooling &&
        (state.lastSuccessAt != null || state.lastError != null);
    final firstSyncCycleDone =
        lightningSettled || allSettled || state.lastError != null;
    if (appState?.phase == AppPhase.ready &&
        firstSyncCycleDone &&
        !_isHandlingSuccess &&
        !_isCompleted) {
      _handleAllSyncsCompleted();
    }
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

  /// Progressive hydration: navigate to home as soon as
  /// `AppLifecycleController` emits `AppPhase.ready`. Boot now reaches
  /// ready right after services are operational (no longer blocking on
  /// the full first-sync cycle), and balances / transactions stream
  /// into the home screen progressively via `watchBalanceFor` /
  /// `watchTransactions`.
  ///
  /// Removed from the blocking gate:
  /// - Explicit `_refreshBalances()` call — `SyncOrchestrator.start()`
  ///   already runs an immediate light refresh; the eager `await` here
  ///   was redundant work that just delayed the splash exit.
  /// - Awaited `markExistingTransactionsAsKnown()` — kept as a fire-
  ///   and-forget so new-tx popup dedup still seeds, without gating UI.
  Future<void> _handleAllSyncsCompleted() async {
    if (_isCompleted || _isHandlingSuccess) return;

    setState(() => _isHandlingSuccess = true);

    if (!mounted) return;
    final t = AppLocalizations.of(context);

    // Notification suppression during the import burst used to be a
    // manual `setImportInProgress(true/false)` flip here. With the
    // persisted dedup ledger + baseline-absorb pass inside the V2
    // notifier (2026-05-12 redesign), the notifier handles this
    // intrinsically: every tx the orchestrator persists during this
    // window is silently registered without emitting until the user
    // reaches `/home` (HomeScreen calls `notifier.setHomeReached()`).
    // No manual UI-driven coordination needed here anymore.

    await _showMessage(t.wallet_import_msg_completed, isCompleted: true);
    await _checkBounceController.forward();

    setState(() => _isCompleted = true);

    if (mounted) {
      context.go("/home");
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

      // (Removed: `notifier.setImportInProgress(true)` — the V2
      // notifier now uses persisted dedup + an internal baseline phase
      // that is sticky until the user reaches `/home`. See the comment
      // in `_handleAllSyncsCompleted`.)

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
      BootTracer.mark('import_loading.controller.resolve.begin');
      final controller =
          await ref.read(appLifecycleControllerProvider.future);
      BootTracer.mark('import_loading.controller.resolve.end');
      BootTracer.mark('import_loading.controller.start.begin');
      await controller.start();
      BootTracer.mark('import_loading.controller.start.end');
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

    // Navigation to /home is driven by the sync-completion gate inside
    // `_trackChainSyncProgress` (called from the syncStateProvider
    // listener above). We deliberately do NOT auto-fire on
    // `AppPhase.ready` here — that arrives at boot+~500ms before any
    // chain has finished its first sync, and navigating then would put
    // the freshly-imported user on /home with empty balances. The
    // appStateProvider listener earlier in this `build()` still arms
    // the error path; navigation itself waits for sync completion.

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
                mainAxisSize: MainAxisSize.min,
                children: _buildVisibleMessages(),
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

  static const int _maxVisibleMessages = 4;

  double _opacityForDepth(int depthFromNewest) {
    const opacities = <double>[1.0, 0.55, 0.3, 0.12];
    if (depthFromNewest < 0) return opacities.first;
    if (depthFromNewest >= opacities.length) return 0.0;
    return opacities[depthFromNewest];
  }

  List<Widget> _buildVisibleMessages() {
    final total = _messages.length;
    final start = math.max(0, total - _maxVisibleMessages);
    return [
      for (int i = start; i < total; i++)
        _buildMessageItem(_messages[i], i, (total - 1) - i),
    ];
  }

  Widget _buildMessageItem(
    ImportMessage message,
    int globalIndex,
    int depthFromNewest,
  ) {
    final isRetryMessage = message.isRetry;
    final depthOpacity =
        message.hasError ? 1.0 : _opacityForDepth(depthFromNewest);

    return TweenAnimationBuilder<double>(
      key: ValueKey('import_msg_$globalIndex'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, entry, child) {
        return Opacity(
          opacity: entry,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              heightFactor: entry,
              child: Transform.translate(
                offset: Offset((entry - 1) * 24, 0),
                child: child,
              ),
            ),
          ),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        opacity: depthOpacity,
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
      }
}
