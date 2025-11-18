import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'selected_asset_provider.dart';
import 'amount_provider.dart';
import 'address_provider.dart';
import 'network_detection_provider.dart';
import 'selected_asset_balance_provider.dart';
import 'fee_estimation_provider.dart';
import 'drain_provider.dart';
import '../../../providers/payment_limits_provider.dart';

class SendValidationController extends StateNotifier<SendValidationState> {
  final Ref ref;

  SendValidationController(this.ref) : super(const SendValidationState());

  Future<void> validateTransaction() async {
    final asset = ref.read(selectedAssetProvider);
    final amount = ref.read(finalAmountProvider);
    final address = ref.read(addressStateProvider);
    final networkType = ref.read(networkDetectionProvider(address));
    final isDrainTransaction = ref.read(isDrainTransactionProvider);

    final errors = <String>[];

    if (address.isEmpty) {
      errors.add('Endereço é obrigatório');
    } else if (networkType == NetworkType.unknown) {
      errors.add('Endereço inválido ou não suportado');
    }

    if (address.isNotEmpty && networkType != NetworkType.unknown) {
      if (asset != Asset.btc && networkType == NetworkType.bitcoin) {
        errors.add(
          '${asset.name} só pode ser enviado pela rede Liquid ou Lightning',
        );
      }
    }

    if (amount <= 0) {
      errors.add('Valor deve ser maior que zero');
    }

    await _validateAmountLimits(asset, amount, networkType, errors);

    if (errors.isNotEmpty) {
      state = SendValidationState(
        isValid: false,
        errors: errors,
        canProceed: false,
      );
      return;
    }

    if (!isDrainTransaction) {
      await _validateBalanceWithFees(asset, amount, errors);
    } else {
      try {
        final balanceResult = await ref.read(
          selectedAssetBalanceRawProvider.future,
        );

        final feeEstimation = await ref.read(feeEstimationProvider.future);

        balanceResult.fold(
          (error) => errors.add('Erro ao verificar saldo disponível'),
          (balance) {
            if (balance <= BigInt.zero) {
              errors.add('Saldo insuficiente');
            }
          },
        );

        if (feeEstimation.hasError) {
          if (feeEstimation.errorMessage == 'INVALID_ADDRESS') {
            errors.add('Endereço inválido ou não reconhecido');
          } else if (feeEstimation.errorMessage != 'INSUFFICIENT_FUNDS') {
            errors.add(
              'Não foi possível validar a transação: ${feeEstimation.errorMessage}',
            );
          }
        }
      } catch (e) {
        errors.add('Erro ao verificar saldo disponível');
      }
    }

    state = SendValidationState(
      isValid: errors.isEmpty,
      errors: errors,
      canProceed: errors.isEmpty && address.isNotEmpty && amount > 0,
    );
  }

  Future<void> _validateBalanceWithFees(
    Asset asset,
    int amount,
    List<String> errors,
  ) async {
    try {
      final balanceResult = await ref.read(
        selectedAssetBalanceRawProvider.future,
      );

      final feeEstimation = await ref.read(feeEstimationProvider.future);

      balanceResult.fold(
        (error) => errors.add('Erro ao verificar saldo disponível'),
        (balance) {
          if (amount > balance.toInt()) {
            errors.add('Valor informado é maior que o saldo disponível');
            return;
          }

          if (feeEstimation.isValid) {
            final totalNeeded = BigInt.from(amount) + feeEstimation.fees;

            if (totalNeeded > balance) {
              final feesInSats = feeEstimation.fees.toInt();
              final satText = feesInSats == 1 ? 'sat' : 'sats';

              errors.add(
                'Saldo insuficiente. Você precisa de $totalNeeded sats (${amount} + $feesInSats $satText de taxa), mas tem apenas ${balance} sats disponíveis',
              );
            }
          } else if (feeEstimation.hasError) {
            if (feeEstimation.errorMessage == 'INSUFFICIENT_FUNDS') {
            } else if (feeEstimation.errorMessage == 'INVALID_ADDRESS') {
              errors.add('Endereço inválido ou não reconhecido');
            } else {
              errors.add(
                'Não foi possível calcular as taxas: ${feeEstimation.errorMessage}',
              );
            }
          }
        },
      );
    } catch (e) {
      errors.add('Erro ao validar saldo e taxas: $e');
    }
  }

  Future<void> _validateAmountLimits(
    Asset asset,
    int amount,
    NetworkType networkType,
    List<String> errors,
  ) async {
    if (amount <= 0) {
      return;
    }

    try {
      // BTC e LBTC
      if (asset == Asset.btc || asset == Asset.lbtc) {
        if (networkType == NetworkType.lightning) {
          final lightningLimits = await ref.read(
            lightningSendLimitsProvider.future,
          );

          final min = lightningLimits?.minSat.toInt() ?? 21;
          final max = lightningLimits?.maxSat.toInt();

          if (amount < min) {
            errors.add('Valor mínimo para lightning é $min sats');
          }

          if (max != null && amount > max) {
            errors.add('Valor máximo para lightning é $max sats');
          }
        }

        // networkType == bitcoin ⇒ no extra validation
        return;
      }

      // USDT
      if (asset == Asset.usdt) {
        const minUsdt = 50000000; // 0.5 USDT
        if (amount < minUsdt) {
          errors.add('Valor mínimo para USDT é 0.5 USDT');
        }
        return;
      }

      // Depix
      if (asset == Asset.depix) {
        const minDepix = 100000000; // 1 Depix
        if (amount < minDepix) {
          errors.add('Valor mínimo para Depix é 1.0 Depix');
        }
        return;
      }
    } catch (e) {
      errors.add('Erro ao validar limites de envio: $e');
    }
  }

  void clearValidation() {
    state = const SendValidationState();
  }
}

class SendValidationState {
  final bool isValid;
  final List<String> errors;
  final bool canProceed;

  const SendValidationState({
    this.isValid = false,
    this.errors = const [],
    this.canProceed = false,
  });
}

final sendValidationControllerProvider =
    StateNotifierProvider<SendValidationController, SendValidationState>((ref) {
      return SendValidationController(ref);
    });
