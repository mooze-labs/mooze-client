import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PixInputAmount extends StatefulWidget {
  final TextEditingController amountController;
  final Function(String)? onChanged;

  const PixInputAmount({
    super.key,
    required this.amountController,
    this.onChanged,
  });

  @override
  State<PixInputAmount> createState() => _PixInputAmountState();
}

class _PixInputAmountState extends State<PixInputAmount> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Valor do PIX",
            style: TextStyle(fontFamily: "roboto", fontSize: 20),
          ),
          SizedBox(
            width: 250,
            child: TextField(
              controller: widget.amountController,
              onChanged: (value) {
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                }
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "• Valor mínimo: R\$ 20,00 \n• Limite diário por CPF/CNPJ: R\$ 5.000,00",
                style: TextStyle(fontFamily: "roboto", fontSize: 16),
                textAlign: TextAlign.center,
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Limite diário"),
                          scrollable: true,
                          content: Text("""
O limite de pagamento via PIX na Mooze é compartilhado com outras plataformas que utilizam o sistema DEPIX, incluindo compras P2P ou concorrentes. Esse limite é monitorado pelas processadoras de pagamento por meio do sistema PIX do BACEN, com base no CPF ou CNPJ vinculado ao DEPIX. Assim, ao atingir o teto diário de R\$5.000 em transações realizadas fora da Mooze, novas tentativas de pagamento via nossos QR Codes serão automaticamente bloqueadas e estornadas à conta de origem.
Essa limitação protege o usuário contra a obrigatoriedade de reporte automático de transações. Nem a Mooze nem as processadoras realizam comunicação compulsória dessas operações, preservando a sua privacidade.
                                        """),
                        ),
                  );
                },
                child: Icon(
                  Icons.question_mark,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
