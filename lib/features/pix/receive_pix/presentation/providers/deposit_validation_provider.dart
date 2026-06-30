import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
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
  final depositAmount = ref.watch(depositAmountProvider);
  final levelsAsync = ref.watch(levelsProvider);

  if (depositAmount <= 0) {
    return const DepositValidation.errorWith(
      DepositValidationError.invalidAmount,
    );
  }

  if (levelsAsync.isLoading) {
    return const DepositValidation.valid();
  }

  if (levelsAsync.hasError) {
    return const DepositValidation.valid();
  }

  return levelsAsync.when(
    data: (levels) {
      if (depositAmount < levels.absoluteMinLimit) {
        return DepositValidation.errorWith(
          DepositValidationError.belowMinimum,
          limitAmount: levels.absoluteMinLimit,
        );
      }

      if (depositAmount > levels.allowedSpending) {
        return DepositValidation.errorWith(
          DepositValidationError.aboveTransaction,
          limitAmount: levels.allowedSpending,
        );
      }

      return const DepositValidation.valid();
    },
    loading: () => const DepositValidation.valid(),
    error: (_, _) => const DepositValidation.valid(),
  );
});
