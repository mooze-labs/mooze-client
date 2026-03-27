import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/period_selector_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/services/price_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

class AssetStatsWidget extends ConsumerWidget {
  final Asset asset;
  final TimePeriod selectedPeriod;

  const AssetStatsWidget({
    super.key,
    required this.asset,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = _getParamsForPeriod(selectedPeriod, asset);
    final priceHistory = ref.watch(assetPriceHistoryWithPeriodProvider(params));

    return priceHistory.when(
      data:
          (data) => data.fold(
            (_) => _buildErrorStats(context),
            (klines) => _buildSuccessStats(context, klines, ref),
          ),
      error: (_, _) => _buildErrorStats(context),
      loading: () => _buildLoadingStats(context),
    );
  }

  AssetPriceHistoryParams _getParamsForPeriod(TimePeriod period, Asset asset) {
    switch (period) {
      case TimePeriod.day:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.oneHour,
          periodInDays: 1,
        );
      case TimePeriod.week:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.fourHours,
          periodInDays: 7,
        );
      case TimePeriod.month:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.oneDay,
          periodInDays: 30,
        );
    }
  }

  static final _numberFormat = NumberFormat('#,##0.00', 'en_US');

  Widget _buildSuccessStats(
    BuildContext context,
    List<double> klines,
    WidgetRef ref,
  ) {
    final icon = ref.watch(currencyControllerProvider.notifier).icon;
    final current = klines.last;
    final high = klines.reduce((a, b) => a > b ? a : b);
    final low = klines.reduce((a, b) => a < b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Máxima',
            value: '$icon ${_numberFormat.format(high)}',
            icon: Icons.arrow_upward_rounded,
            iconColor: context.colors.positiveColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Mínima',
            value: '$icon ${_numberFormat.format(low)}',
            icon: Icons.arrow_downward_rounded,
            iconColor: context.colors.negativeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Atual',
            value: '$icon ${_numberFormat.format(current)}',
            icon: Icons.radio_button_checked_rounded,
            iconColor: context.colors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildLoadingCard(context)),
        const SizedBox(width: 12),
        Expanded(child: _buildLoadingCard(context)),
        const SizedBox(width: 12),
        Expanded(child: _buildLoadingCard(context)),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.baseColor,
      highlightColor: context.colors.highlightColor,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: context.colors.baseColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Máxima',
            value: 'N/A',
            icon: Icons.arrow_upward_rounded,
            iconColor: context.colors.positiveColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Mínima',
            value: 'N/A',
            icon: Icons.arrow_downward_rounded,
            iconColor: context.colors.negativeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Atual',
            value: 'N/A',
            icon: Icons.radio_button_checked_rounded,
            iconColor: context.colors.primaryColor,
          ),
        ),
      ],
    );
  }
}
