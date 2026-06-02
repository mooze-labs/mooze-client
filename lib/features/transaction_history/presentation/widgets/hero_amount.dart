import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Hero amount stack — sats are the principal figure for BTC-like assets
/// (with the BTC decimal and a fiat line underneath); token assets keep their
/// native decimal amount. Every priced asset shows a fiat estimate underneath.
/// Mirrors the send-review `_HeroAmountStack`, but adds the receive `+` sign
/// and positive tint so credits read at a glance.
class HeroAmount extends StatelessWidget {
  final Asset asset;
  final BigInt amountInSats;
  final bool isReceive;
  final String currencySymbol;

  const HeroAmount({
    super.key,
    required this.asset,
    required this.amountInSats,
    required this.isReceive,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;

    final amount = amountInSats.toDouble() / 100000000;
    final decimalStr =
        isBtcLike
            ? amount.toStringAsFixed(8)
            : amount
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');

    final principal =
        isBtcLike
            ? '${SatsInputFormatter.formatValue(amountInSats.toInt())} sats'
            : '$decimalStr ${asset.ticker}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            principal,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (isBtcLike) ...[
          const SizedBox(height: 8),
          Text(
            '$decimalStr ${asset.ticker}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        HeroFiatLine(
          asset: asset,
          amountInSats: amountInSats,
          currencySymbol: currencySymbol,
        ),
      ],
    );
  }
}

/// pt_BR / es_ES `4.999,11`).
class HeroFiatLine extends ConsumerWidget {
  final Asset asset;
  final BigInt amountInSats;
  final String currencySymbol;

  const HeroFiatLine({
    super.key,
    required this.asset,
    required this.amountInSats,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0.00', ref.watch(localeStringProvider));
    final style = theme.textTheme.titleSmall?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return ref
        .watch(fiatPriceProvider(asset))
        .maybeWhen(
          data:
              (either) => either.fold((_) => const SizedBox.shrink(), (price) {
                if (price <= 0) return const SizedBox.shrink();
                final fiat = asset.toUsd(amountInSats, price);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$currencySymbol ${formatter.format(fiat)}',
                    style: style,
                  ),
                );
              }),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

/// "Asset" row inside the hero card — the asset icon to the left of its name
/// and ticker, rendered at the larger hero scale.
class HeroAssetRow extends StatelessWidget {
  final Asset asset;

  const HeroAssetRow({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SvgPicture.asset(asset.iconPath, width: 32, height: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).wallet_send_conversion_asset,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                asset.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          asset.ticker,
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
