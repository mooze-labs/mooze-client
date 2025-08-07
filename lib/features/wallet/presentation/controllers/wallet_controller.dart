import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/features/wallet/data/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class WalletController {
  final WalletRepository _walletRepository;

  WalletController(WalletRepository walletRepository) : _walletRepository = walletRepository;

  TaskEither<String, PartiallySignedTransaction> beginNewTransaction(
      String destination,
      Asset asset,
      Blockchain blockchain,
      BigInt amount,
      ) {
    if (asset != Asset.btc) {
      final stablecoinAmount = (amount / BigInt.from(pow(10, 8))).roundToDouble();
      final psbt = _walletRepository.buildStablecoinPaymentTransaction(destination, asset, stablecoinAmount);

      return psbt.mapLeft((err) => err.description);
    }

    switch (blockchain) {
      case Blockchain.bitcoin: return _buildOnchainPsbt(destination, amount);
      case Blockchain.lightning: return _walletRepository.buildLightningPaymentTransaction(destination, amount)
          .mapLeft((err) => err.description);
      case Blockchain.liquid: return _walletRepository.buildLiquidBitcoinPaymentTransaction(destination, amount)
          .mapLeft((err) => err.description);
    }
  }

  TaskEither<String, Transaction> confirmTransaction(PartiallySignedTransaction psbt) {
    switch (psbt) {
      case PreparedOnchainBitcoinTransaction(): return _walletRepository.sendOnchainBitcoinPayment(psbt)
          .mapLeft((err) => err.description);
      case PreparedLayer2BitcoinTransaction(): return _walletRepository.sendL2BitcoinPayment(psbt)
          .mapLeft((err) => err.description);
      case PreparedStablecoinTransaction(): return _walletRepository.sendStablecoinPayment(psbt)
          .mapLeft((err) => err.description);
    }
  }

  TaskEither<String, PartiallySignedTransaction> _buildOnchainPsbt(String destination, BigInt amount) {
    if (amount < BigInt.from(25000)) return TaskEither.left("Quantidade deve ser maior que 25000 sats");

    return _walletRepository.buildOnchainBitcoinPaymentTransaction(destination, amount).mapLeft(
        (err) => err.description
    );
  }
}