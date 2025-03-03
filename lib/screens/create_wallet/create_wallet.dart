import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/create_wallet/widgets/mnemonic_display.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class CreateWalletScreen extends StatefulWidget {
  @override
  CreateWalletState createState() => CreateWalletState();
}

class CreateWalletState extends State<CreateWalletScreen> {
  late Future<String> _mnemonicFuture;

  @override
  void initState() {
    super.initState();
    final mnemonicHandler = MnemonicHandler();
    final walletId = "mainWallet";
    _mnemonicFuture = mnemonicHandler.createNewBip39Mnemonic(walletId, false);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Build option to select 12 or 24 words
    return Scaffold(
      appBar: MoozeAppBar(title: "Criar nova carteira"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<String>(
            future: _mnemonicFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Erro: ${snapshot.error}");
              } else if (snapshot.hasData) {
                final mnemonic = snapshot.data!;
                final mnemonicGridDisplay = MnemonicGridDisplay(
                  mnemonic: mnemonic,
                );

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Estas são suas palavras de recuperação. Guarde-as com segurança: ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "roboto",
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 20),
                    mnemonicGridDisplay,
                    PrimaryButton(
                      text: "Confirmar",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          "/confirm_mnemonic",
                          arguments: mnemonic,
                        );
                      },
                    ),
                  ],
                );
              }

              return Container(); // fallback
            },
          ),
        ),
      ),
    );
  }
}
