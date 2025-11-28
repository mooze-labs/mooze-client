import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:pinput/pinput.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';

class PhoneVerificationCodeScreen extends StatefulWidget {
  final Function() onPinConfirmed;
  final bool forceAuth;
  final bool isAppResuming;

  const PhoneVerificationCodeScreen({
    super.key,
    required this.onPinConfirmed,
    this.forceAuth = false,
    this.isAppResuming = false,
  });

  @override
  State<PhoneVerificationCodeScreen> createState() =>
      _PhoneVerificationCodeScreenState();
}

class _PhoneVerificationCodeScreenState
    extends State<PhoneVerificationCodeScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinValid = false;
  bool _isResending = false;

  final LocalAuthentication auth = LocalAuthentication();

  int _secondsRemaining = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _pinController.addListener(() {
      setState(() {
        _isPinValid = _pinController.text.length == 6;
      });
    });

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = 30;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _onResendCode() async {
    setState(() {
      _isResending = true;
    });

    _pinController.clear();

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isResending = false;
    });

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Confirmar Código'),
          leading: Icon(Icons.arrow_back_ios_new_rounded),
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
                      const TextSpan(text: 'Digite o '),
                      TextSpan(
                        text: 'código recebido',
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
                    text:
                        'Enviamos um código de 6 dígitos para o número +55 (54) 998446-2341 via Telegram.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                Pinput(
                  keyboardType: TextInputType.number,
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: PinThemes.focusedPinTheme,
                ),
                const SizedBox(height: 50),
                PrimaryButton(
                  text: "Verificar",
                  onPressed: _isPinValid ? widget.onPinConfirmed : null,
                  isEnabled: _isPinValid,
                ),
                const SizedBox(height: 20),
                if (_secondsRemaining > 0)
                  Text(
                    'Reenviar em 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  )
                else
                  _isResending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : TextButton(
                        onPressed: _onResendCode,
                        child: Text(
                          'Reenviar código',
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
