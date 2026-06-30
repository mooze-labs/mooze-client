import '../entities/chain.dart';

/// Returns an Electrum endpoint string (host:port) for a given chain,
/// rotating through fallbacks when the current endpoint reports failure.
///
/// Production reliability gap that this closes: V2 `LiquidWalletServiceImpl`
/// originally hardcoded `'blockstream.info:995'`. If that endpoint is
/// down the wallet has no fallback. Legacy LWK / BDK datasources had a
/// 4-server rotation kept in module-level `static` state.
///
/// This abstraction keeps the rotation logic per-instance, injectable,
/// and testable. Service implementations call:
///
/// ```dart
/// final url = resolver.current(ChainId.liquid);
/// try {
///   await wallet.sync_(electrumUrl: url, validateDomain: true);
///   resolver.reportSuccess(ChainId.liquid);
/// } catch (e) {
///   resolver.reportFailure(ChainId.liquid, e);
///   rethrow;
/// }
/// ```
///
/// Implementations MUST be safe to call from any isolate that hosts the
/// service instance. State is per-resolver-instance — no statics.
abstract interface class ElectrumEndpointResolver {
  /// Current endpoint for the given chain. Implementations stick to the
  /// last-known-good endpoint until [reportFailure] crosses the failure
  /// threshold, then rotate.
  String current(ChainId chain);

  /// Record that the current endpoint produced a failure. Implementations
  /// may rotate immediately or accumulate failures before rotating.
  void reportFailure(ChainId chain, Object error);

  /// Record that the current endpoint produced a success. Resets failure
  /// counters and pins the current endpoint as preferred.
  void reportSuccess(ChainId chain);
}
