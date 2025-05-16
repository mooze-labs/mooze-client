import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/repositories/wallet/bitcoin.dart';
import 'package:mooze_mobile/repositories/wallet/liquid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_fee_provider.g.dart';

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
    try {
      NetworkFee? bitcoinFast;
      NetworkFee? bitcoinNormal;
      NetworkFee? bitcoinSlow;
      NetworkFee? liquid;

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

      if (liquidBitcoinOwnedAsset.amount > 100) {
        try {
          final liquidFeeAmount = await liquidWallet
              .buildPartiallySignedTransaction(
                liquidBitcoinOwnedAsset,
                liquidAddress,
                1,
                null,
              )
              .then((psbt) => psbt.feeAmount);
          liquid = NetworkFee(absoluteFees: liquidFeeAmount ?? 0, feeRate: 1);
        } catch (e) {
          liquid = NetworkFee(absoluteFees: 40, feeRate: 1);
        }
      }

      if (bitcoinOwnedAsset.amount > 1000) {
        try {
          final fastBtcPsbt = await bitcoinWallet
              .buildPartiallySignedTransaction(
                bitcoinOwnedAsset,
                bitcoinAddress,
                546,
                fastBitcoinFees?.satPerVb,
              );
          bitcoinFast = NetworkFee(
            absoluteFees: fastBtcPsbt.feeAmount ?? 0,
            feeRate: fastBitcoinFees?.satPerVb ?? 0,
          );
        } catch (e) {
          bitcoinFast = NetworkFee(absoluteFees: 300, feeRate: 0);
        }
      }

      if (bitcoinOwnedAsset.amount > 547) {
        try {
          final normalBtcPsbt = await bitcoinWallet
              .buildPartiallySignedTransaction(
                bitcoinOwnedAsset,
                bitcoinAddress,
                546,
                normalBitcoinFees?.satPerVb,
              );
          bitcoinNormal = NetworkFee(
            absoluteFees: normalBtcPsbt.feeAmount ?? 0,
            feeRate: normalBitcoinFees?.satPerVb ?? 0,
          );
        } catch (e) {
          bitcoinNormal = NetworkFee(absoluteFees: 200, feeRate: 0);
        }
      }

      if (bitcoinOwnedAsset.amount > 547) {
        try {
          final slowBtcPsbt = await bitcoinWallet
              .buildPartiallySignedTransaction(
                bitcoinOwnedAsset,
                bitcoinAddress,
                546,
                slowBitcoinFees?.satPerVb,
              );
          bitcoinSlow = NetworkFee(
            absoluteFees: slowBtcPsbt.feeAmount ?? 0,
            feeRate: slowBitcoinFees?.satPerVb ?? 0,
          );
        } catch (e) {
          bitcoinSlow = NetworkFee(absoluteFees: 100, feeRate: 0);
        }
      }

      return NetworkFees(
        bitcoinFast: bitcoinFast ?? NetworkFee(absoluteFees: 300, feeRate: 0),
        bitcoinNormal:
            bitcoinNormal ?? NetworkFee(absoluteFees: 200, feeRate: 0),
        bitcoinSlow: bitcoinSlow ?? NetworkFee(absoluteFees: 100, feeRate: 0),
        liquid: liquid ?? NetworkFee(absoluteFees: 40, feeRate: 1),
      );
    } catch (e) {
      return NetworkFees(
        bitcoinFast: NetworkFee(absoluteFees: 300, feeRate: 4),
        bitcoinNormal: NetworkFee(absoluteFees: 200, feeRate: 2),
        bitcoinSlow: NetworkFee(absoluteFees: 100, feeRate: 1),
        liquid: NetworkFee(absoluteFees: 40, feeRate: 1),
      );
    }
  }
}
