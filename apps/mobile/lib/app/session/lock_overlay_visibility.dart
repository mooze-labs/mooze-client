/// Pure resolution of what the global overlay should paint, given the two
/// independent security states. Extracted from the widget so the rule can be
/// unit tested without pumping a widget tree.
///
/// Rules:
///   - An opaque cover is shown whenever the privacy shield is up OR the
///     session is locked.
///   - Authentication takes precedence while the session is locked: the locked
///     [VerifyPinScreen] is itself an opaque cover, and letting the shield front
///     it would interrupt biometrics and loop the PIN screen.
///   - The privacy shield therefore only fronts when the session is unlocked.
({bool showCover, bool showAuthentication}) resolveLockOverlay({
  required bool privacyShieldVisible,
  required bool sessionLocked,
}) {
  return (
    showCover: privacyShieldVisible || sessionLocked,
    showAuthentication: sessionLocked,
  );
}
