import 'chain.dart';

/// Fee priority hint passed by the UI / use case to fee estimation. The infra
/// layer is free to interpret these (fee-rate buckets vary by chain — sat/vB
/// for Bitcoin/Liquid mempool, off-chain fixed fees for Lightning, etc.).
enum FeePriority {
  /// Best-effort low fee — may take many blocks to confirm. Default for
  /// non-time-sensitive flows.
  low,

  /// Sensible default — confirm within a few blocks under normal mempool.
  medium,

  /// Confirm in the next block at typical mempool levels.
  high,
}

/// A fee quote returned by [WalletService.estimateFee] (extension surface).
///
/// Held in domain so the UI never has to know about chain-specific units
/// (sat/vB, payment-fee, route-fee) — for Lightning the [feeRateSatPerVByte]
/// is null and only [absoluteFeeSat] matters. For on-chain it's the inverse:
/// [absoluteFeeSat] is the per-tx fee at the current size, [feeRateSatPerVByte]
/// is the underlying rate the user can re-quote against.
class FeeEstimate {
  const FeeEstimate({
    required this.chain,
    required this.priority,
    required this.absoluteFeeSat,
    this.feeRateSatPerVByte,
    this.estimatedBlocks,
  });

  final ChainId chain;
  final FeePriority priority;

  /// Total fee for this specific transaction in satoshis (or asset minimal
  /// units for Liquid asset transfers, where the fee is still in L-BTC sats).
  final int absoluteFeeSat;

  /// On-chain fee rate. Null for Lightning.
  final double? feeRateSatPerVByte;

  /// Best-effort confirmation horizon. Null when not applicable (Lightning).
  final int? estimatedBlocks;
}
