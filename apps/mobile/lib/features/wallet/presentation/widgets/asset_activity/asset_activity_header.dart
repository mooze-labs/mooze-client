import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Identity + balance hero: a clean centered asset logo, the current balance,
/// its fiat equivalent, and a flat market-price line. No tinted containers or
/// chips — the balance is the focal point.
class AssetActivityHeader extends ConsumerWidget {
  final Asset asset;

  const AssetActivityHeader({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hidden = ref.watch(isVisibleProvider);
    final locale = ref.watch(localeStringProvider);
    final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;
    final holdingsAsync = ref.watch(walletHoldingsProvider);

    final holding = holdingsAsync.valueOrNull?.fold(
      (_) => null,
      (holdings) => _findHolding(holdings),
    );

    final balanceText =
        hidden
            ? '••••••'
            : (holding?.formattedBalance ??
                WalletHolding.formatBalance(BigInt.zero, asset, locale));
    final fiatText = hidden ? '••••••' : holding?.formattedFiatValue;
    final price = holding?.fiatPrice;
    final secondary = context.colors.textSecondary;

    return Column(
      children: [
        SvgPicture.asset(asset.iconPath, width: 60, height: 60),
        const SizedBox(height: 20),
        Text(
          balanceText,
          textAlign: TextAlign.center,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        if (fiatText != null) ...[
          const SizedBox(height: 6),
          Text(
            '≈ $fiatText',
            style: context.textTheme.bodyMedium?.copyWith(color: secondary),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.asset_activity_market_price(asset.ticker),
              style: context.textTheme.bodySmall?.copyWith(color: secondary),
            ),
            const SizedBox(width: 8),
            Text(
              price != null
                  ? '$currencyIcon ${NumberFormat('#,##0.00', locale).format(price)}'
                  : '—',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
