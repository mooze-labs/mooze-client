import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_action_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_method_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Pix transaction limits of the account.
///
/// The numbers come from [levelsProvider], the same source the deposit screen
/// and the level screen read, so nothing here is simulated. The limits
/// section handles its own loading and error states.
class PixLimitsScreen extends ConsumerWidget {
  const PixLimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    // The button has a fixed height of 55 pt. With large text, it grows to
    // fit its label instead of clipping it.
    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return PixScreenScaffold(
      title: t.pix_hub_preferences_limits,
      subtitle: t.pix_hub_limits_subtitle,
      onRefresh: () async => ref.invalidate(levelsProvider),
      bottomAction: SecondaryButton(
        text: t.pix_hub_limits_how_it_works,
        height: isLargeText ? null : 55,
        onPressed: () => PixLimitsInfoDialog.show(context),
      ),
      children: [
        const _CurrentLimits(),
        const SizedBox(height: 32),
        PixSurfaceCard(
          child: Column(
            children: [
              PixActionTile(
                icon: PixIcons.level,
                title: t.pix_hub_preferences_level,
                subtitle: t.pix_hub_preferences_level_subtitle,
                onTap: () => context.push('/wallet-levels'),
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: PixActionTile.textInset,
                color: AppSurfaces.hairline(context),
              ),
              PixActionTile(
                icon: PixIcons.receipt,
                title: t.pix_hub_menu_fees,
                subtitle: t.pix_hub_other_fees_subtitle,
                onTap: () => context.push('/pix/fees'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The current limits of the account in one glass summary.
///
/// The limit per transaction is the main figure, so it has the larger value.
/// The level shows as a tag next to the section title. The hint about the
/// next level follows the panel as secondary text.
class _CurrentLimits extends ConsumerWidget {
  const _CurrentLimits();

  /// Formats a limit in reais as Brazilian currency.
  static String _formatLimit(double reais) =>
      formatBrlCents((reais * 100).round());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final levels = ref.watch(levelsProvider);

    return levels.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LimitsTitle(
            level: t.wallet_levels_current_level(data.currentLevelName),
          ),
          const SizedBox(height: 8),
          PixSummaryCard(
            entries: [
              PixSummaryEntry(
                t.wallet_levels_limit_per_transaction,
                _formatLimit(data.allowedSpending),
                highlight: true,
              ),
              PixSummaryEntry(
                t.wallet_levels_limit_daily,
                _formatLimit(UserLevelsData.dailyLimit),
              ),
              PixSummaryEntry(
                t.wallet_levels_limit_minimum,
                _formatLimit(data.absoluteMinLimit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LimitsHint(
            text: data.nextLevelName != null
                ? t.wallet_levels_next_level_hint_named(data.nextLevelName!)
                : t.wallet_levels_next_level_hint,
          ),
        ],
      ),
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_LimitsTitle(), SizedBox(height: 8), _LimitsSkeleton()],
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LimitsTitle(),
          const SizedBox(height: 8),
          PixSurfaceCard(
            child: PixEmptyState(
              icon: PixIcons.error,
              title: t.wallet_levels_load_limits_error_title,
              message: t.wallet_levels_load_limits_error_body,
              actionLabel: t.common_retry,
              // The limits depend on the user data and on the level table.
              // A retry loads both again.
              onAction: () {
                ref.invalidate(walletLevelsRemoteProvider);
                ref.invalidate(userDataProvider);
              },
              isCompact: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Title of the limits section, with the current level as a tag.
class _LimitsTitle extends StatelessWidget {
  const _LimitsTitle({this.level});

  /// Label of the current level. Null while the limits load.
  final String? level;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final level = this.level;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PixSectionHeader(title: t.wallet_levels_current_limits_title),
        ),
        if (level != null) ...[
          const SizedBox(width: 12),
          // The tag ends at the content edge. With large text, it wraps
          // inside its share of the row instead of overflowing.
          Flexible(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PixTag(level),
            ),
          ),
        ],
      ],
    );
  }
}

/// The hint about the next level, below the limits panel.
class _LimitsHint extends StatelessWidget {
  const _LimitsHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Aligns the icon with the first line of text.
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(PixIcons.trendingUp, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder in the shape of the limits panel, while the limits load.
class _LimitsSkeleton extends StatelessWidget {
  const _LimitsSkeleton();

  /// Widths of the label placeholders, one per row.
  static const List<double> _labelWidths = [104, 88, 64];

  @override
  Widget build(BuildContext context) {
    return PixSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: SkeletonShimmer(
        child: Column(
          children: [
            for (var index = 0; index < _labelWidths.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppSurfaces.hairline(context),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    SkeletonBox(width: _labelWidths[index], height: 14),
                    const Spacer(),
                    SkeletonBox(width: index == 0 ? 96 : 72, height: 14),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
