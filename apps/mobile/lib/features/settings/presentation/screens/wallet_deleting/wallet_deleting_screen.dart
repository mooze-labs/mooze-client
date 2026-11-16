import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'widgets/closing_scene.dart';

/// Deletes the wallet once the user has confirmed it with the PIN, then
/// starts the app over at the onboarding.
///
/// The delete shows as art: the opening of the wallet, played backward
/// and put to rest (see [ClosingScene]). The coins of the assets leave the
/// orbit one after another while the wallet is deleted. Once it is
/// deleted, and every coin has left, the farewell plays, "Wallet deleted"
/// stays for [doneHold], and the onboarding opens. A fast delete does not
/// cut the scene short.
///
/// The delete cannot stop halfway, so the screen cannot be left while it
/// runs. If it fails, the coins come back to the orbit, and a glass panel
/// offers to try again or to go back.
class WalletDeletingScreen extends ConsumerStatefulWidget {
  const WalletDeletingScreen({super.key});

  /// Wait between two coins leaving the orbit.
  static const Duration departureStagger = Duration(milliseconds: 240);

  /// How long "Wallet deleted" stays once the scene rests.
  static const Duration doneHold = Duration(milliseconds: 1200);

  @override
  ConsumerState<WalletDeletingScreen> createState() =>
      _WalletDeletingScreenState();
}

class _WalletDeletingScreenState extends ConsumerState<WalletDeletingScreen>
    with TickerProviderStateMixin, StageHaptics<WalletDeletingScreen> {
  /// The slow cycle of the scene while the wallet is deleted.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: Motion.durationAmbient * 3,
  );
  late final AnimationController _farewell = AnimationController(
    vsync: this,
    duration: Motion.durationFarewell,
  );
  late final Map<Asset, AnimationController> _departures = {
    for (final asset in Asset.values)
      asset: AnimationController(
        vsync: this,
        duration: Motion.durationSlow * 2,
      ),
  };

  /// The caption of the delete fades out after the peak, and the caption
  /// of the end comes in, on the same timeline as the farewell.
  late final Animation<double> _captionOut = ReverseAnimation(
    CurvedAnimation(
      parent: _farewell,
      curve: const Interval(0.45, ClosingScene.revealAt, curve: Curves.easeIn),
    ),
  );
  late final Animation<double> _captionIn = CurvedAnimation(
    parent: _farewell,
    curve: const Interval(ClosingScene.revealAt, 0.9, curve: Motion.curveEnter),
  );

  final List<Timer> _timers = [];
  bool _started = false;
  bool _still = false;
  bool _failed = false;

  /// Whether the caption tells that the wallet is deleted.
  bool _done = false;

  @override
  Animation<double> get stageAnimation => _farewell;

  @override
  List<StageBeat> get stageBeats => const [
    (at: ClosingScene.edgeOnAt, play: HapticFeedback.mediumImpact),
    (at: ClosingScene.landAt, play: HapticFeedback.lightImpact),
  ];

  @override
  void initState() {
    super.initState();
    _farewell.addListener(() {
      final done = _farewell.value >= ClosingScene.revealAt;
      if (done != _done) setState(() => _done = done);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = Motion.isReduced(context);
    if (_started) return;
    _started = true;
    if (!_still) _spin.repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _delete());
    _afterEntrance(_depart);
  }

  @override
  void dispose() {
    _cancelTimers();
    _spin.dispose();
    _farewell.dispose();
    for (final departure in _departures.values) {
      departure.dispose();
    }
    super.dispose();
  }

  /// Runs [action] once the route has come in, so the first coin does not
  /// leave under the page transition.
  void _afterEntrance(VoidCallback action) {
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.isCompleted) {
      action();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      route.removeStatusListener(onStatus);
      if (mounted) action();
    }

    route.addStatusListener(onStatus);
  }

  /// The coins leave the orbit one after another, the last one in first.
  void _depart() {
    for (final (i, asset) in Asset.values.reversed.indexed) {
      final departure = _departures[asset]!;
      if (_still) {
        departure.value = 1;
        continue;
      }
      _timers.add(
        Timer(WalletDeletingScreen.departureStagger * i, () {
          if (mounted && !_failed) departure.forward();
        }),
      );
    }
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  Future<void> _delete() async {
    if (!mounted) return;
    try {
      ref.invalidate(pixRepositoryProvider);
      final controller = await ref.read(appLifecycleControllerProvider.future);
      final result = await controller.deleteWalletAndReimport();
      if (!mounted) return;
      result.match((failure) => _fail(failure), (_) => _finish());
    } catch (error, stackTrace) {
      if (mounted) _fail(error, stackTrace);
    }
  }

  void _fail(Object error, [StackTrace? stackTrace]) {
    ref
        .read(loggerProvider)
        .error(
          'wallet.delete.screen_failed',
          {'error': '$error'},
          error: error,
          stackTrace: stackTrace,
        );
    _cancelTimers();
    _spin.stop();
    // The wallet is still here: its coins come back to the orbit.
    for (final departure in _departures.values) {
      if (_still) {
        departure.value = 0;
      } else {
        departure.reverse();
      }
    }
    setState(() => _failed = true);
  }

  /// A new attempt, from the panel. It plays the departures again.
  void _tryAgain() {
    setState(() => _failed = false);
    if (!_still) _spin.repeat();
    _depart();
    _delete();
  }

  /// Completes once [departure] has left the orbit.
  Future<void> _left(AnimationController departure) {
    if (departure.isCompleted) return Future.value();
    final left = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      departure.removeStatusListener(onStatus);
      left.complete();
    }

    departure.addStatusListener(onStatus);
    return left.future;
  }

  /// The ending: the coins still on the orbit leave, the farewell plays,
  /// and "Wallet deleted" stays for a beat. Then the app starts over at
  /// the onboarding. Under reduced motion, the scene shows its end at once.
  Future<void> _finish() async {
    await Future.wait([
      for (final departure in _departures.values) _left(departure),
    ]);
    if (!mounted) return;
    // The picture rests as the farewell plays.
    if (_still) {
      _farewell.value = 1;
      HapticFeedback.lightImpact();
    } else {
      await _farewell.forward();
    }
    await Future<void>.delayed(WalletDeletingScreen.doneHold);
    if (!mounted) return;
    await _forget();
    if (mounted) context.go('/setup/onboarding');
  }

  /// Forgets what the app kept in memory about the deleted wallet, so the
  /// next wallet starts from nothing. It runs right before the onboarding
  /// opens: the screens under this one are still mounted, and would
  /// rebuild these providers for a wallet that is gone.
  Future<void> _forget() async {
    ref.invalidate(mnemonicProvider);
    // The core forgets the identity of the deleted mnemonic.
    await ref.read(sessionManagerServiceProvider).resetIdentity().run();
    ref.invalidate(sessionManagerServiceProvider);
    ref.invalidate(authenticatedClientProvider);
    ref.invalidate(pixRepositoryProvider);
    ref.invalidate(userDataProvider);
    ref.invalidate(balanceCacheProvider);
    ref.invalidate(transactionHistoryCacheProvider);
    // Drop the V2 cache-first balance state and force the walletId to be
    // regenerated, so the next wallet starts from an empty snapshot and
    // never sees the deleted wallet's persisted balances.
    ref.invalidate(walletIdProvider);
    ref.invalidate(allBalancesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      // The delete cannot stop halfway: the screen can be left only after
      // it failed.
      canPop: _failed,
      child: Scaffold(
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
                        opacity: _failed ? 0.35 : 1,
                        duration: Motion.of(context, Motion.durationBase),
                        curve: Motion.curveMove,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _spin,
                            _farewell,
                            ..._departures.values,
                          ]),
                          builder: (context, _) => ClosingScene(
                            motion: ClosingMotion(
                              spin: _spin.value,
                              departures: {
                                for (final MapEntry(:key, :value)
                                    in _departures.entries)
                                  key: value.value,
                              },
                              farewell: _farewell.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Motion.of(context, Motion.durationBase),
                      switchInCurve: Motion.curveEnter,
                      switchOutCurve: Motion.curveExit,
                      child: _failed
                          ? _FailurePanel(
                              key: const ValueKey('failure'),
                              onRetry: _tryAgain,
                              onBack: () => context.pop(),
                            )
                          // Sized by the taller caption, so the scene
                          // does not move when the caption changes.
                          : IndexedStack(
                              key: const ValueKey('captions'),
                              index: _done ? 1 : 0,
                              alignment: Alignment.topCenter,
                              children: [
                                _Caption(
                                  title: t.wallet_delete_step_deleting,
                                  hint: t.wallet_delete_hint,
                                  reveal: _captionOut,
                                ),
                                _Caption(
                                  title: t.wallet_delete_step_done,
                                  hint: t.wallet_delete_done_hint,
                                  reveal: _captionIn,
                                ),
                              ],
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
}

/// A title and a hint under the scene, shown as far as [reveal] goes: it
/// fades and grows from 90% into place.
class _Caption extends StatelessWidget {
  const _Caption({
    required this.title,
    required this.hint,
    required this.reveal,
  });

  final String title;
  final String hint;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: reveal,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(reveal),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                hint,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What went wrong, in a glass panel, with the ways forward: try again,
/// or go back to the delete screen.
class _FailurePanel extends StatelessWidget {
  const _FailurePanel({super.key, required this.onRetry, required this.onBack});

  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
              child: Icon(
                Icons.error_outline_rounded,
                size: 26,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            header: true,
            child: Text(
              t.wallet_delete_error_title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.wallet_delete_error_body,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(text: t.common_retry, onPressed: onRetry),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onBack,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: context.colors.textPrimary,
            ),
            child: Text(
              t.common_back,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
