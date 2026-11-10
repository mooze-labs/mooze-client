import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The unit after an amount from [Asset.formatAmount]: "sats" for the
/// BTC-like assets, as in the hero amount, else the ticker in capitals.
String conversionUnit(Asset asset) =>
    asset == Asset.btc || asset == Asset.lbtc ? 'sats' : asset.displayUnit;

/// One side of a conversion: what left the wallet or what came in.
class ConversionLeg {
  final String label;
  final Asset asset;
  final BigInt amountInSats;

  /// Fiat estimate, already formatted. Null hides the line.
  final String? fiat;

  const ConversionLeg({
    required this.label,
    required this.asset,
    required this.amountInSats,
    this.fiat,
  });
}

/// The two sides of a swap side by side, in reading order: what was sent on
/// the left, an arrow, what was received on the right.
///
/// One horizontal glass strip shows the whole conversion at a glance. A
/// neutral arrow joins the two sides; the amounts carry the weight. The
/// rate, when given, sits below the strip.
class ConversionStrip extends StatelessWidget {
  const ConversionStrip({
    super.key,
    required this.from,
    required this.to,
    this.rate,
  });

  final ConversionLeg from;
  final ConversionLeg to;

  /// The rate line, for example "1 DEPIX = 227 SATS".
  final String? rate;

  static const double _arrowSize = 36;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _Leg(leg: from, locale: locale, alignEnd: false),
              ),
              const SizedBox(width: 10),
              const _Arrow(size: _arrowSize),
              const SizedBox(width: 10),
              Expanded(
                child: _Leg(leg: to, locale: locale, alignEnd: true),
              ),
            ],
          ),
        ),
        if (rate != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  rate!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Leg extends StatelessWidget {
  const _Leg({required this.leg, required this.locale, required this.alignEnd});

  final ConversionLeg leg;
  final String locale;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    final amount = leg.asset.formatAmount(
      leg.amountInSats.toInt(),
      locale: locale,
    );
    final unit = conversionUnit(leg.asset);
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final alignment = alignEnd
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: cross,
        children: [
          Text(
            leg.label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: SvgPicture.asset(
                  leg.asset.iconPath,
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  leg.asset.name,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // A long amount scales down instead of wrapping.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: amount),
                  TextSpan(
                    text: ' $unit',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFeatures: tabular,
              ),
            ),
          ),
          if (leg.fiat != null) ...[
            const SizedBox(height: 2),
            Text(
              leg.fiat!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontFeatures: tabular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The arrow between the two sides, on a neutral well. It points in the
/// reading direction, so it flips in right-to-left languages.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.actionButtonBackground,
        ),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: size / 2,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
