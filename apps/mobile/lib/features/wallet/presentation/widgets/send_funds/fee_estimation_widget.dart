import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/fee_estimation_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import 'send_flow_parts.dart';

/// The estimated network fee, as one quiet row on the page.
///
/// It shows a small spinner while the fee loads, and an alert icon with a
/// message when the estimate fails.
class FeeEstimationWidget extends ConsumerWidget {
  const FeeEstimationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizeFadeSwitcher(child: _content(context, ref));
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    const none = SizedBox(key: ValueKey('none'), width: double.infinity);
    final t = AppLocalizations.of(context);
    final asset = ref.watch(selectedAssetProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final validationState = ref.watch(sendValidationControllerProvider);

    if (isDrainTransaction || asset == Asset.btc) {
      return none;
    }

    if (validationState.errors.isNotEmpty) {
      final hasOnlyBalanceErrors = validationState.errors.every(
        (error) => error.category == SendValidationErrorCategory.balance,
      );
      if (!hasOnlyBalanceErrors) return none;
    }

    final feeEstimation = ref.watch(feeEstimationProvider);

    return feeEstimation.when(
      data: (estimation) {
        if (!estimation.isValid || estimation.hasError) {
          return none;
        }
        return _FeeRow(
          key: const ValueKey('fee'),
          label: t.wallet_send_fee_estimated,
          value: _formatFee(estimation.fees, asset, t),
        );
      },
      loading: () => _FeeLoadingRow(
        key: const ValueKey('loading'),
        label: t.wallet_send_fee_calculating,
      ),
      error: (_, _) => _FeeErrorRow(
        key: const ValueKey('error'),
        label: t.wallet_send_fee_calc_error,
      ),
    );
  }

  String _formatFee(BigInt fees, Asset asset, AppLocalizations t) {
    if (fees == BigInt.zero) return t.wallet_send_fee_free;
    if (asset == Asset.btc || asset == Asset.lbtc) {
      final satText = fees == BigInt.one ? 'sat' : 'sats';
      return '${SatsInputFormatter.formatValue(fees.toInt())} $satText';
    }
    final lbtcAmount = fees;
    return '$lbtcAmount Sats (L-BTC)';
  }
}

/// Spacing above the fee row, so it sits apart from the amount.
const _rowPadding = EdgeInsets.only(top: 18);

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;

  const _FeeRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _rowPadding,
      child: MergeSemantics(
        child: Row(
          children: [
            PixIcon(
              PixIcons.receipt,
              size: 16,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: sendTabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeLoadingRow extends StatelessWidget {
  final String label;
  const _FeeLoadingRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _rowPadding,
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeErrorRow extends StatelessWidget {
  final String label;
  const _FeeErrorRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.negativeColor;
    return Padding(
      padding: _rowPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: PixIcon(PixIcons.warning, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
