import '../typedefs.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../enums/blockchain.dart';

class PaymentRequest {
  final Address address;
  final Blockchain blockchain;
  final Asset asset;
  final BigInt fees;
  final BigInt? amount;
  final String? description;

  PaymentRequest({
    required this.address,
    required this.blockchain,
    required this.asset,
    required this.fees,
    this.amount,
    this.description = '',
  });
}
