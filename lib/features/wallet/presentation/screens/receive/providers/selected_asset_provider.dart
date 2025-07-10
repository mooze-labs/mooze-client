import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/entities/asset.dart';

import 'selected_tab_provider.dart';

final StateProvider<Asset> selectedAssetProvider = StateProvider<Asset>((ref) {
  final index = ref.watch(selectedTabProvider);
  return switch (index) {
    0 => Asset.depix,
    1 => Asset.btc,
    2 => Asset.usdt,
    _ => Asset.btc,
  };
});
