/// Identifier for the three blockchain stacks the wallet integrates.
///
/// `aggregate` is used by sync results that span multiple chains.
enum ChainId {
  liquid,
  bitcoin,
  lightning,
  aggregate;

  bool get isReal => this != ChainId.aggregate;
}

/// Network selection — controls which Electrum/Breez environment is used.
enum AppNetwork {
  mainnet,
  testnet,
  regtest;

  static AppNetwork fromName(String name) {
    return AppNetwork.values.firstWhere(
      (n) => n.name == name,
      orElse: () => AppNetwork.mainnet,
    );
  }
}

class ChainFilter {
  const ChainFilter(this.chains);
  factory ChainFilter.only(ChainId chain) => ChainFilter({chain});
  final Set<ChainId> chains;
  bool matches(ChainId c) => chains.contains(c);
}
