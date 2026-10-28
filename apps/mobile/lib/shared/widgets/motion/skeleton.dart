import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

/// Runs one shimmer over all skeleton shapes in [child].
///
/// One cycle takes [Motion.durationShimmer]. With reduced motion, the
/// skeleton stays static.
class SkeletonShimmer extends StatelessWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.baseColor,
      highlightColor: context.colors.highlightColor,
      period: Motion.durationShimmer,
      enabled: !Motion.isReduced(context),
      child: child,
    );
  }
}

/// A skeleton placeholder in the shape of the final content.
///
/// Put it inside a [SkeletonShimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 4,
  });

  /// A circle with the given [size].
  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = size / 2;

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
