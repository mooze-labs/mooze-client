import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

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

const _tag = 'FeeEstimation';

final feeEstimationProvider = FutureProvider<FeeEstimation>((ref) async {
  final log = AppLoggerService();
  final destination = ref.watch(cleanAddressProvider);
  final asset = ref.watch(selectedAssetProvider);
  final blockchain = ref.watch(selectedNetworkProvider);
  final finalAmount = ref.watch(finalAmountProvider);
  final amount = BigInt.from(finalAmount);
  final isDrainTransaction = ref.watch(isDrainTransactionProvider);

  if (destination.isEmpty || amount <= BigInt.zero) {
    log.debug(
      _tag,
      'Skipping fee estimation: destination empty or amount zero '
      '(destination empty: ${destination.isEmpty}, amount: $amount)',
    );
    return FeeEstimation.initial();
  }

  final validationState = ref.watch(sendValidationControllerProvider);
  if (!validationState.canProceed || validationState.errors.isNotEmpty) {
    final hasOnlyBalanceErrors = validationState.errors.every(
      (error) => error.toLowerCase().contains('saldo'),
    );

    if (!hasOnlyBalanceErrors) {
      log.debug(
        _tag,
        'Skipping fee estimation: validation not ready — errors: ${validationState.errors}',
      );
      return FeeEstimation.initial();
    }
  }

  log.debug(
    _tag,
    'Estimating fees — asset: ${asset.ticker}, amount: $amount sats, '
    'blockchain: ${blockchain.name}, isDrain: $isDrainTransaction',
  );

  final walletControllerResult = await ref.watch(
    walletControllerProvider.future,
  );

  return walletControllerResult.fold(
    (error) {
      log.error(
        _tag,
        'Wallet controller unavailable for fee estimation: ${error.description}',
      );
      return FeeEstimation.error(
        "Erro ao acessar carteira: ${error.description}",
      );
    },
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

        return psbtResult.fold(
          (error) {
            final errorLower = error.toLowerCase();
            if (errorLower.contains('insufficient') ||
                errorLower.contains('insuficient') ||
                errorLower.contains('not enough')) {
              log.warning(
                _tag,
                'Fee estimation failed: insufficient funds — raw: $error',
              );
              return FeeEstimation.error('INSUFFICIENT_FUNDS');
            }

            if (errorLower.contains('unrecognized input type') ||
                errorLower.contains('invalid address') ||
                errorLower.contains('invalid input') ||
                errorLower.contains('destination is not valid') ||
                errorLower.contains('invalid destination')) {
              log.warning(
                _tag,
                'Fee estimation failed: invalid address — raw: $error',
              );
              return FeeEstimation.error('INVALID_ADDRESS');
            }

            if (errorLower.contains('cannot drain while') ||
                errorLower.contains('pending payments')) {
              log.warning(
                _tag,
                'Fee estimation failed: pending payments — raw: $error',
              );
              return FeeEstimation.error('PENDING_PAYMENTS');
            }

            log.error(_tag, 'Fee estimation failed with unknown error: $error');
            return FeeEstimation.error(error);
          },
          (psbt) {
            log.info(
              _tag,
              'Fee estimation successful — fees: ${psbt.networkFees} sats, '
              'asset: ${asset.ticker}, amount: $amount sats',
            );
            return FeeEstimation(fees: psbt.networkFees);
          },
        );
      } catch (e, stackTrace) {
        log.critical(
          _tag,
          'Unexpected error during fee estimation',
          error: e,
          stackTrace: stackTrace,
        );
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
