/// Visibility of the branded app-switcher privacy shield.
///
/// Independent of authentication: the shield only hides sensitive content while
/// the app is inactive/backgrounded and in the app-switcher snapshot. It never
/// requires a PIN and is dropped the instant the app resumes. (When the session
/// has also expired, the separate [SessionLockState] keeps a cover up for auth.)
enum PrivacyShieldState {
  /// No shield — the app is fully visible and interactive.
  hidden,

  /// The branded opaque cover is up, hiding all wallet content.
  visible,
}
