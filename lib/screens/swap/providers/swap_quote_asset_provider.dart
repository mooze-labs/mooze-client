import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_quote_asset_provider.g.dart';

@riverpod
class SwapQuoteAssetNotifier extends _$SwapQuoteAssetNotifier {
  @override
  String? build() {
    return null;
  }

  void updateQuoteAsset(String? newValue) {
    state = newValue;
  }
}
