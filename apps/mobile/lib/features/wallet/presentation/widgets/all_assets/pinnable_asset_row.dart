import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_row.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// An [AssetRow] of the All assets screen, with a star that pins the asset
/// to the home screen.
///
/// The row keeps its own tap, which opens the market sheet. The star sits
/// beside it with its own 48 pt target, so a tap on it never opens the
/// sheet.
///
/// With [reorderIndex], a handle at the start of the row drags it to
/// another place of a reorderable list, at that index. The handle is far
/// from the star, so a drag never lands on it.
class PinnableAssetRow extends StatelessWidget {
  const PinnableAssetRow({super.key, required this.asset, this.reorderIndex});

  final Asset asset;

  /// Index of the row in its reorderable list. Null shows no handle.
  final int? reorderIndex;

  /// Width of the touch target of the handle.
  static const double handleWidth = 44;

  /// How far the row moves to the end to make room for the handle. The
  /// handle overlaps the empty start padding of the row, so the row gives
  /// up less width than the handle takes.
  static const double handleInset =
      handleWidth - AssetRowView.horizontalPadding;

  /// Distance from the panel edge to the text of a row with a handle.
  /// Hairlines between such rows start here.
  static const double textInsetWithHandle =
      AssetRowView.textInset + handleInset;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: AssetRow(asset: asset, compact: reorderIndex != null),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: PinStarButton(asset: asset),
        ),
      ],
    );
    final index = reorderIndex;
    if (index == null) return row;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: handleInset),
          child: row,
        ),
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: handleWidth,
          child: _DragHandle(index: index),
        ),
      ],
    );
  }
}

/// The grip at the start of a pinned row. A drag on it starts at once,
/// without a long press.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: t.wallet_all_assets_reorder,
        // The whole slot takes the drag, not only the icon.
        child: ColoredBox(
          color: Colors.transparent,
          child: Center(
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 22,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A star that pins [asset] to the home screen, or unpins it.
///
/// A pinned asset shows a filled star in the brand color. The home screen
/// shows at least one asset, so the star of the last pinned one is off,
/// dimmed, and says why. The star pops a little when it changes, unless
/// reduced motion is on.
class PinStarButton extends ConsumerWidget {
  const PinStarButton({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final favorites = ref.watch(favoriteAssetsProvider);
    final pinned = favorites.contains(asset);
    final locked = pinned && favorites.length <= 1;
    final label = locked
        ? t.wallet_all_assets_keep_one
        : pinned
        ? t.wallet_all_assets_unpin
        : t.wallet_all_assets_pin;
    final primary = context.colors.primaryColor;

    return Semantics(
      toggled: pinned,
      child: IconButton(
        tooltip: label,
        onPressed: locked
            ? null
            : () {
                HapticFeedback.selectionClick();
                ref.read(favoriteAssetsProvider.notifier).toggleFavorite(asset);
              },
        icon: AnimatedSwitcher(
          duration: Motion.of(context, Motion.durationFast),
          switchInCurve: Motion.curveEnter,
          switchOutCurve: Motion.curveExit,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            pinned ? Icons.star_rounded : Icons.star_outline_rounded,
            key: ValueKey(pinned),
            size: 24,
            color: pinned
                ? (locked ? primary.withValues(alpha: 0.45) : primary)
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
