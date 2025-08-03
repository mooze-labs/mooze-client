import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/selected_asset_provider.dart';
import '../providers/selected_asset_balance_provider.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.pinBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary)
      ),
      child: Column(
        children: [
          Text("Saldo disponível", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          BalanceText(),
          const SizedBox(height: 4),
          FiatBalanceText()
        ],
      ),
    );
  }
}

class BalanceText extends ConsumerWidget {
  const BalanceText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.read(selectedAssetProvider);
    final balance = ref.read(selectedAssetBalanceProvider);

    return balance.when(
        data: (data) => data.fold(
            (err) => Text("Indisponível", style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: Theme.of(context).colorScheme.error
            )),
            (val) => Text(_formatBalance(val, asset), style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary
            ))
        ),
        error: (err, _) => Text("Indisponível", style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: Theme.of(context).colorScheme.error
        )),
        loading: () => Shimmer.fromColors( baseColor: Colors.grey[800]!, highlightColor: Colors.grey[600]!, child: SizedBox(width: 100, height: 28)));
  }
}

class FiatBalanceText extends ConsumerWidget {
  const FiatBalanceText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.read(selectedAssetProvider);
    final assetBalance = ref.watch(selectedAssetBalanceProvider);
    final fiatPrice = ref.watch(fiatPriceProvider(selectedAsset));
    final currency = ref.watch(currencyProvider);

    return _buildBalanceWidget(context, assetBalance, fiatPrice, currency, selectedAsset);
  }

  Widget _buildBalanceWidget(
    BuildContext context,
    AsyncValue<Either<WalletError, BigInt>> assetBalance,
    AsyncValue<Either<String, double>> fiatPrice,
    AsyncValue<Either<String, String>> currency,
    Asset selectedAsset,
  ) {
    return assetBalance.when(
      data: (balanceResult) => _handleBalanceResult(
        context,
        balanceResult,
        fiatPrice,
        currency,
        selectedAsset,
      ),
      error: (err, _) => _buildErrorText(context, "Indisponível"),
      loading: () => _buildLoadingWidget(),
    );
  }

  Widget _handleBalanceResult(
    BuildContext context,
    Either<WalletError, BigInt> balanceResult,
    AsyncValue<Either<String, double>> fiatPrice,
    AsyncValue<Either<String, String>> currency,
    Asset selectedAsset,
  ) {
    return balanceResult.fold(
      (err) => _buildErrorText(context, "Indisponível"),
      (balance) => _buildPriceWidget(context, balance, fiatPrice, currency, selectedAsset),
    );
  }

  Widget _buildPriceWidget(
    BuildContext context,
    BigInt balance,
    AsyncValue<Either<String, double>> fiatPrice,
    AsyncValue<Either<String, String>> currency,
    Asset selectedAsset,
  ) {
    return fiatPrice.when(
      data: (priceResult) => _handlePriceResult(
        context,
        balance,
        priceResult,
        currency,
        selectedAsset,
      ),
      error: (err, _) => _buildErrorText(context, "Valor indisponível"),
      loading: () => _buildLoadingWidget(),
    );
  }

  Widget _handlePriceResult(
    BuildContext context,
    BigInt balance,
    Either<String, double> priceResult,
    AsyncValue<Either<String, String>> currency,
    Asset selectedAsset,
  ) {
    return priceResult.fold(
      (err) => _buildErrorText(context, "Valor indisponível"),
      (price) => _buildCurrencyWidget(context, balance, price, currency, selectedAsset),
    );
  }

  Widget _buildCurrencyWidget(
    BuildContext context,
    BigInt balance,
    double price,
    AsyncValue<Either<String, String>> currency,
    Asset selectedAsset,
  ) {
    return currency.when(
      data: (currencyResult) => _handleCurrencyResult(
        context,
        balance,
        price,
        currencyResult,
        selectedAsset,
      ),
      error: (err, _) => _buildErrorText(context, "Moeda indisponível"),
      loading: () => _buildLoadingWidget(),
    );
  }

  Widget _handleCurrencyResult(
    BuildContext context,
    BigInt balance,
    double price,
    Either<String, String> currencyResult,
    Asset selectedAsset,
  ) {
    return currencyResult.fold(
      (err) => _buildErrorText(context, "Moeda indisponível"),
      (currencyCode) => _buildFiatValueText(context, balance, price, currencyCode, selectedAsset),
    );
  }

  Widget _buildFiatValueText(
    BuildContext context,
    BigInt balance,
    double price,
    String currencyCode,
    Asset selectedAsset,
  ) {
    final adjustedBalance = _getAdjustedBalance(balance, selectedAsset);
    final fiatValue = adjustedBalance * price;
    return Text(
      "\$${fiatValue.toStringAsFixed(2)} $currencyCode",
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildErrorText(BuildContext context, String message) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: const SizedBox(width: 80, height: 16),
    );
  }
}

String _formatBalance(BigInt value, Asset asset) {
  if (asset == Asset.btc) return value.toString();

  return (value / BigInt.from(pow(10, 8))).toDouble().toStringAsFixed(2);
}

double _getAdjustedBalance(BigInt balance, Asset asset) {
  if (asset == Asset.btc) {
    return balance.toDouble();
  }
  // For non-BTC assets (like stablecoins), divide by 10^8 for proper precision
  return balance.toDouble() / pow(10, 8);
}