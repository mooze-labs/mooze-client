import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:path_provider/path_provider.dart';

final configProvider = FutureProvider<Config>((ref) async {
  const breezApiKey = String.fromEnvironment('BREEZ_API_KEY');
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
    useDefaultExternalInputParsers:
        defaultBreezConfig.useDefaultExternalInputParsers,
    breezApiKey: breezApiKey,
    assetMetadata: [
      AssetMetadata(
        assetId:
            "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
        name: "DePix",
        ticker: "DEPIX",
        precision: 8,
      ),
    ],
    useMagicRoutingHints: true,
  );

  return config;
});
