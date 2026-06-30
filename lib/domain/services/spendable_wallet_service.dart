import 'package:fpdart/fpdart.dart';

import '../entities/broadcast_result.dart';
import '../entities/fee_estimate.dart';
import '../entities/receive_address.dart';
import '../entities/send_request.dart';
import '../failures/failure.dart';

/// On-chain "send + receive" capability mixed onto a [WalletService] when the
/// underlying SDK supports building, signing, and broadcasting transactions.
///
/// Both `BitcoinWalletService` and `LiquidWalletService` extend this. The
/// `LightningWalletService` does NOT — Lightning has different semantics
/// (no fee-rate, prepared payment token), captured by
/// [SpendableLightningService] below.
///
/// Single-write rule: every successful `broadcast()` MUST hand the resulting
/// transaction to the orchestrator's tx pipeline via the same path the
/// per-service `transactions` stream uses. Implementations achieve this by
/// emitting a `TransactionEvent` synthetically right after the broadcast
/// succeeds, which the orchestrator then upserts into the store before
/// republishing. Bypassing the orchestrator is a migration violation.
abstract interface class SpendableWalletService {
  /// Estimate the fee for a hypothetical transaction. Pure: does not build,
  /// does not sign, does not broadcast.
  Future<Either<ServiceFailure, FeeEstimate>> estimateFee(SendRequest request);

  /// Derive the next unused receive address (on-chain) — the service is
  /// responsible for advancing its receive-index pointer.
  Future<Either<ServiceFailure, ReceiveAddress>> nextReceiveAddress({
    String? assetId,
    String? label,
  });

  /// Build, sign, and broadcast a transaction. Returns once the tx has been
  /// accepted by the network mempool (on-chain) or by the LSP (Lightning).
  Future<Either<ServiceFailure, BroadcastResult>> sendOnchain(
      SendRequest request);
}

/// Lightning-specific spendable surface. Two-step (prepare → send) because
/// the prepare step does the route-probing and amount-resolution work that
/// the user must review before the payment goes out.
abstract interface class SpendableLightningService {
  Future<Either<ServiceFailure, PreparedLightningSend>> prepareSend(
      LightningSendRequest request);

  Future<Either<ServiceFailure, BroadcastResult>> sendLightning(
      PreparedLightningSend prepared);

  /// Receive flow: produces a BOLT-11 invoice (or LNURL-pay metadata if the
  /// SDK supports it). The caller is responsible for displaying the invoice;
  /// the listener for the eventual settlement is the service's regular
  /// `transactions` stream.
  Future<Either<ServiceFailure, ReceiveAddress>> createInvoice({
    required int amountSat,
    String? description,
    Duration? expiry,
  });

  /// Limits surfaced by the LSP — used by the UI to gate the amount picker.
  /// Returned as a generic structure so that domain layer doesn't import the
  /// SDK's `LightningPaymentLimitsResponse` type.
  Future<Either<ServiceFailure, LightningPaymentLimits>> fetchLightningLimits();

  Future<Either<ServiceFailure, OnchainPaymentLimits>> fetchOnchainLimits();
}

/// Min/max payment range exposed by the LSP for off-chain payments.
class LightningPaymentLimits {
  const LightningPaymentLimits({
    required this.minSendSat,
    required this.maxSendSat,
    required this.minReceiveSat,
    required this.maxReceiveSat,
  });
  final int minSendSat;
  final int maxSendSat;
  final int minReceiveSat;
  final int maxReceiveSat;
}

/// Min/max range for swap-based onchain payments under the Lightning service
/// (e.g. Breez Liquid's "send onchain via swap" path).
class OnchainPaymentLimits {
  const OnchainPaymentLimits({
    required this.minSendSat,
    required this.maxSendSat,
    required this.minReceiveSat,
    required this.maxReceiveSat,
  });
  final int minSendSat;
  final int maxSendSat;
  final int minReceiveSat;
  final int maxReceiveSat;
}
