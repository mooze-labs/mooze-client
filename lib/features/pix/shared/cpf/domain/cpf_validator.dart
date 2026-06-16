
enum CpfValidationError {

  empty,

  incomplete,

  invalid,
}

class CpfValidator {
  const CpfValidator._();
  static String strip(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');
  static CpfValidationError? validate(String input) {
    final digits = strip(input);
    if (digits.isEmpty) return CpfValidationError.empty;
    if (digits.length != 11) return CpfValidationError.incomplete;
    if (_allSameDigit(digits)) return CpfValidationError.invalid;
    if (!_hasValidCheckDigits(digits)) return CpfValidationError.invalid;
    return null;
  }

  static bool isValid(String input) => validate(input) == null;

  static bool _allSameDigit(String digits) =>
      RegExp(r'^(\d)\1{10}$').hasMatch(digits);

  static bool _hasValidCheckDigits(String digits) {
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

    final first = checkDigit(9);
    final second = checkDigit(10);
    return first == int.parse(digits[9]) && second == int.parse(digits[10]);
  }
}
