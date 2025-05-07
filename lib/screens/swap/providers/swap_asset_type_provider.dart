import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_asset_type_provider.g.dart';

@Riverpod(keepAlive: true)
class SwapAssetTypeNotifier extends _$SwapAssetTypeNotifier {
  @override
  String build() {
    return 'Base';
  }

  void updateAssetType(String newValue) {
    state = newValue;
  }
}
