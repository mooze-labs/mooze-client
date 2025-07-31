import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../consts.dart';

class PercentageTagDisplay extends ConsumerWidget {
  final Asset asset;

  const PercentageTagDisplay({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = ref.watch(assetPercentageVariationProvider(asset));
    
    return percentage.when(
      data: (data) => data.fold(
        (err) => ErrorPercentageTagDisplay(),
        (val) => SuccessfulPercentageTagDisplay(percentage: val)
      ),
      error: (err, stackTrace) => ErrorPercentageTagDisplay(),
      loading: () => LoadingPercentageTagDisplay()
    );
  }
}

class SuccessfulPercentageTagDisplay extends StatelessWidget {
  final double percentage;

  const SuccessfulPercentageTagDisplay({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = (percentage > 0) ? positiveValueColor : negativeValueColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        "${percentage > 0 ? '+' : '-'}${percentage.toStringAsFixed(2)}%",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500
        )
      ),
    );
  }
}

class ErrorPercentageTagDisplay extends StatelessWidget {
  const ErrorPercentageTagDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        "N/A",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500
        )
      ),
    );
  }
}

class LoadingPercentageTagDisplay extends StatelessWidget {
  const LoadingPercentageTagDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 60,
        height: 22,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class PercentageTag extends StatelessWidget {
  final double percentage;

  const PercentageTag({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = (percentage > 0) ? positiveValueColor : negativeValueColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        "${percentage > 0 ? '+' : ''}${percentage.toStringAsFixed(2)}%",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500
        )
      ),
    );
  }
}