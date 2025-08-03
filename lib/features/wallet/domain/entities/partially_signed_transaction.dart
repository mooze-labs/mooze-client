import 'dart:math';

import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

sealed class PartiallySignedTransaction {
  String get destination;
  Asset get asset;
  Blockchain get blockchain;

  BigInt get satoshi;
  BigInt get networkFees;
}

class PreparedStablecoinTransaction implements PartiallySignedTransaction {

  @override
  final String destination;
  @override
  final Asset asset;
  @override
  final Blockchain blockchain = Blockchain.liquid;
  @override
  final BigInt networkFees;

  final double amount;
  @override
  BigInt get satoshi => BigInt.from((amount * pow(10, 8)));


  PreparedStablecoinTransaction({
    required this.destination,
    required this.asset,
    required this.amount,
    required this.networkFees
  });
}

class PreparedLayer2BitcoinTransaction implements PartiallySignedTransaction {
  @override
  final String destination;
  @override
  final BigInt networkFees;
  @override
  final Blockchain blockchain;
  @override
  Asset get asset => Asset.btc;

  final BigInt amount;
  @override
  BigInt get satoshi => amount;

  PreparedLayer2BitcoinTransaction({required this.destination, required this.amount, required this.networkFees, required this.blockchain});
}

class PreparedOnchainBitcoinTransaction implements PartiallySignedTransaction {
  @override
  final String destination;
  @override
  final BigInt networkFees;
  @override
  final Blockchain blockchain = Blockchain.bitcoin;
  @override
  Asset get asset => Asset.btc;

  final BigInt amount;
  @override
  BigInt get satoshi => amount;

  PreparedOnchainBitcoinTransaction({required this.destination, required this.amount, required this.networkFees});
}