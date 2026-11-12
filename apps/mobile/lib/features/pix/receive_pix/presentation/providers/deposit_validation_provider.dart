import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart'
    show DepositLimitsDto, DepositValidationErrorDto;
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

enum DepositValidationError {
  none,
  belowMinimum,
  aboveTransaction,
  aboveRemaining,
  invalidAmount,
}

class DepositValidation {
  final DepositValidationError error;
  final double? limitAmount;
  final bool isValid;

  const DepositValidation({
    required this.error,
    this.limitAmount,
    required this.isValid,
  });

  const DepositValidation.valid()
    : error = DepositValidationError.none,
      limitAmount = null,
      isValid = true;

  const DepositValidation.errorWith(this.error, {this.limitAmount})
    : isValid = false;

  String? localize(BuildContext context) {
    if (isValid) return null;
    final t = AppLocalizations.of(context);
    switch (error) {
      case DepositValidationError.invalidAmount:
        return t.pix_receive_validation_invalid_amount;
      case DepositValidationError.belowMinimum:
        return t.pix_receive_validation_below_min(
          (limitAmount ?? 0).toStringAsFixed(2),
        );
      case DepositValidationError.aboveTransaction:
        return t.pix_receive_validation_above_transaction(
          (limitAmount ?? 0).toStringAsFixed(2),
        );
      case DepositValidationError.aboveRemaining:
      case DepositValidationError.none:
        return null;
    }
  }
}

final depositValidationProvider = Provider<DepositValidation>((ref) {
  return validatePixReceiveAmount(
    ref.watch(depositAmountProvider),
    ref.watch(levelsProvider),
  );
});

/// Checks [amountBrl] against the Pix receive limits of the account: the
/// minimum and the limit per transaction of [levelsAsync].
///
/// Every screen that receives a Pix uses it, the deposit and the payment
/// links, so they share one rule.
DepositValidation validatePixReceiveAmount(
  double amountBrl,
  AsyncValue<UserLevelsData> levelsAsync,
) {
  final levels = levelsAsync.isLoading || levelsAsync.hasError
      ? null
      : levelsAsync.valueOrNull;

  // While the levels load, or after a load error, the core treats every
  // positive amount as valid.
  final result = CoreSyncHelpers.instance.pixValidateAmount(
    amountBrl: amountBrl,
    limits: levels == null
        ? null
        : DepositLimitsDto(
            absoluteMinLimit: levels.absoluteMinLimit,
            allowedSpending: levels.allowedSpending,
          ),
  );
  if (result.isValid) return const DepositValidation.valid();
  return DepositValidation.errorWith(
    switch (result.error) {
      DepositValidationErrorDto.belowMinimum =>
        DepositValidationError.belowMinimum,
      DepositValidationErrorDto.aboveTransaction =>
        DepositValidationError.aboveTransaction,
      DepositValidationErrorDto.aboveRemaining =>
        DepositValidationError.aboveRemaining,
      DepositValidationErrorDto.invalidAmount ||
      null =>
        DepositValidationError.invalidAmount,
    },
    limitAmount: result.limitAmount,
  );
}
