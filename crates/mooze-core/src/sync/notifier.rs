//! Decides which transaction events become "transaction received" notifications.
//!
//! Display is out of scope.
//!
//! Emission needs three gates: baseline ready, home reached, app in foreground.
//! Dedup goes through [`NotifiedTxRegistry`], so a restart never shows a tx twice.

use std::collections::BTreeSet;

use serde::{Deserialize, Serialize};

use crate::domain::{
    Asset, ChainId, Transaction, TransactionDirection, TransactionEvent, TransactionStatus, BTC_ASSET_ID, LBTC_ASSET_ID,
};
use crate::ports::KvStore;
use crate::store::NotifiedTxRegistry;

use super::orchestrator::SyncState;

/// Chains that must finish a first sync before the baseline snapshot.
pub const BASELINE_GATE_CHAINS: [ChainId; 3] = [ChainId::Liquid, ChainId::Bitcoin, ChainId::Lightning];
/// Longest wait for the first sync before the baseline snapshot runs anyway.
pub const FIRST_SYNC_MAX_WAIT_MS: u64 = 90_000;

/// One user-facing notification.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TxNotification {
    pub transaction_id: String,
    pub asset_id: String,
    pub asset_ticker: String,
    /// Credited amount in base units.
    pub amount: i64,
    pub confirmed_at_ms: u64,
}

/// Baseline phase of the notifier.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BaselinePhase {
    /// Live events are buffered until the baseline completes.
    Initializing,
    /// Live events go through the decision path.
    Ready,
}

/// True when every chain in [`BASELINE_GATE_CHAINS`] has synced once.
pub fn first_sync_settled(state: &SyncState) -> bool {
    BASELINE_GATE_CHAINS.iter().all(|c| state.first_synced_chains.contains(c))
}

/// Fallback asset id when the record has none. Bitcoin maps to BTC, Lightning to L-BTC.
pub fn default_asset_id_for_chain(chain: ChainId) -> Option<&'static str> {
    match chain {
        ChainId::Bitcoin => Some(BTC_ASSET_ID),
        ChainId::Lightning => Some(LBTC_ASSET_ID),
        _ => None,
    }
}

/// Ticker for an asset id.
///
/// NOTE: unknown ids fall back to BTC and show "BTC" by design.
pub fn ticker_for(asset_id: &str) -> String {
    Asset::from_id(asset_id).unwrap_or(Asset::Btc).ticker().to_owned()
}

/// Twin chain used to dedup cross-chain copies of one receive across restarts.
fn twin_chain(tx: &Transaction) -> Option<ChainId> {
    match tx.chain {
        ChainId::Lightning => Some(ChainId::Liquid),
        ChainId::Bitcoin => tx.swap_claim_tx_id.as_ref().map(|_| ChainId::Liquid),
        ChainId::Liquid => Some(if tx.swap_claim_tx_id.is_some() { ChainId::Bitcoin } else { ChainId::Lightning }),
        ChainId::Aggregate => None,
    }
}

/// Notification decision state machine.
#[derive(Debug)]
pub struct TransactionNotifier<K: KvStore> {
    registry: NotifiedTxRegistry<K>,
    baseline: BaselinePhase,
    baseline_started_at_ms: Option<u64>,
    home_reached: bool,
    foregrounded: bool,
    imported_at_ms: Option<i64>,
    init_buffer: Vec<TransactionEvent>,
    pending: Vec<TxNotification>,
    emitted_ids: BTreeSet<String>,
}

impl<K: KvStore> TransactionNotifier<K> {
    /// Notifier in the initializing phase, foregrounded, home not reached.
    pub fn new(registry: NotifiedTxRegistry<K>) -> Self {
        Self {
            registry,
            baseline: BaselinePhase::Initializing,
            baseline_started_at_ms: None,
            home_reached: false,
            foregrounded: true,
            imported_at_ms: None,
            init_buffer: Vec::new(),
            pending: Vec::new(),
            emitted_ids: BTreeSet::new(),
        }
    }

    /// Current baseline phase.
    pub fn baseline(&self) -> BaselinePhase {
        self.baseline
    }

    /// Loads the import stamp and baseline flag.
    ///
    /// If the baseline already completed, the notifier becomes ready and
    /// returns notifications from buffered events. Otherwise the platform
    /// must call [`Self::complete_baseline`] when
    /// [`Self::should_complete_baseline`] turns true. Read errors are non-fatal.
    pub async fn init(&mut self, now_ms: u64) -> Vec<TxNotification> {
        self.imported_at_ms = self.registry.imported_at_ms().await.unwrap_or(None);
        let done = self.registry.is_baseline_complete().await.unwrap_or(false);
        if done {
            self.baseline = BaselinePhase::Ready;
            return self.drain_init_buffer(now_ms).await;
        }
        self.baseline_started_at_ms = Some(now_ms);
        Vec::new()
    }

    /// True when the baseline snapshot should run: first sync settled or wait timed out.
    pub fn should_complete_baseline(&self, sync: &SyncState, now_ms: u64) -> bool {
        if self.baseline != BaselinePhase::Initializing {
            return false;
        }
        let Some(started) = self.baseline_started_at_ms else {
            return false;
        };
        first_sync_settled(sync) || now_ms.saturating_sub(started) >= FIRST_SYNC_MAX_WAIT_MS
    }

    /// Absorbs `stored` (the full transaction store) into the ledger without
    /// notifying, sets the baseline flag, then replays buffered events.
    ///
    /// Storage failures do not block readiness.
    pub async fn complete_baseline(&mut self, stored: &[Transaction], now_ms: u64) -> Vec<TxNotification> {
        if self.baseline == BaselinePhase::Ready {
            return Vec::new();
        }
        if !stored.is_empty() {
            let entries: Vec<(ChainId, String)> = stored.iter().map(|t| (t.chain, t.id.clone())).collect();
            let _ = self.registry.bulk_mark(&entries, now_ms).await;
        }
        let _ = self.registry.set_baseline_complete().await;
        self.baseline = BaselinePhase::Ready;
        self.drain_init_buffer(now_ms).await
    }

    async fn drain_init_buffer(&mut self, now_ms: u64) -> Vec<TxNotification> {
        let buffered = std::mem::take(&mut self.init_buffer);
        let mut out = Vec::new();
        for e in &buffered {
            out.extend(self.process_event(e, now_ms).await);
        }
        out
    }

    /// Handles store change events. Returns notifications to show now.
    ///
    /// Events buffer while the baseline initializes.
    pub async fn on_events(&mut self, events: &[TransactionEvent], now_ms: u64) -> Vec<TxNotification> {
        if self.baseline == BaselinePhase::Initializing {
            self.init_buffer.extend_from_slice(events);
            return Vec::new();
        }
        let mut out = Vec::new();
        for e in events {
            out.extend(self.process_event(e, now_ms).await);
        }
        out
    }

    /// Marks that the user reached home. Sticky. Returns released notifications.
    pub fn set_home_reached(&mut self) -> Vec<TxNotification> {
        if self.home_reached {
            return Vec::new();
        }
        self.home_reached = true;
        self.flush_pending()
    }

    /// Sets the foreground gate. Returns released notifications.
    pub fn set_foregrounded(&mut self, foregrounded: bool) -> Vec<TxNotification> {
        if self.foregrounded == foregrounded {
            return Vec::new();
        }
        self.foregrounded = foregrounded;
        if foregrounded {
            self.flush_pending()
        } else {
            Vec::new()
        }
    }

    /// Notifications held by the home or foreground gate.
    pub fn pending(&self) -> &[TxNotification] {
        &self.pending
    }

    fn can_emit_now(&self) -> bool {
        self.home_reached && self.foregrounded
    }

    fn flush_pending(&mut self) -> Vec<TxNotification> {
        if !self.can_emit_now() {
            return Vec::new();
        }
        std::mem::take(&mut self.pending)
    }

    async fn process_event(&mut self, event: &TransactionEvent, now_ms: u64) -> Option<TxNotification> {
        let tx = &event.transaction;
        let is_plain_receive = matches!(tx.direction, TransactionDirection::Incoming | TransactionDirection::Internal);
        let is_swap = tx.direction == TransactionDirection::Swap;
        if !is_plain_receive && !is_swap {
            return None;
        }
        if tx.status != TransactionStatus::Confirmed {
            return None;
        }
        // Persisted dedup. A storage failure counts as "already seen".
        if !self.registry.mark_if_new(tx.chain, &tx.id, now_ms).await.unwrap_or(false) {
            return None;
        }
        // Wallet history restored after import never notifies.
        if let Some(imported) = self.imported_at_ms {
            if (tx.timestamp_ms as i64) < imported {
                return None;
            }
        }
        let (asset_id, amount) = if is_swap {
            match (&tx.to_asset_id, tx.received_amount_sat) {
                (Some(a), Some(r)) if r > 0 => (a.clone(), r),
                _ => return None,
            }
        } else {
            let asset = tx.asset_id.clone().or_else(|| default_asset_id_for_chain(tx.chain).map(str::to_owned))?;
            (asset, tx.amount_sat)
        };
        let note = TxNotification {
            transaction_id: tx.id.clone(),
            asset_ticker: ticker_for(&asset_id),
            asset_id,
            amount,
            confirmed_at_ms: event.observed_at_ms,
        };

        // In-process cross-chain dedup (Breez lightning + LWK claim leg).
        let correlation = tx.swap_claim_tx_id.clone().unwrap_or_else(|| tx.id.clone());
        if !self.emitted_ids.insert(correlation.clone()) {
            return None;
        }
        if let Some(twin) = twin_chain(tx) {
            // Best-effort: the result is ignored.
            let _ = self.registry.mark_if_new(twin, &correlation, now_ms).await;
        }

        if self.can_emit_now() {
            Some(note)
        } else {
            self.pending.push(note);
            None
        }
    }

    /// Registry used for dedup.
    pub fn registry(&self) -> &NotifiedTxRegistry<K> {
        &self.registry
    }

    /// Clears volatile state.
    pub fn dispose(&mut self) {
        self.init_buffer.clear();
        self.pending.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{TransactionEventKind, USDT_ASSET_ID};
    use crate::testing::{block_on, MemoryKv};

    fn confirmed(id: &str, chain: ChainId, dir: TransactionDirection, ts: u64) -> Transaction {
        let mut t = Transaction::new(id, chain, dir, TransactionStatus::Confirmed, 5000, 10, ts);
        t.confirmations = 1;
        t
    }

    fn ev(tx: Transaction) -> TransactionEvent {
        TransactionEvent::diff(None, &tx, 777).unwrap()
    }

    async fn ready_notifier(kv: MemoryKv) -> TransactionNotifier<MemoryKv> {
        let reg = NotifiedTxRegistry::new(kv);
        reg.set_baseline_complete().await.unwrap();
        let mut n = TransactionNotifier::new(reg);
        n.init(0).await;
        n.set_home_reached();
        n
    }

    #[test]
    fn baseline_absorbs_history_and_buffers_live_events() {
        block_on(async {
            let mut n = TransactionNotifier::new(NotifiedTxRegistry::new(MemoryKv::new()));
            assert!(n.init(1_000).await.is_empty());
            n.set_home_reached();
            let old = confirmed("old", ChainId::Bitcoin, TransactionDirection::Incoming, 1);
            let new = confirmed("new", ChainId::Bitcoin, TransactionDirection::Incoming, 2);
            assert!(n.on_events(&[ev(old.clone()), ev(new.clone())], 1_100).await.is_empty());

            let mut sync = SyncState::default();
            assert!(!n.should_complete_baseline(&sync, 1_500));
            sync.first_synced_chains.extend(BASELINE_GATE_CHAINS);
            assert!(n.should_complete_baseline(&sync, 1_500));

            // Only "old" is in the store snapshot; "new" arrived live.
            let out = n.complete_baseline(&[old], 2_000).await;
            assert_eq!(out.len(), 1);
            assert_eq!(out[0].transaction_id, "new");
            assert_eq!(out[0].asset_id, BTC_ASSET_ID);
            assert_eq!(out[0].asset_ticker, "BTC");
            assert_eq!(out[0].confirmed_at_ms, 777);
            assert_eq!(n.baseline(), BaselinePhase::Ready);
            assert!(n.registry().is_baseline_complete().await.unwrap());
        });
    }

    #[test]
    fn baseline_wait_times_out() {
        block_on(async {
            let mut n = TransactionNotifier::new(NotifiedTxRegistry::new(MemoryKv::new()));
            n.init(0).await;
            let s = SyncState::default();
            assert!(!n.should_complete_baseline(&s, FIRST_SYNC_MAX_WAIT_MS - 1));
            assert!(n.should_complete_baseline(&s, FIRST_SYNC_MAX_WAIT_MS));
        });
    }

    #[test]
    fn dedup_across_restarts_and_filters() {
        block_on(async {
            let kv = MemoryKv::new();
            let mut n = ready_notifier(kv.clone()).await;
            let rx = confirmed("a", ChainId::Liquid, TransactionDirection::Incoming, 5);
            let mut rx_with_asset = rx.clone();
            rx_with_asset.asset_id = Some(USDT_ASSET_ID.into());
            assert_eq!(n.on_events(&[ev(rx_with_asset.clone())], 1).await[0].asset_ticker, "USDT");
            assert!(n.on_events(&[ev(rx_with_asset.clone())], 2).await.is_empty());

            // New process, same storage: no repeat.
            let mut n2 = ready_notifier(kv).await;
            assert!(n2.on_events(&[ev(rx_with_asset)], 3).await.is_empty());

            // Outgoing, pending, and liquid without asset id never notify.
            let out = confirmed("o", ChainId::Liquid, TransactionDirection::Outgoing, 5);
            let mut pend = confirmed("p", ChainId::Bitcoin, TransactionDirection::Incoming, 5);
            pend.status = TransactionStatus::Pending;
            let no_asset = confirmed("n", ChainId::Liquid, TransactionDirection::Incoming, 5);
            assert!(n2.on_events(&[ev(out), ev(pend), ev(no_asset)], 4).await.is_empty());
        });
    }

    #[test]
    fn swap_uses_credit_leg_and_drops_malformed() {
        block_on(async {
            let mut n = ready_notifier(MemoryKv::new()).await;
            let mut s = confirmed("s", ChainId::Liquid, TransactionDirection::Swap, 5);
            s.to_asset_id = Some(LBTC_ASSET_ID.into());
            s.received_amount_sat = Some(1234);
            let out = n.on_events(&[ev(s)], 1).await;
            assert_eq!((out[0].amount, out[0].asset_ticker.as_str()), (1234, "BTC L2"));
            let mut bad = confirmed("bad", ChainId::Liquid, TransactionDirection::Swap, 5);
            bad.to_asset_id = Some(LBTC_ASSET_ID.into());
            bad.received_amount_sat = Some(0);
            assert!(n.on_events(&[ev(bad)], 1).await.is_empty());
        });
    }

    #[test]
    fn import_stamp_drops_history() {
        block_on(async {
            let reg = NotifiedTxRegistry::new(MemoryKv::new());
            reg.set_baseline_complete().await.unwrap();
            reg.set_imported_at_ms(100).await.unwrap();
            let mut n = TransactionNotifier::new(reg);
            n.init(0).await;
            n.set_home_reached();
            let before = confirmed("b", ChainId::Bitcoin, TransactionDirection::Incoming, 99);
            let after = confirmed("c", ChainId::Bitcoin, TransactionDirection::Incoming, 100);
            let out = n.on_events(&[ev(before), ev(after)], 1).await;
            assert_eq!(out.iter().map(|o| o.transaction_id.as_str()).collect::<Vec<_>>(), ["c"]);
            assert!(n.registry().contains(ChainId::Bitcoin, "b").await.unwrap());
        });
    }

    #[test]
    fn home_and_foreground_gates_hold_then_release() {
        block_on(async {
            let reg = NotifiedTxRegistry::new(MemoryKv::new());
            reg.set_baseline_complete().await.unwrap();
            let mut n = TransactionNotifier::new(reg);
            n.init(0).await;
            let t = confirmed("g", ChainId::Bitcoin, TransactionDirection::Incoming, 5);
            assert!(n.on_events(&[ev(t)], 1).await.is_empty());
            assert_eq!(n.pending().len(), 1);
            assert!(n.set_foregrounded(false).is_empty());
            assert!(n.set_home_reached().is_empty(), "still backgrounded");
            let released = n.set_foregrounded(true);
            assert_eq!(released.len(), 1);
            assert!(n.pending().is_empty());
            assert!(n.set_home_reached().is_empty());
        });
    }

    #[test]
    fn cross_chain_twin_is_deduped() {
        block_on(async {
            let kv = MemoryKv::new();
            let mut n = ready_notifier(kv.clone()).await;
            let ln = confirmed("x", ChainId::Lightning, TransactionDirection::Incoming, 5);
            let mut lq = confirmed("x", ChainId::Liquid, TransactionDirection::Incoming, 5);
            lq.asset_id = Some(LBTC_ASSET_ID.into());
            let out = n.on_events(&[ev(ln)], 1).await;
            assert_eq!(out[0].asset_id, LBTC_ASSET_ID);
            assert!(n.on_events(&[ev(lq.clone())], 2).await.is_empty());
            // The twin row was persisted, so a new process also drops it.
            let mut n2 = ready_notifier(kv).await;
            assert!(n2.on_events(&[ev(lq)], 3).await.is_empty());
        });
    }

    #[test]
    fn status_change_event_notifies() {
        block_on(async {
            let mut n = ready_notifier(MemoryKv::new()).await;
            let mut p = confirmed("s", ChainId::Bitcoin, TransactionDirection::Internal, 5);
            p.status = TransactionStatus::Pending;
            let c = confirmed("s", ChainId::Bitcoin, TransactionDirection::Internal, 5);
            let e = TransactionEvent::diff(Some(&p), &c, 9).unwrap();
            assert_eq!(e.kind, TransactionEventKind::StatusChanged);
            assert_eq!(n.on_events(&[e], 9).await.len(), 1);
        });
    }
}
