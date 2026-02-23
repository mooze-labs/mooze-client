import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'selected_asset_provider.dart';
import 'amount_provider.dart';
import 'clean_address_provider.dart';
import 'network_detection_provider.dart';
import 'selected_asset_balance_provider.dart';
import 'fee_estimation_provider.dart';
import 'drain_provider.dart';
import '../../../providers/payment_limits_provider.dart';

class SendValidationController extends StateNotifier<SendValidationState> {
  final Ref ref;
  final _log = AppLoggerService();

  static const _tag = 'SendValidation';

  SendValidationController(this.ref) : super(const SendValidationState());

  Future<void> validateTransaction() async {
    final asset = ref.read(selectedAssetProvider);
    final amount = ref.read(finalAmountProvider);
    final address = ref.read(cleanAddressProvider);
    final networkType = ref.read(networkDetectionProvider(address));
    final isDrainTransaction = ref.read(isDrainTransactionProvider);

    _log.debug(
      _tag,
      'Starting transaction validation — asset: ${asset.ticker}, amount: $amount, '
      'network: ${networkType.name}, isDrain: $isDrainTransaction, '
      'address: ${address.isEmpty ? "(empty)" : "${address.substring(0, address.length.clamp(0, 12))}..."}',
    );

    final errors = <String>[];

    if (address.isEmpty) {
      _log.warning(_tag, 'Validation failed: address is empty');
      errors.add('Endereço é obrigatório');
    } else if (networkType == NetworkType.unknown) {
      _log.warning(
        _tag,
        'Validation failed: unknown network type for address prefix',
      );
      errors.add('Endereço inválido ou não suportado');
    }

    if (address.isNotEmpty && networkType != NetworkType.unknown) {
      if (asset != Asset.btc && networkType == NetworkType.bitcoin) {
        _log.warning(
          _tag,
          'Asset/network mismatch: ${asset.ticker} cannot be sent over Bitcoin network',
        );
        errors.add(
          '${asset.name} só pode ser enviado pela rede Liquid ou Lightning',
        );
      }

      if (asset == Asset.btc &&
          (networkType == NetworkType.liquid ||
              networkType == NetworkType.lightning)) {
        _log.warning(
          _tag,
          'Asset/network mismatch: BTC cannot be sent over Liquid/Lightning network',
        );
        errors.add('Para enviar ativos Liquid use Bitcoin L2, Depix ou USDT');
      }
    }

    if (amount <= 0) {
      _log.warning(_tag, 'Validation failed: amount is $amount (must be > 0)');
      errors.add('Valor deve ser maior que zero');
    }

    await _validateAmountLimits(asset, amount, networkType, errors);

    if (errors.isNotEmpty) {
      _log.info(
        _tag,
        'Validation completed with ${errors.length} error(s) before balance check: $errors',
      );
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
        _log.debug(
          _tag,
          'Drain transaction: checking balance and fee estimation',
        );
        final balanceResult = await ref.read(
          selectedAssetBalanceRawProvider.future,
        );

        final feeEstimation = await ref.read(feeEstimationProvider.future);

        balanceResult.fold(
          (error) {
            _log.error(
              _tag,
              'Failed to fetch balance for drain transaction: ${error.description}',
            );
            errors.add('Erro ao verificar saldo disponível');
          },
          (balance) {
            _log.debug(_tag, 'Balance for drain: $balance sats');
            if (balance <= BigInt.zero) {
              _log.warning(
                _tag,
                'Drain validation failed: balance is zero or negative',
              );
              errors.add('Saldo insuficiente');
            }
          },
        );

        if (feeEstimation.hasError) {
          _log.warning(
            _tag,
            'Fee estimation error during drain validation: ${feeEstimation.errorMessage}',
          );
          if (feeEstimation.errorMessage == 'INVALID_ADDRESS') {
            errors.add('Endereço inválido ou não reconhecido');
          } else if (feeEstimation.errorMessage == 'PENDING_PAYMENTS') {
            errors.add(
              'Não é possível enviar o saldo total enquanto há pagamentos pendentes. Aguarde a conclusão dos pagamentos e tente novamente.',
            );
          } else if (feeEstimation.errorMessage != 'INSUFFICIENT_FUNDS') {
            errors.add(
              'Não foi possível validar a transação: ${feeEstimation.errorMessage}',
            );
          }
        } else {
          _log.debug(_tag, 'Drain fee estimation: ${feeEstimation.fees} sats');
        }
      } catch (e, stackTrace) {
        _log.critical(
          _tag,
          'Unexpected error during drain transaction validation',
          error: e,
          stackTrace: stackTrace,
        );
        errors.add('Erro ao verificar saldo disponível');
      }
    }

    if (errors.isEmpty) {
      _log.info(
        _tag,
        'Validation passed — asset: ${asset.ticker}, amount: $amount sats, '
        'network: ${networkType.name}',
      );
    } else {
      _log.info(
        _tag,
        'Validation failed with ${errors.length} error(s): $errors',
      );
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
    if (asset == Asset.btc) {
      _log.debug(
        _tag,
        'Skipping balance+fee validation for BTC (handled by SDK)',
      );
      return;
    }
    try {
      _log.debug(
        _tag,
        'Validating balance with fees — asset: ${asset.ticker}, amount: $amount sats',
      );
      final balanceResult = await ref.read(
        selectedAssetBalanceRawProvider.future,
      );

      final feeEstimation = await ref.read(feeEstimationProvider.future);

      balanceResult.fold(
        (error) {
          _log.error(
            _tag,
            'Failed to fetch ${asset.ticker} balance: ${error.description}',
          );
          errors.add('Erro ao verificar saldo disponível');
        },
        (balance) {
          _log.debug(
            _tag,
            '${asset.ticker} balance: $balance sats, requested: $amount sats',
          );
          if (amount > balance.toInt()) {
            _log.warning(
              _tag,
              'Insufficient balance: requested $amount sats but only $balance sats available',
            );
            errors.add('Valor informado é maior que o saldo disponível');
            return;
          }

          if (feeEstimation.isValid) {
            final totalNeeded = BigInt.from(amount) + feeEstimation.fees;
            _log.debug(
              _tag,
              'Fee estimation: ${feeEstimation.fees} sats — total needed: $totalNeeded sats',
            );

            if (totalNeeded > balance) {
              final feesInSats = feeEstimation.fees.toInt();
              final satText = feesInSats == 1 ? 'sat' : 'sats';

              _log.warning(
                _tag,
                'Insufficient balance after fees: need $totalNeeded sats '
                '($amount + $feesInSats $satText fee), have $balance sats',
              );
              errors.add(
                'Saldo insuficiente. Você precisa de $totalNeeded sats ($amount + $feesInSats $satText de taxa), mas tem apenas $balance sats disponíveis',
              );
            }
          } else if (feeEstimation.hasError) {
            _log.warning(
              _tag,
              'Fee estimation error during balance validation: ${feeEstimation.errorMessage}',
            );
            if (feeEstimation.errorMessage == 'INSUFFICIENT_FUNDS') {
            } else if (feeEstimation.errorMessage == 'INVALID_ADDRESS') {
              errors.add('Endereço inválido ou não reconhecido');
            } else if (feeEstimation.errorMessage == 'PENDING_PAYMENTS') {
              errors.add(
                'Não é possível enviar o saldo total enquanto há pagamentos pendentes. Aguarde a conclusão dos pagamentos e tente novamente.',
              );
            } else {
              errors.add(
                'Não foi possível calcular as taxas: ${feeEstimation.errorMessage}',
              );
            }
          }
        },
      );
    } catch (e, stackTrace) {
      _log.critical(
        _tag,
        'Unexpected error validating balance with fees',
        error: e,
        stackTrace: stackTrace,
      );
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

    _log.debug(
      _tag,
      'Validating amount limits — asset: ${asset.ticker}, amount: $amount, network: ${networkType.name}',
    );

    try {
      // BTC e LBTC
      if (asset == Asset.btc) {
        _log.debug(_tag, 'BTC selected: skipping amount limit validation');
        return;
      }
      if (asset == Asset.lbtc) {
        if (networkType == NetworkType.lightning) {
          _log.debug(_tag, 'Fetching Lightning send limits for L-BTC');
          final lightningLimits = await ref.read(
            lightningSendLimitsProvider.future,
          );

          final min = lightningLimits?.minSat.toInt() ?? 21;
          final max = lightningLimits?.maxSat.toInt();

          _log.debug(_tag, 'Lightning limits — min: $min sats, max: $max sats');

          if (amount < min) {
            _log.warning(
              _tag,
              'Amount $amount sats is below Lightning minimum $min sats',
            );
            errors.add('Valor mínimo para lightning é $min sats');
          }

          if (max != null && amount > max) {
            _log.warning(
              _tag,
              'Amount $amount sats exceeds Lightning maximum $max sats',
            );
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
          _log.warning(
            _tag,
            'USDT amount $amount is below minimum $minUsdt (0.5 USDT)',
          );
          errors.add('Valor mínimo para USDT é 0.5 USDT');
        }
        return;
      }

      // Depix
      if (asset == Asset.depix) {
        const minDepix = 100000000; // 1 Depix
        if (amount < minDepix) {
          _log.warning(
            _tag,
            'Depix amount $amount is below minimum $minDepix (1.0 Depix)',
          );
          errors.add('Valor mínimo para Depix é 1.0 Depix');
        }
        return;
      }
    } catch (e, stackTrace) {
      _log.error(
        _tag,
        'Error validating amount limits for ${asset.ticker}',
        error: e,
        stackTrace: stackTrace,
      );
      errors.add('Erro ao validar limites de envio: $e');
    }
  }

  void clearValidation() {
    _log.debug(_tag, 'Clearing validation state');
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
