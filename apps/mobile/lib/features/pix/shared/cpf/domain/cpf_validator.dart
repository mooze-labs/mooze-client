import 'package:mooze_core_bridge/mooze_core_bridge.dart'
    show CpfValidationErrorDto;
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

/// Why a CPF/CNPJ input is not valid.
enum CpfValidationError { empty, incomplete, invalid }

/// Validates Brazilian taxpayer ids: CPF (11 digits) and CNPJ (14 digits).
///
/// The rules run in mooze-core. This class maps the core results to the
/// app enum.
class CpfValidator {
  const CpfValidator._();

  /// Keeps only the digits of [input].
  static String strip(String input) =>
      CoreSyncHelpers.instance.taxIdStrip(input);

  /// Returns null when [input] is a valid CPF or CNPJ, masked or raw.
  static CpfValidationError? validate(String input) =>
      switch (CoreSyncHelpers.instance.taxIdValidate(input)) {
        null => null,
        CpfValidationErrorDto.empty => CpfValidationError.empty,
        CpfValidationErrorDto.incomplete => CpfValidationError.incomplete,
        CpfValidationErrorDto.invalid => CpfValidationError.invalid,
      };

  static bool isValid(String input) =>
      CoreSyncHelpers.instance.taxIdIsValid(input);
}

/// Formats digits as CPF (`000.000.000-00`, up to 11) or CNPJ
/// (`00.000.000/0000-00`, 12 to 14), progressively.
String formatCpfCnpj(String digits) =>
    CoreSyncHelpers.instance.taxIdFormat(digits);
