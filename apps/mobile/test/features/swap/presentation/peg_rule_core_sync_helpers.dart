import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import '../../../shared/fake_core_sync_helpers.dart';

/// [FakeCoreSyncHelpers] with the peg amount rule of mooze-core
/// (`crates/mooze-core/src/peg/validation.rs`): the minimum comes from the
/// limits, or the fallback without them; a drain (Max) needs the spendable
/// balance to reach the minimum; below the minimum wins over the balance.
class PegRuleCoreSyncHelpers extends FakeCoreSyncHelpers {
  const PegRuleCoreSyncHelpers();

  @override
  PegAmountValidationDto pegValidateAmount({
    required PegDirectionDto direction,
    BigInt? amountSat,
    required BigInt spendableSat,
    PegServerLimitsDto? limits,
    required BigInt fallbackMinimumSats,
    required bool drain,
  }) {
    final minimum = limits == null
        ? fallbackMinimumSats
        : (direction == PegDirectionDto.pegIn
              ? limits.minPegInSat
              : limits.minPegOutSat);
    PegAmountValidationDto invalid(PegAmountIssueDto issue) =>
        PegAmountValidationDto(
          hasAmount: true,
          isValid: false,
          issue: issue,
          minimumSats: minimum,
          maximumSats: spendableSat,
          showsIssue: true,
        );
    final valid = PegAmountValidationDto(
      hasAmount: true,
      isValid: true,
      minimumSats: minimum,
      maximumSats: spendableSat,
      showsIssue: false,
    );
    if (drain) {
      return spendableSat < minimum
          ? invalid(PegAmountIssueDto.belowMinimum)
          : valid;
    }
    final amount = amountSat;
    if (amount == null || amount <= BigInt.zero) {
      return const PegAmountValidationDto(
        hasAmount: false,
        isValid: false,
        showsIssue: false,
      );
    }
    if (amount < minimum) return invalid(PegAmountIssueDto.belowMinimum);
    if (amount > spendableSat) return invalid(PegAmountIssueDto.aboveBalance);
    return valid;
  }
}
