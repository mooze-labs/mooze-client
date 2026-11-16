import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/verify_pin_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_seal.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../auth_prompt_controller.dart';
import '../privacy_shield_controller.dart';
import '../privacy_shield_state.dart';
import 'privacy_shield_overlay.dart';

/// The single global overlay that covers the app for both the privacy shield
/// and the session lock. It is not a route — it lives inside
/// `MaterialApp.router`'s `builder`, above the `Navigator`, so the screen
/// underneath stays mounted and untouched.
///
/// Layers (all opaque):
///   - [showCover] false → fully [Offstage]: not painted, not hit-tested; the
///     subtree stays mounted so raising the cover is instantaneous.
///   - [showCover] true, [showAuthentication] false → the [PrivacyShieldOverlay]
///     as a cosmetic app-switcher / transient cover.
///   - [showCover] true, [showAuthentication] true → the locked flow
///     ([_LockedView]): the same branded shield, now the biometric step.
///
/// With [sealKind], both show the biometric seal: at rest on the shield, and
/// on the locked flow it scans while the system prompt is up.
///
/// The session unlocks the moment the user is in. The locked flow then stays
/// a little longer, on its own: the seal shows a check when the biometric let
/// the user in, and the cover fades away over the wallet. The unlocked
/// session counts a trip out of the app in that time as any other, and a
/// lock that comes of it brings a fresh locked flow, which prompts again.
///
/// When the cover rises, the focus leaves the screen below, which closes the
/// keyboard: see [_WalletLockOverlayState.didUpdateWidget].
class WalletLockOverlay extends StatefulWidget {
  /// Whether any opaque cover is shown (privacy shield visible OR session
  /// locked).
  final bool showCover;

  /// Whether the locked authentication flow is shown (session locked).
  final bool showAuthentication;

  /// Invoked on successful authentication, at once. The cover leaves after.
  final VoidCallback onAuthenticated;

  /// The biometric on the seal of the cover, when the user unlocks with one.
  /// Without it, the cover shows the vault of the onboarding.
  final BiometricKind? sealKind;

  const WalletLockOverlay({
    super.key,
    required this.showCover,
    required this.showAuthentication,
    required this.onAuthenticated,
    this.sealKind,
  });

  @override
  State<WalletLockOverlay> createState() => _WalletLockOverlayState();
}

class _WalletLockOverlayState extends State<WalletLockOverlay> {
  /// Whether the locked flow is on its way out, over an unlocked session.
  bool _leaving = false;

  /// Counts the locks, so each one gets a fresh locked flow.
  int _lock = 0;

  void _unlocked() {
    setState(() => _leaving = true);
    widget.onAuthenticated();
  }

  void _gone() => setState(() => _leaving = false);

  @override
  void didUpdateWidget(WalletLockOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Locked again while the last locked flow was on its way out.
    if (widget.showAuthentication && !oldWidget.showAuthentication) {
      _leaving = false;
      _lock++;
    }
    // The keyboard is a system window above the app, so the cover cannot
    // paint over it. While a field of the screen below keeps the focus, the
    // keyboard stays open over the cover and opens again when the app
    // returns. Taking the focus away closes it. The user taps the field
    // again after the unlock.
    if (widget.showCover && !oldWidget.showCover) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.showCover || _leaving;
    return Offstage(
      offstage: !cover,
      child: TickerMode(
        enabled: cover,
        child: widget.showAuthentication || _leaving
            ? _LockedView(
                key: ValueKey(_lock),
                onAuthenticated: _unlocked,
                onGone: _gone,
                sealKind: widget.sealKind,
              )
            : PrivacyShieldOverlay(sealKind: widget.sealKind),
      ),
    );
  }
}

/// The locked authentication flow shown on resume. Starts as the branded
/// [PrivacyShieldOverlay] and auto-attempts biometrics when enabled. If
/// biometrics are unavailable, disabled, or the user taps "Use PIN", it
/// switches to the same [VerifyPinScreen] used on cold start (`startInPinMode`
/// so it doesn't immediately re-prompt biometrics).
///
/// Once the user is in, it calls [onAuthenticated] at once, then fades away
/// over the wallet, and calls [onGone]. While the privacy shield is up, the
/// cover stays opaque, so a fade never shows in the app switcher.
class _LockedView extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback onGone;
  final BiometricKind? sealKind;

  const _LockedView({
    super.key,
    required this.onAuthenticated,
    required this.onGone,
    this.sealKind,
  });

  @override
  ConsumerState<_LockedView> createState() => _LockedViewState();
}

class _LockedViewState extends ConsumerState<_LockedView>
    with TickerProviderStateMixin, StageHaptics<_LockedView> {
  /// The seal is already on the cover: the shield showed it at rest.
  late final BiometricSeal _seal = BiometricSeal(
    vsync: this,
    finale: BiometricFinale.check,
    entered: true,
  );

  /// The fade of the cover away, once the user is in.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: Motion.durationExit,
  );
  late final Animation<double> _coverOpacity = ReverseAnimation(
    CurvedAnimation(parent: _exit, curve: Motion.curveExit),
  );

  /// Once true, render the PIN keypad instead of the biometric shield.
  bool _showPin = false;

  /// Whether the biometric availability probe has finished. Until then the
  /// shield shows pure branding (no buttons).
  bool _initialized = false;
  bool _biometricAvailable = false;
  bool _biometricLoading = false;

  /// Whether the user is in: the cover is on its way out.
  bool _unlocking = false;

  @override
  Animation<double> get stageAnimation => _seal.success;

  @override
  List<StageBeat> get stageBeats => _seal.beats;

  @override
  void initState() {
    super.initState();
    // Probe after first frame so the branded shield is already on screen (and
    // localizations are available) before we prompt anything.
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seal.still = Motion.isReduced(context);
  }

  @override
  void dispose() {
    _seal.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final biometricService = ref.read(biometricServiceProvider);
    final isEnabled = await biometricService.isEnabled().run();
    final capabilities = await biometricService.capabilities().run();
    if (!mounted) return;

    final available = isEnabled && capabilities.hasBiometrics;
    setState(() {
      _initialized = true;
      _biometricAvailable = available;
    });

    if (available) {
      _attemptBiometric();
    } else {
      setState(() => _showPin = true);
    }
  }

  Future<void> _attemptBiometric() async {
    if (_biometricLoading || _unlocking) return;

    final t = AppLocalizations.of(context);
    final biometricService = ref.read(biometricServiceProvider);
    final authPrompt = ref.read(authPromptActiveProvider.notifier);

    setState(() => _biometricLoading = true);
    _seal.scan();

    // The prompt fires `inactive`; the flag tells the privacy shield not to
    // treat that as a real backgrounding. `whenComplete` guarantees it clears.
    authPrompt.begin();
    final result = await biometricService
        .unlockWithBiometric(reason: t.pin_biometric_access_reason)
        .run()
        .whenComplete(authPrompt.end);

    if (!mounted) return;

    result.fold(
      (error) {
        _seal.fail();
        setState(() => _biometricLoading = false);
        AppSnackBar.error(context, t.biometric_auth_error(error.message));
      },
      (authenticated) {
        if (authenticated) {
          _unlock(check: true);
          return;
        }
        // On dismissal, stay on the shield — the affordances are right there.
        _seal.stopScanning();
        setState(() => _biometricLoading = false);
      },
    );
  }

  /// The user is in: the session unlocks at once. The seal shows a check
  /// when the biometric let the user in, and the cover fades away over the
  /// wallet while its shockwave still spreads. Under reduced motion it goes
  /// at once.
  Future<void> _unlock({bool check = false}) async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    widget.onAuthenticated();
    if (check) await _seal.succeed();
    if (!mounted) return;
    if (Motion.isReduced(context)) {
      _exit.value = 1;
    } else {
      await _exit.forward();
    }
    if (mounted) widget.onGone();
  }

  @override
  Widget build(BuildContext context) {
    final shielded =
        ref.watch(privacyShieldControllerProvider) ==
        PrivacyShieldState.visible;
    final ready = _initialized && !_unlocking;
    // The shield stays painted, fully opaque, under the PIN layer while the
    // layer fades in. A cross-fade of the two would let the wallet behind
    // the overlay show through halfway. Once the PIN layer is up, the
    // shield takes no taps and is hidden from screen readers.
    final cover = Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: _showPin,
          child: ExcludeSemantics(
            excluding: _showPin,
            child: PrivacyShieldOverlay(
              onUseBiometric: (ready && _biometricAvailable)
                  ? _attemptBiometric
                  : null,
              onUsePin: ready ? () => setState(() => _showPin = true) : null,
              isBiometricLoading: _biometricLoading,
              sealKind: widget.sealKind,
              seal: _seal,
            ),
          ),
        ),
        if (_showPin)
          // Wrapped in its own [Overlay]: this layer lives above the
          // Navigator, so there is no ambient Overlay, and the PIN screen
          // needs an Overlay ancestor for tooltips and text selection.
          _FadeIn(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  maintainState: true,
                  builder: (context) => VerifyPinScreen(
                    forceAuth: true,
                    canGoBack: false,
                    isAppResuming: true,
                    startInPinMode: true,
                    onPinConfirmed: _unlock,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return FadeTransition(
      // An app switcher snapshot taken as the cover leaves shows it whole.
      opacity: shielded ? kAlwaysCompleteAnimation : _coverOpacity,
      child: cover,
    );
  }
}

/// Fades [child] in once, over [Motion.durationSlow] with
/// [Motion.curveEnter], the same as the PIN page after the splash. With
/// reduced motion it appears at once.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
