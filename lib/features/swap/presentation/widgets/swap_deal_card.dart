import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shared "send → receive" deal card used by both confirm-swap sheets
/// (Sideswap quote flow + BTC↔LBTC peg flow).
///
/// Renders an elevated, theme-tuned card with two [_AmountRow]s stacked
/// vertically and a primary-tinted down-arrow chip flanked by hairline
/// dividers between them. The receive row is the visual hero
/// (`headlineMedium w700`); the send row is one tier down.
///
/// **Why a primitive-param API:**
/// The two confirm sheets drive the card from different state sources
/// (the regular sheet pulls from `SwapState` / Riverpod; the
/// BTC↔LBTC sheet computes values locally from the peg-in/out amount
/// and fee estimates). Keeping the widget tied to raw assets + sats
/// keeps it reusable across both — the caller does the mapping.
///
/// All formatting goes through `Asset.formatAmount` / `Asset.displayUnit`
/// so light/dark themes and locales render consistently.
class SwapDealCard extends StatelessWidget {
  final core.Asset sendAsset;
  final int? sendAmountSats;
  final core.Asset receiveAsset;
  final int? receiveAmountSats;
  final bool isLoadingReceive;

  /// "You send" / "You receive" labels — supplied by the caller so this
  /// widget stays free of an `AppLocalizations` import dependency.
  final String sendLabel;
  final String receiveLabel;

  const SwapDealCard({
    super.key,
    required this.sendAsset,
    required this.sendAmountSats,
    required this.receiveAsset,
    required this.receiveAmountSats,
    required this.sendLabel,
    required this.receiveLabel,
    this.isLoadingReceive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();

    final borderColor = isDark
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.45)
        : theme.colorScheme.outline.withValues(alpha: 0.55);
    final dividerColor = isDark
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.35)
        : theme.colorScheme.outline.withValues(alpha: 0.45);

    final sendAmountText = sendAmountSats != null
        ? sendAsset.formatAmount(sendAmountSats!, locale: locale)
        : '0';
    final receiveAmountText = receiveAmountSats != null
        ? receiveAsset.formatAmount(receiveAmountSats!, locale: locale)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        // Match the main-screen swap cards' dark-theme fill so the
        // sheet feels like a natural extension of the screen.
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          _AmountRow(
            label: sendLabel,
            asset: sendAsset,
            amount: sendAmountText,
            isShimmer: false,
            isHero: false,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: dividerColor, height: 1)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: dividerColor, height: 1)),
            ],
          ),
          const SizedBox(height: 14),
          _AmountRow(
            label: receiveLabel,
            asset: receiveAsset,
            amount: receiveAmountText ?? '0',
            isShimmer: isLoadingReceive || receiveAmountText == null,
            isHero: true,
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final core.Asset asset;
  final String amount;
  final bool isShimmer;
  final bool isHero;

  const _AmountRow({
    required this.label,
    required this.asset,
    required this.amount,
    required this.isShimmer,
    required this.isHero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountStyle = isHero
        ? theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: SvgPicture.asset(asset.iconPath, width: 28, height: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              isShimmer
                  ? _ShimmerBlock(width: 140, height: isHero ? 28 : 22)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            amount,
                            style: amountStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          asset.displayUnit,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBlock({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final base = context.colors.baseColor;
    final highlight = context.colors.highlightColor;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
