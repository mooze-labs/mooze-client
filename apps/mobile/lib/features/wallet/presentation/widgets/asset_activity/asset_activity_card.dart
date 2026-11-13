import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shared presentation pieces of the asset activity sheet.
///
/// The sheet is a floating glass sheet. Its panels are glass lenses on that
/// glass, as the deal card of the swap sheet, and their icons are the app
/// icons ([PixIcons]) in round wells, as in the Pix screens.

/// Corner radius of a panel of the sheet.
const double assetActivityPanelRadius = 20;

/// The title of a section of the sheet. The single weight of the titles.
class AssetSectionTitle extends StatelessWidget {
  final String title;

  const AssetSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// A panel of the sheet: a glass lens on the sheet glass, with [child] on
/// top. The lens takes the fill, the soft shadow and the rim of the glass
/// style, so it reads in both themes.
class AssetGlassLens extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const AssetGlassLens({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(assetActivityPanelRadius),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: GlassLens(borderRadius: borderRadius)),
        Padding(padding: padding, child: child),
      ],
    );
  }
}

/// A hairline that separates the parts of a panel.
class AssetPanelDivider extends StatelessWidget {
  const AssetPanelDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppSurfaces.hairline(context),
    );
  }
}

/// One metric of the summary strip.
class AssetSummaryMetric {
  /// The app icon of the metric. Its shape tells the direction.
  final PixIconData icon;

  /// The tint of the well. [PixTone.positive] marks what came in.
  final PixTone tone;
  final String value;
  final String label;

  const AssetSummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.tone = PixTone.neutral,
  });
}

/// The metrics of the summary side by side, split by hairlines. Each one
/// shows its icon well, its value, and its label, and reads as one to a
/// screen reader.
class AssetSummaryStrip extends StatelessWidget {
  final List<AssetSummaryMetric> metrics;

  const AssetSummaryStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < metrics.length; i++) {
      if (i > 0) {
        children.add(
          VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 4,
            endIndent: 4,
            color: AppSurfaces.hairline(context),
          ),
        );
      }
      children.add(Expanded(child: _Metric(metric: metrics[i])));
    }
    return IntrinsicHeight(child: Row(children: children));
  }
}

class _Metric extends StatelessWidget {
  final AssetSummaryMetric metric;

  const _Metric({required this.metric});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            ExcludeSemantics(
              child: PixIconWell(
                icon: metric.icon,
                tone: metric.tone,
                size: 36,
              ),
            ),
            const SizedBox(height: 8),
            // A large amount shrinks to the width of its column.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                metric.value,
                maxLines: 1,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              metric.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
