import 'package:flutter/services.dart';

class BtcInputFormatter extends TextInputFormatter {
  static const int _decimalPlaces = 8;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '0.00000000',
        selection: TextSelection.collapsed(offset: 10),
      );
    }

    String newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newDigits.isEmpty) {
      return const TextEditingValue(
        text: '0.00000000',
        selection: TextSelection.collapsed(offset: 10),
      );
    }

    newDigits = newDigits.replaceFirst(RegExp(r'^0+'), '');
    if (newDigits.isEmpty) {
      newDigits = '0';
    }

    if (newDigits.length > 16) {
      newDigits = newDigits.substring(0, 16);
    }

    String formattedText;

    if (newDigits.length <= _decimalPlaces) {
      newDigits = newDigits.padLeft(_decimalPlaces, '0');
      formattedText = '0.$newDigits';
    } else {
      final integerPart = newDigits.substring(
        0,
        newDigits.length - _decimalPlaces,
      );
      final decimalPart = newDigits.substring(
        newDigits.length - _decimalPlaces,
      );
      formattedText = '$integerPart.$decimalPart';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  static double parseValue(String formattedText) {
    final cleanText = formattedText.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return 0.0;

    final trimmed = cleanText.replaceFirst(RegExp(r'^0+'), '');
    if (trimmed.isEmpty) return 0.0;

    if (trimmed.length <= _decimalPlaces) {
      final paddedDigits = trimmed.padLeft(_decimalPlaces, '0');
      return double.parse('0.$paddedDigits');
    } else {
      final integerPart = trimmed.substring(0, trimmed.length - _decimalPlaces);
      final decimalPart = trimmed.substring(trimmed.length - _decimalPlaces);
      return double.parse('$integerPart.$decimalPart');
    }
  }

  static String formatValue(double value) {
    if (value <= 0) return '0.00000000';

    return value.toStringAsFixed(_decimalPlaces);
  }
}
