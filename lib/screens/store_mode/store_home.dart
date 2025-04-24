import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/screens/receive_pix/receive_pix.dart';
import 'package:mooze_mobile/screens/store_mode/receive_pix_store_mode.dart';
import 'package:mooze_mobile/screens/wallet/wallet.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/utils/store_mode.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class StoreHomeScreen extends StatefulWidget {
  StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => StoreHomeState();
}

class StoreHomeState extends State<StoreHomeScreen> {
  late final StoreModeHandler _storeModeHandler = StoreModeHandler();

  Future<void> _initStoreMode() async {
    final authService = AuthenticationService();
    await _storeModeHandler.setStoreMode(true);
    await authService.invalidateSession();
  }

  @override
  void initState() {
    super.initState();
    _initStoreMode();
  }

  void _onReturnWalletTap(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WalletScreen()),
    );

    await _storeModeHandler.setStoreMode(false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final TextStyle defaultStyle = TextStyle(
      color: Colors.white,
      fontSize: 16.0,
    );
    final TextStyle linkStyle = TextStyle(
      color: Colors.pinkAccent,
      fontSize: 16.0,
    );

    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: "Receber novo pagamento",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReceivePixScreen()),
            );
          },
          icon: Icons.payment,
        ),
        SizedBox(height: size.height * 0.02), // Responsive spacing
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Quer acessar a carteira? ", style: defaultStyle),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => VerifyPinScreen(
                          onPinConfirmed: () async {
                            _onReturnWalletTap(context);
                          },
                          forceAuth: true,
                        ),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Clique aqui.", style: linkStyle),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: linkStyle.color),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final body = SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.03,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.1), // Top spacing
              Image.asset(
                'assets/images/mooze-logo.png',
                width: size.width * 0.5, // Responsive width
                height: size.width * 0.5, // Keep aspect ratio square
                fit: BoxFit.contain,
              ),
              SizedBox(height: size.height * 0.05),
              SizedBox(width: size.width * 0.9, child: buttons),
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: body,
      ),
    );
  }
}
