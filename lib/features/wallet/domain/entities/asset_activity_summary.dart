import 'package:mooze_mobile/shared/entities/asset.dart';

/// Aggregated, non-investment view of a single asset's wallet activity.
///
/// Every monetary field is expressed in the asset's base unit (satoshis for
/// BTC/L-BTC, 10^-8 units for USDT/Depix) so callers format with the same
/// rules the rest of the wallet uses. Deliberately carries no cost-basis,
/// P/L, or performance data — this is a history/activity summary, not a
/// portfolio analytic.
class AssetActivitySummary {
  final Asset asset;

  /// Number of transactions that involve [asset] (sends, receives, and any
  /// swap/peg with [asset] on either leg).
  final int transactionCount;

  /// Sum of every value that entered the wallet as [asset].
  final BigInt totalReceived;

  /// Sum of every value that left the wallet as [asset].
  final BigInt totalSent;

  /// [totalReceived] + [totalSent] — the gross value moved through [asset].
  final BigInt totalVolume;

  /// Largest single received amount of [asset].
  final BigInt largestReceive;

  /// Largest single sent amount of [asset].
  final BigInt largestSend;

  /// Timestamp of the earliest recorded movement, or null when there is none.
  final DateTime? firstActivity;

  /// Timestamp of the most recent recorded movement, or null when there is
  /// none.
  final DateTime? lastActivity;

  const AssetActivitySummary({
    required this.asset,
    required this.transactionCount,
    required this.totalReceived,
    required this.totalSent,
    required this.totalVolume,
    required this.largestReceive,
    required this.largestSend,
    required this.firstActivity,
    required this.lastActivity,
  });

  /// Empty summary for an asset the wallet has never moved.
  factory AssetActivitySummary.empty(Asset asset) => AssetActivitySummary(
    asset: asset,
    transactionCount: 0,
    totalReceived: BigInt.zero,
    totalSent: BigInt.zero,
    totalVolume: BigInt.zero,
    largestReceive: BigInt.zero,
    largestSend: BigInt.zero,
    firstActivity: null,
    lastActivity: null,
  );

  bool get hasActivity => transactionCount > 0;
}
