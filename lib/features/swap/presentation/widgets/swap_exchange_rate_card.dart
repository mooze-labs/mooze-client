import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;

class SwapExchangeRateCard extends StatelessWidget {
  final double? exchangeRate;
  final core.Asset fromAsset;
  final core.Asset toAsset;

  const SwapExchangeRateCard({
    super.key,
    required this.exchangeRate,
    required this.fromAsset,
    required this.toAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (exchangeRate == null) return const SizedBox.shrink();

    String formattedRate;
    if (exchangeRate! >= 1) {
      formattedRate = exchangeRate!.toStringAsFixed(2);
    } else if (exchangeRate! >= 0.01) {
      formattedRate = exchangeRate!.toStringAsFixed(4);
    } else {
      formattedRate = exchangeRate!.toStringAsFixed(8);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Taxa de câmbio',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            '1 ${fromAsset.ticker} = $formattedRate ${toAsset.ticker}',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
