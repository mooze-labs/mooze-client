
enum CpfValidationError {

  empty,

  incomplete,

  invalid,
}

/// Validates Brazilian taxpayer ids: CPF (11 digits) and CNPJ (14 digits).
class CpfValidator {
  const CpfValidator._();
  static String strip(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');
  static CpfValidationError? validate(String input) {
    final digits = strip(input);
    if (digits.isEmpty) return CpfValidationError.empty;
    if (digits.length == 11) {
      return _isValidCpf(digits) ? null : CpfValidationError.invalid;
    }
    if (digits.length == 14) {
      return _isValidCnpj(digits) ? null : CpfValidationError.invalid;
    }
    return digits.length < 14
        ? CpfValidationError.incomplete
        : CpfValidationError.invalid;
  }

  static bool isValid(String input) => validate(input) == null;

  static bool _allSameDigit(String digits) =>
      RegExp(r'^(\d)\1*$').hasMatch(digits);

  static bool _isValidCpf(String digits) {
    if (_allSameDigit(digits)) return false;
    int checkDigit(int length) {
      var sum = 0;
      var weight = length + 1;
      for (var i = 0; i < length; i++) {
        sum += int.parse(digits[i]) * weight;
        weight--;
      }
      final remainder = sum % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    return checkDigit(9) == int.parse(digits[9]) &&
        checkDigit(10) == int.parse(digits[10]);
  }

  static bool _isValidCnpj(String digits) {
    if (_allSameDigit(digits)) return false;
    const base = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int checkDigit(int length) {
      final weights = base.sublist(base.length - length);
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += int.parse(digits[i]) * weights[i];
      }
      final remainder = sum % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    return checkDigit(12) == int.parse(digits[12]) &&
        checkDigit(13) == int.parse(digits[13]);
  }
}

/// Formats digits as CPF (`000.000.000-00`, up to 11) or CNPJ
/// (`00.000.000/0000-00`, 12–14), progressively.
String formatCpfCnpj(String digits) {
  final buffer = StringBuffer();
  if (digits.length <= 11) {
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
  } else {
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
  }
  return buffer.toString();
}
