import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lwk/lwk.dart' as liquid;
import 'package:mooze_mobile/models/liquid.dart';
import 'package:mooze_mobile/providers/bitcoin/wallet_provider.dart';
import 'package:mooze_mobile/providers/liquid/asset_provider.dart';
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart';

part 'owned_assets_provider.g.dart';

@Riverpod(keepAlive: true)
class OwnedAssetsNotifier extends _$OwnedAssetsNotifier {
  @override
  Future<List<OwnedAsset>> build() async {
    return _fetchOwnedAssets();
  }

  Future<List<OwnedAsset>> _fetchOwnedAssets() async {
    final ownedBitcoin = _fetchOwnedBitcoin();
    final ownedLiquidAssets = await _fetchOwnedLiquidAssets();

    return [ownedBitcoin, ...ownedLiquidAssets];
  }

  OwnedAsset _fetchOwnedBitcoin() {
    final bitcoinState = ref.watch(bitcoinWalletNotifierProvider);
    final bitcoinBalance = bitcoinState.when(
      data: (wallet) => wallet.getBalance().total.toInt(),
      loading: () => null,
      error: (error, stack) => null,
    );

    return (bitcoinBalance != null)
        ? OwnedAsset.bitcoin(bitcoinBalance)
        : OwnedAsset.bitcoin(0);
  }

  Future<List<OwnedAsset>> _fetchOwnedLiquidAssets() async {
    final liquidState = ref.watch(liquidWalletNotifierProvider);
    final liquidBalance = await liquidState.when(
      data: (wallet) async => await wallet.balances(),
      loading: () => Future.value([]),
      error: (error, stack) => Future.value([]),
    );

    final defaultLiquidAssets = AssetCatalog.liquidAssets;
    final ownedLiquidAssets = await Future.wait(
      liquidBalance.map((balance) async {
        return OwnedAsset.liquid(
          assetId: balance.assetId,
          amount: balance.value,
        );
      }),
    );

    final Map<String, OwnedAsset> ownedAssetsMap = {};

    // add all actual liquid balances
    for (final owned in ownedLiquidAssets) {
      ownedAssetsMap[owned.asset.id] = owned;
    }

    // then add defaults that are not already in the map
    for (final defaultAsset in defaultLiquidAssets) {
      if (!ownedAssetsMap.containsKey(defaultAsset.id)) {
        ownedAssetsMap[defaultAsset.id] = OwnedAsset.zero(defaultAsset);
      }
    }

    return ownedAssetsMap.values.toList();
  }

  Future<bool> refresh() async {
    state = const AsyncValue.loading();

    bool hasError = false;
    List<String> errorMessages = [];

    try {
      final bitcoinNotifier = ref.read(bitcoinWalletNotifierProvider.notifier);
      await bitcoinNotifier.sync();
    } catch (e) {
      hasError = true;
      errorMessages.add("[ERROR] Bitcoin sync failed: ${e.toString()}");
    }

    try {
      final liquidNotifier = ref.read(liquidWalletNotifierProvider.notifier);
      await liquidNotifier.sync();
    } catch (e) {
      hasError = true;
      errorMessages.add("[ERROR] Liquid sync failed: ${e.toString()}");
    }

    try {
      final assets = await _fetchOwnedAssets();
      state = AsyncValue.data(assets);
      // Even with partial errors, we return the latest data
      return !hasError;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}
