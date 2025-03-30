import 'package:flutter/material.dart';

class PegInDisplay extends StatelessWidget {
  final TextEditingController amountController;
  final bool receiveFromExternalWallet;

  const PegInDisplay({
    Key? key,
    required this.amountController,
    required this.receiveFromExternalWallet,
  }) : super(key: key);

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
        ],
      ),
    );
  }
}
