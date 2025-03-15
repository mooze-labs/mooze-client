import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mooze_mobile/utils/formatters.dart';

class CurrencyForm extends StatelessWidget {
  final String? hintText;
  final String? helperText;
  final IconData? icon;
  final TextEditingController controller;

  const CurrencyForm({
    required this.controller,
    this.hintText,
    this.helperText,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      border: InputBorder.none,
      hintText: hintText ?? 'Digite o valor',
      hintStyle: GoogleFonts.roboto(
        fontSize: 16.0,
        color: Colors.white,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w300,
      ),
      helperText: helperText,
      helperStyle: GoogleFonts.roboto(fontSize: 12.0, color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17.0,
        horizontal: 0.0,
      ),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white) : null,
    );

    return TextFormField(
      controller: controller,
      decoration: decoration,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyInputFormatter()],
    );
  }
}
