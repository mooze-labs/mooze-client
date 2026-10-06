# Mooze desktop and web client design

Date: 2026-10-05. Status: approved design, not implemented.

## Goal

Build a Mooze wallet for desktop and for the browser on top of `mooze-core`.
One React frontend serves both. Desktop ships first. Web ships second.
The design keeps the door open for native mobile apps that bind the same Rust facade.

## Decisions

These decisions came out of the brainstorm. They are fixed for this spec.

1. Desktop and web share one frontend and one Rust facade. Desktop runs in a Tauri 2 shell.
2. Mobile stays on Flutter for now. If Flutter goes, mobile goes native (Swift, Kotlin), not Tauri.
   The Rust facade must be exposable through UniFFI from day one.
3. The Dart-facing API of `mooze_core_bridge` stays frozen during this work.
4. The frontend calls per-method typed functions. There is no generic dispatch command.
5. Frontend stack: TypeScript, Vite, React 19, TanStack Query, React Router, FormatJS.
6. Web uses Esplora only. Desktop keeps Electrum as an optional native feature.
7. Web stores the mnemonic under a mandatory user passphrase. The PIN never protects data at rest on the web.
8. WebAuthn with the PRF extension is a requirement for the web. It ships after the web version is validated.
9. Merchant mode stays in the core. Desktop and web do not surface it.
10. Visual direction is a separate design step. It happens before the first frontend screens.

## Scope

Desktop and web reach parity with mobile, minus merchant mode:
create and import wallet, PIN, send, receive, history, PIX, swap, peg, wallet levels,
favorite payers, address explorer, settings.

Out of scope: merchant mode outside mobile, mobile in Tauri, web push notifications,
and the visual design system.

## Current state

- `crates/mooze-core`: 24k lines of Rust. No I/O. Six port traits: `HttpClient`,
  `WsConnector` and `WsConnection`, `KvStore`, `SecureStore`, `Clock`, `BlockingSpawner`.
  Esplora is the default chain backend. Electrum is a native-only feature.
  BDK and LWK state persist as JSON in `KvStore`. CI builds `wasm32-unknown-unknown`.
- `packages/mooze_core_bridge`: flutter_rust_bridge crate. About 100 async methods on
  `MoozeCore`, DTOs, port implementations and `glue.rs`. The glue wires wallets into PIX,
  swap and peg, and runs the SideSwap event driver on tokio. tokio coupling is small:
  one async mutex, one sleep, one spawn, two yields, and the WebSocket port.
- `apps/mobile`: Flutter, Riverpod, go_router, 817 Dart files. Chain and wallet code calls
  the bridge only. Still in Dart: boot and sync orchestration, transaction notifier,
  session lock, prices, fee providers, user service, wallet levels, phone verification.

## Architecture

```
apps/mobile                 Flutter (unchanged behavior)
apps/frontend               React SPA, CoreClient interface, two transports
apps/desktop                Tauri 2 host, native ports, points at apps/frontend
crates/mooze-core           unchanged domain and ports
crates/mooze-app            facade: App, Runtime, DTOs, AppEvent, app_api! macro
crates/mooze-wasm           wasm-bindgen exports and browser ports (web phase)
packages/mooze_core_bridge  thin frb wrapper over mooze-app
```

Data flow: frontend -> `CoreClient` -> transport (Tauri IPC or wasm) -> `App` -> `mooze-core` -> ports.
Events flow back the same path through `AppEvent`.

### `mooze-app` facade

The bridge `Inner`, `glue.rs`, `api/*` methods, DTOs, and the SideSwap and PIX drivers move
into `crates/mooze-app`. The crate depends on `mooze-core` only.

- `App<P: Platform>` holds the state. `Platform` bundles the port implementations.
- Two new ports in `mooze_core::ports`:
  - `Spawner`: spawns a `MaybeSend` future, fire and forget.
  - `Timer`: `sleep(ms)`.
- `BlockingSpawner` becomes optional in `Platform`. Only the Electrum path needs it.
- The tokio mutex becomes `futures::lock::Mutex`. `yield_now` becomes `Timer::sleep(0)`.
<<<<<<< HEAD
  The facade has no tokio dependency.
=======
  The facade has no tokio runtime dependency. It uses tokio with only the `sync` feature, which is
  runtime-free, builds on wasm32, and gives a FIFO-fair mutex that the SideSwap driver relies on.
>>>>>>> 82457a16f352ad2ddf90c258df932ee059cb9ffe

API surface rules, for UniFFI, wasm-bindgen and Tauri:

- Methods take and return owned, flat DTOs with serde derives.
- No generics, lifetimes or trait objects cross the boundary.
- Errors are one flat `AppError`: a stable `code` string, a message, optional details.

Events: one `AppEvent` enum with variants `SyncState`, `Transactions`, `PixStatus`,
`SideSwap`, `PegProgress`, `SessionLock`, `AuthSession`. `App::subscribe(Box<dyn EventSink>)`.
The polling methods `take_events` stay for Dart. Push is the primary path for new hosts.

Logic absorbed from Dart into `mooze-app`, screen by screen as the frontend needs it:
boot orchestration, sync orchestration, transaction notifier decisions, session lock timing,
prices, fee providers, user service, wallet levels, phone verification. The core already has
Rust `BootOrchestrator`, `SyncOrchestrator` and `AppLifecycle` that mobile does not use yet.
The lock screen, the biometric prompt and the screenshot block stay host UI.

### `app_api!` macro

`mooze-app` declares the API once:

```rust
app_api! {
    async fn bitcoin_sync(&self) -> SyncOutcomeDto;
    async fn liquid_send(&self, request: SendRequestDto) -> BroadcastResultDto;
    // ...
}
```

The macro emits:

1. The `impl App` method signatures the facade must implement.
2. A `METHODS` const table: name, request type, response type.
3. Host wrapper generators: `tauri_commands!()` emits one `#[tauri::command]` per method,
   `wasm_exports!()` emits one `#[wasm_bindgen]` function per method with `serde-wasm-bindgen`,
   `uniffi_exports!()` is added when a native mobile host exists.

Adding a method means one line in the macro and one body in `App`. Hosts regenerate.

### TypeScript generation

- DTOs derive `ts-rs` and export to `apps/frontend/src/core/types.generated.ts`.
- An `xtask` reads `METHODS` and emits `CoreClient`, a typed interface with one async method
  per entry, plus the `TauriTransport` implementation.
- CI fails when a generated file is stale.

### Transports

`CoreClient` has two implementations. Runtime selection checks the Tauri global.

- `TauriTransport` (desktop phase): one `invoke` per method, `listen` for `AppEvent`.
- `WasmTransport` (web phase): the wasm core and its typed exports live inside a Web Worker.
  The UI thread uses Comlink to get a typed async proxy of `CoreClient`. Events arrive through
  a Comlink callback. The worker exists because Argon2id, BDK and LWK scans and PSET signing
  would block the UI thread.

### Frontend

`apps/frontend` is a static SPA. No server rendering.

- TanStack Query wraps every `CoreClient` call. A fixed map turns each `AppEvent` variant into
  query invalidations. Example: `Transactions` invalidates balances and history of its chain.
  No component polls.
- React Router mirrors the mobile route set, minus merchant.
- FormatJS for i18n. A build script converts the three ARB files (`pt`, `en`, `es`) to the
  FormatJS format, so translations stay in sync with mobile from one source.
- Error codes map to i18n messages, reusing the humanized texts from mobile PR #146.
- Two host error codes exist outside the core mapping: `locked`, which routes to the unlock
  screen, and `transport`, for a crashed worker or failed Tauri IPC.

### Desktop host (`apps/desktop`)

- Tauri 2. `frontendDist` points at `apps/frontend/dist`.
- `NativePlatform`: file-backed `KvStore` (from the bridge), `keyring` crate as `SecureStore`
  (macOS Keychain, Windows Credential Manager, Linux Secret Service), `reqwest` HTTP,
  tungstenite WebSocket, tokio `Spawner`, `Timer` and `BlockingSpawner`.
- Security model equals mobile: the keychain holds the mnemonic, the PIN gates the UI with
  the core `PinService` and `SessionLockTimeout` rules.
- Chain backend: Electrum and Esplora both available. Default is Electrum, like mobile.
- `tauri-plugin-single-instance`. A hidden window counts as background for the lock clock
  only. Sync continues unthrottled.
- Notifications through the Tauri notification plugin. Optional for the first release.

### Runtime and lifecycle

`mooze-app` has a `Runtime` built on `Spawner` and `Timer`. It owns four loops:
the sync scheduler around `SyncOrchestrator` (60 s tick, 60 s per-chain timeout),
the PIX poll loop (active only while polls exist), the SideSwap driver with its reconnect policy,
and price refresh.

Host entry points: `start()`, `stop()`, `on_background(now)`, `on_foreground(now)`.
The frozen Dart wrapper never starts the runtime. Dart keeps driving ticks as today.

Timeouts are real cancellations: a `select` between the sync future and `Timer::sleep`.
Dropping the reqwest future aborts the request on both native and wasm.

Browser lifecycle (web phase):

- `visibilitychange` hidden: `on_background`. The lock clock starts. Loops keep running.
  Browsers throttle hidden-tab timers to once a minute, which matches the sync cadence.
- `visibilitychange` visible: `on_foreground`. The core decides whether to lock.
  The runtime fires an immediate light refresh.
- `pagehide`: best-effort `stop()`. BDK persists after every change and the LWK journal
  flushes on each update, so nothing is at risk.
- Multi-tab: the worker takes an exclusive Web Lock named after the wallet before it opens
  `App`. A second tab shows "wallet open in another tab" and offers to take over, which steals
  the lock and stops the first worker. The lock releases when a tab closes.

### Web host (`crates/mooze-wasm`, web phase)

Browser ports:

- `HttpClient`: `reqwest`, which uses `fetch` on wasm and already builds in CI.
- `KvStore` and `WsConnector`: TypeScript inside the worker over IndexedDB and `WebSocket`,
  handed to wasm as one `BrowserPlatform` object. Rust wrappers implement the port traits.
- `SecureStore`: Rust, encrypted namespace over the `KvStore`. See the security section.
- `Clock`: `js_sys::Date::now`. `Timer`: promise over `setTimeout`.
  `Spawner`: `wasm_bindgen_futures::spawn_local`. No `BlockingSpawner`.
- Build: `cargo build --target wasm32-unknown-unknown`, then `wasm-bindgen` CLI and
  `wasm-opt` from the `xtask`. Vite consumes the output. A service worker caches the wasm.
  Measure the bundle before optimizing it.

Deployment requirements:

- CORS: the Mooze API must allow the web origin. Esplora at blockstream.info and
  mempool.space already allow any origin. SideSwap is WebSocket.
- Prices on the web come from a new Mooze backend API, not from CoinGecko or Binance
  directly. Its contract is pending. The price port in `mooze-app` gets a second source
  when the contract exists.
- Strict Content Security Policy: no inline scripts, no third-party origins.
  Self-hosted fonts and assets. No analytics scripts. Subresource Integrity on every bundle.
- The UI states that the desktop build avoids the web hosting trust problem.

## Security: key storage and unlock

### Desktop

Same as mobile. Keychain holds the mnemonic. PIN gates the UI.

### Web

The mobile PIN scheme is a six-digit PIN with one SHA-256 round. It cannot protect data at
rest in a browser. The web model:

1. `SecureStore` on wasm is an encrypted namespace over IndexedDB. Values are encrypted in
   Rust with XChaCha20-Poly1305. The key derives from a user passphrase with Argon2id,
   tuned to about one second in the browser. Salt and parameters sit beside the ciphertext.
   Crates: `argon2`, `chacha20poly1305`, `zeroize`. Each passes the supply-chain check before
   it is added.
2. `App` gains `unlock(passphrase)` and `lock()`. Before unlock the secure store returns
   `AppError` code `locked`. `lock()` zeroizes the key in wasm memory. Auto-lock follows
   `SessionLockTimeout`, driven by tab visibility and idle time.
3. The mnemonic never leaves wasm, except on the explicit "view mnemonic" screen.
   The bridge methods that take a mnemonic parameter stay frozen for Dart only.
   The facade signing path reads from the secure store. The web transport exposes only that path.
4. The six-digit PIN is a quick re-unlock while the derived key is still in memory in the same
   tab session. It never protects data at rest.
5. WebAuthn PRF derives the key from a passkey or platform authenticator. The passphrase stays
   as fallback. Ships after web validation.

Covered: stolen disk, leaked browser profile, shared machine.
Not covered: XSS and a compromised host. Mitigated by the CSP and SRI requirements above.

Secrets per store: mnemonic, PIN hash and salt stay in `SecureStore` under today's key names.
Session tokens, counters and preferences stay in plain `KvStore`.

## Error handling

- `AppError { code, message, details }`. One mapping from `mooze_core::Error` in `mooze-app`.
- Hosts add `locked` and `transport`.
- On a worker crash the UI restarts the worker and returns to the unlock screen.

## Testing

- `mooze-app`: unit tests with `mooze_core::testing` fakes. Runtime loops use a manual-advance
  fake `Timer` and an inline `Spawner`. Existing bridge tests move over unchanged.
- `mooze_core_bridge`: the Dart test suite proves the frozen API after the lift.
- `apps/desktop`: `cargo test` on the generated commands and the native platform.
- `apps/frontend`: Vitest with a fake `CoreClient`. Playwright end to end against regtest.
  The core already targets regtest Esplora on port 3002. A compose file runs bitcoind,
  elementsd and two Esplora instances. Nightly, not per push.
- `mooze-wasm` (web phase): `wasm-bindgen-test` in headless Chrome. IndexedDB round trip.
  Secure store lock, unlock and wrong passphrase. WebSocket against a local echo server.
- CI: generated TypeScript freshness, `cargo deny check advisories bans sources`,
  wasm build of `mooze-core` and `mooze-app`.

## Rollout

Each phase ships alone and is testable alone.

1. Lift the facade into `mooze-app`: `Spawner` and `Timer` ports, `Runtime`, `AppEvent`,
   `app_api!`, `ts-rs` export, `xtask`. `mooze_core_bridge` becomes a thin wrapper.
   Mobile behavior unchanged.
   Done in `docs/superpowers/plans/2026-10-05-mooze-app-facade.md`. The macro is named
   `for_each_app_method!`, the generator is a `codegen` binary in the crate, and the crate package
   is `mooze_app`. The price refresh loop lands with the prices absorption in phase 3.
2. `apps/desktop` Tauri host: `NativePlatform`, keychain, single instance, generated commands,
   event emit. Smoke screen that opens a wallet and syncs.
3. Visual direction design step. Then `apps/frontend` wallet screens: create or import, PIN,
   unlock, home, receive, send, history, settings. Absorb Dart logic into `mooze-app` per screen.
4. PIX, swap, peg, wallet levels, favorite payers, address explorer on desktop.
5. Web: `mooze-wasm`, browser ports, passphrase secure store, worker, Web Locks, CSP, CORS.
   `WasmTransport` behind the same `CoreClient`.
6. WebAuthn PRF after web validation.

## Success criteria

1. Phase 1: `flutter test` in `apps/mobile` passes with the thin bridge. `cargo test` passes in
   `mooze-app`. `cargo build --target wasm32-unknown-unknown` passes for `mooze-app`.
2. Phase 2 to 4: the desktop app creates a wallet, receives and sends on Bitcoin and Liquid,
   completes a PIX deposit, a swap and a peg on testnet, with the same addresses mobile derives
   from the same mnemonic.
3. Phase 5: the web app passes the same flows on Esplora, locks and unlocks with a passphrase,
   and a second tab is refused until it takes over.
4. `cargo deny check advisories bans sources` reports no vulnerabilities at every phase.

## Open items

1. Contract of the Mooze backend price API for the web. Pending instructions.
2. Argon2id parameters measured in real browsers before the web phase.
3. UniFFI wrapper crate name and location, when a native mobile host starts.

Resolved: desktop defaults to Electrum, like mobile.
