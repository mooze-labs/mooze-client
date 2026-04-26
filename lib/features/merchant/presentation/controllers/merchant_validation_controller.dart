import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

enum MerchantValidationError {
  none,
  belowMinimum,
  aboveTransaction,
  aboveRemaining,
  invalidAmount,
}

class MerchantValidation {
  final MerchantValidationError error;
  final double? amount;
  final bool isValid;

  const MerchantValidation({
    required this.error,
    this.amount,
    required this.isValid,
  });

  const MerchantValidation.valid()
    : error = MerchantValidationError.none,
      amount = null,
      isValid = true;

  const MerchantValidation.failure(this.error, this.amount) : isValid = false;

  /// Resolves a user-facing message at the call site, where AppLocalizations
  /// is available. Returns null when the validation is valid.
  String? localizedMessage(AppLocalizations t) {
    final value = amount?.toStringAsFixed(2) ?? '';
    return switch (error) {
      MerchantValidationError.belowMinimum =>
        t.merchant_validation_min_amount(value),
      MerchantValidationError.aboveTransaction =>
        t.merchant_validation_max_per_tx(value),
      _ => null,
    };
  }
}

final merchantValidationProvider = Provider.family<MerchantValidation, double>((
  ref,
  totalAmount,
) {
  final levelsAsync = ref.watch(levelsProvider);

  if (levelsAsync.isLoading) {
    return const MerchantValidation.valid();
  }

  if (levelsAsync.hasError) {
    return const MerchantValidation.valid();
  }

  if (totalAmount <= 0) {
    return const MerchantValidation.valid();
  }

  return levelsAsync.when(
    data: (levels) {
      if (totalAmount < levels.absoluteMinLimit) {
        return MerchantValidation.failure(
          MerchantValidationError.belowMinimum,
          levels.absoluteMinLimit,
        );
      }

      if (totalAmount > levels.allowedSpending) {
        return MerchantValidation.failure(
          MerchantValidationError.aboveTransaction,
          levels.allowedSpending,
        );
      }

      return const MerchantValidation.valid();
    },
    loading: () => const MerchantValidation.valid(),
    error: (_, _) => const MerchantValidation.valid(),
  );
});
