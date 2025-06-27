import '../enums/asset.dart';

class PartiallySignedTransaction {
  final String recipient;
  final Asset asset;
  final BigInt amount;
  final BigInt networkFees;

  PartiallySignedTransaction({
    required this.recipient,
    required this.asset,
    required this.amount,
    required this.networkFees,
  });
}
