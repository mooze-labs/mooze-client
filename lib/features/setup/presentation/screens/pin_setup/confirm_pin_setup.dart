import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../domain/providers/pin_setup_repository_provider.dart';

class ConfirmPinSetupScreen extends ConsumerStatefulWidget {
  const ConfirmPinSetupScreen({super.key, required this.pin});

  final String pin;

  @override
  ConsumerState<ConfirmPinSetupScreen> createState() =>
      _ConfirmPinSetupScreenState();
}

class _ConfirmPinSetupScreenState extends ConsumerState<ConfirmPinSetupScreen> {
  final TextEditingController pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final pinSetupRepository = ref.read(pinSetupRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text("Confirme seu PIN")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Text(
              "Confirme seu PIN",
              style: TextStyle(fontSize: 20, fontFamily: "Inter"),
            ),
            Spacer(),
            Pinput(
              keyboardType: TextInputType.number,
              length: 6,
              obscureText: true,
              controller: pinController,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: TextStyle(
                  fontSize: 20,
                  fontFamily: "Inter",
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text != widget.pin) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("PINs não coincidem")));
                } else {
                  final result =
                      await pinSetupRepository
                          .createPin(pinController.text)
                          .run();

                  result.match(
                    (failure) => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(failure.toString()))),
                    (_) => context.go("/splash"),
                  );
                }
              },
              child: Text(
                "Confirmar",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "Inter",
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
