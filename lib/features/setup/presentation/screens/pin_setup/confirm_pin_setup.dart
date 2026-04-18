import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/key_management/providers/has_pin_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';
import 'package:pinput/pinput.dart';

import '../../../di/providers/pin_setup_repository_provider.dart';

class ConfirmPinSetupScreen extends ConsumerStatefulWidget {
  const ConfirmPinSetupScreen({
    super.key,
    required this.pin,
    this.isChangingPin = false,
  });
  final String pin;
  final bool isChangingPin;

  @override
  ConsumerState<ConfirmPinSetupScreen> createState() =>
      _ConfirmPinSetupScreenState();
}

class _ConfirmPinSetupScreenState extends ConsumerState<ConfirmPinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isPinValid = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() {
      setState(() {
        isPinValid = _pinController.text.length == 6;
      });
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onConfirmPressed() async {
    final inputPin = _pinController.text;

    if (inputPin != widget.pin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PINs não coincidem")));
      return;
    }

    final pinSetupRepository = ref.read(pinSetupRepositoryProvider);
    final result = await pinSetupRepository.createPin(inputPin).run();

    result.match(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.toString()))),
      (_) async {
        // Invalidate hasPinProvider after PIN creation
        ref.invalidate(hasPinProvider);

        // Always clear the session after a PIN save so the next app open
        // requires the new PIN — whether this is initial setup or a change.
        // Without this, the old session allows bypassing PIN entry entirely.
        await AuthenticationService().invalidateSession();

        if (!mounted) return;

        if (widget.isChangingPin) {
          int count = 0;
          Navigator.of(context).popUntil((route) {
            return count++ == 3;
          });
        } else {
          // For new wallet setup, offer biometric opt-in if the device
          // supports it. Otherwise go straight to the loading screen.
          final biometricService = ref.read(biometricServiceProvider);
          final isAvailable = await biometricService.isAvailable().run();

          if (!mounted) return;

          if (isAvailable) {
            context.go('/setup/biometric');
          } else {
            context.go('/setup/wallet-import-loading');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmar PIN'),
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
                    const TextSpan(text: 'Confirme seu '),
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
                  children: [
                    const TextSpan(text: 'Digite novamente o '),
                    TextSpan(
                      text: 'PIN ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: 'que você acabou de criar.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              Pinput(
                keyboardType: TextInputType.number,
                length: 6,
                obscureText: true,
                controller: _pinController,
                focusNode: _focusNode,
                defaultPinTheme: PinThemes.focusedThemeOf(context),
              ),

              const SizedBox(height: 50),

              PrimaryButton(
                text: 'Confirmar',
                onPressed: _onConfirmPressed,
                isEnabled: isPinValid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
