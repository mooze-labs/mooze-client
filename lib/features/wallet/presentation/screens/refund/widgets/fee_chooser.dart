import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Widget to display and choose between different fee options
class FeeChooser extends StatelessWidget {
  final int amountSat;
  final List<RefundFeeOption> feeOptions;
  final int selectedFeeIndex;
  final Function(int) onSelect;

  const FeeChooser({
    super.key,
    required this.amountSat,
    required this.feeOptions,
    required this.selectedFeeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Get affordable options
    final affordableFees =
        feeOptions
            .where((f) => f.isAffordable(feeCoverageSat: amountSat))
            .toList();

    if (affordableFees.isEmpty) {
      return Center(
        child: Text(
          t.refund_amount_too_small_short,
          style: TextStyle(color: context.colors.textPrimary),
        ),
      );
    }

    // Define fee labels based on position
    final labels = _getFeeLabels(t, affordableFees.length);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Text(
            t.refund_speed_select_title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ...List.generate(affordableFees.length, (index) {
          final feeOption = affordableFees[index];
          final isSelected = index == selectedFeeIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildFeeOptionCard(
              context,
              label: labels[index]['label']!,
              estimatedTime: labels[index]['time']!,
              feeRate: feeOption.feeRateSatPerVbyte.toInt(),
              txFee: feeOption.txFeeSat.toInt(),
              isSelected: isSelected,
              onTap: () => onSelect(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeeOptionCard(
    BuildContext context, {
    required String label,
    required String estimatedTime,
    required int feeRate,
    required int txFee,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? context.colors.primaryColor.withValues(alpha: 0.1)
                  : context.colors.backgroundCard,
          border: Border.all(
            color: isSelected ? context.colors.primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: context.colors.primaryColor,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              estimatedTime,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).refund_fee_rate(feeRate),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  ).refund_fee_total(_formatSats(txFee)),
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getFeeLabels(AppLocalizations t, int count) {
    if (count == 1) {
      return [
        {'label': t.refund_fee_label_standard, 'time': t.refund_fee_time_1h},
      ];
    } else if (count == 2) {
      return [
        {'label': t.refund_fee_label_economy, 'time': t.refund_fee_time_24h},
        {'label': t.refund_fee_label_fast, 'time': t.refund_fee_time_30m},
      ];
    } else if (count == 3) {
      return [
        {'label': t.refund_fee_label_economy, 'time': t.refund_fee_time_24h},
        {'label': t.refund_fee_label_standard, 'time': t.refund_fee_time_1h},
        {'label': t.refund_fee_label_fast, 'time': t.refund_fee_time_30m},
      ];
    } else {
      // 4 or more options
      return [
        {'label': t.refund_fee_label_economy, 'time': t.refund_fee_time_24h},
        {'label': t.refund_fee_label_standard, 'time': t.refund_fee_time_1h},
        {'label': t.refund_fee_label_fast, 'time': t.refund_fee_time_30m},
        {'label': t.refund_fee_label_urgent, 'time': t.refund_fee_time_10m},
      ];
    }
  }

  String _formatSats(int sats) {
    return sats.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
