import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/animated_amount.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Mask that replaces a hidden holding amount.
const String holdingMask = '•••••';

/// One holding in the portfolio panel.
///
/// Left: the icon, the name, and the ticker below it. Right: the fiat value,
/// and the token balance below it. The primary line of each side carries
/// what the user scans for (name, value); the secondary line explains it
/// (ticker, amount). The allocation legend of the panel shows the shares.
///
/// Motion:
/// - A new fiat value uses [AnimatedAmount] (numberChange, at most once per
///   second).
/// - Hide and show cross-fade the amounts and the mask over
///   [Motion.durationFast].
///
/// Reduced motion removes both animations.
class AssetTransactionItem extends StatelessWidget {
  /// Size of the asset icon.
  static const double iconSize = 40;

  /// Space between the panel edge and the row content.
  static const double horizontalPadding = 16;

  /// Distance from the panel edge to the row text. Dividers start here.
  static const double textInset = horizontalPadding + iconSize + 12;

  final String icon;
  final String title;

  /// The ticker below the name, for example "BTC". Empty shows no ticker.
  final String ticker;

  /// The token balance below the fiat value, for example "0.0012 BTC".
  final String balance;

  /// The formatted fiat value.
  final String value;

  /// The numeric fiat value. It sets the direction of a value change.
  final double? fiatValue;

  /// A short status in place of the token balance, for example "No
  /// balance". Hidden balances show no status.
  final String status;

  /// True when the balance is hidden.
  final bool isHidden;

  /// True for a holding without balance. Its value uses the secondary
  /// color, so the holdings with balance stand out.
  final bool muted;

  const AssetTransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.balance,
    required this.value,
    required this.isHidden,
    this.ticker = '',
    this.fiatValue,
    this.status = '',
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final secondaryStyle = textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final valueStyle = textTheme.bodyLarge?.copyWith(
      color: muted ? context.colors.textSecondary : context.colors.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Container(
      color: Colors.transparent,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            ExcludeSemantics(
              child: SvgPicture.asset(icon, width: iconSize, height: iconSize),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ticker.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ticker,
                      style: secondaryStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // The value takes at most 45% of the row. A wider value
            // scales down, so it never wraps or overflows.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Masked(
                      isHidden: isHidden,
                      alignment: AlignmentDirectional.centerEnd,
                      style: valueStyle,
                      child: AnimatedAmount(
                        text: value,
                        value: fiatValue,
                        alignment: AlignmentDirectional.centerEnd,
                        style: valueStyle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (status.isNotEmpty && !isHidden)
                      Text(status, style: secondaryStyle)
                    else
                      _Masked(
                        isHidden: isHidden,
                        alignment: AlignmentDirectional.centerEnd,
                        style: secondaryStyle,
                        child: Text(
                          balance,
                          style: secondaryStyle,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-fades [child] and a mask when [isHidden] changes.
class _Masked extends StatelessWidget {
  const _Masked({
    required this.isHidden,
    required this.alignment,
    required this.style,
    required this.child,
  });

  final bool isHidden;
  final AlignmentGeometry alignment;
  final TextStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.durationFast),
      switchInCurve: Motion.curveMove,
      switchOutCurve: Motion.curveMove,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, if (current != null) current],
      ),
      child: isHidden
          ? Semantics(
              key: const ValueKey('mask'),
              label: AppLocalizations.of(context).wallet_amount_hidden,
              excludeSemantics: true,
              child: Text(holdingMask, style: style),
            )
          : KeyedSubtree(key: const ValueKey('value'), child: child),
    );
  }
}
