import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
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

enum SendValidationErrorCategory {
  address,
  network,
  amount,
  balance,
  fee,
  limits,
  unknown,
}

enum SendValidationErrorCode {
  addressRequired,
  addressInvalid,
  assetLiquidOnly,
  liquidOnly,
  amountPositive,
  balanceCheck,
  insufficientBalance,
  addressUnrecognized,
  pendingPayments,
  validationFailed,
  amountExceedsBalance,
  insufficientWithFees,
  feeCalcFailed,
  validateBalanceFees,
  minLightning,
  maxLightning,
  minUsdt,
  minDepix,
  validateLimits,
}

class SendValidationError {
  final SendValidationErrorCode code;
  final SendValidationErrorCategory category;
  final Map<String, Object?> params;

  const SendValidationError({
    required this.code,
    required this.category,
    this.params = const {},
  });

  String localize(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (code) {
      case SendValidationErrorCode.addressRequired:
        return t.wallet_send_error_address_required;
      case SendValidationErrorCode.addressInvalid:
        return t.wallet_send_error_address_invalid;
      case SendValidationErrorCode.assetLiquidOnly:
        return t.wallet_send_error_asset_liquid_only(
          params['asset'] as String? ?? '',
        );
      case SendValidationErrorCode.liquidOnly:
        return t.wallet_send_error_liquid_only;
      case SendValidationErrorCode.amountPositive:
        return t.wallet_send_error_amount_positive;
      case SendValidationErrorCode.balanceCheck:
        return t.wallet_send_error_balance_check;
      case SendValidationErrorCode.insufficientBalance:
        return t.wallet_send_error_insufficient_balance;
      case SendValidationErrorCode.addressUnrecognized:
        return t.wallet_send_error_address_unrecognized;
      case SendValidationErrorCode.pendingPayments:
        return t.wallet_send_error_pending_payments;
      case SendValidationErrorCode.validationFailed:
        return t.wallet_send_error_validation_failed(
          params['error'] as String? ?? '',
        );
      case SendValidationErrorCode.amountExceedsBalance:
        return t.wallet_send_error_amount_exceeds_balance;
      case SendValidationErrorCode.insufficientWithFees:
        return t.wallet_send_error_insufficient_with_fees(
          params['total']?.toString() ?? '',
          params['amount']?.toString() ?? '',
          params['fee']?.toString() ?? '',
          params['satText'] as String? ?? '',
          params['balance']?.toString() ?? '',
        );
      case SendValidationErrorCode.feeCalcFailed:
        return t.wallet_send_error_fee_calc_failed(
          params['error'] as String? ?? '',
        );
      case SendValidationErrorCode.validateBalanceFees:
        return t.wallet_send_error_validate_balance_fees(
          params['error'] as String? ?? '',
        );
      case SendValidationErrorCode.minLightning:
        return t.wallet_send_error_min_lightning(
          (params['amount'] as int?) ?? 0,
        );
      case SendValidationErrorCode.maxLightning:
        return t.wallet_send_error_max_lightning(
          (params['amount'] as int?) ?? 0,
        );
      case SendValidationErrorCode.minUsdt:
        return t.wallet_send_error_min_usdt;
      case SendValidationErrorCode.minDepix:
        return t.wallet_send_error_min_depix;
      case SendValidationErrorCode.validateLimits:
        return t.wallet_send_error_validate_limits(
          params['error'] as String? ?? '',
        );
    }
  }

  @override
  String toString() => '${category.name}:${code.name}';
}

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

    final errors = <SendValidationError>[];

    if (address.isEmpty) {
      _log.warning(_tag, 'Validation failed: address is empty');
      errors.add(
        const SendValidationError(
          code: SendValidationErrorCode.addressRequired,
          category: SendValidationErrorCategory.address,
        ),
      );
    } else if (networkType == NetworkType.unknown) {
      _log.warning(
        _tag,
        'Validation failed: unknown network type for address prefix',
      );
      errors.add(
        const SendValidationError(
          code: SendValidationErrorCode.addressInvalid,
          category: SendValidationErrorCategory.address,
        ),
      );
    }

    if (address.isNotEmpty && networkType != NetworkType.unknown) {
      if (asset != Asset.btc && networkType == NetworkType.bitcoin) {
        _log.warning(
          _tag,
          'Asset/network mismatch: ${asset.ticker} cannot be sent over Bitcoin network',
        );
        errors.add(
          SendValidationError(
            code: SendValidationErrorCode.assetLiquidOnly,
            category: SendValidationErrorCategory.network,
            params: {'asset': asset.name},
          ),
        );
      }

      if (asset == Asset.btc &&
          (networkType == NetworkType.liquid ||
              networkType == NetworkType.lightning)) {
        _log.warning(
          _tag,
          'Asset/network mismatch: BTC cannot be sent over Liquid/Lightning network',
        );
        errors.add(
          const SendValidationError(
            code: SendValidationErrorCode.liquidOnly,
            category: SendValidationErrorCategory.network,
          ),
        );
      }
    }

    if (amount <= 0) {
      _log.warning(_tag, 'Validation failed: amount is $amount (must be > 0)');
      errors.add(
        const SendValidationError(
          code: SendValidationErrorCode.amountPositive,
          category: SendValidationErrorCategory.amount,
        ),
      );
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
            errors.add(
              const SendValidationError(
                code: SendValidationErrorCode.balanceCheck,
                category: SendValidationErrorCategory.balance,
              ),
            );
          },
          (balance) {
            _log.debug(_tag, 'Balance for drain: $balance sats');
            if (balance <= BigInt.zero) {
              _log.warning(
                _tag,
                'Drain validation failed: balance is zero or negative',
              );
              errors.add(
                const SendValidationError(
                  code: SendValidationErrorCode.insufficientBalance,
                  category: SendValidationErrorCategory.balance,
                ),
              );
            }
          },
        );

        if (feeEstimation.hasError) {
          _log.warning(
            _tag,
            'Fee estimation error during drain validation: ${feeEstimation.errorMessage}',
          );
          if (feeEstimation.errorMessage == 'INVALID_ADDRESS') {
            errors.add(
              const SendValidationError(
                code: SendValidationErrorCode.addressUnrecognized,
                category: SendValidationErrorCategory.address,
              ),
            );
          } else if (feeEstimation.errorMessage == 'PENDING_PAYMENTS') {
            errors.add(
              const SendValidationError(
                code: SendValidationErrorCode.pendingPayments,
                category: SendValidationErrorCategory.balance,
              ),
            );
          } else if (feeEstimation.errorMessage != 'INSUFFICIENT_FUNDS') {
            errors.add(
              SendValidationError(
                code: SendValidationErrorCode.validationFailed,
                category: SendValidationErrorCategory.unknown,
                params: {'error': feeEstimation.errorMessage ?? ''},
              ),
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
        errors.add(
          const SendValidationError(
            code: SendValidationErrorCode.balanceCheck,
            category: SendValidationErrorCategory.balance,
          ),
        );
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
    List<SendValidationError> errors,
  ) async {
    if (asset == Asset.btc) {
      try {
        final balanceResult = await ref.read(
          selectedAssetBalanceRawProvider.future,
        );
        balanceResult.fold(
          (_) {},
          (balance) {
            if (BigInt.from(amount) > balance) {
              _log.warning(
                _tag,
                'BTC validation: amount $amount sats exceeds raw balance $balance sats',
              );
              errors.add(
                const SendValidationError(
                  code: SendValidationErrorCode.amountExceedsBalance,
                  category: SendValidationErrorCategory.balance,
                ),
              );
            }
          },
        );
      } catch (e, stackTrace) {
        _log.warning(
          _tag,
          'BTC balance pre-check failed (deferring to SDK): $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
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
          errors.add(
            const SendValidationError(
              code: SendValidationErrorCode.balanceCheck,
              category: SendValidationErrorCategory.balance,
            ),
          );
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
            errors.add(
              const SendValidationError(
                code: SendValidationErrorCode.amountExceedsBalance,
                category: SendValidationErrorCategory.balance,
              ),
            );
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
                SendValidationError(
                  code: SendValidationErrorCode.insufficientWithFees,
                  category: SendValidationErrorCategory.balance,
                  params: {
                    'total': totalNeeded.toString(),
                    'amount': amount.toString(),
                    'fee': feesInSats.toString(),
                    'satText': satText,
                    'balance': balance.toString(),
                  },
                ),
              );
            }
          } else if (feeEstimation.hasError) {
            _log.warning(
              _tag,
              'Fee estimation error during balance validation: ${feeEstimation.errorMessage}',
            );
            if (feeEstimation.errorMessage == 'INSUFFICIENT_FUNDS') {
            } else if (feeEstimation.errorMessage == 'INVALID_ADDRESS') {
              errors.add(
                const SendValidationError(
                  code: SendValidationErrorCode.addressUnrecognized,
                  category: SendValidationErrorCategory.address,
                ),
              );
            } else if (feeEstimation.errorMessage == 'PENDING_PAYMENTS') {
              errors.add(
                const SendValidationError(
                  code: SendValidationErrorCode.pendingPayments,
                  category: SendValidationErrorCategory.balance,
                ),
              );
            } else {
              errors.add(
                SendValidationError(
                  code: SendValidationErrorCode.feeCalcFailed,
                  category: SendValidationErrorCategory.fee,
                  params: {'error': feeEstimation.errorMessage ?? ''},
                ),
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
      errors.add(
        SendValidationError(
          code: SendValidationErrorCode.validateBalanceFees,
          category: SendValidationErrorCategory.balance,
          params: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> _validateAmountLimits(
    Asset asset,
    int amount,
    NetworkType networkType,
    List<SendValidationError> errors,
  ) async {
    if (amount <= 0) {
      return;
    }

    _log.debug(
      _tag,
      'Validating amount limits — asset: ${asset.ticker}, amount: $amount, network: ${networkType.name}',
    );

    try {
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
            errors.add(
              SendValidationError(
                code: SendValidationErrorCode.minLightning,
                category: SendValidationErrorCategory.limits,
                params: {'amount': min},
              ),
            );
          }

          if (max != null && amount > max) {
            _log.warning(
              _tag,
              'Amount $amount sats exceeds Lightning maximum $max sats',
            );
            errors.add(
              SendValidationError(
                code: SendValidationErrorCode.maxLightning,
                category: SendValidationErrorCategory.limits,
                params: {'amount': max},
              ),
            );
          }
        }

        return;
      }

      if (asset == Asset.usdt) {
        const minUsdt = 50000000; // 0.5 USDT
        if (amount < minUsdt) {
          _log.warning(
            _tag,
            'USDT amount $amount is below minimum $minUsdt (0.5 USDT)',
          );
          errors.add(
            const SendValidationError(
              code: SendValidationErrorCode.minUsdt,
              category: SendValidationErrorCategory.limits,
            ),
          );
        }
        return;
      }

      if (asset == Asset.depix) {
        const minDepix = 100000000; // 1 Depix
        if (amount < minDepix) {
          _log.warning(
            _tag,
            'Depix amount $amount is below minimum $minDepix (1.0 Depix)',
          );
          errors.add(
            const SendValidationError(
              code: SendValidationErrorCode.minDepix,
              category: SendValidationErrorCategory.limits,
            ),
          );
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
      errors.add(
        SendValidationError(
          code: SendValidationErrorCode.validateLimits,
          category: SendValidationErrorCategory.limits,
          params: {'error': e.toString()},
        ),
      );
    }
  }

  void clearValidation() {
    _log.debug(_tag, 'Clearing validation state');
    state = const SendValidationState();
  }
}

class SendValidationState {
  final bool isValid;
  final List<SendValidationError> errors;
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
