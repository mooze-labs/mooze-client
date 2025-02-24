import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmMnemonicScreen extends StatefulWidget {
  @override
  _ConfirmMnemonicScreenState createState() => _ConfirmMnemonicScreenState();
}

class _ConfirmMnemonicScreenState extends State<ConfirmMnemonicScreen> {
  TextEditingController _mnemonicController = TextEditingController();
  String? _storedMnemonic;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoredMnemonic();
  }

  Future<void> _loadStoredMnemonic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedMnemonic = prefs.getString('mnemonic');
    });
  }

  void _confirmMnemonic() {
    String enteredMnemonic = _mnemonicController.text.trim();
    if (enteredMnemonic == _storedMnemonic) {
      Navigator.pushNamed(context, '/wallet');
    } else {
      setState(() {
        _errorMessage = "A frase de recuperação está incorreta.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Confirmar mnemônico"),
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
                    "Digite sua frase de recuperação",
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
                    onPressed: _confirmMnemonic,
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
                      "Confirmar",
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
