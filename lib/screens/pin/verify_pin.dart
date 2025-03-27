import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/pin/confirm_pin.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:pinput/pinput.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

/// Screen to verify PIN for sensitive operations.
class VerifyPinScreen extends StatefulWidget {
  final Function() onPinConfirmed;
  VerifyPinScreen({required this.onPinConfirmed});
  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final TextEditingController pinController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasValidSession = await _authService.hasValidSession();
    if (hasValidSession) {
      widget.onPinConfirmed();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: MoozeAppBar(title: "Validar PIN"),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: MoozeAppBar(title: "Validar PIN"),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Text(
                "Digite seu PIN:",
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
              Spacer(),
              PrimaryButton(
                text: "Continuar",
                onPressed: () async {
                  final auth = await _authService.authenticate(
                    pinController.text,
                  );
                  if (auth) {
                    widget.onPinConfirmed();
                  }
                },
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
