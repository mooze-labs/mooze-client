import 'package:flutter/material.dart';

class ConfirmTransactionScreen extends StatelessWidget {
  final String address;
  final String assetId;
  final String amount;
  final Map<String, Map<String, String>> assetDetails;

  const ConfirmTransactionScreen({
    Key? key,
    required this.address,
    required this.assetId,
    required this.amount,
    required this.assetDetails,
  }) : super(key: key);

  void _confirmTransaction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transação enviada com sucesso!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Confirmar Transação"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Revise os detalhes antes de confirmar",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Asset Information
            Row(
              children: [
                Image.asset(
                  assetDetails[assetId]!['logo']!,
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 10),
                Text(
                  assetDetails[assetId]!['name']!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Address Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD973C1), width: 1),
              ),
              child: Text(
                "Endereço: $address",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Amount Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD973C1), width: 1),
              ),
              child: Text(
                "Quantidade: $amount",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => _confirmTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD973C1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              child: const Text(
                "Confirmar Transação",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
