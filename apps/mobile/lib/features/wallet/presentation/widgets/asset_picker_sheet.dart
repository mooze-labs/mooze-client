import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shows an [AssetPickerSheet] and returns the asset that the user taps.
///
/// It returns null when the user closes the sheet without a pick. The send
/// and receive screens use it, so both list the assets the same way.
Future<Asset?> showAssetPickerSheet(
  BuildContext context, {
  required String title,
  required List<Asset> assets,
  required Asset? selected,
}) {
  return showFloatingGlassSheet<Asset>(
    context,
    builder: (_) =>
        AssetPickerSheet(title: title, assets: assets, selected: selected),
  );
}

/// Ticker on top, full name below it.
class AssetTickerName extends StatelessWidget {
  final Asset asset;

  const AssetTickerName({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          asset.ticker,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          asset.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// The asset logo in a round glass lens.
class AssetLensLogo extends StatelessWidget {
  final Asset asset;
  final double size;

  const AssetLensLogo({super.key, required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GlassStyle.of(context).lensFill,
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: SvgPicture.asset(
        asset.iconPath,
        width: size * 0.6,
        height: size * 0.6,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Floating glass sheet that lists the assets with their balances.
///
/// The selected asset has a brand border and a check, so the selection
/// never depends on color alone. A tap closes the sheet with that asset.
/// When the user hides the balances on the home screen, the sheet shows a
/// mask instead of the amounts.
class AssetPickerSheet extends ConsumerWidget {
  /// Heading of the sheet.
  final String title;

  /// Assets in the order of the list.
  final List<Asset> assets;
  final Asset? selected;

  const AssetPickerSheet({
    super.key,
    required this.title,
    required this.assets,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `isVisibleProvider` is true when the balance is hidden.
    final isHidden = ref.watch(isVisibleProvider);
    final holdingsAsync = ref.watch(walletHoldingsProvider);
    final holdings = holdingsAsync.valueOrNull?.fold(
      (_) => null,
      (list) => {for (final holding in list) holding.asset: holding},
    );

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _SheetHandle()),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final asset in assets)
                    _AssetOption(
                      asset: asset,
                      isSelected: asset == selected,
                      holding: holdings?[asset],
                      isLoading: holdingsAsync.isLoading,
                      isHidden: isHidden,
                      onTap: () => Navigator.of(context).pop(asset),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetOption extends StatelessWidget {
  final Asset asset;
  final bool isSelected;

  /// Balance of the asset. Null when the balances are not available.
  final WalletHolding? holding;

  /// True while the balances load.
  final bool isLoading;

  /// True when the user hides the balances.
  final bool isHidden;
  final VoidCallback onTap;

  const _AssetOption({
    required this.asset,
    required this.isSelected,
    required this.holding,
    required this.isLoading,
    required this.isHidden,
    required this.onTap,
  });

  /// Largest part of the row that the balance can take.
  static const double _maxBalanceShare = 0.45;

  /// Text scale from which the balance goes below the name.
  static const double _stackedTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primaryColor;
    const radius = BorderRadius.all(Radius.circular(16));
    // With very large text, a balance beside the name leaves too little
    // width and cuts the name. The balance then goes below the name.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final stacked = textScale >= _stackedTextScale;
    final balance = _balance(context, alignEnd: !stacked);

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: '${asset.ticker}, ${asset.name}',
      // A hidden or loading balance is not read.
      value: isHidden || isLoading ? null : holding?.formattedBalance,
      excludeSemantics: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? primary : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    AssetLensLogo(asset: asset, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: stacked && balance != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AssetTickerName(asset: asset),
                                const SizedBox(height: 4),
                                balance,
                              ],
                            )
                          : AssetTickerName(asset: asset),
                    ),
                    // The balance gets at most [_maxBalanceShare] of the
                    // row and scales down when it does not fit, so a large
                    // amount never overflows. The name gives way first.
                    if (!stacked && balance != null) ...[
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * _maxBalanceShare,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: balance,
                        ),
                      ),
                    ],
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      PixIcon(PixIcons.check, size: 20, color: primary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The asset amount, with its fiat value below it.
  ///
  /// A zero balance is muted. While the balances load, a skeleton bar
  /// holds the place. Without balance data, the row shows no amount.
  Widget? _balance(BuildContext context, {required bool alignEnd}) {
    if (isLoading) {
      return const SkeletonShimmer(child: SkeletonBox(width: 72, height: 12));
    }
    final holding = this.holding;
    if (holding == null) return null;

    const tabular = [FontFeature.tabularFigures()];
    final amountStyle = context.textTheme.bodyMedium?.copyWith(
      color: holding.hasBalance
          ? context.colors.textPrimary
          : context.colors.textSecondary,
      fontWeight: FontWeight.w600,
      fontFeatures: tabular,
    );
    if (isHidden) return Text(holdingMask, style: amountStyle);

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(holding.formattedBalance, style: amountStyle),
        // Without a price, the fiat value is a status text. The row then
        // shows only the amount.
        if (holding.fiatValue != null) ...[
          const SizedBox(height: 1),
          Text(
            holding.formattedFiatValue,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: tabular,
            ),
          ),
        ],
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.colorScheme.onSurface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
