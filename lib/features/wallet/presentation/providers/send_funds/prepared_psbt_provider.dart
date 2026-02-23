import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';

final preparedPsbtProvider = StateProvider<PartiallySignedTransaction?>(
  (ref) => null,
);
