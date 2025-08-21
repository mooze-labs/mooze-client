import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/key_management/providers.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';
import 'package:pinput/pinput.dart';

import '../../../di/providers/pin_setup_repository_provider.dart';

class ConfirmPinSetupScreen extends ConsumerStatefulWidget {
  const ConfirmPinSetupScreen({super.key, required this.pin});
  final String pin;

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
      (_) {
        ref.invalidate(mnemonicProvider);
        context.go("/home");
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
                defaultPinTheme: PinThemes.focusedPinTheme,
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
