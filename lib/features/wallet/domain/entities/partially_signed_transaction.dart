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
