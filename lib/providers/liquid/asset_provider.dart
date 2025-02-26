import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/models/liquid/asset.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

part 'asset_provider.g.dart';

final liquidAssetServiceProvider = Provider<LiquidAssetService>(
  (ref) => LiquidAssetService(),
);

@riverpod
final liquidAssetProvider =
    FutureProvider.family<LiquidAsset, (String, Network)>((ref, params) async {
      final assetId = params.$1;
      final network = params.$2;
      final service = ref.watch(liquidAssetServiceProvider);

      final asset = await service.fetchAsset(assetId, network);
      return asset ??
          LiquidAsset(
            assetId: assetId,
            network: network,
            name: 'Unknown',
            precision: 8,
            ticker: 'UNK',
          );
    });
