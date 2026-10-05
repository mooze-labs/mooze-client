import 'package:mooze_core_bridge/mooze_core_bridge.dart' as bridge;

/// Synchronous mooze-core helpers: tax id rules, PIX key detection, PIX fees
/// and validation, peg amount validation.
///
/// The bridge exposes these as free functions on the native library. This
/// class wraps them so that code and tests can replace the native calls.
/// Production code reads [CoreSyncHelpers.instance]. Tests set it to a fake
/// and restore it in `tearDown`.
///
/// NOTE: the native library must be initialized before a call. The app
/// initializes it when `moozeCoreProvider` opens the core during boot. Every
/// caller runs after boot.
class CoreSyncHelpers {
  const CoreSyncHelpers();

  /// The active helpers. Replace it only in tests.
  static CoreSyncHelpers instance = const CoreSyncHelpers();

  /// Returns null when [input] is a valid CPF or CNPJ.
  bridge.CpfValidationErrorDto? taxIdValidate(String input) =>
      bridge.taxIdValidate(input: input);

  bool taxIdIsValid(String input) => bridge.taxIdIsValid(input: input);

  /// Keeps only the digits of [input].
  String taxIdStrip(String input) => bridge.taxIdStrip(input: input);

  /// Formats [digits] as CPF (up to 11 digits) or CNPJ (12 or more).
  String taxIdFormat(String digits) => bridge.taxIdFormat(digits: digits);

  /// Live input mask: strips, caps at 14 digits, formats.
  String taxIdMaskInput(String text) => bridge.taxIdMaskInput(text: text);

  bool pixLooksLikeKey(String value) => bridge.pixLooksLikeKey(value: value);

  int pixPollIntervalMs() => bridge.pixPollIntervalMs();

  bridge.PixFeeDto pixFee({
    required double amountBrl,
    required bool hasReferral,
    double? quoteBrl,
  }) =>
      bridge.pixFee(
        amountBrl: amountBrl,
        hasReferral: hasReferral,
        quoteBrl: quoteBrl,
      );

  bridge.DepositValidationDto pixValidateAmount({
    required double amountBrl,
    bridge.DepositLimitsDto? limits,
  }) =>
      bridge.pixValidateAmount(amountBrl: amountBrl, limits: limits);

  bridge.PegAmountValidationDto pegValidateAmount({
    required bridge.PegDirectionDto direction,
    BigInt? amountSat,
    required BigInt spendableSat,
    bridge.PegServerLimitsDto? limits,
    required BigInt fallbackMinimumSats,
    required bool drain,
  }) =>
      bridge.pegValidateAmount(
        direction: direction,
        amountSat: amountSat,
        spendableSat: spendableSat,
        limits: limits,
        fallbackMinimumSats: fallbackMinimumSats,
        drain: drain,
      );
}

/// Message of a bridge error, for the user-facing `String` failures.
String coreErrorMessage(Object error) =>
    error is bridge.CoreError ? error.message : error.toString();
