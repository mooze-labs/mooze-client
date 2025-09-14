import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final selectedAssetProvider = StateProvider<Asset>((ref) => Asset.btc);
