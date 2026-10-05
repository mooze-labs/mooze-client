//! Cold-start sequence.
//!
//! Phases: platform, database, credentials, services, session.
//! Failure policy: platform, database and credential errors are fatal;
//! one chain down is a soft degrade; all chains down is fatal; session
//! failure is non-fatal.

use std::future::Future;

use crate::domain::{ChainId, WalletCredentials};
use crate::ports::{Clock, MaybeSend, MaybeSync};
use crate::{Error, Result};

/// Per-service connect timeout.
pub const CONNECT_TIMEOUT_MS: u64 = 45_000;
/// Session authentication timeout.
pub const AUTH_TIMEOUT_MS: u64 = 10_000;
/// Per-service disconnect cap during shutdown.
pub const DISCONNECT_CAP_MS: u64 = 5_000;

/// Boot phase.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum BootPhase {
    #[default]
    Idle,
    InitializingPlatform,
    InitializingDatabase,
    LoadingCredentials,
    ConnectingServices,
    AuthenticatingSession,
    Ready,
    NeedsSetup,
    Error,
}

/// Observable boot state.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct BootState {
    pub phase: BootPhase,
    pub failure: Option<Error>,
    pub started_at_ms: Option<u64>,
    pub completed_at_ms: Option<u64>,
    pub last_phase_duration_ms: Option<u64>,
}

impl BootState {
    /// True for ready, needs-setup and error.
    pub fn is_terminal(&self) -> bool {
        matches!(self.phase, BootPhase::Ready | BootPhase::NeedsSetup | BootPhase::Error)
    }

    /// True when ready.
    pub fn is_ready(&self) -> bool {
        self.phase == BootPhase::Ready
    }
}

/// Side effects the boot sequence needs. Integration implements it.
pub trait BootServices: MaybeSend + MaybeSync {
    /// Platform setup.
    fn init_platform(&self) -> impl Future<Output = Result<()>> + MaybeSend;
    /// Forces the store open.
    fn open_database(&self) -> impl Future<Output = Result<()>> + MaybeSend;
    /// Loads the wallet credentials.
    fn load_credentials(&self) -> impl Future<Output = Result<WalletCredentials>> + MaybeSend;
    /// Chains to connect, in order (liquid, bitcoin).
    fn chains(&self) -> Vec<ChainId>;
    /// Connects one chain service. The platform enforces [`CONNECT_TIMEOUT_MS`].
    fn connect(&self, chain: ChainId, credentials: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend;
    /// Disconnects one chain service. The platform enforces [`DISCONNECT_CAP_MS`].
    fn disconnect(&self, chain: ChainId) -> impl Future<Output = Result<()>> + MaybeSend;
    /// Ensures an API session. The platform enforces [`AUTH_TIMEOUT_MS`].
    fn ensure_session(&self, credentials: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend;
}

/// Owns the boot state machine.
#[derive(Debug)]
pub struct BootOrchestrator<B: BootServices, C: Clock> {
    services: B,
    clock: C,
    state: BootState,
    state_log: Vec<BootState>,
}

impl<B: BootServices, C: Clock> BootOrchestrator<B, C> {
    /// Orchestrator in the idle phase.
    pub fn new(services: B, clock: C) -> Self {
        Self { services, clock, state: BootState::default(), state_log: Vec::new() }
    }

    /// Current state.
    pub fn state(&self) -> &BootState {
        &self.state
    }

    /// Drains every state emitted since the last call.
    pub fn take_state_changes(&mut self) -> Vec<BootState> {
        std::mem::take(&mut self.state_log)
    }

    /// The services.
    pub fn services(&self) -> &B {
        &self.services
    }

    fn emit(&mut self, s: BootState) {
        self.state = s;
        self.state_log.push(self.state.clone());
    }

    fn enter(&mut self, phase: BootPhase) {
        let mut s = self.state.clone();
        s.phase = phase;
        self.emit(s);
    }

    fn fail(&mut self, phase_name: &str, cause: &Error, dur: u64) -> Error {
        let f = Error::Boot { phase: phase_name.to_owned(), message: boot_message(cause) };
        let mut s = self.state.clone();
        s.phase = BootPhase::Error;
        s.failure = Some(f.clone());
        s.completed_at_ms = Some(self.clock.now_ms());
        s.last_phase_duration_ms = Some(dur);
        self.emit(s);
        f
    }

    fn phase_ok(&mut self, dur: u64) {
        let mut s = self.state.clone();
        s.last_phase_duration_ms = Some(dur);
        self.emit(s);
    }

    /// Runs the boot sequence. Returns the state on ready or needs-setup.
    ///
    /// A second call after ready returns the ready state without work.
    pub async fn start(&mut self) -> Result<BootState> {
        if self.state.is_ready() {
            return Ok(self.state.clone());
        }
        let started = self.clock.now_ms();
        self.emit(BootState { phase: BootPhase::InitializingPlatform, started_at_ms: Some(started), ..Default::default() });

        // Platform.
        self.enter(BootPhase::InitializingPlatform);
        let t0 = self.clock.now_ms();
        let r = self.services.init_platform().await;
        let dur = self.clock.now_ms().saturating_sub(t0);
        match r {
            Err(e) => return Err(self.fail("platform", &e, dur)),
            Ok(()) => self.phase_ok(dur),
        }

        // Database.
        // Any error from `open_database` fails the phase.
        self.enter(BootPhase::InitializingDatabase);
        let t0 = self.clock.now_ms();
        let r = self.services.open_database().await;
        let dur = self.clock.now_ms().saturating_sub(t0);
        match r {
            Err(e) => {
                let cause = Error::Unexpected(format!("database open failed: {}", boot_message(&e)));
                return Err(self.fail("database", &cause, dur));
            }
            Ok(()) => self.phase_ok(dur),
        }

        // Credentials.
        self.enter(BootPhase::LoadingCredentials);
        let t0 = self.clock.now_ms();
        let r = self.services.load_credentials().await;
        let dur = self.clock.now_ms().saturating_sub(t0);
        let creds = match r {
            Err(e) => return Err(self.fail("loadingCredentials", &e, dur)),
            Ok(c) if c.is_absent() => {
                let mut s = self.state.clone();
                s.phase = BootPhase::NeedsSetup;
                s.last_phase_duration_ms = Some(dur);
                self.emit(s);
                let mut s = self.state.clone();
                s.completed_at_ms = Some(self.clock.now_ms());
                self.emit(s);
                return Ok(self.state.clone());
            }
            Ok(c) => {
                self.phase_ok(dur);
                c
            }
        };

        // Services: concurrent fan-out, soft degrade.
        self.enter(BootPhase::ConnectingServices);
        let t0 = self.clock.now_ms();
        let chains = self.services.chains();
        let services = &self.services;
        let results =
            futures::future::join_all(chains.iter().map(|c| services.connect(*c, &creds))).await;
        let dur = self.clock.now_ms().saturating_sub(t0);
        if !results.is_empty() && results.iter().all(Result::is_err) {
            let first = results.into_iter().find_map(Result::err).unwrap_or_else(|| Error::Unexpected("all services failed".into()));
            let cause = Error::Unexpected(format!("all chain services failed: {}", boot_message(&first)));
            return Err(self.fail("connectingServices", &cause, dur));
        }
        self.phase_ok(dur);

        // Session: failure is non-fatal (degraded mode).
        self.enter(BootPhase::AuthenticatingSession);
        let t0 = self.clock.now_ms();
        let _degraded = self.services.ensure_session(&creds).await.is_err();
        let dur = self.clock.now_ms().saturating_sub(t0);
        self.phase_ok(dur);

        let mut s = self.state.clone();
        s.phase = BootPhase::Ready;
        s.completed_at_ms = Some(self.clock.now_ms());
        s.failure = None;
        self.emit(s);
        Ok(self.state.clone())
    }

    /// Disconnects bitcoin then liquid, ignoring errors, and resets to idle.
    pub async fn shutdown(&mut self) {
        for chain in [ChainId::Bitcoin, ChainId::Liquid] {
            if self.services.chains().contains(&chain) {
                let _ = self.services.disconnect(chain).await;
            }
        }
        self.emit(BootState::default());
    }
}

/// Message of a cause, without the error-kind prefix where one exists.
fn boot_message(e: &Error) -> String {
    match e {
        Error::Service { message, .. }
        | Error::Sync { message, .. }
        | Error::Boot { message, .. }
        | Error::Credential(message)
        | Error::Storage(message)
        | Error::Unexpected(message) => message.clone(),
        other => other.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::AppNetwork;
    use crate::testing::{block_on, FixedClock};
    use std::sync::{Arc, Mutex};

    #[derive(Default)]
    struct Fake {
        platform_fails: bool,
        creds: Option<WalletCredentials>,
        failing_chains: Vec<ChainId>,
        session_fails: bool,
        log: Mutex<Vec<String>>,
    }

    impl BootServices for Fake {
        fn init_platform(&self) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push("platform".into());
            std::future::ready(if self.platform_fails { Err(Error::Unexpected("no fs".into())) } else { Ok(()) })
        }
        fn open_database(&self) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push("db".into());
            std::future::ready(Ok(()))
        }
        fn load_credentials(&self) -> impl Future<Output = Result<WalletCredentials>> + MaybeSend {
            self.log.lock().unwrap().push("creds".into());
            std::future::ready(Ok(self.creds.clone().unwrap_or(WalletCredentials::absent(AppNetwork::Mainnet))))
        }
        fn chains(&self) -> Vec<ChainId> {
            vec![ChainId::Liquid, ChainId::Bitcoin]
        }
        fn connect(&self, chain: ChainId, _c: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push(format!("connect:{}", chain.as_str()));
            let fail = self.failing_chains.contains(&chain);
            std::future::ready(if fail { Err(Error::service(chain, format!("{} down", chain.as_str()))) } else { Ok(()) })
        }
        fn disconnect(&self, chain: ChainId) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push(format!("disconnect:{}", chain.as_str()));
            std::future::ready(Err(Error::Timeout("wedged".into())))
        }
        fn ensure_session(&self, _c: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push("session".into());
            std::future::ready(if self.session_fails { Err(Error::Session("401".into())) } else { Ok(()) })
        }
    }

    fn creds() -> Option<WalletCredentials> {
        Some(WalletCredentials { mnemonic: "words".into(), network: AppNetwork::Mainnet })
    }

    #[test]
    fn happy_path_runs_phases_in_order() {
        block_on(async {
            let mut b = BootOrchestrator::new(Fake { creds: creds(), session_fails: true, ..Default::default() }, Arc::new(FixedClock::new(7)));
            let s = b.start().await.unwrap();
            assert!(s.is_ready());
            assert_eq!(s.started_at_ms, Some(7));
            assert_eq!(
                *b.services().log.lock().unwrap(),
                ["platform", "db", "creds", "connect:liquid", "connect:bitcoin", "session"]
            );
            let phases: Vec<BootPhase> = b.take_state_changes().iter().map(|s| s.phase).collect();
            for p in [BootPhase::InitializingDatabase, BootPhase::LoadingCredentials, BootPhase::ConnectingServices, BootPhase::AuthenticatingSession] {
                assert!(phases.contains(&p));
            }
            assert_eq!(phases.last(), Some(&BootPhase::Ready));
            // Idempotent once ready.
            b.start().await.unwrap();
            assert_eq!(b.services().log.lock().unwrap().len(), 6);
        });
    }

    #[test]
    fn absent_credentials_need_setup_without_error() {
        block_on(async {
            let mut b = BootOrchestrator::new(Fake::default(), FixedClock::new(0));
            let s = b.start().await.unwrap();
            assert_eq!(s.phase, BootPhase::NeedsSetup);
            assert!(s.failure.is_none());
            assert!(s.completed_at_ms.is_some());
        });
    }

    #[test]
    fn platform_failure_is_terminal_error() {
        block_on(async {
            let mut b = BootOrchestrator::new(Fake { platform_fails: true, creds: creds(), ..Default::default() }, FixedClock::new(0));
            let e = b.start().await.unwrap_err();
            assert_eq!(e, Error::Boot { phase: "platform".into(), message: "no fs".into() });
            assert_eq!(b.state().phase, BootPhase::Error);
            assert_eq!(*b.services().log.lock().unwrap(), ["platform"]);
        });
    }

    #[test]
    fn one_chain_down_degrades_all_down_fails() {
        block_on(async {
            let mut b = BootOrchestrator::new(
                Fake { creds: creds(), failing_chains: vec![ChainId::Bitcoin], ..Default::default() },
                FixedClock::new(0),
            );
            assert!(b.start().await.unwrap().is_ready());

            let mut b = BootOrchestrator::new(
                Fake { creds: creds(), failing_chains: vec![ChainId::Liquid, ChainId::Bitcoin], ..Default::default() },
                FixedClock::new(0),
            );
            let e = b.start().await.unwrap_err();
            assert_eq!(
                e,
                Error::Boot { phase: "connectingServices".into(), message: "all chain services failed: liquid down".into() }
            );
        });
    }

    #[test]
    fn shutdown_resets_to_idle_even_on_errors() {
        block_on(async {
            let mut b = BootOrchestrator::new(Fake { creds: creds(), ..Default::default() }, FixedClock::new(0));
            b.start().await.unwrap();
            b.shutdown().await;
            assert_eq!(b.state().phase, BootPhase::Idle);
            let log = b.services().log.lock().unwrap().clone();
            assert_eq!(&log[log.len() - 2..], ["disconnect:bitcoin", "disconnect:liquid"]);
        });
    }
}
