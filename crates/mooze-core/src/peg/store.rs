//! Peg persistence over [`KvStore`].
//!
//! One JSON record per order at `peg/<wallet_id>/<order_id>`. Fields match
//! the legacy Drift `Pegs` table of the Flutter app database.

use std::future::{ready, Future};

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use super::entities::{PegDirection, PegOrder, PegPhase};
use super::orchestrator::PegStore;
use super::tracker::{PegRecoverySource, TrackedPeg};
use crate::ports::{Clock, KvStore, MaybeSend, MaybeSync};
use crate::{Error, Result};

/// Status of an open peg.
pub const PEG_STATUS_PENDING: &str = "pending";
/// Status of a completed peg.
pub const PEG_STATUS_COMPLETED: &str = "completed";
/// Status of a failed peg.
pub const PEG_STATUS_FAILED: &str = "failed";
/// Status of an under-funded peg.
pub const PEG_STATUS_INSUFFICIENT_AMOUNT: &str = "insufficient_amount";
/// Provider name stored on every record.
pub const PEG_PROVIDER: &str = "sideswap";

/// Stored status string for a phase. Non-terminal phases are pending.
pub fn status_for(phase: PegPhase) -> &'static str {
    match phase {
        PegPhase::Completed => PEG_STATUS_COMPLETED,
        PegPhase::InsufficientAmount => PEG_STATUS_INSUFFICIENT_AMOUNT,
        PegPhase::Failed => PEG_STATUS_FAILED,
        _ => PEG_STATUS_PENDING,
    }
}

/// One persisted peg. Matches a legacy Drift `Pegs` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegRecord {
    pub order_id: String,
    pub peg_in: bool,
    /// SideSwap deposit address.
    pub sideswap_address: String,
    pub payout_address: String,
    pub amount: u64,
    pub created_at_ms: u64,
    pub wallet_id: String,
    pub status: String,
    pub provider: String,
    #[serde(default)]
    pub funding_tx_id: Option<String>,
    #[serde(default)]
    pub payout_tx_id: Option<String>,
    #[serde(default)]
    pub error_message: Option<String>,
    #[serde(default)]
    pub updated_at_ms: Option<u64>,
    #[serde(default)]
    pub metadata: Option<Value>,
}

impl PegRecord {
    /// Direction of the record.
    pub fn direction(&self) -> PegDirection {
        PegDirection::from_peg_in_flag(self.peg_in)
    }

    /// Resume state: awaiting deposit until funded, detected after.
    pub fn to_tracked(&self) -> TrackedPeg {
        TrackedPeg {
            order_id: self.order_id.clone(),
            direction: self.direction(),
            phase: if self.funding_tx_id.is_none() { PegPhase::AwaitingDeposit } else { PegPhase::Detected },
            amount_sat: self.amount,
            deposit_address: self.sideswap_address.clone(),
            funding_tx_id: self.funding_tx_id.clone(),
            payout_tx_id: self.payout_tx_id.clone(),
            confirmations: None,
            required_confirmations: None,
            error_message: None,
        }
    }
}

/// Swap history entry written when a peg is created.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PendingSwapAudit {
    pub provider: String,
    pub direction: String,
    pub send_asset: String,
    pub receive_asset: String,
    pub send_amount: u64,
    pub receive_amount: u64,
    pub tx_id: Option<String>,
    pub metadata: Value,
}

impl PendingSwapAudit {
    /// Audit entry for a new peg order, as `DriftPegStore._recordAudit`.
    pub fn for_peg(order: &PegOrder, amount_sat: u64) -> Self {
        let peg_in = order.direction.is_peg_in();
        Self {
            provider: PEG_PROVIDER.to_owned(),
            direction: order.direction.audit_direction().to_owned(),
            send_asset: if peg_in { "BTC" } else { "LBTC" }.to_owned(),
            receive_asset: if peg_in { "LBTC" } else { "BTC" }.to_owned(),
            send_amount: amount_sat,
            receive_amount: amount_sat,
            tx_id: None,
            metadata: json!({
                "orderId": order.order_id,
                "depositAddress": order.deposit_address,
                "payoutAddress": order.payout_address,
            }),
        }
    }
}

/// Swap history sink (`SwapAuditRepository.recordPending`). Best-effort.
pub trait SwapAudit: MaybeSend + MaybeSync {
    /// Records a pending swap.
    fn record_pending(&self, entry: PendingSwapAudit) -> impl Future<Output = Result<()>> + MaybeSend;
}

/// [`SwapAudit`] that records nothing.
#[derive(Debug, Clone, Copy, Default)]
pub struct NoAudit;

impl SwapAudit for NoAudit {
    fn record_pending(&self, _entry: PendingSwapAudit) -> impl Future<Output = Result<()>> + MaybeSend {
        ready(Ok(()))
    }
}

/// [`PegStore`] and [`PegRecoverySource`] over a [`KvStore`], scoped by wallet.
#[derive(Debug)]
pub struct KvPegStore<K, T, A = NoAudit> {
    kv: K,
    clock: T,
    wallet_id: String,
    audit: A,
}

impl<K: KvStore, T: Clock> KvPegStore<K, T, NoAudit> {
    /// Store for `wallet_id` without audit.
    pub fn new(kv: K, clock: T, wallet_id: impl Into<String>) -> Self {
        Self { kv, clock, wallet_id: wallet_id.into(), audit: NoAudit }
    }
}

impl<K: KvStore, T: Clock, A: SwapAudit> KvPegStore<K, T, A> {
    /// Adds an audit sink.
    pub fn with_audit<B: SwapAudit>(self, audit: B) -> KvPegStore<K, T, B> {
        KvPegStore { kv: self.kv, clock: self.clock, wallet_id: self.wallet_id, audit }
    }

    fn prefix(&self) -> String {
        format!("peg/{}/", self.wallet_id)
    }

    fn key(&self, order_id: &str) -> String {
        format!("{}{order_id}", self.prefix())
    }

    /// Reads one record.
    pub async fn get(&self, order_id: &str) -> Result<Option<PegRecord>> {
        match self.kv.get(&self.key(order_id)).await? {
            Some(bytes) => serde_json::from_slice(&bytes).map(Some).map_err(Error::storage),
            None => Ok(None),
        }
    }

    async fn put(&self, rec: &PegRecord) -> Result<()> {
        let bytes = serde_json::to_vec(rec).map_err(Error::storage)?;
        self.kv.put(&self.key(&rec.order_id), bytes).await
    }

    /// Writes an existing record unchanged, for a data migration.
    /// Replaces a record with the same order id. The record must belong
    /// to this store's wallet.
    pub async fn import(&self, rec: &PegRecord) -> Result<()> {
        if rec.wallet_id != self.wallet_id {
            return Err(Error::invalid(format!(
                "peg {} belongs to wallet {}, not {}",
                rec.order_id, rec.wallet_id, self.wallet_id
            )));
        }
        self.put(rec).await
    }

    /// Every record of the wallet, oldest first.
    pub async fn list(&self) -> Result<Vec<PegRecord>> {
        let mut out = Vec::new();
        for key in self.kv.list_keys(&self.prefix()).await? {
            if let Some(bytes) = self.kv.get(&key).await? {
                out.push(serde_json::from_slice::<PegRecord>(&bytes).map_err(Error::storage)?);
            }
        }
        out.sort_by_key(|r| r.created_at_ms);
        Ok(out)
    }

    /// Sets only the given fields. No-op if absent.
    async fn update(
        &self,
        order_id: &str,
        status: Option<&str>,
        funding_tx_id: Option<&str>,
        payout_tx_id: Option<&str>,
        error_message: Option<&str>,
    ) -> Result<()> {
        let Some(mut rec) = self.get(order_id).await? else { return Ok(()) };
        if let Some(s) = status {
            rec.status = s.to_owned();
        }
        if let Some(f) = funding_tx_id {
            rec.funding_tx_id = Some(f.to_owned());
        }
        if let Some(p) = payout_tx_id {
            rec.payout_tx_id = Some(p.to_owned());
        }
        if let Some(e) = error_message {
            rec.error_message = Some(e.to_owned());
        }
        rec.updated_at_ms = Some(self.clock.now_ms());
        self.put(&rec).await
    }
}

impl<K: KvStore, T: Clock, A: SwapAudit> PegStore for KvPegStore<K, T, A> {
    async fn record_created(&self, order: &PegOrder, amount_sat: u64) -> Result<()> {
        // Idempotent: a reconciled create must not write a second row.
        if self.get(&order.order_id).await?.is_some() {
            return Ok(());
        }
        let now = self.clock.now_ms();
        let rec = PegRecord {
            order_id: order.order_id.clone(),
            peg_in: order.direction.is_peg_in(),
            sideswap_address: order.deposit_address.clone(),
            payout_address: order.payout_address.clone(),
            amount: amount_sat,
            created_at_ms: now,
            wallet_id: self.wallet_id.clone(),
            status: PEG_STATUS_PENDING.to_owned(),
            provider: PEG_PROVIDER.to_owned(),
            funding_tx_id: None,
            payout_tx_id: None,
            error_message: None,
            updated_at_ms: Some(now),
            metadata: None,
        };
        self.put(&rec).await?;
        // History annotation is never worth failing a peg over.
        let _ = self.audit.record_pending(PendingSwapAudit::for_peg(order, amount_sat)).await;
        Ok(())
    }

    async fn record_funded(&self, order_id: &str, funding_tx_id: &str) -> Result<()> {
        self.update(order_id, None, Some(funding_tx_id), None, None).await
    }

    async fn record_terminal(
        &self,
        order_id: &str,
        phase: PegPhase,
        payout_tx_id: Option<&str>,
        error_message: Option<&str>,
    ) -> Result<()> {
        self.update(order_id, Some(status_for(phase)), None, payout_tx_id, error_message).await
    }
}

impl<K: KvStore, T: Clock, A: SwapAudit> PegRecoverySource for KvPegStore<K, T, A> {
    async fn load_active_pegs(&self) -> Result<Vec<TrackedPeg>> {
        Ok(self.list().await?.iter().filter(|r| r.status == PEG_STATUS_PENDING).map(PegRecord::to_tracked).collect())
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use std::sync::{Arc, Mutex};

    use super::*;
    use crate::testing::{block_on, FixedClock, MemoryKv};

    fn order(id: &str, direction: PegDirection) -> PegOrder {
        PegOrder {
            order_id: id.into(),
            direction,
            deposit_address: "dep".into(),
            payout_address: "pay".into(),
            created_at_ms: 0,
            expires_at_ms: None,
        }
    }

    #[derive(Default, Clone)]
    struct RecAudit(Arc<Mutex<Vec<PendingSwapAudit>>>);

    impl SwapAudit for RecAudit {
        fn record_pending(&self, entry: PendingSwapAudit) -> impl Future<Output = Result<()>> + MaybeSend {
            self.0.lock().unwrap().push(entry);
            ready(Err(Error::Storage("audit down".into())))
        }
    }

    #[test]
    fn roundtrip_and_lifecycle() {
        let kv = MemoryKv::new();
        let clock = Arc::new(FixedClock::new(1_000));
        let audit = RecAudit::default();
        let store = KvPegStore::new(kv.clone(), clock.clone(), "w1").with_audit(audit.clone());
        block_on(async {
            store.record_created(&order("b", PegDirection::PegOut), 30_000).await.unwrap();
            clock.advance(10);
            store.record_created(&order("a", PegDirection::PegIn), 50_000).await.unwrap();
            // Idempotent.
            store.record_created(&order("a", PegDirection::PegIn), 99).await.unwrap();
            assert_eq!(store.get("a").await.unwrap().unwrap().amount, 50_000);

            let active = store.load_active_pegs().await.unwrap();
            assert_eq!(active.iter().map(|p| p.order_id.as_str()).collect::<Vec<_>>(), ["b", "a"]);
            assert_eq!(active[0].phase, PegPhase::AwaitingDeposit);

            store.record_funded("b", "lwk-txid").await.unwrap();
            let active = store.load_active_pegs().await.unwrap();
            assert_eq!((active[0].phase, active[0].funding_tx_id.as_deref()), (PegPhase::Detected, Some("lwk-txid")));

            clock.advance(5);
            store.record_terminal("b", PegPhase::Completed, Some("btc-payout"), None).await.unwrap();
            let b = store.get("b").await.unwrap().unwrap();
            assert_eq!((b.status.as_str(), b.payout_tx_id.as_deref()), ("completed", Some("btc-payout")));
            assert_eq!(b.funding_tx_id.as_deref(), Some("lwk-txid"));
            assert_eq!(b.updated_at_ms, Some(1_015));
            store.record_terminal("a", PegPhase::InsufficientAmount, None, Some("x")).await.unwrap();
            assert!(store.load_active_pegs().await.unwrap().is_empty());
            // Unknown order is a no-op.
            store.record_funded("zzz", "t").await.unwrap();
            assert!(store.get("zzz").await.unwrap().is_none());
        });
        // Audit failure is swallowed; one entry per new order.
        let entries = audit.0.lock().unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!((entries[1].direction.as_str(), entries[1].send_asset.as_str()), ("btc_to_lbtc", "BTC"));
        assert_eq!(entries[0].metadata["orderId"], "b");
        // Other wallets are isolated.
        let other = KvPegStore::new(kv, clock, "w2");
        assert!(block_on(other.list()).unwrap().is_empty());
    }

    #[test]
    fn corrupt_record_is_storage_error() {
        let kv = MemoryKv::new();
        block_on(kv.put("peg/w/x", b"not json".to_vec())).unwrap();
        let store = KvPegStore::new(kv, FixedClock::new(0), "w");
        assert!(matches!(block_on(store.get("x")), Err(Error::Storage(_))));
    }

    #[test]
    fn status_strings() {
        assert_eq!(status_for(PegPhase::Failed), "failed");
        assert_eq!(status_for(PegPhase::InsufficientAmount), "insufficient_amount");
        assert_eq!(status_for(PegPhase::Processing), "pending");
    }
}
