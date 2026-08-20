import 'package:fpdart/fpdart.dart';

import '../entities/balance.dart';
import '../entities/refund.dart';
import '../failures/failure.dart';
import 'spendable_wallet_service.dart';
import 'wallet_service.dart';

/// Breez-Liquid–backed service.
///
/// **Naming note:** despite "Lightning" in the name, this service is the
/// Breez Liquid SDK adapter — which natively handles BOTH Lightning
/// (BOLT-11 / LNURL) AND Liquid on-chain payments (L-BTC + Liquid assets
/// like USDt, DePix). Legacy code routes every Liquid send/receive
/// through this same SDK, NOT through LWK; LWK is a passive read view
/// for sync, balances, tx-history, and swap PSET signing.
///
/// To match that legacy reality and avoid implementing a parallel
/// LWK-based send pipeline (which `lwk-dart` does not even expose a
/// broadcast API for), the V2 service implements both:
///
///   - [SpendableWalletService] for Liquid on-chain (`SendRequest.chain
///     == ChainId.liquid`). Bitcoin on-chain (`ChainId.bitcoin`) is
///     rejected here — it lives on `BitcoinWalletService` (BDK).
///
/// The `chain` field on this service stays `ChainId.lightning` for
/// orchestrator iteration and tx-stream tagging; the spendable surface
/// dispatches internally based on `SendRequest.chain`. Renaming the
/// service to remove the "Lightning" framing is parked for Phase 2.7
/// cleanup — it's a wide rename touching DI providers and not load-
/// bearing for the migration.
///
/// Lifecycle: connect/disconnect is exclusive at the SDK level (only
/// one Breez client may hold the working dir at a time), so the impl
/// gates them under a per-instance mutex and a workdir lock.
abstract interface class LightningWalletService
    implements WalletService, SpendableWalletService {
  /// Best-effort onchain swap rescan within the given lookback window.
  /// Used to recover funds sent to previously-issued swap addresses.
  Future<Either<ServiceFailure, Unit>> rescan({required Duration window});

  /// Re-fetch the SDK's balance view and update the internal cache
  /// WITHOUT running a full chain sync. Useful right after a broadcast
  /// (e.g. SideSwap) where the caller wants to nudge the cached balance
  /// without paying for a fresh electrum scan.
  ///
  /// Breez here re-runs a single `getInfo()` and remaps `_lastBalance`.
  /// Returns the freshly-cached value. Falls back to the previous
  /// cache if `getInfo()` fails (best-effort — never throws).
  Future<Either<ServiceFailure, Balance>> refreshBalance();

  /// Apply known per-asset deltas to the cached `_lastBalance` for
  /// instant UI feedback. Used after broadcasts that the SDK does NOT
  /// observe immediately — primarily SideSwap, where the broadcast
  /// goes through the SideSwap server (not Breez), so neither
  /// `getInfo()` nor `sync()` reflects the new state until the
  /// next electrum scan picks up the mempool entry.
  ///
  /// [deltas] maps Liquid asset id → signed sat delta. The L-BTC
  /// asset uses [lbtcAssetId]. Negative values shrink the cached
  /// balance, positive grow it. Missing asset ids leave that asset
  /// untouched. Cache is overwritten on the next successful `sync()`.
  Future<Either<ServiceFailure, Balance>> applyOptimisticBalanceDelta({
    required Map<String, int> deltas,
  });

  // ─────────────────────────────────────────── refund surface
  //
  // Refunds reclaim funds from stuck or expired submarine swaps. The
  // Breez Liquid SDK exposes the underlying `listRefundables` /
  // `prepareRefund` / `refund` calls; this surface translates them into
  // V2 domain types (`RefundableSwap`, `MempoolFees`, etc.) so feature
  // and UI layers don't import `flutter_breez_liquid`.

  /// List swaps eligible for refund. Empty list means nothing pending.
  Future<Either<ServiceFailure, List<RefundableSwap>>> listRefundables();

  /// Look up the Breez chain-swap id that owns [lockupTxId] (the BDK
  /// peg-in send or LWK peg-out send broadcasted to a Boltz lockup
  /// address). Returns the short opaque id Breez uses internally —
  /// e.g. `wCaunaTNZaHv` — or `null` if no matching payment exists
  /// yet (Breez has not observed the lockup in `listPayments`).
  ///
  /// Used by the optimistic-swap watcher to enrich its locally-
  /// stored pending row with the real swap id once Breez has wired
  /// the lockup tx to a Payment record. Without this, the UI would
  /// keep showing the lockup txid as the "Swap ID" — which is wrong:
  /// the lockup tx and the swap are different entities with
  /// different lifecycles.
  Future<Either<ServiceFailure, String?>> findChainSwapIdByLockup({
    required String lockupTxId,
  });

  /// Current mempool-policy fee suggestions, used to populate refund fee
  /// pickers. UI should treat failure as "use fallback values" and
  /// degrade gracefully — refunds without recommended fees still work,
  /// just at a fixed rate.
  Future<Either<ServiceFailure, MempoolFees>> recommendedFees();

  /// Prepare a refund tx so the UI can display exact fees before
  /// broadcasting. No on-chain state change.
  Future<Either<ServiceFailure, PrepareRefundOutcome>> prepareRefund(
    PrepareRefundParams params,
  );

  /// Build, sign, and broadcast the refund tx. Returns the on-chain
  /// txid of the refund. Like other broadcast paths, the resulting tx
  /// is also persisted via the orchestrator's tx-event pipeline.
  Future<Either<ServiceFailure, RefundOutcome>> executeRefund(
    ExecuteRefundParams params,
  );

  // ─────────────────────────────────────────── peg surface
  //
  // Peg operations cross the Bitcoin ↔ L-BTC boundary via Breez submarine
  // swaps. Peg-out is Breez-end-to-end. Peg-in produces a Bitcoin deposit
  // address — the actual on-chain Bitcoin tx that funds it is built and
  // broadcast by `BitcoinWalletService` (BDK), orchestrated at the
  // repository boundary.
}
