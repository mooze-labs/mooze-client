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
    SendRequest request,
  );
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
