//! Sync orchestration across chains.
//!
//! Port of `SyncOrchestratorImpl` (`lib/features/sync/data/sync_orchestrator_impl.dart`).
//! The core owns no timer. The platform calls [`SyncOrchestrator::tick`]
//! and the orchestrator decides if a periodic refresh is due.
//! Methods take `&mut self`, which serializes refresh and reconnect like the Dart mutex.

use std::collections::{BTreeMap, BTreeSet};
use std::future::Future;

use futures::stream::{FuturesUnordered, StreamExt};

use crate::domain::{
    ChainId, ServiceLifecycle, SyncOutcome, Transaction, TransactionEvent, WalletCredentials,
};
use crate::ports::{Clock, KvStore, MaybeSend, MaybeSync};
use crate::store::TransactionStore;
use crate::{Error, Result};

/// One chain wallet service as the orchestrator sees it.
///
/// Integration wraps the Liquid and Bitcoin services. Use an enum when the
/// two services have different types.
pub trait ChainSyncer: MaybeSend + MaybeSync {
    /// Chain of the service.
    fn chain(&self) -> ChainId;

    /// Current connection lifecycle.
    fn lifecycle(&self) -> ServiceLifecycle;

    /// True when connected.
    fn is_operational(&self) -> bool {
        self.lifecycle() == ServiceLifecycle::Connected
    }

    /// Syncs the chain. The platform enforces `timeout_ms`
    /// (and the hard cap [`SyncConfig::hard_timeout_ms`]).
    fn sync(&self, timeout_ms: u64) -> impl Future<Output = Result<SyncOutcome>> + MaybeSend;

    /// Current transaction records of the chain, read after a sync.
    fn transactions(&self) -> impl Future<Output = Result<Vec<Transaction>>> + MaybeSend;

    /// Connects with `credentials`.
    fn connect(&self, credentials: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend;

    /// Disconnects. Idempotent.
    fn disconnect(&self) -> impl Future<Output = Result<()>> + MaybeSend;
}

/// Refresh strategy.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SyncStrategy {
    /// Balances and tx state on every connected chain.
    #[default]
    Light,
    /// Light plus swap rescan and refunds.
    Full,
}

/// Tunable sync parameters. Defaults match the Dart `SyncConfig`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SyncConfig {
    /// Periodic refresh cadence.
    pub tick_ms: u64,
    pub liquid_timeout_ms: u64,
    pub bitcoin_timeout_ms: u64,
    /// Run one refresh inside [`SyncOrchestrator::start`].
    pub startup_sync_on_boot: bool,
}

impl Default for SyncConfig {
    fn default() -> Self {
        Self { tick_ms: 60_000, liquid_timeout_ms: 60_000, bitcoin_timeout_ms: 60_000, startup_sync_on_boot: true }
    }
}

/// Extra time past the per-chain timeout before Dart gives up ("sync hard timeout").
pub const HARD_TIMEOUT_GRACE_MS: u64 = 5_000;
/// Time `stop` waits for an in-flight refresh in Dart.
pub const STOP_DRAIN_TIMEOUT_MS: u64 = 5_000;

impl SyncConfig {
    /// Per-chain sync timeout. Lightning and aggregate use the Liquid value.
    pub fn timeout_for(&self, chain: ChainId) -> u64 {
        match chain {
            ChainId::Bitcoin => self.bitcoin_timeout_ms,
            ChainId::Liquid | ChainId::Lightning | ChainId::Aggregate => self.liquid_timeout_ms,
        }
    }

    /// Hard cap for one chain sync: timeout plus [`HARD_TIMEOUT_GRACE_MS`].
    pub fn hard_timeout_ms(&self, chain: ChainId) -> u64 {
        self.timeout_for(chain) + HARD_TIMEOUT_GRACE_MS
    }
}

/// Phase of the orchestrator.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SyncPhase {
    #[default]
    Idle,
    Running,
    Cooling,
    Stopped,
}

/// Observable sync state.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SyncState {
    pub phase: SyncPhase,
    pub per_chain: BTreeMap<ChainId, ServiceLifecycle>,
    pub last_error: Option<Error>,
    pub last_success_at_ms: Option<u64>,
    pub last_duration_ms: Option<u64>,
    /// Chains with at least one successful sync this session.
    pub first_synced_chains: BTreeSet<ChainId>,
}

/// Everything one refresh produced.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RefreshReport {
    /// Aggregate outcome, or the failure when every operational chain failed.
    pub outcome: Result<SyncOutcome>,
    /// Per-chain results in completion order (not-operational chains first).
    pub per_chain: Vec<(ChainId, Result<SyncOutcome>)>,
    /// Store changes, replaces the Dart `transactions` stream.
    pub events: Vec<TransactionEvent>,
}

/// Single owner of sync activity.
#[derive(Debug)]
pub struct SyncOrchestrator<S: ChainSyncer, K: KvStore, C: Clock> {
    syncers: Vec<S>,
    store: TransactionStore<K>,
    config: SyncConfig,
    clock: C,
    state: SyncState,
    started: bool,
    started_at_ms: u64,
    next_tick_at_ms: Option<u64>,
    state_log: Vec<SyncState>,
}

impl<S: ChainSyncer, K: KvStore, C: Clock> SyncOrchestrator<S, K, C> {
    /// Orchestrator over `syncers`, in Dart order (liquid, bitcoin).
    pub fn new(syncers: Vec<S>, store: TransactionStore<K>, config: SyncConfig, clock: C) -> Self {
        Self {
            syncers,
            store,
            config,
            clock,
            state: SyncState::default(),
            started: false,
            started_at_ms: 0,
            next_tick_at_ms: None,
            state_log: Vec::new(),
        }
    }

    /// Current state.
    pub fn state(&self) -> &SyncState {
        &self.state
    }

    /// Drains every state emitted since the last call (Dart `state` stream).
    pub fn take_state_changes(&mut self) -> Vec<SyncState> {
        std::mem::take(&mut self.state_log)
    }

    /// The services.
    pub fn syncers(&self) -> &[S] {
        &self.syncers
    }

    /// The transaction store.
    pub fn store(&self) -> &TransactionStore<K> {
        &self.store
    }

    /// True between `start` and `stop`.
    pub fn is_started(&self) -> bool {
        self.started
    }

    /// Time the next periodic refresh is due, if started.
    pub fn next_tick_at_ms(&self) -> Option<u64> {
        self.next_tick_at_ms
    }

    fn emit(&mut self, s: SyncState) {
        self.state = s;
        self.state_log.push(self.state.clone());
    }

    /// Starts the orchestrator. Runs the startup refresh if configured.
    ///
    /// Returns `None` when already started or when no startup refresh runs.
    pub async fn start(&mut self) -> Option<RefreshReport> {
        if self.started {
            return None;
        }
        self.started = true;
        self.started_at_ms = self.clock.now_ms();
        let report =
            if self.config.startup_sync_on_boot { Some(self.refresh(SyncStrategy::Light).await) } else { None };
        // Timer.periodic is anchored when it is created, after the startup refresh.
        self.started_at_ms = self.clock.now_ms();
        self.next_tick_at_ms = Some(self.started_at_ms + self.config.tick_ms);
        report
    }

    /// True if started and the periodic refresh is due at `now_ms`.
    pub fn is_tick_due(&self, now_ms: u64) -> bool {
        self.started && self.next_tick_at_ms.is_some_and(|t| now_ms >= t)
    }

    /// Runs the periodic light refresh if due. Missed ticks collapse into one.
    pub async fn tick(&mut self) -> Option<RefreshReport> {
        let now = self.clock.now_ms();
        if !self.is_tick_due(now) {
            return None;
        }
        let tick = self.config.tick_ms.max(1);
        let elapsed = now.saturating_sub(self.started_at_ms);
        self.next_tick_at_ms = Some(self.started_at_ms + (elapsed / tick + 1) * tick);
        Some(self.refresh(SyncStrategy::Light).await)
    }

    /// Refreshes every operational chain concurrently.
    ///
    /// One failing chain does not block the others. Each successful chain
    /// lands in `first_synced_chains` after its transactions are in the store.
    pub async fn refresh(&mut self, strategy: SyncStrategy) -> RefreshReport {
        // NOTE(port): Dart services ignore the strategy in `sync(timeout)`; kept for API parity.
        let _ = strategy;
        self.run_refresh().await
    }

    async fn run_refresh(&mut self) -> RefreshReport {
        let t0 = self.clock.now_ms();
        let per_chain: BTreeMap<ChainId, ServiceLifecycle> =
            self.syncers.iter().map(|s| (s.chain(), s.lifecycle())).collect();
        let mut s = self.state.clone();
        s.phase = SyncPhase::Running;
        s.per_chain = per_chain;
        s.last_error = None;
        self.emit(s);

        let mut outcomes: Vec<(ChainId, Result<SyncOutcome>)> = Vec::new();
        let mut events = Vec::new();
        let mut total_fetched = 0;
        let mut total_changed = 0;

        let config = self.config;
        let mut in_flight = FuturesUnordered::new();
        for syncer in &self.syncers {
            let chain = syncer.chain();
            if !syncer.is_operational() {
                outcomes.push((chain, Err(Error::service(chain, "not operational"))));
                continue;
            }
            in_flight.push(async move {
                let r = syncer.sync(config.timeout_for(chain)).await;
                // Dart persists the chain's tx events before marking it settled.
                let txs = match &r {
                    Ok(_) => Some(syncer.transactions().await),
                    Err(_) => None,
                };
                (chain, r, txs)
            });
        }

        let mut settled = Vec::new();
        while let Some(done) = in_flight.next().await {
            settled.push(done);
        }
        drop(in_flight);

        for (chain, r, txs) in settled {
            // A failed read or a failed write only loses this batch.
            // Dart logs `sync.tx.persist.batch.failed` and drops the batch.
            if let Some(Ok(txs)) = txs {
                if let Ok(evs) = self.store.upsert_all(&txs, self.clock.now_ms()).await {
                    events.extend(evs);
                }
            }
            if let Ok(o) = &r {
                total_fetched += o.fetched;
                total_changed += o.changed;
                let mut s = self.state.clone();
                s.first_synced_chains.insert(chain);
                s.per_chain.insert(chain, ServiceLifecycle::Connected);
                s.last_success_at_ms = Some(self.clock.now_ms());
                s.last_error = None;
                self.emit(s);
            }
            outcomes.push((chain, r));
        }

        let duration = self.clock.now_ms().saturating_sub(t0);
        let aggregate =
            SyncOutcome { chain: ChainId::Aggregate, fetched: total_fetched, changed: total_changed, duration_ms: duration };

        let operational: Vec<ChainId> =
            self.syncers.iter().filter(|s| s.is_operational()).map(|s| s.chain()).collect();
        let failed = operational
            .iter()
            .filter(|c| outcomes.iter().any(|(oc, r)| oc == *c && r.is_err()))
            .count();
        let all_failed = !operational.is_empty() && failed == operational.len();
        let new_per_chain: BTreeMap<ChainId, ServiceLifecycle> =
            self.syncers.iter().map(|s| (s.chain(), s.lifecycle())).collect();

        if all_failed {
            // NOTE(port): Dart picks the first failure in insertion order,
            // which can be a "not operational" entry of a skipped chain.
            let (fchain, ferr) = outcomes
                .iter()
                .find_map(|(c, r)| r.as_ref().err().map(|e| (*c, e.clone())))
                .unwrap_or((ChainId::Aggregate, Error::service(ChainId::Aggregate, "unknown")));
            let (chain, message) = failure_parts(fchain, &ferr);
            let sf = Error::Sync { chain, message: format!("all operational services failed: {message}") };
            let mut s = self.state.clone();
            s.phase = SyncPhase::Cooling;
            s.per_chain = new_per_chain;
            s.last_error = Some(sf.clone());
            s.last_duration_ms = Some(duration);
            self.emit(s);
            return RefreshReport { outcome: Err(sf), per_chain: outcomes, events };
        }

        let mut s = self.state.clone();
        s.phase = SyncPhase::Cooling;
        s.per_chain = new_per_chain;
        s.last_success_at_ms = Some(self.clock.now_ms());
        s.last_duration_ms = Some(duration);
        s.last_error = None;
        self.emit(s);
        RefreshReport { outcome: Ok(aggregate), per_chain: outcomes, events }
    }

    /// Reconnects every non-operational service, then runs a light refresh.
    ///
    /// Fails only when no service is operational after the pass.
    pub async fn reconnect(&mut self, credentials: &WalletCredentials) -> RefreshReport {
        let mut last_failure: Option<(ChainId, Error)> = None;
        for syncer in &self.syncers {
            if syncer.is_operational() {
                continue;
            }
            let chain = syncer.chain();
            // Disconnect releases half-acquired handles. Its error counts as a failure too.
            let r = match syncer.disconnect().await {
                Ok(()) => syncer.connect(credentials).await,
                Err(e) => Err(e),
            };
            if let Err(e) = r {
                last_failure = Some((chain, e));
            }
        }
        let report = self.run_refresh().await;
        let operational_after = self.syncers.iter().filter(|s| s.is_operational()).count();
        if operational_after == 0 {
            if let Some((c, e)) = last_failure {
                let (chain, message) = failure_parts(c, &e);
                let err = Error::Sync { chain, message: format!("reconnect: no service operational: {message}") };
                return RefreshReport { outcome: Err(err), ..report };
            }
        }
        report
    }

    /// Stops the orchestrator and resets per-wallet state.
    ///
    /// The next `start` rebuilds `first_synced_chains` from fresh syncs.
    pub fn stop(&mut self) {
        if !self.started {
            return;
        }
        self.started = false;
        self.next_tick_at_ms = None;
        self.emit(SyncState { phase: SyncPhase::Stopped, ..SyncState::default() });
    }
}

/// Chain and message of a service failure.
fn failure_parts(fallback_chain: ChainId, e: &Error) -> (ChainId, String) {
    match e {
        Error::Service { chain, message } | Error::Sync { chain, message } => (*chain, message.clone()),
        other => (fallback_chain, other.to_string()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{AppNetwork, TransactionDirection, TransactionStatus};
    use crate::testing::{block_on, FixedClock, MemoryKv};
    use std::sync::{Arc, Mutex};

    #[derive(Debug, Clone)]
    struct FakeSyncer {
        chain: ChainId,
        lifecycle: Arc<Mutex<ServiceLifecycle>>,
        fail_sync: bool,
        fail_connect: bool,
        txs: Vec<Transaction>,
        calls: Arc<Mutex<Vec<String>>>,
    }

    impl FakeSyncer {
        fn new(chain: ChainId) -> Self {
            Self {
                chain,
                lifecycle: Arc::new(Mutex::new(ServiceLifecycle::Connected)),
                fail_sync: false,
                fail_connect: false,
                txs: vec![],
                calls: Arc::default(),
            }
        }
    }

    impl ChainSyncer for FakeSyncer {
        fn chain(&self) -> ChainId {
            self.chain
        }
        fn lifecycle(&self) -> ServiceLifecycle {
            *self.lifecycle.lock().unwrap()
        }
        fn sync(&self, timeout_ms: u64) -> impl Future<Output = Result<SyncOutcome>> + MaybeSend {
            self.calls.lock().unwrap().push(format!("sync:{timeout_ms}"));
            let r = if self.fail_sync {
                Err(Error::service(self.chain, "boom"))
            } else {
                Ok(SyncOutcome { chain: self.chain, fetched: self.txs.len(), changed: 1, duration_ms: 3 })
            };
            std::future::ready(r)
        }
        fn transactions(&self) -> impl Future<Output = Result<Vec<Transaction>>> + MaybeSend {
            std::future::ready(Ok(self.txs.clone()))
        }
        fn connect(&self, _c: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend {
            self.calls.lock().unwrap().push("connect".into());
            let r = if self.fail_connect {
                Err(Error::service(self.chain, "no route"))
            } else {
                *self.lifecycle.lock().unwrap() = ServiceLifecycle::Connected;
                Ok(())
            };
            std::future::ready(r)
        }
        fn disconnect(&self) -> impl Future<Output = Result<()>> + MaybeSend {
            self.calls.lock().unwrap().push("disconnect".into());
            std::future::ready(Ok(()))
        }
    }

    fn tx(id: &str, chain: ChainId) -> Transaction {
        Transaction::new(id, chain, TransactionDirection::Incoming, TransactionStatus::Pending, 10, 1, 5)
    }

    fn orch(
        syncers: Vec<FakeSyncer>,
        clock: Arc<FixedClock>,
    ) -> SyncOrchestrator<FakeSyncer, MemoryKv, Arc<FixedClock>> {
        SyncOrchestrator::new(syncers, TransactionStore::new(MemoryKv::new()), SyncConfig::default(), clock)
    }

    #[test]
    fn one_failing_chain_does_not_block_others() {
        block_on(async {
            let mut liquid = FakeSyncer::new(ChainId::Liquid);
            liquid.fail_sync = true;
            let mut btc = FakeSyncer::new(ChainId::Bitcoin);
            btc.txs = vec![tx("b1", ChainId::Bitcoin)];
            let mut o = orch(vec![liquid, btc], Arc::new(FixedClock::new(1_000)));
            let r = o.refresh(SyncStrategy::Light).await;
            let agg = r.outcome.unwrap();
            assert_eq!((agg.chain, agg.fetched), (ChainId::Aggregate, 1));
            assert_eq!(r.events.len(), 1);
            assert_eq!(o.state().phase, SyncPhase::Cooling);
            assert_eq!(o.state().first_synced_chains, BTreeSet::from([ChainId::Bitcoin]));
            assert!(o.state().last_error.is_none());
            assert_eq!(o.store().list(None, None).await.unwrap().len(), 1);
            let phases: Vec<SyncPhase> = o.take_state_changes().iter().map(|s| s.phase).collect();
            assert_eq!(phases.first(), Some(&SyncPhase::Running));
            assert_eq!(phases.last(), Some(&SyncPhase::Cooling));
            // A second refresh with the same data yields no new events.
            assert!(o.refresh(SyncStrategy::Light).await.events.is_empty());
        });
    }

    #[test]
    fn all_operational_failed_is_sync_error() {
        block_on(async {
            let mut a = FakeSyncer::new(ChainId::Liquid);
            a.fail_sync = true;
            let mut b = FakeSyncer::new(ChainId::Bitcoin);
            b.fail_sync = true;
            let mut o = orch(vec![a, b], Arc::new(FixedClock::new(0)));
            let r = o.refresh(SyncStrategy::Light).await;
            match r.outcome {
                Err(Error::Sync { chain, message }) => {
                    assert_eq!(chain, ChainId::Liquid);
                    assert_eq!(message, "all operational services failed: boom");
                }
                other => panic!("unexpected {other:?}"),
            }
            assert!(o.state().last_error.is_some());
            assert!(o.state().first_synced_chains.is_empty());
        });
    }

    #[test]
    fn non_operational_chain_is_skipped_and_no_operational_means_success() {
        block_on(async {
            let a = FakeSyncer::new(ChainId::Liquid);
            *a.lifecycle.lock().unwrap() = ServiceLifecycle::Errored;
            let mut o = orch(vec![a.clone()], Arc::new(FixedClock::new(0)));
            let r = o.refresh(SyncStrategy::Light).await;
            assert!(r.outcome.is_ok(), "Dart: allFailed needs at least one operational service");
            assert!(a.calls.lock().unwrap().is_empty());
            assert!(r.per_chain[0].1.is_err());
        });
    }

    #[test]
    fn start_and_tick_cadence_with_fixed_clock() {
        block_on(async {
            let clock = Arc::new(FixedClock::new(10_000));
            let btc = FakeSyncer::new(ChainId::Bitcoin);
            let mut o = orch(vec![btc.clone()], clock.clone());
            assert!(o.start().await.is_some());
            assert!(o.start().await.is_none(), "start is idempotent");
            assert_eq!(o.next_tick_at_ms(), Some(70_000));
            clock.advance(59_999);
            assert!(o.tick().await.is_none());
            clock.advance(1);
            assert!(o.tick().await.is_some());
            assert_eq!(o.next_tick_at_ms(), Some(130_000));
            // Missed ticks collapse into one refresh.
            clock.set(300_000);
            assert!(o.tick().await.is_some());
            assert!(o.tick().await.is_none());
            assert_eq!(o.next_tick_at_ms(), Some(310_000));
            assert_eq!(btc.calls.lock().unwrap().len(), 3);
            o.stop();
            assert_eq!(o.state().phase, SyncPhase::Stopped);
            assert!(o.state().first_synced_chains.is_empty());
            assert!(o.tick().await.is_none());
        });
    }

    #[test]
    fn reconnect_only_touches_broken_services() {
        block_on(async {
            let good = FakeSyncer::new(ChainId::Liquid);
            let broken = FakeSyncer::new(ChainId::Bitcoin);
            *broken.lifecycle.lock().unwrap() = ServiceLifecycle::Disconnected;
            let mut o = orch(vec![good.clone(), broken.clone()], Arc::new(FixedClock::new(0)));
            let creds = WalletCredentials { mnemonic: "m".into(), network: AppNetwork::Mainnet };
            let r = o.reconnect(&creds).await;
            assert!(r.outcome.is_ok());
            assert_eq!(*broken.calls.lock().unwrap(), ["disconnect", "connect", "sync:60000"]);
            assert_eq!(*good.calls.lock().unwrap(), ["sync:60000"]);
        });
    }

    #[test]
    fn reconnect_fails_when_nothing_recovers() {
        block_on(async {
            let mut a = FakeSyncer::new(ChainId::Liquid);
            a.fail_connect = true;
            *a.lifecycle.lock().unwrap() = ServiceLifecycle::Errored;
            let mut o = orch(vec![a], Arc::new(FixedClock::new(0)));
            let creds = WalletCredentials { mnemonic: "m".into(), network: AppNetwork::Mainnet };
            match o.reconnect(&creds).await.outcome {
                Err(Error::Sync { message, .. }) => assert_eq!(message, "reconnect: no service operational: no route"),
                other => panic!("unexpected {other:?}"),
            }
        });
    }

    #[test]
    fn config_timeouts() {
        let c = SyncConfig::default();
        assert_eq!(c.timeout_for(ChainId::Lightning), 60_000);
        assert_eq!(c.hard_timeout_ms(ChainId::Bitcoin), 65_000);
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod send_checks {
    use super::*;
    use crate::store::NotifiedTxRegistry;
    use crate::sync::notifier::TransactionNotifier;
    use crate::testing::{FixedClock, MemoryKv};

    fn assert_send<T: Send>(_: &T) {}

    /// Futures of the public async API are `Send` on native targets.
    #[allow(dead_code)]
    fn futures_are_send<S: ChainSyncer, B: crate::sync::boot::BootServices>(
        o: &mut SyncOrchestrator<S, MemoryKv, FixedClock>,
        n: &mut TransactionNotifier<MemoryKv>,
        b: &mut crate::sync::boot::BootOrchestrator<B, FixedClock>,
        c: &WalletCredentials,
    ) {
        assert_send(&o.refresh(SyncStrategy::Light));
        assert_send(&o.reconnect(c));
        assert_send(&n.on_events(&[], 0));
        assert_send(&b.start());
        let r = NotifiedTxRegistry::new(MemoryKv::new());
        assert_send(&r.mark_if_new(ChainId::Liquid, "x", 0));
    }
}
