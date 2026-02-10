import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart';

final networkProvider = Provider<Network>((ref) {
  final network = switch (String.fromEnvironment(
    "BLOCKCHAIN_NETWORK_TYPE",
    defaultValue: "mainnet",
  )) {
    "mainnet" => Network.mainnet,
    "testnet" => Network.testnet,
    "regtest" => Network.testnet,
    _ => throw ArgumentError("Invalid network specified"),
  };

  return network;
});
