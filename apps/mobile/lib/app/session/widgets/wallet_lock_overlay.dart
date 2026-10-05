import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/verify_pin_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../auth_prompt_controller.dart';
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
class WalletLockOverlay extends StatelessWidget {
  /// Whether any opaque cover is shown (privacy shield visible OR session
  /// locked).
  final bool showCover;

  /// Whether the locked authentication flow is shown (session locked).
  final bool showAuthentication;

  /// Invoked on successful authentication.
  final VoidCallback onAuthenticated;

  const WalletLockOverlay({
    super.key,
    required this.showCover,
    required this.showAuthentication,
    required this.onAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !showCover,
      child: TickerMode(
        enabled: showCover,
        child: showAuthentication
            ? _LockedView(onAuthenticated: onAuthenticated)
            : const PrivacyShieldOverlay(),
      ),
    );
  }
}

/// The locked authentication flow shown on resume. Starts as the branded
/// [PrivacyShieldOverlay] and auto-attempts biometrics when enabled. If
/// biometrics are unavailable, disabled, or the user taps "Use PIN", it
/// switches to the same [VerifyPinScreen] used on cold start (`startInPinMode`
/// so it doesn't immediately re-prompt biometrics).
class _LockedView extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;

  const _LockedView({required this.onAuthenticated});

  @override
  ConsumerState<_LockedView> createState() => _LockedViewState();
}

class _LockedViewState extends ConsumerState<_LockedView> {
  /// Once true, render the PIN keypad instead of the biometric shield.
  bool _showPin = false;

  /// Whether the biometric availability probe has finished. Until then the
  /// shield shows pure branding (no buttons).
  bool _initialized = false;
  bool _biometricAvailable = false;
  bool _biometricLoading = false;

  @override
  void initState() {
    super.initState();
    // Probe after first frame so the branded shield is already on screen (and
    // localizations are available) before we prompt anything.
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
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
    if (_biometricLoading) return;

    final t = AppLocalizations.of(context);
    final biometricService = ref.read(biometricServiceProvider);
    final authPrompt = ref.read(authPromptActiveProvider.notifier);

    setState(() => _biometricLoading = true);

    // The prompt fires `inactive`; the flag tells the privacy shield not to
    // treat that as a real backgrounding. `whenComplete` guarantees it clears.
    authPrompt.begin();
    final result = await biometricService
        .unlockWithBiometric(reason: t.pin_biometric_access_reason)
        .run()
        .whenComplete(authPrompt.end);

    if (!mounted) return;
    setState(() => _biometricLoading = false);

    result.fold(
      (error) =>
          AppSnackBar.error(context, t.biometric_auth_error(error.message)),
      (authenticated) {
        // On dismissal, stay on the shield — the affordances are right there.
        if (authenticated) widget.onAuthenticated();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showPin) {
      // Wrapped in its own [Overlay]: this layer lives above the Navigator, so
      // there is no ambient Overlay, and the PIN field's EditableText needs an
      // Overlay ancestor for text selection.
      return SizedBox.expand(
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              maintainState: true,
              builder: (context) => VerifyPinScreen(
                forceAuth: true,
                canGoBack: false,
                isAppResuming: true,
                startInPinMode: true,
                onPinConfirmed: widget.onAuthenticated,
              ),
            ),
          ],
        ),
      );
    }

    return PrivacyShieldOverlay(
      onUseBiometric:
          (_initialized && _biometricAvailable) ? _attemptBiometric : null,
      onUsePin: _initialized ? () => setState(() => _showPin = true) : null,
      isBiometricLoading: _biometricLoading,
    );
  }
}
