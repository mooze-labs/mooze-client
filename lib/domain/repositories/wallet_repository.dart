import 'package:fpdart/fpdart.dart';

import '../entities/asset.dart';
import '../entities/balance.dart';
import '../entities/broadcast_result.dart';
import '../entities/chain.dart';
import '../entities/fee_estimate.dart';
import '../entities/liquid_utxo.dart';
import '../entities/payment_limits.dart';
import '../entities/peg.dart';
import '../entities/receive_address.dart';
import '../entities/refund.dart';
import '../entities/send_request.dart';
import '../entities/transaction.dart';
import '../failures/failure.dart';

/// High-level domain API for the wallet. Built on top of the chain services
/// and the transaction store. Use cases depend only on this abstraction.
abstract interface class WalletRepository {
  // ─────────────────────────────────────────── reads
  Stream<List<Transaction>> watchTransactions({ChainFilter? filter});
  Future<Either<Failure, List<Transaction>>> listTransactions({
    ChainFilter? filter,
    int? limit,
  });
  Future<Either<Failure, Balance>> aggregateBalance();

  /// Resolve the balance for a single primary asset, fanning out to the
  /// chain services per [AssetChains.resolutionChains] priority. Returns
  /// `BigInt.zero` when no chain has the asset (preserving legacy semantics —
  /// the UI never sees `null`/error for an asset the user hasn't received yet).
  ///
  /// Errors from the underlying services are folded — if the priority chain
  /// fails, the next chain in the list is tried. Only when ALL chains fail is
  /// a [Failure] returned.
  Future<Either<Failure, BigInt>> balanceFor(Asset asset);

  /// Bulk-fetch balances for several assets in one fan-out. Cheaper than
  /// calling [balanceFor] in a loop because each chain service is hit at most
  /// once. The legacy `Map<Asset, BigInt>` shape is preserved.
  Future<Either<Failure, Map<Asset, BigInt>>> balanceMap(List<Asset> assets);

  /// Stream of [BigInt] for a single asset. Emits the current value on
  /// subscribe (via the same fan-out as [balanceFor]) and re-emits on every
  /// merged transaction event from the sync orchestrator. Internally
  /// debounced so a 200-tx import burst produces a small constant number of
  /// emissions, NOT one per tx.
  Stream<BigInt> watchBalanceFor(Asset asset);

  // ─────────────────────────────────────────── send / receive (Liquid)
  //
  // Phase 2.5-Liquid scope. Bitcoin and Lightning analogues land in their
  // respective Phase 2.5 sub-phases — they will follow the same shape so
  // the UI can switch on the destination chain to pick the entry point.
  //
  // All three Liquid methods route to `LightningWalletService` (the V2
  // service backing Breez Liquid SDK), preserving the legacy reality that
  // Breez owns the active Liquid send/receive engine. LWK is read-only
  // sync + swap PSET signing.

  /// Estimate fees for a Liquid on-chain send (L-BTC or asset). Pure: does
  /// not build, sign, or broadcast. The returned [FeeEstimate.absoluteFeeSat]
  /// is the SDK-computed fee for THIS specific payment shape — re-call
  /// when the user changes the amount/destination.
  Future<Either<Failure, FeeEstimate>> estimateLiquidSend(SendRequest request);

  /// Generate a Liquid receive address (or asset-specific receive). The
  /// SDK persists this internally so the eventual incoming payment is
  /// matched back to it; the caller does NOT need to record anything.
  Future<Either<Failure, ReceiveAddress>> liquidReceiveAddress({
    String? assetId,
    String? label,
  });

  /// Build, sign, and broadcast a Liquid on-chain send. On success the
  /// resulting [Transaction] is also persisted via the orchestrator's
  /// single-writer `transactionStore.upsert` path BEFORE this method
  /// returns — callers reading the store immediately after will see it.
  Future<Either<Failure, BroadcastResult>> sendLiquid(SendRequest request);

  // ─────────────────────────────────────────── send / receive (Bitcoin)
  //
  // Phase 2.5-Bitcoin scope. Mirrors the Liquid contract above so a
  // dispatcher in the UI can switch on `request.chain` cleanly. All three
  // route to `BitcoinWalletService` (BDK-backed); BDK's TxBuilder handles
  // fee estimation and PSBT construction, the wallet signs, and the
  // Electrum blockchain handle broadcasts.

  /// Estimate fees for a Bitcoin on-chain send. Pure: builds a PSBT to
  /// read [TransactionDetails.fee], discards it. Re-call when the user
  /// changes amount / destination / fee priority. The `assetId` field on
  /// [SendRequest] MUST be null — BDK does not handle asset transfers.
  Future<Either<Failure, FeeEstimate>> estimateBitcoinSend(SendRequest request);

  /// Generate a Bitcoin receive address. Walks BDK's descriptor forward
  /// from `lastUnused` until it finds an address whose script does not
  /// appear in any wallet UTXO or historical output, then pins BDK's
  /// internal counter past it (preserving the legacy "no double-used
  /// address" guarantee). Returns the address as a bech32 / legacy string.
  Future<Either<Failure, ReceiveAddress>> bitcoinReceiveAddress({String? label});

  /// Build, sign, and broadcast a Bitcoin on-chain send. PSBT is rebuilt
  /// inside this call (NOT reusing an estimate's PSBT) so UTXO selection
  /// runs against the current wallet state — avoids double-spending a
  /// UTXO consumed between estimate and send. The resulting [Transaction]
  /// is persisted via the orchestrator's single-writer pipeline before
  /// this method returns.
  Future<Either<Failure, BroadcastResult>> sendBitcoin(SendRequest request);

  // ─────────────────────────────────────────── send / receive (Lightning)
  //
  // Phase 2.5-Lightning. Lightning is a *transport rail* on top of the
  // unified Liquid balance — there is no separate Lightning balance
  // domain (per product clarification 2026-05-06). Outgoing Lightning
  // payments debit the L-BTC pool; incoming Lightning settlements
  // credit it. UI shows the rail in tx history but balances aggregate
  // through `Asset.lbtc`.
  //
  // Two-step flow (prepare → send) preserves user-review-before-pay UX
  // and matches Breez's native API shape; the prepared object is opaque
  // and round-trips through the UI.

  /// Prepare a Lightning send. Parses the destination string (BOLT-11
  /// invoice, LNURL-pay endpoint, or Lightning Address — exactly one set
  /// in [LightningSendRequest]) and runs Breez's prepare phase, returning
  /// a [PreparedLightningSend] the UI can render fees from. Does NOT
  /// commit the payment.
  Future<Either<Failure, PreparedLightningSend>> prepareLightningSend(
      LightningSendRequest request);

  /// Commit a previously-prepared Lightning send. The prepared token
  /// MUST be the exact one returned from [prepareLightningSend] — it
  /// carries Breez's `PrepareSendResponse` / `PrepareLnUrlPayResponse`
  /// internally. On success the resulting [Transaction] is persisted
  /// via the orchestrator's single-writer pipeline before this method
  /// returns; the L-BTC balance reflects the debit on next read.
  Future<Either<Failure, BroadcastResult>> sendLightning(
      PreparedLightningSend prepared);

  /// Generate a Lightning invoice (BOLT-11) for receiving the given
  /// amount. The eventual settlement is a Lightning HTLC routed through
  /// the LSP, settled into the L-BTC pool — visible to the user as an
  /// L-BTC balance increase tagged Lightning in tx history.
  Future<Either<Failure, ReceiveAddress>> createLightningInvoice({
    required int amountSat,
    String? description,
    Duration? expiry,
  });

  // ─────────────────────────────────────────── chain metadata
  //
  // Surfaces UI screens read directly from the SDKs in legacy. Routed
  // through the repository here so feature/UI files don't need to read
  // chain-service providers — the wallet repository remains the single
  // boundary for SDK access.

  /// Current Bitcoin chain tip height (Electrum). Used by tx-history UI
  /// to compute confirmation counts. Failure means "unknown" — the UI
  /// should render gracefully without blocking.
  Future<Either<Failure, int>> getCurrentBitcoinBlockHeight();

  // ─────────────────────────────────────────── refund surface
  //
  // Recovery flow for stuck or expired Lightning swaps. Routed through
  // `LightningWalletService` (Breez Liquid SDK), translated to V2
  // domain types so feature/UI layers don't import the Breez SDK.

  Future<Either<Failure, List<RefundableSwap>>> listRefundableSwaps();

  Future<Either<Failure, MempoolFees>> getRecommendedFees();

  Future<Either<Failure, PrepareRefundOutcome>> prepareRefund(
      PrepareRefundParams params);

  Future<Either<Failure, RefundOutcome>> executeRefund(
      ExecuteRefundParams params);

  // ─────────────────────────────────────────── swap surface (LWK-backed)
  //
  // SideSwap PayJoin requires three things from the wallet:
  //   1. UTXO enumeration (caller picks inputs).
  //   2. A confidential receive address (where the swap proceeds land).
  //   3. PSET signing (server constructs the PSET, wallet signs its
  //      own inputs).
  //
  // All three live on the LWK service in V2 — Breez Liquid SDK does
  // not expose raw PSET signing. The repository routes through there.

  /// Enumerate the wallet's spendable Liquid UTXOs as V2 domain types.
  /// The swap repository filters by asset and selects a covering set
  /// before handing UTXOs off to SideSwap.
  Future<Either<Failure, List<LiquidUtxo>>> getLiquidUtxos();

  /// Sign a SideSwap-supplied PSET. Caller passes the mnemonic per
  /// call; the repository (and underlying service) does NOT cache it.
  Future<Either<Failure, String>> signSwapPset({
    required String pset,
    required String mnemonic,
  });

  /// Liquid receive address used by the swap flow. Same data path as
  /// `liquidReceiveAddress(assetId: null)` but documented separately
  /// to make the swap-call-site grep clean.
  Future<Either<Failure, String>> getLiquidSwapAddress();

  // ─────────────────────────────────────────── payment limits
  //
  // Single normalised shape — chain-specific behaviour lives in the impl
  // (Lightning derives from the LSP offer, on-chain from network dust +
  // fee floor). Consumers pick a chain and read min/max for both directions.

  Future<Either<Failure, PaymentLimits>> fetchLimits(ChainId chain);

  // ─────────────────────────────────────────── peg-in / peg-out
  //
  // Cross-stack balance transitions between Bitcoin and L-BTC. Stateless
  // prepare/execute pair — execute re-derives the swap from the canonical
  // request rather than consuming a prepared token. No opaque round-trips.

  /// Prepare a peg-in (Bitcoin → L-BTC). Returns a quote with the swap
  /// server's bitcoinAddress, fees, and final amount. Does NOT broadcast.
  Future<Either<Failure, PegInQuote>> preparePegIn(PegInRequest request);

  /// Execute the peg-in: build, sign, and broadcast a Bitcoin tx to the
  /// swap server's address. Resulting tx is persisted via the sync
  /// orchestrator's single-writer pipeline before this method returns.
  Future<Either<Failure, BroadcastResult>> executePegIn(PegInRequest request);

  /// Prepare a peg-out (L-BTC → Bitcoin). Returns a quote with total
  /// fees and the BTC amount that will land at the destination.
  Future<Either<Failure, PegOutQuote>> preparePegOut(PegOutRequest request);

  /// Execute the peg-out: instructs Breez to settle the swap onto the
  /// user-supplied BTC address. Resulting tx is persisted via the sync
  /// orchestrator's single-writer pipeline before this method returns.
  Future<Either<Failure, BroadcastResult>> executePegOut(PegOutRequest request);
}
