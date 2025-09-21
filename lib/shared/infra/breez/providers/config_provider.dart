import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:path_provider/path_provider.dart';

final configProvider = FutureProvider<Config>((ref) async {
  const breezApiKey =
      'MIIBajCCARygAwIBAgIHPgbGnsVq8TAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjUwNDI5MDEyNDI5WhcNMzUwNDI3MDEyNDI5WjArMRMwEQYDVQQKEwpNb296ZSBMYWJzMRQwEgYDVQQDEwtMdWNjYSBHb2RveTAqMAUGAytlcAMhANCD9cvfIDwcoiDKKYdT9BunHLS2/OuKzV8NS0SzqV13o3oweDAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwHwYDVR0jBBgwFoAU3qrWklbzjed0khb8TLYgsmsomGswGAYDVR0RBBEwD4ENZGV2QG1vb3plLmFwcDAFBgMrZXADQQAx9hoGj97ubdjFT/C7KqEZOOSVV2C8HHIw4D6//NG9mEJPB1Mc9HTvWmEFaIKhz1vdH6z5zQDyw9RJV4Ej7tEL';
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
