import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_base_asset_provider.g.dart';

@riverpod
class SwapBaseAssetNotifier extends _$SwapBaseAssetNotifier {
  @override
  String? build() {
    return null;
  }

  void updateBaseAsset(String? newValue) {
    state = newValue;
  }
}