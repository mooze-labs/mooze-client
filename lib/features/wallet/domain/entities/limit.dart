import 'package:mooze_mobile/core/entities/asset.dart';

class PaymentLimit {
  final Asset asset;
  final BigInt min;
  final BigInt max;

  PaymentLimit({required this.asset, required this.min, required this.max});
}
