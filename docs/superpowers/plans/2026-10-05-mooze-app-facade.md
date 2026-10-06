# mooze-app facade lift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the host-neutral application facade out of the flutter_rust_bridge crate into `crates/mooze-app`, add the `Spawner` and `Timer` ports, a `Runtime`, `AppEvent`, the method table and TypeScript generation, and make `packages/mooze_core_bridge` a thin wrapper with its Dart API unchanged.

**Architecture:** `mooze-app` holds `App<P: Platform>`: the state and methods that live today in the bridge `Inner`, `glue.rs` and `api/*`. It depends on `mooze-core` only and uses no tokio runtime. Hosts supply a `Platform` with port implementations. The bridge keeps the `MoozeCore` opaque type, its DTO names and its `CoreError`, and delegates every call to `App<NativePlatform>` on its tokio runtime.

**Tech Stack:** Rust 1.85+ (edition 2021), `mooze-core`, `tokio::sync` only (no runtime), `futures`, `serde`, `ts-rs 12.0.1`, flutter_rust_bridge 2.11.1, Flutter 3.41.9.

**Spec:** `docs/superpowers/specs/2026-10-05-desktop-web-client-design.md` (sections "`mooze-app` facade", "`app_api!` macro", "TypeScript generation", "Runtime and lifecycle", "Error handling", "Testing", "Rollout" phase 1).

## Global Constraints

- Pin every dependency with `=x.y.z`. No git dependencies. `Cargo.lock` committed.
- Each crate is standalone: `[workspace]` at the end of its `Cargo.toml`, like `crates/mooze-core`.
- `mooze-app` builds for `wasm32-unknown-unknown` with `--features http-reqwest`. Never build wasm with `--all-features`.
- `mooze-app` has no tokio runtime dependency. `tokio` with only the `sync` feature is allowed: it is runtime-free, builds on wasm32, and its `Mutex` is FIFO fair, which the SideSwap driver relies on. This amends the spec sentence "The facade has no tokio dependency" (Task 11 edits the spec).
- The Dart-facing API of `packages/mooze_core_bridge` is frozen: every class, enum, method name, parameter name and `CoreErrorKind` value stays. The files under `packages/mooze_core_bridge/lib/src/rust/api/` must not change in public shape after regeneration.
- API surface rules of `mooze-app`: owned flat DTOs with serde derives; no generics, lifetimes or trait objects in method signatures; every method returns `Result<T, AppError>`.
- Secure-store key names stay `mnemonic_mainWallet`, `jwt`, `refresh_token`, `hashedPin`, `pinSalt`, `device_id`.
- New crates not on the organization trust list (`ts-rs`) go through the `supply-chain` skill before `cargo add`. `cargo deny check advisories bans sources` passes in every crate at every commit.
- Commit messages end with the attribution lines given in the session's system reminder.
- Commands below run from the repository root unless a step says otherwise.

## Review Focus

1. Dart registers the secure store after `open` and may call auth before that. Expected: `InvalidState` with message `secure storage not set; call setSecureStorage first`, and the next auth call after registration works without `authReset`. Pinned in Task 10 (`late_secure_store_errors_until_set_then_works`).
2. A tick fires while the previous refresh still runs, or `start` is called twice. Expected: one refresh at a time, second `start` is a no-op, `stop` before `start` is a no-op. Pinned in Task 8 (`start_twice_is_noop`, `stop_without_start_is_noop`).
3. A chain sync hangs longer than its timeout. Expected: that chain reports `Timeout`, the other chain's result still lands, the loop continues at the next tick. Pinned in Task 8 (`sync_longer_than_timeout_reports_timeout_and_loop_continues`).
4. The host drops the `App` while loops sleep. Expected: every loop ends at its next wake; no panic, no leaked task that holds the state alive. Pinned in Task 8 (`dropping_app_ends_loops`).
5. The last SideSwap event subscriber goes away. Expected: the driver stops and emits `closed` once; a new subscription starts a new driver. Pinned in Task 7 (`driver_stops_when_last_subscriber_leaves`).

---

## File structure

```
crates/mooze-core/src/ports/task.rs            new: TaskFuture, Spawner, Timer
crates/mooze-core/src/ports/mod.rs             modify: exports
crates/mooze-core/src/testing/mod.rs           modify: ManualTimer, ChannelSpawner, TestExecutor

crates/mooze-app/Cargo.toml                    new crate
crates/mooze-app/deny.toml                     copy of crates/mooze-core/deny.toml
crates/mooze-app/.cargo/config.toml            copy of crates/mooze-core/.cargo/config.toml
crates/mooze-app/src/lib.rs
crates/mooze-app/src/error.rs                  AppError, ErrorCode, From<mooze_core::Error>
crates/mooze-app/src/platform.rs               Platform trait
crates/mooze-app/src/dto/mod.rs                re-exports
crates/mooze-app/src/dto/config.rs             NetworkDto, BackendDto, AppConfig
crates/mooze-app/src/dto/wallet.rs             moved from bridge api/types.rs (minus CoreError)
crates/mooze-app/src/dto/pix.rs                moved from bridge api/pix.rs DTO section
crates/mooze-app/src/dto/swap.rs               moved from bridge api/swap.rs DTO section
crates/mooze-app/src/dto/runtime.rs            StartConfigDto, SessionLockStateDto, SyncStateDto
crates/mooze-app/src/rules.rs                  pure functions: pix_fee, tax_id_*, peg_validate_amount, ...
crates/mooze-app/src/events.rs                 AppEvent, EventSink, Subscribers
crates/mooze-app/src/glue.rs                   LiquidPort<P>, WalletPegPort<P>, SideSwapState<P>, driver
crates/mooze-app/src/app/mod.rs                Inner<P>, App<P>, open, migration, secure, auth, api_request
crates/mooze-app/src/app/wallets.rs            bitcoin_*, liquid_*
crates/mooze-app/src/app/pix.rs                pix_*, favorite_payer*, pix_flag_*
crates/mooze-app/src/app/swap.rs               sideswap_*, peg_*
crates/mooze-app/src/runtime/mod.rs            start, stop, on_background, on_foreground, loops wiring
crates/mooze-app/src/runtime/sync_loop.rs      SyncLoop<S: ChainSyncer, K, C>, generic and tested alone
crates/mooze-app/src/runtime/syncers.rs        AppSyncer<P>: ChainSyncer over the App wallets
crates/mooze-app/src/methods.rs                for_each_app_method!, METHODS table
crates/mooze-app/src/bin/codegen.rs            writes generated/types.ts and generated/client.ts
crates/mooze-app/generated/types.ts            committed output
crates/mooze-app/generated/client.ts           committed output

packages/mooze_core_bridge/rust/Cargo.toml     add mooze-app
packages/mooze_core_bridge/rust/src/ports.rs   add TokioTaskSpawner, TokioTimer, NativePlatform
packages/mooze_core_bridge/rust/src/secure_store.rs  add LateSecureStore
packages/mooze_core_bridge/rust/src/api/*.rs   thin wrappers
packages/mooze_core_bridge/rust/src/glue.rs    deleted
packages/mooze_core_bridge/flutter_rust_bridge.yaml  rust_input adds mooze_app::dto

.github/workflows/mooze-core.yml               add mooze-app jobs
docs/superpowers/specs/2026-10-05-desktop-web-client-design.md  tokio::sync amendment
```

---

### Task 1: `Spawner` and `Timer` ports with test fakes

**Files:**
- Create: `crates/mooze-core/src/ports/task.rs`
- Modify: `crates/mooze-core/src/ports/mod.rs`
- Modify: `crates/mooze-core/src/testing/mod.rs`
- Test: inline `#[cfg(test)]` modules in both files

**Interfaces:**
- Produces: `mooze_core::ports::{TaskFuture, Spawner, Timer}`, `mooze_core::testing::{ManualTimer, ChannelSpawner, TestExecutor}`.

- [ ] **Step 1: Write the failing tests in `crates/mooze-core/src/testing/mod.rs`**

Append inside the file, after the existing `blocking_tests` module:

```rust
#[cfg(all(test, not(target_arch = "wasm32")))]
mod task_tests {
    use super::*;
    use crate::ports::{Spawner, Timer};
    use std::sync::atomic::{AtomicU32, Ordering};

    #[test]
    fn manual_timer_fires_in_deadline_order() {
        let timer = Arc::new(ManualTimer::new());
        let (spawner, mut exec) = TestExecutor::new();
        let log = Arc::new(Mutex::new(Vec::new()));
        for (ms, tag) in [(300u64, "c"), (100, "a"), (200, "b")] {
            let (t, l) = (timer.clone(), log.clone());
            spawner.spawn(Box::pin(async move {
                t.sleep(ms).await;
                l.lock().unwrap().push(tag);
            }));
        }
        exec.run_until_stalled();
        assert!(log.lock().unwrap().is_empty());
        timer.advance(150);
        exec.run_until_stalled();
        assert_eq!(*log.lock().unwrap(), vec!["a"]);
        timer.advance(200);
        exec.run_until_stalled();
        assert_eq!(*log.lock().unwrap(), vec!["a", "b", "c"]);
        assert_eq!(timer.pending(), 0);
    }

    #[test]
    fn channel_spawner_runs_tasks_on_the_executor() {
        let (spawner, mut exec) = TestExecutor::new();
        let count = Arc::new(AtomicU32::new(0));
        for _ in 0..3 {
            let c = count.clone();
            spawner.spawn(Box::pin(async move {
                c.fetch_add(1, Ordering::SeqCst);
            }));
        }
        assert_eq!(count.load(Ordering::SeqCst), 0);
        exec.run_until_stalled();
        assert_eq!(count.load(Ordering::SeqCst), 3);
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd crates/mooze-core && cargo test --all-features task_tests`
Expected: compile error, `ManualTimer`, `TestExecutor` and `Spawner` not found.

- [ ] **Step 3: Create `crates/mooze-core/src/ports/task.rs`**

```rust
//! Task ports: spawn a future, sleep for a duration.
//!
//! The core and the facade own no executor and no timers. A host runs
//! tasks on tokio, on `wasm_bindgen_futures::spawn_local`, or on a test
//! executor. `std::thread::sleep` and `tokio::time::sleep` both fail on
//! wasm, so sleeping is a port too.

use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;

use super::{MaybeSend, MaybeSync};

/// Boxed future a port returns or accepts. `Send` on native targets only.
#[cfg(not(target_arch = "wasm32"))]
pub type TaskFuture<'a, T> = Pin<Box<dyn Future<Output = T> + Send + 'a>>;
/// Boxed future a port returns or accepts. `Send` on native targets only.
#[cfg(target_arch = "wasm32")]
pub type TaskFuture<'a, T> = Pin<Box<dyn Future<Output = T> + 'a>>;

/// Runs a future to completion in the background. Fire and forget.
pub trait Spawner: MaybeSend + MaybeSync {
    fn spawn(&self, task: TaskFuture<'static, ()>);
}

impl<T: Spawner + ?Sized> Spawner for Arc<T> {
    fn spawn(&self, task: TaskFuture<'static, ()>) {
        (**self).spawn(task)
    }
}

/// Resolves after `ms` milliseconds.
pub trait Timer: MaybeSend + MaybeSync {
    fn sleep(&self, ms: u64) -> TaskFuture<'static, ()>;
}

impl<T: Timer + ?Sized> Timer for Arc<T> {
    fn sleep(&self, ms: u64) -> TaskFuture<'static, ()> {
        (**self).sleep(ms)
    }
}
```

- [ ] **Step 4: Export the port in `crates/mooze-core/src/ports/mod.rs`**

Add `mod task;` next to the other `mod` lines and `pub use task::{Spawner, TaskFuture, Timer};` next to the other `pub use` lines.

- [ ] **Step 5: Add the fakes to `crates/mooze-core/src/testing/mod.rs`**

Add these imports at the top of the file, with the existing ones: `use crate::ports::{Spawner, TaskFuture, Timer};`, `use futures::channel::{mpsc, oneshot};`, `use std::sync::atomic::AtomicU64;`. Then add, before the test modules:

```rust
/// [`Timer`] that fires only when the test calls [`ManualTimer::advance`].
#[derive(Debug, Default)]
pub struct ManualTimer {
    now_ms: AtomicU64,
    pending: Mutex<Vec<(u64, oneshot::Sender<()>)>>,
}

impl ManualTimer {
    /// Timer at time zero with no pending sleeps.
    pub fn new() -> Self {
        Self::default()
    }

    /// Current virtual time.
    pub fn now_ms(&self) -> u64 {
        self.now_ms.load(Ordering::SeqCst)
    }

    /// Moves time forward and completes every sleep that is due.
    pub fn advance(&self, ms: u64) {
        let now = self.now_ms.fetch_add(ms, Ordering::SeqCst) + ms;
        let mut pending = self.pending.lock().expect("poisoned");
        let (due, later): (Vec<_>, Vec<_>) = pending.drain(..).partition(|(at, _)| *at <= now);
        *pending = later;
        for (_, tx) in due {
            let _ = tx.send(());
        }
    }

    /// Number of sleeps that have not fired.
    pub fn pending(&self) -> usize {
        self.pending.lock().expect("poisoned").len()
    }
}

impl Timer for ManualTimer {
    fn sleep(&self, ms: u64) -> TaskFuture<'static, ()> {
        let (tx, rx) = oneshot::channel();
        self.pending.lock().expect("poisoned").push((self.now_ms() + ms, tx));
        Box::pin(async move {
            let _ = rx.await;
        })
    }
}

/// [`Spawner`] that queues tasks on a channel. [`TestExecutor`] runs them.
#[derive(Debug, Clone)]
pub struct ChannelSpawner {
    tx: mpsc::UnboundedSender<TaskFuture<'static, ()>>,
}

impl Spawner for ChannelSpawner {
    fn spawn(&self, task: TaskFuture<'static, ()>) {
        let _ = self.tx.unbounded_send(task);
    }
}

/// Single-threaded executor for runtime tests. Native only.
#[cfg(not(target_arch = "wasm32"))]
pub struct TestExecutor {
    pool: futures::executor::LocalPool,
    rx: mpsc::UnboundedReceiver<TaskFuture<'static, ()>>,
}

#[cfg(not(target_arch = "wasm32"))]
impl TestExecutor {
    /// A spawner and the executor that runs what it spawns.
    pub fn new() -> (ChannelSpawner, Self) {
        let (tx, rx) = mpsc::unbounded();
        (ChannelSpawner { tx }, Self { pool: futures::executor::LocalPool::new(), rx })
    }

    /// Moves queued tasks onto the pool and runs until every task waits.
    pub fn run_until_stalled(&mut self) {
        use futures::task::{FutureObj, Spawn};
        loop {
            let mut moved = false;
            while let Ok(Some(task)) = self.rx.try_next() {
                self.pool.spawner().spawn_obj(FutureObj::new(task)).expect("pool open");
                moved = true;
            }
            self.pool.run_until_stalled();
            if !moved {
                break;
            }
        }
    }

    /// Runs one future to completion, driving queued tasks alongside it.
    pub fn block_on<F: Future>(&mut self, f: F) -> F::Output {
        let mut f = Box::pin(f);
        loop {
            self.run_until_stalled();
            let waker = futures::task::noop_waker();
            let mut cx = std::task::Context::from_waker(&waker);
            if let std::task::Poll::Ready(v) = f.as_mut().poll(&mut cx) {
                return v;
            }
            self.pool.run_until_stalled();
        }
    }
}
```

`futures` already has the `std` and `async-await` features in `mooze-core`. `mpsc` and `oneshot` live under `futures::channel`, which the `std` feature enables. `LocalPool` needs the `executor` feature: it is already a dev-dependency feature. Because `TestExecutor` is `cfg(not(wasm32))` and `ManualTimer` and `ChannelSpawner` are not, add `features = ["std", "async-await", "executor"]` to the `futures` entry in `[dependencies]` of `crates/mooze-core/Cargo.toml` only under `[target.'cfg(not(target_arch = "wasm32"))'.dependencies]`:

```toml
[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
bdk_electrum = { version = "=0.24.0", default-features = false, features = ["use-rustls-ring"], optional = true }
futures = { version = "=0.3.34", default-features = false, features = ["std", "async-await", "executor"] }
```

Cargo unifies the two `futures` entries. The wasm build keeps `executor` off.

- [ ] **Step 6: Run the tests to verify they pass, on host and wasm**

Run: `cd crates/mooze-core && cargo test --all-features task_tests && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo clippy --all-features --all-targets -- -D warnings`
Expected: 2 tests pass, both builds succeed, clippy clean.

- [ ] **Step 7: Commit**

```bash
git add crates/mooze-core
git commit -m "Add Spawner and Timer ports with test fakes to mooze-core"
```

---

### Task 2: `mooze-app` crate skeleton, `AppError`, `Platform`, `AppConfig`

**Files:**
- Create: `crates/mooze-app/Cargo.toml`, `crates/mooze-app/deny.toml`, `crates/mooze-app/.cargo/config.toml`, `crates/mooze-app/.gitignore`
- Create: `crates/mooze-app/src/lib.rs`, `src/error.rs`, `src/platform.rs`, `src/dto/mod.rs`, `src/dto/config.rs`
- Test: `crates/mooze-app/src/error.rs` inline tests

**Interfaces:**
- Produces: `mooze_app::{AppError, ErrorCode, Result}`, `mooze_app::Platform`, `mooze_app::dto::{NetworkDto, BackendDto, AppConfig}`.

- [ ] **Step 1: Run the supply-chain check for `ts-rs`**

Invoke the `supply-chain` skill for `ts-rs` version `12.0.1` from crates.io. Record its verdict in the commit message of this task. Do not add the dependency if the skill blocks it; stop and report.

- [ ] **Step 2: Create the crate files**

`crates/mooze-app/Cargo.toml`:

```toml
[package]
name = "mooze-app"
version = "0.1.0"
edition = "2021"
rust-version = "1.85"
description = "Host-neutral application facade of the Mooze wallet over mooze-core."
license = "GPL-3.0-only"
publish = false

[lib]
crate-type = ["rlib"]

[[bin]]
name = "codegen"
path = "src/bin/codegen.rs"
required-features = ["codegen"]

[features]
default = []
# Pass-through of the mooze-core features.
http-reqwest = ["mooze-core/http-reqwest"]
electrum = ["mooze-core/electrum"]
# TypeScript generation. Never needed by a host build.
codegen = ["dep:ts-rs"]

[dependencies]
mooze-core = { path = "../mooze-core", version = "=0.1.0" }
serde = { version = "=1.0.229", features = ["derive"] }
serde_json = { version = "=1.0.151" }
thiserror = { version = "=2.0.21" }
futures = { version = "=0.3.34", default-features = false, features = ["std", "async-await"] }
# Runtime-free primitives only. Builds on wasm32. The Mutex is FIFO fair.
tokio = { version = "=1.53.2", default-features = false, features = ["sync"] }
ts-rs = { version = "=12.0.1", optional = true, features = ["serde-compat"] }

[dev-dependencies]
futures = { version = "=0.3.34", features = ["executor"] }

[workspace]
```

The versions of `serde`, `serde_json`, `thiserror`, `futures` and `tokio` equal those in `crates/mooze-core/Cargo.toml` and `packages/mooze_core_bridge/rust/Cargo.toml`.

`crates/mooze-app/deny.toml`: copy `crates/mooze-core/deny.toml` unchanged.
`crates/mooze-app/.cargo/config.toml`: copy `crates/mooze-core/.cargo/config.toml` unchanged.
`crates/mooze-app/.gitignore`: one line, `target/`.

`crates/mooze-app/src/lib.rs`:

```rust
//! Application facade of the Mooze wallet.
//!
//! [`App`] holds the wallets, the API session, PIX, SideSwap and the peg
//! tracker, and exposes flat DTO methods that every host binds:
//! flutter_rust_bridge, Tauri, wasm-bindgen, UniFFI. The crate does no I/O
//! and starts no tasks by itself. A [`Platform`] supplies the ports.

pub mod dto;
pub mod error;
pub mod platform;

pub use error::{AppError, ErrorCode, Result};
pub use platform::Platform;
```

`crates/mooze-app/src/error.rs`:

```rust
//! One flat error for every facade method.

use serde::{Deserialize, Serialize};

/// Stable error category. Serialized as `snake_case` text.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    Service,
    Storage,
    Credential,
    Network,
    InvalidInput,
    InvalidState,
    Timeout,
    Session,
    /// The secure store is locked. Web hosts set it; see the spec.
    Locked,
    /// The host transport failed. Hosts set it; the facade never does.
    Transport,
    Other,
}

/// Error every facade method returns.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, thiserror::Error)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
#[error("{code:?}: {message}")]
pub struct AppError {
    pub code: ErrorCode,
    pub message: String,
    /// Extra text for logs and support, never shown as the main message.
    pub details: Option<String>,
}

pub type Result<T> = std::result::Result<T, AppError>;

impl AppError {
    pub fn new(code: ErrorCode, message: impl Into<String>) -> Self {
        Self { code, message: message.into(), details: None }
    }

    pub fn invalid_input(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::InvalidInput, message)
    }

    pub fn invalid_state(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::InvalidState, message)
    }
}

impl From<mooze_core::Error> for AppError {
    fn from(e: mooze_core::Error) -> Self {
        use mooze_core::Error as E;
        let code = match &e {
            E::Service { .. } | E::Sync { .. } => ErrorCode::Service,
            E::Storage(_) => ErrorCode::Storage,
            E::Credential(_) => ErrorCode::Credential,
            E::Network(_) | E::Http { .. } => ErrorCode::Network,
            E::InvalidInput(_) => ErrorCode::InvalidInput,
            E::InvalidState(_) => ErrorCode::InvalidState,
            E::Timeout(_) => ErrorCode::Timeout,
            E::Session(_) => ErrorCode::Session,
            _ => ErrorCode::Other,
        };
        Self { code, message: e.to_string(), details: None }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use mooze_core::domain::ChainId;
    use mooze_core::Error as E;

    #[test]
    fn core_errors_map_to_stable_codes() {
        let cases: Vec<(E, ErrorCode)> = vec![
            (E::service(ChainId::Liquid, "x"), ErrorCode::Service),
            (E::storage("x"), ErrorCode::Storage),
            (E::Credential("x".into()), ErrorCode::Credential),
            (E::Network("x".into()), ErrorCode::Network),
            (E::Http { status: 500, body: "x".into() }, ErrorCode::Network),
            (E::InvalidInput("x".into()), ErrorCode::InvalidInput),
            (E::InvalidState("x".into()), ErrorCode::InvalidState),
            (E::Timeout("x".into()), ErrorCode::Timeout),
            (E::Session("x".into()), ErrorCode::Session),
            (E::Unexpected("x".into()), ErrorCode::Other),
        ];
        for (e, code) in cases {
            assert_eq!(AppError::from(e).code, code);
        }
    }

    #[test]
    fn code_serializes_as_snake_case() {
        assert_eq!(serde_json::to_string(&ErrorCode::InvalidInput).unwrap(), "\"invalid_input\"");
    }
}
```

The `E::Session`, `E::Timeout` and other variant spellings copy `CoreError::from` in `packages/mooze_core_bridge/rust/src/api/types.rs`. If a constructor named here, such as `E::service` or `E::storage`, has a different signature in `crates/mooze-core/src/error.rs`, use the constructor that file defines; the mapping must not change.

`crates/mooze-app/src/platform.rs`:

```rust
//! The ports a host supplies.

use std::sync::Arc;

use mooze_core::ports::{BlockingSpawner, Clock, HttpClient, KvStore, SecureStore, Spawner, Timer, WsConnector};
use mooze_core::{MaybeSend, MaybeSync};

/// Port implementations of one host. Each accessor returns a cheap clone.
pub trait Platform: MaybeSend + MaybeSync + 'static {
    type Kv: KvStore + Clone + 'static;
    type Secure: SecureStore + Clone + 'static;
    type Http: HttpClient + Clone + 'static;
    type Ws: WsConnector + Clone + 'static;
    type Clock: Clock + Clone + 'static;

    fn kv(&self) -> Self::Kv;
    fn secure(&self) -> Self::Secure;
    fn http(&self) -> Self::Http;
    fn ws(&self) -> Self::Ws;
    fn clock(&self) -> Self::Clock;
    fn spawner(&self) -> Arc<dyn Spawner>;
    fn timer(&self) -> Arc<dyn Timer>;
    /// Blocking pool for the Electrum clients. `None` on hosts without Electrum.
    fn blocking(&self) -> Option<Arc<dyn BlockingSpawner>>;
}
```

`crates/mooze-app/src/dto/mod.rs`:

```rust
//! Plain data types that cross the host boundary.
//!
//! Every type derives serde. With the `codegen` feature it also derives
//! `ts_rs::TS` and exports to `crates/mooze-app/generated/`.

pub mod config;

pub use config::*;
```

`crates/mooze-app/src/dto/config.rs`:

```rust
use serde::{Deserialize, Serialize};

use mooze_core::domain as d;

/// Network the wallet runs on.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
pub enum NetworkDto {
    Mainnet,
    Testnet,
    Regtest,
}

impl From<NetworkDto> for d::AppNetwork {
    fn from(n: NetworkDto) -> Self {
        match n {
            NetworkDto::Mainnet => d::AppNetwork::Mainnet,
            NetworkDto::Testnet => d::AppNetwork::Testnet,
            NetworkDto::Regtest => d::AppNetwork::Regtest,
        }
    }
}

/// Protocol used to reach the chains.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
pub enum BackendDto {
    Esplora,
    Electrum,
}

/// Settings for `App::open`. The host owns storage locations.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
pub struct AppConfig {
    pub network: NetworkDto,
    pub backend: BackendDto,
    /// Custom Bitcoin node. Empty uses the default servers.
    pub bitcoin_node_url: String,
    /// Custom Liquid node. Empty uses the default servers.
    pub liquid_node_url: String,
    /// Mooze backend base URL. `None` uses `mooze_core::api::DEFAULT_BASE_URL`.
    pub api_base_url: Option<String>,
}
```

- [ ] **Step 3: Build, test, deny**

Run: `cd crates/mooze-app && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo deny check advisories bans sources && cargo clippy --all-targets -- -D warnings`
Expected: 2 tests pass, wasm build passes, deny reports no errors (the two ignored advisories come from `mooze-core`'s `deny.toml` copy), clippy clean.

- [ ] **Step 4: Commit**

```bash
git add crates/mooze-app
git commit -m "Add mooze-app crate skeleton with AppError, Platform and AppConfig"
```

---

### Task 3: Move the DTOs into `mooze-app`

The bridge keeps compiling: its `api::types`, `api::pix` and `api::swap` re-export the moved types. `CoreError` and `CoreErrorKind` stay in the bridge.

**Files:**
- Create: `crates/mooze-app/src/dto/wallet.rs`, `src/dto/pix.rs`, `src/dto/swap.rs`
- Modify: `crates/mooze-app/src/dto/mod.rs`
- Modify: `packages/mooze_core_bridge/rust/Cargo.toml`, `rust/src/api/types.rs`, `rust/src/api/pix.rs`, `rust/src/api/swap.rs`
- Test: `cargo test` in both crates, the Dart smoke test

**Interfaces:**
- Produces: `mooze_app::dto::*` with every DTO of the bridge except `CoreError`, `CoreErrorKind`, `CoreConfig`. All conversion impls (`From<&d::X> for XDto`, `to_domain`) become `pub`.
- Consumes: `NetworkDto`, `BackendDto` from Task 2 (the bridge versions are deleted in favor of these).

- [ ] **Step 1: Move `types.rs`**

```bash
git mv packages/mooze_core_bridge/rust/src/api/types.rs crates/mooze-app/src/dto/wallet.rs
```

Edit `crates/mooze-app/src/dto/wallet.rs`:
- Delete `NetworkDto`, its `From` impl, `BackendDto` and `CoreConfig` (they live in `dto/config.rs` and in the bridge).
- Delete `CoreErrorKind`, `CoreError`, their `Display`, `Error` and `From` impls.
- On every `struct` and `enum`, replace the derive line with: `#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]` plus `#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]`. Keep `Copy` and `Eq` where the original had them. Enums keep the original variant names: no `serde(rename_all)`, so the wire format equals the Rust name.
- Change every `pub(crate) fn` to `pub fn`.
- Add `use serde::{Deserialize, Serialize};` at the top.

- [ ] **Step 2: Move the PIX and swap DTO sections**

Create `crates/mooze-app/src/dto/pix.rs` with the content of `packages/mooze_core_bridge/rust/src/api/pix.rs` from the line `// ───────────────────────────── DTOs` up to the line before `// ───────────────────────────── MoozeCore`, excluding the `#[frb(sync)]` free functions (`pix_poll_interval_ms`, `pix_fee`, `pix_validate_amount`, `tax_id_*`, `pix_looks_like_key`). Those move in Task 6. Apply the same derive and visibility edits as Step 1. Remove `#[frb(...)]` attributes.

Create `crates/mooze-app/src/dto/swap.rs` with the DTO section of `packages/mooze_core_bridge/rust/src/api/swap.rs` (from `// ───────────────────────────── DTOs` to the line before `// ───────────────────────────── MoozeCore`), excluding the free functions `peg_validate_amount` and `sideswap_default_url`, and excluding `peg_core_error` (it maps to `CoreError` and is rewritten in Task 7). Same edits. `SideSwapEventDto`'s constructors become `pub`.

In `crates/mooze-app/src/dto/mod.rs` add `pub mod pix; pub mod swap; pub mod wallet;` and `pub use pix::*; pub use swap::*; pub use wallet::*;`.

- [ ] **Step 3: Make the bridge consume the moved types**

In `packages/mooze_core_bridge/rust/Cargo.toml`, under `[dependencies]`, add before `mooze-core`:

```toml
mooze-app = { path = "../../../crates/mooze-app", version = "=0.1.0", features = ["electrum", "http-reqwest"] }
```

Create a new `packages/mooze_core_bridge/rust/src/api/types.rs`:

```rust
//! Plain data types that cross the bridge. The DTOs live in `mooze_app::dto`
//! and are re-exported here so the Dart class names stay unchanged.

pub use mooze_app::dto::*;

/// Settings for [`super::core::MoozeCore::open`].
#[derive(Debug, Clone)]
pub struct CoreConfig {
    /// Directory the core may own. The app support directory is a good choice.
    pub data_dir: String,
    pub network: NetworkDto,
    pub backend: BackendDto,
    /// Custom Bitcoin node. Empty uses the default servers.
    pub bitcoin_node_url: String,
    /// Custom Liquid node. Empty uses the default servers.
    pub liquid_node_url: String,
}

/// Category of a bridge error. Dart maps it to its failure classes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CoreErrorKind {
    Service,
    Storage,
    Credential,
    Network,
    InvalidInput,
    InvalidState,
    Timeout,
    Other,
    /// The API session is missing or could not be refreshed.
    Session,
}

/// Error thrown on the Dart side by every failing bridge call.
#[derive(Debug, Clone)]
pub struct CoreError {
    pub kind: CoreErrorKind,
    pub message: String,
}

impl std::fmt::Display for CoreError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}: {}", self.kind, self.message)
    }
}

impl std::error::Error for CoreError {}

impl From<mooze_core::Error> for CoreError {
    fn from(e: mooze_core::Error) -> Self {
        mooze_app::AppError::from(e).into()
    }
}

impl From<mooze_app::AppError> for CoreError {
    fn from(e: mooze_app::AppError) -> Self {
        use mooze_app::ErrorCode as C;
        let kind = match e.code {
            C::Service => CoreErrorKind::Service,
            C::Storage => CoreErrorKind::Storage,
            C::Credential => CoreErrorKind::Credential,
            C::Network => CoreErrorKind::Network,
            C::InvalidInput => CoreErrorKind::InvalidInput,
            C::InvalidState | C::Locked => CoreErrorKind::InvalidState,
            C::Timeout => CoreErrorKind::Timeout,
            C::Session => CoreErrorKind::Session,
            C::Transport | C::Other => CoreErrorKind::Other,
        };
        Self { kind, message: e.message }
    }
}
```

In the bridge `api/pix.rs` and `api/swap.rs`, delete the moved DTO sections and add `use super::types::*;` so the remaining methods resolve. Keep the free functions and the `MoozeCore` impl blocks as they are.

- [ ] **Step 4: Build and test both crates**

Run: `cd crates/mooze-app && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cd ../../packages/mooze_core_bridge/rust && cargo build && cargo test && cargo clippy --all-targets -- -D warnings`
Expected: all green. frb_generated.rs resolves `crate::api::types::X` through the re-exports.

- [ ] **Step 5: Run the Dart smoke test**

Run: `cd packages/mooze_core_bridge && flutter pub get && flutter test test/bridge_smoke_test.dart`
Expected: pass (not skipped: `rust/target/debug/libmooze_core_bridge.dylib` exists from Step 4).

- [ ] **Step 6: Commit**

```bash
git add crates/mooze-app packages/mooze_core_bridge
git commit -m "Move bridge DTOs into mooze-app::dto"
```

---

### Task 4: `App<P>`: open, migration, secure store, auth, API requests

**Files:**
- Create: `crates/mooze-app/src/app/mod.rs`
- Modify: `crates/mooze-app/src/lib.rs`
- Test: `crates/mooze-app/src/app/mod.rs` inline tests, with a `testing` helper module

**Interfaces:**
- Produces: `mooze_app::App<P>` with `open`, `is_migrated`, `import_flutter_snapshot`, `secure_get`, `secure_put`, `secure_delete`, `secure_list_keys`, `api_set_base_url`, `auth_ensure_session`, `auth_access_token`, `auth_force_refresh`, `auth_refresh_current`, `auth_invalidate`, `auth_reset`, `auth_set_device_safe`, `auth_device_id`, `api_set_metrics`, `api_request`. `pub(crate) struct Inner<P>` with fields the later tasks use: `platform: P`, `network: AppNetwork`, `backend: ChainBackend`, `endpoints: EndpointResolver`, `bitcoin: Mutex<Option<Bitcoin<P>>>`, `liquid: Mutex<Option<Liquid<P>>>`, `auth: Mutex<Option<Arc<Auth<P>>>>`, `api_base_url: RwLock<String>`, `device_safe: AtomicBool`, `metrics: RwLock<Option<Value>>`, `pix_polls: std::sync::Mutex<Vec<DepositPoll>>`, `sideswap: Arc<SideSwapState<P>>` (added in Task 7), `subscribers: Subscribers` (added in Task 7), `runtime: RuntimeState` (added in Task 8). `pub(crate) async fn auth(inner: &Inner<P>) -> Result<Arc<Auth<P>>>`.
- Produces: `mooze_app::testing::{TestPlatform, open_test_app}` under `#[cfg(test)]`.

- [ ] **Step 1: Write the failing tests**

In `crates/mooze-app/src/app/mod.rs`, at the bottom:

```rust
#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::testing::{open_test_app, TestPlatform, ABANDON, JWT_1, JWT_2};
    use mooze_core::ports::HttpMethod;
    use mooze_core::testing::block_on;
    use serde_json::json;

    #[test]
    fn no_mnemonic_reports_missing_then_signs_in_once_one_exists() {
        let (app, plat) = open_test_app();
        let out = block_on(app.auth_ensure_session()).unwrap();
        assert_eq!(out.kind, AuthEnsureKind::MissingMnemonic);
        assert_eq!(block_on(app.auth_access_token()).unwrap_err().code, ErrorCode::Session);
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        plat.secure_insert("jwt", JWT_1);
        plat.secure_insert("refresh_token", "rt");
        assert_eq!(block_on(app.auth_access_token()).unwrap(), JWT_1);
    }

    #[test]
    fn rejects_non_json_body() {
        let (app, _plat) = open_test_app();
        let err = block_on(app.api_request(HttpMethodDto::Post, "/x".into(), Some("{nope".into()))).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidInput);
    }

    #[test]
    fn sign_in_then_api_request_refreshes_on_401() {
        let (app, plat) = open_test_app();
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        let base = "https://api.test";
        plat.http.on_json(HttpMethod::Post, &format!("{base}/auth/challenge"), 200,
            json!({"data": {"id": "ch-1", "message": "SGVsbG8gV29ybGQ="}}));
        plat.http.on_json(HttpMethod::Post, &format!("{base}/auth/sign"), 200,
            json!({"data": {"jwt": JWT_1, "refresh_token": "rt-1"}}));
        plat.http.on_json(HttpMethod::Post, &format!("{base}/auth/refresh"), 200,
            json!({"data": {"jwt": JWT_2}}));
        plat.http.once_json(HttpMethod::Get, &format!("{base}/users/me"), 401, json!({"error": "expired"}));
        plat.http.on_json(HttpMethod::Get, &format!("{base}/users/me"), 200, json!({"id": "u2"}));

        block_on(app.api_set_base_url(base.into())).unwrap();
        block_on(app.api_set_metrics(Some(DeviceMetricsDto {
            device_id: "dev-1".into(), battery_level: Some(80), screen_brightness: None, boot_time: None,
        }))).unwrap();

        let out = block_on(app.auth_ensure_session()).unwrap();
        assert_eq!(out.kind, AuthEnsureKind::Ready, "{out:?}");
        assert_eq!(plat.secure_get("jwt").as_deref(), Some(JWT_1));
        assert_eq!(plat.secure_get("refresh_token").as_deref(), Some("rt-1"));

        let resp = block_on(app.api_request(HttpMethodDto::Get, "/users/me".into(), None)).unwrap();
        assert_eq!((resp.status, resp.body.as_str()), (200, r#"{"id":"u2"}"#));
        assert_eq!(plat.secure_get("jwt").as_deref(), Some(JWT_2));

        let reqs = plat.http.requests();
        let paths: Vec<String> = reqs.iter().map(|r| r.url.trim_start_matches(base).to_owned()).collect();
        assert_eq!(paths, vec!["/auth/challenge", "/auth/sign", "/users/me", "/auth/refresh", "/users/me"]);
        assert!(reqs[0].headers.get("Authorization").is_none());
        assert_eq!(reqs[2].headers.get("Authorization").map(String::as_str), Some(format!("Bearer {JWT_1}").as_str()));

        block_on(app.auth_invalidate()).unwrap();
        assert!(plat.secure_get("jwt").is_none());
    }

    #[test]
    fn unsafe_device_cannot_sign_in() {
        let (app, plat) = open_test_app();
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        block_on(app.auth_set_device_safe(false)).unwrap();
        let err = block_on(app.auth_access_token()).unwrap_err();
        assert_eq!(err.code, ErrorCode::Session);
        assert!(err.message.contains("Unsafe device"), "{}", err.message);
    }

    #[test]
    fn secure_round_trip_and_device_id() {
        let (app, plat) = open_test_app();
        plat.secure_insert("from_host", "ç value");
        assert_eq!(block_on(app.secure_get("from_host".into())).unwrap().as_deref(), Some("ç value"));
        block_on(app.secure_put("from_core".into(), "v".into())).unwrap();
        assert_eq!(plat.secure_get("from_core").as_deref(), Some("v"));
        assert_eq!(block_on(app.secure_list_keys("from_".into())).unwrap(), vec!["from_core", "from_host"]);
        block_on(app.secure_delete("from_core".into())).unwrap();
        assert!(plat.secure_get("from_core").is_none());
        let id = block_on(app.auth_device_id(Some("SERIAL".into()), None)).unwrap();
        assert_eq!(id, mooze_core::auth::hash_device_id("SERIAL"));
    }
}
```

The exact JSON shapes of `/auth/challenge`, `/auth/sign` and `/auth/refresh` copy `mock_backend` in the bridge `api/core.rs` tests. `MockHttp::on_json`, `once_json` and `requests()` exist in `mooze_core::testing`. If `MockHttp` matches on the full URL with a different rule than `base + path`, read `crates/mooze-core/src/testing/mod.rs` lines 110 to 190 and use the rule it implements; the asserted path list must stay as written.

- [ ] **Step 2: Create the test platform in `crates/mooze-app/src/testing.rs`**

```rust
//! Test platform over the mooze-core fakes.

use std::sync::Arc;

use mooze_core::ports::{BlockingSpawner, Spawner, Timer};
use mooze_core::testing::{ChannelSpawner, FixedClock, InlineSpawner, ManualTimer, MemoryKv, MockHttp, MockWs, TestExecutor};
use mooze_core::ports::KvStore;

use crate::dto::{AppConfig, BackendDto, NetworkDto};
use crate::{App, Platform};

pub const ABANDON: &str = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
/// Unsigned JWTs that expire in 2100.
pub const JWT_1: &str = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUxIn0.sig";
pub const JWT_2: &str = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUyIn0.sig";

#[derive(Clone)]
pub struct TestPlatform {
    pub kv: MemoryKv,
    pub secure: MemoryKv,
    pub http: MockHttp,
    pub ws: MockWs,
    pub clock: Arc<FixedClock>,
    pub spawner: ChannelSpawner,
    pub timer: Arc<ManualTimer>,
}

impl TestPlatform {
    /// Platform plus the executor that runs its spawned tasks.
    pub fn new() -> (Self, TestExecutor) {
        let (spawner, exec) = TestExecutor::new();
        let plat = Self {
            kv: MemoryKv::new(),
            secure: MemoryKv::new(),
            http: MockHttp::new(),
            ws: MockWs::new(|_| Vec::new()),
            clock: Arc::new(FixedClock::new(1_800_000_000_000)),
            spawner,
            timer: Arc::new(ManualTimer::new()),
        };
        (plat, exec)
    }

    pub fn with_ws(mut self, ws: MockWs) -> Self {
        self.ws = ws;
        self
    }

    pub fn secure_insert(&self, key: &str, value: &str) {
        mooze_core::testing::block_on(self.secure.put(key, value.as_bytes().to_vec())).unwrap();
    }

    pub fn secure_get(&self, key: &str) -> Option<String> {
        mooze_core::testing::block_on(self.secure.get(key)).unwrap().map(|b| String::from_utf8(b).unwrap())
    }
}

impl Platform for TestPlatform {
    type Kv = MemoryKv;
    type Secure = MemoryKv;
    type Http = MockHttp;
    type Ws = MockWs;
    type Clock = Arc<FixedClock>;
    fn kv(&self) -> MemoryKv { self.kv.clone() }
    fn secure(&self) -> MemoryKv { self.secure.clone() }
    fn http(&self) -> MockHttp { self.http.clone() }
    fn ws(&self) -> MockWs { self.ws.clone() }
    fn clock(&self) -> Arc<FixedClock> { self.clock.clone() }
    fn spawner(&self) -> Arc<dyn Spawner> { Arc::new(self.spawner.clone()) }
    fn timer(&self) -> Arc<dyn Timer> { self.timer.clone() }
    fn blocking(&self) -> Option<Arc<dyn BlockingSpawner>> { Some(Arc::new(InlineSpawner)) }
}

pub fn test_config() -> AppConfig {
    AppConfig {
        network: NetworkDto::Mainnet,
        backend: BackendDto::Esplora,
        bitcoin_node_url: String::new(),
        liquid_node_url: String::new(),
        api_base_url: None,
    }
}

/// Open app over a fresh test platform. Drops the executor: tests that
/// need spawned tasks call `open_test_app_with_executor`.
pub fn open_test_app() -> (App<TestPlatform>, TestPlatform) {
    let (app, plat, _exec) = open_test_app_with_executor();
    (app, plat)
}

pub fn open_test_app_with_executor() -> (App<TestPlatform>, TestPlatform, TestExecutor) {
    let (plat, exec) = TestPlatform::new();
    let app = mooze_core::testing::block_on(App::open(test_config(), plat.clone())).unwrap();
    (app, plat, exec)
}
```

`MockHttp` and `MockWs` must be `Clone`; `MockWs` already is, and `MockHttp` holds `Arc`s. If `MockHttp` lacks `#[derive(Clone)]`, add it in `crates/mooze-core/src/testing/mod.rs`. `Arc<FixedClock>` implements `Clock` through the blanket `impl<T: Clock + ?Sized> Clock for Arc<T>`.

Add `#[cfg(test)] pub(crate) mod testing;` to `lib.rs` and `pub mod app; pub use app::App;`.

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd crates/mooze-app && cargo test`
Expected: compile errors, `App` not defined.

- [ ] **Step 4: Write `crates/mooze-app/src/app/mod.rs`**

Port `packages/mooze_core_bridge/rust/src/api/core.rs` lines 1 to 396 (everything before the `// ───────────────────────────── bitcoin` section) with these changes:

- `Inner` becomes `pub(crate) struct Inner<P: Platform>` with `pub(crate) platform: P` replacing `kv` and `secure`. Field types: `bitcoin: Mutex<Option<Bitcoin<P>>>` where `pub(crate) type Bitcoin<P> = BitcoinWallet<<P as Platform>::Kv, <P as Platform>::Clock>;` and `Liquid<P>` likewise. `Sessions<P> = SessionManager<P::Http, P::Secure, P::Clock>`, `Api<P> = MoozeApi<P::Http, SerializedSession<P>>`.
- Remove `secure: RwLock<Option<DartSecureStore>>` and `secure_store()`. Use `self.platform.secure()` wherever `inner.secure_store()?` appeared. The "not set" behavior moves to the bridge's `LateSecureStore` in Task 10.
- Remove `Drop for Inner` for now (Task 7 adds it back for the driver).
- `pub struct App<P: Platform> { pub(crate) inner: Arc<Inner<P>> }` with `#[derive(Clone)]` (manual impl, so `P: Clone` is not required).
- `pub async fn open(config: AppConfig, platform: P) -> Result<App<P>>`: builds `backend` as `ChainBackend::Esplora` or, for `BackendDto::Electrum`, `ChainBackend::Electrum(ElectrumConfig::new(platform.blocking().ok_or_else(|| AppError::invalid_state("electrum backend needs a blocking spawner"))?))`. The `electrum` match arm is under `#[cfg(feature = "electrum")]`; without the feature `BackendDto::Electrum` returns `AppError::invalid_state("electrum backend not compiled in")`. `api_base_url` starts as `config.api_base_url.unwrap_or_else(|| DEFAULT_BASE_URL.to_owned())`. No `install_crypto_provider`: that is a host concern.
- `SessionManager::for_credentials(inner.platform.http(), inner.platform.secure(), inner.platform.clock(), &base_url, &credentials)`.
- Remove every `on_runtime(...)` wrapper: methods are plain `async fn` bodies. Remove `MaybeSend` juggling that existed only for `on_runtime`.
- Every method returns `crate::Result<T>`; the ones that returned `()` or a bare value now return `Ok(...)`.
- `api_request` body parse error: `AppError::invalid_input(format!("json_body is not JSON: {e}"))`.
- `secure_get` converts bytes with `String::from_utf8(bytes).map_err(|_| AppError::new(ErrorCode::Storage, format!("secure value for {key} is not UTF-8")))`.
- `pub(crate) async fn auth<P: Platform>(inner: &Inner<P>) -> Result<Arc<Auth<P>>>`.

Imports: `use mooze_core::api::{ApiConfig, MoozeApi, SessionProvider, DEFAULT_BASE_URL}; use mooze_core::auth::{get_device_id, metrics_json, DeviceInfo, SessionManager}; use mooze_core::domain::{AppNetwork, ChainId}; use mooze_core::migration::{import_flutter_data, is_migrated, parse_snapshot}; use mooze_core::ports::{KvStore, MaybeSend}; use mooze_core::store::CredentialStore; use mooze_core::wallet::{BitcoinWallet, ChainBackend, EndpointResolver, LiquidWallet}; use mooze_core::pix::rules::DepositPoll; use tokio::sync::Mutex; use std::sync::{Arc, RwLock}; use std::sync::atomic::{AtomicBool, Ordering}; use serde_json::Value; use crate::dto::*; use crate::{AppError, ErrorCode, Platform, Result};` and `#[cfg(feature = "electrum")] use mooze_core::wallet::ElectrumConfig;`.

The `not_connected(chain)` helper returns `AppError::invalid_state(format!("{} wallet not connected", chain.as_str()))`. Keep the message text: Dart tests match on the kind only, but logs compare text.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd crates/mooze-app && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo clippy --all-targets -- -D warnings`
Expected: 5 tests in `app::tests` plus the 2 from Task 2 pass. wasm build passes.

- [ ] **Step 6: Commit**

```bash
git add crates/mooze-app
git commit -m "Add App open, migration, secure store, auth and API request methods"
```

---

### Task 5: Wallet methods on `App`

**Files:**
- Create: `crates/mooze-app/src/app/wallets.rs`
- Modify: `crates/mooze-app/src/app/mod.rs` (add `mod wallets;`)
- Test: inline tests

**Interfaces:**
- Produces on `App<P>`: `bitcoin_connect(mnemonic: String)`, `bitcoin_disconnect()`, `bitcoin_sync()`, `bitcoin_balance()`, `bitcoin_transactions()`, `bitcoin_take_events()`, `bitcoin_receive_address(label: Option<String>)`, `bitcoin_estimate_fee(request: SendRequestDto)`, `bitcoin_send(request: SendRequestDto)`, `bitcoin_block_height()`, `bitcoin_derived_addresses(keychain: KeychainDto, start: u32, count: u32)`, `bitcoin_unspent_outputs()`, `bitcoin_is_mine(address: String)`, `bitcoin_next_unused_address()`, `bitcoin_register_external_broadcast(transaction: TransactionDto)`, and the `liquid_*` set: `liquid_connect`, `liquid_disconnect`, `liquid_sync`, `liquid_balance`, `liquid_refresh_balance`, `liquid_apply_balance_delta(asset_ids: Vec<String>, deltas: Vec<i64>)`, `liquid_transactions`, `liquid_take_events`, `liquid_receive_address(asset_id: Option<String>, label: Option<String>)`, `liquid_derived_addresses`, `liquid_unspent_outputs`, `liquid_is_mine(address: String, scan_limit: u32)`, `liquid_next_unused_address`, `liquid_utxos`, `liquid_estimate_fee`, `liquid_build_lbtc_send(destination: String, amount_sat: u64, fee_rate_sat_per_vb: Option<f64>, drain: bool)`, `liquid_send(request: SendRequestDto)`, `liquid_sign_and_broadcast(pset: String)`, `liquid_sign_swap_pset(pset: String)`. Each returns `Result<...>` with the same DTO as the bridge method of the same name.
- The three Liquid signing methods read the mnemonic from the secure store (`load_mnemonic`, moved from the bridge `glue.rs`). The bridge keeps its `mnemonic` parameters and ignores them in favor of the store only when the store has a mnemonic; see Task 10 for the exact rule.

- [ ] **Step 1: Write the failing tests**

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{open_test_app, ABANDON};
    use mooze_core::testing::block_on;

    #[test]
    fn derives_the_same_first_addresses_as_the_flutter_app() {
        let (app, _plat) = open_test_app();
        block_on(app.bitcoin_connect(ABANDON.into())).unwrap();
        let ext = block_on(app.bitcoin_derived_addresses(KeychainDto::External, 0, 2)).unwrap();
        assert_eq!(ext[0].address, "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu");
        assert_eq!(ext[1].address, "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g");
        let change = block_on(app.bitcoin_derived_addresses(KeychainDto::Internal, 0, 1)).unwrap();
        assert_eq!(change[0].address, "bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el");
        let own = block_on(app.bitcoin_is_mine(ext[1].address.clone())).unwrap().unwrap();
        assert_eq!((own.keychain, own.index), (KeychainDto::External, 1));
        assert!(block_on(app.bitcoin_is_mine("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq".into())).unwrap().is_none());
        assert_eq!(block_on(app.bitcoin_is_mine("garbage".into())).unwrap_err().code, ErrorCode::InvalidInput);

        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let lq = block_on(app.liquid_derived_addresses(KeychainDto::External, 0, 1)).unwrap();
        assert!(lq[0].address.starts_with("lq1"), "{}", lq[0].address);
        assert!(block_on(app.liquid_transactions()).unwrap().is_empty());
    }

    #[test]
    fn calls_before_connect_report_invalid_state() {
        let (app, _plat) = open_test_app();
        let err = block_on(app.bitcoin_balance()).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidState);
        assert_eq!(err.message, "bitcoin wallet not connected");
    }

    #[test]
    fn balance_delta_lengths_must_match() {
        let (app, _plat) = open_test_app();
        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let err = block_on(app.liquid_apply_balance_delta(vec!["a".into()], vec![])).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidInput);
    }

    #[test]
    fn liquid_signing_needs_a_stored_mnemonic() {
        let (app, _plat) = open_test_app();
        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let err = block_on(app.liquid_sign_swap_pset("cHNldP8BAgQCAAAAAQQBAAEFAQABBgEDAfsEAgAAAAA=".into())).unwrap_err();
        assert_eq!(err.code, ErrorCode::Credential);
    }
}
```

The addresses copy `packages/mooze_core_bridge/test/bridge_smoke_test.dart`. `bitcoin_connect` and `liquid_connect` need no network: `connect` only loads or creates the wallet.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd crates/mooze-app && cargo test wallets`
Expected: compile error, methods not found.

- [ ] **Step 3: Write `crates/mooze-app/src/app/wallets.rs`**

Port the `// ───────────────────────────── bitcoin` and `// ───────────────────────────── liquid` sections of the bridge `api/core.rs` (lines 397 to 751) as `impl<P: Platform> App<P>`. Rules:
- Drop `on_runtime`. Replace `inner.kv.clone()` with `inner.platform.kv()`, `SystemClock` with `inner.platform.clock()`.
- `bitcoin_connect`: after `BitcoinWallet::connect(&creds, kv, clock, endpoints)`, call `wallet.set_backend(inner.backend.clone(), inner.endpoints.clone())?` only when `inner.backend.is_electrum()`, exactly as the bridge does.
- `liquid_send`, `liquid_sign_and_broadcast`, `liquid_sign_swap_pset` lose the `mnemonic` parameter and call `load_mnemonic(&inner).await?`:

```rust
/// Mnemonic from the secure store (`mnemonic_mainWallet`).
pub(crate) async fn load_mnemonic<P: Platform>(inner: &Inner<P>) -> Result<String> {
    let credentials = CredentialStore::new(inner.platform.secure(), inner.network).load().await?;
    if credentials.is_absent() {
        return Err(AppError::new(ErrorCode::Credential, "no mnemonic in the secure store"));
    }
    Ok(credentials.mnemonic)
}
```

- Every method returns `Result<_>`; `bitcoin_disconnect` and `liquid_disconnect` return `Result<()>` with `Ok(())`.
- `liquid_apply_balance_delta` length check error: `AppError::invalid_input("asset_ids and deltas differ in length")`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd crates/mooze-app && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo clippy --all-targets -- -D warnings`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add crates/mooze-app
git commit -m "Add Bitcoin and Liquid wallet methods to App"
```

---

### Task 6: Glue ports, PIX methods and pure rules

**Files:**
- Create: `crates/mooze-app/src/glue.rs` (only `LiquidPort<P>` and `WalletPegPort<P>` in this task)
- Create: `crates/mooze-app/src/app/pix.rs`, `crates/mooze-app/src/rules.rs`
- Modify: `crates/mooze-app/src/lib.rs`, `src/app/mod.rs`
- Test: inline tests in `app/pix.rs` and `rules.rs`

**Interfaces:**
- Produces: `glue::LiquidPort<P>` (`AddressProvider`, `SwapSigner`), `glue::WalletPegPort<P>` (`PegWallet`), both holding `Weak<Inner<P>>`, constructed with `LiquidPort::new(&Arc<Inner<P>>)`.
- Produces on `App<P>`: `pix_create_deposit(amount_in_cents: u64, asset_id: String, tax_id_number: Option<String>, address: Option<String>)`, `pix_poll_tick()`, `pix_active_polls()`, `pix_cancel_polls()`, `pix_get_deposit(deposit_id: String)`, `pix_list_deposits(limit: Option<u32>, offset: Option<u32>)`, `pix_update_deposit_details(deposit_ids: Vec<String>)`, `pix_history(limit, offset)`, `pix_clear_deposits()`, `favorite_payers_list()`, `favorite_payer_save(id: Option<u64>, label: String, cpf: String)`, `favorite_payer_delete(id: u64)`, `favorite_payer_cpf_exists(cpf: String, excluding_id: Option<u64>)`, `favorite_payers_clear()`, `pix_flag_is_set(flag: PixFlagDto)`, `pix_flag_set(flag)`, `pix_flag_reset(flag)`.
- Produces in `mooze_app::rules`: `pix_poll_interval_ms() -> u32`, `pix_fee(amount_brl: f64, has_referral: bool, quote_brl: Option<f64>) -> PixFeeDto`, `pix_validate_amount(amount_brl: f64, limits: Option<DepositLimitsDto>) -> DepositValidationDto`, `tax_id_validate(input: String) -> Option<CpfValidationErrorDto>`, `tax_id_is_valid(input: String) -> bool`, `tax_id_strip(input: String) -> String`, `tax_id_format(digits: String) -> String`, `tax_id_mask_input(text: String) -> String`, `pix_looks_like_key(value: String) -> bool`, `peg_validate_amount(...)` and `sideswap_default_url() -> String` with the same signatures as the bridge free functions.

- [ ] **Step 1: Write the failing tests**

In `crates/mooze-app/src/app/pix.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{open_test_app, ABANDON, JWT_1};
    use mooze_core::domain::DEPIX_ASSET_ID;
    use mooze_core::ports::HttpMethod;
    use mooze_core::testing::block_on;
    use serde_json::json;

    fn ready_session(plat: &crate::testing::TestPlatform) {
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        plat.secure_insert("jwt", JWT_1);
        plat.secure_insert("refresh_token", "rt");
    }

    #[test]
    fn deposit_create_poll_and_read_back() {
        let (app, plat) = open_test_app();
        ready_session(&plat);
        let base = mooze_core::api::DEFAULT_BASE_URL;
        // Same answers as the bridge mock backend in api/pix.rs `pix_backend`.
        plat.http.on_json(HttpMethod::Post, &format!("{base}/v2/transactions"), 200,
            json!({"data": {"transaction_id": "dep-1", "qr_copy_paste": "qr-copy", "qr_image_url": "https://img"}}));
        plat.http.on_json(HttpMethod::Get, &format!("{base}/transactions/status?ids=dep-1"), 200,
            json!({"data": [{"id": "dep-1", "status": "depix_sent", "amount_in_cents": 1000,
                             "blockchain_txid": "tx9", "asset_amount": 970000}]}));

        // Without a Liquid wallet there is no address.
        let err = block_on(app.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), None, None)).unwrap_err();
        assert!(err.message.contains("Erro ao gerar endereço"), "{}", err.message);
        let err = block_on(app.pix_create_deposit(1000, "nope".into(), None, None)).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidInput);

        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let dep = block_on(app.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), Some("52998224725".into()), None)).unwrap();
        assert_eq!((dep.deposit_id.as_str(), dep.pix_key.as_str()), ("dep-1", "qr-copy"));
        assert_eq!(dep.status, DepositStatusDto::Pending);
        assert_eq!(block_on(app.pix_active_polls()).unwrap(), 1);

        let events = block_on(app.pix_poll_tick()).unwrap();
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].status, DepositStatusDto::DepixSent);
        assert_eq!(events[0].asset_amount, Some(970_000));
        assert_eq!(block_on(app.pix_active_polls()).unwrap(), 0);
        assert!(block_on(app.pix_poll_tick()).unwrap().is_empty());

        let stored = block_on(app.pix_get_deposit("dep-1".into())).unwrap().unwrap();
        assert_eq!((stored.status, stored.blockchain_txid.as_deref()), (DepositStatusDto::DepixSent, Some("tx9")));
        assert_eq!(block_on(app.pix_list_deposits(Some(10), None)).unwrap().len(), 1);

        let reqs = plat.http.requests();
        assert_eq!(reqs[0].method, HttpMethod::Post);
        assert_eq!(reqs[0].headers.get("Authorization").map(String::as_str), Some(format!("Bearer {JWT_1}").as_str()));
        let body: serde_json::Value = serde_json::from_slice(reqs[0].body.as_deref().unwrap()).unwrap();
        assert!(body["address"].as_str().unwrap().starts_with("lq1"), "{body}");
        assert_eq!((body["tax_id"].as_str(), body["network"].as_str()), (Some("52998224725"), Some("liquid")));
        assert!(reqs[1].url.ends_with("/transactions/status?ids=dep-1"));

        block_on(app.pix_clear_deposits()).unwrap();
        assert!(block_on(app.pix_list_deposits(None, None)).unwrap().is_empty());
    }

    #[test]
    fn favorite_payers_and_flags() {
        let (app, _plat) = open_test_app();
        let refused = block_on(app.favorite_payer_save(None, "Ana".into(), "529.982.247-25".into())).unwrap();
        assert!(refused.is_none());
        let dup = block_on(app.favorite_payer_save(None, "Bia".into(), "52998224725".into())).unwrap();
        assert_eq!(dup, Some(FavoritePayerSaveErrorDto::DuplicateCpf));
        assert_eq!(block_on(app.favorite_payers_list()).unwrap().len(), 1);
        assert!(block_on(app.favorite_payer_cpf_exists("52998224725".into(), None)).unwrap());
        assert!(!block_on(app.pix_flag_is_set(PixFlagDto::TutorialShown)).unwrap());
        block_on(app.pix_flag_set(PixFlagDto::TutorialShown)).unwrap();
        assert!(block_on(app.pix_flag_is_set(PixFlagDto::TutorialShown)).unwrap());
    }
}
```

The routes, bodies and assertions copy `deposit_create_poll_and_read_back` and `pix_backend` from the bridge `api/pix.rs`, so the facade proves the same behavior. `MockHttp` records `HttpRequest` values: `method`, `url`, `headers` and `body: Option<Vec<u8>>`.

In `crates/mooze-app/src/rules.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pure_helpers_match_the_dart_rules() {
        assert!(tax_id_is_valid("529.982.247-25".into()));
        assert!(!tax_id_is_valid("111.111.111-11".into()));
        assert_eq!(tax_id_strip("529.982.247-25".into()), "52998224725");
        assert_eq!(tax_id_format("52998224725".into()), "529.982.247-25");
        assert_eq!(tax_id_mask_input("5299822472512345678".into()).len(), 18);
        assert_eq!(pix_poll_interval_ms(), 30_000);
        assert!(pix_fee(100.0, false, Some(5.0)).estimated_asset_units.is_some());
        assert!(!pix_validate_amount(0.0, None).is_valid);
        assert!(sideswap_default_url().starts_with("wss://"));
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd crates/mooze-app && cargo test pix rules`
Expected: compile errors.

- [ ] **Step 3: Write `glue.rs` with the two wallet ports**

Port lines 1 to 220 of `packages/mooze_core_bridge/rust/src/glue.rs` (`load_mnemonic` was moved in Task 5; import it from `crate::app::wallets`). `LiquidPort<P: Platform> { inner: Weak<Inner<P>> }` and `WalletPegPort<P>` with the same trait impls. Replace `mooze_core::Error` constructions with the core error types the traits expect: the `AddressProvider`, `SwapSigner` and `PegWallet` traits return `mooze_core::Result` and `PegError`, so inside these impls keep `mooze_core::Error::InvalidState("… wallet not connected")` for `gone()` and `not_connected()`; they are not facade methods. `gone()` message: `core closed`.

- [ ] **Step 4: Write `rules.rs`**

Move the `#[frb(sync)]` free functions from the bridge `api/pix.rs` and `api/swap.rs` here without the attribute. Keep names and signatures. `sideswap_default_url` returns `SIDESWAP_API_URL.to_owned()`.

- [ ] **Step 5: Write `app/pix.rs`**

Port the `impl MoozeCore` block of the bridge `api/pix.rs` as `impl<P: Platform> App<P>`. `type Pix<P> = PixService<P::Http, SessionTokens<SerializedSession<P>>, P::Kv, LiquidPort<P>>;` and `pix_service(inner: &Arc<Inner<P>>)` builds `PixClient::new(inner.platform.http(), SessionTokens(auth.session.clone()), inner.api_base_url())`. `pix_create_deposit` keeps the error text mapping through `create_deposit_error_message`, producing `AppError { code: Network | Timeout, message }`. Unknown asset: `AppError::invalid_input(format!("unknown asset id {asset_id}"))`.

Register `pub mod glue; pub mod rules;` in `lib.rs` and `mod pix;` in `app/mod.rs`.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd crates/mooze-app && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo clippy --all-targets -- -D warnings`
Expected: pass.

- [ ] **Step 7: Commit**

```bash
git add crates/mooze-app
git commit -m "Add PIX methods, wallet glue ports and pure rules to mooze-app"
```

---

### Task 7: Events, SideSwap state, driver, swap and peg methods

**Files:**
- Create: `crates/mooze-app/src/events.rs`, `crates/mooze-app/src/app/swap.rs`
- Modify: `crates/mooze-app/src/glue.rs` (SideSwap state and driver), `src/app/mod.rs` (fields `sideswap`, `subscribers`, `Drop`), `src/lib.rs`
- Test: inline tests in `events.rs` and `app/swap.rs`

**Interfaces:**
- Produces: `events::{AppEvent, EventSink, SubscriptionId, Subscribers}`.

```rust
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", content = "data", rename_all = "snake_case")]
pub enum AppEvent {
    SideSwap(SideSwapEventDto),
    Transactions(Vec<TransactionEventDto>),
    PixStatus(Vec<PixStatusEventDto>),
    SyncState(SyncStateDto),
    PegProgress(PegRefreshDto),
    SessionLock(SessionLockStateDto),
    AuthSession(AuthEnsureDto),
}
pub trait EventSink: MaybeSend + MaybeSync { fn send(&self, event: AppEvent) -> bool; }
pub type SubscriptionId = u64;
```

`SyncStateDto` and `SessionLockStateDto` are added to `dto/runtime.rs` in this task (definitions below); `Runtime` fills them in Task 8.
- Produces on `App<P>`: `subscribe(&self, sink: Box<dyn EventSink>) -> SubscriptionId`, `unsubscribe(&self, id: SubscriptionId)`, `sideswap_connect(api_key: String, url: Option<String>)`, `sideswap_disconnect()`, `sideswap_is_connected()`, `sideswap_start_events()`, `sideswap_stop_events()`, `sideswap_events_running()`, `sideswap_markets()`, `sideswap_assets()`, `sideswap_start_quote(send_asset_id, receive_asset_id, amount)`, `sideswap_stop_quote()`, `sideswap_execute_swap(quote_id: u64)`, `peg_limits()`, `peg_quote(direction, amount_sat, fee_rate_sat_per_vbyte, drain)`, `peg_execute(wallet_id, direction, amount_sat, fee_rate_sat_per_vbyte, drain, external_payout_address)`, `peg_status(direction, order_id)`, `peg_list(wallet_id)`, `peg_restore(wallet_id)`, `peg_tracked()`, `peg_untrack(order_id)`, `peg_refresh_due(wallet_id)`.
- `Subscribers::emit(&self, event: AppEvent) -> usize` returns the number of live sinks after removing the ones whose `send` returned false.

- [ ] **Step 1: Add the runtime DTOs to `crates/mooze-app/src/dto/runtime.rs`**

```rust
use serde::{Deserialize, Serialize};

/// Phase of the sync orchestrator. Mirrors `mooze_core::sync::SyncPhase`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
pub enum SyncPhaseDto { Idle, Running, Cooling, Stopped }

/// Observable sync state after a refresh.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
pub struct SyncStateDto {
    pub phase: SyncPhaseDto,
    pub last_error: Option<String>,
    pub last_success_at_ms: Option<u64>,
    pub last_duration_ms: Option<u64>,
    /// Chains with at least one successful sync this session.
    pub first_synced_chains: Vec<super::ChainDto>,
}

/// Whether the host must show the PIN or biometric challenge.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
pub enum SessionLockStateDto { Unlocked, Locked }

/// Settings for `App::start`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS), ts(export, export_to = "../generated/"))]
pub struct StartConfigDto {
    /// Periodic refresh cadence. `None` uses the core default (60 s).
    pub sync_tick_ms: Option<u64>,
    /// Per-chain sync timeout. `None` uses the core default (60 s).
    pub sync_timeout_ms: Option<u64>,
    /// Run one refresh inside `start`.
    pub startup_sync: bool,
    /// Wallet id under which pegs are stored. `None` disables the peg loop.
    pub peg_wallet_id: Option<String>,
}
```

Add `pub mod runtime; pub use runtime::*;` to `dto/mod.rs`.

- [ ] **Step 2: Write the failing tests**

`crates/mooze-app/src/events.rs` tests:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicBool, Ordering};
    use std::sync::{Arc, Mutex};

    struct Collect(Arc<Mutex<Vec<AppEvent>>>, Arc<AtomicBool>);
    impl EventSink for Collect {
        fn send(&self, e: AppEvent) -> bool {
            self.0.lock().unwrap().push(e);
            self.1.load(Ordering::SeqCst)
        }
    }

    #[test]
    fn emit_reaches_live_sinks_and_drops_dead_ones() {
        let subs = Subscribers::default();
        let (a, alive_a) = (Arc::new(Mutex::new(vec![])), Arc::new(AtomicBool::new(true)));
        let (b, alive_b) = (Arc::new(Mutex::new(vec![])), Arc::new(AtomicBool::new(false)));
        let id_a = subs.subscribe(Box::new(Collect(a.clone(), alive_a)));
        subs.subscribe(Box::new(Collect(b.clone(), alive_b)));
        assert_eq!(subs.emit(AppEvent::SessionLock(SessionLockStateDto::Locked)), 1);
        assert_eq!(a.lock().unwrap().len(), 1);
        assert_eq!(b.lock().unwrap().len(), 1);
        assert_eq!(subs.emit(AppEvent::SessionLock(SessionLockStateDto::Unlocked)), 1);
        assert_eq!(b.lock().unwrap().len(), 1, "dead sink removed after first false");
        subs.unsubscribe(id_a);
        assert_eq!(subs.emit(AppEvent::SessionLock(SessionLockStateDto::Unlocked)), 0);
    }

    #[test]
    fn app_event_serializes_tagged() {
        let v = serde_json::to_value(AppEvent::SessionLock(SessionLockStateDto::Locked)).unwrap();
        assert_eq!(v, serde_json::json!({"type": "session_lock", "data": "Locked"}));
    }
}
```

`crates/mooze-app/src/app/swap.rs` tests:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::events::{AppEvent, EventSink};
    use crate::testing::{open_test_app_with_executor, TestPlatform, ABANDON};
    use mooze_core::testing::{block_on, MockWs};
    use serde_json::{json, Value};
    use std::sync::{Arc, Mutex};

    /// Replies of the mock SideSwap server. Copied from the bridge
    /// `api/swap.rs` test module (`replies`), which answers login_client,
    /// server_status (plus one PegInWalletBalance push), markets and assets.
    fn replies(frame: &str) -> Vec<String> {
        let v: Value = serde_json::from_str(frame).unwrap();
        let id = v["id"].clone();
        let method = v["method"].as_str().unwrap_or_default().to_owned();
        let reply = |r: Value| json!({"id": id, "method": method, "result": r}).to_string();
        match method.as_str() {
            "login_client" => vec![reply(json!({}))],
            "server_status" => vec![
                reply(json!({"elements_fee_rate": 0.1, "min_peg_in_amount": 10000, "min_peg_out_amount": 25000,
                    "server_fee_percent_peg_in": 0.1, "server_fee_percent_peg_out": 0.1})),
                json!({"method": "subscribed_value", "params": {"value": {"PegInWalletBalance": {"available": 777}}}}).to_string(),
            ],
            _ => vec![reply(json!({}))],
        }
    }

    struct Collect(Arc<Mutex<Vec<AppEvent>>>);
    impl EventSink for Collect {
        fn send(&self, e: AppEvent) -> bool { self.0.lock().unwrap().push(e); true }
    }

    fn sideswap_kinds(events: &[AppEvent]) -> Vec<SideSwapEventKind> {
        events.iter().filter_map(|e| match e { AppEvent::SideSwap(s) => Some(s.kind), _ => None }).collect()
    }

    #[test]
    fn connect_limits_and_balance_push_reach_subscribers() {
        let (plat, mut exec) = TestPlatform::new();
        let plat = plat.with_ws(MockWs::new(replies));
        let app = block_on(App::open(crate::testing::test_config(), plat.clone())).unwrap();
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        block_on(app.sideswap_connect("key".into(), None)).unwrap();
        assert!(block_on(app.sideswap_is_connected()).unwrap());
        let limits = block_on(app.peg_limits()).unwrap();
        assert_eq!(limits.min_peg_in_sat, 10_000);

        let got = Arc::new(Mutex::new(vec![]));
        app.subscribe(Box::new(Collect(got.clone())));
        block_on(app.sideswap_start_events()).unwrap();
        exec.run_until_stalled();
        assert!(sideswap_kinds(&got.lock().unwrap()).contains(&SideSwapEventKind::PegInWalletBalance));

        block_on(app.sideswap_stop_events()).unwrap();
        exec.run_until_stalled();
        assert_eq!(sideswap_kinds(&got.lock().unwrap()).last(), Some(&SideSwapEventKind::Closed));
        assert!(!block_on(app.sideswap_events_running()).unwrap());
    }

    #[test]
    fn driver_stops_when_last_subscriber_leaves() {
        let (plat, mut exec) = TestPlatform::new();
        let plat = plat.with_ws(MockWs::new(replies));
        let app = block_on(App::open(crate::testing::test_config(), plat.clone())).unwrap();
        block_on(app.sideswap_connect("key".into(), None)).unwrap();
        let got = Arc::new(Mutex::new(vec![]));
        let id = app.subscribe(Box::new(Collect(got.clone())));
        block_on(app.sideswap_start_events()).unwrap();
        exec.run_until_stalled();
        app.unsubscribe(id);
        plat.timer.advance(500);
        exec.run_until_stalled();
        assert!(!block_on(app.sideswap_events_running()).unwrap());
        // A new subscription starts a fresh driver.
        let got2 = Arc::new(Mutex::new(vec![]));
        app.subscribe(Box::new(Collect(got2.clone())));
        block_on(app.sideswap_start_events()).unwrap();
        assert!(block_on(app.sideswap_events_running()).unwrap());
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd crates/mooze-app && cargo test events swap`
Expected: compile errors.

- [ ] **Step 4: Write `events.rs`**

```rust
//! Push events from the facade to the host.

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Mutex;

use mooze_core::{MaybeSend, MaybeSync};
use serde::{Deserialize, Serialize};

use crate::dto::*;

/* AppEvent, EventSink, SubscriptionId as in Interfaces */

/// Registered sinks of one `App`.
#[derive(Default)]
pub struct Subscribers {
    next_id: AtomicU64,
    sinks: Mutex<Vec<(SubscriptionId, Box<dyn EventSink>)>>,
}

impl Subscribers {
    pub fn subscribe(&self, sink: Box<dyn EventSink>) -> SubscriptionId {
        let id = self.next_id.fetch_add(1, Ordering::SeqCst) + 1;
        self.sinks.lock().unwrap_or_else(|e| e.into_inner()).push((id, sink));
        id
    }

    pub fn unsubscribe(&self, id: SubscriptionId) {
        self.sinks.lock().unwrap_or_else(|e| e.into_inner()).retain(|(i, _)| *i != id);
    }

    /// Sends `event` to every sink. Removes sinks that return false.
    /// Returns the number of sinks still registered.
    pub fn emit(&self, event: AppEvent) -> usize {
        let mut sinks = self.sinks.lock().unwrap_or_else(|e| e.into_inner());
        sinks.retain(|(_, s)| s.send(event.clone()));
        sinks.len()
    }

    pub fn len(&self) -> usize {
        self.sinks.lock().unwrap_or_else(|e| e.into_inner()).len()
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}
```

The sink runs under the lock, so a sink must not call back into `subscribe`. Document that on `EventSink`.

- [ ] **Step 5: Port the SideSwap state and driver into `glue.rs`**

Port lines 220 to 438 of the bridge `glue.rs` with these changes:
- `SideSwapState<P: Platform>`; `type Swap<P> = SwapService<P::Ws, LiquidPort<P>>`.
- `Emit` becomes a closure `Arc<dyn Fn(SideSwapEventDto) -> bool + MaybeSend + MaybeSync>` built by `App::sideswap_start_events`: it calls `inner.subscribers.emit(AppEvent::SideSwap(e)) > 0`. Zero live sinks returns false and stops the driver, which preserves the "receiver gone" rule.
- `DriverCtl::pause(d)` takes `timer: &dyn Timer`: `let sleep = timer.sleep(d.as_millis() as u64);` instead of `tokio::time::sleep`.
- `tokio::task::yield_now().await` becomes `timer.sleep(0).await`.
- `start_driver(self: &Arc<Self>, platform_spawner: Arc<dyn Spawner>, timer: Arc<dyn Timer>, clock: P::Clock, emit: Emit)` spawns through `spawner.spawn(Box::pin(async move { ... }))`.
- `SystemClock.now_ms()` becomes `clock.now_ms()`.
- `tokio::sync::{Mutex, Notify}` stay (runtime-free).

Add to `Inner<P>`: `pub(crate) sideswap: Arc<SideSwapState<P>>`, `pub(crate) subscribers: Subscribers`. Add `impl<P: Platform> Drop for Inner<P> { fn drop(&mut self) { self.sideswap.stop_driver(); } }`.

- [ ] **Step 6: Write `app/swap.rs`**

Port the `impl MoozeCore` block of the bridge `api/swap.rs` as `impl<P: Platform> App<P>`:
- `sideswap_connect`: `SideSwapClient::new(inner.platform.ws(), api_key).with_url(...).with_clock(Arc::new(inner.platform.clock()))`.
- `sideswap_events(sink)` becomes `sideswap_start_events()`: builds the `Emit` closure over `inner.subscribers` and calls `inner.sideswap.start_driver(platform.spawner(), platform.timer(), platform.clock(), emit)`. `sideswap_close_events` becomes `sideswap_stop_events()`.
- `peg_core_error(e: PegError) -> AppError` maps `PegError` variants to `ErrorCode` with the same table the bridge used for `CoreErrorKind`.
- `peg_store(inner, wallet_id)` builds `KvPegStore::new(inner.platform.kv(), inner.platform.clock(), wallet_id)`.
- Add `pub fn subscribe` and `pub fn unsubscribe` on `App<P>` delegating to `inner.subscribers`.

Register `pub mod events;` in `lib.rs`, `mod swap;` in `app/mod.rs`.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `cd crates/mooze-app && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo clippy --all-targets -- -D warnings`
Expected: pass. If `MockWsConnection::recv` returns `Closed` once its inbox is empty and the driver then enters reconnect backoff, the balance push still arrives first; the `Closed` kind assertion at the end holds because `stop_driver` emits `closed` last.

- [ ] **Step 8: Commit**

```bash
git add crates/mooze-app
git commit -m "Add AppEvent subscriptions, SideSwap driver and swap/peg methods"
```

---

### Task 8: `Runtime`: start, stop, background, foreground, loops

**Files:**
- Create: `crates/mooze-app/src/runtime/mod.rs`, `src/runtime/sync_loop.rs`, `src/runtime/syncers.rs`
- Modify: `crates/mooze-app/src/app/mod.rs` (field `runtime: RuntimeState`), `src/lib.rs`
- Test: inline tests in `sync_loop.rs` (generic, fake syncer) and `runtime/mod.rs`

**Interfaces:**
- Produces on `App<P>`: `start(config: StartConfigDto) -> Result<()>`, `stop() -> Result<()>`, `is_running() -> Result<bool>`, `refresh_now() -> Result<()>`, `on_background(now_ms: u64) -> Result<()>`, `on_foreground(now_ms: u64, lock_enabled: bool) -> Result<SessionLockStateDto>`, `session_unlocked() -> Result<()>`.
- Produces: `runtime::sync_loop::SyncLoop<S, K, C>` with `new(orchestrator: SyncOrchestrator<S, K, C>, timer: Arc<dyn Timer>, clock: C, cancel: Arc<Cancel>, emit: Arc<dyn Fn(RefreshReport, SyncState) + MaybeSend + MaybeSync>)` and `async fn run(self)`.
- Produces: `runtime::Cancel` (an `AtomicBool` plus `tokio::sync::Notify`, with `cancel()`, `is_cancelled()`, `async fn sleep_or_cancel(&self, timer: &dyn Timer, ms: u64) -> bool` that returns true when cancelled).
- Produces: `runtime::syncers::AppSyncer<P>` implementing `ChainSyncer` for one chain over `Weak<Inner<P>>`; `lifecycle()` is `Connected` when the wallet slot is `Some`, else `Disconnected`; `sync(timeout_ms)` races `wallet.sync()` against `timer.sleep(timeout_ms)` and returns `Err(Error::Timeout(format!("{} sync exceeded {timeout_ms} ms", chain.as_str())))` on timeout.

- [ ] **Step 1: Write the failing `SyncLoop` tests in `sync_loop.rs`**

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use mooze_core::domain::{AppNetwork, ChainId, ServiceLifecycle, SyncOutcome, Transaction, WalletCredentials};
    use mooze_core::ports::Timer;
    use mooze_core::store::TransactionStore;
    use mooze_core::sync::{ChainSyncer, SyncConfig, SyncOrchestrator};
    use mooze_core::testing::{FixedClock, ManualTimer, MemoryKv, TestExecutor};
    use std::future::Future;
    use std::sync::atomic::{AtomicU32, Ordering};
    use std::sync::{Arc, Mutex};

    /// Syncer that completes at once, or never when `hang` is set.
    #[derive(Clone)]
    struct FakeSyncer { chain: ChainId, calls: Arc<AtomicU32>, hang: Arc<std::sync::atomic::AtomicBool>, timer: Arc<ManualTimer> }
    impl ChainSyncer for FakeSyncer {
        fn chain(&self) -> ChainId { self.chain }
        fn lifecycle(&self) -> ServiceLifecycle { ServiceLifecycle::Connected }
        fn sync(&self, timeout_ms: u64) -> impl Future<Output = mooze_core::Result<SyncOutcome>> + Send {
            let this = self.clone();
            async move {
                this.calls.fetch_add(1, Ordering::SeqCst);
                if this.hang.load(Ordering::SeqCst) {
                    // The real AppSyncer races the wallet against the timer; mimic its timeout.
                    this.timer.sleep(timeout_ms).await;
                    return Err(mooze_core::Error::Timeout("hung".into()));
                }
                Ok(SyncOutcome { chain: this.chain, fetched: 1, changed: 0, duration_ms: 1 })
            }
        }
        fn transactions(&self) -> impl Future<Output = mooze_core::Result<Vec<Transaction>>> + Send { async { Ok(vec![]) } }
        fn connect(&self, _c: &WalletCredentials) -> impl Future<Output = mooze_core::Result<()>> + Send { async { Ok(()) } }
        fn disconnect(&self) -> impl Future<Output = mooze_core::Result<()>> + Send { async { Ok(()) } }
    }

    fn setup(hang_bitcoin: bool) -> (Arc<ManualTimer>, Arc<FixedClock>, Arc<Cancel>, Arc<AtomicU32>, Arc<AtomicU32>, Arc<Mutex<Vec<SyncState>>>, TestExecutor) {
        let timer = Arc::new(ManualTimer::new());
        let clock = Arc::new(FixedClock::new(0));
        let cancel = Arc::new(Cancel::default());
        let (spawner, mut exec) = TestExecutor::new();
        let liquid_calls = Arc::new(AtomicU32::new(0));
        let bitcoin_calls = Arc::new(AtomicU32::new(0));
        let hang = Arc::new(std::sync::atomic::AtomicBool::new(hang_bitcoin));
        let syncers = vec![
            FakeSyncer { chain: ChainId::Liquid, calls: liquid_calls.clone(), hang: Arc::default(), timer: timer.clone() },
            FakeSyncer { chain: ChainId::Bitcoin, calls: bitcoin_calls.clone(), hang, timer: timer.clone() },
        ];
        let config = SyncConfig { tick_ms: 60_000, liquid_timeout_ms: 10_000, bitcoin_timeout_ms: 10_000, startup_sync_on_boot: true };
        let orchestrator = SyncOrchestrator::new(syncers, TransactionStore::new(MemoryKv::new()), config, clock.clone());
        let states = Arc::new(Mutex::new(vec![]));
        let s = states.clone();
        let emit = Arc::new(move |_report: RefreshReport, state: SyncState| s.lock().unwrap().push(state));
        let lp = SyncLoop::new(orchestrator, timer.clone(), clock.clone(), cancel.clone(), emit);
        use mooze_core::ports::Spawner;
        spawner.spawn(Box::pin(lp.run()));
        exec.run_until_stalled();
        (timer, clock, cancel, liquid_calls, bitcoin_calls, states, exec)
    }

    #[test]
    fn startup_refresh_then_ticks_every_period() {
        let (timer, clock, cancel, liquid, bitcoin, _states, mut exec) = setup(false);
        assert_eq!((liquid.load(Ordering::SeqCst), bitcoin.load(Ordering::SeqCst)), (1, 1));
        clock.advance(60_000); timer.advance(60_000); exec.run_until_stalled();
        assert_eq!(liquid.load(Ordering::SeqCst), 2);
        cancel.cancel(); exec.run_until_stalled();
        clock.advance(60_000); timer.advance(60_000); exec.run_until_stalled();
        assert_eq!(liquid.load(Ordering::SeqCst), 2, "no refresh after cancel");
    }

    #[test]
    fn sync_longer_than_timeout_reports_timeout_and_loop_continues() {
        let (timer, clock, _cancel, liquid, bitcoin, states, mut exec) = setup(true);
        // Startup refresh: liquid done, bitcoin hangs until its 10 s timeout.
        assert_eq!(liquid.load(Ordering::SeqCst), 1);
        clock.advance(10_000); timer.advance(10_000); exec.run_until_stalled();
        let last = states.lock().unwrap().last().cloned().unwrap();
        assert!(last.first_synced_chains.contains(&ChainId::Liquid));
        assert!(!last.first_synced_chains.contains(&ChainId::Bitcoin));
        clock.advance(50_000); timer.advance(50_000); exec.run_until_stalled();
        assert_eq!(bitcoin.load(Ordering::SeqCst), 2, "next tick still runs");
    }
}
```

- [ ] **Step 2: Write the failing `App` runtime tests in `runtime/mod.rs`**

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::open_test_app_with_executor;
    use mooze_core::testing::block_on;

    fn config() -> StartConfigDto {
        StartConfigDto { sync_tick_ms: None, sync_timeout_ms: None, startup_sync: false, peg_wallet_id: None }
    }

    #[test]
    fn start_twice_is_noop() {
        let (app, _plat, mut exec) = open_test_app_with_executor();
        block_on(app.start(config())).unwrap();
        block_on(app.start(config())).unwrap();
        exec.run_until_stalled();
        assert!(block_on(app.is_running()).unwrap());
        block_on(app.stop()).unwrap();
        exec.run_until_stalled();
        assert!(!block_on(app.is_running()).unwrap());
    }

    #[test]
    fn stop_without_start_is_noop() {
        let (app, _plat, _exec) = open_test_app_with_executor();
        block_on(app.stop()).unwrap();
        assert!(!block_on(app.is_running()).unwrap());
    }

    #[test]
    fn dropping_app_ends_loops() {
        let (app, plat, mut exec) = open_test_app_with_executor();
        block_on(app.start(config())).unwrap();
        exec.run_until_stalled();
        assert!(plat.timer.pending() >= 1, "sync loop sleeps on the timer");
        drop(app);
        plat.timer.advance(60_000);
        exec.run_until_stalled();
        plat.timer.advance(60_000);
        exec.run_until_stalled();
        assert_eq!(plat.timer.pending(), 0, "no loop re-armed after the app was dropped");
    }

    #[test]
    fn foreground_after_long_background_locks() {
        let (app, plat, _exec) = open_test_app_with_executor();
        // Default timeout is Immediate (0 ms): any real backgrounding locks.
        block_on(app.on_background(1_000)).unwrap();
        assert_eq!(block_on(app.on_foreground(1_001, true)).unwrap(), SessionLockStateDto::Locked);
        block_on(app.session_unlocked()).unwrap();
        block_on(plat.kv.put(mooze_core::auth::SessionLockTimeout::PREFS_KEY, b"minutes5".to_vec())).unwrap();
        block_on(app.on_background(2_000)).unwrap();
        assert_eq!(block_on(app.on_foreground(2_500, true)).unwrap(), SessionLockStateDto::Unlocked);
        block_on(app.on_background(3_000)).unwrap();
        assert_eq!(block_on(app.on_foreground(3_000 + 300_001, true)).unwrap(), SessionLockStateDto::Locked);
    }
}
```

`mooze_core::ports::KvStore` must be in scope for `plat.kv.put`.

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd crates/mooze-app && cargo test runtime`
Expected: compile errors.

- [ ] **Step 4: Write `runtime/sync_loop.rs`**

```rust
//! Periodic refresh loop around `SyncOrchestrator`. Generic, so tests run
//! it with fake syncers and a manual timer.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use futures::future::{select, Either};
use futures::pin_mut;
use mooze_core::ports::{Clock, KvStore, Timer};
use mooze_core::sync::{ChainSyncer, RefreshReport, SyncOrchestrator, SyncState};
use mooze_core::{MaybeSend, MaybeSync};
use tokio::sync::Notify;

/// Cancellation flag shared by the loops of one `App`.
#[derive(Default)]
pub struct Cancel {
    flag: AtomicBool,
    wake: Notify,
}

impl Cancel {
    pub fn cancel(&self) {
        self.flag.store(true, Ordering::SeqCst);
        self.wake.notify_waiters();
        self.wake.notify_one();
    }

    pub fn is_cancelled(&self) -> bool {
        self.flag.load(Ordering::SeqCst)
    }

    /// Sleeps `ms`, or less when cancelled. True when cancelled.
    pub async fn sleep_or_cancel(&self, timer: &dyn Timer, ms: u64) -> bool {
        if self.is_cancelled() {
            return true;
        }
        let sleep = timer.sleep(ms);
        let woken = self.wake.notified();
        pin_mut!(sleep, woken);
        let _ = select(sleep, woken).await;
        self.is_cancelled()
    }
}

pub type EmitRefresh = Arc<dyn Fn(RefreshReport, SyncState) + MaybeSend + MaybeSync>;

pub struct SyncLoop<S: ChainSyncer, K: KvStore, C: Clock> {
    orchestrator: SyncOrchestrator<S, K, C>,
    timer: Arc<dyn Timer>,
    clock: C,
    cancel: Arc<Cancel>,
    emit: EmitRefresh,
    /// Set by `refresh_now`; the loop refreshes at its next wake.
    refresh_requested: Arc<AtomicBool>,
}

impl<S: ChainSyncer, K: KvStore, C: Clock> SyncLoop<S, K, C> {
    pub fn new(orchestrator: SyncOrchestrator<S, K, C>, timer: Arc<dyn Timer>, clock: C, cancel: Arc<Cancel>, emit: EmitRefresh) -> Self {
        Self { orchestrator, timer, clock, cancel, emit, refresh_requested: Arc::default() }
    }

    /// Handle that asks the loop for an extra light refresh.
    pub fn refresh_handle(&self) -> Arc<AtomicBool> {
        self.refresh_requested.clone()
    }

    pub async fn run(mut self) {
        if let Some(report) = self.orchestrator.start().await {
            (self.emit)(report, self.orchestrator.state().clone());
        }
        while !self.cancel.is_cancelled() {
            let now = self.clock.now_ms();
            let wait = self.orchestrator.next_tick_at_ms().map(|t| t.saturating_sub(now)).unwrap_or(60_000);
            if self.cancel.sleep_or_cancel(self.timer.as_ref(), wait).await {
                break;
            }
            if self.refresh_requested.swap(false, Ordering::SeqCst) {
                let report = self.orchestrator.refresh(mooze_core::sync::SyncStrategy::Light).await;
                (self.emit)(report, self.orchestrator.state().clone());
            }
            if let Some(report) = self.orchestrator.tick().await {
                (self.emit)(report, self.orchestrator.state().clone());
            }
        }
    }
}
```

`refresh_now` wakes the loop by calling `cancel.wake.notify_one()`; expose `pub fn poke(&self)` on `Cancel` that only notifies without setting the flag, and use it from `App::refresh_now`.

- [ ] **Step 5: Write `runtime/syncers.rs`**

```rust
//! `ChainSyncer` over the App wallets, one per chain.

use std::future::Future;
use std::sync::{Arc, Weak};

use futures::future::{select, Either};
use futures::pin_mut;
use mooze_core::domain::{ChainId, ServiceLifecycle, SyncOutcome, Transaction, WalletCredentials};
use mooze_core::ports::Timer;
use mooze_core::sync::ChainSyncer;
use mooze_core::{Error, MaybeSend, Result};

use crate::app::Inner;
use crate::Platform;

pub struct AppSyncer<P: Platform> {
    pub(crate) inner: Weak<Inner<P>>,
    pub(crate) chain: ChainId,
    pub(crate) timer: Arc<dyn Timer>,
}

impl<P: Platform> AppSyncer<P> {
    fn inner(&self) -> Result<Arc<Inner<P>>> {
        self.inner.upgrade().ok_or_else(|| Error::InvalidState("core closed".into()))
    }
}

impl<P: Platform> ChainSyncer for AppSyncer<P> {
    fn chain(&self) -> ChainId { self.chain }

    fn lifecycle(&self) -> ServiceLifecycle {
        let Some(inner) = self.inner.upgrade() else { return ServiceLifecycle::Disconnected };
        let connected = match self.chain {
            ChainId::Bitcoin => inner.bitcoin.try_lock().map(|g| g.is_some()).unwrap_or(true),
            _ => inner.liquid.try_lock().map(|g| g.is_some()).unwrap_or(true),
        };
        if connected { ServiceLifecycle::Connected } else { ServiceLifecycle::Disconnected }
    }

    fn sync(&self, timeout_ms: u64) -> impl Future<Output = Result<SyncOutcome>> + MaybeSend {
        async move {
            let inner = self.inner()?;
            let timeout = self.timer.sleep(timeout_ms);
            let work = async {
                match self.chain {
                    ChainId::Bitcoin => {
                        let mut g = inner.bitcoin.lock().await;
                        g.as_mut().ok_or_else(|| Error::InvalidState("bitcoin wallet not connected".into()))?.sync().await
                    }
                    _ => {
                        let mut g = inner.liquid.lock().await;
                        g.as_mut().ok_or_else(|| Error::InvalidState("liquid wallet not connected".into()))?.sync().await
                    }
                }
            };
            pin_mut!(timeout, work);
            match select(work, timeout).await {
                Either::Left((r, _)) => r,
                Either::Right(_) => Err(Error::Timeout(format!("{} sync exceeded {timeout_ms} ms", self.chain.as_str()))),
            }
        }
    }

    fn transactions(&self) -> impl Future<Output = Result<Vec<Transaction>>> + MaybeSend {
        async move {
            let inner = self.inner()?;
            Ok(match self.chain {
                ChainId::Bitcoin => inner.bitcoin.lock().await.as_ref().map(|w| w.list_transactions().to_vec()).unwrap_or_default(),
                _ => inner.liquid.lock().await.as_ref().map(|w| w.list_transactions().to_vec()).unwrap_or_default(),
            })
        }
    }

    fn connect(&self, _c: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend {
        // Hosts connect through `App::bitcoin_connect` and `liquid_connect`.
        async { Ok(()) }
    }

    fn disconnect(&self) -> impl Future<Output = Result<()>> + MaybeSend {
        async { Ok(()) }
    }
}
```

A locked wallet (sync in progress) counts as connected in `lifecycle`, so a tick during a long sync waits on the mutex instead of skipping the chain. `list_transactions()` returns a slice of `Transaction`; if it returns `&[Transaction]`, `.to_vec()` applies; if it returns `Vec`, drop `.to_vec()`.

- [ ] **Step 6: Write `runtime/mod.rs`**

```rust
//! Host-driven lifecycle: start and stop the loops, background and foreground.

pub mod sync_loop;
pub mod syncers;

use std::sync::atomic::AtomicBool;
use std::sync::{Arc, Mutex as StdMutex};

use mooze_core::auth::{SessionLockController, SessionLockState, SessionLockTimeout};
use mooze_core::domain::ChainId;
use mooze_core::pix::rules::DEPOSIT_POLL_INTERVAL_MS;
use mooze_core::ports::{Clock, KvStore};
use mooze_core::store::TransactionStore;
use mooze_core::sync::{RefreshReport, SyncConfig, SyncOrchestrator, SyncPhase, SyncState};

use self::sync_loop::{Cancel, SyncLoop};
use self::syncers::AppSyncer;
use crate::app::{App, Inner};
use crate::dto::*;
use crate::events::AppEvent;
use crate::{Platform, Result};

/// Mutable runtime state inside `Inner`.
#[derive(Default)]
pub(crate) struct RuntimeState {
    cancel: StdMutex<Option<Arc<Cancel>>>,
    refresh: StdMutex<Option<Arc<AtomicBool>>>,
    lock: StdMutex<SessionLockController>,
}

fn sync_state_dto(s: &SyncState) -> SyncStateDto {
    SyncStateDto {
        phase: match s.phase {
            SyncPhase::Idle => SyncPhaseDto::Idle,
            SyncPhase::Running => SyncPhaseDto::Running,
            SyncPhase::Cooling => SyncPhaseDto::Cooling,
            SyncPhase::Stopped => SyncPhaseDto::Stopped,
        },
        last_error: s.last_error.as_ref().map(|e| e.to_string()),
        last_success_at_ms: s.last_success_at_ms,
        last_duration_ms: s.last_duration_ms,
        first_synced_chains: s.first_synced_chains.iter().map(|c| (*c).into()).collect(),
    }
}

impl<P: Platform> App<P> {
    /// Starts the sync, PIX poll and peg loops. No-op while running.
    pub async fn start(&self, config: StartConfigDto) -> Result<()> {
        let inner = self.inner.clone();
        let mut slot = inner.runtime.cancel.lock().unwrap_or_else(|e| e.into_inner());
        if slot.as_ref().is_some_and(|c| !c.is_cancelled()) {
            return Ok(());
        }
        let cancel = Arc::new(Cancel::default());
        *slot = Some(cancel.clone());
        drop(slot);

        let mut sync_config = SyncConfig::default();
        if let Some(t) = config.sync_tick_ms { sync_config.tick_ms = t; }
        if let Some(t) = config.sync_timeout_ms { sync_config.liquid_timeout_ms = t; sync_config.bitcoin_timeout_ms = t; }
        sync_config.startup_sync_on_boot = config.startup_sync;

        let timer = inner.platform.timer();
        let weak = Arc::downgrade(&inner);
        let syncers = vec![
            AppSyncer { inner: weak.clone(), chain: ChainId::Liquid, timer: timer.clone() },
            AppSyncer { inner: weak.clone(), chain: ChainId::Bitcoin, timer: timer.clone() },
        ];
        let orchestrator = SyncOrchestrator::new(syncers, TransactionStore::new(inner.platform.kv()), sync_config, inner.platform.clock());
        let emit_weak = weak.clone();
        let emit = Arc::new(move |report: RefreshReport, state: SyncState| {
            if let Some(inner) = emit_weak.upgrade() {
                if !report.events.is_empty() {
                    inner.subscribers.emit(AppEvent::Transactions(report.events.iter().map(Into::into).collect()));
                }
                inner.subscribers.emit(AppEvent::SyncState(sync_state_dto(&state)));
            }
        });
        let sync_loop = SyncLoop::new(orchestrator, timer.clone(), inner.platform.clock(), cancel.clone(), emit);
        *inner.runtime.refresh.lock().unwrap_or_else(|e| e.into_inner()) = Some(sync_loop.refresh_handle());
        inner.platform.spawner().spawn(Box::pin(sync_loop.run()));

        // PIX poll loop.
        let (pix_weak, pix_cancel, pix_timer) = (weak.clone(), cancel.clone(), timer.clone());
        inner.platform.spawner().spawn(Box::pin(async move {
            loop {
                if pix_cancel.sleep_or_cancel(pix_timer.as_ref(), DEPOSIT_POLL_INTERVAL_MS).await { break; }
                let Some(inner) = pix_weak.upgrade() else { break };
                let app = App { inner };
                if app.pix_active_polls().await.unwrap_or(0) == 0 { continue; }
                if let Ok(events) = app.pix_poll_tick().await {
                    if !events.is_empty() { app.inner.subscribers.emit(AppEvent::PixStatus(events)); }
                }
            }
        }));

        // Peg loop.
        if let Some(wallet_id) = config.peg_wallet_id {
            let (peg_weak, peg_cancel, peg_timer) = (weak, cancel, timer);
            inner.platform.spawner().spawn(Box::pin(async move {
                loop {
                    let Some(inner) = peg_weak.upgrade() else { break };
                    let app = App { inner };
                    let now = app.inner.platform.clock().now_ms();
                    let next = app.inner.sideswap.pegs.lock().await.next_wakeup_ms();
                    let wait = next.map(|t| t.saturating_sub(now)).unwrap_or(60_000);
                    drop(app);
                    if peg_cancel.sleep_or_cancel(peg_timer.as_ref(), wait.max(1_000)).await { break; }
                    let Some(inner) = peg_weak.upgrade() else { break };
                    let app = App { inner };
                    if let Ok(refresh) = app.peg_refresh_due(wallet_id.clone()).await {
                        if !refresh.changed.is_empty() || !refresh.finished.is_empty() {
                            app.inner.subscribers.emit(AppEvent::PegProgress(refresh));
                        }
                    }
                }
            }));
        }
        Ok(())
    }

    /// Stops every loop. No-op when not running.
    pub async fn stop(&self) -> Result<()> {
        if let Some(c) = self.inner.runtime.cancel.lock().unwrap_or_else(|e| e.into_inner()).take() {
            c.cancel();
        }
        *self.inner.runtime.refresh.lock().unwrap_or_else(|e| e.into_inner()) = None;
        Ok(())
    }

    pub async fn is_running(&self) -> Result<bool> {
        Ok(self.inner.runtime.cancel.lock().unwrap_or_else(|e| e.into_inner()).as_ref().is_some_and(|c| !c.is_cancelled()))
    }

    /// Asks the sync loop for one light refresh now.
    pub async fn refresh_now(&self) -> Result<()> {
        if let Some(flag) = self.inner.runtime.refresh.lock().unwrap_or_else(|e| e.into_inner()).as_ref() {
            flag.store(true, std::sync::atomic::Ordering::SeqCst);
        }
        if let Some(c) = self.inner.runtime.cancel.lock().unwrap_or_else(|e| e.into_inner()).as_ref() {
            c.poke();
        }
        Ok(())
    }

    /// The host left the foreground. Starts the lock clock.
    pub async fn on_background(&self, now_ms: u64) -> Result<()> {
        self.inner.runtime.lock.lock().unwrap_or_else(|e| e.into_inner()).on_backgrounded(now_ms, true, false);
        Ok(())
    }

    /// The host returned to the foreground. Decides the lock and asks for a refresh.
    pub async fn on_foreground(&self, now_ms: u64, lock_enabled: bool) -> Result<SessionLockStateDto> {
        let stored = self.inner.platform.kv().get(SessionLockTimeout::PREFS_KEY).await?;
        let timeout = SessionLockTimeout::from_storage(stored.as_deref().and_then(|b| std::str::from_utf8(b).ok()));
        let state = self.inner.runtime.lock.lock().unwrap_or_else(|e| e.into_inner()).on_resumed(now_ms, lock_enabled, false, timeout);
        let dto = match state { SessionLockState::Locked => SessionLockStateDto::Locked, SessionLockState::Unlocked => SessionLockStateDto::Unlocked };
        self.inner.subscribers.emit(AppEvent::SessionLock(dto));
        self.refresh_now().await?;
        Ok(dto)
    }

    /// The host verified the PIN or biometric.
    pub async fn session_unlocked(&self) -> Result<()> {
        self.inner.runtime.lock.lock().unwrap_or_else(|e| e.into_inner()).unlock();
        self.inner.subscribers.emit(AppEvent::SessionLock(SessionLockStateDto::Unlocked));
        Ok(())
    }
}
```

`App { inner }` construction requires `App`'s field to be `pub(crate)`. `on_background` passes `lock_enabled = true` and `auth_prompt_active = false`: the host tells `on_foreground` whether the lock is enabled, which is when the decision is made. `merchant_mode` is `false` on these hosts.

Add `pub(crate) runtime: RuntimeState` to `Inner<P>`, `pub mod runtime;` to `lib.rs`.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `cd crates/mooze-app && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo clippy --all-targets -- -D warnings`
Expected: pass. `dropping_app_ends_loops` relies on loops holding only `Weak<Inner>`: check no closure captures `Arc<Inner>` across an await.

- [ ] **Step 8: Commit**

```bash
git add crates/mooze-app
git commit -m "Add Runtime: sync, PIX and peg loops, background and foreground"
```

---

### Task 9: Method table, TypeScript generation, freshness check

**Files:**
- Create: `crates/mooze-app/src/methods.rs`, `crates/mooze-app/src/bin/codegen.rs`, `crates/mooze-app/generated/types.ts`, `crates/mooze-app/generated/client.ts`
- Create: `crates/mooze-app/tests/generated_up_to_date.rs`
- Modify: `crates/mooze-app/src/lib.rs`

**Interfaces:**
- Produces: `#[macro_export] macro_rules! for_each_app_method { ($callback:ident) => { $callback! { <entries> } } }` with entries of the form `name(param: Type, ...) -> ReturnType;` for every public `async fn` on `App<P>` except `subscribe` and `unsubscribe` (they take a sink, which hosts bind by hand).
- Produces: `mooze_app::methods::{MethodSpec, METHODS}` under `feature = "codegen"`:

```rust
pub struct MethodSpec {
    pub name: &'static str,
    pub params: &'static [(&'static str, fn() -> String)],
    pub returns: fn() -> String,
}
pub static METHODS: &[MethodSpec] = &[ /* one per entry */ ];
```
`fn() -> String` points at `<T as ts_rs::TS>::name` (or `ts_rs::TS::inline` for primitives: `ts_rs` implements `TS` for `String`, `u32`, `u64`, `i64`, `f64`, `bool`, `Option<T>`, `Vec<T>`, `()`).

- [ ] **Step 1: Write the failing freshness test `crates/mooze-app/tests/generated_up_to_date.rs`**

```rust
//! Fails when `generated/` differs from what `cargo run --features codegen --bin codegen` writes.
#![cfg(feature = "codegen")]

use std::path::PathBuf;
use std::process::Command;

#[test]
fn generated_files_are_up_to_date() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let out = tempfile_dir();
    let status = Command::new(env!("CARGO_BIN_EXE_codegen")).arg(&out).status().unwrap();
    assert!(status.success());
    for name in ["types.ts", "client.ts"] {
        let want = std::fs::read_to_string(out.join(name)).unwrap();
        let have = std::fs::read_to_string(root.join("generated").join(name)).unwrap();
        assert_eq!(have, want, "{name} is stale: run `cargo run --features codegen --bin codegen`");
    }
}

fn tempfile_dir() -> PathBuf {
    let d = std::env::temp_dir().join(format!("mooze-app-codegen-{}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    d
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd crates/mooze-app && cargo test --features codegen --test generated_up_to_date`
Expected: fails, binary `codegen` missing.

- [ ] **Step 3: Write `methods.rs`**

```rust
//! The facade API as data, so hosts generate their bindings from one list.

/// Calls `$callback!` with every facade method.
///
/// Entry syntax: `name(param: Type, ...) -> ReturnType;` where every method
/// is `async` and returns `Result<ReturnType, AppError>`.
#[macro_export]
macro_rules! for_each_app_method {
    ($callback:ident) => {
        $callback! {
            is_migrated() -> bool;
            import_flutter_snapshot(snapshot_json: String) -> MigrationReportDto;
            secure_get(key: String) -> Option<String>;
            secure_put(key: String, value: String) -> ();
            secure_delete(key: String) -> ();
            secure_list_keys(prefix: String) -> Vec<String>;
            api_set_base_url(base_url: String) -> ();
            auth_ensure_session() -> AuthEnsureDto;
            auth_access_token() -> String;
            auth_force_refresh() -> String;
            auth_refresh_current() -> bool;
            auth_invalidate() -> ();
            auth_reset() -> ();
            auth_set_device_safe(safe: bool) -> ();
            auth_device_id(serial: Option<String>, platform_id: Option<String>) -> String;
            api_set_metrics(metrics: Option<DeviceMetricsDto>) -> ();
            api_request(method: HttpMethodDto, path: String, json_body: Option<String>) -> ApiResponseDto;
            bitcoin_connect(mnemonic: String) -> ();
            bitcoin_disconnect() -> ();
            bitcoin_sync() -> SyncOutcomeDto;
            bitcoin_balance() -> BalanceDto;
            bitcoin_transactions() -> Vec<TransactionDto>;
            bitcoin_take_events() -> Vec<TransactionEventDto>;
            bitcoin_receive_address(label: Option<String>) -> ReceiveAddressDto;
            bitcoin_estimate_fee(request: SendRequestDto) -> FeeEstimateDto;
            bitcoin_send(request: SendRequestDto) -> BroadcastResultDto;
            bitcoin_block_height() -> u32;
            bitcoin_derived_addresses(keychain: KeychainDto, start: u32, count: u32) -> Vec<DerivedAddressDto>;
            bitcoin_unspent_outputs() -> Vec<WalletUtxoDto>;
            bitcoin_is_mine(address: String) -> Option<AddressOwnershipDto>;
            bitcoin_next_unused_address() -> NextUnusedAddressDto;
            bitcoin_register_external_broadcast(transaction: TransactionDto) -> ();
            liquid_connect(mnemonic: String) -> ();
            liquid_disconnect() -> ();
            liquid_sync() -> SyncOutcomeDto;
            liquid_balance() -> BalanceDto;
            liquid_refresh_balance() -> BalanceDto;
            liquid_apply_balance_delta(asset_ids: Vec<String>, deltas: Vec<i64>) -> BalanceDto;
            liquid_transactions() -> Vec<TransactionDto>;
            liquid_take_events() -> Vec<TransactionEventDto>;
            liquid_receive_address(asset_id: Option<String>, label: Option<String>) -> ReceiveAddressDto;
            liquid_derived_addresses(keychain: KeychainDto, start: u32, count: u32) -> Vec<DerivedAddressDto>;
            liquid_unspent_outputs() -> Vec<WalletUtxoDto>;
            liquid_is_mine(address: String, scan_limit: u32) -> Option<AddressOwnershipDto>;
            liquid_next_unused_address() -> NextUnusedAddressDto;
            liquid_utxos() -> Vec<LiquidUtxoDto>;
            liquid_estimate_fee(request: SendRequestDto) -> FeeEstimateDto;
            liquid_build_lbtc_send(destination: String, amount_sat: u64, fee_rate_sat_per_vb: Option<f64>, drain: bool) -> LiquidSendDraftDto;
            liquid_send(request: SendRequestDto) -> BroadcastResultDto;
            liquid_sign_and_broadcast(pset: String) -> String;
            liquid_sign_swap_pset(pset: String) -> String;
            pix_create_deposit(amount_in_cents: u64, asset_id: String, tax_id_number: Option<String>, address: Option<String>) -> PixDepositDto;
            pix_poll_tick() -> Vec<PixStatusEventDto>;
            pix_active_polls() -> u32;
            pix_cancel_polls() -> ();
            pix_get_deposit(deposit_id: String) -> Option<PixDepositDto>;
            pix_list_deposits(limit: Option<u32>, offset: Option<u32>) -> Vec<PixDepositDto>;
            pix_update_deposit_details(deposit_ids: Vec<String>) -> Vec<PixDepositDto>;
            pix_history(limit: Option<u32>, offset: Option<u32>) -> Vec<PixDepositDto>;
            pix_clear_deposits() -> ();
            favorite_payers_list() -> Vec<FavoritePayerDto>;
            favorite_payer_save(id: Option<u64>, label: String, cpf: String) -> Option<FavoritePayerSaveErrorDto>;
            favorite_payer_delete(id: u64) -> ();
            favorite_payer_cpf_exists(cpf: String, excluding_id: Option<u64>) -> bool;
            favorite_payers_clear() -> ();
            pix_flag_is_set(flag: PixFlagDto) -> bool;
            pix_flag_set(flag: PixFlagDto) -> ();
            pix_flag_reset(flag: PixFlagDto) -> ();
            sideswap_connect(api_key: String, url: Option<String>) -> ();
            sideswap_disconnect() -> ();
            sideswap_is_connected() -> bool;
            sideswap_start_events() -> ();
            sideswap_stop_events() -> ();
            sideswap_events_running() -> bool;
            sideswap_markets() -> Vec<SideswapMarketDto>;
            sideswap_assets() -> Vec<SideswapAssetDto>;
            sideswap_start_quote(send_asset_id: String, receive_asset_id: String, amount: u64) -> StartQuoteDto;
            sideswap_stop_quote() -> ();
            sideswap_execute_swap(quote_id: u64) -> String;
            peg_limits() -> PegServerLimitsDto;
            peg_quote(direction: PegDirectionDto, amount_sat: u64, fee_rate_sat_per_vbyte: Option<u32>, drain: bool) -> PegQuoteDto;
            peg_execute(wallet_id: String, direction: PegDirectionDto, amount_sat: u64, fee_rate_sat_per_vbyte: Option<u32>, drain: bool, external_payout_address: Option<String>) -> PegExecutionDto;
            peg_status(direction: PegDirectionDto, order_id: String) -> PegProgressDto;
            peg_list(wallet_id: String) -> Vec<PegRecordDto>;
            peg_restore(wallet_id: String) -> Vec<TrackedPegDto>;
            peg_tracked() -> Vec<TrackedPegDto>;
            peg_untrack(order_id: String) -> ();
            peg_refresh_due(wallet_id: String) -> PegRefreshDto;
            start(config: StartConfigDto) -> ();
            stop() -> ();
            is_running() -> bool;
            refresh_now() -> ();
            on_background(now_ms: u64) -> ();
            on_foreground(now_ms: u64, lock_enabled: bool) -> SessionLockStateDto;
            session_unlocked() -> ();
        }
    };
}

/// Compile-time check: every listed method exists on `App` with these types.
macro_rules! assert_methods_exist {
    ($($name:ident($($p:ident : $t:ty),*) -> $r:ty;)*) => {
        #[allow(dead_code)]
        fn _assert_methods_exist<P: $crate::Platform>(app: &$crate::App<P>) {
            $( let _ = |$($p: $t),*| async move { let _r: $crate::Result<$r> = app.$name($($p),*).await; }; )*
        }
    };
}
for_each_app_method!(assert_methods_exist);

#[cfg(feature = "codegen")]
pub use table::{MethodSpec, METHODS};

#[cfg(feature = "codegen")]
mod table {
    use crate::dto::*;
    use ts_rs::TS;

    pub struct MethodSpec {
        pub name: &'static str,
        pub params: &'static [(&'static str, fn() -> String)],
        pub returns: fn() -> String,
    }

    fn ts_name<T: TS>() -> String {
        T::name()
    }

    macro_rules! method_table {
        ($($name:ident($($p:ident : $t:ty),*) -> $r:ty;)*) => {
            pub static METHODS: &[MethodSpec] = &[
                $( MethodSpec { name: stringify!($name), params: &[$((stringify!($p), ts_name::<$t> as fn() -> String)),*], returns: ts_name::<$r> as fn() -> String }, )*
            ];
        };
    }
    for_each_app_method!(method_table);
}
```

Add `pub mod methods;` to `lib.rs`. Every `*Dto` and `MigrationReportDto` referenced must derive `TS` under `codegen` (Task 3 did that for the moved DTOs; `MigrationReportDto`, `TableCountDto`, `SkippedRowDto` came with `wallet.rs`). Types without `TS` fail to compile under `--features codegen`; add the derive where missing.

For `ts_name::<()>`: `ts_rs` implements `TS` for `()` as `null`. Generic `fn ts_name<T: TS>()` cast to `fn() -> String` works because the monomorphized item is a plain function.

- [ ] **Step 4: Write `src/bin/codegen.rs`**

```rust
//! Writes `types.ts` (every DTO) and `client.ts` (the `CoreClient` interface).
//! Usage: `cargo run --features codegen --bin codegen [out_dir]`.
//! Default `out_dir`: `crates/mooze-app/generated`.

use std::path::PathBuf;

use mooze_app::methods::METHODS;
use ts_rs::TS;

fn camel(s: &str) -> String {
    let mut out = String::new();
    let mut up = false;
    for c in s.chars() {
        if c == '_' { up = true; continue; }
        if up { out.extend(c.to_uppercase()); up = false; } else { out.push(c); }
    }
    out
}

fn main() {
    let out = std::env::args().nth(1).map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("generated"));
    std::fs::create_dir_all(&out).expect("create out dir");

    // types.ts: one file, every exported type, sorted by name.
    let mut decls: Vec<(String, String)> = Vec::new();
    macro_rules! export {
        ($($t:ty),* $(,)?) => { $( decls.push((<$t as TS>::name(), <$t as TS>::decl())); )* };
    }
    use mooze_app::dto::*;
    use mooze_app::events::AppEvent;
    use mooze_app::{AppError, ErrorCode};
    export!(
        AppError, ErrorCode, AppEvent,
        NetworkDto, BackendDto, AppConfig,
        ChainDto, DirectionDto, StatusDto, SourceDto, TransactionDto, TransactionEventKindDto, TransactionEventDto,
        AssetBalanceDto, BalanceDto, SyncOutcomeDto, FeePriorityDto, SendRequestDto, FeeEstimateDto, ReceiveAddressDto,
        BroadcastResultDto, LiquidSendDraftDto, LiquidUtxoDto, KeychainDto, DerivedAddressDto, WalletUtxoDto,
        AddressOwnershipDto, NextUnusedAddressDto, TableCountDto, SkippedRowDto, MigrationReportDto, AuthEnsureKind,
        AuthEnsureDto, HttpMethodDto, ApiResponseDto, DeviceMetricsDto,
        SyncPhaseDto, SyncStateDto, SessionLockStateDto, StartConfigDto,
        DepositStatusDto, PixDepositDto, PixStatusEventDto, PixFeeDto, DepositLimitsDto, DepositValidationErrorDto,
        DepositValidationDto, FavoritePayerDto, FavoritePayerSaveErrorDto, PixFlagDto, CpfValidationErrorDto,
        QuoteStatusDto, QuoteDto, SideSwapEventKind, SideSwapEventDto, StartQuoteDto, SideswapMarketDto, SideswapAssetDto,
        PegDirectionDto, PegPhaseDto, PegServerLimitsDto, PegQuoteDto, PegOrderDto, PegExecutionDto, TrackedPegDto,
        PegRefreshDto, PegProgressDto, PegRecordDto, PegAmountIssueDto, PegAmountValidationDto,
    );
    decls.sort();
    decls.dedup();
    let mut types = String::from("// Generated by `cargo run --features codegen --bin codegen`. Do not edit.\n\n");
    for (_, d) in &decls {
        types.push_str("export ");
        types.push_str(d);
        types.push_str("\n\n");
    }
    std::fs::write(out.join("types.ts"), types).expect("write types.ts");

    // client.ts
    let mut client = String::from("// Generated by `cargo run --features codegen --bin codegen`. Do not edit.\nimport type * as T from \"./types\";\n\n");
    client.push_str("export interface CoreClient {\n");
    for m in METHODS {
        let params: Vec<String> = m.params.iter().map(|(n, t)| format!("{}: {}", camel(n), qualify(&t()))).collect();
        let ret = qualify(&(m.returns)());
        client.push_str(&format!("  {}({}): Promise<{}>;\n", camel(m.name), params.join(", "), ret));
    }
    client.push_str("}\n\nexport const METHOD_NAMES = [\n");
    for m in METHODS {
        client.push_str(&format!("  \"{}\",\n", m.name));
    }
    client.push_str("] as const;\n");
    std::fs::write(out.join("client.ts"), client).expect("write client.ts");
}

/// Prefixes DTO names with `T.`; leaves TypeScript primitives alone.
fn qualify(ts: &str) -> String {
    let primitives = ["string", "number", "bigint", "boolean", "null", "undefined"];
    let mut out = String::new();
    let mut word = String::new();
    let flush = |word: &mut String, out: &mut String| {
        if word.is_empty() { return; }
        let w = word.as_str();
        if primitives.contains(&w) || w == "Array" { out.push_str(w); } else { out.push_str("T."); out.push_str(w); }
        word.clear();
    };
    for c in ts.chars() {
        if c.is_alphanumeric() || c == '_' { word.push(c); } else { flush(&mut word, &mut out); out.push(c); }
    }
    flush(&mut word, &mut out);
    out
}
```

The `export!` list names every `pub` type of `dto/*.rs`, `AppError`, `ErrorCode` and `AppEvent`. A type added later and missing here is a stale `types.ts` the moment a method references it, which the `client.ts` import then fails to type-check in the frontend phase. Nothing enforces it in phase 1 beyond review.

ts-rs `decl()` output for generic containers (`Option<T>`, `Vec<T>`) is inline in the field types, so only named types need exporting.

- [ ] **Step 5: Generate, then run the freshness test**

Run: `cd crates/mooze-app && cargo run --features codegen --bin codegen && cargo test --features codegen && cargo test && cargo build --target wasm32-unknown-unknown --features http-reqwest && cargo clippy --all-targets --features codegen -- -D warnings`
Expected: `generated/types.ts` and `generated/client.ts` exist; `generated_files_are_up_to_date` passes; wasm build still passes without `codegen`.

Open `generated/client.ts` and confirm one line reads `bitcoinDerivedAddresses(keychain: T.KeychainDto, start: number, count: number): Promise<Array<T.DerivedAddressDto>>;`. Confirm `types.ts` has `export type ErrorCode = "service" | "storage" | ...`.

- [ ] **Step 6: Commit**

```bash
git add crates/mooze-app
git commit -m "Add facade method table and TypeScript generation"
```

---

### Task 10: Thin bridge over `App<NativePlatform>`

**Files:**
- Modify: `packages/mooze_core_bridge/rust/src/ports.rs` (add `TokioTaskSpawner`, `TokioTimer`, `NativePlatform`)
- Modify: `packages/mooze_core_bridge/rust/src/secure_store.rs` (add `LateSecureStore`)
- Rewrite: `packages/mooze_core_bridge/rust/src/api/core.rs`, `api/pix.rs`, `api/swap.rs`
- Delete: `packages/mooze_core_bridge/rust/src/glue.rs`
- Modify: `packages/mooze_core_bridge/rust/src/lib.rs`, `rust/Cargo.toml`, `flutter_rust_bridge.yaml`
- Regenerate: `rust/src/frb_generated.rs`, `lib/src/rust/**`
- Test: bridge Rust tests, Dart smoke test, `apps/mobile` analyze and test

**Interfaces:**
- Consumes: everything `mooze_app` exports.
- Produces: the unchanged Dart API.

- [ ] **Step 1: Write the failing `LateSecureStore` test in `secure_store.rs`**

```rust
#[test]
fn late_secure_store_errors_until_set_then_works() {
    let late = LateSecureStore::default();
    let err = runtime().block_on(late.get("jwt")).unwrap_err();
    assert!(matches!(&err, Error::InvalidState(m) if m == "secure storage not set; call setSecureStorage first"), "{err}");
    let (store, map) = memory_store();
    late.set(store);
    runtime().block_on(late.put("jwt", b"t".to_vec())).unwrap();
    assert_eq!(map.lock().unwrap().get("jwt").map(String::as_str), Some("t"));
}
```

- [ ] **Step 2: Add `LateSecureStore`**

```rust
/// Secure store slot that Dart fills after `open`.
///
/// Every call before `set` fails with `InvalidState`, the error the Dart
/// code expects from `secureGet` and the auth calls.
#[derive(Clone, Default, Debug)]
pub struct LateSecureStore {
    inner: Arc<std::sync::RwLock<Option<DartSecureStore>>>,
}

impl LateSecureStore {
    pub fn set(&self, store: DartSecureStore) {
        *self.inner.write().unwrap_or_else(|e| e.into_inner()) = Some(store);
    }

    fn current(&self) -> Result<DartSecureStore> {
        self.inner.read().unwrap_or_else(|e| e.into_inner()).clone()
            .ok_or_else(|| Error::InvalidState("secure storage not set; call setSecureStorage first".into()))
    }
}

impl KvStore for LateSecureStore {
    fn get(&self, key: &str) -> impl Future<Output = Result<Option<Vec<u8>>>> + MaybeSend {
        let store = self.current();
        let key = key.to_owned();
        async move { store?.get(&key).await }
    }
    fn put(&self, key: &str, value: Vec<u8>) -> impl Future<Output = Result<()>> + MaybeSend {
        let store = self.current();
        let key = key.to_owned();
        async move { store?.put(&key, value).await }
    }
    fn delete(&self, key: &str) -> impl Future<Output = Result<()>> + MaybeSend {
        let store = self.current();
        let key = key.to_owned();
        async move { store?.delete(&key).await }
    }
    fn list_keys(&self, prefix: &str) -> impl Future<Output = Result<Vec<String>>> + MaybeSend {
        let store = self.current();
        let prefix = prefix.to_owned();
        async move { store?.list_keys(&prefix).await }
    }
}

impl SecureStore for LateSecureStore {}
```

- [ ] **Step 3: Add the native task ports and `NativePlatform` to `ports.rs`**

```rust
use mooze_core::ports::{Spawner, TaskFuture, Timer};
use mooze_app::Platform;

/// [`Spawner`] over the shared tokio runtime.
#[derive(Debug, Clone, Copy, Default)]
pub struct TokioTaskSpawner;

impl Spawner for TokioTaskSpawner {
    fn spawn(&self, task: TaskFuture<'static, ()>) {
        runtime().spawn(task);
    }
}

/// [`Timer`] over tokio time. Needs a tokio context at poll time, which
/// every bridge call has because it runs under `on_runtime`.
#[derive(Debug, Clone, Copy, Default)]
pub struct TokioTimer;

impl Timer for TokioTimer {
    fn sleep(&self, ms: u64) -> TaskFuture<'static, ()> {
        let handle = runtime().handle().clone();
        Box::pin(async move {
            let _guard = handle.enter();
            tokio::time::sleep(std::time::Duration::from_millis(ms)).await;
        })
    }
}

/// Ports of the mobile host.
#[derive(Clone)]
pub struct NativePlatform {
    pub kv: FileKv,
    pub secure: crate::secure_store::LateSecureStore,
}

impl Platform for NativePlatform {
    type Kv = FileKv;
    type Secure = crate::secure_store::LateSecureStore;
    type Http = mooze_core::ports::ReqwestHttpClient;
    type Ws = crate::ws::TungsteniteConnector;
    type Clock = SystemClock;
    fn kv(&self) -> FileKv { self.kv.clone() }
    fn secure(&self) -> Self::Secure { self.secure.clone() }
    fn http(&self) -> Self::Http { mooze_core::ports::ReqwestHttpClient::default() }
    fn ws(&self) -> Self::Ws { crate::ws::TungsteniteConnector }
    fn clock(&self) -> SystemClock { SystemClock }
    fn spawner(&self) -> Arc<dyn Spawner> { Arc::new(TokioTaskSpawner) }
    fn timer(&self) -> Arc<dyn Timer> { Arc::new(TokioTimer) }
    fn blocking(&self) -> Option<Arc<dyn BlockingSpawner>> { Some(Arc::new(TokioSpawner)) }
}
```

`tokio::time::sleep` requires the `time` feature, which the bridge `Cargo.toml` already enables.

- [ ] **Step 4: Rewrite `api/core.rs`**

```rust
//! The core handle Dart holds. Every method delegates to `mooze_app::App`.
//!
//! Calls run on the shared tokio runtime (see [`crate::ports`]) because
//! reqwest and the Electrum spawner need a tokio context.

use std::path::PathBuf;
use std::sync::Arc;

use flutter_rust_bridge::{frb, DartFnFuture};
use mooze_app::dto::AppConfig;
use mooze_app::App;

use super::types::*;
use crate::ports::{install_crypto_provider, on_runtime, FileKv, NativePlatform};
use crate::secure_store::{DartSecureStore, LateSecureStore};

const KV_DIR: &str = "core_kv";

/// Handle to one opened core. Dart keeps one for the app's lifetime.
#[frb(opaque)]
pub struct MoozeCore {
    pub(crate) app: App<NativePlatform>,
    pub(crate) secure: LateSecureStore,
}

/// Runs an `App` future on the runtime and maps the error.
macro_rules! delegate {
    ($self:ident . $method:ident ( $($arg:expr),* )) => {{
        let app = $self.app.clone();
        Ok(on_runtime(async move { app.$method($($arg),*).await.map_err(mooze_core::Error::from_app) }).await?)
    }};
}
```

`mooze_core::Error::from_app` does not exist. Instead, give `on_runtime` a generic error type: change its signature in `ports.rs` to

```rust
pub async fn on_runtime<T, E, F>(fut: F) -> Result<T, CoreError>
where
    T: Send + 'static,
    E: Into<CoreError> + Send + 'static,
    F: Future<Output = Result<T, E>> + Send + 'static,
{
    runtime().spawn(fut).await
        .map_err(|e| CoreError { kind: CoreErrorKind::Other, message: format!("core task failed: {e}") })?
        .map_err(Into::into)
}
```

and write `delegate!` as `Ok(on_runtime(async move { app.$method($($arg),*).await }).await?)`. Both `mooze_core::Error` and `mooze_app::AppError` convert into `CoreError` (Task 3).

Then every method of the old `impl MoozeCore` keeps its exact signature and body `delegate!(self.method(args))`, with these exceptions:

- `open(config: CoreConfig)`: `install_crypto_provider()`; `let kv = FileKv::open(PathBuf::from(&config.data_dir).join(KV_DIR))?;` `let secure = LateSecureStore::default();` build `AppConfig { network: config.network, backend: config.backend, bitcoin_node_url, liquid_node_url, api_base_url: None }`; `let app = on_runtime(App::open(app_config, NativePlatform { kv, secure: secure.clone() })).await?;`.
- `set_secure_storage(read, write, delete, list_keys)`: `self.secure.set(DartSecureStore::new(read, write, delete, list_keys));` then `delegate!(self.auth_reset())` and discard the result (the method returns `()`).
- `bitcoin_disconnect`, `liquid_disconnect`, `auth_reset`, `auth_set_device_safe`, `api_set_metrics`, `api_set_base_url`, `sideswap_disconnect`, `sideswap_stop_quote`, `sideswap_close_events`, `peg_untrack`, `pix_cancel_polls` return `()` in Dart: call `let _: Result<(), CoreError> = delegate!(...)` and return `()`.
- `pix_active_polls() -> u32`, `sideswap_is_connected() -> bool`, `sideswap_events_running() -> bool`, `peg_tracked() -> Vec<TrackedPegDto>` return bare values in Dart: `delegate!(...).unwrap_or_default()` for the bool and vec, `unwrap_or(0)` for the count.
- `liquid_send(request, mnemonic)`, `liquid_sign_and_broadcast(pset, mnemonic)`, `liquid_sign_swap_pset(pset, mnemonic)`: keep the Dart parameter. Rule: if the secure store holds a mnemonic, the facade path is used and `mnemonic` is ignored; if it holds none, the bridge writes `mnemonic` to the secure store under `mnemonic_mainWallet` first, then calls the facade. This keeps every current Dart caller working, because the Dart app always stores the mnemonic in `flutter_secure_storage` before it signs. Implement as a helper `ensure_mnemonic(&self, mnemonic: String) -> Result<(), CoreError>` that calls `self.app.secure_get("mnemonic_mainWallet")` and `secure_put` when `None`.
- `sideswap_events(sink: StreamSink<SideSwapEventDto>)`: subscribe a forwarder, then start the driver:

```rust
struct SinkForwarder(StreamSink<SideSwapEventDto>);
impl mooze_app::events::EventSink for SinkForwarder {
    fn send(&self, e: mooze_app::events::AppEvent) -> bool {
        match e {
            mooze_app::events::AppEvent::SideSwap(s) => self.0.add(s).is_ok(),
            _ => true,
        }
    }
}
```

`MoozeCore` gains `pub(crate) events: std::sync::Mutex<Option<(mooze_app::events::SubscriptionId, StreamSink<SideSwapEventDto>)>>`. `sideswap_events`: take the previous entry; if any, `app.unsubscribe(id)` and `old_sink.add(SideSwapEventDto::closed())`; subscribe the new forwarder, store it, then `delegate!(self.sideswap_start_events())`. `sideswap_close_events`: `delegate!(self.sideswap_stop_events())`; the driver emits `closed` through the forwarder on its way out.

- [ ] **Step 5: Rewrite `api/pix.rs` and `api/swap.rs`**

Each `#[frb(sync)]` free function keeps its name and signature and calls `mooze_app::rules::<same name>(args)`. Each `MoozeCore` method is `delegate!`. `peg_core_error` is gone; `From<AppError> for CoreError` covers it. Delete `glue.rs` and remove `pub(crate) mod glue;` from `lib.rs`. Remove the `anyhow` and `serde_json` dependencies from the bridge `Cargo.toml` if nothing uses them after the rewrite (check with `cargo build`; `serde_json` is still used by tests that build JSON, keep it as a dev-dependency then).

- [ ] **Step 6: Regenerate the bindings**

Edit `packages/mooze_core_bridge/flutter_rust_bridge.yaml`: `rust_input: crate::api,mooze_app::dto`. Then:

```bash
cd packages/mooze_core_bridge && flutter_rust_bridge_codegen generate
```

Expected: `rust/src/frb_generated.rs` and `lib/src/rust/**` regenerate. Then verify the frozen API:

```bash
git diff --stat lib/src/rust/api/
git diff lib/src/rust/api/types.dart lib/src/rust/api/core.dart lib/src/rust/api/pix.dart lib/src/rust/api/swap.dart | grep -E '^[+-]\s*(class|enum|Future|Stream|\w+ get |  \w+\()' | grep -vE '^[+-]\s*//' 
```

Expected: the second command prints nothing. Allowed differences in the full diff: import lines, generated comments, the `rustContentHash`, and the order of declarations. If a class or method line appears in the output, a name or type changed; fix the Rust side until the output is empty. Dart class and enum names come from the Rust type names, so a DTO renamed in `mooze_app::dto` would show here.

If `flutter_rust_bridge_codegen` cannot scan `mooze_app::dto` (error mentions "third-party crate" or an unresolved path), the fallback is mirror declarations: keep `rust_input: crate::api` and add to `api/types.rs` a `#[frb(mirror(TransactionDto))] pub struct _TransactionDto { /* same fields */ }` for every DTO. This is 700 lines of mirrors; try the scan first and report which path worked in the commit message.

- [ ] **Step 7: Run every check**

```bash
cd packages/mooze_core_bridge/rust && cargo build && cargo test && cargo clippy --all-targets -- -D warnings && cargo deny check advisories bans sources
cd .. && flutter pub get && flutter test test/bridge_smoke_test.dart
cd ../../apps/mobile && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test
```

Expected: all pass. The Dart smoke test runs against the rebuilt host library and asserts the same addresses and error kinds as before. The mobile `flutter test` proves the frozen API: no Dart file in `apps/mobile` changes in this task.

- [ ] **Step 8: Commit**

```bash
git add packages/mooze_core_bridge
git commit -m "Make mooze_core_bridge a thin wrapper over mooze-app"
```

---

### Task 11: CI, spec amendment, docs

**Files:**
- Modify: `.github/workflows/mooze-core.yml`
- Modify: `docs/superpowers/specs/2026-10-05-desktop-web-client-design.md`
- Modify: `README.md` (repository layout)

- [ ] **Step 1: Extend the workflow**

In `.github/workflows/mooze-core.yml`:
- Add `"crates/mooze-app/**"` to both `paths` lists.
- Add a job `app` after `build-test`, a copy of `build-test` with `working-directory: crates/mooze-app` and these steps: `cargo build --locked --features electrum,http-reqwest`, `cargo build --locked --target wasm32-unknown-unknown --features http-reqwest`, `cargo test --locked --features electrum,http-reqwest`, `cargo test --locked --features codegen --test generated_up_to_date`, `cargo clippy --locked --all-targets --features electrum,http-reqwest,codegen -- -D warnings`.
- Add a second `cargo-deny-action` step in the `deny` job with `manifest-path: crates/mooze-app/Cargo.toml`.
- In the `bridge` job add `cargo deny check advisories bans sources` after clippy.

- [ ] **Step 2: Amend the spec**

In the spec's "`mooze-app` facade" section replace the sentence `The facade has no tokio dependency.` with `The facade has no tokio runtime dependency. It uses tokio with only the sync feature, which is runtime-free, builds on wasm32, and gives a FIFO-fair mutex that the SideSwap driver relies on.`

In the "Rollout" section, phase 1 line, append: `Done in docs/superpowers/plans/2026-10-05-mooze-app-facade.md. The price refresh loop lands with the prices absorption in phase 3.`

- [ ] **Step 3: Update the README layout**

In `README.md` under "Repository layout" add `- \`crates/mooze-app\`: host-neutral application facade over mooze-core; every client binds it.` after the `mooze-core` line.

- [ ] **Step 4: Verify the workflow file parses**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/mooze-core.yml'))" && echo ok`
Expected: `ok`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/mooze-core.yml docs/superpowers/specs/2026-10-05-desktop-web-client-design.md README.md
git commit -m "Add mooze-app to CI, amend spec on tokio sync, document the crate"
```

---

## Self-review notes

- Spec coverage: facade crate (Tasks 2 to 8), new ports (Task 1), no tokio runtime (Global Constraints, Task 2), API surface rules (Task 2 error, Tasks 4 to 8 signatures), `AppEvent` and `subscribe` (Task 7), `app_api!` as `for_each_app_method!` with host generators deferred to the host crates (Task 9 provides the callback macro; `tauri_commands!` lives in `apps/desktop` in phase 2), ts-rs export and generated `CoreClient` (Task 9), thin frb wrapper with frozen Dart API (Task 10), Runtime with sync, PIX and peg loops, `on_background`, `on_foreground`, timeouts as cancellations (Task 8), CI freshness and deny (Task 11). Not in phase 1 by spec: price refresh loop, boot orchestration adoption by mobile, UniFFI exports.
- The spec names the macro `app_api!`; this plan names it `for_each_app_method!` because the callback pattern is what hosts invoke. Task 11's spec amendment does not rename it in the spec; the executor of phase 2 reads this plan.
- Type consistency: `AppError { code: ErrorCode, message, details }` everywhere; `Result<T>` is `mooze_app::Result`; `App<P>` field `inner: Arc<Inner<P>>` is `pub(crate)`; `Subscribers::emit` returns `usize`; `Cancel::{cancel, is_cancelled, poke, sleep_or_cancel}`.
- Review Focus items 1 to 5 map to the named tests in Tasks 10, 8, 8, 8 and 7.
