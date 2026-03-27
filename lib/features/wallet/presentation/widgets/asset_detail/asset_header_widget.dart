import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

class AssetHeaderWidget extends ConsumerWidget {
  final Asset asset;

  const AssetHeaderWidget({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;
    final priceAsync = ref.watch(fiatPriceProvider(asset));
    final priceHistory = ref.watch(assetPriceHistoryProvider(asset));
    final isUsingCache = ref.watch(isUsingCacheProvider);

    final colorScheme = context.colorScheme;
    final warning = context.appColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUsingCache) ...[
          _buildOfflineBadge(context, warning),
          const SizedBox(height: 16),
        ],

        // Asset identity row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SvgPicture.asset(asset.iconPath, width: 32, height: 32),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  asset.ticker,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Price hero
        priceAsync.when(
          data: (result) => result.fold(
            (_) => _buildErrorPrice(context),
            (price) => _buildCurrentPrice(context, currencyIcon, price),
          ),
          loading: () => _buildLoadingPrice(context),
          error: (_, _) => _buildErrorPrice(context),
        ),

        const SizedBox(height: 10),

        // Change row
        priceHistory.when(
          data: (data) => data.fold(
            (_) => _buildErrorChange(context),
            (klines) => _buildPriceChange(context, klines, ref),
          ),
          error: (_, _) => _buildErrorChange(context),
          loading: () => _buildLoadingChange(context),
        ),
      ],
    );
  }

  Widget _buildOfflineBadge(BuildContext context, Color warning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, color: warning, size: 14),
          const SizedBox(width: 6),
          Text(
            'Dados offline',
            style: context.textTheme.labelSmall?.copyWith(
              color: warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static final _numberFormat = NumberFormat('#,##0.00', 'en_US');

  Widget _buildCurrentPrice(BuildContext context, String icon, double price) {
    return Text(
      '$icon ${_numberFormat.format(price)}',
      style: context.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildErrorPrice(BuildContext context) {
    return Text(
      'N/A',
      style: context.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: context.colors.textSecondary,
      ),
    );
  }

  Widget _buildLoadingPrice(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.baseColor,
      highlightColor: context.colors.highlightColor,
      child: Container(
        width: 180,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.baseColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPriceChange(
    BuildContext context,
    List<double> klines,
    WidgetRef ref,
  ) {
    final percentage = ((klines.last - klines.first) / klines.first) * 100;
    final isPositive = klines.last >= klines.first;
    final change = klines.last - klines.first;
    final icon = ref.watch(currencyControllerProvider.notifier).icon;
    final lineColor = isPositive
        ? context.colors.positiveColor
        : context.colors.negativeColor;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: lineColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: lineColor,
                size: 20,
              ),
              Text(
                '${isPositive ? '+' : ''}${percentage.toStringAsFixed(2)}%',
                style: context.textTheme.labelLarge?.copyWith(
                  color: lineColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${isPositive ? '+' : ''}$icon ${_numberFormat.format(change.abs())}',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '24h',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingChange(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.baseColor,
      highlightColor: context.colors.highlightColor,
      child: Container(
        width: 150,
        height: 30,
        decoration: BoxDecoration(
          color: context.colors.baseColor,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildErrorChange(BuildContext context) {
    final outline = context.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove, color: outline, size: 14),
          const SizedBox(width: 4),
          Text(
            'N/A',
            style: context.textTheme.labelLarge?.copyWith(
              color: outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
