import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/settings/terms_and_conditions.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class FirstAccessScreen extends StatelessWidget {
  const FirstAccessScreen({super.key});

  void _importWallet(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text("Aviso para usuários\nAqua/Sideswap"),
              ],
            ),
            content: Text("""
A carteira Mooze utiliza versões mais atualizadas da rede Liquid, com suporte para native segwit. As carteiras Sideswap e Aqua Wallet
não possuem suporte para native segwit, portanto, não é possível importar seeds dessas carteiras para a Mooze.
É recomendado que você crie uma nova carteira no nosso app e transfira os seus fundos para cá.
          """),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Voltar"),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(
                      context,
                      "/import_wallet",
                    ),
                child: Text("Importar"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 16.0);
    TextStyle linkStyle = TextStyle(color: Colors.pinkAccent, fontSize: 16.0);

    final buttons = Column(
      children: [
        PrimaryButton(
          text: "Começar",
          onPressed: () {
            Navigator.pushNamed(context, '/create_wallet');
          },
          icon: Icons.wallet_rounded,
        ),
        SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Já tem uma carteira? ", style: defaultStyle),
            InkWell(
              onTap: () => _importWallet(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Importe-a.", style: linkStyle),
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
          Spacer(),
          Image.asset('assets/images/mooze-logo.png', width: 200, height: 200),
          SizedBox(height: 50),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(children: [buttons]),
          ),
          Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Ao prosseguir, você concorda",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "com nossos",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 5),
                  InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsAndConditionsScreen(),
                          ),
                        ),
                    child: Text(
                      "Termos e Condições",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 80),
        ],
      ),
    );

    return Scaffold(backgroundColor: Color(0xFF14181B), body: body);
  }
}
