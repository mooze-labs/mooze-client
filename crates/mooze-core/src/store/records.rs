//! App database records.
//!
//! Pegs, deposits and favorite payers live in their feature modules
//! (`peg::store`, `pix::store`). This module keeps the tables without one.
//!
//! Each table maps to a key prefix with zero-padded ids and an
//! auto-increment sequence. Swap audit rows are append-only.

use serde::{Deserialize, Serialize};

use crate::ports::KvStore;
use crate::{Error, Result};

use super::json::{bump_seq, delete_key, delete_prefix, get_json, id_key, list_json, next_id, put_json};

/// Wallet id of rows that predate wallet scoping.
pub const UNKNOWN_WALLET_ID: &str = "unknown";

fn check_len(field: &str, value: &str, min: usize, max: usize) -> Result<()> {
    // The length counts characters.
    let n = value.chars().count();
    if n < min || n > max {
        return Err(Error::invalid(format!("{field} length {n} outside {min}..={max}")));
    }
    Ok(())
}

/// `lower(column) LIKE '%needle%'` with a lower-cased needle.
///
/// NOTE: `%` and `_` in the needle match literally, not as wildcards.
fn like_ci(haystack: Option<&str>, needle_lower: &str) -> bool {
    haystack.is_some_and(|h| h.to_lowercase().contains(needle_lower))
}

async fn rows<K: KvStore, T: serde::de::DeserializeOwned>(kv: &K, prefix: &str) -> Result<Vec<T>> {
    Ok(list_json(kv, prefix).await?.into_iter().map(|(_, v)| v).collect())
}

// ───────────────────────────── swaps

/// Immutable audit row of one executed swap (`Swaps` table).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SwapRecord {
    pub id: i64,
    pub send_asset: String,
    pub receive_asset: String,
    pub send_amount: i64,
    pub receive_amount: i64,
    pub created_at_ms: u64,
    /// `breez`, `sideswap`, `internal_liquid`, or `unknown`.
    pub provider: String,
    /// `pending`, `completed` or `failed`.
    pub status: String,
    /// Free-form label such as `lbtc_to_btc` or `asset_swap`.
    pub direction: String,
    pub tx_id: Option<String>,
    /// Provider-specific JSON text.
    pub metadata: Option<String>,
    pub wallet_id: String,
}

/// Insert payload for [`SwapRecord`]. `None` fields take the default values.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct NewSwap {
    pub send_asset: String,
    pub receive_asset: String,
    pub send_amount: i64,
    pub receive_amount: i64,
    pub created_at_ms: Option<u64>,
    pub provider: Option<String>,
    pub status: Option<String>,
    pub direction: Option<String>,
    pub tx_id: Option<String>,
    pub metadata: Option<String>,
    pub wallet_id: Option<String>,
}

const SWAP_ROWS: &str = "db/swaps/row/";
const SWAP_SEQ: &str = "db/swaps/seq";

/// Append-only swap audit log. No delete method exists by design.
#[derive(Debug, Clone)]
pub struct SwapAuditStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> SwapAuditStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Inserts a row and returns its id. `now_ms` fills a missing `created_at_ms`.
    pub async fn insert(&self, s: NewSwap, now_ms: u64) -> Result<i64> {
        let rec = SwapRecord {
            id: 0,
            send_asset: s.send_asset,
            receive_asset: s.receive_asset,
            send_amount: s.send_amount,
            receive_amount: s.receive_amount,
            created_at_ms: s.created_at_ms.unwrap_or(now_ms),
            provider: s.provider.unwrap_or_else(|| "unknown".into()),
            status: s.status.unwrap_or_else(|| "completed".into()),
            direction: s.direction.unwrap_or_else(|| "asset_swap".into()),
            tx_id: s.tx_id,
            metadata: s.metadata,
            wallet_id: s.wallet_id.unwrap_or_else(|| UNKNOWN_WALLET_ID.into()),
        };
        check_len("send_asset", &rec.send_asset, 1, 128)?;
        check_len("receive_asset", &rec.receive_asset, 1, 128)?;
        check_len("provider", &rec.provider, 1, 32)?;
        check_len("status", &rec.status, 1, 16)?;
        check_len("direction", &rec.direction, 1, 32)?;
        check_len("wallet_id", &rec.wallet_id, 1, 64)?;
        let id = next_id(&self.kv, SWAP_SEQ).await?;
        put_json(&self.kv, &id_key(SWAP_ROWS, id), &SwapRecord { id, ..rec }).await?;
        Ok(id)
    }

    /// Writes an existing row with its original id, for a data migration.
    /// Replaces a row with the same id. Later inserts get higher ids.
    pub async fn import(&self, rec: &SwapRecord) -> Result<()> {
        check_len("send_asset", &rec.send_asset, 1, 128)?;
        check_len("receive_asset", &rec.receive_asset, 1, 128)?;
        if rec.id <= 0 {
            return Err(Error::invalid(format!("swap id {} must be positive", rec.id)));
        }
        put_json(&self.kv, &id_key(SWAP_ROWS, rec.id), rec).await?;
        bump_seq(&self.kv, SWAP_SEQ, rec.id).await
    }

    /// Updates only status, and tx id and metadata when given. Returns 0 or 1.
    pub async fn update_status(
        &self,
        id: i64,
        status: &str,
        tx_id: Option<&str>,
        metadata: Option<&str>,
    ) -> Result<u32> {
        let key = id_key(SWAP_ROWS, id);
        let Some(mut rec): Option<SwapRecord> = get_json(&self.kv, &key).await? else {
            return Ok(0);
        };
        check_len("status", status, 1, 16)?;
        rec.status = status.to_owned();
        if let Some(t) = tx_id {
            rec.tx_id = Some(t.to_owned());
        }
        if let Some(m) = metadata {
            rec.metadata = Some(m.to_owned());
        }
        put_json(&self.kv, &key, &rec).await?;
        Ok(1)
    }

    /// Reads one row by id.
    pub async fn get(&self, id: i64) -> Result<Option<SwapRecord>> {
        get_json(&self.kv, &id_key(SWAP_ROWS, id)).await
    }

    /// Rows of `wallet_id`, in id order.
    pub async fn get_all(&self, wallet_id: &str) -> Result<Vec<SwapRecord>> {
        let all: Vec<SwapRecord> = rows(&self.kv, SWAP_ROWS).await?;
        Ok(all.into_iter().filter(|s| s.wallet_id == wallet_id).collect())
    }

    /// True if a row of `(wallet_id, provider)` has `tx_id` equal to `tx_id`
    /// or metadata containing it (case-insensitive).
    pub async fn exists_for_tx_id(&self, wallet_id: &str, provider: &str, tx_id: &str) -> Result<bool> {
        let needle = tx_id.to_lowercase();
        Ok(self.get_all(wallet_id).await?.iter().any(|s| {
            s.provider == provider && (s.tx_id.as_deref() == Some(tx_id) || like_ci(s.metadata.as_deref(), &needle))
        }))
    }

    /// Newest pending row of `(wallet_id, provider)` whose metadata mentions `deposit_address`.
    pub async fn find_pending_peg_in_by_deposit_address(
        &self,
        wallet_id: &str,
        provider: &str,
        deposit_address: &str,
    ) -> Result<Option<SwapRecord>> {
        let needle = deposit_address.to_lowercase();
        let mut hits: Vec<SwapRecord> = self
            .get_all(wallet_id)
            .await?
            .into_iter()
            .filter(|s| s.provider == provider && s.status == "pending" && like_ci(s.metadata.as_deref(), &needle))
            .collect();
        hits.sort_by_key(|x| std::cmp::Reverse(x.created_at_ms));
        Ok(hits.into_iter().next())
    }

    /// Page of rows of `wallet_id`, newest first, with optional provider and search filters.
    ///
    /// The search matches send asset, receive asset, direction, tx id and metadata.
    pub async fn paginated(
        &self,
        wallet_id: &str,
        limit: usize,
        offset: usize,
        provider: Option<&str>,
        search: Option<&str>,
    ) -> Result<Vec<SwapRecord>> {
        let needle = search.filter(|s| !s.is_empty()).map(str::to_lowercase);
        let mut hits: Vec<SwapRecord> = self
            .get_all(wallet_id)
            .await?
            .into_iter()
            .filter(|s| provider.is_none_or(|p| s.provider == p))
            .filter(|s| {
                needle.as_deref().is_none_or(|n| {
                    like_ci(Some(&s.send_asset), n)
                        || like_ci(Some(&s.receive_asset), n)
                        || like_ci(Some(&s.direction), n)
                        || like_ci(s.tx_id.as_deref(), n)
                        || like_ci(s.metadata.as_deref(), n)
                })
            })
            .collect();
        hits.sort_by_key(|x| std::cmp::Reverse(x.created_at_ms));
        Ok(hits.into_iter().skip(offset).take(limit).collect())
    }

    /// Number of rows of `wallet_id`.
    pub async fn count(&self, wallet_id: &str) -> Result<usize> {
        Ok(self.get_all(wallet_id).await?.len())
    }
}

// ───────────────────────────── sync metadata

/// Last sync result per datasource.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncMetadataRecord {
    pub datasource: String,
    pub last_sync_time_ms: u64,
    pub transaction_count: i64,
    pub sync_status: String,
}

const SYNC_META_PREFIX: &str = "db/sync_metadata/";

/// Sync metadata keyed by datasource name.
#[derive(Debug, Clone)]
pub struct SyncMetadataStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> SyncMetadataStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Row of `datasource`.
    pub async fn get(&self, datasource: &str) -> Result<Option<SyncMetadataRecord>> {
        get_json(&self.kv, &format!("{SYNC_META_PREFIX}{datasource}")).await
    }

    /// Inserts or replaces the row of `rec.datasource`.
    pub async fn upsert(&self, rec: &SyncMetadataRecord) -> Result<()> {
        put_json(&self.kv, &format!("{SYNC_META_PREFIX}{}", rec.datasource), rec).await
    }

    /// Every row.
    pub async fn get_all(&self) -> Result<Vec<SyncMetadataRecord>> {
        rows(&self.kv, SYNC_META_PREFIX).await
    }

    /// Deletes the row of `datasource`.
    pub async fn delete(&self, datasource: &str) -> Result<()> {
        delete_key(&self.kv, &format!("{SYNC_META_PREFIX}{datasource}")).await
    }

    /// Deletes every row. Only the wallet-deletion sweep calls this.
    pub async fn delete_all(&self) -> Result<usize> {
        delete_prefix(&self.kv, SYNC_META_PREFIX).await
    }
}

// ───────────────────────────── app logs

/// One app log line.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AppLogRecord {
    pub id: i64,
    pub timestamp_ms: u64,
    pub level: String,
    pub tag: String,
    pub message: String,
    pub error: Option<String>,
    pub stack_trace: Option<String>,
}

const LOG_ROWS: &str = "db/app_logs/row/";
const LOG_SEQ: &str = "db/app_logs/seq";

/// App log store.
#[derive(Debug, Clone)]
pub struct AppLogStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> AppLogStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Inserts a line. The `id` field is ignored and the new id is returned.
    pub async fn insert(&self, rec: AppLogRecord) -> Result<i64> {
        check_len("level", &rec.level, 1, 20)?;
        check_len("tag", &rec.tag, 1, 100)?;
        let id = next_id(&self.kv, LOG_SEQ).await?;
        put_json(&self.kv, &id_key(LOG_ROWS, id), &AppLogRecord { id, ..rec }).await?;
        Ok(id)
    }

    /// Every line, in id order.
    pub async fn get_all(&self) -> Result<Vec<AppLogRecord>> {
        rows(&self.kv, LOG_ROWS).await
    }

    /// Lines of one level.
    pub async fn by_level(&self, level: &str) -> Result<Vec<AppLogRecord>> {
        Ok(self.get_all().await?.into_iter().filter(|l| l.level == level).collect())
    }

    /// Lines with `start <= timestamp <= end`.
    pub async fn by_time_range(&self, start_ms: u64, end_ms: u64) -> Result<Vec<AppLogRecord>> {
        Ok(self.get_all().await?.into_iter().filter(|l| l.timestamp_ms >= start_ms && l.timestamp_ms <= end_ms).collect())
    }

    /// Deletes lines older than `cutoff_ms`. Returns the count.
    pub async fn delete_old(&self, cutoff_ms: u64) -> Result<usize> {
        let mut n = 0;
        for (key, l) in list_json::<K, AppLogRecord>(&self.kv, LOG_ROWS).await? {
            if l.timestamp_ms < cutoff_ms {
                delete_key(&self.kv, &key).await?;
                n += 1;
            }
        }
        Ok(n)
    }

    /// Deletes every line.
    pub async fn delete_all(&self) -> Result<usize> {
        delete_prefix(&self.kv, LOG_ROWS).await
    }

    /// Number of lines.
    pub async fn count(&self) -> Result<usize> {
        Ok(self.kv.list_keys(LOG_ROWS).await?.len())
    }

    /// Page of lines, newest first. Search spans message, tag, error and stack trace.
    pub async fn paginated(
        &self,
        limit: usize,
        offset: usize,
        level: Option<&str>,
        search: Option<&str>,
    ) -> Result<Vec<AppLogRecord>> {
        let needle = search.filter(|s| !s.is_empty()).map(str::to_lowercase);
        let mut v: Vec<AppLogRecord> = self
            .get_all()
            .await?
            .into_iter()
            .filter(|l| level.is_none_or(|lv| l.level == lv))
            .filter(|l| {
                needle.as_deref().is_none_or(|n| {
                    like_ci(Some(&l.message), n)
                        || like_ci(Some(&l.tag), n)
                        || like_ci(l.error.as_deref(), n)
                        || like_ci(l.stack_trace.as_deref(), n)
                })
            })
            .collect();
        v.sort_by_key(|x| std::cmp::Reverse(x.timestamp_ms));
        Ok(v.into_iter().skip(offset).take(limit).collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    fn swap(wallet: &str, provider: &str, created: u64) -> NewSwap {
        NewSwap {
            send_asset: "LBTC".into(),
            receive_asset: "BTC".into(),
            send_amount: 1000,
            receive_amount: 990,
            created_at_ms: Some(created),
            provider: Some(provider.into()),
            wallet_id: Some(wallet.into()),
            ..Default::default()
        }
    }

    #[test]
    fn swaps_defaults_scoping_and_queries() {
        block_on(async {
            let s = SwapAuditStore::new(MemoryKv::new());
            let id = s.insert(NewSwap { send_asset: "A".into(), receive_asset: "B".into(), ..Default::default() }, 9).await.unwrap();
            let r = s.get(id).await.unwrap().unwrap();
            assert_eq!((r.provider.as_str(), r.status.as_str(), r.direction.as_str()), ("unknown", "completed", "asset_swap"));
            assert_eq!((r.wallet_id.as_str(), r.created_at_ms), ("unknown", 9));

            let mut p = swap("w1", "sideswap", 10);
            p.status = Some("pending".into());
            p.metadata = Some(r#"{"deposit":"BC1QXYZ"}"#.into());
            let pid = s.insert(p, 0).await.unwrap();
            s.insert(swap("w1", "breez", 20), 0).await.unwrap();
            s.insert(swap("w2", "breez", 30), 0).await.unwrap();

            assert_eq!(s.count("w1").await.unwrap(), 2);
            assert!(s.exists_for_tx_id("w1", "sideswap", "bc1qxyz").await.unwrap());
            assert!(!s.exists_for_tx_id("w2", "sideswap", "bc1qxyz").await.unwrap());
            let hit = s.find_pending_peg_in_by_deposit_address("w1", "sideswap", "bc1qXyz").await.unwrap().unwrap();
            assert_eq!(hit.id, pid);

            let page = s.paginated("w1", 10, 0, None, None).await.unwrap();
            assert_eq!(page.iter().map(|r| r.created_at_ms).collect::<Vec<_>>(), [20, 10]);
            let page = s.paginated("w1", 10, 0, Some("breez"), Some("")).await.unwrap();
            assert_eq!(page.len(), 1);
            let page = s.paginated("w1", 1, 1, None, Some("lbtc")).await.unwrap();
            assert_eq!(page[0].id, pid);

            assert_eq!(s.update_status(pid, "completed", Some("tx1"), None).await.unwrap(), 1);
            let u = s.get(pid).await.unwrap().unwrap();
            assert_eq!((u.status.as_str(), u.tx_id.as_deref()), ("completed", Some("tx1")));
            assert!(u.metadata.is_some());
            assert_eq!(s.update_status(999, "failed", None, None).await.unwrap(), 0);
            assert!(s.insert(NewSwap::default(), 0).await.is_err());
        });
    }

    #[test]
    fn logs_and_metadata() {
        block_on(async {
            let kv = MemoryKv::new();
            let logs = AppLogStore::new(kv.clone());
            for (ts, lvl, msg) in [(1, "info", "boot ok"), (2, "error", "SocketException"), (3, "info", "sync")] {
                let rec = AppLogRecord {
                    id: 0,
                    timestamp_ms: ts,
                    level: lvl.into(),
                    tag: "t".into(),
                    message: msg.into(),
                    error: None,
                    stack_trace: None,
                };
                logs.insert(rec).await.unwrap();
            }
            assert_eq!(logs.paginated(10, 0, None, Some("socket")).await.unwrap().len(), 1);
            assert_eq!(logs.paginated(1, 0, Some("info"), None).await.unwrap()[0].timestamp_ms, 3);
            assert_eq!(logs.by_time_range(2, 3).await.unwrap().len(), 2);
            assert_eq!(logs.delete_old(2).await.unwrap(), 1);
            assert_eq!(logs.count().await.unwrap(), 2);

            let m = SyncMetadataStore::new(kv.clone());
            let rec = SyncMetadataRecord { datasource: "lwk".into(), last_sync_time_ms: 5, transaction_count: 3, sync_status: "ok".into() };
            m.upsert(&rec).await.unwrap();
            assert_eq!(m.get("lwk").await.unwrap(), Some(rec));
            assert_eq!(m.delete_all().await.unwrap(), 1);

        });
    }
}
