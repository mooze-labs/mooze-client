//! Periodic refresh loop around `SyncOrchestrator`. Generic, so tests run
//! it with fake syncers and a manual timer.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use futures::future::select;
use futures::pin_mut;
use mooze_core::ports::{Clock, KvStore, Timer};
use mooze_core::sync::{ChainSyncer, RefreshReport, SyncOrchestrator, SyncState, SyncStrategy};
use tokio::sync::Notify;

/// Cancellation flag shared by the loops of one `App`.
#[derive(Default)]
pub struct Cancel {
    flag: AtomicBool,
    wake: Notify,
}

impl Cancel {
    /// Sets the flag and wakes every waiting loop.
    pub fn cancel(&self) {
        self.flag.store(true, Ordering::SeqCst);
        self.wake.notify_waiters();
        self.wake.notify_one();
    }

    pub fn is_cancelled(&self) -> bool {
        self.flag.load(Ordering::SeqCst)
    }

    /// Wakes the waiting loops without cancelling them.
    pub fn poke(&self) {
        self.wake.notify_waiters();
        self.wake.notify_one();
    }

    /// Resolves once cancelled. Pokes do not resolve it.
    pub async fn cancelled(&self) {
        while !self.is_cancelled() {
            self.wake.notified().await;
        }
    }

    /// Sleeps `ms`, or less when woken. True when cancelled.
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

/// Receives each refresh report with the state after it.
#[cfg(not(target_arch = "wasm32"))]
pub type EmitRefresh = Arc<dyn Fn(RefreshReport, SyncState) + Send + Sync>;
/// Receives each refresh report with the state after it.
#[cfg(target_arch = "wasm32")]
pub type EmitRefresh = Arc<dyn Fn(RefreshReport, SyncState)>;

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
    pub fn new(
        orchestrator: SyncOrchestrator<S, K, C>,
        timer: Arc<dyn Timer>,
        clock: C,
        cancel: Arc<Cancel>,
        emit: EmitRefresh,
    ) -> Self {
        Self {
            orchestrator,
            timer,
            clock,
            cancel,
            emit,
            refresh_requested: Arc::default(),
        }
    }

    /// Handle that asks the loop for an extra light refresh at its next wake.
    pub fn refresh_handle(&self) -> Arc<AtomicBool> {
        self.refresh_requested.clone()
    }

    /// Runs the startup refresh, then one light refresh per tick, until cancelled.
    ///
    /// Nothing is reported after `cancel`: a refresh that was in flight
    /// finishes silently, so a host that stops and starts again hears only
    /// the new loop.
    pub async fn run(mut self) {
        if let Some(report) = self.orchestrator.start().await {
            if self.cancel.is_cancelled() {
                return;
            }
            (self.emit)(report, self.orchestrator.state().clone());
        }
        while !self.cancel.is_cancelled() {
            let now = self.clock.now_ms();
            let wait = self
                .orchestrator
                .next_tick_at_ms()
                .map(|t| t.saturating_sub(now))
                .unwrap_or(60_000);
            if self.cancel.sleep_or_cancel(self.timer.as_ref(), wait).await {
                break;
            }
            if self.refresh_requested.swap(false, Ordering::SeqCst) {
                let report = self.orchestrator.refresh(SyncStrategy::Light).await;
                if self.cancel.is_cancelled() {
                    break;
                }
                (self.emit)(report, self.orchestrator.state().clone());
            }
            if let Some(report) = self.orchestrator.tick().await {
                if self.cancel.is_cancelled() {
                    break;
                }
                (self.emit)(report, self.orchestrator.state().clone());
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use mooze_core::domain::{
        ChainId, ServiceLifecycle, SyncOutcome, Transaction, WalletCredentials,
    };
    use mooze_core::ports::{Spawner, Timer};
    use mooze_core::store::TransactionStore;
    use mooze_core::sync::{ChainSyncer, SyncConfig, SyncOrchestrator};
    use mooze_core::testing::{FixedClock, ManualTimer, MemoryKv, TestExecutor};
    use std::future::Future;
    use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
    use std::sync::{Arc, Mutex};

    /// Syncer that completes at once, or hangs until its timeout when `hang` is set.
    #[derive(Clone)]
    struct FakeSyncer {
        chain: ChainId,
        calls: Arc<AtomicU32>,
        hang: Arc<AtomicBool>,
        timer: Arc<ManualTimer>,
    }

    #[allow(clippy::manual_async_fn)]
    impl ChainSyncer for FakeSyncer {
        fn chain(&self) -> ChainId {
            self.chain
        }
        fn lifecycle(&self) -> ServiceLifecycle {
            ServiceLifecycle::Connected
        }
        fn sync(
            &self,
            timeout_ms: u64,
        ) -> impl Future<Output = mooze_core::Result<SyncOutcome>> + Send {
            let this = self.clone();
            async move {
                this.calls.fetch_add(1, Ordering::SeqCst);
                if this.hang.load(Ordering::SeqCst) {
                    // The real AppSyncer races the wallet against the timer; mimic its timeout.
                    this.timer.sleep(timeout_ms).await;
                    return Err(mooze_core::Error::Timeout("hung".into()));
                }
                Ok(SyncOutcome {
                    chain: this.chain,
                    fetched: 1,
                    changed: 0,
                    duration_ms: 1,
                })
            }
        }
        fn transactions(
            &self,
        ) -> impl Future<Output = mooze_core::Result<Vec<Transaction>>> + Send {
            async { Ok(vec![]) }
        }
        fn connect(
            &self,
            _c: &WalletCredentials,
        ) -> impl Future<Output = mooze_core::Result<()>> + Send {
            async { Ok(()) }
        }
        fn disconnect(&self) -> impl Future<Output = mooze_core::Result<()>> + Send {
            async { Ok(()) }
        }
    }

    struct Rig {
        timer: Arc<ManualTimer>,
        clock: Arc<FixedClock>,
        cancel: Arc<Cancel>,
        liquid: Arc<AtomicU32>,
        bitcoin: Arc<AtomicU32>,
        states: Arc<Mutex<Vec<SyncState>>>,
        exec: TestExecutor,
    }

    fn setup(hang_bitcoin: bool) -> Rig {
        let timer = Arc::new(ManualTimer::new());
        let clock = Arc::new(FixedClock::new(0));
        let cancel = Arc::new(Cancel::default());
        let (spawner, mut exec) = TestExecutor::new();
        let liquid = Arc::new(AtomicU32::new(0));
        let bitcoin = Arc::new(AtomicU32::new(0));
        let syncers = vec![
            FakeSyncer {
                chain: ChainId::Liquid,
                calls: liquid.clone(),
                hang: Arc::default(),
                timer: timer.clone(),
            },
            FakeSyncer {
                chain: ChainId::Bitcoin,
                calls: bitcoin.clone(),
                hang: Arc::new(AtomicBool::new(hang_bitcoin)),
                timer: timer.clone(),
            },
        ];
        let config = SyncConfig {
            tick_ms: 60_000,
            liquid_timeout_ms: 10_000,
            bitcoin_timeout_ms: 10_000,
            startup_sync_on_boot: true,
        };
        let orchestrator = SyncOrchestrator::new(
            syncers,
            TransactionStore::new(MemoryKv::new()),
            config,
            clock.clone(),
        );
        let states = Arc::new(Mutex::new(vec![]));
        let s = states.clone();
        let emit: EmitRefresh =
            Arc::new(move |_report: RefreshReport, state: SyncState| s.lock().unwrap().push(state));
        let lp = SyncLoop::new(
            orchestrator,
            timer.clone(),
            clock.clone(),
            cancel.clone(),
            emit,
        );
        spawner.spawn(Box::pin(lp.run()));
        exec.run_until_stalled();
        Rig {
            timer,
            clock,
            cancel,
            liquid,
            bitcoin,
            states,
            exec,
        }
    }

    fn pass(rig: &mut Rig, ms: u64) {
        rig.clock.advance(ms);
        rig.timer.advance(ms);
        rig.exec.run_until_stalled();
    }

    #[test]
    fn startup_refresh_then_ticks_every_period() {
        let mut rig = setup(false);
        assert_eq!(
            (
                rig.liquid.load(Ordering::SeqCst),
                rig.bitcoin.load(Ordering::SeqCst)
            ),
            (1, 1)
        );
        pass(&mut rig, 60_000);
        assert_eq!(rig.liquid.load(Ordering::SeqCst), 2);
        rig.cancel.cancel();
        rig.exec.run_until_stalled();
        pass(&mut rig, 60_000);
        assert_eq!(
            rig.liquid.load(Ordering::SeqCst),
            2,
            "no refresh after cancel"
        );
    }

    #[test]
    fn no_report_is_emitted_after_cancel_during_a_refresh() {
        let mut rig = setup(true);
        // Bitcoin hangs; cancel while the startup refresh is in flight.
        let before = rig.states.lock().unwrap().len();
        rig.cancel.cancel();
        rig.exec.run_until_stalled();
        pass(&mut rig, 10_000);
        assert_eq!(
            rig.states.lock().unwrap().len(),
            before,
            "a cancelled loop reports nothing more"
        );
    }

    #[test]
    fn sync_longer_than_timeout_reports_timeout_and_loop_continues() {
        let mut rig = setup(true);
        // Startup refresh: liquid done, bitcoin hangs until its 10 s timeout.
        assert_eq!(rig.liquid.load(Ordering::SeqCst), 1);
        pass(&mut rig, 10_000);
        let last = rig.states.lock().unwrap().last().cloned().unwrap();
        assert!(last.first_synced_chains.contains(&ChainId::Liquid));
        assert!(!last.first_synced_chains.contains(&ChainId::Bitcoin));
        // The periodic tick anchors after the startup refresh finished (t = 10 s),
        // like Dart's Timer.periodic, so the next refresh is due at t = 70 s.
        pass(&mut rig, 60_000);
        assert_eq!(
            rig.bitcoin.load(Ordering::SeqCst),
            2,
            "next tick still runs"
        );
    }
}
