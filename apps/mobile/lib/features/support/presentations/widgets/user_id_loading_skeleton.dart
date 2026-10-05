import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

class UserIdLoadingSkeleton extends StatelessWidget {
  final ColorScheme colorScheme;

  const UserIdLoadingSkeleton({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _ShimmerBox(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  width: 20,
                  height: 20,
                  borderRadius: 6,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ShimmerBox(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    height: 14,
                    borderRadius: 4,
                  ),
                ),
                const SizedBox(width: 8),
                _ShimmerBox(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  width: 20,
                  height: 20,
                  borderRadius: 6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: _ShimmerBox(
                baseColor: baseColor,
                highlightColor: highlightColor,
                width: 160,
                height: 14,
                borderRadius: 4,
              ),
            ),
          ],
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
