import 'dart:async';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as breez;

import '../../domain/entities/chain.dart';

/// Builds a [breez.Config] for the given network and working directory.
class BreezConfigFactory {
  BreezConfigFactory({required this.workingDir, this.apiKey});

  /// Already-acquired absolute path on disk for the Breez working dir.
  final String workingDir;
  final String? apiKey;

  Future<breez.Config> build(AppNetwork network) async {
    final liquidNetwork = switch (network) {
      AppNetwork.mainnet => breez.LiquidNetwork.mainnet,
      AppNetwork.testnet => breez.LiquidNetwork.testnet,
      AppNetwork.regtest => breez.LiquidNetwork.regtest,
    };
    final defaults = breez.defaultConfig(network: liquidNetwork);

    return breez.Config(
      liquidExplorer: defaults.liquidExplorer,
      bitcoinExplorer: defaults.bitcoinExplorer,
      workingDir: workingDir,
      network: liquidNetwork,
      paymentTimeoutSec: defaults.paymentTimeoutSec,
      useDefaultExternalInputParsers: defaults.useDefaultExternalInputParsers,
      breezApiKey: apiKey ??
          const String.fromEnvironment('BREEZ_API_KEY', defaultValue: ''),
      assetMetadata: const [
        breez.AssetMetadata(
          assetId:
              '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
          name: 'DePix',
          ticker: 'DEPIX',
          precision: 8,
        ),
      ],
      useMagicRoutingHints: true,
      onchainSyncPeriodSec: 20,
      onchainSyncRequestTimeoutSec: 10,
    );
  }
}
