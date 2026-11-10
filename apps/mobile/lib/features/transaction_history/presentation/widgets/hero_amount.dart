import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The amount of a transaction as the hero of the detail screen.
///
/// Sats are the main figure for BTC-like assets; other assets show their
/// decimal amount. The digits are large and tabular, and the unit is
/// smaller and muted, so the eye goes to the digits. A capsule below holds
/// the BTC amount of a BTC-like asset and the fiat estimate.
///
/// [sign] carries the direction ("+" or "−"), so the direction never
/// depends on color. Money in is green; money out keeps the primary text
/// color. A failed transaction shows the amount struck through.
class HeroAmount extends ConsumerWidget {
  final Asset asset;
  final BigInt amountInSats;
  final String currencySymbol;

  /// "+", "−", or null when the transaction has no direction.
  final String? sign;

  final bool isIncoming;
  final bool struckThrough;

  const HeroAmount({
    super.key,
    required this.asset,
    required this.amountInSats,
    required this.currencySymbol,
    this.sign,
    this.isIncoming = false,
    this.struckThrough = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tabular = [FontFeature.tabularFigures()];
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final amount = amountInSats.toDouble() / 100000000;
    final decimal = isBtcLike
        ? amount.toStringAsFixed(8)
        : amount
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
    final locale = ref.watch(localeStringProvider);
    final digits = isBtcLike
        ? NumberFormat('#,##0', locale).format(amountInSats.toInt())
        : decimal;
    final unit = isBtcLike ? 'sats' : asset.ticker;

    final price = ref.watch(
      priceQuotesProvider.select((quotes) => quotes.priceFor(asset)),
    );
    final fiat = price == null || price <= 0
        ? null
        : '$currencySymbol ${NumberFormat('#,##0.00', locale).format(asset.toUsd(amountInSats, price))}';

    final secondaryParts = [if (isBtcLike) '$decimal ${asset.ticker}', ?fiat];
    final secondary = secondaryParts.join(', ');

    final decoration = struckThrough ? TextDecoration.lineThrough : null;
    final color = struckThrough
        ? context.colors.textSecondary
        : isIncoming
        ? context.colors.positiveColor
        : context.colors.textPrimary;
    final signText = sign == null ? '' : '$sign ';

    return Semantics(
      label: '$signText$digits $unit${secondary.isEmpty ? '' : ', $secondary'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A long amount or a large text size scales the line down. It
          // never wraps.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$signText$digits'),
                  TextSpan(
                    text: ' $unit',
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      decoration: decoration,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              style: context.textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                height: 1.1,
                fontFeatures: tabular,
                decoration: decoration,
              ),
            ),
          ),
          if (secondaryParts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ValueCapsule(parts: secondaryParts),
          ],
        ],
      ),
    );
  }
}

/// The secondary values of the hero in one quiet capsule, split by a small
/// brand dot.
class _ValueCapsule extends StatelessWidget {
  const _ValueCapsule({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: context.colors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0)
                TextSpan(
                  text: '  •  ',
                  style: TextStyle(color: context.colorScheme.primary),
                ),
              TextSpan(text: parts[i]),
            ],
          ],
        ),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

/// The coin of the hero on its stage: a glass tile that floats on a lit
/// orbit, with an optional badge at its corner.
///
/// The orbit artwork sits behind the tile and is wider than it, so the
/// ring reads as passing around the tile.
class _HeroStage extends StatelessWidget {
  const _HeroStage({required this.coin, this.badge});

  final Widget coin;
  final Widget? badge;

  static const String _orbit = 'assets/images/transaction/hero_orbit.svg';

  /// Side of the glass tile.
  static const double tileSize = 84;

  /// Size of the orbit artwork, in its own 5:2 proportion.
  static const double _orbitWidth = 250;
  static const double _orbitHeight = 100;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(24));
    return ExcludeSemantics(
      child: SizedBox(
        width: _orbitWidth,
        height: tileSize + 16,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // The orbit centers a little below the tile center.
            Positioned(
              top: tileSize / 2 + 12 - _orbitHeight / 2,
              child: Opacity(
                opacity: isDark ? 1 : 0.6,
                child: SvgPicture.asset(
                  _orbit,
                  width: _orbitWidth,
                  height: _orbitHeight,
                ),
              ),
            ),
            Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.shadow.withValues(
                      alpha: isDark ? 0.35 : 0.10,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: GlassPanel(
                borderRadius: radius,
                child: Center(child: coin),
              ),
            ),
            if (badge != null)
              Positioned(
                top: tileSize - 26,
                left: _orbitWidth / 2 + tileSize / 2 - 22,
                child: badge!,
              ),
          ],
        ),
      ),
    );
  }
}

/// The asset coin of the hero, with a badge that shows the direction.
///
/// It is the leading icon of the home transaction row on the hero stage,
/// so the row and its detail read as the same transaction.
class HeroAssetIcon extends StatelessWidget {
  final Asset asset;

  /// Direction glyph of the badge. Null shows the coin alone.
  final IconData? glyph;

  const HeroAssetIcon({super.key, required this.asset, this.glyph});

  /// Size of the coin inside the tile.
  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    return _HeroStage(
      coin: SvgPicture.asset(asset.iconPath, width: size, height: size),
      badge: glyph == null
          ? null
          : HeroBadge(
              color: context.colors.actionButtonBackground,
              child: Icon(glyph, size: 16, color: context.colors.textPrimary),
            ),
    );
  }
}

/// The coins of a swap: the sent asset in the tile, the received asset as
/// its badge, so the swap reads as "from, into". A refund shows the sent
/// coin with a return badge.
class HeroSwapIcon extends StatelessWidget {
  final Asset fromAsset;
  final Asset toAsset;
  final bool isRefund;

  const HeroSwapIcon({
    super.key,
    required this.fromAsset,
    required this.toAsset,
    this.isRefund = false,
  });

  @override
  Widget build(BuildContext context) {
    return _HeroStage(
      coin: SvgPicture.asset(
        fromAsset.iconPath,
        width: HeroAssetIcon.size,
        height: HeroAssetIcon.size,
      ),
      badge: isRefund
          ? HeroBadge(
              color: context.appColors.warning,
              // Black on the warning orange keeps the glyph readable in both
              // themes.
              child: Icon(
                Icons.assignment_return,
                size: 16,
                color: context.colors.absoluteBlack,
              ),
            )
          : SvgPicture.asset(
              toAsset.iconPath,
              width: HeroBadge.size,
              height: HeroBadge.size,
            ),
    );
  }
}

/// A round badge at the corner of a hero tile.
///
/// The tile sits on the gradient of the screen backdrop, so a ring in one
/// page color would not match everywhere. A hairline rim and a soft shadow
/// separate the badge from the tile below it.
class HeroBadge extends StatelessWidget {
  final Color color;
  final Widget child;

  const HeroBadge({super.key, required this.color, required this.child});

  static const double size = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppSurfaces.hairline(context)),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
