import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, allow it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove any non-digit characters except the decimal point or comma
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle the case where user types a comma
    if (newText == ',') {
      return newValue.copyWith(text: '0,');
    }

    // Parse the input, treating it as cents initially
    String cleanText = newText.replaceAll(
      '.',
      '',
    ); // Remove thousands separators
    double value = double.tryParse(cleanText.replaceAll(',', '.')) ?? 0.0;

    if (newText.contains(',')) {
      // If user is typing decimals, preserve partial input
      List<String> parts = newText.split(',');
      String integerPart = parts[0].isEmpty ? '0' : parts[0];
      String decimalPart = parts.length > 1 ? parts[1] : '';
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2); // Limit to 2 decimal places
      }
      newText = _formatter
          .format(double.parse('$integerPart.0'))
          .replaceAll(',00', '');
      if (decimalPart.isNotEmpty) {
        newText = '$newText,$decimalPart';
      }
    } else {
      // Treat input as cents (e.g., 1234 -> 12,34)
      value = value / 100;
      newText = _formatter.format(value);
    }

    // Adjust cursor position to the end
    int selectionIndex = newText.length;
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
