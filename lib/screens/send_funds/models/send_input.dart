import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';

class SendInput {
  final Asset? asset;
  final String address;
  final int amount;
  NetworkFee? networkFee;

  SendInput({
    this.asset = null,
    this.address = "",
    this.amount = 0,
    this.networkFee = null,
  });

  SendInput copyWith({
    Asset? asset,
    String? address,
    int? amount,
    NetworkFee? networkFee,
  }) {
    return SendInput(
      asset: asset ?? this.asset,
      address: address ?? this.address,
      amount: amount ?? this.amount,
      networkFee: networkFee ?? this.networkFee,
    );
  }
}
