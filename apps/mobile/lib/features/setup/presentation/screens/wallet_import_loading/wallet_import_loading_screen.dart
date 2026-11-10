import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_state.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/features/boot/domain/boot_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'widgets/opening_scene.dart';

/// The steps of opening a wallet, as the screen shows them.
enum OpeningStep {
  /// The app reads the wallet: the platform, the storage, and the keys.
  opening,

  /// The wallet connects to the Bitcoin and Liquid networks.
  connecting,

  /// The wallet is open, and its balances arrive.
  syncing,

  /// Everything is ready: the home screen opens.
  done,
}

/// Why a wallet did not open, as the screen tells it.
enum OpeningFailure {
  /// The networks did not answer: most of the time, the internet.
  connection,

  /// The recovery phrase is not on this device.
  missingPhrase,

  /// Anything else.
  other;

  /// The kind of [error], from its message.
  static OpeningFailure of(Object error) {
    final text = (error is Failure ? error.message : '$error').toLowerCase();
    const network = [
      'timeout',
      'connect',
      'network',
      'socket',
      'electrum',
      'host',
      'unreachable',
      'offline',
    ];
    return network.any(text.contains) ? connection : other;
  }
}

/// Opens the wallet after it is created or imported, then opens the home
/// screen.
///
/// The steps show as art, not as text: the Mooze coin appears, an orbit
/// ring turns as the wallet connects, and the coin of each asset flies
/// into the orbit as its network syncs. A step track and one short
/// caption follow along. Once Liquid has synced, the coins still out of
/// the orbit land one after another, a burst plays, "All set" stays for a
/// beat, and the home screen opens. The ending always plays in full, and
/// the screen shows for at least [minimumShow], so a fast opening does not
/// cut it short.
///
/// A failed start retries by itself, up to [maxAttempts] in all, and the
/// caption says so. Then a glass panel explains what happened and offers
/// to try again; a missing recovery phrase sends the user back to import
/// it. If the balances take longer than [syncPatience], the home screen
/// opens anyway and they arrive there.
class WalletImportLoadingScreen extends ConsumerStatefulWidget {
  const WalletImportLoadingScreen({super.key});

  /// Starts before the screen asks the user: the first one and two
  /// automatic retries.
  static const int maxAttempts = 3;

  /// Wait before an automatic retry, times the number of the attempt.
  static const Duration retryDelay = Duration(seconds: 2);

  /// Longest wait for the first sync once the wallet is open.
  static const Duration syncPatience = Duration(seconds: 45);

  /// Wait before the caption says that the first time takes longer.
  static const Duration slowAfter = Duration(seconds: 12);

  /// The least time the screen shows before the home screen opens.
  static const Duration minimumShow = Duration(milliseconds: 3500);

  /// How long "All set" stays after the burst.
  static const Duration doneHold = Duration(milliseconds: 600);

  @override
  ConsumerState<WalletImportLoadingScreen> createState() =>
      _WalletImportLoadingScreenState();
}

class _WalletImportLoadingScreenState
    extends ConsumerState<WalletImportLoadingScreen>
    with TickerProviderStateMixin {
  /// The slow cycle of the scene while the wallet opens.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: Motion.durationAmbient * 3,
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
  );
  late final AnimationController _finale = AnimationController(
    vsync: this,
    duration: Motion.durationCelebrate,
  );
  late final Map<Asset, AnimationController> _arrivals = {
    for (final asset in Asset.values)
      asset: AnimationController(
        vsync: this,
        duration: Motion.durationSlow * 2,
      ),
  };

  OpeningStep _step = OpeningStep.opening;
  OpeningFailure? _failure;
  bool _retrying = false;
  bool _slow = false;
  bool _still = false;
  bool _started = false;
  int _attempts = 0;
  Timer? _retryTimer;
  Timer? _slowTimer;
  Timer? _minimumTimer;
  final Completer<void> _minimumShown = Completer();
  Timer? _patienceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = Motion.isReduced(context);
    if (_started) return;
    _started = true;
    if (!_still) _spin.repeat();
    _minimumTimer = Timer(
      WalletImportLoadingScreen.minimumShow,
      _minimumShown.complete,
    );
    _slowTimer = Timer(WalletImportLoadingScreen.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _slowTimer?.cancel();
    _minimumTimer?.cancel();
    _patienceTimer?.cancel();
    _spin.dispose();
    _ring.dispose();
    _finale.dispose();
    for (final arrival in _arrivals.values) {
      arrival.dispose();
    }
    super.dispose();
  }

  /// Starts the app lifecycle controller: boot, then the first sync. The
  /// controller is single-flighted, so a start already running joins it.
  Future<void> _start() async {
    if (!mounted) return;
    _attempts++;
    setState(() {
      _retrying = false;
      _failure = null;
    });
    try {
      BootTracer.mark('import_loading.controller.resolve.begin');
      final controller = await ref.read(appLifecycleControllerProvider.future);
      BootTracer.mark('import_loading.controller.resolve.end');
      BootTracer.mark('import_loading.controller.start.begin');
      final result = await controller.start();
      BootTracer.mark('import_loading.controller.start.end');
      if (!mounted) return;
      result.match(_onFailed, (state) {
        if (state.phase == AppPhase.needsSetup) {
          _fail(OpeningFailure.missingPhrase);
        } else if (state.phase == AppPhase.ready) {
          _onOpen();
        }
      });
    } catch (error) {
      if (mounted) _onFailed(error);
    }
  }

  void _onFailed(Object error) {
    if (_attempts < WalletImportLoadingScreen.maxAttempts) {
      setState(() => _retrying = true);
      _retryTimer = Timer(
        WalletImportLoadingScreen.retryDelay * _attempts,
        _start,
      );
    } else {
      _fail(OpeningFailure.of(error));
    }
  }

  void _fail(OpeningFailure failure) {
    _spin.stop();
    _patienceTimer?.cancel();
    setState(() {
      _retrying = false;
      _failure = failure;
    });
  }

  /// A new round of attempts, from the panel.
  void _tryAgain() {
    _attempts = 0;
    if (!_still) _spin.repeat();
    _start();
  }

  void _onBoot(BootState state) {
    final step = switch (state.phase) {
      BootPhase.connectingServices ||
      BootPhase.authenticatingSession => OpeningStep.connecting,
      _ => OpeningStep.opening,
    };
    if (step == OpeningStep.connecting) _showRing();
    // A retry boots again: the track does not step back.
    if (step.index > _step.index) setState(() => _step = step);
  }

  void _onOpen() {
    if (_step.index >= OpeningStep.syncing.index) return;
    _showRing();
    setState(() => _step = OpeningStep.syncing);
    _patienceTimer ??= Timer(WalletImportLoadingScreen.syncPatience, _finish);
    _onSync(ref.read(syncStateProvider).valueOrNull);
  }

  void _showRing() => _still ? _ring.value = 1 : _ring.forward();

  /// The coins of a chain fly in as it syncs. The home screen waits for
  /// Liquid, the source of the assets and swaps the user looks for first;
  /// a failed sync, or a settled cycle, also lets it open, so a stuck
  /// network never strands the user.
  void _onSync(SyncState? state) {
    if (state == null) return;
    for (final chain in state.firstSyncedChains) {
      _arrive(chain);
    }
    if (_step != OpeningStep.syncing) return;
    final liquidSettled = state.firstSyncedChains.contains(ChainId.liquid);
    final allSettled =
        state.phase == SyncPhase.cooling &&
        (state.lastSuccessAt != null || state.lastError != null);
    if (liquidSettled || allSettled || state.lastError != null) _finish();
  }

  void _arrive(ChainId chain) => _fly(switch (chain) {
    ChainId.bitcoin => const [Asset.btc],
    ChainId.liquid => const [Asset.lbtc, Asset.depix, Asset.usdt],
    _ => const <Asset>[],
  });

  /// Flies the coins of [assets] still out of the orbit into it, one after
  /// another.
  void _fly(Iterable<Asset> assets) {
    final waiting = [
      for (final asset in assets)
        if (_arrivals[asset]!.isDismissed) _arrivals[asset]!,
    ];
    for (final (i, arrival) in waiting.indexed) {
      if (_still) {
        arrival.value = 1;
      } else {
        Future.delayed(Motion.staggerStep * 3 * i, () {
          if (mounted && arrival.isDismissed) arrival.forward();
        });
      }
    }
  }

  /// Completes once [arrival] has landed.
  Future<void> _landed(AnimationController arrival) {
    if (arrival.isCompleted) return Future.value();
    final landed = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      arrival.removeStatusListener(onStatus);
      landed.complete();
    }

    arrival.addStatusListener(onStatus);
    return landed.future;
  }

  /// The ending: the coins still out of the orbit land, the burst plays,
  /// and "All set" stays for a beat, then the home screen opens, once the
  /// screen has shown for [WalletImportLoadingScreen.minimumShow]. Under
  /// reduced motion, the home screen opens at once.
  Future<void> _finish() async {
    if (_step == OpeningStep.done || _failure != null) return;
    _patienceTimer?.cancel();
    _slowTimer?.cancel();
    setState(() => _step = OpeningStep.done);
    _fly(Asset.values);
    if (!_still) {
      await Future.wait([
        for (final arrival in _arrivals.values) _landed(arrival),
      ]);
      if (!mounted) return;
      // The picture rests as the burst plays.
      _spin.stop();
      HapticFeedback.lightImpact();
      await _finale.forward();
      await Future.wait([
        Future<void>.delayed(WalletImportLoadingScreen.doneHold),
        _minimumShown.future,
      ]);
    } else {
      HapticFeedback.lightImpact();
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppState>>(appStateProvider, (_, next) {
      if (next.valueOrNull?.phase == AppPhase.ready) _onOpen();
    });
    ref.listen<AsyncValue<BootState>>(bootStateProvider, (_, next) {
      final state = next.valueOrNull;
      if (state != null) _onBoot(state);
    });
    ref.listen<AsyncValue<SyncState>>(
      syncStateProvider,
      (_, next) => _onSync(next.valueOrNull),
    );

    final failure = _failure;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: failure == null ? 1 : 0.35,
                      duration: Motion.of(context, Motion.durationBase),
                      curve: Motion.curveMove,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _spin,
                          _ring,
                          _finale,
                          ..._arrivals.values,
                        ]),
                        builder: (context, _) => OpeningScene(
                          motion: OpeningMotion(
                            spin: _spin.value,
                            ring: _ring.value,
                            arrivals: {
                              for (final MapEntry(:key, :value)
                                  in _arrivals.entries)
                                key: value.value,
                            },
                            finale: _finale.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.durationBase),
                    switchInCurve: Motion.curveEnter,
                    switchOutCurve: Motion.curveExit,
                    child: failure == null
                        ? _Progress(
                            key: const ValueKey('progress'),
                            step: _step,
                            retrying: _retrying,
                            slow: _slow,
                            pulse: _spin,
                          )
                        : _FailurePanel(
                            key: ValueKey(failure),
                            failure: failure,
                            onRetry: _tryAgain,
                            onImportAgain: () =>
                                context.go('/setup/first-access'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The caption of the step and the step track.
class _Progress extends StatelessWidget {
  const _Progress({
    super.key,
    required this.step,
    required this.retrying,
    required this.slow,
    required this.pulse,
  });

  final OpeningStep step;
  final bool retrying;
  final bool slow;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final title = switch (step) {
      OpeningStep.opening => t.wallet_open_step_opening,
      OpeningStep.connecting => t.wallet_open_step_connecting,
      OpeningStep.syncing => t.wallet_open_step_syncing,
      OpeningStep.done => t.wallet_open_step_done,
    };
    final hint = retrying
        ? t.wallet_open_retrying
        : slow
        ? t.wallet_open_hint_slow
        : t.wallet_open_hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.durationBase),
          switchInCurve: Motion.curveEnter,
          switchOutCurve: Motion.curveExit,
          child: Column(
            key: ValueKey('$title|$hint'),
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // The hint keeps its height once everything is ready, so the
              // track does not move.
              Visibility.maintain(
                visible: step != OpeningStep.done,
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _StepTrack(step: step, pulse: pulse),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Three nodes, one per step: the keys, the networks, and the coins. A
/// step done fills with the brand color, the step in progress glows, and
/// the next ones wait in gray.
class _StepTrack extends StatelessWidget {
  const _StepTrack({required this.step, required this.pulse});

  final OpeningStep step;
  final Animation<double> pulse;

  static const _icons = [
    Icons.key_rounded,
    Icons.lan_rounded,
    Icons.toll_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, icon) in _icons.indexed) ...[
            if (i > 0) _Connector(filled: step.index >= i),
            _StepNode(
              icon: icon,
              state: step == OpeningStep.done || step.index > i
                  ? _NodeState.done
                  : step.index == i
                  ? _NodeState.active
                  : _NodeState.waiting,
              pulse: pulse,
            ),
          ],
        ],
      ),
    );
  }
}

enum _NodeState { waiting, active, done }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.icon,
    required this.state,
    required this.pulse,
  });

  final IconData icon;
  final _NodeState state;
  final Animation<double> pulse;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final duration = Motion.of(context, Motion.durationBase);
    final (fill, border, ink) = switch (state) {
      _NodeState.done => (brand, brand, context.colors.onPrimaryColor),
      _NodeState.active => (brand.withValues(alpha: 0.14), brand, brand),
      _NodeState.waiting => (
        context.colors.textPrimary.withValues(alpha: 0.05),
        AppSurfaces.hairline(context),
        context.colors.textSecondary,
      ),
    };
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        // The step in progress breathes with the scene.
        final glow = state == _NodeState.active
            ? 0.18 + 0.14 * math.sin(6 * math.pi * pulse.value)
            : 0.0;
        return AnimatedContainer(
          duration: duration,
          curve: Motion.curveMove,
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border, width: 1.5),
            boxShadow: [
              if (glow > 0)
                BoxShadow(
                  color: brand.withValues(alpha: glow),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: child,
        );
      },
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: ink),
        duration: duration,
        builder: (context, color, _) => Icon(icon, size: 22, color: color),
      ),
    );
  }
}

/// The line between two nodes. It fills as the step before it is done.
class _Connector extends StatelessWidget {
  const _Connector({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: context.colors.textPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(1),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: Motion.of(context, Motion.durationEmphasis),
        curve: Motion.curveMove,
        widthFactor: filled ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.primaryColor,
            borderRadius: BorderRadius.circular(1),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// What went wrong, in a glass panel, with the way forward: try again,
/// or import the wallet again when its phrase is missing.
class _FailurePanel extends StatelessWidget {
  const _FailurePanel({
    super.key,
    required this.failure,
    required this.onRetry,
    required this.onImportAgain,
  });

  final OpeningFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onImportAgain;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (icon, message) = switch (failure) {
      OpeningFailure.connection => (
        Icons.wifi_off_rounded,
        t.wallet_open_error_connection,
      ),
      OpeningFailure.missingPhrase => (
        Icons.key_off_rounded,
        t.wallet_open_error_missing,
      ),
      OpeningFailure.other => (
        Icons.error_outline_rounded,
        t.wallet_open_error_generic,
      ),
    };
    final missing = failure == OpeningFailure.missingPhrase;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.textPrimary.withValues(alpha: 0.06),
                border: Border.all(color: AppSurfaces.hairline(context)),
              ),
              child: Icon(icon, size: 26, color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            header: true,
            child: Text(
              t.wallet_open_error_title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: missing ? t.wallet_open_import_again : t.common_retry,
            onPressed: missing ? onImportAgain : onRetry,
          ),
        ],
      ),
    );
  }
}
