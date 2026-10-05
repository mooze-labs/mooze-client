import '../entities/chain.dart';

/// Result of a single chain sync (or aggregate across all chains).
class SyncOutcome {
  const SyncOutcome({
    required this.chain,
    required this.fetched,
    required this.changed,
    required this.duration,
  });

  final ChainId chain;
  final int fetched;
  final int changed;
  final Duration duration;

  static SyncOutcome empty(ChainId chain) => SyncOutcome(
        chain: chain,
        fetched: 0,
        changed: 0,
        duration: Duration.zero,
      );
}
