/// Authentication gate state for the app.
///
/// Binary: the session either requires authentication right now (`locked`) or
/// it does not (`unlocked`). Obscuring content (app-switcher snapshot, the
/// resume window) is handled separately by the privacy shield — see
/// [PrivacyShieldState]. The two cooperate in [SessionLockGate].
enum SessionLockState {
  /// Session is valid; no authentication is owed.
  unlocked,

  /// Session expired while backgrounded; a PIN / biometric challenge is
  /// required before the app becomes usable again.
  locked,
}
