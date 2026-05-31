import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';

class WalletHolding {
  final Asset asset;
  final BigInt balance;
  final double? fiatPrice;
  final double? fiatValue;
  final String formattedBalance;
  final String formattedFiatValue;
  final bool hasBalance;

  const WalletHolding({
    required this.asset,
    required this.balance,
    this.fiatPrice,
    this.fiatValue,
    required this.formattedBalance,
    required this.formattedFiatValue,
    required this.hasBalance,
  });

  factory WalletHolding.empty(Asset asset) {
    return WalletHolding(
      asset: asset,
      balance: BigInt.zero,
      fiatPrice: null,
      fiatValue: null,
      formattedBalance: '0 ${asset.ticker}',
      formattedFiatValue: 'Carregando...',
      hasBalance: false,
    );
  }
  static const int satsPerBtc = 100000000;

  factory WalletHolding.fromData({
    required Asset asset,
    required BigInt balance,
    required double fiatPrice,
    required String currencySymbol,
    required String locale,
  }) {
    final hasBalance = balance > BigInt.zero;
    final balanceInMainUnit = balance.toDouble() / satsPerBtc;
    final fiatValue = balanceInMainUnit * fiatPrice;
    final fiatFormatter = NumberFormat('#,##0.00', locale);

    return WalletHolding(
      asset: asset,
      balance: balance,
      fiatPrice: fiatPrice,
      fiatValue: fiatValue,
      formattedBalance: formatBalance(balance, asset, locale),
      formattedFiatValue: hasBalance
          ? '$currencySymbol ${fiatFormatter.format(fiatValue)}'
          : '$currencySymbol ${fiatFormatter.format(0)}',
      hasBalance: hasBalance,
    );
  }

  /// Formats a base-unit [balance] (sats for BTC/L-BTC, 10^-8 units for
  /// tokens) for display. Public so screens that render asset amounts
  /// (e.g. the asset activity screen) share one formatting source of truth.
  static String formatBalance(BigInt balance, Asset asset, String locale) {
    if (balance == BigInt.zero) {
      if (asset == Asset.btc || asset == Asset.lbtc) {
        return '0 sat';
      }
      return '0 ${asset.ticker}';
    }

    if (asset == Asset.btc || asset == Asset.lbtc) {
      final satoshis = balance.toInt();
      if (satoshis == 1) return '1 sat';

      return '${NumberFormat('#,##0', locale).format(satoshis)} sats';
    }

    final amount = balance.toDouble() / satsPerBtc;
    return '${NumberFormat('#,##0.00', locale).format(amount)} ${asset.ticker}';
  }
}


final walletHoldingsProvider =
    FutureProvider<Either<String, List<WalletHolding>>>((ref) async {
  final allAssets = ref.watch(allAssetsProvider);
  final allBalances = await ref.watch(allBalancesProvider.future);
  final quotes = ref.watch(priceQuotesProvider);
  final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;
  final locale = ref.watch(localeStringProvider);
  final zeroFiat = NumberFormat('#,##0.00', locale).format(0);

  final List<WalletHolding> holdings = [];

  for (final asset in allAssets) {
    final balance = allBalances[asset] ?? BigInt.zero;
    final price = quotes.priceFor(asset);

    if (price == null) {
      holdings.add(WalletHolding(
        asset: asset,
        balance: balance,
        fiatPrice: null,
        fiatValue: null,
        formattedBalance: WalletHolding.formatBalance(balance, asset, locale),
        formattedFiatValue: 'Preço indisponível',
        hasBalance: balance > BigInt.zero,
      ));
      continue;
    }

    if (price == 0) {
      holdings.add(WalletHolding(
        asset: asset,
        balance: balance,
        fiatPrice: 0,
        fiatValue: 0,
        formattedBalance: WalletHolding.formatBalance(balance, asset, locale),
        formattedFiatValue: '$currencyIcon $zeroFiat',
        hasBalance: balance > BigInt.zero,
      ));
      continue;
    }

    holdings.add(WalletHolding.fromData(
      asset: asset,
      balance: balance,
      fiatPrice: price,
      currencySymbol: currencyIcon,
      locale: locale,
    ));
  }

  holdings.sort((a, b) {
    if (a.hasBalance && !b.hasBalance) return -1;
    if (!a.hasBalance && b.hasBalance) return 1;
    if (!a.hasBalance && !b.hasBalance) return 0;

    final aValue = a.fiatValue ?? 0.0;
    final bValue = b.fiatValue ?? 0.0;
    return bValue.compareTo(aValue);
  });

  return Right(holdings);
});

final walletHoldingsWithBalanceProvider =
    FutureProvider<Either<String, List<WalletHolding>>>((ref) async {
      final allHoldingsResult = await ref.watch(walletHoldingsProvider.future);

      return allHoldingsResult.map(
        (holdings) => holdings.where((holding) => holding.hasBalance).toList(),
      );
    });
