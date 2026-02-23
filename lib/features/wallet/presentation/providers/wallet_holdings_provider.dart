import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';

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
  }) {
    final hasBalance = balance > BigInt.zero;
    final balanceInMainUnit = balance.toDouble() / satsPerBtc;
    final fiatValue = balanceInMainUnit * fiatPrice;

    return WalletHolding(
      asset: asset,
      balance: balance,
      fiatPrice: fiatPrice,
      fiatValue: fiatValue,
      formattedBalance: _formatBalance(balance, asset),
      formattedFiatValue:
          hasBalance
              ? '$currencySymbol ${fiatValue.toStringAsFixed(2)}'
              : '$currencySymbol 0,00',
      hasBalance: hasBalance,
    );
  }

  static String _formatBalance(BigInt balance, Asset asset) {
    if (balance == BigInt.zero) {
      if (asset == Asset.btc || asset == Asset.lbtc) {
        return '0 sat';
      }
      return '0 ${asset.ticker}';
    }

    if (asset == Asset.btc || asset == Asset.lbtc) {
      final satoshis = balance.toInt();
      if (satoshis == 1) return '1 sat';

      final formatter = NumberFormat('#,##0', 'pt_BR');
      return '${formatter.format(satoshis)} sats';
    }

    final amount = balance.toDouble() / satsPerBtc;
    return '${amount.toStringAsFixed(2)} ${asset.ticker}';
  }
}

final walletHoldingsProvider = FutureProvider.autoDispose<
  Either<String, List<WalletHolding>>
>((ref) async {
  final allAssets = ref.watch(allAssetsProvider);
  ref.watch(currencyControllerProvider);

  // IMPORTANT: Wait for all balances to load first
  // This ensures we stay in loading state until data is ready
  final allBalances = await ref.watch(allBalancesProvider.future);

  final List<WalletHolding> holdings = [];

  try {
    final currency = ref.watch(currencyControllerProvider.notifier);

    for (final asset in allAssets) {
      final balance = allBalances[asset] ?? BigInt.zero;
      final priceResult = await ref.watch(fiatPriceProvider(asset).future);

      debugPrint(
        '[WalletHoldingsProvider] ${asset.ticker}: balance=$balance, price=$priceResult',
      );

      final holding = priceResult.fold(
        (error) {
          debugPrint(
            '[WalletHoldingsProvider] ${asset.ticker}: Price error: $error. Using balance without price.',
          );
          // Even without price, we show the balance if available
          return WalletHolding(
            asset: asset,
            balance: balance,
            fiatPrice: null,
            fiatValue: null,
            formattedBalance: WalletHolding._formatBalance(balance, asset),
            formattedFiatValue: 'Preço indisponível',
            hasBalance: balance > BigInt.zero,
          );
        },
        (price) {
          if (price == 0) {
            debugPrint(
              '[WalletHoldingsProvider] ${asset.ticker}: Price is zero. Using balance without price.',
            );
            // Even with zero price, we show the balance
            return WalletHolding(
              asset: asset,
              balance: balance,
              fiatPrice: 0,
              fiatValue: 0,
              formattedBalance: WalletHolding._formatBalance(balance, asset),
              formattedFiatValue: '${currency.icon} 0,00',
              hasBalance: balance > BigInt.zero,
            );
          }

          return WalletHolding.fromData(
            asset: asset,
            balance: balance,
            fiatPrice: price,
            currencySymbol: currency.icon,
          );
        },
      );

      holdings.add(holding);
    }

    holdings.sort((a, b) {
      if (a.hasBalance && !b.hasBalance) return -1;
      if (!a.hasBalance && b.hasBalance) return 1;
      if (!a.hasBalance && !b.hasBalance) return 0;

      final aValue = a.fiatValue ?? 0.0;
      final bValue = b.fiatValue ?? 0.0;
      return bValue.compareTo(aValue);
    });

    return Either.right(holdings);
  } catch (e) {
    return Either.left('Error loading wallet assets: $e');
  }
});

final walletHoldingsWithBalanceProvider =
    FutureProvider.autoDispose<Either<String, List<WalletHolding>>>((
      ref,
    ) async {
      final allHoldingsResult = await ref.read(walletHoldingsProvider.future);

      return allHoldingsResult.map(
        (holdings) => holdings.where((holding) => holding.hasBalance).toList(),
      );
    });
