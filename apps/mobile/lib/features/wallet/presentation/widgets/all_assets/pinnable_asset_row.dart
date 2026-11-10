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
class PinnableAssetRow extends StatelessWidget {
  const PinnableAssetRow({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AssetRow(asset: asset)),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: PinStarButton(asset: asset),
        ),
      ],
    );
  }
}

/// A star that pins [asset] to the home screen, or unpins it.
///
/// A pinned asset shows a filled star in the brand color. The star pops a
/// little when it changes, unless reduced motion is on.
class PinStarButton extends ConsumerWidget {
  const PinStarButton({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final pinned = ref.watch(isFavoriteAssetProvider(asset));
    final label = pinned ? t.wallet_all_assets_unpin : t.wallet_all_assets_pin;

    return Semantics(
      toggled: pinned,
      child: IconButton(
        tooltip: label,
        onPressed: () {
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
                ? context.colors.primaryColor
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
