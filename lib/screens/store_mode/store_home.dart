import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
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
    TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 16.0);
    TextStyle linkStyle = TextStyle(color: Colors.pinkAccent, fontSize: 16.0);

    final buttons = Column(
      children: [
        PrimaryButton(
          text: "Receber novo pagamento",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReceivePixStoreModeScreen()),
            );
          },
          icon: Icons.payment,
        ),
        SizedBox(height: 20),
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

    final body = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/mooze-logo.png', width: 200, height: 200),
          SizedBox(height: 50),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(children: [buttons]),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(padding: const EdgeInsets.all(16.0), child: body),
    );
  }
}
