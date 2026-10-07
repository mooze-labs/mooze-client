# Desktop native authentication with wallet PIN fallback

## Intent and agreed behavior

Give desktop users the mobile wallet's opt-in native authentication experience: Touch ID on macOS and standard Windows Hello on Windows, with the existing six-digit Mooze PIN available as a separate fallback. The user explicitly accepted Windows Hello methods including its device PIN. This is local wallet session authentication; it does not introduce passkeys, seed derivation, remote identity services, or a new custody model.

This is an architectural change because it introduces a desktop authentication boundary spanning native OS APIs, Rust session authorization, and frontend onboarding/settings/lock flows. This document is the proposed implementation specification for review.

## Existing behavior

- Mobile `BiometricSetupScreen` offers opt-in after PIN creation and persists the preference only after successful native confirmation.
- Mobile `WalletLockOverlay` automatically attempts authentication once on entry, offers retry and wallet PIN, and tracks native prompts to avoid lifecycle-triggered prompt loops. Cancellation leaves the user locked with fallback controls available.
- Desktop `WalletSession::unlock` verifies the wallet PIN, loads credentials from the OS credential store, connects the wallet, and calls `open_session`.
- Desktop session generations invalidate work after lock and other session transitions. PIN throttling lives in `session/security.rs`.
- The desktop secure store uses one OS credential item holding a map of wallet secrets. Current authentication gates application access; it does not derive an encryption key from the PIN.

## User experience

1. Keep PIN creation required. After successful creation or import, offer optional native unlock when the platform reports availability. Declining or cancelling continues normally. Existing wallets can enable it in Security settings.
2. Use platform-specific labels: “Touch ID” and “Windows Hello”. Enablement requires a successful native confirmation before saving the preference. In settings, require fresh wallet PIN verification before changing this authentication preference; onboarding can rely on the just-completed PIN setup within that same authenticated setup transition.
3. Automatically request native unlock once when a configured, enabled wallet enters the foreground lock screen. Do not launch prompts for a background window or on every render/focus event. Cancellation leaves explicit retry and “Use wallet PIN” controls; it never automatically reopens the prompt.
4. Missing hardware, missing enrollment, lockout, or native API failure leaves wallet PIN available. Treat cancellation as a normal user action, not an alarming error. Explain actionable unavailability briefly.
5. Choosing wallet PIN invalidates any pending native unlock result. Attempt cancellation where supported; do not accept a late success afterward. Serialize native prompts and prohibit competing authentication operations.
6. Keep the existing PIN confirmation for seed reveal, PIN change, and wallet removal. The feature adds session unlock only.
7. Linux and other unsupported platforms retain PIN access. Existing installs default to native unlock disabled; no migration prompt or OS prompt occurs until the user opts in.
8. Localize new UI and authentication reasons in the existing supported languages. Keep keyboard navigation, loading state, and error announcements accessible.

## Architecture

Introduce a desktop-owned native authentication port with capability discovery, verification, and cancellation/invalidation semantics. Keep OS APIs out of `mooze-core` and the frontend. Use dependency injection for deterministic tests. Represent policy decisions and authentication transitions as pure functions/enums; keep OS calls and persistence in adapters.

- macOS adapter: use Apple's LocalAuthentication framework, a fresh `LAContext`, and the biometric authentication policy for Touch ID. The app's fallback is the Mooze PIN. Do not silently switch this policy to a macOS password prompt.
- Windows adapter: use `UserConsentVerifier` availability and desktop `IUserConsentVerifierInterop::RequestVerificationForWindowAsync`, bound to the actual main-window handle. Accept standard Windows Hello verification, including its PIN. A successful result is required; all other result codes fail closed.
- Unsupported adapter: report unavailable and never return successful verification.

Tauri commands expose capability/preference status, native unlock, native unlock cancellation, and authenticated preference changes. There is no command accepting a frontend-provided `authenticated: true` or reusable success token. Rust owns native verification and session opening in the same trusted workflow. Only nonsecret availability/status information is exposed before unlock.

Persist a versioned enablement marker in the wallet's secure-store namespace, independently from ordinary display settings. Missing means disabled; malformed or unreadable state cannot enable native unlock. Wallet removal clears this marker together with the existing secret map. Mainnet, testnet, and isolated validation profiles remain separated.

Refactor the existing PIN unlock flow to share post-authentication wallet loading/session opening with native unlock. Both paths enforce configured-wallet and removal-pending checks and the same session generation rules. Native failure does not increment or clear PIN attempts. Native success does not erase PIN throttling; OS authentication and wallet PIN throttling remain separate policies.

## Concurrency and lifecycle invariants

- Associate each native request with an attempt ID and captured session generation. Before opening a session or saving enablement, recheck that the attempt is current, the wallet still exists, the preference permits the operation, and the generation is unchanged.
- Lock, wallet removal, authentication preference changes, and switching to PIN invalidate relevant pending attempts. Late callbacks cannot unlock or enable authentication for a replacement wallet.
- Avoid holding the main wallet mutex over an interactive OS prompt. Acquire the necessary session serialization after verification and revalidate before loading credentials and committing the transition.
- Keep native-prompt lifetime cleanup reliable on success, failure, cancellation, and dropped callers. Reject duplicate requests while a native prompt remains active; frontend remounts must not create duplicate prompts.
- A prompt's focus changes must not trigger another prompt. Do not globally suspend auto-lock or extend an existing session just because an authentication dialog is open. Expiry during settings enrollment invalidates its result.
- Do not display recovery phrases or other unlocked content while verification is pending. Do not log PINs, native authentication material, or wallet secrets.

## Security boundary and limitations

This matches the current application-level authentication architecture: Rust checks native authentication before accessing the wallet. It does not add biometric-bound encryption of the stored seed or claim protection against code execution inside the wallet process. OS credential storage remains responsible for storage protection. No PIN is saved to simulate a biometric unlock.

Platform integration uses OS APIs through narrow adapters, not a hosted authentication provider. Capability discovery happens at runtime. Hardware enrollment and availability may change between discovery and verification; handle that as a normal fallback case.

## Validation and acceptance criteria

Automated Rust tests with a controllable fake native authenticator must cover disabled/default/unavailable states, successful unlock, failure/cancellation, duplicate requests, wallet-PIN fallback, existing PIN throttling, stale callbacks after lock/removal/preference changes, and enablement persistence only after successful verification. Use deferred completion to exercise races rather than timing sleeps.

Frontend tests must cover opt-in/skip, settings enable/disable, platform labels, a single automatic prompt, cancellation without repeated prompting, explicit retry, switching to PIN, unsupported-platform fallback, and loading/accessibility behavior. Verify existing PIN unlock and onboarding tests continue to pass.

Run frontend tests, type checking and production build, and desktop Rust formatting/check/tests appropriate to the changed code. Compile each native adapter on its target platform. A macOS build does not establish Windows correctness.

Validate actual packaged applications manually on Touch ID hardware and Windows Hello hardware/configuration: success, cancellation, lockout/unavailability, wallet PIN fallback, window ownership/focus, app restart, auto-lock, and enrollment changes. Use an isolated testnet wallet. Record any platform/hardware validation unavailable in the current environment explicitly; do not label it passed based on mocks.

## Primary references

- Apple LocalAuthentication policies: https://developer.apple.com/documentation/localauthentication/lapolicy
- Windows UserConsentVerifier and desktop interop: https://learn.microsoft.com/en-us/uwp/api/windows.security.credentials.ui.userconsentverifier
- Existing mobile behavior: `apps/mobile/lib/shared/authentication/services/biometric_service_impl.dart`, `apps/mobile/lib/features/setup/presentation/screens/pin_setup/biometric_setup_screen.dart`, and `apps/mobile/lib/app/session/widgets/wallet_lock_overlay.dart`.
- Existing desktop boundary: `apps/desktop/src-tauri/src/session.rs`, `session/security.rs`, and `platform/secure_store.rs`.
