import 'package:flutter/services.dart';

class SatsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    String newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newDigits.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    newDigits = newDigits.replaceFirst(RegExp(r'^0+'), '');
    if (newDigits.isEmpty) {
      newDigits = '0';
    }

    // 16 raw digits matches the max BTC supply in sats
    // (2,100,000,000,000,000) and aligns with the BTC/fiat formatter
    // caps so all three input modes share the same digit budget.
    if (newDigits.length > 16) {
      newDigits = newDigits.substring(0, 16);
    }

    final formattedText = _formatWithThousandsSeparator(newDigits);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _formatWithThousandsSeparator(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  static int parseValue(String formattedText) {
    final digitsOnly = formattedText.replaceAll('.', '');

    return int.tryParse(digitsOnly) ?? 0;
  }

  static String formatValue(int value) {
    if (value <= 0) return '0';

    final formatter = SatsInputFormatter();
    return formatter._formatWithThousandsSeparator(value.toString());
  }
}
