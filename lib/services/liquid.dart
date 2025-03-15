import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/models/liquid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiquidAssetService {
  Future<LiquidAsset?> fetchAsset(String assetId, bool mainnet) async {
    final network = (mainnet) ? Network.mainnet : Network.testnet;
    final endpoint = (network == Network.mainnet) ? "liquid" : "liquidtestnet";
    final prefs = await SharedPreferences.getInstance();
    final cachedInfo = prefs.getString('asset_$assetId');

    if (cachedInfo != null) {
      return LiquidAsset.fromJson(jsonDecode(cachedInfo));
    }

    try {
      final response = await http.get(
        Uri.https('blockstream.info', '$endpoint/api/asset/$assetId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LiquidAsset(
          assetId: assetId,
          network: network,
          name: data['name'],
          precision: data['precision'],
          ticker: data['ticker'] ?? data['name'],
        );
      }
    } catch (e) {
      print("Error fetching asset: $e");
    }
    return null;
  }

  Future<String> fetchImageUrl(String assetId) async {
    final imageUrl = "https://liquid.network/api/v1/asset/$assetId/icon";
    return imageUrl;
  }
}
