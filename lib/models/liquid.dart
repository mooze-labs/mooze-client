import 'dart:convert';
import 'package:lwk/lwk.dart';

class LiquidAsset {
  final String assetId;
  final Network network;
  final String name;
  final int precision;
  final String ticker;

  factory LiquidAsset.fromLocal(
    String assetId,
    Network network,
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
    network: json['network'] == "liquid" ? Network.mainnet : Network.testnet,
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
    "network": network == Network.mainnet ? "liquid" : "liquidtestnet",
    "name": name,
    "precision": precision,
    "ticker": ticker,
  };
}
