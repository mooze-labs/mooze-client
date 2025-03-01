import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mooze_mobile/providers/external/price_provider.dart';
import 'package:mooze_mobile/widgets/forms/currency_form.dart';

/*
class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _brlController = TextEditingController();
  double _btcAmount = 0.0;
  final double _btcPrice = 50000.0; // Example BTC price in BRL

  @override
  void initState() {
    super.initState();
    _brlController.addListener(_updateBTCAmount);
  }

  @override
  void dispose() {
    _brlController.removeListener(_updateBTCAmount);
    _brlController.dispose();
    super.dispose();
  }

  void _updateBTCAmount() {
    final brlText = _brlController.text
        .replaceAll('R\$ ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final brlAmount = double.tryParse(brlText) ?? 0.0;
    setState(() {
      _btcAmount = brlAmount / _btcPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurrencyForm(
            controller: _brlController,
            hintText: "Digite o valor em reais.",
            helperText: "Limite diário: R\$ 5.000",
            icon: Icons.monetization_on,
          ),
          const SizedBox(height: 16.0),
          Text(
            "Equivalente em BTC: ${_btcAmount.toStringAsFixed(8)} BTC",
            style: GoogleFonts.roboto(
              fontSize: 16.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
*/
