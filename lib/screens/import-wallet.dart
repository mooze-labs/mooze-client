import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/mnemonic_provider.dart';

class ImportWalletScreen extends ConsumerStatefulWidget {
  @override
  _ImportWalletScreenState createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  String? _errorMessage;

  Future<void> _importMnemonic() async {
    String mnemonic = _mnemonicController.text.trim();
    List<String> words = mnemonic.split(RegExp(r'\s+'));

    if (words.length != 12 && words.length != 24) {
      setState(() {
        _errorMessage = "A frase de recuperação deve ter 12 ou 24 palavras.";
      });
      return;
    }

    try {
      await ref
          .read(mnemonicNotifierProvider.notifier)
          .importMnemonic(mnemonic);
      Navigator.pushNamed(context, '/wallet');
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao importar: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Importar carteira existente"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          StarryBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Digite sua frase de recuperação: ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _mnemonicController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Digite sua frase de recuperação aqui",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFD973C1)),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _importMnemonic,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD973C1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 40,
                      ),
                    ),
                    child: Text(
                      "Importar carteira",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StarryBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Colors.black));
  }
}
