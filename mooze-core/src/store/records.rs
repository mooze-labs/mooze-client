//! App database records. Port of the drift schema in `lib/database/database.dart`.
//!
//! Each drift table maps to a key prefix with zero-padded ids and an
//! auto-increment sequence. The DAO methods keep their Dart semantics,
//! including the append-only rule for swap and peg audit rows.

use serde::{Deserialize, Serialize};

use crate::ports::KvStore;
use crate::{Error, Result};

use super::json::{delete_key, delete_prefix, get_json, id_key, list_json, next_id, put_json};

/// Peg status: order still in progress.
pub const PEG_STATUS_PENDING: &str = "pending";
/// Peg status: payout done.
pub const PEG_STATUS_COMPLETED: &str = "completed";
/// Peg status: order failed.
pub const PEG_STATUS_FAILED: &str = "failed";
/// Peg status: deposit below the provider minimum.
pub const PEG_STATUS_INSUFFICIENT_AMOUNT: &str = "insufficient_amount";

/// Wallet id of rows that predate wallet scoping.
pub const UNKNOWN_WALLET_ID: &str = "unknown";

fn check_len(field: &str, value: &str, min: usize, max: usize) -> Result<()> {
    // Drift `withLength` counts characters.
    let n = value.chars().count();
    if n < min || n > max {
        return Err(Error::invalid(format!("{field} length {n} outside {min}..={max}")));
    }
    Ok(())
}

/// `lower(column) LIKE '%needle%'` with a lower-cased needle.
///
/// NOTE(port): SQL `LIKE` treats `%` and `_` in the needle as wildcards.
/// This port matches them literally.
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

/// Insert payload for [`SwapRecord`]. `None` fields take the drift defaults.
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

// ───────────────────────────── pegs

/// Audit row of one SideSwap peg-in or peg-out (`Pegs` table).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegRecord {
    pub id: i64,
    pub order_id: String,
    pub peg_in: bool,
    pub sideswap_address: String,
    pub payout_address: String,
    pub amount: i64,
    pub created_at_ms: u64,
    pub wallet_id: String,
    pub status: String,
    pub provider: String,
    /// Funding tx we broadcast. `None` until the broadcast returns.
    pub funding_tx_id: Option<String>,
    /// Payout tx reported by the provider.
    pub payout_tx_id: Option<String>,
    pub error_message: Option<String>,
    pub updated_at_ms: Option<u64>,
    /// Provider-specific JSON text.
    pub metadata: Option<String>,
}

/// Insert payload for [`PegRecord`]. `None` fields take the drift defaults.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct NewPeg {
    pub order_id: String,
    pub peg_in: bool,
    pub sideswap_address: String,
    pub payout_address: String,
    pub amount: i64,
    pub created_at_ms: Option<u64>,
    pub wallet_id: Option<String>,
    pub status: Option<String>,
    pub provider: Option<String>,
    pub funding_tx_id: Option<String>,
    pub payout_tx_id: Option<String>,
    pub error_message: Option<String>,
    pub updated_at_ms: Option<u64>,
    pub metadata: Option<String>,
}

/// Fields [`PegAuditStore::update_progress`] may change. `None` leaves a field alone.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct PegProgress {
    pub status: Option<String>,
    pub funding_tx_id: Option<String>,
    pub payout_tx_id: Option<String>,
    pub error_message: Option<String>,
    pub amount: Option<i64>,
    /// Encoded with `jsonEncode` semantics.
    pub metadata: Option<serde_json::Value>,
}

const PEG_ROWS: &str = "db/pegs/row/";
const PEG_SEQ: &str = "db/pegs/seq";

/// Append-only peg audit log. No delete method exists by design.
#[derive(Debug, Clone)]
pub struct PegAuditStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> PegAuditStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Inserts a row and returns its id.
    pub async fn insert(&self, p: NewPeg, now_ms: u64) -> Result<i64> {
        let rec = PegRecord {
            id: 0,
            order_id: p.order_id,
            peg_in: p.peg_in,
            sideswap_address: p.sideswap_address,
            payout_address: p.payout_address,
            amount: p.amount,
            created_at_ms: p.created_at_ms.unwrap_or(now_ms),
            wallet_id: p.wallet_id.unwrap_or_else(|| UNKNOWN_WALLET_ID.into()),
            // NOTE(port): the drift default status is 'completed', not 'pending'.
            status: p.status.unwrap_or_else(|| PEG_STATUS_COMPLETED.into()),
            provider: p.provider.unwrap_or_else(|| "sideswap".into()),
            funding_tx_id: p.funding_tx_id,
            payout_tx_id: p.payout_tx_id,
            error_message: p.error_message,
            updated_at_ms: p.updated_at_ms,
            metadata: p.metadata,
        };
        check_len("wallet_id", &rec.wallet_id, 1, 64)?;
        check_len("status", &rec.status, 1, 24)?;
        check_len("provider", &rec.provider, 1, 32)?;
        let id = next_id(&self.kv, PEG_SEQ).await?;
        put_json(&self.kv, &id_key(PEG_ROWS, id), &PegRecord { id, ..rec }).await?;
        Ok(id)
    }

    /// Rows of `wallet_id`, in id order.
    pub async fn get_all(&self, wallet_id: &str) -> Result<Vec<PegRecord>> {
        let all: Vec<PegRecord> = rows(&self.kv, PEG_ROWS).await?;
        Ok(all.into_iter().filter(|p| p.wallet_id == wallet_id).collect())
    }

    /// Pending rows of `wallet_id`, oldest first. Read at boot to resume tracking.
    pub async fn get_active(&self, wallet_id: &str) -> Result<Vec<PegRecord>> {
        let mut v: Vec<PegRecord> =
            self.get_all(wallet_id).await?.into_iter().filter(|p| p.status == PEG_STATUS_PENDING).collect();
        v.sort_by_key(|p| p.created_at_ms);
        Ok(v)
    }

    /// First row with `order_id` in `wallet_id`.
    pub async fn find_by_order_id(&self, order_id: &str, wallet_id: &str) -> Result<Option<PegRecord>> {
        Ok(self.get_all(wallet_id).await?.into_iter().find(|p| p.order_id == order_id))
    }

    /// Updates lifecycle fields of every row with `(order_id, wallet_id)`. Returns the row count.
    pub async fn update_progress(
        &self,
        order_id: &str,
        wallet_id: &str,
        progress: &PegProgress,
        updated_at_ms: u64,
    ) -> Result<u32> {
        let metadata = progress.metadata.as_ref().map(serde_json::Value::to_string);
        let mut n = 0;
        for (key, mut rec) in list_json::<K, PegRecord>(&self.kv, PEG_ROWS).await? {
            if rec.order_id != order_id || rec.wallet_id != wallet_id {
                continue;
            }
            if let Some(s) = &progress.status {
                rec.status = s.clone();
            }
            if let Some(v) = &progress.funding_tx_id {
                rec.funding_tx_id = Some(v.clone());
            }
            if let Some(v) = &progress.payout_tx_id {
                rec.payout_tx_id = Some(v.clone());
            }
            if let Some(v) = &progress.error_message {
                rec.error_message = Some(v.clone());
            }
            if let Some(v) = progress.amount {
                rec.amount = v;
            }
            if let Some(v) = &metadata {
                rec.metadata = Some(v.clone());
            }
            rec.updated_at_ms = Some(updated_at_ms);
            put_json(&self.kv, &key, &rec).await?;
            n += 1;
        }
        Ok(n)
    }
}

// ───────────────────────────── deposits

/// PIX deposit row (`Deposits` table).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DepositRecord {
    pub id: i64,
    pub deposit_id: String,
    pub asset_id: String,
    pub amount_in_cents: i64,
    pub created_at_ms: u64,
    pub status: String,
    pub asset_amount: Option<i64>,
    pub blockchain_txid: Option<String>,
    pub pix_key: String,
}

const DEPOSIT_ROWS: &str = "db/deposits/row/";
const DEPOSIT_SEQ: &str = "db/deposits/seq";

/// PIX deposit rows.
#[derive(Debug, Clone)]
pub struct DepositStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> DepositStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Inserts a row. The `id` field is ignored and the new id is returned.
    pub async fn insert(&self, rec: DepositRecord) -> Result<i64> {
        let id = next_id(&self.kv, DEPOSIT_SEQ).await?;
        put_json(&self.kv, &id_key(DEPOSIT_ROWS, id), &DepositRecord { id, ..rec }).await?;
        Ok(id)
    }

    /// Replaces the row with `rec.id`. Returns false if absent.
    pub async fn update(&self, rec: &DepositRecord) -> Result<bool> {
        let key = id_key(DEPOSIT_ROWS, rec.id);
        if self.kv.get(&key).await?.is_none() {
            return Ok(false);
        }
        put_json(&self.kv, &key, rec).await?;
        Ok(true)
    }

    /// Every row, in id order.
    pub async fn get_all(&self) -> Result<Vec<DepositRecord>> {
        rows(&self.kv, DEPOSIT_ROWS).await
    }

    /// First row with `deposit_id`.
    pub async fn find_by_deposit_id(&self, deposit_id: &str) -> Result<Option<DepositRecord>> {
        Ok(self.get_all().await?.into_iter().find(|d| d.deposit_id == deposit_id))
    }

    /// Deletes every row. Returns the count.
    pub async fn delete_all(&self) -> Result<usize> {
        delete_prefix(&self.kv, DEPOSIT_ROWS).await
    }
}

// ───────────────────────────── favorite payers

/// Saved PIX payer (`FavoritePayerEntries` table).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FavoritePayer {
    pub id: i64,
    pub label: String,
    /// Unmasked CPF (11 digits) or CNPJ (14 digits).
    pub cpf: String,
    pub created_at_ms: u64,
}

const PAYER_ROWS: &str = "db/favorite_payers/row/";
const PAYER_SEQ: &str = "db/favorite_payers/seq";

/// Wallet-scoped favorite payers.
#[derive(Debug, Clone)]
pub struct FavoritePayerStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> FavoritePayerStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    fn check(label: &str, cpf: &str) -> Result<()> {
        check_len("label", label, 1, 255)?;
        check_len("cpf", cpf, 11, 14)
    }

    /// Every payer, newest first.
    pub async fn get_all(&self) -> Result<Vec<FavoritePayer>> {
        let mut v: Vec<FavoritePayer> = rows(&self.kv, PAYER_ROWS).await?;
        v.sort_by_key(|x| std::cmp::Reverse(x.created_at_ms));
        Ok(v)
    }

    /// Inserts a payer and returns its id.
    pub async fn insert(&self, label: &str, cpf: &str, created_at_ms: u64) -> Result<i64> {
        Self::check(label, cpf)?;
        let id = next_id(&self.kv, PAYER_SEQ).await?;
        let rec = FavoritePayer { id, label: label.into(), cpf: cpf.into(), created_at_ms };
        put_json(&self.kv, &id_key(PAYER_ROWS, id), &rec).await?;
        Ok(id)
    }

    /// Updates label and tax id of `id`. Returns 0 or 1.
    pub async fn update_by_id(&self, id: i64, label: &str, cpf: &str) -> Result<u32> {
        Self::check(label, cpf)?;
        let key = id_key(PAYER_ROWS, id);
        let Some(mut rec): Option<FavoritePayer> = get_json(&self.kv, &key).await? else {
            return Ok(0);
        };
        rec.label = label.into();
        rec.cpf = cpf.into();
        put_json(&self.kv, &key, &rec).await?;
        Ok(1)
    }

    /// Deletes `id`. Returns 0 or 1.
    pub async fn delete(&self, id: i64) -> Result<u32> {
        let key = id_key(PAYER_ROWS, id);
        let existed = self.kv.get(&key).await?.is_some();
        delete_key(&self.kv, &key).await?;
        Ok(u32::from(existed))
    }

    /// Deletes every payer. Wallet-isolation sweep on delete or import.
    pub async fn delete_all(&self) -> Result<usize> {
        delete_prefix(&self.kv, PAYER_ROWS).await
    }

    /// True if another payer already has `cpf`.
    pub async fn cpf_exists(&self, cpf: &str, excluding_id: Option<i64>) -> Result<bool> {
        let all: Vec<FavoritePayer> = rows(&self.kv, PAYER_ROWS).await?;
        Ok(all.iter().any(|p| p.cpf == cpf && Some(p.id) != excluding_id))
    }
}

// ───────────────────────────── sync metadata

/// Last sync result per datasource (`SyncMetadata` table).
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

/// One app log line (`AppLogs` table).
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
    fn pegs_active_and_progress() {
        block_on(async {
            let s = PegAuditStore::new(MemoryKv::new());
            let base = NewPeg {
                order_id: "o1".into(),
                peg_in: true,
                sideswap_address: "sa".into(),
                payout_address: "pa".into(),
                amount: 5000,
                wallet_id: Some("w".into()),
                status: Some(PEG_STATUS_PENDING.into()),
                created_at_ms: Some(20),
                ..Default::default()
            };
            s.insert(base.clone(), 0).await.unwrap();
            s.insert(NewPeg { order_id: "o2".into(), created_at_ms: Some(10), ..base.clone() }, 0).await.unwrap();
            s.insert(NewPeg { order_id: "o3".into(), status: None, ..base }, 0).await.unwrap();
            let active = s.get_active("w").await.unwrap();
            assert_eq!(active.iter().map(|p| p.order_id.as_str()).collect::<Vec<_>>(), ["o2", "o1"]);
            let prog = PegProgress {
                status: Some(PEG_STATUS_COMPLETED.into()),
                payout_tx_id: Some("ptx".into()),
                metadata: Some(serde_json::json!({"k": 1})),
                ..Default::default()
            };
            assert_eq!(s.update_progress("o1", "w", &prog, 99).await.unwrap(), 1);
            let p = s.find_by_order_id("o1", "w").await.unwrap().unwrap();
            assert_eq!(p.status, PEG_STATUS_COMPLETED);
            assert_eq!(p.metadata.as_deref(), Some(r#"{"k":1}"#));
            assert_eq!(p.updated_at_ms, Some(99));
            assert!(s.find_by_order_id("o1", "other").await.unwrap().is_none());
        });
    }

    #[test]
    fn payers_logs_metadata_deposits() {
        block_on(async {
            let kv = MemoryKv::new();
            let f = FavoritePayerStore::new(kv.clone());
            let a = f.insert("Ana", "12345678901", 1).await.unwrap();
            let b = f.insert("Loja", "12345678000199", 2).await.unwrap();
            assert!(f.insert("x", "123", 3).await.is_err());
            assert_eq!(f.get_all().await.unwrap()[0].id, b);
            assert!(f.cpf_exists("12345678901", None).await.unwrap());
            assert!(!f.cpf_exists("12345678901", Some(a)).await.unwrap());
            assert_eq!(f.delete(a).await.unwrap(), 1);
            assert_eq!(f.delete(a).await.unwrap(), 0);

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

            let d = DepositStore::new(kv);
            let rec = DepositRecord {
                id: 0,
                deposit_id: "dep".into(),
                asset_id: "a".into(),
                amount_in_cents: 2500,
                created_at_ms: 1,
                status: "pending".into(),
                asset_amount: None,
                blockchain_txid: None,
                pix_key: "N/A".into(),
            };
            let id = d.insert(rec).await.unwrap();
            let mut got = d.find_by_deposit_id("dep").await.unwrap().unwrap();
            assert_eq!(got.id, id);
            got.status = "finished".into();
            assert!(d.update(&got).await.unwrap());
            assert_eq!(d.delete_all().await.unwrap(), 1);
        });
    }
}
