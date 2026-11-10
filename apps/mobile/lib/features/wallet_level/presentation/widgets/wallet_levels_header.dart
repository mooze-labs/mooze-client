import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Hero of the wallet levels screen.
///
/// It sits on the screen backdrop, without a card: a chart glyph in a glass
/// lens well, the title, and the subtitle in muted text.
class WalletLevelsHeader extends StatelessWidget {
  final bool isLoading;

  const WalletLevelsHeader({super.key, this.isLoading = false});

  static const double _wellSize = 64;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (isLoading) {
      return _buildLoadingHeader(context);
    }

    return Column(
      children: [
        Container(
          width: _wellSize,
          height: _wellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GlassStyle.of(context).lensFill,
            border: Border.all(color: AppSurfaces.hairline(context)),
          ),
          child: Icon(
            Icons.auto_graph_rounded,
            size: _wellSize / 2,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            t.wallet_levels_header_title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.wallet_levels_header_subtitle,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHeader(BuildContext context) {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;

    Widget box(double width, double height, {BoxShape? shape}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape ?? BoxShape.rectangle,
          borderRadius: shape == null
              ? BorderRadius.circular(height / 2)
              : null,
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: Motion.durationShimmer,
      enabled: !Motion.isReduced(context),
      child: Column(
        children: [
          box(_wellSize, _wellSize, shape: BoxShape.circle),
          const SizedBox(height: 20),
          box(200, 22),
          const SizedBox(height: 10),
          box(240, 14),
        ],
      ),
    );
  }
}
