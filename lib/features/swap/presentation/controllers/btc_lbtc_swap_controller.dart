import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';

import 'package:mooze_mobile/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class BtcLbtcFeeEstimate {
  final BigInt boltzServiceFeeSat;
  final BigInt networkFeeSat;
  final BigInt totalFeeSat;

  BtcLbtcFeeEstimate({
    required this.boltzServiceFeeSat,
    required this.networkFeeSat,
    required this.totalFeeSat,
  });
}

class BtcLbtcSwapController {
  final WalletController _walletController;

  BtcLbtcSwapController(this._walletController);

  static const int minSwapAmount = 25000;

  TaskEither<String, BtcLbtcFeeEstimate> prepareFeeEstimate({
    required BigInt amount,
    required bool isPegIn,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (kDebugMode) {
      print(
        '[BtcLbtcSwapController] prepareFeeEstimate - amount: $amount, isPegIn: $isPegIn, drain: $drain, feeRate: $feeRateSatPerVByte',
      );
    }

    if (!drain && amount < BigInt.from(minSwapAmount)) {
      return TaskEither.left('Quantidade mínima é $minSwapAmount sats');
    }

    if (isPegIn) {
      return _walletController
          .preparePegInFullFees(
            amount: amount,
            feeRateSatPerVByte: feeRateSatPerVByte,
          )
          .mapLeft((error) => 'Erro ao preparar peg-in: $error')
          .map((fees) {
            if (kDebugMode) {
              print(
                '✅ [PegIn] Taxas - Breez (service): ${fees.breezFeesSat} sats, BDK (network): ${fees.bdkFeesSat} sats (${feeRateSatPerVByte ?? 3} sat/vB), Total: ${fees.breezFeesSat + fees.bdkFeesSat} sats',
              );
            }
            return BtcLbtcFeeEstimate(
              boltzServiceFeeSat: fees.breezFeesSat,
              networkFeeSat: fees.bdkFeesSat,
              totalFeeSat: fees.breezFeesSat + fees.bdkFeesSat,
            );
          });
    } else {
      return _walletController.getBitcoinReceiveAddress().flatMap(
        (bitcoinAddress) => _walletController
            .beginNewTransaction(
              destination: bitcoinAddress,
              asset: Asset.lbtc,
              blockchain: Blockchain.bitcoin,
              amount: amount,
              feeRateSatPerVByte: feeRateSatPerVByte,
              drain: drain,
            )
            .mapLeft((error) => 'Erro ao preparar peg-out: $error')
            .map((psbt) {
              final claimFee =
                  (psbt is PreparedOnchainBitcoinTransaction)
                      ? (psbt.claimFeesSat ?? BigInt.zero)
                      : BigInt.zero;
              final serviceFee = psbt.networkFees - claimFee;

              if (kDebugMode) {
                print(
                  '[PegOut] Total fees: ${psbt.networkFees} sats, Claim (network): $claimFee sats, Service (Boltz): $serviceFee sats',
                );
              }

              return BtcLbtcFeeEstimate(
                boltzServiceFeeSat: serviceFee,
                networkFeeSat: claimFee,
                totalFeeSat: psbt.networkFees,
              );
            }),
      );
    }
  }

  TaskEither<String, Transaction> executePegIn({
    required BigInt amount,
    int? feeRateSatPerVByte,
  }) {
    if (amount < BigInt.from(minSwapAmount)) {
      return TaskEither.left('Quantidade mínima é $minSwapAmount sats');
    }

    return _walletController.executePegIn(
      amount: amount,
      feeRateSatPerVByte: feeRateSatPerVByte,
    );
  }

  TaskEither<String, Transaction> executePegOut({
    required BigInt amount,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (!drain && amount < BigInt.from(minSwapAmount)) {
      return TaskEither.left('Quantidade mínima é $minSwapAmount sats');
    }

    return _walletController.getBitcoinReceiveAddress().flatMap(
      (bitcoinAddress) => _walletController.executePegOut(
        btcAddress: bitcoinAddress,
        amount: amount,
        feeRateSatPerVByte: feeRateSatPerVByte,
        drain: drain,
      ),
    );
  }

  bool isValidAmount(BigInt? amount) {
    if (amount == null) return false;
    return amount >= BigInt.from(minSwapAmount);
  }

  String formatSatsToBtc(BigInt sats) {
    final btc = sats.toDouble() / 100000000;
    return btc.toStringAsFixed(8);
  }
}
