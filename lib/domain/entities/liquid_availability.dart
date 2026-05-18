/// Tri-state availability of the Liquid layer.
///
/// Replaces the implicit "Liquid ready == LWK connected" assumption
/// that pre-2026-05-18 callers used. The Liquid stack actually has
/// **two** providers — `LiquidWalletServiceImpl` (LWK, on-chain
/// authoritative) and `LightningWalletServiceImpl` (Breez Liquid SDK,
/// the L-BTC pool watcher) — so availability is properly a function
/// of both.
///
/// UI gating contract:
///
///   - [unavailable]: render loading / hard-error state. Neither
///     provider can serve Liquid data.
///   - [degraded]: render the timeline / balances / swaps as normal.
///     **Do NOT block on LWK.** Breez is operational and the persisted
///     transaction store has whatever Breez has reconciled so far.
///     The source-aware upsert will reconcile field-level when LWK
///     eventually connects — UI does not need to coordinate.
///   - [operational]: render normally. LWK is authoritative; all
///     classifications are final.
///
/// Computation contract (`liquidAvailabilityProvider`):
///   - If LWK is `ServiceLifecycle.connected` → [operational].
///   - Else if Breez (Lightning service) is `connected` → [degraded].
///   - Else → [unavailable].
enum LiquidAvailability {
  unavailable,
  degraded,
  operational,
}
