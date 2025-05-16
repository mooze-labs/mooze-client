import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/screens/receive_pix/providers/pix_input_provider.dart';

class PixInputAmount extends ConsumerStatefulWidget {
  const PixInputAmount({super.key});

  @override
  PixInputAmountState createState() => PixInputAmountState();
}

class PixInputAmountState extends ConsumerState<PixInputAmount> {
  final amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Valor do PIX",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          child: TextField(
            controller: amountController,
            onChanged: (value) {
              if (value.isEmpty) {
                ref.read(pixInputProvider.notifier).updateAmount(0);
                return;
              }

              final amountInCents =
                  double.parse(value.replaceAll(",", ".")) * 100;
              ref
                  .read(pixInputProvider.notifier)
                  .updateAmount(amountInCents.toInt());
            },
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: "R\$",
              prefixStyle: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: "roboto",
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.transparent),
              ),
            ),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: "roboto",
            ),
            keyboardType:
                (Platform.isIOS)
                    ? null
                    : TextInputType.numberWithOptions(decimal: true),
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

                // Check for decimal places limit
                final parts = newValue.text.split(RegExp(r'[.,]'));
                if (parts.length > 1 && parts[1].length > 2) {
                  // More than 2 decimal places, reject
                  return oldValue;
                }

                return newValue;
              }),
            ],
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
