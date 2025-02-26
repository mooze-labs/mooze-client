import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lwk/lwk.dart' as liquid show Network;
import 'package:shared_preferences/shared_preferences.dart';

class LiquidAsset {
  final String assetId;
  final liquid.Network network;
  final String name;
  final int precision;
  final String ticker;

  factory LiquidAsset.fromLocal(
    String assetId,
    liquid.Network network,
    String name,
    int precision,
    String ticker,
  ) {
    return LiquidAsset(
      assetId: assetId,
      network: network,
      name: name,
      precision: precision,
      ticker: ticker,
    );
  }

  factory LiquidAsset.fromJson(Map<String, dynamic> json) => LiquidAsset(
    assetId: json['assetId'],
    network:
        json['network'] == "liquid"
            ? liquid.Network.mainnet
            : liquid.Network.testnet,
    name: json['name'],
    precision: json['precision'],
    ticker: json['ticker'],
  );

  LiquidAsset({
    required this.assetId,
    required this.network,
    required this.name,
    required this.precision,
    required this.ticker,
  });

  LiquidAsset copyWith({String? name, int? precision, String? ticker}) {
    return LiquidAsset(
      assetId: assetId,
      network: network,
      name: name ?? this.name,
      precision: precision ?? this.precision,
      ticker: ticker ?? this.ticker,
    );
  }

  Map<String, dynamic> toJson() => {
    "assetId": assetId,
    "network": network == liquid.Network.mainnet ? "liquid" : "liquidtestnet",
    "name": name,
    "precision": precision,
    "ticker": ticker,
  };
}

class LiquidAssetService {
  Future<LiquidAsset?> fetchAsset(
    String assetId,
    liquid.Network network,
  ) async {
    final endpoint =
        (network == liquid.Network.mainnet) ? "liquid" : "liquidtestnet";
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
}
