import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

final configProvider = Provider<Config>((ref) {
  final breezApiKey = String.fromEnvironment('BREEZ_API_KEY');
  final network = switch (String.fromEnvironment(
    "BLOCKCHAIN_NETWORK_TYPE",
    defaultValue: "mainnet",
  )) {
    "mainnet" => LiquidNetwork.mainnet,
    "testnet" => LiquidNetwork.testnet,
    "regtest" => LiquidNetwork.regtest,
    _ => throw ArgumentError("Invalid network specified"),
  };

  Config config = defaultConfig(network: network, breezApiKey: breezApiKey);

  return config;
});
