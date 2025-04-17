import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/user.dart';

class PixInputAmount extends ConsumerStatefulWidget {
  final TextEditingController amountController;
  final Function(String)? onChanged;
  final User? userDetails;

  const PixInputAmount({
    super.key,
    required this.amountController,
    this.onChanged,
    this.userDetails,
  });

  @override
  ConsumerState<PixInputAmount> createState() => _PixInputAmountState();
}

class _PixInputAmountState extends ConsumerState<PixInputAmount> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
          if (widget.userDetails != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Limite por transação atual: R\$ ${(widget.userDetails!.allowedSpending.toDouble() / 100).toStringAsFixed(2)}",
                  style: TextStyle(fontFamily: "roboto", fontSize: 16),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text("Limite por transação"),
                            scrollable: true,
                            content: Text("""
Novas carteiras passam por um filtro da Mooze, as primeiras transações possuem um sistema de segurança onde existem limites de valores por transações:
1ª degrau - até R\$250 por transação. Ao atingir compras de R\$250, o usuário libera o próximo degrau;
2ª degrau - até R\$750 por transação. Ao atingir compras de R\$750, o usuário libera o próximo degrau;
3ª degrau - até R\$1500 por transação. Ao atingir compras de R\$1500, usuário finaliza o sistema TRUST e tem compras liberadas de R\$20 a R\$5000 com seu restante de saldo diário.
A rota completa de degraus do sistema TRUST é necessária apenas uma vez.
""", style: TextStyle(fontFamily: "roboto", fontSize: 16)),
                          ),
                    );
                  },
                  child: Icon(
                    Icons.question_mark,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            )
          else
            Text(
              "Limite de transação indisponível.",
              style: TextStyle(fontFamily: "roboto", fontSize: 16),
            ),
        ],
      ),
    );
  }
}
