import 'package:flutter/material.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';
import 'package:mooze_mobile/utils/store_mode.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:pinput/pinput.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

/// Screen to verify PIN for sensitive operations.
class VerifyPinScreen extends StatefulWidget {
  final Function() onPinConfirmed;
  bool forceAuth;
  bool isAppResuming;

  VerifyPinScreen({
    required this.onPinConfirmed,
    this.forceAuth = false,
    this.isAppResuming = false,
  });
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
    final isPinSetup = await _authService.isPinSetup();
    final isStoreMode = await StoreModeHandler().isStoreMode();

    final noScreenshot = NoScreenshot.instance;
    await noScreenshot.screenshotOn();

    // Skip verification if:
    // 1. We're in store mode, or
    // 2. User authenticated less than a minute ago (and we're not forcing auth), or
    // 3. No PIN has been set up
    if ((isStoreMode ||
        (hasValidSession && !widget.forceAuth) ||
        !isPinSetup)) {
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
        appBar: AppBar(
          title: Text(
            "Validar PIN",
            style: TextStyle(
              fontFamily: "roboto",
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: !widget.isAppResuming,
        ),
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
                obscureText: true,
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
