import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:path_provider/path_provider.dart';

final configProvider = FutureProvider<Config>((ref) async {
  final breezApiKey = String.fromEnvironment('BREEZ_API_KEY');
  final workingDir = await getApplicationDocumentsDirectory();
  final network = switch (String.fromEnvironment(
    "BLOCKCHAIN_NETWORK_TYPE",
    defaultValue: "mainnet",
  )) {
    "mainnet" => LiquidNetwork.mainnet,
    "testnet" => LiquidNetwork.testnet,
    "regtest" => LiquidNetwork.regtest,
    _ => throw ArgumentError("Invalid network specified"),
  };

  final defaultBreezConfig = defaultConfig(network: network);

  Config config = Config(
      liquidExplorer: defaultBreezConfig.liquidExplorer,
      bitcoinExplorer: defaultBreezConfig.bitcoinExplorer,
      workingDir: "${workingDir.path}/mooze",
      network: network,
      paymentTimeoutSec: defaultBreezConfig.paymentTimeoutSec,
      useDefaultExternalInputParsers: defaultBreezConfig.useDefaultExternalInputParsers,
      breezApiKey: breezApiKey
  );

  return config;
});
