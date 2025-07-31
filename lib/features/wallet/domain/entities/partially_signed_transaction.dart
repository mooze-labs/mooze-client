import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class PartiallySignedTransaction {
  final String id;
  final String recipient;
  final Asset asset;
  final BigInt amount;
  final BigInt networkFees;

  PartiallySignedTransaction({
    required this.id,
    required this.recipient,
    required this.asset,
    required this.amount,
    required this.networkFees,
  });
}

class PreparedStablecoinTransaction {
  final String destination;
  final Asset asset;
  final double amount;
  final BigInt networkFees;
  final Blockchain blockchain = Blockchain.liquid;

  PreparedStablecoinTransaction({
    required this.destination,
    required this.asset,
    required this.amount,
    required this.networkFees
  });
}

class PreparedLayer2BitcoinTransaction {
  final String destination;
  final BigInt amount;
  final BigInt networkFees;
  final Blockchain blockchain;

  PreparedLayer2BitcoinTransaction({required this.destination, required this.amount, required this.networkFees, required this.blockchain});
}

class PreparedOnchainBitcoinTransaction {
  final String destination;
  final BigInt amount;
  final BigInt networkFees;
  final Blockchain blockchain = Blockchain.bitcoin;

  PreparedOnchainBitcoinTransaction({required this.destination, required this.amount, required this.networkFees});
}