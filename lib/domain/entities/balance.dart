import 'chain.dart';

/// Per-asset balance. For Bitcoin/Lightning the assetId is null and the chain
/// implies BTC. For Liquid, the assetId is the L-BTC or token id.

class AssetBalance {
  const AssetBalance({
    required this.chain,
    required this.amountSat,
    this.assetId,
    this.precision = 8,
    this.ticker,
    this.pendingSat = 0,
  });
  final ChainId chain;
  final String? assetId;
  final int amountSat;
  final int precision;
  final String? ticker;
  final int pendingSat;
}

class Balance {
  const Balance({required this.assets, required this.snapshotAt});
  final List<AssetBalance> assets;
  final DateTime snapshotAt;

  int totalSatForChain(ChainId chain) =>
      assets.where((a) => a.chain == chain).fold(0, (a, b) => a + b.amountSat);

  int pendingSatForChain(ChainId chain) =>
      assets.where((a) => a.chain == chain).fold(0, (a, b) => a + b.pendingSat);

  static Balance empty() => Balance(assets: const [], snapshotAt: DateTime.fromMillisecondsSinceEpoch(0));
}
