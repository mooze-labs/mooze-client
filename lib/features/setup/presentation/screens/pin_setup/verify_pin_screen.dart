import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/session/auth_prompt_controller.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
import 'package:mooze_mobile/utils/store_mode.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:pinput/pinput.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';
import 'package:mooze_mobile/shared/widgets.dart';

/// What kind of UI is currently being shown. Splitting these out — instead of
/// conditionally hiding pieces of a single scaffold — prevents the PIN Pinput
/// from building (and flashing) while the native biometric prompt is up.
enum _AuthMode {
  /// Initial state: deciding which authentication path to take.
  loading,

  /// Native biometric prompt is up (or about to be). UI is intentionally
  /// minimal so nothing flickers behind the system dialog.
  biometric,

  /// Biometric is unavailable, declined, or the user chose PIN entry.
  pin,
}

class VerifyPinScreen extends ConsumerStatefulWidget {
  final Function() onPinConfirmed;
  final bool forceAuth;
  final bool isAppResuming;
  final bool canGoBack;

  /// Start directly on the PIN keypad and do not auto-trigger biometrics. Used
  /// when the user chose "Use PIN" from the lock overlay's biometric step;
  /// re-prompting biometrics here would undo that choice. The in-screen "use
  /// biometrics" button still works.
  final bool startInPinMode;

  const VerifyPinScreen({
    super.key,
    required this.onPinConfirmed,
    this.forceAuth = false,
    this.isAppResuming = false,
    this.canGoBack = true,
    this.startInPinMode = false,
  });

  @override
  ConsumerState<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends ConsumerState<VerifyPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();

  _AuthMode _mode = _AuthMode.loading;
  bool _isVerifying = false;
  bool _isPinValid = false;

  // Resolved once during _checkSession, then fixed for this screen instance.
  BiometricCapabilities _capabilities = BiometricCapabilities.none;
  bool _biometricEnabled = false;
  bool _isBiometricLoading = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() {
      setState(() {
        _isPinValid = _pinController.text.length == 6;
      });
    });
    _checkSession();
  }

  Future<void> _checkSession() async {
    BootTracer.mark('pin.check_session.begin');
    final hasValidSession = await _authService.hasValidSession();
    final isPinSetup = await _authService.isPinSetup();
    final isStoreMode = await StoreModeHandler().isStoreMode();
    BootTracer.mark('pin.check_session.done', {
      'has_session': hasValidSession,
      'pin_setup': isPinSetup,
      'store_mode': isStoreMode,
    });

    final noScreenshot = NoScreenshot.instance;
    await noScreenshot.screenshotOn();

    if ((isStoreMode && !widget.forceAuth) ||
        (hasValidSession && !widget.forceAuth) ||
        !isPinSetup) {
      BootTracer.mark('pin.confirmed.session_short_circuit');
      widget.onPinConfirmed();
      return;
    }

    // Pick the auth mode before any UI is shown so we never build the PIN form
    // just to immediately hide it behind a biometric prompt.
    final biometricService = ref.read(biometricServiceProvider);
    final capabilities = await biometricService.capabilities().run();
    final isEnabled = await biometricService.isEnabled().run();

    if (!mounted) return;

    // Auto-trigger biometrics only when the user opted in and a biometric is
    // enrolled. If the preference is on but biometrics were removed, fall back
    // to PIN — never to the device passcode.
    final shouldUseBiometric =
        isEnabled && capabilities.hasBiometrics && !widget.startInPinMode;

    setState(() {
      _capabilities = capabilities;
      _biometricEnabled = isEnabled;
      _mode = shouldUseBiometric ? _AuthMode.biometric : _AuthMode.pin;
    });

    if (shouldUseBiometric) {
      _authWithBiometrics();
    }
  }

  void _onContinuePressed() async {
    if (_isVerifying || _pinController.text.length != 6) return;

    setState(() {
      _isVerifying = true;
    });

    final t = AppLocalizations.of(context);

    try {
      final isValid = await _authService.authenticate(_pinController.text);

      if (isValid) {
        BootTracer.mark('pin.authenticated.manual');
        await Future.delayed(const Duration(seconds: 1));
        BootTracer.mark('pin.confirmed.manual');
        widget.onPinConfirmed();
      } else if (mounted) {
        AppSnackBar.error(context, t.pin_incorrect);
        _pinController.clear();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, t.error_generic(e.toString()));
        _pinController.clear();
      }
    } finally {
      // Always reset the spinner. Keeping it up across the route transition to
      // /home reads as a UI freeze because the home screen's first build does
      // enough synchronous work to stall it; clearing it lets the transition
      // handle visual continuity.
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  /// Triggers the native biometric prompt. On failure or cancel we stay on the
  /// biometric view — its inline PIN input lets the user finish without a mode
  /// switch.
  Future<void> _authWithBiometrics() async {
    if (_isBiometricLoading) return;

    setState(() => _isBiometricLoading = true);

    final t = AppLocalizations.of(context);
    final biometricService = ref.read(biometricServiceProvider);
    // Captured before the await so it can be cleared even if this widget is
    // disposed by the time the prompt resolves.
    final authPrompt = ref.read(authPromptActiveProvider.notifier);

    // `whenComplete` clears the flag even if the prompt throws — a stuck `true`
    // would suppress the privacy shield forever.
    authPrompt.begin();
    final result = await biometricService
        .unlockWithBiometric(reason: t.pin_biometric_access_reason)
        .run()
        .whenComplete(authPrompt.end);

    if (!mounted) return;

    result.fold(
      (error) {
        AppSnackBar.error(context, t.biometric_auth_error(error.message));
        setState(() => _isBiometricLoading = false);
      },
      (authenticated) {
        if (authenticated) {
          BootTracer.mark('pin.confirmed.biometric');
          widget.onPinConfirmed();
          return;
        }
        // User dismissed the prompt — stay put, the inline PIN input is there.
        setState(() => _isBiometricLoading = false);
      },
    );
  }

  /// Emergency fallback: lets users who forgot their PIN unlock using only
  /// device credentials. Only shown when biometric auth is not enabled.
  Future<void> _authWithDeviceCredential() async {
    final t = AppLocalizations.of(context);
    final biometricService = ref.read(biometricServiceProvider);
    final authPrompt = ref.read(authPromptActiveProvider.notifier);

    if (!_capabilities.hasAnyAuth) {
      AppSnackBar.warning(context, t.pin_biometric_unavailable);
      return;
    }

    // Routes through the native CredentialAuthBridge on Android so the
    // BIOMETRIC_WEAK | DEVICE_CREDENTIAL mask is used (the only combination
    // that works on API 28-29 and survives Xiaomi/MIUI's replacement prompt).
    // Falls through to KeyguardManager.createConfirmDeviceCredentialIntent if
    // the prompt refuses to launch.
    authPrompt.begin();
    final result = await biometricService
        .unlockWithDeviceCredential(
          reason: t.pin_reset_biometric_reason,
          title: t.pin_reset_biometric_reason,
        )
        .run()
        .whenComplete(authPrompt.end);

    if (!mounted) return;

    result.fold(
      (error) =>
          AppSnackBar.error(context, t.biometric_auth_error(error.message)),
      (authenticated) {
        if (authenticated) {
          BootTracer.mark('pin.confirmed.device_credential');
          widget.onPinConfirmed();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final canGoBack = widget.canGoBack;

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_mode == _AuthMode.pin
              ? t.pin_validate_security
              : t.pin_validate_title),
          leading: canGoBack
              ? IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                )
              : null,
          automaticallyImplyLeading: canGoBack,
        ),
        body: PlatformSafeArea(
          child: switch (_mode) {
            _AuthMode.loading => const Center(
                child: CircularProgressIndicator(),
              ),
            _AuthMode.biometric => _buildBiometricView(context, t),
            _AuthMode.pin => _buildPinView(context, t),
          },
        ),
      ),
    );
  }

  /// Lightweight splash shown while the native biometric prompt is up.
  /// Deliberately minimal so nothing flickers when the system dialog dismisses.
  Widget _buildBiometricView(BuildContext context, AppLocalizations t) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.fingerprint,
              size: 72,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            t.pin_biometric_access_reason,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: t.pin_use_biometric,
            onPressed: () => _authWithBiometrics(),
            isEnabled: !_isBiometricLoading,
            isLoading: _isBiometricLoading,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _mode = _AuthMode.pin),
            child: Text(
              t.pin_use_pin,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinView(BuildContext context, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall,
              children: [
                TextSpan(text: t.pin_validate_action),
                TextSpan(
                  text: t.pin_word,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              text: t.pin_validate_body,
            ),
          ),
          const SizedBox(height: 50),
          const LinearProgressIndicator(),
          const SizedBox(height: 50),
          Pinput(
            keyboardType: TextInputType.number,
            length: 6,
            obscureText: true,
            controller: _pinController,
            defaultPinTheme: PinThemes.focusedThemeOf(context),
          ),
          const SizedBox(height: 50),
          PrimaryButton(
            text: t.common_continue,
            onPressed: _onContinuePressed,
            isEnabled: _isPinValid && !_isVerifying,
            isLoading: _isVerifying,
          ),
          const SizedBox(height: 20),

          if (_biometricEnabled && _capabilities.hasBiometrics) ...[
            // Re-trigger the prompt, switching back to the biometric splash so
            // the PIN form doesn't sit visible behind the native dialog.
            TextButton.icon(
              onPressed: _isBiometricLoading
                  ? null
                  : () {
                      setState(() => _mode = _AuthMode.biometric);
                      _authWithBiometrics();
                    },
              icon: _isBiometricLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: Text(t.pin_use_biometric),
            ),
          ] else ...[
            // Emergency device-credential fallback for users who forgot their PIN.
            Text(t.pin_forgot),
            TextButton(
              onPressed: _authWithDeviceCredential,
              child: Text(
                t.pin_use_device_password,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
