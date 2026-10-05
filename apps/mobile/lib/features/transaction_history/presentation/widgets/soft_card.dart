import 'package:flutter/material.dart';

/// Shared visual vocabulary — mirrors the send-review screen so transaction
/// detail and review feel like one cohesive design system.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final borderColor =
        isDark
            ? cs.onSurface.withValues(alpha: 0.08)
            : cs.outline.withValues(alpha: 0.55);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            isDark
                ? cs.onSurface.withValues(alpha: 0.05)
                : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
      ),
      child: child,
    );
  }
}
