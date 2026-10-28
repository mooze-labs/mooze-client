import 'package:mooze_core_bridge/mooze_core_bridge.dart'
    show CpfValidationErrorDto;

import '../../../shared/fake_core_sync_helpers.dart';

/// Test double for the core tax id helpers, with the CPF and CNPJ check digits.
///
/// The Pix key tests reject a document with wrong check digits, so the base
/// fake is not enough. The core rules have their own Rust tests.
class CheckDigitCoreSyncHelpers extends FakeCoreSyncHelpers {
  const CheckDigitCoreSyncHelpers();

  @override
  CpfValidationErrorDto? taxIdValidate(String input) {
    final error = super.taxIdValidate(input);
    if (error != null) return error;
    final digits = taxIdStrip(input).split('').map(int.parse).toList();
    final valid = digits.length == 11
        ? _isValidCpf(digits)
        : _isValidCnpj(digits);
    return valid ? null : CpfValidationErrorDto.invalid;
  }

  static bool _isValidCpf(List<int> d) =>
      _cpfDigit(d, 9) == d[9] && _cpfDigit(d, 10) == d[10];

  static int _cpfDigit(List<int> d, int length) {
    var sum = 0;
    for (var i = 0; i < length; i++) {
      sum += d[i] * (length + 1 - i);
    }
    final rest = (sum * 10) % 11;
    return rest == 10 ? 0 : rest;
  }

  static bool _isValidCnpj(List<int> d) =>
      _cnpjDigit(d, 12) == d[12] && _cnpjDigit(d, 13) == d[13];

  static int _cnpjDigit(List<int> d, int length) {
    var sum = 0;
    var weight = length - 7;
    for (var i = 0; i < length; i++) {
      sum += d[i] * weight;
      weight = weight == 2 ? 9 : weight - 1;
    }
    final rest = sum % 11;
    return rest < 2 ? 0 : 11 - rest;
  }
}
