import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/receive_crypto_input.dart';

part 'receive_invoice_provider.g.dart';

@riverpod
class ReceiveInvoiceNotifier extends _$ReceiveInvoiceNotifier {
  @override
  ReceiveCryptoInput build() {
    return ReceiveCryptoInput(network: Network.bitcoin);
  }

  void updateAmount(int amount) {
    state = state.copyWith(recvAmount: amount);
  }

  void updateNetwork(Network network) {
    state = state.copyWith(network: network);
  }

  void updateAssetId(String assetId) {
    state = state.copyWith(assetId: assetId);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }
}
