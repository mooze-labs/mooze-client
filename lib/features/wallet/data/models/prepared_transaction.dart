import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prepared_transaction.freezed.dart';

@freezed
sealed class PreparedTransaction with _$PreparedTransaction {
  const factory PreparedTransaction.onchain(PreparePayOnchainResponse res) =
      OnchainPsbt;

  const factory PreparedTransaction.l2(PrepareSendResponse res) = L2Psbt;
}
