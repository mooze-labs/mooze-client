//! Host-driven lifecycle: start and stop the loops, background and foreground.
//!
//! `start` spawns the sync loop, the PIX poll loop and, with a wallet id,
//! the peg loop on the platform spawner. Every loop holds only a `Weak`
//! reference to the app state, so dropping the last `App` ends them at
//! their next wake. Mobile keeps driving ticks from Dart and never calls
//! `start`.

pub mod sync_loop;
pub mod syncers;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex as StdMutex};

use mooze_core::auth::{SessionLockController, SessionLockState, SessionLockTimeout};
use mooze_core::domain::ChainId;
use mooze_core::pix::rules::DEPOSIT_POLL_INTERVAL_MS;
use mooze_core::ports::{Clock, KvStore};
use mooze_core::store::TransactionStore;
use mooze_core::sync::{RefreshReport, SyncConfig, SyncOrchestrator, SyncPhase, SyncState};

use self::sync_loop::{Cancel, EmitRefresh, SyncLoop};
use self::syncers::AppSyncer;
use crate::app::App;
use crate::dto::*;
use crate::events::AppEvent;
use crate::{Platform, Result};

/// Mutable runtime state inside `Inner`.
#[derive(Default)]
pub(crate) struct RuntimeState {
    cancel: StdMutex<Option<Arc<Cancel>>>,
    finishes: StdMutex<Vec<futures::channel::oneshot::Receiver<()>>>,
    refresh: StdMutex<Option<Arc<AtomicBool>>>,
    lock: StdMutex<SessionLockController>,
}

impl RuntimeState {
    fn spawn(&self, spawner: &dyn mooze_core::ports::Spawner, task: mooze_core::ports::TaskFuture<'static, ()>) {
        let (done, completion) = futures::channel::oneshot::channel();
        self.finishes.lock().unwrap_or_else(|e| e.into_inner()).push(completion);
        spawner.spawn(Box::pin(async move {
            task.await;
            let _ = done.send(());
        }));
    }

    /// Cancels the loops, if running. `Inner::drop` calls it.
    pub(crate) fn cancel_all(&self) {
        if let Some(cancel) = self.cancel.lock().unwrap_or_else(|e| e.into_inner()).take() {
            cancel.cancel();
        }
    }
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
    ///
    /// `stop()` cancels the loops and any chain sync in flight, and the old
    /// loops report nothing more, so `stop()` then `start()` during a
    /// refresh never doubles an event. Dropping the last `App` without
    /// `stop()` cancels the same way, but a sync that is already running
    /// holds the state until its request returns or times out. Call
    /// `stop()` first when the state must go away now.
    pub async fn start(&self, config: StartConfigDto) -> Result<()> {
        self.start_runtime(config, true).await
    }

    /// Chain synchronization for hosts that own authenticated Pix polling and its
    /// session cancellation. Existing mobile `start` behavior stays unchanged.
    pub async fn start_wallet_sync(&self, config: StartConfigDto) -> Result<()> {
        self.start_runtime(config, false).await
    }

    async fn start_runtime(&self, config: StartConfigDto, poll_pix: bool) -> Result<()> {
        let inner = self.inner.clone();
        let cancel = {
            let mut slot = inner.runtime.cancel.lock().unwrap_or_else(|e| e.into_inner());
            if slot.as_ref().is_some_and(|c| !c.is_cancelled()) {
                return Ok(());
            }
            let cancel = Arc::new(Cancel::default());
            *slot = Some(cancel.clone());
            cancel
        };

        let mut sync_config = SyncConfig::default();
        if let Some(t) = config.sync_tick_ms {
            sync_config.tick_ms = t;
        }
        if let Some(t) = config.sync_timeout_ms {
            sync_config.liquid_timeout_ms = t;
            sync_config.bitcoin_timeout_ms = t;
        }
        sync_config.startup_sync_on_boot = config.startup_sync;

        let timer = inner.platform.timer();
        let spawner = inner.platform.spawner();
        let weak = Arc::downgrade(&inner);

        // Sync loop.
        let syncers = vec![
            AppSyncer { inner: weak.clone(), chain: ChainId::Liquid, timer: timer.clone(), cancel: cancel.clone() },
            AppSyncer { inner: weak.clone(), chain: ChainId::Bitcoin, timer: timer.clone(), cancel: cancel.clone() },
        ];
        let orchestrator = SyncOrchestrator::new(
            syncers,
            TransactionStore::new(inner.platform.kv()),
            sync_config,
            inner.platform.clock(),
        );
        let emit_weak = weak.clone();
        let emit: EmitRefresh = Arc::new(move |report: RefreshReport, state: SyncState| {
            if let Some(inner) = emit_weak.upgrade() {
                if !report.events.is_empty() {
                    inner.subscribers.emit(AppEvent::Transactions(report.events.iter().map(Into::into).collect()));
                }
                for (chain, outcome) in &report.per_chain {
                    inner.subscribers.emit(AppEvent::ChainSyncState(crate::dto::ChainSyncStateDto {
                        chain: (*chain).into(),
                        succeeded: outcome.is_ok(),
                        observed_at_ms: inner.platform.clock().now_ms(),
                    }));
                }
                inner.subscribers.emit(AppEvent::SyncState(sync_state_dto(&state)));
            }
        });
        let sync_loop = SyncLoop::new(orchestrator, timer.clone(), inner.platform.clock(), cancel.clone(), emit);
        *inner.runtime.refresh.lock().unwrap_or_else(|e| e.into_inner()) = Some(sync_loop.refresh_handle());
        inner.runtime.spawn(spawner.as_ref(), Box::pin(sync_loop.run()));

        if poll_pix {
            // PIX poll loop.
            let (pix_weak, pix_cancel, pix_timer) = (weak.clone(), cancel.clone(), timer.clone());
            inner.runtime.spawn(
                spawner.as_ref(),
                Box::pin(async move {
                    loop {
                        if pix_cancel.sleep_or_cancel(pix_timer.as_ref(), DEPOSIT_POLL_INTERVAL_MS).await {
                            break;
                        }
                        let Some(inner) = pix_weak.upgrade() else {
                            break;
                        };
                        let app = App { inner };
                        if app.pix_active_polls().await.unwrap_or(0) == 0 {
                            continue;
                        }
                        if let Ok(events) = app.pix_poll_tick().await {
                            if !events.is_empty() {
                                app.inner.subscribers.emit(AppEvent::PixStatus(events));
                            }
                        }
                    }
                }),
            );
        }

        // Peg loop.
        if let Some(wallet_id) = config.peg_wallet_id {
            let (peg_weak, peg_cancel, peg_timer) = (weak, cancel, timer);
            inner.runtime.spawn(
                spawner.as_ref(),
                Box::pin(async move {
                    loop {
                        let wait = {
                            let Some(inner) = peg_weak.upgrade() else {
                                break;
                            };
                            let now = inner.platform.clock().now_ms();
                            let next = inner.sideswap.pegs.lock().await.next_wakeup_ms();
                            next.map(|t| t.saturating_sub(now)).unwrap_or(60_000).max(1_000)
                        };
                        if peg_cancel.sleep_or_cancel(peg_timer.as_ref(), wait).await {
                            break;
                        }
                        let Some(inner) = peg_weak.upgrade() else {
                            break;
                        };
                        let app = App { inner };
                        if let Ok(refresh) = app.peg_refresh_due(wallet_id.clone()).await {
                            if !refresh.changed.is_empty() || !refresh.finished.is_empty() {
                                app.inner.subscribers.emit(AppEvent::PegProgress(refresh));
                            }
                        }
                    }
                }),
            );
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

    /// Native storage-lifecycle barrier. The host must serialize start with this call.
    /// Cancellation alone does not guarantee pending persistence has completed.
    pub async fn stop_and_wait(&self) -> Result<()> {
        self.stop().await?;
        let finishes = std::mem::take(&mut *self.inner.runtime.finishes.lock().unwrap_or_else(|e| e.into_inner()));
        futures::future::join_all(finishes).await;
        Ok(())
    }

    /// True between `start` and `stop`.
    pub async fn is_running(&self) -> Result<bool> {
        Ok(self
            .inner
            .runtime
            .cancel
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .as_ref()
            .is_some_and(|c| !c.is_cancelled()))
    }

    /// Asks the sync loop for one light refresh now.
    pub async fn refresh_now(&self) -> Result<()> {
        if let Some(flag) = self.inner.runtime.refresh.lock().unwrap_or_else(|e| e.into_inner()).as_ref() {
            flag.store(true, Ordering::SeqCst);
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

    /// The host returned to the foreground. Decides the lock from the
    /// stored `SessionLockTimeout` and asks the sync loop for a refresh.
    pub async fn on_foreground(&self, now_ms: u64, lock_enabled: bool) -> Result<SessionLockStateDto> {
        let stored = self.inner.platform.kv().get(SessionLockTimeout::PREFS_KEY).await?;
        let timeout = SessionLockTimeout::from_storage(stored.as_deref().and_then(|b| std::str::from_utf8(b).ok()));
        let state = self.inner.runtime.lock.lock().unwrap_or_else(|e| e.into_inner()).on_resumed(
            now_ms,
            lock_enabled,
            false,
            timeout,
        );
        let dto = match state {
            SessionLockState::Locked => SessionLockStateDto::Locked,
            SessionLockState::Unlocked => SessionLockStateDto::Unlocked,
        };
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

#[cfg(test)]
mod tests {
    use crate::dto::{SessionLockStateDto, StartConfigDto};
    use crate::testing::open_test_app_with_executor;
    use mooze_core::ports::KvStore;
    use mooze_core::testing::block_on;

    fn config() -> StartConfigDto {
        StartConfigDto { sync_tick_ms: None, sync_timeout_ms: None, startup_sync: false, peg_wallet_id: None }
    }

    #[test]
    fn host_owned_pix_polling_does_not_spawn_an_unguarded_poll_loop() {
        let (app, _plat, mut exec) = open_test_app_with_executor();
        block_on(app.start_wallet_sync(config())).unwrap();
        assert_eq!(app.inner.runtime.finishes.lock().unwrap().len(), 1);
        exec.run_until_stalled();
        block_on(app.stop()).unwrap();
        exec.run_until_stalled();
        assert!(!block_on(app.is_running()).unwrap());
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
    fn stop_and_wait_observes_loop_completion() {
        use futures::FutureExt;
        let (app, _plat, mut exec) = open_test_app_with_executor();
        block_on(app.start(config())).unwrap();
        exec.run_until_stalled();
        let mut stopped = Box::pin(app.stop_and_wait());
        assert!(stopped.as_mut().now_or_never().is_none());
        exec.run_until_stalled();
        block_on(stopped).unwrap();
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
