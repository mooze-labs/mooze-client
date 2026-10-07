# Desktop Native Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in Touch ID and standard Windows Hello wallet unlock with the existing six-digit Mooze PIN as fallback.

**Architecture:** A desktop-owned native authentication port supplies OS verification to Rust session orchestration. Pure attempt-state transitions reject stale results; native adapters own OS effects and cancellation. The frontend presents capabilities, onboarding, settings, and unlock controls without deciding authorization.

**Tech Stack:** Rust, Tauri 2, Tokio, Apple LocalAuthentication through objc2 bindings, Windows WinRT bindings, React, TypeScript, Vitest.

**Spec:** `docs/superpowers/specs/2026-10-07-desktop-native-auth-design.md` (approved).

## Global Constraints

- Accept standard Windows Hello verification, including its PIN.
- The app's fallback is the Mooze PIN.
- Existing installs default to native unlock disabled.
- Keep the existing PIN confirmation for seed reveal, PIN change, and wallet removal.
- Native success does not erase PIN throttling.
- Avoid holding the main wallet mutex over an interactive OS prompt.
- No PIN is saved to simulate a biometric unlock.
- Linux and other unsupported platforms retain PIN access.
- Mainnet, testnet, and isolated validation profiles remain separated.
- No changes to seed generation, custody, or the mobile application.
- Do not claim native hardware validation from mocked tests or a build on another OS.

## Review Focus

- Native callback after switching to PIN: never unlock; test in Tasks 1, 3, and 5.
- React StrictMode/remount/focus churn: at most one automatic prompt per locked generation; test in Task 5.
- Credential-store write failure during enablement: remain disabled and preserve PIN; test in Task 3.
- OS enrollment or policy changes after capability discovery: fail closed and keep PIN usable; test in Tasks 2 and 5.
- Wallet removal and recreation while a callback is pending: never apply the old result to the new wallet; test in Task 3.

## File map

- Create `apps/desktop/src-tauri/src/native_auth/{mod.rs,attempt.rs,macos.rs,windows.rs,unsupported.rs}`: port, pure attempt state, native adapters.
- Create `apps/desktop/src-tauri/src/session/native_auth.rs`: authentication orchestration and secure preference management.
- Create `apps/desktop/src-tauri/src/session/tests/native_auth.rs`: session tests sharing the existing parent test fixtures.
- Modify desktop `Cargo.toml`, `Cargo.lock`, `src/lib.rs`, `src/dto.rs`, `src/commands.rs`, `src/session.rs`, `src/session/{setup.rs,security.rs,tests.rs}` for wiring and lifecycle integration.
- Modify frontend `src/core/{client.ts,tauri.ts,desktop.generated.ts}` for the typed command boundary.
- Create frontend `src/features/session/{native-auth-controller.ts,native-auth-controller.test.ts}` for per-generation prompt ownership, and `src/features/setup/{native-auth-offer.tsx,native-auth-offer.test.tsx}` for the shared opt-in UI.
- Modify frontend session/setup/security screens and their existing tests; modify `src/app/session-provider.tsx` and its tests for post-setup event sequencing; modify `src/i18n/messages.ts` for translations.
- Create `docs/desktop-native-auth-validation.md` to record validation evidence and remaining hardware checks.

## Task 1: Authentication port and pure attempt state

**Interfaces:** In `native_auth/mod.rs`, define object-safe `NativeAuthenticator: Send + Sync` with `capabilities(&self) -> BoxFuture<'_, NativeCapabilities>`, `verify(&self, attempt_id: u64, reason: String) -> BoxFuture<'_, NativeOutcome>`, and `cancel(&self, attempt_id: u64)`. Use `futures::future::BoxFuture`. `NativeCapabilities` has `kind: NativeKind` and `availability: NativeAvailability`; kinds are `TouchId`, `WindowsHello`, `Unsupported`; availability is `Available`, `NotEnrolled`, `LockedOut`, `Unavailable`. Outcomes are `Verified`, `Cancelled`, `Rejected`, `Unavailable`, `LockedOut`, `Failed`.

`attempt.rs` owns `AttemptState`, `Attempt { id: u64, generation: u32 }`, and `AttemptPurpose::{Unlock, Enable}`. Expose `begin(generation, purpose) -> Result<Attempt, AttemptBusy>`, `invalidate() -> Option<u64>`, `accepts(attempt, current_generation) -> bool`, and `finish(attempt_id)`. An invalidated but physically unfinished prompt still occupies the prompt slot; `finish` releases it only for the matching ID. Attempts use a checked monotonically increasing ID; exhaustion fails closed.

- [ ] Write tests `invalidated_attempt_is_never_accepted`, `different_generation_is_rejected`, `duplicate_begin_is_busy`, and `old_finish_does_not_clear_new_attempt`. Assert `accepts` is false after invalidation, second `begin` fails until physical completion, and old completion does not affect a later request.
- [ ] Run `cargo test --manifest-path apps/desktop/src-tauri/Cargo.toml native_auth::attempt`; confirm tests fail before the implementation exists.
- [ ] Implement the port, pure state transitions, and unsupported adapter. Declare the new desktop module. Keep native platform modules cfg-gated.
- [ ] Run the same tests; require success. Add an unsupported-adapter assertion that verification never returns `Verified`.
- [ ] Commit this independently testable boundary.

## Task 2: macOS and Windows adapters

**Interfaces:** Produce `native_auth::for_app(app: tauri::AppHandle) -> Arc<dyn NativeAuthenticator>`. The adapter resolves the real main window itself; IPC must never accept an arbitrary window handle. Use the Task 1 interface without adding platform dependencies to shared wallet crates.

- [ ] Write platform-local result-mapping tests: `only_native_success_is_verified`, `cancel_is_not_failure_or_success`, `unavailable_after_probe_is_unavailable`, and `unknown_error_fails_closed`. Assert every non-success maps away from `Verified`.
- [ ] Run native-auth tests on the current host to establish the expected missing-implementation failures.
- [ ] Add target-specific dependencies: `objc2-local-authentication` with LAContext/LAPolicy/error and block support, compatible `objc2`, `objc2-foundation`, and `block2`; Windows `windows` bindings with Credentials UI, WinRT interop, and window-handle features required by the resolved version. Reuse compatible existing lockfile versions and pin additions consistently with this repository. Check actual crate declarations before selecting feature names.
- [ ] Implement macOS with a new retained `LAContext` per operation, `deviceOwnerAuthenticationWithBiometrics`, no authentication reuse interval, capability checks, and `invalidate` cancellation. Marshal context lifetime/operations through an appropriate owner thread and send only owned result enums across callbacks; never invent unsafe `Send` implementations for native objects. Localize the supplied reason and route OS fallback/cancel to Mooze's locked UI.
- [ ] Implement Windows capability discovery and `IUserConsentVerifierInterop::RequestVerificationForWindowAsync` using the main window HWND. Initialize/use WinRT on the appropriate thread, retain the async operation, and map only `Verified` to success. Attempt operation cancellation, but retain prompt ownership until completion. Missing APIs/activation failures return unavailable. Microsoft's desktop API documents Windows build 22000 as its minimum; do not raise the whole application's OS floor just to enable this optional feature.
- [ ] Run current-host compile and native-auth tests. Arrange Windows-native compile validation in Task 6; do not consider cfg-excluded source validated on macOS.
- [ ] Commit adapters and lockfile together.

## Task 3: Rust session authorization and enrollment

**Interfaces:** Add `with_native_authenticator(self, Arc<dyn NativeAuthenticator>) -> Self` with the unsupported adapter as constructor default for existing tests. Add session methods `native_auth_status() -> Result<NativeAuthStatusDto>`, `unlock_native() -> Result<SessionDto>`, `cancel_native_auth() -> Result<()>`, `set_native_auth_enabled(enabled: bool, pin: String) -> Result<NativeAuthStatusDto>`, and `complete_native_auth_offer(enable: bool) -> Result<NativeAuthStatusDto>`.

`NativeAuthStatusDto` has `kind: NativeKindDto`, `availability: NativeAvailabilityDto`, `enabled: bool`, and `setup_offer_pending: bool`. Use serde snake_case enum values matching Task 1. This DTO contains no secrets. The onboarding exception is a Rust-owned, in-memory grant bound to the generation produced by successful setup/import; the client cannot create it. `complete_native_auth_offer` requires that grant and an unlocked session. Decline or successful enrollment consumes it; cancellation may keep it for explicit retry. Lock, wallet removal, or a generation change invalidates it. On restart no grant exists.

- [ ] Add a controllable fake authenticator in `session/tests/native_auth.rs` using channels to suspend verification. Write session tests asserting: disabled defaults; PIN-required settings changes; enable writes only after `Verified`; decline needs no native prompt; successful native unlock opens a session; cancellation/failure/unavailable never do; existing five-failure/30-second PIN throttle remains unchanged.
- [ ] Add deferred-callback tests for lock, switching to PIN, disabling native auth, removal/recreation, and auto-lock during settings enrollment. Assert no stale result opens a session or writes enablement. Test a secure-store write failure leaves the marker disabled and PIN unlock usable. Use existing `TestPlatform`, `FaultStore`, and `FixedClock` fixtures.
- [ ] Run `cargo test --manifest-path apps/desktop/src-tauri/Cargo.toml native_auth`; confirm failure before implementation.
- [ ] Store the enablement marker under `desktop/nativeAuth/v1` in `platform.secure()`: absent means disabled, exact `enabled-v1` means enabled, and any other value is a storage error. Disabling deletes the marker. Keep this out of `DesktopSettingsDto` and ordinary preferences.
- [ ] Implement the session methods in `session/native_auth.rs`. Capture the generation and claim the prompt slot before awaiting native verification. Select the localized reason from stored locale through a pure mapping. Do not hold `inner` while prompting. Revalidate state after verification and before every authorization commit. Serialize preference mutations with wallet operations; rollback a newly written enrollment marker if the generation changes before commit. Coordinate final checks/commit with the existing transition lock without holding a synchronous lock over an await.
- [ ] Extract the post-verification wallet load/connect/open flow from `unlock` into a private helper used by both unlock methods. Preserve import/removal checks and generation validation. Native success never calls PIN authentication or resets its attempts. PIN unlock invalidates pending native attempts before taking the wallet mutex.
- [ ] Wire invalidation into lock, expiry, wallet removal, and authenticated preference changes. `cancel_native_auth` invalidates first, requests native cancellation second, and returns without waiting for the OS callback. Keep physical prompt ownership until native completion, including if an IPC caller disappears; use an owned worker/cleanup guard so a dropped caller cannot free a live prompt slot. PIN fallback can proceed once the old attempt is invalidated.
- [ ] Run native-auth tests plus the existing session test suite; require all passed. Commit orchestration and DTO changes.

## Task 4: Tauri commands and typed frontend boundary

**Interfaces:** Register `native_auth_status`, `unlock_native`, `cancel_native_auth`, `set_native_auth_enabled { enabled, pin }`, and `complete_native_auth_offer { enable }`. Add matching `DesktopClient` methods `nativeAuthStatus`, `unlockNative`, `cancelNativeAuth`, `setNativeAuthEnabled`, and `completeNativeAuthOffer`, using the generated DTOs.

- [ ] Add command/client mapping tests asserting exact command names and arguments, cancellation acknowledgement, and native failure propagation without manufacturing a session. Ensure generated DTO checks cover all new enums.
- [ ] Run those tests before adding mappings and confirm expected failures.
- [ ] Initialize the native adapter from the Tauri app handle in `lib.rs`, inject it into the wallet session, register commands, and add their wrappers in `commands.rs`. Add DTOs to `generated_types`; generate `desktop.generated.ts` using `npm run codegen -w @mooze/desktop`. Update typed client stubs required by frontend tests.
- [ ] Run `npm run frontend:typecheck` and `cargo test --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen bindings_are_current`; require success. Commit the typed boundary.

## Task 5: Onboarding, settings, and lock-screen UX

**Interfaces:** `NativeAuthOffer({client, status, onDone})` uses `NativeAuthStatusDto` and calls `completeNativeAuthOffer`. `NativeAuthController` is owned at session-provider lifetime, with generation-specific automatic-attempt state; it exposes `attemptAutomatic(generation)`, `retry(generation)`, and `usePin(generation)` as async operations and publishes a discriminated view state (`checking`, `native`, `prompting`, `pin`, `opening`). Inject client/capability/focus access for tests. Automatic eligibility is consumed before awaiting the native call and does not reset on component remount or focus churn within the same generation.

- [ ] Write tests for the shared offer and setup page: successful creation/import leads to an optional offer, skip continues, cancel stays usable, enabled is displayed only after server confirmation, unsupported devices skip it, and no wallet PIN is retained in React state for later authentication.
- [ ] Write controller/session-screen tests: enabled and foreground prompts once; StrictMode/remount/focus events do not repeat; background does not prompt; cancellation offers retry/PIN; explicit PIN selection awaits invalidation acknowledgement; late success cannot update UI; capability loss keeps PIN usable; no retry is automatic after cancellation. Test unchanged six-digit validation and retry countdown.
- [ ] Write Security-page tests: enabling requires current wallet PIN and native success, disabling requires PIN, unavailable state has explanatory copy, persistence failure preserves the previous setting, controls remain keyboard accessible.
- [ ] Run the relevant Vitest tests and confirm they fail before implementation.
- [ ] Implement the controller and lock-screen views with explicit “Use wallet PIN” and retry controls. Let the Rust backend remain authoritative. Display normal cancellation without an error banner; use actionable messages for unavailable/locked-out states. Do not block PIN indefinitely because an OS prompt failed to dismiss.
- [ ] Implement the shared offer after successful create/import, including the legacy import entry in `SessionScreen`. Update session-provider routing so the backend's immediate unlocked event does not unmount the pending offer; the Rust `setup_offer_pending` flag is the authority. No wallet mutex is held while showing the offer. A lock event always dismisses it. Skip and success advance to the normal wallet screen.
- [ ] Implement the Security setting using the existing PIN field/dialog patterns. Add messages for pt-BR, en, and es, including “Touch ID”, “Windows Hello”, native prompt reasons, fallback, retry, enrollment, and unavailable states. Keep the other sensitive-action PIN dialogs unchanged.
- [ ] Run `npm run frontend:test`, `npm run frontend:typecheck`, and `npm run frontend:build`; require success. Commit the user-facing flow.

## Task 6: Integration verification and hardware evidence

- [ ] Run `cargo fmt --manifest-path apps/desktop/src-tauri/Cargo.toml --check` and `cargo test --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen`; resolve failures introduced by this feature. Run frontend checks from Task 5 again only if subsequent changes affect them.
- [ ] Compile the desktop crate on Windows with `cargo check --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen`. Use a Windows runner or actual Windows environment; do not equate a Linux/macOS target check with packaged runtime validation. Record a missing environment as an explicit validation limitation.
- [ ] Build the isolated testnet app with `npm run desktop:build:testnet`. On real Touch ID hardware validate opt-in, cold start, cancellation, PIN fallback, explicit retry, settings changes, auto-lock, and focus behavior. Use no funded wallet. Do not enroll biometrics or modify OS account settings automatically.
- [ ] On Windows Hello hardware validate the same flow plus its Hello PIN, actual HWND ownership, foreground behavior, and missing API/unavailable configuration fallback. Record OS version and packaged-build result.
- [ ] Write `docs/desktop-native-auth-validation.md` with executed commands/results, platform/hardware coverage, and unperformed manual checks. Verify no success claim exceeds evidence. Commit validation documentation and any integration fixes.

## References checked during planning

- https://docs.rs/objc2-local-authentication/latest/objc2_local_authentication/struct.LAContext.html — callback lifetime, policy evaluation, cancellation.
- https://learn.microsoft.com/en-us/windows/win32/api/userconsentverifierinterop/nf-userconsentverifierinterop-iuserconsentverifierinterop-requestverificationforwindowasync — HWND ownership and documented minimum Windows build 22000.
- https://microsoft.github.io/windows-docs-rs/doc/windows/Win32/System/WinRT/struct.IUserConsentVerifierInterop.html — Rust binding shape.

## Execution handoff

Review this plan before implementation. Recommended execution: native/in-session implementation because the session, IPC, and UI tasks share a tightly coupled contract, followed by an independent review of the completed change. Subagent-driven implementation with per-task reviews is an alternative if preferred. Hardware validation on each OS remains necessary with either method.

## Execution record

Implemented in `/private/tmp/mooze-native-auth` on `feature/desktop-native-auth`.

- Tasks 1–5: implemented. Pure state, macOS adapter, session, UI, and generated-binding tests pass. Windows adapter source type-checks against the Windows bindings in an isolated harness; full native Windows validation remains in Task 6.
- Task 6: frontend 119 tests and Rust codegen 86 tests pass; TypeScript, frontend production build, Rust formatting, and whitespace checks pass. macOS packaging result and native-device checks are recorded in `docs/desktop-native-auth-validation.md`.
- Independent review found and rechecked persistence cancellation and stale-foreground bugs; regression tests now pass and no concrete issue remained in the focused recheck.
- Enrollment refinement replaces the proposed rollback: write disabled `pending-v1`, validate proof/generation/expiry under the transition lock, then let an owned worker complete the final enabled write. Cancellation before commit leaves pending disabled; after commit it cannot revoke an accepted enrollment. This avoids dependence on rollback deletion succeeding.
- Tauri holds `Arc<WalletSession>` so complete preference transactions survive dropped IPC callers. `AttemptPurpose` was unnecessary; session method scope supplies purpose.
- The frontend controller is scoped by client lifetime with a WeakMap; it survives React remounts and checks actual focus immediately before automatic dispatch. The onboarding offer is rendered by SessionProvider so immediate unlocked events cannot bypass it.
- Translations use existing `pt-BR.json`, `en.json`, and `es.json` catalogs. Trivial IPC-forwarding tests were omitted in favor of generated-binding and consumer behavior checks.
- Windows full cross-check was blocked by missing MinGW; a Windows-native CI job was added but not run remotely. Hardware authentication remains a manual validation requirement.
