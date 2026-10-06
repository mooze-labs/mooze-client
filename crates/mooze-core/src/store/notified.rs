//! Persisted dedup ledger for transaction notifications.
//!
//! Port of `SqliteNotifiedTxRegistry` (`lib/infra/storage/notified_tx_registry_impl.dart`).
//! Tables `notified_tx_ids` and `notification_meta` become two key prefixes.

use serde::{Deserialize, Serialize};

use crate::domain::ChainId;
use crate::ports::KvStore;
use crate::Result;

use super::json::{delete_prefix, get_json, get_string, put_json, put_string};

/// Prefix of the `notified_tx_ids` rows.
pub const NOTIFIED_PREFIX: &str = "notified_tx/";
/// Prefix of the `notification_meta` rows.
pub const META_PREFIX: &str = "notification_meta/";

const BASELINE_KEY: &str = "baseline_completed";
const BASELINE_TRUE: &str = "1";
const IMPORTED_AT_KEY: &str = "wallet_imported_at_ms";

/// One ledger row.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct NotifiedRow {
    /// Time the row was written.
    pub notified_at_ms: u64,
}

fn notified_key(chain: ChainId, tx_id: &str) -> String {
    format!("{NOTIFIED_PREFIX}{}/{tx_id}", chain.as_str())
}

fn meta_key(key: &str) -> String {
    format!("{META_PREFIX}{key}")
}

/// Dedup ledger keyed by `(chain, tx_id)`. Survives restarts.
#[derive(Debug, Clone)]
pub struct NotifiedTxRegistry<K: KvStore> {
    kv: K,
}

impl<K: KvStore> NotifiedTxRegistry<K> {
    /// Registry over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Returns `true` the first time `(chain, tx_id)` is seen, `false` after.
    ///
    /// NOTE(port): Dart relies on SQLite `INSERT OR IGNORE` for atomicity.
    /// Here callers must not run two `mark_if_new` calls for the same key at once.
    pub async fn mark_if_new(&self, chain: ChainId, tx_id: &str, now_ms: u64) -> Result<bool> {
        let key = notified_key(chain, tx_id);
        if self.kv.get(&key).await?.is_some() {
            return Ok(false);
        }
        put_json(
            &self.kv,
            &key,
            &NotifiedRow {
                notified_at_ms: now_ms,
            },
        )
        .await?;
        Ok(true)
    }

    /// True if `(chain, tx_id)` is already in the ledger.
    pub async fn contains(&self, chain: ChainId, tx_id: &str) -> Result<bool> {
        Ok(self.kv.get(&notified_key(chain, tx_id)).await?.is_some())
    }

    /// Marks many entries. Existing rows keep their timestamp.
    pub async fn bulk_mark(&self, entries: &[(ChainId, String)], now_ms: u64) -> Result<()> {
        for (chain, tx_id) in entries {
            self.mark_if_new(*chain, tx_id, now_ms).await?;
        }
        Ok(())
    }

    /// True once the baseline absorb pass has completed.
    pub async fn is_baseline_complete(&self) -> Result<bool> {
        Ok(get_string(&self.kv, &meta_key(BASELINE_KEY))
            .await?
            .as_deref()
            == Some(BASELINE_TRUE))
    }

    /// Marks the baseline absorb pass as complete. Sticky until [`Self::clear`].
    pub async fn set_baseline_complete(&self) -> Result<()> {
        put_string(&self.kv, &meta_key(BASELINE_KEY), BASELINE_TRUE).await
    }

    /// Wallet import time in epoch ms. `None` if absent or unparsable.
    pub async fn imported_at_ms(&self) -> Result<Option<i64>> {
        Ok(get_string(&self.kv, &meta_key(IMPORTED_AT_KEY))
            .await?
            .and_then(|s| s.parse().ok()))
    }

    /// Stores the wallet import time in epoch ms.
    pub async fn set_imported_at_ms(&self, ms: i64) -> Result<()> {
        put_string(&self.kv, &meta_key(IMPORTED_AT_KEY), &ms.to_string()).await
    }

    /// Wipes the ledger and every meta value (baseline flag, import stamp).
    pub async fn clear(&self) -> Result<()> {
        delete_prefix(&self.kv, NOTIFIED_PREFIX).await?;
        delete_prefix(&self.kv, META_PREFIX).await?;
        Ok(())
    }

    /// Reads one ledger row.
    pub async fn row(&self, chain: ChainId, tx_id: &str) -> Result<Option<NotifiedRow>> {
        get_json(&self.kv, &notified_key(chain, tx_id)).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn mark_if_new_is_idempotent_per_chain() {
        block_on(async {
            let r = NotifiedTxRegistry::new(MemoryKv::new());
            assert!(r.mark_if_new(ChainId::Liquid, "t", 1).await.unwrap());
            assert!(!r.mark_if_new(ChainId::Liquid, "t", 2).await.unwrap());
            assert!(r.mark_if_new(ChainId::Lightning, "t", 3).await.unwrap());
            assert_eq!(
                r.row(ChainId::Liquid, "t")
                    .await
                    .unwrap()
                    .unwrap()
                    .notified_at_ms,
                1
            );
        });
    }

    #[test]
    fn baseline_import_stamp_and_clear() {
        block_on(async {
            let r = NotifiedTxRegistry::new(MemoryKv::new());
            assert!(!r.is_baseline_complete().await.unwrap());
            assert_eq!(r.imported_at_ms().await.unwrap(), None);
            r.set_baseline_complete().await.unwrap();
            r.set_imported_at_ms(1_700_000_000_000).await.unwrap();
            r.bulk_mark(
                &[
                    (ChainId::Bitcoin, "a".into()),
                    (ChainId::Bitcoin, "b".into()),
                ],
                5,
            )
            .await
            .unwrap();
            assert!(r.is_baseline_complete().await.unwrap());
            assert_eq!(r.imported_at_ms().await.unwrap(), Some(1_700_000_000_000));
            assert!(r.contains(ChainId::Bitcoin, "b").await.unwrap());
            r.clear().await.unwrap();
            assert!(!r.is_baseline_complete().await.unwrap());
            assert_eq!(r.imported_at_ms().await.unwrap(), None);
            assert!(!r.contains(ChainId::Bitcoin, "b").await.unwrap());
        });
    }
}
