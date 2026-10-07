# Desktop native authentication validation

Implementation branch: `feature/desktop-native-auth`.

## Behavior and architecture

Touch ID and standard Windows Hello (including the Hello PIN) are opt-in local session unlock methods. Mooze's six-digit PIN remains an independent fallback. Enrollment is offered after creation/import and in Security settings. Unsupported platforms keep PIN access. Recovery phrase, PIN changes, and wallet removal still require the wallet PIN.

Rust owns native verification and session authorization. No passkeys, remote authentication service, seed derivation, or saved PIN are introduced. OS credential storage remains unchanged; this is application-level authentication, not biometric-bound seed encryption.

Enrollment first writes a disabled `pending-v1` marker. A transition-locked check validates the current native attempt, generation, unlocked state, and expiry. This is the enrollment commit point: cancellation before it leaves a disabled marker; after acceptance an owned worker finishes the enabled marker write even if the caller disappears. The wallet mutex serializes disable/removal behind that write. No rollback deletion is necessary. A crash or final-write failure leaving `pending-v1` is treated as disabled on restart. Redundant enrollment does not erase an existing enabled preference.

## Automated evidence

- `npm run frontend:test`: 46 files / 119 tests passed.
- `npm run frontend:typecheck`: passed.
- `npm run frontend:build`: passed; Vite reports its bundle-size warning (main JavaScript chunk about 930 kB before gzip).
- `cargo test --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen`: 86 tests passed, including binding freshness and native-auth regression tests. Existing `proc-macro-error2` future-incompatibility warning remains.
- `cargo fmt --manifest-path apps/desktop/src-tauri/Cargo.toml --check`: passed.
- `git diff --check`: passed.
- `npm run desktop:build:testnet`: macOS release `.app` bundle built successfully (37.37 MiB). The bundle is a build artifact only; successful physical Touch ID authentication is still untested.
- An independent read-only reviewer found and then rechecked the persistence and background-prompt fixes; no remaining concrete issue in that focused recheck.

The tests cover successful enrollment/unlock, cancellation, unsupported/unavailable authentication, settings PIN verification, PIN throttling, duplicate attempts, capability checks in progress, auto-lock, wallet removal/recreation, detached callbacks, deferred storage writes, and post-commit serialization. Frontend tests cover one automatic prompt per generation, manual retry, PIN fallback, background transitions, onboarding event ordering, and settings persistence failures.

The initial sandbox Rust baseline had four WebSocket tests fail when binding loopback sockets (`Operation not permitted`). They passed with loopback networking enabled; this was an environment limitation.

## Windows validation boundary

A full `cargo check --target x86_64-pc-windows-gnu` was attempted on macOS and stopped in a dependency because `x86_64-w64-mingw32-gcc` is not installed. This did not compile the complete Windows application.

The actual Windows adapter source passed an isolated cross-target Rust type check against windows 0.62.2 and windows-future 0.3.2, substituting a minimal Tauri app/window-handle shim. This checks Windows binding use, not Tauri integration, packaging, or runtime behavior. The existing desktop workflow now includes a Windows-native test job; it has not been run remotely in this session.

## Manual release checks still required

Use an unfunded isolated testnet wallet on each platform. Do not substitute a funded wallet for validation.

1. On packaged macOS with Touch ID enrolled: opt in after creating/importing a wallet, lock/reopen, authenticate, cancel, explicitly retry, and choose the Mooze PIN. Repeat with Touch ID unavailable/locked out.
2. In Security settings, enable/disable using fresh wallet PIN; test cancellation and auto-lock during the prompt. Confirm sensitive actions still require wallet PIN.
3. Ensure a background window does not automatically prompt, focus changes caused by the prompt do not cause loops, and switching to PIN rejects a late native result.
4. On packaged Windows: repeat with face/fingerprint and Windows Hello PIN; verify the prompt belongs to the main wallet window and unavailable/unconfigured Hello retains Mooze PIN access.
5. Restart the app and verify persistence; remove a disposable wallet and confirm a newly created wallet defaults to native authentication disabled.

Successful physical Touch ID / Windows Hello authentication has not been exercised in this session. These checks require the device owner's interaction. Neither mock tests nor a successful macOS build establish Windows runtime support.
