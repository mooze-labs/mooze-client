import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../wallet_provider.dart';
import 'clean_address_provider.dart';
import 'amount_provider.dart';
import 'selected_asset_provider.dart';
import 'selected_network_provider.dart';
import 'drain_provider.dart';
import 'send_validation_controller.dart';

class FeeEstimation {
  final BigInt fees;
  final bool isEstimating;
  final String? errorMessage;

  FeeEstimation({
    required this.fees,
    this.isEstimating = false,
    this.errorMessage,
  });

  FeeEstimation.initial()
    : fees = BigInt.zero,
      isEstimating = false,
      errorMessage = null;

  FeeEstimation.loading()
    : fees = BigInt.zero,
      isEstimating = true,
      errorMessage = null;

  FeeEstimation.error(String message)
    : fees = BigInt.zero,
      isEstimating = false,
      errorMessage = message;

  FeeEstimation copyWith({
    BigInt? fees,
    bool? isEstimating,
    String? errorMessage,
  }) {
    return FeeEstimation(
      fees: fees ?? this.fees,
      isEstimating: isEstimating ?? this.isEstimating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isValid => !hasError && fees > BigInt.zero;
}

final feeEstimationProvider = FutureProvider<FeeEstimation>((ref) async {
  final destination = ref.watch(cleanAddressProvider);
  final asset = ref.watch(selectedAssetProvider);
  final blockchain = ref.watch(selectedNetworkProvider);
  final finalAmount = ref.watch(finalAmountProvider);
  final amount = BigInt.from(finalAmount);
  final isDrainTransaction = ref.watch(isDrainTransactionProvider);

  if (destination.isEmpty || amount <= BigInt.zero) {
    return FeeEstimation.initial();
  }

  final validationState = ref.watch(sendValidationControllerProvider);
  if (!validationState.canProceed || validationState.errors.isNotEmpty) {
    final hasOnlyBalanceErrors = validationState.errors.every(
      (error) => error.toLowerCase().contains('saldo'),
    );

    if (!hasOnlyBalanceErrors) {
      return FeeEstimation.initial();
    }
  }

  final walletControllerResult = await ref.watch(
    walletControllerProvider.future,
  );

  return walletControllerResult.fold(
    (error) =>
        FeeEstimation.error("Erro ao acessar carteira: ${error.description}"),
    (controller) async {
      try {
        final psbtResult =
            isDrainTransaction
                ? await controller
                    .beginDrainTransaction(
                      destination: destination,
                      asset: asset,
                      blockchain: blockchain,
                      amount: amount,
                    )
                    .run()
                : await controller
                    .beginNewTransaction(
                      destination: destination,
                      asset: asset,
                      blockchain: blockchain,
                      amount: amount,
                    )
                    .run();

        return psbtResult.fold((error) {
          final errorLower = error.toLowerCase();
          if (errorLower.contains('insufficient') ||
              errorLower.contains('insuficient') ||
              errorLower.contains('not enough')) {
            return FeeEstimation.error('INSUFFICIENT_FUNDS');
          }

          if (errorLower.contains('unrecognized input type') ||
              errorLower.contains('invalid address') ||
              errorLower.contains('invalid input') ||
              errorLower.contains('destination is not valid') ||
              errorLower.contains('invalid destination')) {
            return FeeEstimation.error('INVALID_ADDRESS');
          }

          if (errorLower.contains('cannot drain while') ||
              errorLower.contains('pending payments')) {
            return FeeEstimation.error('PENDING_PAYMENTS');
          }

          return FeeEstimation.error(error);
        }, (psbt) => FeeEstimation(fees: psbt.networkFees));
      } catch (e) {
        return FeeEstimation.error("Erro ao calcular taxas: $e");
      }
    },
  );
});

final currentFeeEstimationProvider = StateProvider<FeeEstimation>((ref) {
  final asyncFee = ref.watch(feeEstimationProvider);

  return asyncFee.when(
    data: (feeEstimation) => feeEstimation,
    loading: () => FeeEstimation.loading(),
    error: (error, _) => FeeEstimation.error(error.toString()),
  );
});
