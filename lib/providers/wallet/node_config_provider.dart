import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/repositories/wallet/node_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'node_config_provider.g.dart';

@riverpod
NodeConfigRepository nodeConfigRepository(Ref ref) {
  return NodeConfigRepository(
    bitcoinNode: defaultBitcoinNode,
    liquidNode: defaultLiquidNode,
    breezApiKey: defaultBreezApiKey,
    network: Network.mainnet,
  );
}
