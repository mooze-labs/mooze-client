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

class NetworkFees {
  final int bitcoinFast;
  final int bitcoinNormal;
  final int bitcoinSlow;
  final int liquid; // due to CT discounts fees keep the same value always

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
      target: BigInt.from(2),
    );
    final normalBitcoinFees = await bitcoinBlockchain?.estimateFee(
      target: BigInt.from(6),
    );
    final slowBitcoinFees = await bitcoinBlockchain?.estimateFee(
      target: BigInt.from(12),
    );
    final liquidFees = await liquidWallet
        .buildPartiallySignedTransaction(
          liquidBitcoinOwnedAsset,
          liquidAddress,
          1,
          1.0,
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
      bitcoinFast: fastBtcPsbt.feeAmount ?? 0,
      bitcoinNormal: normalBtcPsbt.feeAmount ?? 0,
      bitcoinSlow: slowBtcPsbt.feeAmount ?? 0,
      liquid: liquidFees ?? 0,
    );
  }
}
