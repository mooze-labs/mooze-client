import 'package:flutter/material.dart';
import 'package:mooze_mobile/widgets/asset_selector.dart';
import 'package:mooze_mobile/screens/confirm-transaction-screen.dart';

class SendFundsScreen extends StatefulWidget {
  const SendFundsScreen({Key? key}) : super(key: key);

  @override
  _SendFundsScreenState createState() => _SendFundsScreenState();
}

class _SendFundsScreenState extends State<SendFundsScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedAssetId;

  final Map<String, Map<String, String>> assetDetails = {
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d': {
      'name': 'Liquid Bitcoin',
      'logo': 'assets/lbtc-logo.png',
    },
    '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189': {
      'name': 'Depix',
      'logo': 'assets/depix-logo.png',
    },
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2': {
      'name': 'USDt',
      'logo': 'assets/usdt-logo.png',
    },
  };

  void _onSubmit() {
    if (_addressController.text.isEmpty || _selectedAssetId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos antes de continuar.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmTransactionScreen(
          address: _addressController.text,
          assetId: _selectedAssetId!,
          amount: _amountController.text,
          assetDetails: assetDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Enviar Fundos"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AssetSelector(
              selectedAssetId: _selectedAssetId,
              assetDetails: assetDetails,
              onChanged: (value) {
                setState(() {
                  _selectedAssetId = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // Address Input Field
            TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                labelText: "Endereço de destino",
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // Amount Input Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                labelText: "Quantidade",
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD973C1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              child: const Text(
                "Continuar",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
