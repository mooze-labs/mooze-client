import 'package:fpdart/fpdart.dart';

import '../entities/broadcast_result.dart';
import '../entities/peg.dart';
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
///   - [SpendableLightningService] for Lightning (BOLT-11 / LNURL).
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
    implements
        WalletService,
        SpendableWalletService,
        SpendableLightningService {
  /// Best-effort onchain swap rescan within the given lookback window.
  /// Used to recover funds sent to previously-issued swap addresses.
  Future<Either<ServiceFailure, Unit>> rescan({required Duration window});

  // ─────────────────────────────────────────── refund surface
  //
  // Refunds reclaim funds from stuck or expired submarine swaps. The
  // Breez Liquid SDK exposes the underlying `listRefundables` /
  // `prepareRefund` / `refund` calls; this surface translates them into
  // V2 domain types (`RefundableSwap`, `MempoolFees`, etc.) so feature
  // and UI layers don't import `flutter_breez_liquid`.

  /// List swaps eligible for refund. Empty list means nothing pending.
  Future<Either<ServiceFailure, List<RefundableSwap>>> listRefundables();

  /// Current mempool-policy fee suggestions, used to populate refund fee
  /// pickers. UI should treat failure as "use fallback values" and
  /// degrade gracefully — refunds without recommended fees still work,
  /// just at a fixed rate.
  Future<Either<ServiceFailure, MempoolFees>> recommendedFees();

  /// Prepare a refund tx so the UI can display exact fees before
  /// broadcasting. No on-chain state change.
  Future<Either<ServiceFailure, PrepareRefundOutcome>> prepareRefund(
      PrepareRefundParams params);

  /// Build, sign, and broadcast the refund tx. Returns the on-chain
  /// txid of the refund. Like other broadcast paths, the resulting tx
  /// is also persisted via the orchestrator's tx-event pipeline.
  Future<Either<ServiceFailure, RefundOutcome>> executeRefund(
      ExecuteRefundParams params);

  // ─────────────────────────────────────────── peg surface
  //
  // Peg operations cross the Bitcoin ↔ L-BTC boundary via Breez submarine
  // swaps. Peg-out is Breez-end-to-end. Peg-in produces a Bitcoin deposit
  // address — the actual on-chain Bitcoin tx that funds it is built and
  // broadcast by `BitcoinWalletService` (BDK), orchestrated at the
  // repository boundary.

  /// Allocate a one-time Bitcoin deposit address backed by a Breez
  /// submarine swap. The user (or this app's BDK service) sends BTC to
  /// the returned address; Breez observes the deposit and credits the
  /// L-BTC pool less [breezFeesSat]. Stateless wrt prepare/execute —
  /// caller passes the same `payerAmountSat` to the eventual BDK send.
  Future<Either<
      ServiceFailure,
      ({String bitcoinAddress, int breezFeesSat})>> preparePegInDeposit(
      {required int payerAmountSat});

  /// Quote a peg-out with Breez. Returns the swap + claim fee total and
  /// the BTC amount that will land at the destination, given the
  /// requested [receiverAmountSat] (or computed under [drain]). Does
  /// NOT settle.
  Future<Either<ServiceFailure, PegOutQuote>> preparePegOut(
    PegOutRequest request,
  );

  /// Execute a peg-out: instructs Breez to settle the swap onto
  /// [PegOutRequest.btcAddress]. Like other broadcast paths, the
  /// resulting tx is persisted via the orchestrator's tx-event pipeline
  /// before this method returns.
  Future<Either<ServiceFailure, BroadcastResult>> executePegOut(
    PegOutRequest request,
  );
}
