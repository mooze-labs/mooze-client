import 'package:mooze_core_bridge/mooze_core_bridge.dart' show PegAmountIssueDto;
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

import '../../data/mappers/core_swap_mapper.dart';
import '../entities/peg.dart';

/// Why a peg amount cannot be used.
enum PegAmountIssue {
  belowMinimum,
  aboveBalance,
}

class PegAmountValidation {
  const PegAmountValidation._({
    required this.hasAmount,
    required this.isValid,
    this.issue,
    this.minimumSats,
    this.maximumSats,
  });

  /// No amount entered yet: nothing to complain about, nothing to proceed with.
  const PegAmountValidation.empty()
    : hasAmount = false,
      isValid = false,
      issue = null,
      minimumSats = null,
      maximumSats = null;

  const PegAmountValidation.valid({
    required BigInt minimumSats,
    required BigInt maximumSats,
  }) : this._(
         hasAmount: true,
         isValid: true,
         minimumSats: minimumSats,
         maximumSats: maximumSats,
       );

  const PegAmountValidation.invalid({
    required PegAmountIssue reason,
    required BigInt minimumSats,
    required BigInt maximumSats,
  }) : this._(
         hasAmount: true,
         isValid: false,
         issue: reason,
         minimumSats: minimumSats,
         maximumSats: maximumSats,
       );

  final bool hasAmount;
  final bool isValid;
  final PegAmountIssue? issue;
  final BigInt? minimumSats;
  final BigInt? maximumSats;

  bool get showsIssue => hasAmount && issue != null;
}

/// Validates a peg amount with the mooze-core rules. The minimum comes from
/// [limits], or [fallbackMinimumSats] while the limits are unknown. A drain
/// is always valid.
PegAmountValidation evaluatePegAmount({
  required PegDirection direction,
  required BigInt? amountSat,
  required BigInt spendableSat,
  required PegServerLimits? limits,
  required BigInt fallbackMinimumSats,
  bool drain = false,
}) {
  final result = CoreSyncHelpers.instance.pegValidateAmount(
    direction: pegDirectionToDto(direction),
    amountSat: amountSat,
    spendableSat: spendableSat,
    limits: limits == null ? null : pegLimitsToDto(limits),
    fallbackMinimumSats: fallbackMinimumSats,
    drain: drain,
  );
  if (!result.hasAmount) return const PegAmountValidation.empty();
  return PegAmountValidation._(
    hasAmount: true,
    isValid: result.isValid,
    issue: switch (result.issue) {
      null => null,
      PegAmountIssueDto.belowMinimum => PegAmountIssue.belowMinimum,
      PegAmountIssueDto.aboveBalance => PegAmountIssue.aboveBalance,
    },
    minimumSats: result.minimumSats,
    maximumSats: result.maximumSats,
  );
}
