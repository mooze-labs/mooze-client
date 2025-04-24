import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
              keyboardType:
                  (Platform.isIOS)
                      ? null
                      : TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // First check for multiple decimal separators
                  int commaCount = newValue.text.split(',').length - 1;
                  int dotCount = newValue.text.split('.').length - 1;

                  // If there's more than one total decimal separator, reject the edit
                  if (commaCount + dotCount > 1) {
                    return oldValue;
                  }

                  return newValue;
                }),
              ],
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
