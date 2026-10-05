//! Peg tracker. Port of `domain/usecases/peg_tracker.dart`.
//!
//! The Dart tracker owns timers and a stream. Here the tracker is pure state:
//! it records the next poll time per order, and the platform asks
//! [`PegTracker::due`] when to call [`PegTracker::refresh`].

use std::collections::BTreeMap;
use std::future::Future;

use serde::{Deserialize, Serialize};

use super::entities::{PegDirection, PegError, PegPhase, PegProgress};
use super::orchestrator::PegStore;
use super::repository::PegRepository;
use crate::ports::{MaybeSend, MaybeSync};
use crate::Result;

/// A peg the tracker watches.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TrackedPeg {
    pub order_id: String,
    pub direction: PegDirection,
    pub phase: PegPhase,
    pub amount_sat: u64,
    pub deposit_address: String,
    pub funding_tx_id: Option<String>,
    pub payout_tx_id: Option<String>,
    pub confirmations: Option<u32>,
    pub required_confirmations: Option<u32>,
    pub error_message: Option<String>,
}

impl TrackedPeg {
    /// True when the phase is terminal.
    pub fn is_terminal(&self) -> bool {
        self.phase.is_terminal()
    }

    /// Dart `copyWith`: `None` keeps the old value.
    fn merged(&self, phase: PegPhase, payout: Option<&str>, confs: Option<u32>, required: Option<u32>) -> Self {
        let mut n = self.clone();
        n.phase = phase;
        if let Some(p) = payout {
            n.payout_tx_id = Some(p.to_owned());
        }
        if confs.is_some() {
            n.confirmations = confs;
        }
        if required.is_some() {
            n.required_confirmations = required;
        }
        n
    }
}

/// Source of pegs to resume after a restart.
pub trait PegRecoverySource: MaybeSend + MaybeSync {
    /// Non-terminal pegs, oldest first.
    fn load_active_pegs(&self) -> impl Future<Output = Result<Vec<TrackedPeg>>> + MaybeSend;
}

/// What one status result changed.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct TrackerUpdate {
    /// True if [`PegTracker::current`] changed (Dart emitted).
    pub changed: bool,
    /// Set when the peg became terminal and must be persisted.
    pub terminal: Option<TrackedPeg>,
}

/// Poll interval per phase in ms. Zero means no polling.
pub fn poll_interval_ms(phase: PegPhase) -> u64 {
    match phase {
        PegPhase::AwaitingDeposit => 5 * 60 * 1000,
        PegPhase::Detected | PegPhase::Processing => 30 * 1000,
        _ => 0,
    }
}

/// Pure peg tracking state machine.
#[derive(Debug, Clone, Default)]
pub struct PegTracker {
    tracked: Vec<TrackedPeg>,
    next_poll_at: BTreeMap<String, u64>,
    offline: bool,
    disposed: bool,
    interval_override: Option<fn(PegPhase) -> u64>,
}

impl PegTracker {
    /// Empty tracker.
    pub fn new() -> Self {
        Self::default()
    }

    /// Tracker with custom intervals (tests).
    pub fn with_interval(f: fn(PegPhase) -> u64) -> Self {
        Self { interval_override: Some(f), ..Self::default() }
    }

    /// Everything tracked, in insertion order.
    pub fn current(&self) -> &[TrackedPeg] {
        &self.tracked
    }

    /// One tracked peg.
    pub fn get(&self, order_id: &str) -> Option<&TrackedPeg> {
        self.tracked.iter().find(|p| p.order_id == order_id)
    }

    /// True while offline.
    pub fn is_offline(&self) -> bool {
        self.offline
    }

    fn interval(&self, phase: PegPhase) -> u64 {
        self.interval_override.map_or_else(|| poll_interval_ms(phase), |f| f(phase))
    }

    fn upsert(&mut self, peg: TrackedPeg) {
        match self.tracked.iter_mut().find(|p| p.order_id == peg.order_id) {
            Some(slot) => *slot = peg,
            None => self.tracked.push(peg),
        }
    }

    fn schedule(&mut self, order_id: &str, now_ms: u64) {
        if self.disposed || self.offline {
            return;
        }
        let Some(phase) = self.get(order_id).map(|p| p.phase) else { return };
        if phase.is_terminal() {
            return;
        }
        self.next_poll_at.remove(order_id);
        let delay = self.interval(phase);
        if delay == 0 {
            return;
        }
        self.next_poll_at.insert(order_id.to_owned(), now_ms + delay);
    }

    /// Adds restored pegs that are not tracked yet and schedules them.
    /// Idempotent. Returns true (Dart always emits).
    pub fn restore(&mut self, pegs: Vec<TrackedPeg>, now_ms: u64) -> bool {
        if self.disposed {
            return false;
        }
        for peg in pegs {
            if self.get(&peg.order_id).is_some() {
                continue;
            }
            let id = peg.order_id.clone();
            self.tracked.push(peg);
            self.schedule(&id, now_ms);
        }
        true
    }

    /// Starts tracking a fresh peg. It is due for an immediate poll.
    pub fn track(&mut self, peg: TrackedPeg, now_ms: u64) -> bool {
        if self.disposed {
            return false;
        }
        let id = peg.order_id.clone();
        self.upsert(peg);
        if !self.offline {
            self.next_poll_at.insert(id, now_ms);
        }
        true
    }

    /// Stops tracking without touching storage.
    pub fn untrack(&mut self, order_id: &str) {
        self.next_poll_at.remove(order_id);
        self.tracked.retain(|p| p.order_id != order_id);
    }

    /// Pauses polling and clears the schedule.
    pub fn go_offline(&mut self) {
        if self.offline {
            return;
        }
        self.offline = true;
        self.next_poll_at.clear();
    }

    /// Resumes polling. Returns every tracked order id to refresh now.
    pub fn go_online(&mut self) -> Vec<String> {
        if !self.offline {
            return Vec::new();
        }
        self.offline = false;
        self.tracked.iter().map(|p| p.order_id.clone()).collect()
    }

    /// Order ids whose poll time has come.
    pub fn due(&self, now_ms: u64) -> Vec<String> {
        self.next_poll_at.iter().filter(|(_, at)| **at <= now_ms).map(|(id, _)| id.clone()).collect()
    }

    /// Earliest scheduled poll, for the platform timer.
    pub fn next_wakeup_ms(&self) -> Option<u64> {
        self.next_poll_at.values().copied().min()
    }

    /// True if a refresh of `order_id` would poll.
    pub fn should_refresh(&self, order_id: &str) -> bool {
        !self.disposed && !self.offline && self.get(order_id).is_some_and(|p| !p.is_terminal())
    }

    /// Applies one status result. Port of the body of `refresh`.
    ///
    /// Transport errors only reschedule. Order-not-found is terminal (failed).
    /// A backward non-terminal phase is ignored.
    pub fn apply_status(
        &mut self,
        order_id: &str,
        result: std::result::Result<PegProgress, PegError>,
        now_ms: u64,
    ) -> TrackerUpdate {
        if self.disposed {
            return TrackerUpdate::default();
        }
        let Some(peg) = self.get(order_id).cloned() else { return TrackerUpdate::default() };
        if peg.is_terminal() {
            return TrackerUpdate::default();
        }
        match result {
            Err(e @ PegError::OrderNotFound(_)) => {
                let mut failed = peg.clone();
                failed.phase = PegPhase::Failed;
                failed.error_message = Some(e.message());
                self.finalise(failed)
            }
            Err(_) => {
                self.schedule(order_id, now_ms);
                TrackerUpdate::default()
            }
            Ok(progress) => {
                let first = progress.deposits.first();
                let updated = peg.merged(
                    progress.phase,
                    progress.payout_tx_id(),
                    first.and_then(|d| d.detected_confirmations),
                    first.and_then(|d| d.total_confirmations),
                );
                if !updated.phase.is_terminal() && updated.phase.progress_rank() < peg.phase.progress_rank() {
                    self.schedule(order_id, now_ms);
                    return TrackerUpdate::default();
                }
                if updated.is_terminal() {
                    self.finalise(updated)
                } else {
                    self.upsert(updated);
                    self.schedule(order_id, now_ms);
                    TrackerUpdate { changed: true, terminal: None }
                }
            }
        }
    }

    fn finalise(&mut self, peg: TrackedPeg) -> TrackerUpdate {
        self.next_poll_at.remove(&peg.order_id);
        self.upsert(peg.clone());
        TrackerUpdate { changed: true, terminal: Some(peg) }
    }

    /// Polls `order_id` once and persists a terminal state (best-effort).
    pub async fn refresh<R: PegRepository, S: PegStore>(
        &mut self,
        repository: &mut R,
        store: &S,
        order_id: &str,
        now_ms: u64,
    ) -> TrackerUpdate {
        if !self.should_refresh(order_id) {
            return TrackerUpdate::default();
        }
        let direction = match self.get(order_id) {
            Some(p) => p.direction,
            None => return TrackerUpdate::default(),
        };
        // Do not refetch until this poll finishes.
        self.next_poll_at.remove(order_id);
        let result = repository.get_status(direction, order_id).await;
        let update = self.apply_status(order_id, result, now_ms);
        if let Some(t) = &update.terminal {
            // A write failure must not crash the tracker; restore re-polls.
            let _ = store
                .record_terminal(&t.order_id, t.phase, t.payout_tx_id.as_deref(), t.error_message.as_deref())
                .await;
        }
        update
    }

    /// Loads persisted pegs and resumes them.
    pub async fn restore_from<P: PegRecoverySource>(&mut self, source: &P, now_ms: u64) -> Result<bool> {
        if self.disposed {
            return Ok(false);
        }
        let pegs = source.load_active_pegs().await?;
        Ok(self.restore(pegs, now_ms))
    }

    /// Stops all polling for good.
    pub fn dispose(&mut self) {
        self.disposed = true;
        self.next_poll_at.clear();
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use std::sync::Arc;

    use super::*;
    use crate::peg::entities::PegDeposit;
    use crate::peg::orchestrator::tests::{FakeRepo, Log, LogStore};
    use crate::testing::block_on;

    fn pending(id: &str) -> TrackedPeg {
        TrackedPeg {
            order_id: id.into(),
            direction: PegDirection::PegOut,
            phase: PegPhase::AwaitingDeposit,
            amount_sat: 100_000,
            deposit_address: "lq1-deposit".into(),
            funding_tx_id: Some("lwk-txid".into()),
            payout_tx_id: None,
            confirmations: None,
            required_confirmations: None,
            error_message: None,
        }
    }

    fn progress(id: &str, phase: PegPhase, payout: Option<&str>, confs: Option<(u32, u32)>) -> PegProgress {
        PegProgress {
            order_id: id.into(),
            direction: PegDirection::PegOut,
            phase,
            deposits: vec![PegDeposit {
                tx_id: "t".into(),
                phase,
                amount_sat: 100_000,
                payout_sat: None,
                payout_tx_id: payout.map(str::to_owned),
                detected_confirmations: confs.map(|c| c.0),
                total_confirmations: confs.map(|c| c.1),
            }],
            deposit_address: "lq1".into(),
            payout_address: "bc1".into(),
        }
    }

    fn setup() -> (PegTracker, FakeRepo, LogStore, Log) {
        let log: Log = Arc::default();
        (
            PegTracker::new(),
            FakeRepo { log: log.clone(), status: None },
            LogStore { log: log.clone(), fail: false },
            log,
        )
    }

    #[test]
    fn restore_is_idempotent_and_schedules() {
        let mut t = PegTracker::new();
        t.restore(vec![pending("order-1"), pending("order-2")], 0);
        t.restore(vec![pending("order-1")], 0);
        assert_eq!(t.current().iter().map(|p| p.order_id.as_str()).collect::<Vec<_>>(), ["order-1", "order-2"]);
        assert!(t.due(299_999).is_empty());
        assert_eq!(t.due(300_000).len(), 2);
        assert_eq!(t.next_wakeup_ms(), Some(300_000));
    }

    #[test]
    fn advances_and_persists_terminal_once() {
        let (mut t, mut repo, store, log) = setup();
        t.track(pending("order-1"), 0);
        assert_eq!(t.due(0), ["order-1"]);
        for phase in [PegPhase::Detected, PegPhase::Processing] {
            repo.status = Some(Ok(progress("order-1", phase, None, None)));
            assert!(block_on(t.refresh(&mut repo, &store, "order-1", 0)).changed);
            assert_eq!(t.current()[0].phase, phase);
        }
        assert_eq!(t.due(30_000), ["order-1"]);
        repo.status = Some(Ok(progress("order-1", PegPhase::Completed, Some("btc-payout"), None)));
        block_on(t.refresh(&mut repo, &store, "order-1", 0));
        block_on(t.refresh(&mut repo, &store, "order-1", 0));
        assert_eq!(t.current()[0].payout_tx_id.as_deref(), Some("btc-payout"));
        let terminals: Vec<_> = log.lock().unwrap().iter().filter(|l| l.starts_with("terminal")).cloned().collect();
        assert_eq!(terminals, ["terminal:order-1:completed"]);
        assert!(t.due(u64::MAX).is_empty());
    }

    #[test]
    fn never_walks_backwards_and_surfaces_confirmations() {
        let mut t = PegTracker::new();
        t.track(pending("o"), 0);
        t.apply_status("o", Ok(progress("o", PegPhase::Processing, None, None)), 0);
        let u = t.apply_status("o", Ok(progress("o", PegPhase::Detected, None, Some((1, 2)))), 0);
        assert!(!u.changed);
        assert_eq!(t.current()[0].phase, PegPhase::Processing);

        let mut t = PegTracker::new();
        t.track(pending("o"), 0);
        t.apply_status("o", Ok(progress("o", PegPhase::Detected, None, Some((1, 2)))), 0);
        assert_eq!((t.current()[0].confirmations, t.current()[0].required_confirmations), (Some(1), Some(2)));
    }

    #[test]
    fn insufficient_amount_is_terminal() {
        let mut t = PegTracker::new();
        t.track(pending("o"), 0);
        let u = t.apply_status("o", Ok(progress("o", PegPhase::InsufficientAmount, None, None)), 0);
        assert_eq!(u.terminal.unwrap().phase, PegPhase::InsufficientAmount);
    }

    #[test]
    fn errors() {
        let mut t = PegTracker::new();
        t.track(pending("o"), 0);
        let u = t.apply_status("o", Err(PegError::TransportFailure("x".into())), 10);
        assert!(!u.changed);
        assert_eq!(t.current()[0].phase, PegPhase::AwaitingDeposit);
        assert_eq!(t.next_wakeup_ms(), Some(10 + 300_000));
        let u = t.apply_status("o", Err(PegError::OrderNotFound("o".into())), 10);
        let term = u.terminal.unwrap();
        assert_eq!((term.phase, term.error_message.as_deref()), (PegPhase::Failed, Some("Ordem não encontrada")));

        // Store failure does not crash.
        let log: Log = Arc::default();
        let mut repo = FakeRepo { log: log.clone(), status: Some(Ok(progress("p", PegPhase::Completed, None, None))) };
        let store = LogStore { log, fail: true };
        t.track(pending("p"), 0);
        assert!(block_on(t.refresh(&mut repo, &store, "p", 0)).terminal.is_some());
    }

    #[test]
    fn offline_online_and_dispose() {
        let (mut t, mut repo, store, log) = setup();
        t.track(pending("a"), 0);
        t.track(pending("b"), 0);
        t.go_offline();
        assert!(t.due(u64::MAX).is_empty());
        repo.status = Some(Ok(progress("a", PegPhase::Detected, None, None)));
        assert!(!block_on(t.refresh(&mut repo, &store, "a", 0)).changed);
        assert!(log.lock().unwrap().is_empty());
        assert_eq!(t.go_online(), ["a", "b"]);
        assert!(block_on(t.refresh(&mut repo, &store, "a", 0)).changed);
        t.dispose();
        assert!(!block_on(t.refresh(&mut repo, &store, "b", 0)).changed);
        assert!(t.next_wakeup_ms().is_none());
    }

    #[test]
    fn custom_interval() {
        let mut t = PegTracker::with_interval(|p| if p.is_terminal() { 0 } else { 5 });
        t.restore(vec![pending("x")], 100);
        assert_eq!(t.next_wakeup_ms(), Some(105));
    }
}
