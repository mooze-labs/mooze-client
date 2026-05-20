import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/fee_estimation_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';

class FeeEstimationWidget extends ConsumerWidget {
  const FeeEstimationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asset = ref.watch(selectedAssetProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final validationState = ref.watch(sendValidationControllerProvider);

    if (isDrainTransaction || asset == Asset.btc) {
      return const SizedBox.shrink();
    }


    if (validationState.errors.isNotEmpty) {
      final hasOnlyBalanceErrors = validationState.errors.every(
        (error) => error.category == SendValidationErrorCategory.balance,
      );
      if (!hasOnlyBalanceErrors) return const SizedBox.shrink();
    }

    final feeEstimation = ref.watch(feeEstimationProvider);

    return feeEstimation.when(
      data: (estimation) {
        if (!estimation.isValid || estimation.hasError) {
          return const SizedBox.shrink();
        }
        return _FeeCard(
          label: t.wallet_send_fee_estimated,
          value: _formatFee(estimation.fees, asset, t),
        );
      },
      loading: () => _FeeLoadingCard(label: t.wallet_send_fee_calculating),
      error: (_, _) => _FeeErrorCard(label: t.wallet_send_fee_calc_error),
    );
  }

  String _formatFee(BigInt fees, Asset asset, AppLocalizations t) {
    if (fees == BigInt.zero) return t.wallet_send_fee_free;
    if (asset == Asset.btc || asset == Asset.lbtc) {
      final satText = fees == BigInt.one ? 'sat' : 'sats';
      return '${SatsInputFormatter.formatValue(fees.toInt())} $satText';
    }
    final lbtcAmount = fees.toDouble() / 100000000;
    return '${lbtcAmount.toStringAsFixed(8)} L-BTC';
  }
}

class _FeeCard extends StatelessWidget {
  final String label;
  final String value;

  const _FeeCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _Surface(
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 16,
            color: context.colors.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeLoadingCard extends StatelessWidget {
  final String label;
  const _FeeLoadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Surface(
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeErrorCard extends StatelessWidget {
  final String label;
  const _FeeErrorCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat-card surface — identical recipe to the amount card and balance
/// card, so the fee estimate row sits visually in the same family.
class _Surface extends StatelessWidget {
  final Widget child;
  const _Surface({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}
