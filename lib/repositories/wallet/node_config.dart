import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

const String defaultBitcoinNode = "blockstream.info:110";
const String defaultLiquidNode = "blockstream.info:995";

enum Network { mainnet, testnet, regtest }

class NodeConfigRepository {
  String _bitcoinNode;
  String _liquidNode;
  Network _network;

  NodeConfigRepository({
    required String bitcoinNode,
    required String liquidNode,
    required Network network,
  }) : _bitcoinNode = bitcoinNode,
       _liquidNode = liquidNode,
       _network = network;

  String get bitcoinNode => _bitcoinNode;
  String get liquidNode => _liquidNode;

  Network get network => _network;

  void setBitcoinNode(String bitcoinNode) {
    _bitcoinNode = bitcoinNode;
  }

  void setLiquidNode(String liquidNode) {
    _liquidNode = liquidNode;
  }

  void setNetwork(Network network) {
    _network = network;
  }
}

@riverpod
NodeConfigRepository nodeConfigRepository(Ref ref) {
  return NodeConfigRepository(
    bitcoinNode: defaultBitcoinNode,
    liquidNode: defaultLiquidNode,
    network: Network.mainnet,
  );
}
