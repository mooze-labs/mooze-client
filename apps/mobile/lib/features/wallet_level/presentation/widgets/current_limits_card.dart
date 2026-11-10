import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/level_names.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';

/// The limits of the current level, in one glass panel.
///
/// A header row with the title and the level name, then one hairline row
/// per limit (muted label, value in tabular figures), then a muted hint on
/// how to reach the next level.
class CurrentLimitsCard extends ConsumerStatefulWidget {
  const CurrentLimitsCard({super.key});

  @override
  ConsumerState<CurrentLimitsCard> createState() => _CurrentLimitsCardState();
}

class _CurrentLimitsCardState extends ConsumerState<CurrentLimitsCard> {
  bool _isRetrying = false;

  /// Inset of the row text, past the 16 pt padding, the icon, and the gap.
  static const double _textInset = 16 + 40 + 14;

  @override
  Widget build(BuildContext context) {
    final levelsData = ref.watch(levelsProvider);

    return levelsData.when(
      data: (data) => _buildLimitsCard(data),
      loading: () => _buildLoadingCurrentLimitsCard(),
      error: (error, stack) => _buildErrorCard(),
    );
  }

  Widget _buildLimitsCard(UserLevelsData data) {
    final t = AppLocalizations.of(context);
    final textTheme = context.textTheme;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                const _IconWell(icon: Icons.account_balance_wallet_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          t.wallet_levels_current_limits_title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.wallet_levels_current_level(t.levelName(data.spendingLevel)),
                        style: textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PanelDivider(),
          _buildLimitRow(
            t.wallet_levels_limit_per_transaction,
            'R\$ ${data.allowedSpending.toStringAsFixed(2)}',
            Icons.trending_up,
          ),
          const PanelDivider(indent: _textInset),
          _buildLimitRow(
            t.wallet_levels_limit_daily,
            'R\$ ${UserLevelsData.dailyLimit.toStringAsFixed(2)}',
            Icons.flag_outlined,
          ),
          const PanelDivider(indent: _textInset),
          _buildLimitRow(
            t.wallet_levels_limit_minimum,
            'R\$ ${data.absoluteMinLimit.toStringAsFixed(2)}',
            Icons.low_priority,
          ),
          const PanelDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.nextLevelName != null
                        ? t.wallet_levels_next_level_hint_named(
                            t.levelName(data.spendingLevel + 1),
                          )
                        : t.wallet_levels_next_level_hint,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final t = AppLocalizations.of(context);
    final textTheme = context.textTheme;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconWell(
                icon: Icons.error_outline,
                color: context.colors.negativeColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.wallet_levels_load_limits_error_title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.wallet_levels_load_limits_error_body,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            text: t.common_retry,
            height: 48,
            isLoading: _isRetrying,
            onPressed: () async {
              setState(() => _isRetrying = true);
              await Future.delayed(const Duration(milliseconds: 500));
              ref.invalidate(walletLevelsRemoteProvider);
              ref.invalidate(userDataProvider);
              if (mounted) {
                setState(() => _isRetrying = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(String title, String value, IconData icon) {
    final textTheme = context.textTheme;

    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Icon(
                  icon,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCurrentLimitsCard() {
    final baseColor = context.colors.baseColor;

    Widget box(double width, double height, {bool circle = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(height / 2),
        ),
      );
    }

    return GlassPanel(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: context.colors.highlightColor,
        period: Motion.durationShimmer,
        enabled: !Motion.isReduced(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                children: [
                  box(40, 40, circle: true),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(140, 16),
                      const SizedBox(height: 8),
                      box(100, 12),
                    ],
                  ),
                ],
              ),
            ),
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 40 + 14),
                    box(110, 12),
                    const Spacer(),
                    box(72, 14),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: box(double.infinity, 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round well for the icon of a header row: a glass lens, or a light tint
/// of [color] when the row marks a state.
class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint == null
            ? GlassStyle.of(context).lensFill
            : tint.withValues(alpha: 0.14),
        border: Border.all(
          color: tint == null
              ? AppSurfaces.hairline(context)
              : tint.withValues(alpha: 0.24),
        ),
      ),
      child: Icon(
        icon,
        size: size / 2,
        color: tint ?? context.colors.textPrimary,
      ),
    );
  }
}
