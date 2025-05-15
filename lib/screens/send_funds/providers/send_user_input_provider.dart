import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/providers/wallet/network_fee_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/send_input.dart';

part 'send_user_input_provider.g.dart';

@riverpod
class SendUserInput extends _$SendUserInput {
  @override
  SendInput build() {
    return SendInput(asset: null, address: "", amount: 0);
  }

  void setNetworkFee(NetworkFee? networkFee) {
    state = state.copyWith(networkFee: networkFee);
  }

  void setAddress(String address) {
    state = state.copyWith(address: address);
  }

  void setAmount(int amount) {
    state = state.copyWith(amount: amount);
  }

  void setAsset(Asset? asset) {
    state = state.copyWith(asset: asset);
  }
}
