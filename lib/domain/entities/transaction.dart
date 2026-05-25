import 'chain.dart';

/// Direction of a transaction relative to the wallet.
///
///   - [incoming]: funds entered the wallet from an outside source.
///   - [outgoing]: funds left the wallet to an outside destination.
///   - [selfTransfer]: funds moved between wallet-owned addresses
///     (UTXO consolidation, peg-out preimage redeposit, swap-leg
///     internal change, etc). Only the network fee is consumed; the
///     asset balance is preserved. UI surfaces these as "Redeposit".
///   - [swap]: a single transaction that moved one asset out of the
///     wallet and a different asset in. Detected from mixed-sign
///     multi-asset balance entries in LWK. The wallet's net balance
///     across all assets is approximately conserved (fee paid in
///     L-BTC). Swap-leg data is carried in [Transaction.fromAssetId]
///     / [Transaction.toAssetId] / [Transaction.sentAmountSat] /
///     [Transaction.receivedAmountSat].
///   - [internal]: mixed-sign movement that does NOT fit any of the
///     above (Breez fee adjustments, unresolvable LWK kinds like
///     issuance/burn/reissuance). Reserved as a catch-all.
///
/// Classification priority (LWK) is:
/// `selfTransfer` → `swap` → `incoming`/`outgoing` → `internal`.
/// Self-transfer wins over swap so a fee-only consolidation that
/// happens to touch multiple assets isn't misclassified as a swap.
enum TransactionDirection { incoming, outgoing, internal, selfTransfer, swap }

enum TransactionStatus { pending, confirmed, failed }

/// Origin of a transaction row in the persisted store. Used by the
/// source-aware upsert merge to decide which fields a writer is
/// authoritative for.
///
/// **Authority matrix (chain=liquid):**
///   - [TransactionSource.lwk] wins for `direction`, `status`,
///     `amountSat`, `feeSat`, `confirmations`, `assetId`, `timestamp`.
///   - [TransactionSource.breez] writes survive only when LWK has not
///     written yet (degraded mode), and its metadata
///     (`address`, `label`) is preserved via COALESCE even after LWK
///     reconciles the authoritative fields.
///
/// **chain=lightning and chain=bitcoin** have a single natural writer
/// (Breez and BDK respectively), so the source priority is a no-op
/// there. The tag is still recorded for observability + future
/// extension.
enum TransactionSource { lwk, breez, bdk }

/// Domain transaction. Contains only fields the wallet needs across chains.
/// SDK-specific metadata stays inside the infra layer.
class Transaction {
  const Transaction({
    required this.id,
    required this.chain,
    required this.direction,
    required this.status,
    required this.amountSat,
    required this.feeSat,
    required this.timestamp,
    this.confirmations = 0,
    this.assetId,
    this.address,
    this.label,
    this.fromAssetId,
    this.toAssetId,
    this.sentAmountSat,
    this.receivedAmountSat,
    this.source,
    this.swapLockupTxId,
    this.swapClaimTxId,
  });

  final String id;
  final ChainId chain;
  final TransactionDirection direction;
  final TransactionStatus status;

  /// Amount in satoshis (or asset minimal units, when [assetId] is set).
  /// Sign convention: always positive; use [direction] to interpret.
  ///
  /// For [TransactionDirection.swap] this carries the **sent** leg
  /// (mirrors the headline amount the user thinks of as "I swapped X").
  /// The receive leg lives in [receivedAmountSat]. UI renders both
  /// when present (see `HomeTransactionItem._buildSwapSubtitle`).
  final int amountSat;
  final int feeSat;
  final DateTime timestamp;
  final int confirmations;

  /// Optional asset id for Liquid transactions. For swaps, this echoes
  /// [fromAssetId] (the headline / sent asset) so existing UI that
  /// reads `tx.assetId` keeps working.
  final String? assetId;
  final String? address;
  final String? label;

  // ─────────────────────────────────────────── swap-pair surface
  //
  // Populated by `LiquidWalletServiceImpl._mapTx` when a single
  // transaction's balance entries show mixed-sign multi-asset
  // movement (legacy heuristic, see `wallet_repository_impl/liquid.dart`).
  // For non-swap rows these are all null.
  //
  // The home transaction list (`transaction_list.dart`) renders a
  // single "Swap from X to Y" row when both `fromAsset` and `toAsset`
  // are set in the legacy mirror — see the v2→legacy adapter for the
  // pass-through.

  final String? fromAssetId;
  final String? toAssetId;
  final int? sentAmountSat;
  final int? receivedAmountSat;

  /// Which chain service produced this row. Nullable for rows persisted
  /// before the source-aware migration (treated as "non-LWK" by the
  /// upsert merge so the first LWK reconciliation overrides them).
  /// See [TransactionSource] for the authority matrix.
  final TransactionSource? source;

  /// For Breez chain-swap rows (peg-in claim, peg-out send) this is the
  /// txid of the Bitcoin-side lockup tx. On a peg-in that's the user's
  /// BDK send (the BTC funding the swap); on a peg-out that's the
  /// Liquid-side lockup tx Breez itself broadcast (and equals the row's
  /// `id`). Lets the home unifier pair the BDK and Breez halves of a
  /// peg-swap by EXACT id linkage instead of guessing by amount + time
  /// (the previous approach mis-paired an unrelated BTC withdrawal with
  /// a same-amount peg-in claim).
  ///
  /// Null for everything that isn't a Breez chain-swap leg.
  final String? swapLockupTxId;

  /// Twin of [swapLockupTxId] for the destination side of the swap.
  /// Peg-in: the Liquid claim txid Breez observed (= the row's `id`).
  /// Peg-out: the Bitcoin claim txid the user receives at their BDK
  /// wallet. Lets the unifier identify the BDK receive that completes
  /// a peg-out without amount guessing.
  final String? swapClaimTxId;

  Transaction copyWith({
    TransactionStatus? status,
    int? confirmations,
    String? label,
  }) {
    return Transaction(
      id: id,
      chain: chain,
      direction: direction,
      status: status ?? this.status,
      amountSat: amountSat,
      feeSat: feeSat,
      timestamp: timestamp,
      confirmations: confirmations ?? this.confirmations,
      assetId: assetId,
      address: address,
      label: label ?? this.label,
      fromAssetId: fromAssetId,
      toAssetId: toAssetId,
      sentAmountSat: sentAmountSat,
      receivedAmountSat: receivedAmountSat,
      source: source,
      swapLockupTxId: swapLockupTxId,
      swapClaimTxId: swapClaimTxId,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'chain': chain.name,
        'direction': direction.name,
        'status': status.name,
        'amount_sat': amountSat,
        'fee_sat': feeSat,
        'timestamp_ms': timestamp.millisecondsSinceEpoch,
        'confirmations': confirmations,
        'asset_id': assetId,
        'address': address,
        'label': label,
        'from_asset_id': fromAssetId,
        'to_asset_id': toAssetId,
        'sent_amount_sat': sentAmountSat,
        'received_amount_sat': receivedAmountSat,
        'source': source?.name,
        'swap_lockup_tx_id': swapLockupTxId,
        'swap_claim_tx_id': swapClaimTxId,
      };

  static Transaction fromMap(Map<String, Object?> m) {
    final sourceStr = m['source'] as String?;
    return Transaction(
      id: m['id'] as String,
      chain: ChainId.values.byName(m['chain'] as String),
      direction:
          TransactionDirection.values.byName(m['direction'] as String),
      status: TransactionStatus.values.byName(m['status'] as String),
      amountSat: (m['amount_sat'] as num).toInt(),
      feeSat: (m['fee_sat'] as num).toInt(),
      timestamp:
          DateTime.fromMillisecondsSinceEpoch((m['timestamp_ms'] as num).toInt()),
      confirmations: (m['confirmations'] as num?)?.toInt() ?? 0,
      assetId: m['asset_id'] as String?,
      address: m['address'] as String?,
      label: m['label'] as String?,
      fromAssetId: m['from_asset_id'] as String?,
      toAssetId: m['to_asset_id'] as String?,
      sentAmountSat: (m['sent_amount_sat'] as num?)?.toInt(),
      receivedAmountSat: (m['received_amount_sat'] as num?)?.toInt(),
      // Unknown source string (corrupt or post-rollback state) parses
      // as null — equivalent to a legacy pre-migration row.
      source: sourceStr == null
          ? null
          : TransactionSource.values.where((s) => s.name == sourceStr).firstOrNull,
      swapLockupTxId: m['swap_lockup_tx_id'] as String?,
      swapClaimTxId: m['swap_claim_tx_id'] as String?,
    );
  }
}
