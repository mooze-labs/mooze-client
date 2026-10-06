//! Persisted transactions for every chain.
//!
//! [`TransactionStore::upsert_all`] returns change events. The store has no watch stream.

use crate::domain::{ChainFilter, ChainId, Transaction, TransactionEvent, TransactionSource};
use crate::ports::KvStore;
use crate::Result;

use super::json::{delete_prefix, get_json, list_json, put_json};

/// Key prefix of every transaction row.
pub const TX_PREFIX: &str = "tx/";

/// Real chains in lookup order for [`TransactionStore::find_by_id`].
const LOOKUP_CHAINS: [ChainId; 3] = [ChainId::Liquid, ChainId::Bitcoin, ChainId::Lightning];

/// Key of one row. The composite key is `(id, chain)`.
pub fn tx_key(chain: ChainId, id: &str) -> String {
    format!("{TX_PREFIX}{}/{id}", chain.as_str())
}

/// Merges an incoming write into the stored row with source-aware rules.
///
/// - Authoritative fields (direction, status, amounts, fee, confirmations,
///   asset id, timestamp) stay locked once LWK wrote the row, unless LWK writes again.
/// - Metadata fields use `COALESCE(incoming, existing)`.
/// - `source` moves monotonically toward `lwk`.
pub fn merge_transaction(existing: Option<&Transaction>, incoming: &Transaction) -> Transaction {
    let Some(old) = existing else {
        return incoming.clone();
    };
    let old_lwk = old.source == Some(TransactionSource::Lwk);
    let new_lwk = incoming.source == Some(TransactionSource::Lwk);
    // NOTE: A write without a source does not lock, so it overwrites an LWK row.
    // This is intentional.
    let locked = old_lwk && incoming.source.is_some() && !new_lwk;
    let source = if new_lwk || old_lwk { Some(TransactionSource::Lwk) } else { incoming.source };
    let auth = if locked { old } else { incoming };
    Transaction {
        id: incoming.id.clone(),
        chain: incoming.chain,
        direction: auth.direction,
        status: auth.status,
        amount_sat: auth.amount_sat,
        fee_sat: auth.fee_sat,
        timestamp_ms: auth.timestamp_ms,
        confirmations: auth.confirmations,
        asset_id: auth.asset_id.clone(),
        address: incoming.address.clone().or_else(|| old.address.clone()),
        label: incoming.label.clone().or_else(|| old.label.clone()),
        from_asset_id: incoming.from_asset_id.clone().or_else(|| old.from_asset_id.clone()),
        to_asset_id: incoming.to_asset_id.clone().or_else(|| old.to_asset_id.clone()),
        sent_amount_sat: incoming.sent_amount_sat.or(old.sent_amount_sat),
        received_amount_sat: incoming.received_amount_sat.or(old.received_amount_sat),
        source,
        swap_lockup_tx_id: incoming.swap_lockup_tx_id.clone().or_else(|| old.swap_lockup_tx_id.clone()),
        swap_claim_tx_id: incoming.swap_claim_tx_id.clone().or_else(|| old.swap_claim_tx_id.clone()),
        breez_swap_id: incoming.breez_swap_id.clone().or_else(|| old.breez_swap_id.clone()),
    }
}

/// Single source of truth for persisted transactions across all chains.
#[derive(Debug, Clone)]
pub struct TransactionStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> TransactionStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Underlying key-value store.
    pub fn kv(&self) -> &K {
        &self.kv
    }

    /// Upserts one transaction. Returns the change event, if any.
    pub async fn upsert(&self, tx: &Transaction, now_ms: u64) -> Result<Option<TransactionEvent>> {
        Ok(self.upsert_all(std::slice::from_ref(tx), now_ms).await?.into_iter().next())
    }

    /// Upserts a batch with the merge rules of [`merge_transaction`].
    ///
    /// Returns one [`TransactionEvent`] per row that was created or changed
    /// status or confirmations, in input order.
    pub async fn upsert_all(&self, txs: &[Transaction], now_ms: u64) -> Result<Vec<TransactionEvent>> {
        let mut events = Vec::new();
        for tx in txs {
            let key = tx_key(tx.chain, &tx.id);
            let previous: Option<Transaction> = get_json(&self.kv, &key).await?;
            let merged = merge_transaction(previous.as_ref(), tx);
            if previous.as_ref() != Some(&merged) {
                put_json(&self.kv, &key, &merged).await?;
            }
            if let Some(ev) = TransactionEvent::diff(previous.as_ref(), &merged, now_ms) {
                events.push(ev);
            }
        }
        Ok(events)
    }

    /// Finds a row by id on any chain.
    ///
    /// NOTE: If the id exists on more than one chain, the first match wins.
    /// The lookup order is liquid, bitcoin, then lightning.
    pub async fn find_by_id(&self, id: &str) -> Result<Option<Transaction>> {
        for chain in LOOKUP_CHAINS {
            if let Some(tx) = get_json(&self.kv, &tx_key(chain, id)).await? {
                return Ok(Some(tx));
            }
        }
        Ok(None)
    }

    /// Finds a row by its composite key.
    pub async fn find(&self, chain: ChainId, id: &str) -> Result<Option<Transaction>> {
        get_json(&self.kv, &tx_key(chain, id)).await
    }

    /// Lists rows, newest first (`ORDER BY timestamp_ms DESC`).
    ///
    /// `filter` keeps only the chains it contains. `limit` caps the count.
    pub async fn list(&self, filter: Option<&ChainFilter>, limit: Option<usize>) -> Result<Vec<Transaction>> {
        let rows: Vec<(String, Transaction)> = list_json(&self.kv, TX_PREFIX).await?;
        let mut txs: Vec<Transaction> =
            rows.into_iter().map(|(_, t)| t).filter(|t| filter.is_none_or(|f| f.matches(t.chain))).collect();
        // Stable sort: ties keep ascending key order.
        txs.sort_by_key(|x| std::cmp::Reverse(x.timestamp_ms));
        if let Some(n) = limit {
            txs.truncate(n);
        }
        Ok(txs)
    }

    /// Deletes every transaction row.
    pub async fn delete_all(&self) -> Result<()> {
        delete_prefix(&self.kv, TX_PREFIX).await.map(|_| ())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{TransactionDirection, TransactionEventKind, TransactionStatus};
    use crate::testing::{block_on, MemoryKv};

    fn tx(id: &str, chain: ChainId, ts: u64) -> Transaction {
        Transaction::new(id, chain, TransactionDirection::Incoming, TransactionStatus::Pending, 1000, 10, ts)
    }

    #[test]
    fn list_orders_newest_first_with_filter_and_limit() {
        block_on(async {
            let store = TransactionStore::new(MemoryKv::new());
            store
                .upsert_all(
                    &[tx("a", ChainId::Liquid, 100), tx("b", ChainId::Bitcoin, 300), tx("c", ChainId::Liquid, 200)],
                    1,
                )
                .await
                .unwrap();
            let all = store.list(None, None).await.unwrap();
            assert_eq!(all.iter().map(|t| t.id.as_str()).collect::<Vec<_>>(), ["b", "c", "a"]);
            let liquid = store.list(Some(&ChainFilter::only(ChainId::Liquid)), Some(1)).await.unwrap();
            assert_eq!(liquid.len(), 1);
            assert_eq!(liquid[0].id, "c");
        });
    }

    #[test]
    fn upsert_emits_created_then_status_then_nothing() {
        block_on(async {
            let store = TransactionStore::new(MemoryKv::new());
            let t = tx("a", ChainId::Liquid, 100);
            let ev = store.upsert(&t, 5).await.unwrap().unwrap();
            assert_eq!(ev.kind, TransactionEventKind::Created);
            assert_eq!(ev.observed_at_ms, 5);
            assert!(store.upsert(&t, 6).await.unwrap().is_none());
            let mut c = t.clone();
            c.status = TransactionStatus::Confirmed;
            c.confirmations = 1;
            let ev = store.upsert(&c, 7).await.unwrap().unwrap();
            assert_eq!(ev.kind, TransactionEventKind::StatusChanged);
            assert_eq!(ev.previous_status, Some(TransactionStatus::Pending));
            let mut d = c.clone();
            d.confirmations = 2;
            let ev = store.upsert(&d, 8).await.unwrap().unwrap();
            assert_eq!(ev.kind, TransactionEventKind::ConfirmationsChanged);
        });
    }

    #[test]
    fn same_id_on_two_chains_are_two_rows() {
        block_on(async {
            let store = TransactionStore::new(MemoryKv::new());
            let evs =
                store.upsert_all(&[tx("x", ChainId::Liquid, 1), tx("x", ChainId::Lightning, 2)], 0).await.unwrap();
            assert_eq!(evs.len(), 2);
            assert_eq!(store.list(None, None).await.unwrap().len(), 2);
            assert_eq!(store.find_by_id("x").await.unwrap().unwrap().chain, ChainId::Liquid);
            assert!(store.find_by_id("nope").await.unwrap().is_none());
        });
    }

    #[test]
    fn lwk_locks_authoritative_fields_but_metadata_coalesces() {
        block_on(async {
            let store = TransactionStore::new(MemoryKv::new());
            let mut lwk = tx("a", ChainId::Liquid, 100);
            lwk.source = Some(TransactionSource::Lwk);
            lwk.amount_sat = 500;
            lwk.label = Some("mine".into());
            store.upsert(&lwk, 0).await.unwrap();

            let mut breez = tx("a", ChainId::Liquid, 999);
            breez.source = Some(TransactionSource::Breez);
            breez.amount_sat = 777;
            breez.status = TransactionStatus::Confirmed;
            breez.address = Some("addr".into());
            breez.breez_swap_id = Some("sw".into());
            let evs = store.upsert_all(&[breez], 1).await.unwrap();
            assert!(evs.is_empty(), "locked status must not produce an event");

            let row = store.find(ChainId::Liquid, "a").await.unwrap().unwrap();
            assert_eq!(row.amount_sat, 500);
            assert_eq!(row.timestamp_ms, 100);
            assert_eq!(row.status, TransactionStatus::Pending);
            assert_eq!(row.source, Some(TransactionSource::Lwk));
            assert_eq!(row.label.as_deref(), Some("mine"));
            assert_eq!(row.address.as_deref(), Some("addr"));
            assert_eq!(row.breez_swap_id.as_deref(), Some("sw"));
        });
    }

    #[test]
    fn non_lwk_rows_take_newer_write_and_null_source_overrides_lwk() {
        let mut a = tx("a", ChainId::Liquid, 1);
        a.source = Some(TransactionSource::Breez);
        let mut b = tx("a", ChainId::Liquid, 2);
        b.source = Some(TransactionSource::Bdk);
        b.amount_sat = 42;
        let m = merge_transaction(Some(&a), &b);
        assert_eq!(m.amount_sat, 42);
        assert_eq!(m.source, Some(TransactionSource::Bdk));

        let mut lwk = a.clone();
        lwk.source = Some(TransactionSource::Lwk);
        let mut none = b.clone();
        none.source = None;
        let m = merge_transaction(Some(&lwk), &none);
        assert_eq!(m.amount_sat, 42);
        assert_eq!(m.source, Some(TransactionSource::Lwk));
    }

    #[test]
    fn delete_all_wipes_rows() {
        block_on(async {
            let kv = MemoryKv::new();
            kv.put("other", vec![1]).await.unwrap();
            let store = TransactionStore::new(kv.clone());
            store.upsert(&tx("a", ChainId::Bitcoin, 1), 0).await.unwrap();
            store.delete_all().await.unwrap();
            assert!(store.list(None, None).await.unwrap().is_empty());
            assert_eq!(kv.len(), 1);
        });
    }
}
