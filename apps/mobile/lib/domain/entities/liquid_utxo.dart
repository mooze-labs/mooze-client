/// Domain representation of a Liquid UTXO, exposed for the swap flow
/// (SideSwap-style PayJoin coin-join needs caller-supplied input lists
/// with full unblinding metadata).
///
/// Field shapes mirror the underlying LWK `TxOut.unblinded` structure
/// (asset / asset_bf / value / value_bf) so the swap repository can
/// hand them to the SideSwap server via JSON-encoding helpers without
/// type translation overhead. Keeps `lwk` SDK types out of feature
/// imports.
library;

class LiquidUtxo {
  const LiquidUtxo({
    required this.txid,
    required this.vout,
    required this.assetId,
    required this.assetBlindingFactor,
    required this.valueSat,
    required this.valueBlindingFactor,
  });

  /// Outpoint txid (32-byte hex).
  final String txid;

  /// Outpoint output index.
  final int vout;

  /// On-chain asset id (Liquid asset hash). Same shape used elsewhere
  /// in the V2 domain (`Asset.id`, `AssetBalance.assetId`).
  final String assetId;

  /// Asset blinding factor (hex). Required by SideSwap to decompose the
  /// confidential commitment server-side.
  final String assetBlindingFactor;

  /// Value in satoshis (or asset minimal units when [assetId] is a
  /// non-L-BTC asset).
  final BigInt valueSat;

  /// Value blinding factor (hex). Same role as the asset BF.
  final String valueBlindingFactor;
}
