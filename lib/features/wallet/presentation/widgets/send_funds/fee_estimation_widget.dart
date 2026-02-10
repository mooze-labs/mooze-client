import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';

import '../../providers/send_funds/fee_estimation_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';

class FeeEstimationWidget extends ConsumerWidget {
  const FeeEstimationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(selectedAssetProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final validationState = ref.watch(sendValidationControllerProvider);

    if (isDrainTransaction) {
      return const SizedBox.shrink();
    }

    if (asset == Asset.btc) {
      return const SizedBox.shrink();
    }

    if (validationState.errors.isNotEmpty) {
      final hasOnlyBalanceErrors = validationState.errors.every(
        (error) => error.toLowerCase().contains('saldo'),
      );

      if (!hasOnlyBalanceErrors) {
        return const SizedBox.shrink();
      }
    }

    final feeEstimation = ref.watch(feeEstimationProvider);

    return feeEstimation.when(
      data: (estimation) {
        if (!estimation.isValid && !estimation.hasError) {
          return const SizedBox.shrink();
        }

        if (estimation.hasError) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          margin: EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taxa estimada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFee(estimation.fees, asset),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Calculando taxa...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
      error: (error, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erro ao calcular taxa',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFee(BigInt fees, Asset asset) {
    if (asset == Asset.btc || asset == Asset.lbtc) {
      if (fees == BigInt.zero) {
        return "Gratuito";
      }
      final satText = fees == BigInt.one ? 'sat' : 'sats';
      return "${SatsInputFormatter.formatValue(fees.toInt())} $satText";
    } else {
      if (fees == BigInt.zero) {
        return "Gratuito";
      }
      final lbtcAmount = fees.toDouble() / 100000000;
      return "${lbtcAmount.toStringAsFixed(8)} L-BTC";
    }
  }
}
