import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/period_selector_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/services/price_service.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas Detalhadas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          priceHistory.when(
            data:
                (data) => data.fold(
                  (err) => _buildErrorStats(),
                  (klines) => _buildSuccessStats(klines, ref),
                ),
            error: (_, __) => _buildErrorStats(),
            loading: () => _buildLoadingStats(),
          ),
        ],
      ),
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

  Widget _buildSuccessStats(List<double> klines, WidgetRef ref) {
    final icon = ref.watch(currencyControllerProvider.notifier).icon;
    final current = klines.last;
    final high = klines.reduce((a, b) => a > b ? a : b);
    final low = klines.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        _buildStatRow('Preço Atual', '$icon ${current.toStringAsFixed(2)}'),
        _buildStatRow('Máxima 24h', '$icon ${high.toStringAsFixed(2)}'),
        _buildStatRow('Mínima 24h', '$icon ${low.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildErrorStats() {
    return Column(
      children: [
        _buildStatRow('Preço Atual', 'N/A'),
        _buildStatRow('Máxima 24h', 'N/A'),
        _buildStatRow('Mínima 24h', 'N/A'),
        _buildStatRow('Volume 24h', 'N/A'),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      children: [
        _buildLoadingStatRow(),
        _buildLoadingStatRow(),
        _buildLoadingStatRow(),
        _buildLoadingStatRow(),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.baseColor,
            highlightColor: AppColors.highlightColor,
            child: Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Shimmer.fromColors(
            baseColor: AppColors.baseColor,
            highlightColor: AppColors.highlightColor,
            child: Container(
              width: 60,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
