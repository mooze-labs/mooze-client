import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Balance hero: the current balance, its fiat equivalent, and the market
/// price in a glass pill. The balance is the focal point. The sheet header
/// above it shows the asset logo and name.
class AssetActivityHeader extends ConsumerWidget {
  final Asset asset;

  const AssetActivityHeader({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hidden = ref.watch(isVisibleProvider);
    final locale = ref.watch(localeStringProvider);
    final currencyIcon = ref.watch(currencySymbolProvider);
    final holdingsAsync = ref.watch(walletHoldingsProvider);

    final holding = holdingsAsync.valueOrNull?.fold(
      (_) => null,
      (holdings) => _findHolding(holdings),
    );

    final balanceText = hidden
        ? '••••••'
        : (holding?.formattedBalance ??
              WalletHolding.formatBalance(BigInt.zero, asset, locale));
    final fiatText = hidden ? '••••••' : holding?.formattedFiatValue;
    final price = holding?.fiatPrice;
    final secondary = context.colors.textSecondary;

    const tabular = [FontFeature.tabularFigures()];

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            balanceText,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              fontFeatures: tabular,
            ),
          ),
        ),
        if (fiatText != null) ...[
          const SizedBox(height: 4),
          Text(
            '≈ $fiatText',
            style: context.textTheme.bodyMedium?.copyWith(
              color: secondary,
              fontFeatures: tabular,
            ),
          ),
        ],
        const SizedBox(height: 12),
        // The market price, in a glass pill below the balance.
        MergeSemantics(
          child: AssetGlassLens(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixIcon(PixIcons.trendingUp, size: 14, color: secondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    t.asset_activity_market_price(asset.ticker),
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  price != null
                      ? '$currencyIcon ${NumberFormat('#,##0.00', locale).format(price)}'
                      : '—',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  WalletHolding? _findHolding(List<WalletHolding> holdings) {
    for (final h in holdings) {
      if (h.asset == asset) return h;
    }
    return null;
  }
}
