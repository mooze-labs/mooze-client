import 'chain.dart';

/// Liquid asset IDs. These are stable, network-wide constants — DO NOT change
/// without coordinated migration. Mirrors `lib/shared/entities/asset.dart` so
/// existing wallets resolve the same assets after the V2 cutover.
const String btcNativeAssetId = 'btc-native-blockchain';
const String lbtcAssetId =
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';
const String usdtAssetId =
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';
const String depixAssetId =
    '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189';

/// The four primary asset classes the wallet exposes.
///
/// Ported from legacy `lib/shared/entities/asset.dart`. **Domain-level only:**
/// formatting / icons / display-name extensions belong in presentation
/// (legacy keeps them on the same enum; V2 separates them to keep the domain
/// pure and re-usable without Flutter).
///
/// An [Asset] is *not* a chain — `Asset.btc` is BTC across BDK and Lightning,
/// `Asset.lbtc` is L-BTC across Liquid (LWK) and Breez-Liquid. The repository
/// resolves per-asset balances by fanning out to the chain services in a
/// documented priority order (see `WalletRepositoryImpl.balanceFor`).
enum Asset {
  btc,
  lbtc,
  depix,
  usdt;

  /// Stable asset ID. For BTC this is the synthetic constant `btc-native-blockchain`
  /// since BTC has no Liquid asset ID; for Liquid assets it is the network ID.
  String get id => switch (this) {
        Asset.btc => btcNativeAssetId,
        Asset.lbtc => lbtcAssetId,
        Asset.usdt => usdtAssetId,
        Asset.depix => depixAssetId,
      };

  /// True if the asset is BTC (i.e. BTC-native, not Liquid). Useful to skip
  /// Liquid-asset-id matching when resolving balances.
  bool get isNativeBitcoin => this == Asset.btc;

  /// Decimals — sats for Bitcoin/Liquid-Bitcoin (8), 8 for the Liquid stables
  /// (preserved from legacy).
  int get precision => 8;

  /// Resolve an [Asset] from its on-chain asset ID. Returns null if no
  /// match — callers MUST handle the null case rather than defaulting to BTC,
  /// which the legacy code did silently and which masked routing bugs.
  static Asset? fromId(String id) => switch (id) {
        btcNativeAssetId => Asset.btc,
        lbtcAssetId => Asset.lbtc,
        usdtAssetId => Asset.usdt,
        depixAssetId => Asset.depix,
        _ => null,
      };
}

/// The set of chains that may carry balance for a given [Asset]. Domain-level
/// — used by `WalletRepositoryImpl` to fan out to the right services.
extension AssetChains on Asset {
  /// Chains that can hold this asset, in resolution-priority order.
  ///
  /// **Order matters and preserves legacy semantics**
  /// (`WalletRepositoryImpl.getBalance` in legacy):
  ///
  /// - `Asset.btc`     → bitcoin only (legacy reads BDK; does NOT fall back
  ///                     to Lightning BTC. Preserved here so user balance
  ///                     numbers don't shift after migration.)
  /// - `Asset.lbtc`    → lightning first (Breez Liquid view), then liquid
  ///                     (LWK on-chain) as fallback.
  /// - `Asset.usdt`    → same as `lbtc` — lightning first, then liquid.
  /// - `Asset.depix`   → same as `lbtc`.
  ///
  /// If product later wants `Asset.btc` to sum BDK + Lightning BTC, that is
  /// a deliberate behaviour change (not a parity port) — track it as a
  /// separate decision and update this list.
  List<ChainId> get resolutionChains => switch (this) {
        Asset.btc => const [ChainId.bitcoin],
        Asset.lbtc => const [ChainId.lightning, ChainId.liquid],
        Asset.usdt => const [ChainId.lightning, ChainId.liquid],
        Asset.depix => const [ChainId.lightning, ChainId.liquid],
      };
}
