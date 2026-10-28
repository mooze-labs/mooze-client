import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';

/// Skeleton of the portfolio panel: the allocation bar and legend, then
/// rows in the shape of [AssetTransactionItem].
///
/// The shimmer stops with reduced motion.
class AssetLoading extends StatelessWidget {
  const AssetLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: SkeletonShimmer(
        child: Column(
          children: [
            // Allocation bar and legend.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  SkeletonBox(width: double.infinity, height: 10, radius: 5),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      SkeletonBox(width: 88, height: 12),
                      Spacer(),
                      SkeletonBox(width: 88, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            ...List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AssetTransactionItem.horizontalPadding,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    SkeletonBox.circle(size: AssetTransactionItem.iconSize),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120, height: 16),
                          SizedBox(height: 6),
                          SkeletonBox(width: 80, height: 12),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SkeletonBox(width: 72, height: 16),
                        SizedBox(height: 6),
                        SkeletonBox(width: 48, height: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
