import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

StateProvider<Asset> assetProvider = StateProvider<Asset>((ref) {
  return Asset.btc;
});
