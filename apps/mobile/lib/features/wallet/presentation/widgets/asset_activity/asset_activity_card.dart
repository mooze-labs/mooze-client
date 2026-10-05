import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shared, theme-aware presentation primitives for the asset activity screen.
///
/// Borders and separators resolve from [ColorScheme.outline] (the design
/// system's sanctioned divider token) so they stay legible in both light and
/// dark themes — the previous faint `onSurface @ 0.06` hairline disappeared on
/// dark backgrounds.

/// Border/divider color with proper contrast in both themes.
Color assetActivityBorderColor(BuildContext context) =>
    context.colorScheme.outline.withValues(alpha: 0.45);

/// Stronger separator (vertical dividers, timeline connectors).
Color assetActivitySeparatorColor(BuildContext context) =>
    context.colorScheme.outline.withValues(alpha: 0.6);

/// SemiBold section header — the single weight used for titles.
class AssetSectionTitle extends StatelessWidget {
  final String title;

  const AssetSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}

/// A refined surface card: [backgroundCard] fill, a contrast-safe hairline
/// border, and a soft shadow in light mode only. The structural building
/// block for every grouped section.
class AssetSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Color? borderColor;

  const AssetSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.colorScheme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? context.colors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? assetActivityBorderColor(context),
        ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
      ),
      child: child,
    );
  }
}

/// A small, subtly-tinted icon chip — the app's recurring icon treatment
/// (see the PIX screens). Tint is derived from [color] at low alpha so it
/// works on both themes without hardcoding.
class AssetIconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AssetIconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// One metric in the summary strip: a subtle icon, a bold value, and a
/// secondary label.
class AssetSummaryMetric {
  final IconData icon;
  final Color? iconColor;
  final String value;
  final String label;

  const AssetSummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });
}

/// The summary centerpiece: metrics laid out horizontally inside an elevated
/// card, separated by contrast-safe vertical dividers. Each metric leads with
/// a small icon, a prominent bold value, and an uppercase micro-label.
class AssetSummaryStrip extends StatelessWidget {
  final List<AssetSummaryMetric> metrics;

  const AssetSummaryStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final separator = assetActivitySeparatorColor(context);
    final children = <Widget>[];
    for (var i = 0; i < metrics.length; i++) {
      children.add(Expanded(child: _metric(context, metrics[i])));
      if (i != metrics.length - 1) {
        children.add(
          Container(
            width: 1,
            height: 46,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: separator,
          ),
        );
      }
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _metric(BuildContext context, AssetSummaryMetric m) {
    final tint = m.iconColor ?? context.colors.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(m.icon, size: 18, color: tint),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            m.value,
            maxLines: 1,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          m.label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 0.4,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

/// A premium metric card for the highlights section.
///
/// [featured] renders a full-width, horizontally-laid headline metric (the
/// primary insight); the default compact form is a vertical block sized for a
/// two-up row (secondary metrics).
class AssetMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool featured;

  const AssetMetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    if (featured) {
      return Row(
        children: [
          AssetIconChip(icon: icon, color: iconColor, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssetIconChip(icon: icon, color: iconColor, size: 36),
        const SizedBox(height: 14),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}
