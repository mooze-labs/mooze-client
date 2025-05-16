import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/pix_input.dart';
import 'liquid_address_provider.dart';

part 'pix_input_provider.g.dart';

@riverpod
class PixInput extends _$PixInput {
  @override
  PixInputModel build() {
    final address = ref
        .watch(liquidAddressProvider)
        .maybeWhen(data: (address) => address, orElse: () => '');

    return PixInputModel(
      amountInCents: 0,
      asset: AssetCatalog.getById("depix")!,
      address: address,
    );
  }

  void updateAmount(int amountInCents) {
    state = state.copyWith(amountInCents: amountInCents);
  }

  void updateAsset(Asset asset) {
    state = state.copyWith(asset: asset);
  }

  void updateAddress(String address) {
    state = state.copyWith(address: address);
  }
}
