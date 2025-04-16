import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/models/liquid.dart';
import 'package:mooze_mobile/services/liquid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final liquidAssetServiceProvider = Provider<LiquidAssetService>(
  (ref) => LiquidAssetService(),
);

@riverpod
final liquidAssetProvider = FutureProvider.family<LiquidAsset, (String, bool)>((
  ref,
  params,
) async {
  final assetId = params.$1;
  final mainnet = params.$2;
  final service = ref.watch(liquidAssetServiceProvider);

  final asset = await service.fetchAsset(assetId, mainnet);
  return asset ??
      LiquidAsset(
        assetId: assetId,
        network: Network.mainnet,
        name: 'Unknown',
        precision: 8,
        ticker: 'UNK',
      );
});
