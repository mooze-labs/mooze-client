import '../../../domain/entities/chain.dart';

/// Tunable sync parameters. One ticker, one cadence, per-chain timeouts.
///
/// Cadence decision (Phase 2.0, V2_PHASE2_PARITY_AND_MIGRATION §6):
/// Legacy `WalletDataManager._periodicSyncTimer` ran at 40 s. V2 keeps the
/// 2-minute default because the chain services are expected to push
/// `TransactionEvent`s themselves (BDK Electrum push, LWK Electrum push,
/// Breez SDK websocket), so the periodic tick is a fallback / drift-correction,
/// not the primary update path. A 2-minute fallback halves device wakeups
/// and battery cost without losing the "balance updates within seconds"
/// expectation, since pushed events still drive the orchestrator's tx
/// stream and `transactionStore.upsert` immediately.
///
/// If a service is verified to NOT push (e.g. an Electrum endpoint without
/// scripthash subscription support), reconsider this cadence.
class SyncConfig {
  const SyncConfig({
    this.tick = const Duration(minutes: 2),
    this.liquidTimeout = const Duration(seconds: 60),
    this.bitcoinTimeout = const Duration(seconds: 60),
    this.lightningTimeout = const Duration(seconds: 45),
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
