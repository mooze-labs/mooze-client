import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/settings/terms_and_conditions.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class FirstAccessScreen extends StatefulWidget {
  const FirstAccessScreen({super.key});

  @override
  State<FirstAccessScreen> createState() => _FirstAccessScreenState();
}

class _FirstAccessScreenState extends State<FirstAccessScreen> {
  bool _termsAccepted = false;

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
                    _termsAccepted
                        ? () => Navigator.pushReplacementNamed(
                          context,
                          "/import_wallet",
                        )
                        : null,
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
    TextStyle termsStyle = TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
      fontSize: 14.0,
    );
    TextStyle termsLinkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 14.0,
      decoration: TextDecoration.underline,
    );

    final termsAndConditionsCheckbox = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (bool? value) {
            setState(() {
              _termsAccepted = value ?? false;
            });
          },
          checkColor: Theme.of(context).colorScheme.onPrimary,
          activeColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: Theme.of(context).colorScheme.onPrimary),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "Eu li e concordo com os ", style: termsStyle),
                TextSpan(
                  text: "Termos e Condições",
                  style: termsLinkStyle,
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TermsAndConditionsScreen(),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final buttons = Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.wallet_rounded, color: Colors.white, size: 20.0),
          label: Text("Começar"),
          onPressed:
              _termsAccepted
                  ? () {
                    Navigator.pushNamed(context, '/create_wallet');
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textStyle: TextStyle(
              fontSize: 19.0,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimary,
              letterSpacing: 0.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 50.0),
            maximumSize: Size(MediaQuery.of(context).size.width * 0.9, 50.0),
            elevation: 3.0,
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Já tem uma carteira? ", style: defaultStyle),
            InkWell(
              onTap: _termsAccepted ? () => _importWallet(context) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Importe-a.",
                    style:
                        _termsAccepted
                            ? linkStyle
                            : linkStyle.copyWith(
                              color: linkStyle.color?.withOpacity(0.5),
                            ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color:
                        _termsAccepted
                            ? linkStyle.color
                            : linkStyle.color?.withOpacity(0.5),
                  ),
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
            child: Column(
              children: [
                termsAndConditionsCheckbox,
                SizedBox(height: 20),
                buttons,
              ],
            ),
          ),
          Spacer(),
          SizedBox(height: 80),
        ],
      ),
    );

    return Scaffold(backgroundColor: Color(0xFF14181B), body: body);
  }
}
