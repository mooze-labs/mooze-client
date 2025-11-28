import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class WalletController {
  final WalletRepository _walletRepository;

  WalletController(WalletRepository walletRepository)
    : _walletRepository = walletRepository;

  TaskEither<String, PartiallySignedTransaction> beginNewTransaction({
    required String destination,
    required Asset asset,
    required Blockchain blockchain,
    required BigInt amount,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (kDebugMode) {
      print(
        '[WalletController] beginNewTransaction - drain: $drain, asset: $asset, blockchain: $blockchain, amount: $amount, feeRate: $feeRateSatPerVByte sat/vB',
      );
    }

    if (drain) {
      return beginDrainTransaction(
        destination: destination,
        asset: asset,
        blockchain: blockchain,
        amount: amount,
        feeRateSatPerVByte: feeRateSatPerVByte,
      );
    }

    if (asset != Asset.btc && asset != Asset.lbtc) {
      final stablecoinAmount =
          (amount / BigInt.from(pow(10, 8))).roundToDouble();
      final psbt = _walletRepository.buildStablecoinPaymentTransaction(
        destination,
        asset,
        stablecoinAmount,
      );

      return psbt.mapLeft((err) => err.description);
    }

    switch (blockchain) {
      case Blockchain.bitcoin:
        return _buildOnchainPsbt(
          destination,
          amount,
          feeRateSatPerVByte,
          asset,
        );
      case Blockchain.lightning:
        return _walletRepository
            .buildLightningPaymentTransaction(destination, amount)
            .mapLeft((err) => err.description);
      case Blockchain.liquid:
        return _walletRepository
            .buildLiquidBitcoinPaymentTransaction(destination, amount)
            .mapLeft((err) => err.description);
    }
  }

  TaskEither<String, PartiallySignedTransaction> beginDrainTransaction({
    required String destination,
    required Asset asset,
    required Blockchain blockchain,
    required BigInt amount,
    int? feeRateSatPerVByte,
  }) {
    if (asset != Asset.btc && asset != Asset.lbtc) {
      return _walletRepository
          .buildDrainStablecoinTransaction(destination, asset)
          .mapLeft((err) => err.description);
    }

    switch (blockchain) {
      case Blockchain.bitcoin:
        return _walletRepository
            .buildDrainOnchainBitcoinTransaction(
              destination,
              asset: asset,
              feeRateSatPerVbyte: feeRateSatPerVByte,
            )
            .mapLeft((err) {
              return err.description;
            });
      case Blockchain.lightning:
        return _walletRepository
            .buildDrainLightningTransaction(destination)
            .mapLeft((err) => err.description);
      case Blockchain.liquid:
        return _walletRepository
            .buildDrainLiquidBitcoinTransaction(destination)
            .mapLeft((err) => err.description);
    }
  }

  TaskEither<String, Transaction> confirmTransaction({
    required PartiallySignedTransaction psbt,
  }) {
    switch (psbt) {
      case PreparedOnchainBitcoinTransaction():
        return _walletRepository
            .sendOnchainBitcoinPayment(psbt)
            .mapLeft((err) => err.description);
      case PreparedLayer2BitcoinTransaction():
        return _walletRepository
            .sendL2BitcoinPayment(psbt)
            .mapLeft((err) => err.description);
      case PreparedStablecoinTransaction():
        return _walletRepository
            .sendStablecoinPayment(psbt)
            .mapLeft((err) => err.description);
    }
  }

  TaskEither<String, PartiallySignedTransaction> _buildOnchainPsbt(
    String destination,
    BigInt amount,
    int? feeRateSatPerVByte, [
    Asset? asset,
  ]) {
    return _walletRepository
        .buildOnchainBitcoinPaymentTransaction(
          destination,
          amount,
          feeRateSatPerVByte,
          asset,
        )
        .mapLeft((err) {
          return err.description;
        });
  }

  TaskEither<String, String> getBitcoinReceiveAddress() {
    return _walletRepository.getBitcoinReceiveAddress().mapLeft(
      (err) => err.description,
    );
  }

  TaskEither<String, String> getLiquidReceiveAddress() {
    return _walletRepository.getLiquidReceiveAddress().mapLeft(
      (err) => err.description,
    );
  }

  TaskEither<String, Transaction> executePegOut({
    required String btcAddress,
    required BigInt amount,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (kDebugMode) {
      print(
        '✅ [WalletController] Iniciando peg-out - amount: $amount sats, drain: $drain, feeRate: $feeRateSatPerVByte sat/vB',
      );
    }

    return _walletRepository
        .fetchOnchainLimits()
        .mapLeft((err) => err.description)
        .flatMap((limits) {
          if (kDebugMode) {
            print(
              '✅ [PegOut] Limites obtidos - Min: ${limits.minSat} sats, Max: ${limits.maxSat} sats',
            );
          }

          if (!drain) {
            if (amount < limits.minSat) {
              return TaskEither<String, Transaction>.left(
                'Valor insuficiente. Mínimo: ${limits.minSat} sats',
              );
            }

            if (amount > limits.maxSat) {
              return TaskEither<String, Transaction>.left(
                'Valor inválido. Máximo: ${limits.maxSat} sats',
              );
            }
          }

          return _walletRepository
              .preparePegOut(
                receiverAmountSat: amount,
                feeRateSatPerVbyte: feeRateSatPerVByte,
                drain: drain,
              )
              .mapLeft((err) => err.description)
              .flatMap((totalFeesSat) {
                if (kDebugMode) {
                  print(
                    '✅ [PegOut] Peg-out preparado - Total de taxas: $totalFeesSat sats',
                  );
                }

                return _walletRepository
                    .executePegOut(
                      btcAddress: btcAddress,
                      receiverAmountSat: amount,
                      totalFeesSat: totalFeesSat,
                      feeRateSatPerVbyte: feeRateSatPerVByte,
                      drain: drain,
                    )
                    .mapLeft((err) => err.description);
              });
        });
  }
}
