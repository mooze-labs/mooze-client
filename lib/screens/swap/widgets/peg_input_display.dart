import 'package:flutter/material.dart';

class PegInputDisplay extends StatelessWidget {
  final bool pegIn;
  final TextEditingController addressController;
  final TextEditingController amountController;
  final bool receiveFromExternalWallet;
  final bool sendToExternalWallet;

  const PegInputDisplay({
    super.key,
    required this.pegIn,
    required this.amountController,
    required this.addressController,
    required this.receiveFromExternalWallet,
    required this.sendToExternalWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Digite o valor",
                hintStyle: TextStyle(
                  fontFamily: "roboto",
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "roboto",
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          if (sendToExternalWallet)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent),
              ),
              child: TextField(
                controller: addressController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      "Digite o endereço para enviar ${pegIn ? "L-BTC" : "BTC"}",
                  hintStyle: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "roboto",
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
