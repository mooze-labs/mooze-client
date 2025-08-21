import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/utils/store_mode.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:pinput/pinput.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';

class VerifyPinScreen extends StatefulWidget {
  final Function() onPinConfirmed;
  bool forceAuth;
  bool isAppResuming;

  VerifyPinScreen({
    super.key,
    required this.onPinConfirmed,
    this.forceAuth = false,
    this.isAppResuming = false,
  });

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isLocked = true;
  bool _isPinValid = false;

  final LocalAuthentication auth = LocalAuthentication();

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
      setState(() {
        _isLocked = false;
      });
      widget.onPinConfirmed();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onContinuePressed() async {
    if (_isVerifying || _pinController.text.length != 6) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final auth = await _authService.authenticate(_pinController.text);

      if (auth && mounted) {
        setState(() => _isLocked = false);
        widget.onPinConfirmed();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN incorreto. Tente novamente.')),
        );
        _pinController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
        _pinController.clear();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _authWithBiometrics() async {
    try {
      final isAvailable =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometria ou senha do sistema não disponível.'),
          ),
        );
        return;
      }

      final didAuthenticate = await auth.authenticate(
        localizedReason:
            'Use sua biometria ou senha do dispositivo para redefinir o PIN',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        if (mounted) {
          context.push("/setup/pin/new");
        }
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao autenticar: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: MoozeAppBar(title: "Validar PIN"),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Validação de segurança'),
          leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: SafeArea(
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
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge,
                    text: 'Digite seu PIN para continuar com segurança.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                Pinput(
                  keyboardType: TextInputType.number,
                  length: 6,
                  obscureText: true,
                  controller: _pinController,
                  defaultPinTheme: PinThemes.focusedPinTheme,
                ),
                const SizedBox(height: 50),
                PrimaryButton(
                  text: "Continuar",
                  onPressed: _onContinuePressed,
                  isEnabled: _isPinValid && !_isVerifying,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Esqueceu seu PIN?',
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: _authWithBiometrics,
                  child: Text(
                    'Use sua senha do dispositivo',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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