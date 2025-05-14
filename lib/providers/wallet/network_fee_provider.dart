import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/repositories/wallet/bitcoin.dart';
import 'package:mooze_mobile/repositories/wallet/liquid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_fee_provider.g.dart';

class NetworkFee {
  final int absoluteFees;
  final double? feeRate;

  NetworkFee({required this.absoluteFees, this.feeRate});
}

class NetworkFees {
  final NetworkFee bitcoinFast;
  final NetworkFee bitcoinNormal;
  final NetworkFee bitcoinSlow;
  final NetworkFee liquid;

  NetworkFees({
    required this.bitcoinFast,
    required this.bitcoinNormal,
    required this.bitcoinSlow,
    required this.liquid,
  });
}

@riverpod
class NetworkFeeProvider extends _$NetworkFeeProvider {
  @override
  Future<NetworkFees> build() async {
    final liquidWallet =
        ref.watch(liquidWalletRepositoryProvider) as LiquidWalletRepository;
    final bitcoinWallet =
        ref.watch(bitcoinWalletRepositoryProvider) as BitcoinWalletRepository;

    final liquidBitcoinOwnedAsset = await liquidWallet.getOwnedAssets().then(
      (assets) => assets.firstWhere(
        (asset) => asset.asset.id == AssetCatalog.getById("lbtc")!.id,
      ),
    );

    final bitcoinOwnedAsset = await bitcoinWallet.getOwnedAssets().then(
      (assets) => assets.firstWhere(
        (asset) => asset.asset.id == AssetCatalog.getById("btc")!.id,
      ),
    );

    final bitcoinAddress = await bitcoinWallet.generateAddress();
    final liquidAddress = await liquidWallet.generateAddress();

    final bitcoinBlockchain = bitcoinWallet.blockchain;
    final fastBitcoinFees = await bitcoinBlockchain?.estimateFee(
      target: BigInt.from(3), // 30 minutes
    );
    final normalBitcoinFees = await bitcoinBlockchain?.estimateFee(
      target: BigInt.from(12), // 2 hours
    );
    final slowBitcoinFees = await bitcoinBlockchain?.estimateFee(
      target: BigInt.from(24), // 4 hours
    );
    final liquidFees = await liquidWallet
        .buildPartiallySignedTransaction(
          liquidBitcoinOwnedAsset,
          liquidAddress,
          1,
          null,
        )
        .then((psbt) => psbt.feeAmount);

    final fastBtcPsbt = await bitcoinWallet.buildPartiallySignedTransaction(
      bitcoinOwnedAsset,
      bitcoinAddress,
      546,
      fastBitcoinFees?.satPerVb,
    );

    final normalBtcPsbt = await bitcoinWallet.buildPartiallySignedTransaction(
      bitcoinOwnedAsset,
      bitcoinAddress,
      546,
      normalBitcoinFees?.satPerVb,
    );

    final slowBtcPsbt = await bitcoinWallet.buildPartiallySignedTransaction(
      bitcoinOwnedAsset,
      bitcoinAddress,
      546,
      slowBitcoinFees?.satPerVb,
    );

    return NetworkFees(
      bitcoinFast: NetworkFee(
        absoluteFees: fastBtcPsbt.feeAmount ?? 0,
        feeRate: fastBitcoinFees?.satPerVb ?? 0,
      ),
      bitcoinNormal: NetworkFee(
        absoluteFees: normalBtcPsbt.feeAmount ?? 0,
        feeRate: normalBitcoinFees?.satPerVb ?? 0,
      ),
      bitcoinSlow: NetworkFee(
        absoluteFees: slowBtcPsbt.feeAmount ?? 0,
        feeRate: slowBitcoinFees?.satPerVb ?? 0,
      ),
      liquid: NetworkFee(absoluteFees: liquidFees ?? 0, feeRate: null),
    );
  }
}
