import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_flow_scaffold.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Merchant Header Widget (Presentation Layer)
///
/// Header of the Merchant Mode screen:
/// - A glass back button that leaves Merchant Mode
/// - The title "Merchant Mode"
/// - A "Clear" pill, only while the cart has items
/// - The cart total as the hero of the screen. A new total slides in from
///   the side of the change, and screen readers announce it.
class MerchantHeaderWidget extends StatelessWidget {
  /// Current total value in BRL (Brazilian Real)
  final double totalAmountInBRL;
  final VoidCallback onClearCart;
  final VoidCallback? onBack;
  final GlobalKey? clearButtonKey;
  final GlobalKey? totalAmountKey;

  const MerchantHeaderWidget({
    super.key,
    required this.totalAmountInBRL,
    required this.onClearCart,
    this.onBack,
    this.clearButtonKey,
    this.totalAmountKey,
  });

  /// Largest text scale of the title.
  static const double _maxTitleScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasItems = totalAmountInBRL > 0;
    final duration = Motion.of(context, Motion.durationFast);

    return Column(
      children: [
        SizedBox(
          height: kToolbarHeight,
          child: NavigationToolbar(
            // The theme draws every back button as the round glass button.
            leading: BackButton(onPressed: onBack),
            middle: Semantics(
              header: true,
              child: Text(
                t.merchant_mode_header,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: _maxTitleScale),
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // The key sits outside the switcher: during a switch, the old
            // and the new pill are both in the tree.
            trailing: KeyedSubtree(
              key: clearButtonKey,
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: Motion.curveEnter,
                switchOutCurve: Motion.curveExit,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: hasItems
                    ? _ClearCartButton(
                        label: t.merchant_clear_cart,
                        onPressed: onClearCart,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        MerchantAmountHero(
          label: t.merchant_total_label,
          amountInCents: merchantCents(totalAmountInBRL),
          amountKey: totalAmountKey,
          animate: true,
          announceChanges: true,
          centered: true,
        ),
      ],
    );
  }
}

/// The glass "Clear" pill of the header.
///
/// The trash icon has the negative color, so the pill reads as a removal
/// before the user taps it. The screen asks for a confirmation.
class _ClearCartButton extends StatelessWidget {
  const _ClearCartButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          widthFactor: 1,
          child: PressScale(
            child: LiquidGlass(
              blurBackdrop: false,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PixIcon(
                          PixIcons.delete,
                          size: 16,
                          color: context.colors.negativeColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          // A toolbar control grows up to the title limit,
                          // so the title keeps room beside it.
                          textScaler: MediaQuery.textScalerOf(context).clamp(
                            maxScaleFactor: MerchantHeaderWidget._maxTitleScale,
                          ),
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
