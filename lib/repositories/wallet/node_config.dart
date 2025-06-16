const String defaultBitcoinNode = "blockstream.info:110";
const String defaultLiquidNode = "blockstream.info:995";
const String defaultBreezApiKey = "breez-api-key";

enum Network { mainnet, testnet, regtest }

class NodeConfigRepository {
  String _bitcoinNode;
  String _liquidNode;
  final String _breezApiKey;
  Network _network;

  NodeConfigRepository({
    required String bitcoinNode,
    required String liquidNode,
    required String breezApiKey,
    required Network network,
  }) : _bitcoinNode = bitcoinNode,
       _liquidNode = liquidNode,
       _breezApiKey = breezApiKey,
       _network = network;

  String get bitcoinNode => _bitcoinNode;
  String get liquidNode => _liquidNode;
  String get breezApiKey => _breezApiKey;
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
