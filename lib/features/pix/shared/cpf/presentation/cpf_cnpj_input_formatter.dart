import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';

/// Live mask that formats input as a CPF (≤11 digits) or CNPJ (12–14 digits),
/// capped at 14 digits.
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = CpfValidator.strip(newValue.text);
    if (digits.length > 14) digits = digits.substring(0, 14);
    final text = formatCpfCnpj(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
