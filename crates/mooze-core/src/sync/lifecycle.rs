//! Top-level app phase: boot, then sync.
//!
//! Port of the logic of `AppLifecycleControllerImpl`
//! (`lib/app/lifecycle/app_lifecycle_controller_impl.dart`) as a pure state machine.
//! The caller runs boot, sync and wallet deletion and reports the results here.

use crate::{Error, Result};

use super::boot::{BootPhase, BootState};

/// App phase.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum AppPhase {
    #[default]
    Uninitialized,
    Booting,
    Ready,
    NeedsSetup,
    ShuttingDown,
    Terminated,
    Error,
}

/// Observable app state.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct AppState {
    pub phase: AppPhase,
    pub failure: Option<Error>,
    pub started_at_ms: Option<u64>,
    pub ready_at_ms: Option<u64>,
}

/// What the caller does after [`AppLifecycle::begin_start`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StartStep {
    /// Already ready. Nothing to run.
    AlreadyReady,
    /// Run the boot orchestrator, then call [`AppLifecycle::finish_boot`].
    RunBoot,
}

/// What the caller does after [`AppLifecycle::finish_boot`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BootOutcome {
    /// Show onboarding.
    NeedsSetup,
    /// Boot failed.
    Failed(Error),
    /// App is ready. Start sync in the background, do not await it.
    ReadyStartSync,
}

/// App lifecycle state machine.
#[derive(Debug, Default)]
pub struct AppLifecycle {
    state: AppState,
}

impl AppLifecycle {
    /// Machine in the uninitialized phase.
    pub fn new() -> Self {
        Self::default()
    }

    /// Current state.
    pub fn state(&self) -> &AppState {
        &self.state
    }

    /// Starts the app. Moves to booting unless already ready.
    pub fn begin_start(&mut self, now_ms: u64) -> StartStep {
        if self.state.phase == AppPhase::Ready {
            return StartStep::AlreadyReady;
        }
        self.state.phase = AppPhase::Booting;
        self.state.started_at_ms = Some(now_ms);
        self.state.failure = None;
        StartStep::RunBoot
    }

    /// Applies the boot result. Branches on the boot phase first, like Dart,
    /// because needs-setup can come back as either side of the result.
    pub fn finish_boot(&mut self, boot: &BootState, result: &Result<BootState>, now_ms: u64) -> BootOutcome {
        if boot.phase == BootPhase::NeedsSetup {
            self.state.phase = AppPhase::NeedsSetup;
            return BootOutcome::NeedsSetup;
        }
        if let Err(e) = result {
            self.state.phase = AppPhase::Error;
            self.state.failure = Some(e.clone());
            return BootOutcome::Failed(e.clone());
        }
        self.state.phase = AppPhase::Ready;
        self.state.ready_at_ms = Some(now_ms);
        BootOutcome::ReadyStartSync
    }

    /// Begins shutdown. Returns false if already terminated.
    /// On true, the caller stops sync, then shuts boot down, then calls [`Self::finish_shutdown`].
    pub fn begin_shutdown(&mut self) -> bool {
        if self.state.phase == AppPhase::Terminated {
            return false;
        }
        self.state.phase = AppPhase::ShuttingDown;
        true
    }

    /// Marks shutdown complete.
    pub fn finish_shutdown(&mut self) {
        self.state.phase = AppPhase::Terminated;
    }

    /// Applies the result of the delete-wallet use case for re-import.
    /// Success resets to uninitialized. Failure keeps the state.
    pub fn finish_delete_for_reimport(&mut self, result: &Result<()>) -> Result<()> {
        result.clone()?;
        self.state = AppState::default();
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ready_path_and_idempotent_start() {
        let mut a = AppLifecycle::new();
        assert_eq!(a.begin_start(5), StartStep::RunBoot);
        let boot = BootState { phase: BootPhase::Ready, ..Default::default() };
        assert_eq!(a.finish_boot(&boot, &Ok(boot.clone()), 9), BootOutcome::ReadyStartSync);
        assert_eq!((a.state().phase, a.state().ready_at_ms), (AppPhase::Ready, Some(9)));
        assert_eq!(a.begin_start(10), StartStep::AlreadyReady);
    }

    #[test]
    fn needs_setup_wins_over_error_side() {
        let mut a = AppLifecycle::new();
        a.begin_start(0);
        let boot = BootState { phase: BootPhase::NeedsSetup, ..Default::default() };
        let r = Err(Error::Boot { phase: "loadingCredentials".into(), message: "mnemonic absent".into() });
        assert_eq!(a.finish_boot(&boot, &r, 1), BootOutcome::NeedsSetup);
        assert_eq!(a.state().phase, AppPhase::NeedsSetup);
    }

    #[test]
    fn failure_shutdown_and_reimport() {
        let mut a = AppLifecycle::new();
        a.begin_start(0);
        let boot = BootState { phase: BootPhase::Error, ..Default::default() };
        let e = Error::Boot { phase: "platform".into(), message: "x".into() };
        assert_eq!(a.finish_boot(&boot, &Err(e.clone()), 1), BootOutcome::Failed(e));
        assert_eq!(a.state().phase, AppPhase::Error);
        assert!(a.begin_shutdown());
        a.finish_shutdown();
        assert!(!a.begin_shutdown());
        assert!(a.finish_delete_for_reimport(&Err(Error::Storage("x".into()))).is_err());
        assert_eq!(a.state().phase, AppPhase::Terminated);
        a.finish_delete_for_reimport(&Ok(())).unwrap();
        assert_eq!(a.state().phase, AppPhase::Uninitialized);
    }
}
