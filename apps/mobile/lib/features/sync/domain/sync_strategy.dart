enum SyncStrategy {
  /// Refresh balances and tx state across all connected chains.
  light,

  /// Light + onchain swap rescan + pending refunds (Lightning).
  full,
}
