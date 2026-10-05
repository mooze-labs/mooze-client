//! One-time copy of the Flutter app's local data into the core stores.
//!
//! The Flutter app keeps its data in two SQLite databases and in
//! SharedPreferences:
//!
//! - The drift app database: swaps, pegs, deposits, products, sync metadata,
//!   favorite payers, app logs and a legacy transactions table.
//! - `mooze_v2.db`: transactions, notified transaction ids and notifier metadata.
//! - SharedPreferences: flags and settings.
//!
//! The Flutter app reads all of it and exports one JSON [`LegacySnapshot`].
//! [`import_flutter_data`] writes the snapshot into the core stores once,
//! then sets a marker. The core needs no SQLite code for this.
//!
//! What is not copied, and why:
//!
//! - **Secrets** (mnemonic, session tokens, PIN hash and salt). The core uses
//!   the same key names as `flutter_secure_storage`, so the mobile
//!   `SecureStore` reads the existing Keychain and Keystore entries. A JSON
//!   snapshot would only add a place where secrets can leak.
//! - **App logs**. Diagnostics only.
//! - **The legacy drift `Transactions` table**. `mooze_v2.db` replaced it.
//! - **Wallet caches** (BDK and LWK state). The first sync rebuilds them.
//! - **Cached prices** (`cached_price_*`). They expire within minutes.
//!
//! The import is safe to repeat. Every row goes to a key derived from its
//! own id, so a second run after a crash rewrites the same keys. The marker
//! is written last, only after every row is stored.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::domain::{ChainId, Transaction};
use crate::merchant::mode::{MERCHANT_MODE_ACTIVE_KEY, MERCHANT_MODE_ORIGIN_KEY, STORE_MODE_KEY};
use crate::merchant::{Product, ProductStore};
use crate::peg::store::PegRecord;
use crate::peg::KvPegStore;
use crate::pix::{DepositRecord, DepositStore, FavoritePayerStore, PixFlag, PixFlagsStore};
use crate::ports::{Clock, KvStore};
use crate::store::json::{get_json, put_json};
use crate::store::records::{SwapRecord, SyncMetadataRecord};
use crate::store::{NodeSettings, NotifiedTxRegistry, SwapAuditStore, SyncMetadataStore, TransactionStore};
use crate::{Error, Result};

/// Snapshot format this core reads.
pub const SNAPSHOT_VERSION: u32 = 1;
/// Marker key. Holds the completion time in ms once the import finished.
pub const MIGRATION_DONE_KEY: &str = "migration/flutter_v1/completed_at_ms";
/// Namespace for preferences the core does not read itself.
pub const PREFS_PREFIX: &str = "prefs/";

/// Notifier metadata key: first sync after install finished.
const META_BASELINE: &str = "baseline_completed";
/// Notifier metadata key: wallet import time in ms.
const META_IMPORTED_AT: &str = "wallet_imported_at_ms";

/// Everything the Flutter app exports. Field names are the contract with the
/// app's exporter. Times are ms since the Unix epoch.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct LegacySnapshot {
    /// Must equal [`SNAPSHOT_VERSION`].
    pub version: u32,
    /// `mooze_v2.db` `transactions` rows. Same columns as [`Transaction`].
    #[serde(default)]
    pub transactions: Vec<Transaction>,
    /// `mooze_v2.db` `notified_tx_ids` rows.
    #[serde(default)]
    pub notified_tx_ids: Vec<LegacyNotifiedTx>,
    /// `mooze_v2.db` `notification_meta` rows.
    #[serde(default)]
    pub notification_meta: BTreeMap<String, String>,
    /// Drift `Swaps` rows.
    #[serde(default)]
    pub swaps: Vec<LegacySwap>,
    /// Drift `Pegs` rows.
    #[serde(default)]
    pub pegs: Vec<LegacyPeg>,
    /// Drift `Deposits` rows.
    #[serde(default)]
    pub deposits: Vec<LegacyDeposit>,
    /// Drift `Products` rows.
    #[serde(default)]
    pub products: Vec<LegacyProduct>,
    /// Drift `SyncMetadata` rows.
    #[serde(default)]
    pub sync_metadata: Vec<LegacySyncMetadata>,
    /// Drift `FavoritePayerEntries` rows.
    #[serde(default)]
    pub favorite_payers: Vec<LegacyFavoritePayer>,
    /// Every SharedPreferences entry, with its JSON-typed value.
    #[serde(default)]
    pub preferences: BTreeMap<String, Value>,
}

/// One `notified_tx_ids` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LegacyNotifiedTx {
    pub chain: String,
    pub tx_id: String,
    pub notified_at_ms: u64,
}

/// One drift `Swaps` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LegacySwap {
    pub id: i64,
    pub send_asset: String,
    pub receive_asset: String,
    pub send_amount: i64,
    pub receive_amount: i64,
    pub created_at_ms: u64,
    pub provider: String,
    pub status: String,
    pub direction: String,
    pub tx_id: Option<String>,
    pub metadata: Option<String>,
    pub wallet_id: String,
}

/// One drift `Pegs` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LegacyPeg {
    pub order_id: String,
    pub peg_in: bool,
    pub sideswap_address: String,
    pub payout_address: String,
    pub amount: i64,
    pub created_at_ms: u64,
    pub wallet_id: String,
    pub status: String,
    pub provider: String,
    pub funding_tx_id: Option<String>,
    pub payout_tx_id: Option<String>,
    pub error_message: Option<String>,
    pub updated_at_ms: Option<u64>,
    /// JSON text, as drift stores it.
    pub metadata: Option<String>,
}

/// One drift `Deposits` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LegacyDeposit {
    pub deposit_id: String,
    pub asset_id: String,
    pub amount_in_cents: i64,
    pub created_at_ms: u64,
    pub status: String,
    pub asset_amount: Option<i64>,
    pub blockchain_txid: Option<String>,
    pub pix_key: String,
}

/// One drift `Products` row.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LegacyProduct {
    pub id: i64,
    pub name: String,
    pub price: f64,
    pub created_at_ms: u64,
}

/// One drift `SyncMetadata` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LegacySyncMetadata {
    pub datasource: String,
    pub last_sync_time_ms: u64,
    pub transaction_count: i64,
    pub sync_status: String,
}

/// One drift `FavoritePayerEntries` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LegacyFavoritePayer {
    pub id: i64,
    pub label: String,
    pub cpf: String,
    pub created_at_ms: u64,
}

/// A row the import left out, and why.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SkippedRow {
    /// Source table or `preferences`.
    pub table: String,
    /// Row id, order id or preference key.
    pub key: String,
    pub reason: String,
}

/// What the import did.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct MigrationReport {
    /// True if an earlier run already finished. Nothing was written.
    pub already_done: bool,
    /// Rows written per source table.
    pub copied: BTreeMap<String, usize>,
    /// Rows left out because they are invalid.
    pub skipped: Vec<SkippedRow>,
}

impl MigrationReport {
    fn count(&mut self, table: &str) {
        *self.copied.entry(table.to_owned()).or_default() += 1;
    }

    fn skip(&mut self, table: &str, key: impl Into<String>, reason: impl std::fmt::Display) {
        self.skipped.push(SkippedRow { table: table.to_owned(), key: key.into(), reason: reason.to_string() });
    }
}

/// Parses the exporter's JSON and checks the version.
pub fn parse_snapshot(json: &[u8]) -> Result<LegacySnapshot> {
    let snapshot: LegacySnapshot = serde_json::from_slice(json)?;
    if snapshot.version != SNAPSHOT_VERSION {
        return Err(Error::invalid(format!(
            "snapshot version {} is not supported (expected {SNAPSHOT_VERSION})",
            snapshot.version
        )));
    }
    Ok(snapshot)
}

/// True once [`import_flutter_data`] finished on this store.
pub async fn is_migrated<K: KvStore>(kv: &K) -> Result<bool> {
    Ok(get_json::<K, u64>(kv, MIGRATION_DONE_KEY).await?.is_some())
}

/// Splits a row-level problem from a storage failure.
///
/// Invalid input skips one row. Anything else, such as a failing store,
/// stops the import so that it runs again on the next launch.
fn row_result(r: Result<()>) -> Result<std::result::Result<(), Error>> {
    match r {
        Ok(()) => Ok(Ok(())),
        Err(e @ Error::InvalidInput(_)) => Ok(Err(e)),
        Err(e) => Err(e),
    }
}

/// Writes `snapshot` into the core stores, once.
///
/// Returns at once with `already_done` set if an earlier run finished.
/// Invalid rows are skipped and listed in the report. A storage failure
/// returns an error and leaves the marker unset, so the platform can retry.
pub async fn import_flutter_data<K, C>(kv: &K, clock: &C, snapshot: &LegacySnapshot) -> Result<MigrationReport>
where
    K: KvStore + Clone,
    C: Clock + Clone,
{
    if is_migrated(kv).await? {
        return Ok(MigrationReport { already_done: true, ..Default::default() });
    }
    if snapshot.version != SNAPSHOT_VERSION {
        return Err(Error::invalid(format!("snapshot version {} is not supported", snapshot.version)));
    }
    let now = clock.now_ms();
    let mut report = MigrationReport::default();

    import_transactions(kv, snapshot, now, &mut report).await?;
    import_notifier_state(kv, snapshot, now, &mut report).await?;
    import_swaps(kv, snapshot, &mut report).await?;
    import_pegs(kv, clock, snapshot, &mut report).await?;
    import_deposits(kv, snapshot, &mut report).await?;
    import_products(kv, snapshot, &mut report).await?;
    import_sync_metadata(kv, snapshot, &mut report).await?;
    import_favorite_payers(kv, snapshot, &mut report).await?;
    import_preferences(kv, snapshot, &mut report).await?;

    put_json(kv, MIGRATION_DONE_KEY, &now).await?;
    Ok(report)
}

async fn import_transactions<K: KvStore + Clone>(
    kv: &K,
    snapshot: &LegacySnapshot,
    now: u64,
    report: &mut MigrationReport,
) -> Result<()> {
    let store = TransactionStore::new(kv.clone());
    let valid: Vec<Transaction> = snapshot
        .transactions
        .iter()
        .filter(|tx| {
            let ok = !tx.id.is_empty() && tx.chain.is_real();
            if !ok {
                report.skip("transactions", tx.id.clone(), "empty id or aggregate chain");
            }
            ok
        })
        .cloned()
        .collect();
    // The returned events would announce old history as new. Drop them.
    store.upsert_all(&valid, now).await?;
    report.copied.insert("transactions".into(), valid.len());
    Ok(())
}

async fn import_notifier_state<K: KvStore + Clone>(
    kv: &K,
    snapshot: &LegacySnapshot,
    now: u64,
    report: &mut MigrationReport,
) -> Result<()> {
    let registry = NotifiedTxRegistry::new(kv.clone());
    let mut entries = Vec::new();
    for row in &snapshot.notified_tx_ids {
        match serde_json::from_value::<ChainId>(Value::String(row.chain.clone())) {
            Ok(chain) if chain.is_real() && !row.tx_id.is_empty() => entries.push((chain, row.tx_id.clone())),
            _ => report.skip("notified_tx_ids", format!("{}:{}", row.chain, row.tx_id), "unknown chain or empty id"),
        }
    }
    registry.bulk_mark(&entries, now).await?;
    report.copied.insert("notified_tx_ids".into(), entries.len());

    for (key, value) in &snapshot.notification_meta {
        match key.as_str() {
            // The app stores '1' for true.
            META_BASELINE if value == "1" || value == "true" => {
                registry.set_baseline_complete().await?;
                report.count("notification_meta");
            }
            META_BASELINE => {}
            META_IMPORTED_AT => match value.trim().parse::<i64>() {
                Ok(ms) => {
                    registry.set_imported_at_ms(ms).await?;
                    report.count("notification_meta");
                }
                Err(e) => report.skip("notification_meta", key.clone(), e),
            },
            other => report.skip("notification_meta", other, "unknown key"),
        }
    }
    Ok(())
}

async fn import_swaps<K: KvStore + Clone>(kv: &K, snapshot: &LegacySnapshot, report: &mut MigrationReport) -> Result<()> {
    let store = SwapAuditStore::new(kv.clone());
    for s in &snapshot.swaps {
        let rec = SwapRecord {
            id: s.id,
            send_asset: s.send_asset.clone(),
            receive_asset: s.receive_asset.clone(),
            send_amount: s.send_amount,
            receive_amount: s.receive_amount,
            created_at_ms: s.created_at_ms,
            provider: s.provider.clone(),
            status: s.status.clone(),
            direction: s.direction.clone(),
            tx_id: s.tx_id.clone(),
            metadata: s.metadata.clone(),
            wallet_id: s.wallet_id.clone(),
        };
        match row_result(store.import(&rec).await)? {
            Ok(()) => report.count("swaps"),
            Err(e) => report.skip("swaps", s.id.to_string(), e),
        }
    }
    Ok(())
}

async fn import_pegs<K: KvStore + Clone, C: Clock + Clone>(
    kv: &K,
    clock: &C,
    snapshot: &LegacySnapshot,
    report: &mut MigrationReport,
) -> Result<()> {
    for p in &snapshot.pegs {
        let Ok(amount) = u64::try_from(p.amount) else {
            report.skip("pegs", p.order_id.clone(), format!("negative amount {}", p.amount));
            continue;
        };
        // Drift stores metadata as text. Keep invalid JSON as a string.
        let metadata = p
            .metadata
            .as_deref()
            .map(|text| serde_json::from_str(text).unwrap_or_else(|_| Value::String(text.to_owned())));
        let rec = PegRecord {
            order_id: p.order_id.clone(),
            peg_in: p.peg_in,
            sideswap_address: p.sideswap_address.clone(),
            payout_address: p.payout_address.clone(),
            amount,
            created_at_ms: p.created_at_ms,
            wallet_id: p.wallet_id.clone(),
            status: p.status.clone(),
            provider: p.provider.clone(),
            funding_tx_id: p.funding_tx_id.clone(),
            payout_tx_id: p.payout_tx_id.clone(),
            error_message: p.error_message.clone(),
            updated_at_ms: p.updated_at_ms,
            metadata,
        };
        let store = KvPegStore::new(kv.clone(), clock.clone(), p.wallet_id.clone());
        match row_result(store.import(&rec).await)? {
            Ok(()) => report.count("pegs"),
            Err(e) => report.skip("pegs", p.order_id.clone(), e),
        }
    }
    Ok(())
}

async fn import_deposits<K: KvStore + Clone>(kv: &K, snapshot: &LegacySnapshot, report: &mut MigrationReport) -> Result<()> {
    let store = DepositStore::new(kv.clone());
    for d in &snapshot.deposits {
        let (Ok(cents), asset_amount) = (u64::try_from(d.amount_in_cents), d.asset_amount.map(u64::try_from)) else {
            report.skip("deposits", d.deposit_id.clone(), "negative amount");
            continue;
        };
        let asset_amount = match asset_amount.transpose() {
            Ok(a) => a,
            Err(_) => {
                report.skip("deposits", d.deposit_id.clone(), "negative asset amount");
                continue;
            }
        };
        let rec = DepositRecord {
            deposit_id: d.deposit_id.clone(),
            pix_key: d.pix_key.clone(),
            asset_id: d.asset_id.clone(),
            amount_in_cents: cents,
            created_at_ms: d.created_at_ms,
            status: d.status.clone(),
            asset_amount,
            blockchain_txid: d.blockchain_txid.clone(),
        };
        match row_result(store.import(&rec).await)? {
            Ok(()) => report.count("deposits"),
            Err(e) => report.skip("deposits", d.deposit_id.clone(), e),
        }
    }
    Ok(())
}

async fn import_products<K: KvStore + Clone>(kv: &K, snapshot: &LegacySnapshot, report: &mut MigrationReport) -> Result<()> {
    let store = ProductStore::new(kv.clone());
    for p in &snapshot.products {
        let product = Product { id: Some(p.id), name: p.name.clone(), price: p.price, created_at_ms: p.created_at_ms };
        match row_result(store.import(&product).await)? {
            Ok(()) => report.count("products"),
            Err(e) => report.skip("products", p.id.to_string(), e),
        }
    }
    Ok(())
}

async fn import_sync_metadata<K: KvStore + Clone>(
    kv: &K,
    snapshot: &LegacySnapshot,
    report: &mut MigrationReport,
) -> Result<()> {
    let store = SyncMetadataStore::new(kv.clone());
    for m in &snapshot.sync_metadata {
        let rec = SyncMetadataRecord {
            datasource: m.datasource.clone(),
            last_sync_time_ms: m.last_sync_time_ms,
            transaction_count: m.transaction_count,
            sync_status: m.sync_status.clone(),
        };
        store.upsert(&rec).await?;
        report.count("sync_metadata");
    }
    Ok(())
}

async fn import_favorite_payers<K: KvStore + Clone>(
    kv: &K,
    snapshot: &LegacySnapshot,
    report: &mut MigrationReport,
) -> Result<()> {
    let store = FavoritePayerStore::new(kv.clone());
    for f in &snapshot.favorite_payers {
        let Ok(id) = u64::try_from(f.id) else {
            report.skip("favorite_payers", f.id.to_string(), "negative id");
            continue;
        };
        match row_result(store.import(id, &f.label, &f.cpf, f.created_at_ms).await)? {
            Ok(()) => report.count("favorite_payers"),
            Err(e) => report.skip("favorite_payers", f.id.to_string(), e),
        }
    }
    Ok(())
}

/// Preferences that core stores read as raw UTF-8 text.
const RAW_TEXT_PREFS: [&str; 5] =
    ["device_id", "user_verification_level", "sessionLockTimeout", "pinAttempts", "lastAuthTime"];
/// Preferences that core stores read as JSON at the same key.
const JSON_PREFS: [&str; 3] = [MERCHANT_MODE_ACTIVE_KEY, MERCHANT_MODE_ORIGIN_KEY, STORE_MODE_KEY];
/// PIX flags, stored by [`PixFlagsStore`] under its own prefix.
const PIX_FLAGS: [PixFlag; 4] = [
    PixFlag::LbtcWarningShown,
    PixFlag::MainFirstTimeDialogShown,
    PixFlag::MerchantFirstTimeDialogShown,
    PixFlag::TutorialShown,
];

/// Text form of a preference value: strings without quotes, the rest as JSON.
fn raw_text(value: &Value) -> String {
    match value {
        Value::String(s) => s.clone(),
        other => other.to_string(),
    }
}

async fn import_preferences<K: KvStore + Clone>(
    kv: &K,
    snapshot: &LegacySnapshot,
    report: &mut MigrationReport,
) -> Result<()> {
    let flags = PixFlagsStore::new(kv.clone());
    let nodes = NodeSettings::new(kv.clone());
    for (key, value) in &snapshot.preferences {
        if key.starts_with("cached_price_") {
            continue;
        }
        if let Some(flag) = PIX_FLAGS.iter().find(|f| f.prefs_key() == key) {
            if value.as_bool() == Some(true) {
                flags.set(*flag).await?;
            }
        } else if key == "bitcoin_node_url" || key == "liquid_node_url" {
            let chain = if key == "bitcoin_node_url" { ChainId::Bitcoin } else { ChainId::Liquid };
            match value.as_str() {
                Some(url) => nodes.set_node_url(chain, url).await?,
                None => {
                    report.skip("preferences", key.clone(), "node url is not a string");
                    continue;
                }
            }
        } else if RAW_TEXT_PREFS.contains(&key.as_str()) {
            kv.put(key, raw_text(value).into_bytes()).await?;
        } else if JSON_PREFS.contains(&key.as_str()) {
            put_json(kv, key, value).await?;
        } else {
            put_json(kv, &format!("{PREFS_PREFIX}{key}"), value).await?;
        }
        report.count("preferences");
    }
    Ok(())
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use std::sync::Arc;

    use serde_json::json;

    use super::*;
    use crate::domain::{TransactionDirection, TransactionStatus};
    use crate::merchant::MerchantModeStore;
    use crate::testing::{block_on, FixedClock, MemoryKv};

    const NOW: u64 = 1_759_686_400_000;

    /// A snapshot with the shapes the app's exporter writes.
    fn snapshot_json() -> serde_json::Value {
        json!({
            "version": 1,
            "transactions": [
                {"id": "aa", "chain": "liquid", "direction": "incoming", "status": "confirmed",
                 "amount_sat": 5000, "fee_sat": 0, "timestamp_ms": 1_700_000_000_000u64, "confirmations": 3,
                 "asset_id": "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d",
                 "label": "rent", "source": "lwk"},
                {"id": "bb", "chain": "bitcoin", "direction": "swap", "status": "pending",
                 "amount_sat": 20000, "fee_sat": 150, "timestamp_ms": 1_700_000_100_000u64,
                 "from_asset_id": "btc-native-blockchain", "to_asset_id": "6f02", "sent_amount_sat": 20000,
                 "received_amount_sat": 19800, "source": null}
            ],
            "notified_tx_ids": [
                {"chain": "liquid", "tx_id": "aa", "notified_at_ms": 1},
                {"chain": "dogecoin", "tx_id": "zz", "notified_at_ms": 2}
            ],
            "notification_meta": {"baseline_completed": "1", "wallet_imported_at_ms": "1690000000000"},
            "swaps": [
                {"id": 7, "send_asset": "LBTC", "receive_asset": "USDT", "send_amount": 1000, "receive_amount": 650,
                 "created_at_ms": 1_700_000_000_000u64, "provider": "sideswap", "status": "completed",
                 "direction": "asset_swap", "tx_id": "cc", "metadata": null, "wallet_id": "w1"}
            ],
            "pegs": [
                {"order_id": "ord1", "peg_in": true, "sideswap_address": "bc1qdeposit", "payout_address": "lq1payout",
                 "amount": 100000, "created_at_ms": 1_700_000_000_000u64, "wallet_id": "w1", "status": "pending",
                 "provider": "sideswap", "funding_tx_id": "ff", "payout_tx_id": null, "error_message": null,
                 "updated_at_ms": 1_700_000_050_000u64, "metadata": "{\"fee\":12}"},
                {"order_id": "ord2", "peg_in": false, "sideswap_address": "lq1x", "payout_address": "bc1x",
                 "amount": -5, "created_at_ms": 1, "wallet_id": "w1", "status": "failed", "provider": "sideswap",
                 "funding_tx_id": null, "payout_tx_id": null, "error_message": null, "updated_at_ms": null,
                 "metadata": "not json"}
            ],
            "deposits": [
                {"deposit_id": "dep1", "asset_id": "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
                 "amount_in_cents": 2500, "created_at_ms": 1_700_000_000_000u64, "status": "finished",
                 "asset_amount": 2500000000i64, "blockchain_txid": "dd", "pix_key": "000201..."}
            ],
            "products": [
                {"id": 3, "name": "Café", "price": 7.5, "created_at_ms": 1_700_000_000_000u64}
            ],
            "sync_metadata": [
                {"datasource": "lwk", "last_sync_time_ms": 1_700_000_000_000u64, "transaction_count": 42, "sync_status": "ok"}
            ],
            "favorite_payers": [
                {"id": 4, "label": "Ana", "cpf": "12345678901", "created_at_ms": 1_700_000_000_000u64},
                {"id": 5, "label": "Bad", "cpf": "123", "created_at_ms": 1}
            ],
            "preferences": {
                "hasSeenPixTutorial": true,
                "lbtc_fluctuation_warning_shown": false,
                "merchant_mode_active": true,
                "merchant_mode_origin": "settings",
                "storeMode": false,
                "device_id": "dev-123",
                "user_verification_level": 2,
                "bitcoin_node_url": "ssl://my.node:50002",
                "liquid_node_url": "",
                "favorite_assets": ["btc", "usdt"],
                "cached_price_btc": "{}"
            }
        })
    }

    fn run(kv: &MemoryKv) -> MigrationReport {
        let snapshot = parse_snapshot(&serde_json::to_vec(&snapshot_json()).unwrap()).unwrap();
        let clock = Arc::new(FixedClock::new(NOW));
        block_on(import_flutter_data(kv, &clock, &snapshot)).unwrap()
    }

    #[test]
    fn copies_every_table_into_its_store() {
        let kv = MemoryKv::new();
        let report = run(&kv);
        assert!(!report.already_done);
        assert_eq!(report.copied["transactions"], 2);
        assert_eq!(report.copied["notified_tx_ids"], 1);
        assert_eq!(report.copied["notification_meta"], 2);
        assert_eq!(report.copied["swaps"], 1);
        assert_eq!(report.copied["pegs"], 1);
        assert_eq!(report.copied["deposits"], 1);
        assert_eq!(report.copied["products"], 1);
        assert_eq!(report.copied["sync_metadata"], 1);
        assert_eq!(report.copied["favorite_payers"], 1);
        let skipped: Vec<(&str, &str)> = report.skipped.iter().map(|s| (s.table.as_str(), s.key.as_str())).collect();
        assert!(skipped.contains(&("notified_tx_ids", "dogecoin:zz")));
        assert!(skipped.contains(&("pegs", "ord2")));
        assert!(skipped.contains(&("favorite_payers", "5")));

        block_on(async {
            // Transactions keep labels and swap pairing, which a rescan cannot rebuild.
            let txs = TransactionStore::new(kv.clone());
            let aa = txs.find_by_id("aa").await.unwrap().unwrap();
            assert_eq!(aa.label.as_deref(), Some("rent"));
            assert_eq!(aa.status, TransactionStatus::Confirmed);
            let bb = txs.find_by_id("bb").await.unwrap().unwrap();
            assert_eq!(bb.direction, TransactionDirection::Swap);
            assert_eq!(bb.received_amount_sat, Some(19800));

            let reg = NotifiedTxRegistry::new(kv.clone());
            assert!(reg.contains(ChainId::Liquid, "aa").await.unwrap());
            assert!(reg.is_baseline_complete().await.unwrap());
            assert_eq!(reg.imported_at_ms().await.unwrap(), Some(1_690_000_000_000));

            let pegs = KvPegStore::new(kv.clone(), Arc::new(FixedClock::new(NOW)), "w1");
            let p = pegs.get("ord1").await.unwrap().unwrap();
            assert_eq!(p.metadata, Some(json!({"fee": 12})));
            assert_eq!(p.funding_tx_id.as_deref(), Some("ff"));

            let deposits = DepositStore::new(kv.clone());
            let d = deposits.get_deposit("dep1").await.unwrap().unwrap();
            assert_eq!((d.amount_in_cents, d.asset_amount), (2500, Some(2_500_000_000)));

            let products = ProductStore::new(kv.clone());
            assert_eq!(products.get_by_id(3).await.unwrap().unwrap().name, "Café");
            // A new product never reuses an imported id.
            let new_id = products.create(&Product::new("Pão", 1.0, NOW)).await.unwrap();
            assert_eq!(new_id, 4);

            let payers = FavoritePayerStore::new(kv.clone());
            assert_eq!(payers.get_all().await.unwrap()[0].label, "Ana");
            assert_eq!(payers.insert("Bia", "98765432100", NOW).await.unwrap(), 5);

            let swaps = SwapAuditStore::new(kv.clone());
            assert_eq!(swaps.get(7).await.unwrap().unwrap().provider, "sideswap");

            let meta = SyncMetadataStore::new(kv.clone());
            assert_eq!(meta.get("lwk").await.unwrap().unwrap().transaction_count, 42);
        });
    }

    #[test]
    fn preferences_land_where_core_readers_look() {
        let kv = MemoryKv::new();
        run(&kv);
        block_on(async {
            let flags = PixFlagsStore::new(kv.clone());
            assert!(flags.is_set(PixFlag::TutorialShown).await.unwrap());
            assert!(!flags.is_set(PixFlag::LbtcWarningShown).await.unwrap());

            let merchant = MerchantModeStore::new(kv.clone());
            assert!(merchant.is_active().await.unwrap());
            assert_eq!(merchant.origin().await.unwrap(), "settings");

            assert_eq!(kv.get("device_id").await.unwrap(), Some(b"dev-123".to_vec()));
            assert_eq!(kv.get("user_verification_level").await.unwrap(), Some(b"2".to_vec()));

            let nodes = NodeSettings::new(kv.clone());
            assert_eq!(nodes.node_url(ChainId::Bitcoin).await.unwrap(), "ssl://my.node:50002");
            assert_eq!(nodes.node_url(ChainId::Liquid).await.unwrap(), "");

            assert_eq!(get_json::<_, Value>(&kv, "prefs/favorite_assets").await.unwrap(), Some(json!(["btc", "usdt"])));
            assert_eq!(kv.get("prefs/cached_price_btc").await.unwrap(), None);
        });
    }

    #[test]
    fn second_run_is_a_no_op() {
        let kv = MemoryKv::new();
        run(&kv);
        let keys_after_first = kv.len();
        let report = run(&kv);
        assert!(report.already_done);
        assert!(report.copied.is_empty());
        assert_eq!(kv.len(), keys_after_first);
        assert!(block_on(is_migrated(&kv)).unwrap());
    }

    #[test]
    fn rejects_unknown_snapshot_version() {
        let err = parse_snapshot(br#"{"version": 2}"#).unwrap_err();
        assert!(matches!(err, Error::InvalidInput(_)));
        // Missing tables default to empty.
        let empty = parse_snapshot(br#"{"version": 1}"#).unwrap();
        let kv = MemoryKv::new();
        let report = block_on(import_flutter_data(&kv, &Arc::new(FixedClock::new(NOW)), &empty)).unwrap();
        assert!(report.skipped.is_empty());
        assert!(block_on(is_migrated(&kv)).unwrap());
    }
}
