import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';

part 'liquid_fee_provider.g.dart';

@riverpod
Future<NetworkFee?> liquidFee(Ref ref) async {
  final liquidWallet = ref.read(liquidWalletRepositoryProvider);
  final addrFuture = liquidWallet.generateAddress();
  final ownedAssetsFuture = ref.read(ownedAssetsNotifierProvider.future);

  final (addr, ownedAssets) = await (addrFuture, ownedAssetsFuture).wait;

  final liquidBitcoinOwnedAsset = ownedAssets.firstWhere(
    (asset) => asset.asset.id == AssetCatalog.getById("lbtc")!.id,
  );

  final response = await liquidWallet.buildPartiallySignedTransaction(
    liquidBitcoinOwnedAsset,
    addr,
    1,
    null,
  );

  return NetworkFee(absoluteFees: response.feeAmount ?? 100, feeRate: 1.0);
}
