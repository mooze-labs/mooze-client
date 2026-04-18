import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/utils/store_mode.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:pinput/pinput.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class VerifyPinScreen extends ConsumerStatefulWidget {
  final Function() onPinConfirmed;
  final bool forceAuth;
  final bool isAppResuming;
  final bool canGoBack;

  const VerifyPinScreen({
    super.key,
    required this.onPinConfirmed,
    this.forceAuth = false,
    this.isAppResuming = false,
    this.canGoBack = true,
  });

  @override
  ConsumerState<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends ConsumerState<VerifyPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isPinValid = false;

  // Biometric state — resolved once during _checkSession and then fixed for
  // the lifetime of this screen instance.
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
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
    final hasValidSession = await _authService.hasValidSession();
    final isPinSetup = await _authService.isPinSetup();
    final isStoreMode = await StoreModeHandler().isStoreMode();

    final noScreenshot = NoScreenshot.instance;
    await noScreenshot.screenshotOn();

    if ((isStoreMode && !widget.forceAuth) ||
        (hasValidSession && !widget.forceAuth) ||
        !isPinSetup) {
      widget.onPinConfirmed();
      return;
    }

    // PIN is required — also check biometric preference before showing the UI.
    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isAvailable().run();
    final isEnabled = await biometricService.isEnabled().run();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _biometricAvailable = isAvailable;
      _biometricEnabled = isEnabled;
    });

    // Auto-trigger biometric prompt if the user has opted in.
    if (isAvailable && isEnabled) {
      _authWithBiometrics();
    }
  }

  void _onContinuePressed() async {
    if (_isVerifying || _pinController.text.length != 6) return;

    setState(() {
      _isVerifying = true;
    });

    bool navigated = false;

    try {
      final isValid = await _authService.authenticate(_pinController.text);

      if (isValid) {
        navigated = true;
        await Future.delayed(const Duration(seconds: 1));
        widget.onPinConfirmed();
      } else if (mounted) {
        AppSnackBar.error(context, 'PIN incorreto. Tente novamente.');
        _pinController.clear();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro: ${e.toString()}');
        _pinController.clear();
      }
    } finally {
      if (!navigated && mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  /// Triggers the native biometric / device-credential prompt.
  ///
  /// Called automatically on screen load when biometric is enabled, and also
  /// manually when the user taps the "Usar biometria" button after dismissing
  /// the prompt.
  Future<void> _authWithBiometrics() async {
    if (_isBiometricLoading) return;

    setState(() => _isBiometricLoading = true);

    final biometricService = ref.read(biometricServiceProvider);

    final result = await biometricService
        .authenticate(reason: 'Use sua biometria para acessar sua carteira')
        .run();

    if (!mounted) return;

    result.fold(
      (error) => AppSnackBar.error(context, 'Erro ao autenticar: $error'),
      (authenticated) {
        if (authenticated) widget.onPinConfirmed();
        // If the user dismissed without authenticating the PIN form remains
        // visible — no action needed.
      },
    );

    if (mounted) setState(() => _isBiometricLoading = false);
  }

  /// Emergency fallback: lets users who forgot their PIN unlock using only
  /// device credentials (device PIN / pattern / password).
  ///
  /// Only shown when biometric authentication is NOT enabled, so there is no
  /// duplicate with the regular biometric flow.
  Future<void> _authWithDeviceCredential() async {
    final biometricService = ref.read(biometricServiceProvider);

    final isAvailable = await biometricService.isAvailable().run();
    if (!mounted) return;

    if (!isAvailable) {
      AppSnackBar.warning(
        context,
        'Biometria ou senha do sistema não disponível.',
      );
      return;
    }

    final result = await biometricService
        .authenticate(
          reason:
              'Use sua biometria ou senha do dispositivo para redefinir o PIN',
        )
        .run();

    if (!mounted) return;

    result.fold(
      (error) => AppSnackBar.error(context, 'Erro ao autenticar: $error'),
      (authenticated) {
        if (authenticated) widget.onPinConfirmed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Validar PIN')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canGoBack = widget.canGoBack;

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validação de segurança'),
          leading:
              canGoBack
                  ? IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  )
                  : null,
          automaticallyImplyLeading: canGoBack,
        ),
        body: PlatformSafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineSmall,
                    children: [
                      const TextSpan(text: 'Validar '),
                      TextSpan(
                        text: 'PIN',
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
                    text: 'Digite seu PIN para continuar com segurança.',
                  ),
                ),
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
                  text: 'Continuar',
                  onPressed: _onContinuePressed,
                  isEnabled: _isPinValid && !_isVerifying,
                  isLoading: _isVerifying,
                ),
                const SizedBox(height: 20),

                // ── Biometric section ──────────────────────────────────────
                if (_biometricEnabled && _biometricAvailable) ...[
                  // Biometric is the user's preferred method — show a
                  // prominent button that re-triggers the prompt.
                  TextButton.icon(
                    onPressed: _isBiometricLoading ? null : _authWithBiometrics,
                    icon:
                        _isBiometricLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.fingerprint),
                    label: const Text('Usar biometria'),
                  ),
                ] else ...[
                  // Biometric not enabled — show an emergency device-credential
                  // fallback for users who forgot their PIN.
                  const Text('Esqueceu seu PIN?'),
                  TextButton(
                    onPressed: _authWithDeviceCredential,
                    child: Text(
                      'Use a senha do dispositivo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
