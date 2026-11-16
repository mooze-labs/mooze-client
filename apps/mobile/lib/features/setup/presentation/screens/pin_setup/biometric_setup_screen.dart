import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import 'package:mooze_mobile/app/session/auth_prompt_controller.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/motion/route_entrance.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_hero.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Offers to turn on biometrics right after the PIN of a new wallet is
/// created. The screen before shows it only when the device has a
/// biometric enrolled.
///
/// Its art, [BiometricScene], is a seal with the biometric of the device,
/// in the words of the device: Face ID or Touch ID on iOS, biometrics on
/// Android. It follows the system prompt: the seal scans while the prompt
/// is up, shakes if it fails, and on success turns into a check, then into
/// the Mooze coin, which flies on into the opening of the wallet.
///
/// A prompt dismissed by the user leaves the screen as it was, so a slip
/// does not skip the choice. "No thanks" opens the wallet without
/// biometrics.
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key, this.capabilities});

  /// What the device has enrolled, from the screen before. When the route
  /// lost it, the screen reads it again.
  final BiometricCapabilities? capabilities;

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

enum _Phase { idle, scanning, saving, success, failed }

/// What went wrong, as the screen tells it.
enum _Problem { failed, locked, notSaved }

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen>
    with TickerProviderStateMixin, StageHaptics<BiometricSetupScreen> {
  /// The entrance of the seal, then its sway, until it rests.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: Motion.durationAmbient * 2,
  );
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: Motion.durationScan,
  );
  late final AnimationController _success = AnimationController(
    vsync: this,
    duration: Motion.durationBiometricSuccess,
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: Motion.durationEmphasis,
  );

  /// The question fades out after the peak, and the caption of success
  /// comes in, on the same timeline as the success.
  late final Animation<double> _questionOut = ReverseAnimation(
    CurvedAnimation(
      parent: _success,
      curve: const Interval(
        0.18,
        BiometricScene.revealAt,
        curve: Curves.easeIn,
      ),
    ),
  );
  late final Animation<double> _doneIn = CurvedAnimation(
    parent: _success,
    curve: const Interval(
      BiometricScene.revealAt,
      0.55,
      curve: Motion.curveEnter,
    ),
  );

  late BiometricKind _kind = widget.capabilities == null
      ? BiometricKind.fingerprint
      : BiometricKind.of(widget.capabilities!);
  _Phase _phase = _Phase.idle;
  _Problem? _problem;
  bool _started = false;
  bool _still = false;

  /// Whether the caption tells that biometrics are on.
  bool _done = false;

  /// Whether the caption has left, before the opening of the wallet.
  bool _leaving = false;

  @override
  Animation<double> get stageAnimation => _success;

  @override
  List<StageBeat> get stageBeats => const [
    (at: BiometricScene.peakAt, play: HapticFeedback.mediumImpact),
    (at: BiometricScene.edgeOnAt, play: HapticFeedback.lightImpact),
  ];

  bool get _busy =>
      _phase == _Phase.scanning ||
      _phase == _Phase.saving ||
      _phase == _Phase.success;

  @override
  void initState() {
    super.initState();
    _success.addListener(() {
      final done = _success.value >= BiometricScene.revealAt;
      if (done != _done) setState(() => _done = done);
    });
    if (widget.capabilities == null) _readCapabilities();
  }

  Future<void> _readCapabilities() async {
    final capabilities = await ref
        .read(biometricServiceProvider)
        .capabilities()
        .run();
    if (mounted) setState(() => _kind = BiometricKind.of(capabilities));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = Motion.isReduced(context);
    if (_started) return;
    _started = true;
    afterRouteEntrance(context, () {
      if (_still) {
        _ambient.value = 1;
      } else {
        _ambient.forward();
      }
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _scan.dispose();
    _sweep.dispose();
    _success.dispose();
    _shake.dispose();
    super.dispose();
  }

  /// The name of the biometric, as the device calls it.
  String _method(AppLocalizations t) {
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return t.biometric_method_generic;
    }
    return _kind == BiometricKind.face
        ? t.biometric_method_face_id
        : t.biometric_method_touch_id;
  }

  /// Runs from the button, which takes no tap while it is loading or the
  /// seal turns into the coin.
  Future<void> _enable() async {
    final t = AppLocalizations.of(context);
    final biometrics = ref.read(biometricServiceProvider);
    // Read before the await, so the flag clears even if the screen is gone
    // when the prompt returns.
    final authPrompt = ref.read(authPromptActiveProvider.notifier);
    setState(() {
      _phase = _Phase.scanning;
      _problem = null;
    });
    if (_still) {
      _scan.value = 1;
      // The beam rests across the middle of the seal.
      _sweep.value = 0.25;
    } else {
      _scan.forward();
      _sweep.repeat();
    }

    // Confirm a biometric works before persisting the preference. MUST be
    // biometric-only — otherwise a user could enable "biometric unlock" while
    // only proving they know the device PIN, leaving the preference flag in
    // an inconsistent state next session.
    //
    // The system prompt takes the app out of the foreground: `inactive` on
    // iOS, `paused` on Android. The flag tells the privacy shield and the
    // session lock that this is no real backgrounding, or the shield covers
    // the scene and the app locks when the prompt closes. `whenComplete`
    // clears it even if the prompt throws.
    authPrompt.begin();
    final result = await biometrics
        .unlockWithBiometric(reason: t.biometric_auth_reason)
        .run()
        .whenComplete(authPrompt.end);
    if (!mounted) return;
    await result.match(
      (error) async => _fail(switch (error.code) {
        auth_error.lockedOut ||
        auth_error.permanentlyLockedOut => _Problem.locked,
        _ => _Problem.failed,
      }),
      (authenticated) async {
        if (!authenticated) return _stopScanning(_Phase.idle);
        setState(() => _phase = _Phase.saving);
        final saved = await biometrics.setEnabled(true).run();
        if (!mounted) return;
        await saved.match((_) async => _fail(_Problem.notSaved), (_) async {
          // Propagate the new preference to any listening provider.
          ref.invalidate(isBiometricEnabledProvider);
          await _succeed();
        });
      },
    );
  }

  void _stopScanning(_Phase phase) {
    _sweep.stop();
    if (_still) {
      _scan.value = 0;
    } else {
      _scan.reverse();
    }
    setState(() => _phase = phase);
  }

  void _fail(_Problem problem) {
    _stopScanning(_Phase.failed);
    HapticFeedback.heavyImpact();
    if (!_still) _shake.forward(from: 0);
    setState(() => _problem = problem);
  }

  /// The seal turns into a check, then into the Mooze coin, which flies on
  /// into the opening of the wallet. Under reduced motion it shows its end
  /// at once.
  Future<void> _succeed() async {
    _stopScanning(_Phase.success);
    // The picture rests as the success plays.
    _ambient.stop();
    if (_still) {
      _success.value = 1;
      HapticFeedback.lightImpact();
    } else {
      await _success.forward();
    }
    if (!mounted) return;
    // The caption leaves first, so only the coin is on the stage when the
    // opening fades in around it.
    setState(() => _leaving = true);
    await Future<void>.delayed(Motion.of(context, Motion.durationExit));
    if (mounted) {
      context.go(
        '/setup/wallet-import-loading',
        extra: StageEntrance.coinInPlace,
      );
    }
  }

  void _skip() => context.go('/setup/wallet-import-loading');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final method = _method(t);
    final problem = _problem;

    return PinScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          AnimatedBuilder(
            animation: Listenable.merge([
              _ambient,
              _scan,
              _sweep,
              _success,
              _shake,
            ]),
            builder: (context, _) => BiometricScene(
              kind: _kind,
              motion: BiometricMotion(
                ambient: _ambient.value,
                scan: _scan.value,
                sweep: _sweep.value,
                success: _success.value,
                shake: _shake.value,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            key: const ValueKey('captions'),
            opacity: _leaving ? 0 : 1,
            duration: Motion.of(context, Motion.durationExit),
            curve: Motion.curveExit,
            // Sized by the taller caption, so nothing moves when it
            // changes.
            child: IndexedStack(
              index: _done ? 1 : 0,
              alignment: Alignment.topCenter,
              children: [
                _Reveal(
                  reveal: _questionOut,
                  child: PinHeader(
                    title: t.biometric_setup_title(method),
                    subtitle: t.biometric_setup_body(method),
                    textAlign: TextAlign.center,
                  ),
                ),
                _Reveal(
                  reveal: _doneIn,
                  child: PinHeader(
                    title: t.biometric_setup_done_title,
                    subtitle: t.biometric_setup_done_body(method),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // The room of the longest message is kept, so the page does not
          // jump when one shows.
          AnimatedOpacity(
            opacity: problem == null ? 0 : 1,
            duration: Motion.of(context, Motion.durationBase),
            curve: Motion.curveMove,
            child: IndexedStack(
              index: problem?.index ?? 0,
              children: [
                for (final message in [
                  t.biometric_setup_failed,
                  t.biometric_setup_locked,
                  t.biometric_save_error,
                ])
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.error,
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          const SizedBox(height: 32),
          // The actions leave as the seal turns into the coin.
          AnimatedOpacity(
            opacity: _phase == _Phase.success ? 0 : 1,
            duration: Motion.of(context, Motion.durationExit),
            curve: Motion.curveExit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  text: t.biometric_setup_button(method),
                  onPressed: _enable,
                  isEnabled: _phase != _Phase.success,
                  isLoading:
                      _phase == _Phase.scanning || _phase == _Phase.saving,
                ),
                const SizedBox(height: 4),
                PinTextAction(
                  label: t.common_no_thanks,
                  onPressed: _busy ? null : _skip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [child], shown as far as [reveal] goes: it fades and grows from 90%
/// into place.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.reveal, required this.child});

  final Animation<double> reveal;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: reveal,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1).animate(reveal),
      child: child,
    ),
  );
}
