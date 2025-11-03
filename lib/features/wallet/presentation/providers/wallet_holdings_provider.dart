import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
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
      formattedFiatValue: 'Indisponível',
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
      return '0 ${asset.ticker}';
    }

    if (asset == Asset.btc || asset == Asset.lbtc) {
      final btcAmount = balance.toDouble() / satsPerBtc;
      if (btcAmount < 0.001) {
        final satoshis = balance.toInt();
        return satoshis == 1 ? '1 sat' : '$satoshis sats';
      } else {
        final formatted = btcAmount
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
        return '$formatted ${asset.ticker}';
      }
    }

    // Outros ativos → 2 casas decimais
    final amount = balance.toDouble() / satsPerBtc;
    return '${amount.toStringAsFixed(2)} ${asset.ticker}';
  }
}

final walletHoldingsProvider =
    FutureProvider<Either<String, List<WalletHolding>>>((ref) async {
      final allAssets = ref.watch(allAssetsProvider);
      ref.watch(currencyControllerProvider);

      final List<WalletHolding> holdings = [];

      try {
        final currency = ref.read(currencyControllerProvider.notifier);

        for (final asset in allAssets) {
          final balanceAsync = ref.watch(balanceProvider(asset));

          final balanceResult = await balanceAsync.when(
            data: (data) async => data,
            loading: () async {
              return await ref.read(balanceProvider(asset).future);
            },
            error: (error, stack) async => throw error,
          );
          final priceResult = await ref.read(fiatPriceProvider(asset).future);

          final holding = balanceResult.fold(
            (error) {
              return WalletHolding.empty(asset);
            },
            (balance) => priceResult.fold(
              (error) {
                return WalletHolding.empty(asset);
              },
              (price) {
                if (price == 0) {
                  return WalletHolding.empty(asset);
                }

                return WalletHolding.fromData(
                  asset: asset,
                  balance: balance,
                  fiatPrice: price,
                  currencySymbol: currency.icon,
                );
              },
            ),
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
        return Either.left('Erro ao carregar ativos da carteira: $e');
      }
    });

final walletHoldingsWithBalanceProvider =
    FutureProvider<Either<String, List<WalletHolding>>>((ref) async {
      final allHoldingsResult = await ref.read(walletHoldingsProvider.future);

      return allHoldingsResult.map(
        (holdings) => holdings.where((holding) => holding.hasBalance).toList(),
      );
    });
