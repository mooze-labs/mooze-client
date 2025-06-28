import 'package:mooze_mobile/features/wallet/data/breez/models/prepared_transaction.dart';

class PartiallySignedTransactionSession {
  final PreparedTransaction psbt;
  final int expireAt;

  PartiallySignedTransactionSession({
    required this.psbt,
    required this.expireAt,
  });
}
