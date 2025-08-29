import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';

/// Modelo para representar um ativo na carteira com suas informações
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

  /// Cria uma instância vazia para quando há erro
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

  /// Cria uma instância com dados válidos
  factory WalletHolding.fromData({
    required Asset asset,
    required BigInt balance,
    required double fiatPrice,
    required String currencySymbol,
  }) {
    final hasBalance = balance > BigInt.zero;
    final balanceInMainUnit =
        asset == Asset.btc
            ? balance.toDouble() / 100000000
            : balance.toDouble();
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

    if (asset == Asset.btc) {
      final btcAmount = balance.toDouble() / 100000000;
      if (btcAmount < 0.001) {
        // Mostrar em satoshis para quantidades muito pequenas
        final satoshis = balance.toInt();
        return satoshis == 1 ? '1 sat' : '$satoshis sats';
      } else {
        return '${btcAmount.toStringAsFixed(8)} BTC'
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
    } else {
      final amount = balance.toDouble();
      return '${amount.toStringAsFixed(2)} ${asset.ticker}';
    }
  }
}

final walletHoldingsProvider = FutureProvider<
  Either<String, List<WalletHolding>>
>((ref) async {
  final allAssets = ref.watch(allAssetsProvider);
  ref.watch(currencyControllerProvider);

  final List<WalletHolding> holdings = [];

  try {
    final currency = ref.read(currencyControllerProvider.notifier);

    for (final asset in allAssets) {
      final balanceResult = await ref.read(balanceProvider(asset).future);
      final priceResult = await ref.read(fiatPriceProvider(asset).future);

      final holding = balanceResult.fold(
        (error) {
          print('DEBUG: Erro ao obter saldo do ${asset.name}: $error');
          return WalletHolding.empty(asset);
        },
        (balance) => priceResult.fold(
          (error) {
            print('DEBUG: Erro ao obter preço do ${asset.name}: $error');
            return WalletHolding.empty(asset);
          },
          (price) {
            if (price == 0) {
              print('DEBUG: Preço do ${asset.name} é zero');
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
      print(
        'DEBUG: ${asset.name} - Saldo: ${holding.formattedBalance}, Valor: ${holding.formattedFiatValue}',
      );
    }

    holdings.sort((a, b) {
      if (a.hasBalance && !b.hasBalance) return -1;
      if (!a.hasBalance && b.hasBalance) return 1;
      if (!a.hasBalance && !b.hasBalance) return 0;

      final aValue = a.fiatValue ?? 0.0;
      final bValue = b.fiatValue ?? 0.0;
      return bValue.compareTo(aValue);
    });

    print('DEBUG: Holdings calculados para ${holdings.length} ativos');
    return Either.right(holdings);
  } catch (e) {
    print('DEBUG: Erro ao calcular holdings: $e');
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
