import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/pin/confirm_pin.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:pinput/pinput.dart';

import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

class CreatePinScreen extends StatefulWidget {
  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final AuthenticationService authenticationService = AuthenticationService();
  final TextEditingController pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(title: "Criar PIN"),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Text(
              "Cadastre seu PIN:",
              style: TextStyle(
                fontSize: 20,
                fontFamily: "roboto",
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Pinput(
              keyboardType: TextInputType.number,
              length: 6,
              onCompleted: (pin) => print(pinController.text),
              controller: pinController,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontFamily: "roboto",
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "O PIN será utilizado para autorizar transações e acessar sua carteira.",
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: "roboto",
              ),
            ),
            Spacer(),
            PrimaryButton(
              text: "Continuar",
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ConfirmPinScreen(pin: pinController.text),
                    ),
                  ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
