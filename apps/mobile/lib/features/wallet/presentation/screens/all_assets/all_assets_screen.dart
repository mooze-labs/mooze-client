import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/all_assets/pinnable_asset_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_row.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The markets of every asset, in the rows of the home screen.
///
/// Two groups: the assets pinned to the home screen, with how many of the
/// two places are taken, and the other assets. Each row shows the 24 h
/// sparkline, the price, and the change, and opens the market sheet of the
/// asset. Its star pins or unpins the asset, and the row moves to the other
/// group. A third pin takes the place of the second one; the first stays
/// first.
///
/// The home screen shows one or two assets: the star of the last pinned one
/// is off. With two, a handle at the start of each pinned row drags it to
/// the other place, inside the panel.
class AllAssetsScreen extends ConsumerWidget {
  const AllAssetsScreen({super.key});

  /// Places on the home screen.
  static const int _maxPinned = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final allAssets = ref.watch(assetsForQuotesProvider);
    final pinned = ref.watch(favoriteAssetsProvider);
    final others = [
      for (final asset in allAssets)
        if (!pinned.contains(asset)) asset,
    ];

    return BackdropPageScaffold(
      title: t.wallet_all_assets_title,
      actions: [
        OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        const SizedBox(width: 16),
      ],
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          BackdropPageScaffold.gutter,
          8,
          BackdropPageScaffold.gutter,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            t.wallet_all_assets_subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          _GroupHeader(
            title: t.wallet_all_assets_pinned,
            trailing: t.wallet_all_assets_favorite_count(pinned.length),
            full: pinned.length >= _maxPinned,
          ),
          // The group grows and shrinks as rows move between the groups. The
          // key ignores the order, so a drag does not fade the group.
          SizeFadeSwitcher(
            child: switch (pinned.length) {
              // Only until the saved pins load: the home screen shows at
              // least one asset.
              0 => _EmptyPinned(
                key: const ValueKey('empty'),
                text: t.wallet_all_assets_pin_hint,
              ),
              1 => AssetRowPanel(
                key: ValueKey(_membership(pinned)),
                rows: [PinnableAssetRow(asset: pinned.single)],
              ),
              _ => _ReorderablePinnedPanel(
                key: ValueKey(_membership(pinned)),
                pinned: pinned,
              ),
            },
          ),
          if (pinned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                pinned.length >= _maxPinned
                    ? t.wallet_all_assets_hint_two
                    : t.wallet_all_assets_hint_one,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          if (others.isNotEmpty) ...[
            _GroupHeader(title: t.wallet_all_assets_others),
            SizeFadeSwitcher(
              child: AssetRowPanel(
                key: ValueKey(others.join()),
                rows: [
                  for (final asset in others) PinnableAssetRow(asset: asset),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The pinned assets without their order.
  static String _membership(List<Asset> pinned) =>
      ([for (final asset in pinned) asset.name]..sort()).join();
}

/// The two pinned assets in one glass panel, in the order of the home
/// screen. The handle at the start of a row drags it to the other place;
/// the dragged row lifts as a card of opaque glass and stays inside the
/// panel. Screen readers get the move actions of a reorderable list.
class _ReorderablePinnedPanel extends ConsumerWidget {
  const _ReorderablePinnedPanel({super.key, required this.pinned});

  final List<Asset> pinned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassPanel(
      // The dragged row stays inside the panel: it cannot leave the list
      // over the header or over the other assets.
      child: DragBoundary(
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          padding: EdgeInsets.zero,
          itemCount: pinned.length,
          onReorderStart: (_) => HapticFeedback.selectionClick(),
          onReorder: (oldIndex, newIndex) {
            // The list gives the index from before the row left its place.
            if (newIndex > oldIndex) newIndex -= 1;
            if (newIndex == oldIndex) return;
            final next = [...pinned];
            next.insert(newIndex, next.removeAt(oldIndex));
            HapticFeedback.lightImpact();
            ref.read(favoriteAssetsProvider.notifier).setFavorites(next);
          },
          proxyDecorator: (_, index, animation) => _LiftedRow(
            animation: animation,
            // The card takes the height of the slice it lifts: the panel
            // inset at an end, the hairline above any other row. The drag
            // boundary holds that height inside the panel.
            slack:
                (index == 0 ? AssetRowPanel.inset : _hairline) +
                (index == pinned.length - 1 ? AssetRowPanel.inset : 0),
            child: PinnableAssetRow(asset: pinned[index], reorderIndex: index),
          ),
          itemBuilder: (context, i) => AssetRowPanel.slice(
            key: ValueKey(pinned[i]),
            index: i,
            count: pinned.length,
            dividerIndent: PinnableAssetRow.textInsetWithHandle,
            row: PinnableAssetRow(asset: pinned[i], reorderIndex: i),
          ),
        ),
      ),
    );
  }

  /// Height of the hairline above a row that is not the first.
  static const double _hairline = 1;
}

/// A row while it is dragged: a card of opaque glass that grows a little.
/// The card holds a fresh row, without the hairline of its slice, with
/// [slack] split above and below it. Under reduced motion the card keeps
/// its size.
class _LiftedRow extends StatelessWidget {
  const _LiftedRow({
    required this.animation,
    required this.slack,
    required this.child,
  });

  final Animation<double> animation;

  /// Height of the slice beyond the row itself.
  final double slack;

  final Widget child;

  /// Scale of the card once it is lifted.
  static const double _liftScale = 1.02;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.isReduced(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, card) {
        final lift = Motion.curveMove.transform(animation.value);
        return Transform.scale(
          scale: reduced ? 1 : 1 + (_liftScale - 1) * lift,
          child: card,
        );
      },
      child: LiquidGlass(
        borderRadius: AppSurfaces.panelRadius,
        blurBackdrop: false,
        opaque: true,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: slack / 2),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The title of a group, with an optional count at the end. A full count
/// takes the primary text color, so the limit reads before the next pin.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, this.trailing, this.full = false});

  final String title;
  final String? trailing;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelMedium?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: style)),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            // With large text the count wraps instead of running off the
            // screen.
            Flexible(
              child: Text(
                trailing!,
                textAlign: TextAlign.end,
                style: style?.copyWith(
                  color: full ? context.colors.textPrimary : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The pinned group without assets: a glass panel with a muted star and
/// the hint.
class _EmptyPinned extends StatelessWidget {
  const _EmptyPinned({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 22,
            color: context.colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
