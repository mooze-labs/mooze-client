import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String? message;
  final bool isValid;

  const MerchantValidation({
    required this.error,
    this.message,
    required this.isValid,
  });

  const MerchantValidation.valid()
    : error = MerchantValidationError.none,
      message = null,
      isValid = true;

  const MerchantValidation.error(this.error, this.message) : isValid = false;
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
        return MerchantValidation.error(
          MerchantValidationError.belowMinimum,
          'Valor mínimo: R\$ ${levels.absoluteMinLimit.toStringAsFixed(2)}',
        );
      }

      if (totalAmount > levels.allowedSpending) {
        return MerchantValidation.error(
          MerchantValidationError.aboveTransaction,
          'Limite por transação: R\$ ${levels.allowedSpending.toStringAsFixed(2)}',
        );
      }

      return const MerchantValidation.valid();
    },
    loading: () => const MerchantValidation.valid(),
    error: (_, __) => const MerchantValidation.valid(),
  );
});
