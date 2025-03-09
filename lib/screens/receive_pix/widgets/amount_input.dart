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
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              maxLines: 1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Valor máximo diário: R\$ 5000",
            style: TextStyle(fontFamily: "roboto", fontSize: 16),
          ),
        ],
      ),
    );
  }
}
