import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/entities/asset.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';

import '../providers.dart';

class SatoshiAmountDisplay extends ConsumerWidget {
  const SatoshiAmountDisplay({super.key});

  double _getResponsiveFontSize(String text, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = 36.0;
    final minFontSize = 20.0;

    // Calculate approximate text width (rough estimation)
    final textLength = text.length;
    final estimatedWidth =
        textLength * baseFontSize * 0.6; // Approximate character width

    // Available width for text (accounting for padding and other elements)
    final availableWidth = screenWidth - 120; // Padding, asset selector, etc.

    if (estimatedWidth <= availableWidth) {
      return baseFontSize;
    }

    // Calculate new font size
    final newFontSize = (availableWidth / textLength) / 0.6;
    return newFontSize.clamp(minFontSize, baseFontSize);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentValue = ref.watch(satoshiInputProvider);
    final price = ref.watch(priceProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    final assetName = switch (selectedAsset) {
      Asset.btc => 'sats',
      Asset.depix => 'DePix',
      Asset.usdt => 'USDt',
    };

    final amountText = '${currentValue.toString()} $assetName';
    final fontSize = _getResponsiveFontSize(amountText, context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${currentValue.toString()} sats',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: fontSize,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          price.when(
            data:
                (data) => Text(
                  (currentValue == 0)
                      ? '0 USD'
                      : '${((currentValue / 100000000) * data).toStringAsFixed(2)} USD',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
            error: (error, stack) => const SizedBox.shrink(),
            loading:
                () => Shimmer.fromColors(
                  baseColor: Colors.grey,
                  highlightColor: Colors.grey,
                  child: const SizedBox(width: 100, height: 20),
                ),
          ),
        ],
      ),
    );
  }
}

class FiatAmountDisplay extends ConsumerWidget {
  const FiatAmountDisplay({super.key});

  double _getResponsiveFontSize(String text, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = 36.0;
    final minFontSize = 20.0;

    // Calculate approximate text width (rough estimation)
    final textLength = text.length;
    final estimatedWidth =
        textLength * baseFontSize * 0.6; // Approximate character width

    // Available width for text (accounting for padding and other elements)
    final availableWidth = screenWidth - 120; // Padding, asset selector, etc.

    if (estimatedWidth <= availableWidth) {
      return baseFontSize;
    }

    // Calculate new font size
    final newFontSize = (availableWidth / textLength) / 0.6;
    return newFontSize.clamp(minFontSize, baseFontSize);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputString = ref.watch(fiatInputStringProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    final assetName = switch (selectedAsset) {
      Asset.btc => 'BTC',
      Asset.depix => 'DePix',
      Asset.usdt => 'USDt',
    };

    double? value = double.tryParse(inputString);
    final amountText = '${(value ?? 0.0).toStringAsFixed(2)} $assetName';
    final fontSize = _getResponsiveFontSize(amountText, context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${(value ?? 0.0).toStringAsFixed(2)} $assetName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: fontSize,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
