import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/presentation/providers/deposit_amount_provider.dart';
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
  final String? message;
  final bool isValid;

  const DepositValidation({
    required this.error,
    this.message,
    required this.isValid,
  });

  const DepositValidation.valid()
    : error = DepositValidationError.none,
      message = null,
      isValid = true;

  const DepositValidation.error(this.error, this.message) : isValid = false;
}

final depositValidationProvider = Provider<DepositValidation>((ref) {
  final depositAmount = ref.watch(depositAmountProvider);
  final levelsAsync = ref.watch(levelsProvider);

  if (depositAmount <= 0) {
    return DepositValidation.error(
      DepositValidationError.invalidAmount,
      'Digite um valor válido',
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
        return DepositValidation.error(
          DepositValidationError.belowMinimum,
          'Valor mínimo: R\$ ${levels.absoluteMinLimit.toStringAsFixed(2)}',
        );
      }

      if (depositAmount > levels.allowedSpending) {
        return DepositValidation.error(
          DepositValidationError.aboveTransaction,
          'Limite por transação: R\$ ${levels.allowedSpending.toStringAsFixed(2)}',
        );
      }

      return const DepositValidation.valid();
    },
    loading: () => const DepositValidation.valid(),
    error: (_, __) => const DepositValidation.valid(),
  );
});
