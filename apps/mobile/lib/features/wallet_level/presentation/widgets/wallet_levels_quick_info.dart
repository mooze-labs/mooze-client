import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// What the levels give, as a strip of three columns in one glass panel.
///
/// The columns are split by vertical hairlines: an icon, a short title, and
/// a muted line.
class WalletLevelsQuickInfo extends StatelessWidget {
  final bool isLoading;

  const WalletLevelsQuickInfo({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final items = isLoading
        ? null
        : [
            (
              Icons.lock_open_rounded,
              t.wallet_levels_quick_unlock_title,
              t.wallet_levels_quick_unlock_subtitle,
            ),
            (
              Icons.redeem_rounded,
              t.wallet_levels_quick_earn_title,
              t.wallet_levels_quick_earn_subtitle,
            ),
            (
              Icons.star_rate_rounded,
              t.wallet_levels_quick_status_title,
              t.wallet_levels_quick_status_subtitle,
            ),
          ];

    return GlassPanel(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppSurfaces.hairline(context),
                ),
              Expanded(
                child: items == null
                    ? const _LoadingColumn()
                    : _InfoColumn(
                        icon: items[i].$1,
                        title: items[i].$2,
                        subtitle: items[i].$3,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: context.colors.textPrimary),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingColumn extends StatelessWidget {
  const _LoadingColumn();

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.baseColor;

    Widget box(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: context.colors.highlightColor,
      period: Motion.durationShimmer,
      enabled: !Motion.isReduced(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            box(22, 22),
            const SizedBox(height: 10),
            box(60, 12),
            const SizedBox(height: 6),
            box(44, 10),
          ],
        ),
      ),
    );
  }
}
