import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/pin/create_pin.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';
import 'package:bdk_flutter/bdk_flutter.dart';

class ImportWalletScreen extends StatefulWidget {
  @override
  _ImportWalletScreenState createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  String? _errorMessage;

  Future<void> _importMnemonic() async {
    String mnemonic = _mnemonicController.text.trim();
    List<String> words = mnemonic.split(RegExp(r'\s+'));
    final mnemonicHandler = MnemonicHandler();

    if (words.length != 12 && words.length != 24) {
      setState(() {
        _errorMessage = "A frase de recuperação deve ter 12 ou 24 palavras.";
      });
      return;
    }

    try {
      await Mnemonic.fromString(mnemonic);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Frase de recuperação inválida. Confira se está usando palavras válidas.",
          ),
        ),
      );
      return;
    }

    try {
      await mnemonicHandler.saveMnemonic("mainWallet", mnemonic);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CreatePinScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao importar: $e";
      });
    }
  }

  Widget build(BuildContext context) {
    InputDecorationThemeData currentTheme =
        Theme.of(context).inputDecorationTheme;

    return Scaffold(
      backgroundColor: Color(0xFF14181B),
      appBar: AppBar(title: Text("Importar carteira")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Digite suas palavras de recuperação separadas por espaço.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _mnemonicController,
                  maxLines: 4,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    fillColor: currentTheme.fillColor,
                    filled: currentTheme.filled,
                    hintText: "palavra1 palavra2 palavra3 ... palavra12",
                  ),
                  keyboardType: TextInputType.visiblePassword,
                ),
              ),
              SizedBox(height: 20),
              PrimaryButton(
                text: "Importar carteira",
                onPressed: () async => _importMnemonic(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
