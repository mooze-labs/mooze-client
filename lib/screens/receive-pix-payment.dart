import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lwk/lwk.dart'; 
class ReceivePixPaymentScreen extends StatefulWidget {
  final Wallet wallet;

  const ReceivePixPaymentScreen({Key? key, required this.wallet})
    : super(key: key);

  @override
  _ReceivePixPaymentScreenState createState() =>
      _ReceivePixPaymentScreenState();
}

class _ReceivePixPaymentScreenState extends State<ReceivePixPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = false;
  String? _address;
  String? _qrImageUrl;
  String? _qrCopyPaste;
  String? _errorMessage;

  static const double _feeRate = 0.02;

  @override
  void initState() {
    super.initState();
    _generateAddress();
  }

  Future<void> _generateAddress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final addressObj = await widget.wallet.addressLastUnused();
      final confidentialAddress = addressObj.confidential;

      setState(() {
        _address = confidentialAddress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Erro ao gerar endereço: $e";
      });
    }
  }

  Future<void> _generatePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _qrImageUrl = null;
      _qrCopyPaste = null;
    });

    try {
      final rawInput = _amountController.text.trim();
      if (rawInput.isEmpty) {
        throw Exception("Digite um valor inteiro entre 50 e 5000");
      }

      final amount = int.parse(rawInput);

      if (amount < 50 || amount > 5000) {
        throw Exception("O valor deve ser entre 50 e 5000");
      }

      if (_address == null) {
        throw Exception("Endereço não foi gerado ainda. Tente novamente.");
      }

      final amountInCents = amount * 100;

      final url = Uri.parse("https://depix.eulen.app/api/deposit");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "amountInCents": amountInCents,
          "depixAddress": _address,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Falha ao gerar pagamento. Código HTTP: ${response.statusCode}",
        );
      }

      final data = json.decode(response.body);
      // Expecting structure: { "response": { "qrCopyPaste": "...", "qrImageUrl": "...", "id": "..." }, "async": false }
      final responseObject = data["response"];
      final qrCopyPaste = responseObject["qrCopyPaste"];
      final qrImageUrl = responseObject["qrImageUrl"];

      setState(() {
        _qrCopyPaste = qrCopyPaste;
        _qrImageUrl = qrImageUrl;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "$e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Copy the qrCopyPaste string to clipboard
  void _copyQrCode() async {
    final code = _qrCopyPaste;
    if (code == null) return; 
    await Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Código PIX copiado para a área de transferência"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int inputAmount = int.tryParse(_amountController.text) ?? 0;
    final int amountAfterFees = (inputAmount * (1 - _feeRate)).round();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Receber por PIX"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Container(color: Colors.black),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Gerar pagamento via PIX",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),

                  // Confidential address info (optional to display)
                  if (_address != null) ...[
                    SizedBox(height: 8),
                    Text(
                      "Seu endereço:",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      _address!,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 16),

                  // Amount text field
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Digite o valor em BRL (inteiro)",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (_) {
                      // Just rebuild to display updated "amountAfterFees"
                      setState(() {});
                    },
                  ),

                  if (inputAmount >= 50 && inputAmount <= 5000) ...[
                    SizedBox(height: 8),
                    Text(
                      "Você envia $inputAmount e recebe $amountAfterFees (após taxa de 2%)",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _generatePayment, // Disable if loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD973C1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                    ),
                    child: Text(
                      _isLoading ? "Processando..." : "Gerar pagamento",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Display generated QR code and copy/paste
                  SizedBox(height: 24),
                  if (_qrImageUrl != null) ...[
                    Text(
                      "QR Code gerado",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Image.network(_qrImageUrl!),
                    SizedBox(height: 12),
                  ],

                  if (_qrCopyPaste != null) ...[
                    Text(
                      "Copie seu código PIX:",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _copyQrCode,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _qrCopyPaste!,
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
