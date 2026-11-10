import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder of `UserIdContainerWidget` while the user code loads. It
/// keeps the layout of the loaded panel, so the content does not jump.
class UserIdLoadingSkeleton extends StatelessWidget {
  final ColorScheme colorScheme;

  const UserIdLoadingSkeleton({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;

    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              _ShimmerBox(
                baseColor: baseColor,
                highlightColor: highlightColor,
                width: 20,
                height: 20,
                borderRadius: 6,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      width: 120,
                      height: 12,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    _ShimmerBox(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      width: 180,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _ShimmerBox(
                baseColor: baseColor,
                highlightColor: highlightColor,
                width: 20,
                height: 20,
                borderRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;
  final double? width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.baseColor,
    required this.highlightColor,
    required this.height,
    required this.borderRadius,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
