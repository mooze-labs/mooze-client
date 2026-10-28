import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_action_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_transaction_tile.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Which movements the history shows.
enum PixHistoryFilter { all, sent, received }

/// History of the Pix movements.
///
/// The list holds Pix records only. Bitcoin, L-BTC, USDT and DePix movements
/// stay in the wallet history.
///
/// A glass segmented control picks the filter. The movements share one
/// glass panel, split by inset hairlines. A change of filter or of loading
/// state grows and fades the panel over [SizeFadeSwitcher].
class PixHubHistoryScreen extends ConsumerStatefulWidget {
  const PixHubHistoryScreen({super.key});

  @override
  ConsumerState<PixHubHistoryScreen> createState() =>
      _PixHubHistoryScreenState();
}

class _PixHubHistoryScreenState extends ConsumerState<PixHubHistoryScreen> {
  PixHistoryFilter _filter = PixHistoryFilter.all;

  List<PixTransaction> _apply(List<PixTransaction> source) {
    return switch (_filter) {
      PixHistoryFilter.all => source,
      PixHistoryFilter.sent =>
        source
            .where((tx) => tx.direction == PixTransactionDirection.outgoing)
            .toList(),
      PixHistoryFilter.received =>
        source
            .where((tx) => tx.direction == PixTransactionDirection.incoming)
            .toList(),
    };
  }

  String _label(AppLocalizations t, PixHistoryFilter filter) {
    return switch (filter) {
      PixHistoryFilter.all => t.pix_hub_history_filter_all,
      PixHistoryFilter.sent => t.pix_hub_history_filter_sent,
      PixHistoryFilter.received => t.pix_hub_history_filter_received,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final transactions = ref.watch(pixHubTransactionsProvider);

    return PixScreenScaffold(
      title: t.pix_hub_action_history,
      subtitle: t.pix_hub_action_history_subtitle,
      onRefresh: () async => ref.invalidate(pixHubTransactionsProvider),
      children: [
        _FilterBar(
          selected: _filter,
          labelOf: (filter) => _label(t, filter),
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: 16),
        SizeFadeSwitcher(
          child: transactions.when(
            loading: () => const _HistorySkeleton(key: ValueKey('loading')),
            error: (_, _) => PixEmptyState(
              key: const ValueKey('error'),
              icon: PixIcons.offline,
              title: t.pix_hub_error_title,
              message: t.pix_hub_error_body,
              actionLabel: t.common_retry,
              onAction: () => ref.invalidate(pixHubTransactionsProvider),
            ),
            data: (all) {
              final list = _apply(all);
              return PixSurfaceCard(
                // A new filter swaps the panel. A refresh keeps it.
                key: ValueKey('data-${_filter.name}-${list.isEmpty}'),
                child: list.isEmpty
                    ? PixEmptyState(
                        icon: PixIcons.receipt,
                        title: t.pix_hub_empty_transactions_title,
                        message: t.pix_hub_empty_transactions_body,
                        isCompact: true,
                      )
                    : Column(
                        children: [
                          for (final (index, transaction) in list.indexed) ...[
                            if (index > 0)
                              Divider(
                                height: 1,
                                thickness: 1,
                                // The divider starts at the row text.
                                indent: PixActionTile.textInset,
                                color: AppSurfaces.hairline(context),
                              ),
                            PixTransactionTile(
                              transaction: transaction,
                              onTap: () => context.push(
                                '/pix/history/detail',
                                extra: transaction,
                              ),
                            ),
                          ],
                        ],
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        PixSurfaceCard(
          child: PixActionTile(
            icon: PixIcons.deposit,
            title: t.pix_hub_other_deposit_history,
            subtitle: t.pix_hub_other_deposit_history_subtitle,
            onTap: () => context.push('/swaps-history'),
          ),
        ),
        const SizedBox(height: 10),
        _Note(text: t.pix_hub_history_note),
      ],
    );
  }
}

/// Glass segmented control of the history filters.
///
/// A glass lens marks the selected segment, as in the navigation bar, and
/// its label turns bold. The selection never depends on color alone. The
/// lens slides to a new segment over [Motion.durationBase]. With reduced
/// motion it moves at once.
class _FilterBar extends StatelessWidget {
  final PixHistoryFilter selected;
  final String Function(PixHistoryFilter filter) labelOf;
  final ValueChanged<PixHistoryFilter> onSelected;

  const _FilterBar({
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const filters = PixHistoryFilter.values;
    final index = filters.indexOf(selected);
    // -1 is the start of the bar and 1 is the end.
    final x = filters.length < 2 ? 0.0 : -1 + 2 * index / (filters.length - 1);

    return GlassPanel(
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(x, 0),
              duration: Motion.of(context, Motion.durationBase),
              curve: Motion.curveMove,
              child: FractionallySizedBox(
                widthFactor: 1 / filters.length,
                heightFactor: 1,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: GlassLens(),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final filter in filters)
                Expanded(
                  child: _FilterSegment(
                    label: labelOf(filter),
                    isSelected: filter == selected,
                    onTap: () => onSelected(filter),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One segment of [_FilterBar]. It is at least 48 pt high.
class _FilterSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // `excludeSemantics` drops the semantics of the ink well below, so the
    // node carries the tap action itself.
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Center(
              // Large text scales the label down instead of clipping it.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: Motion.of(context, Motion.durationFast),
                  curve: Motion.curveMove,
                  style: context.textTheme.labelLarge!.copyWith(
                    color: isSelected
                        ? context.colors.textPrimary
                        : context.colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(label, maxLines: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder rows in the shape of the history rows, shown while they load.
class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return PixSurfaceCard(
      child: SkeletonShimmer(
        child: Column(
          children: [
            for (var index = 0; index < 4; index++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    SkeletonBox.circle(size: PixIconWell.defaultSize),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 128, height: 14),
                          SizedBox(height: 8),
                          SkeletonBox(width: 96, height: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    SkeletonBox(width: 76, height: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A short explanation at the end of the screen, with an info icon.
class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    // Secondary, not tertiary: the tertiary gray fails 4.5:1 on the light
    // page background.
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PixIcon(PixIcons.info, size: 15, color: color),
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
      ),
    );
  }
}
