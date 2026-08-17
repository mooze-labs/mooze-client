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

PegAmountValidation evaluatePegAmount({
  required PegDirection direction,
  required BigInt? amountSat,
  required BigInt spendableSat,
  required PegServerLimits? limits,
  required BigInt fallbackMinimumSats,
  bool drain = false,
}) {
  final minimum =
      limits == null
          ? fallbackMinimumSats
          : BigInt.from(limits.minimumFor(direction));

  if (drain) {
    return PegAmountValidation.valid(
      minimumSats: minimum,
      maximumSats: spendableSat,
    );
  }

  if (amountSat == null || amountSat <= BigInt.zero) {
    return const PegAmountValidation.empty();
  }

  if (amountSat < minimum) {
    return PegAmountValidation.invalid(
      reason: PegAmountIssue.belowMinimum,
      minimumSats: minimum,
      maximumSats: spendableSat,
    );
  }

  if (amountSat > spendableSat) {
    return PegAmountValidation.invalid(
      reason: PegAmountIssue.aboveBalance,
      minimumSats: minimum,
      maximumSats: spendableSat,
    );
  }

  return PegAmountValidation.valid(
    minimumSats: minimum,
    maximumSats: spendableSat,
  );
}
