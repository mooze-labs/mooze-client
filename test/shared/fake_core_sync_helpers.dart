import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

/// Test double for [CoreSyncHelpers] without the native library.
///
/// It covers the tax id helpers that widgets call while they build. The
/// rules are a small reference version: widget tests need plausible masks
/// and validity, not the core's exact rules. The core rules have their own
/// Rust tests.
class FakeCoreSyncHelpers extends CoreSyncHelpers {
  const FakeCoreSyncHelpers();

  @override
  String taxIdStrip(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  String taxIdFormat(String digits) {
    final buffer = StringBuffer();
    final cpf = digits.length <= 11;
    for (var i = 0; i < digits.length; i++) {
      if (cpf) {
        if (i == 3 || i == 6) buffer.write('.');
        if (i == 9) buffer.write('-');
      } else {
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('/');
        if (i == 12) buffer.write('-');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  String taxIdMaskInput(String text) {
    var digits = taxIdStrip(text);
    if (digits.length > 14) digits = digits.substring(0, 14);
    return taxIdFormat(digits);
  }

  /// Valid when the input has 11 or 14 digits that are not all equal.
  @override
  CpfValidationErrorDto? taxIdValidate(String input) {
    final digits = taxIdStrip(input);
    if (digits.isEmpty) return CpfValidationErrorDto.empty;
    if (digits.length != 11 && digits.length != 14) {
      return digits.length < 14
          ? CpfValidationErrorDto.incomplete
          : CpfValidationErrorDto.invalid;
    }
    return RegExp(r'^(\d)\1*$').hasMatch(digits)
        ? CpfValidationErrorDto.invalid
        : null;
  }

  @override
  bool taxIdIsValid(String input) => taxIdValidate(input) == null;

  @override
  bool pixLooksLikeKey(String value) => value.trim().isNotEmpty;

  @override
  int pixPollIntervalMs() => 30000;
}

/// Installs [helpers] for each test of the enclosing group and restores the
/// native helpers after it.
void useCoreSyncHelpers([CoreSyncHelpers helpers = const FakeCoreSyncHelpers()]) {
  setUp(() => CoreSyncHelpers.instance = helpers);
  tearDown(() => CoreSyncHelpers.instance = const CoreSyncHelpers());
}
