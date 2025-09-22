import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class AssetHeaderWidget extends ConsumerWidget {
  final Asset asset;

  const AssetHeaderWidget({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = ref.watch(currencyControllerProvider.notifier).icon;
    final priceHistory = ref.watch(assetPriceHistoryProvider(asset));

    // Usar o fiatPriceProvider que já tem cache integrado do HybridPriceService
    final priceAsync = ref.watch(fiatPriceProvider(asset));
    final isUsingCache = ref.watch(isUsingCacheProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.2),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isUsingCache
                  ? Colors.orange.withOpacity(0.5)
                  : AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Indicador de cache no topo se offline
          if (isUsingCache) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_bolt, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Dados offline',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Usar o preço do cache que já tem fallback automático
                  priceAsync.when(
                    data:
                        (priceResult) => priceResult.fold(
                          (error) => _buildErrorPrice(),
                          (price) => _buildCurrentPrice(icon, price),
                        ),
                    loading: () => _buildLoadingPrice(),
                    error: (_, __) => _buildErrorPrice(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(asset.iconPath, width: 48, height: 48),
              ),
            ],
          ),
          const SizedBox(height: 16),
          priceHistory.when(
            data:
                (data) => data.fold(
                  (err) => _buildErrorChange(),
                  (klines) => _buildPriceChange(klines, ref),
                ),
            error: (_, __) => _buildErrorChange(),
            loading: () => _buildLoadingChange(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPrice(String icon, double price) {
    return Text(
      '$icon ${price.toStringAsFixed(2)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildErrorPrice() {
    return const Text(
      'N/A',
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLoadingPrice() {
    return Shimmer.fromColors(
      baseColor: AppColors.baseColor,
      highlightColor: AppColors.highlightColor,
      child: Container(
        width: 120,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.baseColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPriceChange(List<double> klines, WidgetRef ref) {
    final percentage = ((klines.last - klines.first) / klines.first) * 100;
    final isPositive = klines.last > klines.first;
    final change = klines.last - klines.first;
    final icon = ref.watch(currencyControllerProvider.notifier).icon;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isPositive
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPositive ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${percentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${isPositive ? '+' : ''}$icon ${change.toStringAsFixed(2)} (24h)',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLoadingChange() {
    return Shimmer.fromColors(
      baseColor: AppColors.baseColor,
      highlightColor: AppColors.highlightColor,
      child: Container(
        width: 150,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.baseColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildErrorChange() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove, color: Colors.grey, size: 16),
          SizedBox(width: 4),
          Text(
            'N/A',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
