import '../../../domain/entities/chain.dart';

/// Tunable sync parameters. One ticker, one cadence, per-chain timeouts.
///
/// Cadence decision (2026-05-24): the periodic tick now runs every 1 min.
/// Legacy `WalletDataManager` polled at 40 s, V2 originally backed off to
/// 2 min once the live Breez `addEventListener()` stream + BDK/LWK Electrum
/// push notifications became the primary update path. Field traces
/// showed that the periodic fallback was firing useful work (catching
/// confirmations on Bitcoin txs that don't push) and that 2 min felt
/// noticeably slow on confirmed-but-not-yet-reflected swaps. 1 min is
/// the compromise: still half the legacy cadence on battery cost, but
/// the user perceives "fresh" state without a manual pull-to-refresh.
///
/// If a service is verified to NOT push (e.g. an Electrum endpoint without
/// scripthash subscription support), reconsider this cadence.
class SyncConfig {
  const SyncConfig({
    this.tick = const Duration(minutes: 1),
    this.liquidTimeout = const Duration(seconds: 60),
    this.bitcoinTimeout = const Duration(seconds: 60),
    this.lightningTimeout = const Duration(seconds: 120),
    this.fullSyncRescanWindow = const Duration(days: 14),
    this.startupSyncOnBoot = true,
  });

  final Duration tick;
  final Duration liquidTimeout;
  final Duration bitcoinTimeout;
  final Duration lightningTimeout;
  final Duration fullSyncRescanWindow;
  final bool startupSyncOnBoot;

  Duration timeoutFor(ChainId chain) {
    switch (chain) {
      case ChainId.liquid:
        return liquidTimeout;
      case ChainId.bitcoin:
        return bitcoinTimeout;
      case ChainId.lightning:
        return lightningTimeout;
      case ChainId.aggregate:
        return liquidTimeout;
    }
  }
}
