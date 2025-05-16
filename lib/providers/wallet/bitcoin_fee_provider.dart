import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/repositories/wallet/bitcoin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'bitcoin_fee_provider.g.dart';

@riverpod
Future<NetworkFee?> bitcoinFee(Ref ref, int estimatedBlocks) async {
  final bitcoinWallet =
      ref.read(bitcoinWalletRepositoryProvider) as BitcoinWalletRepository;

  Future<String> addrFuture = bitcoinWallet.generateAddress();
  Future<List<OwnedAsset>> ownedAssetsFuture = ref.read(
    ownedAssetsNotifierProvider.future,
  );
  Future<FeeRate> estimatedFeesFuture =
      bitcoinWallet.blockchain?.estimateFee(
        target: BigInt.from(estimatedBlocks),
      ) ??
      Future.value(FeeRate(satPerVb: 2));

  final (addr, ownedAssets, estimatedFees) =
      await (addrFuture, ownedAssetsFuture, estimatedFeesFuture).wait;

  final bitcoinOwnedAsset = ownedAssets.firstWhere(
    (asset) => asset.asset.id == AssetCatalog.getById("btc")!.id,
  );

  try {
    final response = await bitcoinWallet.buildPartiallySignedTransaction(
      bitcoinOwnedAsset,
      addr,
      546,
      estimatedFees.satPerVb,
    );

    return NetworkFee(
      absoluteFees: response.feeAmount ?? 100,
      feeRate: estimatedFees.satPerVb,
    );
  } catch (e) {
    return NetworkFee(absoluteFees: 200, feeRate: estimatedFees.satPerVb);
  }
}
