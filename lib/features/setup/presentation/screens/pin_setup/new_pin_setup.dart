import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import 'package:go_router/go_router.dart';

class NewPinSetupScreen extends ConsumerStatefulWidget {
  const NewPinSetupScreen({super.key});

  @override
  ConsumerState<NewPinSetupScreen> createState() => _NewPinSetupScreenState();
}

class _NewPinSetupScreenState extends ConsumerState<NewPinSetupScreen> {
  final TextEditingController pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crie seu PIN")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Text(
              "Cadastre seu PIN",
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
            Text(
              "O PIN será utilizado para autorizar transações e acessar sua carteira.",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Inter",
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed:
                  () => context.go(
                    '/setup/pin/confirm',
                    extra: pinController.text,
                  ),
              child: Text(
                "Continuar",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "Inter",
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
