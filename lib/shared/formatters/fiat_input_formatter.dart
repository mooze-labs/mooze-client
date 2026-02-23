import 'package:flutter/services.dart';

class FiatInputFormatter extends TextInputFormatter {
  static const int _decimalPlaces = 2;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    String newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newDigits.isEmpty) {
      return const TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    newDigits = newDigits.replaceFirst(RegExp(r'^0+'), '');
    if (newDigits.isEmpty) {
      newDigits = '0';
    }

    if (newDigits.length > 12) {
      newDigits = newDigits.substring(0, 12);
    }

    if (newDigits.length < 3) {
      newDigits = newDigits.padLeft(3, '0');
    }

    final integerPart = newDigits.substring(
      0,
      newDigits.length - _decimalPlaces,
    );
    final decimalPart = newDigits.substring(newDigits.length - _decimalPlaces);

    final formattedInteger = _formatIntegerWithThousandsSeparator(integerPart);

    final formattedText = '$formattedInteger,$decimalPart';

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _formatIntegerWithThousandsSeparator(String integer) {
    integer = integer.replaceFirst(RegExp(r'^0+'), '');
    if (integer.isEmpty) integer = '0';

    final buffer = StringBuffer();
    final length = integer.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integer[i]);
    }

    return buffer.toString();
  }

  static double parseValue(String formattedText) {
    final normalized = formattedText.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0.0;
  }

  static String formatValue(double value) {
    if (value <= 0) return '0,00';
    final cents = (value * 100).round();

    final centsString = cents.toString().padLeft(3, '0');

    final integerPart = centsString.substring(0, centsString.length - 2);
    final decimalPart = centsString.substring(centsString.length - 2);

    final formatter = FiatInputFormatter();
    final formattedInteger = formatter._formatIntegerWithThousandsSeparator(
      integerPart,
    );

    return '$formattedInteger,$decimalPart';
  }
}
