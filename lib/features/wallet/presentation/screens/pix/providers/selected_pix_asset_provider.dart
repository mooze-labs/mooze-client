import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/entities/asset.dart';

import 'selected_tab_provider.dart';

final selectedPixAssetProvider = StateProvider<Asset>((ref) {
  final selectedTab = ref.watch(selectedTabProvider);
  return switch (selectedTab) {
    0 => Asset.depix,
    1 => Asset.btc,
    _ => Asset.depix,
  };
});
