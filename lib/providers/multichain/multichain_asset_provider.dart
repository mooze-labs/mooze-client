import 'package:mooze_mobile/models/assets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart' as liquid;
import 'package:mooze_mobile/models/liquid.dart';
import 'package:mooze_mobile/providers/bitcoin/wallet_provider.dart';
import 'package:mooze_mobile/providers/liquid/asset_provider.dart';
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'multichain_asset_provider.g.dart';

@riverpod
Future<List<Asset>> ownedMultiChainAssets(Ref ref) async {
  final liquidState = ref.watch(liquidWalletNotifierProvider);
  final bitcoinState = ref.watch(bitcoinWalletNotifierProvider);

  final liquidBalances = await liquidState.when(
    data: (wallet) async => await wallet.balances(),
    loading: () => Future.value([]),
    error: (error, stack) => Future.value([]),
  );

  final bitcoinBalance = bitcoinState.when(
    data: (wallet) => wallet.getBalance().total.toInt(),
    loading: () => null,
    error: (error, stack) => null,
  );

  final bitcoinAsset = Asset(
    id: "bitcoin",
    name: "Bitcoin",
    ticker: "BTC",
    amount: bitcoinBalance ?? 0,
    precision: 8,
    network: Network.bitcoin,
    logoPath: "assets/images/bitcoin-logo.png",
    coingeckoId: "bitcoin",
  );

  final liquidAssets = await Future.wait(
    liquidBalances.map((balance) async {
      if (balance.assetId ==
          "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d") {
        return Asset(
          id: "liquid_bitcoin",
          name: "Liquid Bitcoin",
          ticker: "L-BTC",
          amount: balance.value,
          precision: 8,
          network: Network.liquid,
          logoPath: "assets/images/lbtc-logo.png",
          coingeckoId: "bitcoin",
        );
      }

      if (balance.assetId ==
          "ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2") {
        return Asset(
          id: "tether",
          name: "Tether USD",
          ticker: "USDT",
          amount: balance.value,
          precision: 8,
          network: Network.liquid,
          logoPath: "assets/images/usdt-logo.png",
          coingeckoId: "tether",
        );
      }

      if (balance.assetId ==
          "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189") {
        return Asset(
          id: "depix",
          name: "Depix",
          ticker: "DEPIX",
          amount: balance.value,
          precision: 8,
          network: Network.liquid,
          logoPath: "assets/images/depix-logo.png",
        );
      }

      final assetDetails = await ref.read(
        liquidAssetProvider((balance.assetId, liquid.Network.mainnet)).future,
      );

      return Asset(
        id: assetDetails.assetId,
        name: assetDetails.name,
        ticker: assetDetails.ticker,
        amount: balance.value,
        precision: assetDetails.precision,
        network: Network.liquid,
        logoPath: "assets/images/nav-default-liquid.png",
      );
    }),
  );

  final defaultTether = Asset(
    id: "tether",
    name: "Tether USD",
    ticker: "USDT",
    amount: 0,
    precision: 8,
    network: Network.liquid,
    logoPath: "assets/images/usdt-logo.png",
    coingeckoId: "tether",
  );

  final defaultDepix = Asset(
    id: "depix",
    name: "Depix",
    ticker: "DEPIX",
    amount: 0,
    precision: 8,
    network: Network.liquid,
    logoPath: "assets/images/depix-logo.png",
  );

  final assetMap = {for (var asset in liquidAssets) asset.id: asset};

  final allLiquidAssets = [
    ...liquidAssets,
    if (!assetMap.containsKey("tether")) defaultTether,
    if (!assetMap.containsKey("depix")) defaultDepix,
  ];

  return [bitcoinAsset, ...allLiquidAssets];
}
