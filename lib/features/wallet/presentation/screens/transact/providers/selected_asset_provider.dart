import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/entities/asset.dart';

final StateProvider<Asset> selectedAssetProvider = StateProvider<Asset>((ref) {
  return Asset.btc;
});
