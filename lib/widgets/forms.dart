import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CurrencyForm extends StatelessWidget {
  final String? hintText;
  final String? helperText;
  final IconData? icon;

  const CurrencyForm({this.hintText, this.helperText, this.icon});

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      border: InputBorder.none,
      hintText: hintText,
      hintStyle: GoogleFonts.roboto(
        fontSize: 16.0,
        color: Colors.white,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w300,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 17.0, horizontal: 0.0),
    );

    return TextFormField(
      decoration: decoration,
      keyboardType: TextInputType.number,
    );
  }
}
