//! PIX persistence over [`KvStore`]. Replaces the drift `deposits` and
//! `favorite_payer_entries` tables and the PIX `SharedPreferences` flags.
//!
//! Keys:
//! - `pix/deposit/<deposit_id>`: [`DepositRecord`] JSON.
//! - `pix/favorite_payer/<id, 20 digits>`: favorite payer JSON.
//! - `pix/favorite_payer_seq`: last favorite payer id.
//! - `pix/flag/<dart prefs key>`: `true` for a set flag.

use serde::{de::DeserializeOwned, Deserialize, Serialize};

use crate::domain::Asset;
use crate::ports::KvStore;
use crate::{Error, Result};

use super::entities::{DepositStatus, FavoritePayer, PixDeposit};
use super::tax_id;

const DEPOSIT_PREFIX: &str = "pix/deposit/";
const PAYER_PREFIX: &str = "pix/favorite_payer/";
const PAYER_SEQ_KEY: &str = "pix/favorite_payer_seq";
const FLAG_PREFIX: &str = "pix/flag/";

/// Network name the repository reports for stored deposits.
pub const STORED_DEPOSIT_NETWORK: &str = "liquid";

async fn get_json<K: KvStore, T: DeserializeOwned>(kv: &K, key: &str) -> Result<Option<T>> {
    match kv.get(key).await? {
        Some(bytes) => serde_json::from_slice(&bytes)
            .map(Some)
            .map_err(Error::storage),
        None => Ok(None),
    }
}

async fn put_json<K: KvStore, T: Serialize>(kv: &K, key: &str, value: &T) -> Result<()> {
    let bytes = serde_json::to_vec(value).map_err(Error::storage)?;
    kv.put(key, bytes).await
}

async fn delete_prefix<K: KvStore>(kv: &K, prefix: &str) -> Result<()> {
    for key in kv.list_keys(prefix).await? {
        kv.delete(&key).await?;
    }
    Ok(())
}

// ---------------------------------------------------------------- deposits

/// One stored deposit. Mirrors the drift `Deposits` row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DepositRecord {
    /// Backend deposit id.
    pub deposit_id: String,
    /// PIX "copia e cola" payload.
    pub pix_key: String,
    /// Asset id.
    pub asset_id: String,
    /// Deposit amount in BRL cents.
    pub amount_in_cents: u64,
    /// Creation time, ms since the Unix epoch.
    pub created_at_ms: u64,
    /// Raw status string, as the API or the app wrote it.
    pub status: String,
    /// Asset amount in base units.
    pub asset_amount: Option<u64>,
    /// Liquid txid.
    pub blockchain_txid: Option<String>,
}

impl DepositRecord {
    /// Maps the row to a [`PixDeposit`].
    ///
    /// Unknown asset ids map to BTC, as Dart `Asset.fromId` does.
    pub fn to_deposit(&self) -> PixDeposit {
        PixDeposit {
            deposit_id: self.deposit_id.clone(),
            pix_key: self.pix_key.clone(),
            asset: Asset::from_id(&self.asset_id).unwrap_or(Asset::Btc),
            amount_in_cents: self.amount_in_cents,
            network: STORED_DEPOSIT_NETWORK.to_owned(),
            status: DepositStatus::from_api_str(&self.status),
            created_at_ms: self.created_at_ms,
            blockchain_txid: self.blockchain_txid.clone(),
            asset_amount: self.asset_amount,
        }
    }
}

/// Deposit store. Port of `PixDepositDatabase`.
///
/// Updates of a missing id do nothing, like a drift `UPDATE ... WHERE`.
#[derive(Debug, Clone)]
pub struct DepositStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> DepositStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    fn key(deposit_id: &str) -> String {
        format!("{DEPOSIT_PREFIX}{deposit_id}")
    }

    /// Inserts a deposit with status `pending`.
    ///
    // NOTE(port): drift has no unique index on deposit_id, so a second insert
    // adds a second row. Here it replaces the first.
    pub async fn add_new_deposit(
        &self,
        deposit_id: &str,
        pix_key: &str,
        asset_id: &str,
        amount_in_cents: u64,
        now_ms: u64,
    ) -> Result<()> {
        let rec = DepositRecord {
            deposit_id: deposit_id.to_owned(),
            pix_key: pix_key.to_owned(),
            asset_id: asset_id.to_owned(),
            amount_in_cents,
            created_at_ms: now_ms,
            status: "pending".to_owned(),
            asset_amount: None,
            blockchain_txid: None,
        };
        put_json(&self.kv, &Self::key(deposit_id), &rec).await
    }

    /// Writes an existing deposit unchanged, for a data migration.
    /// Replaces a deposit with the same id.
    pub async fn import(&self, rec: &DepositRecord) -> Result<()> {
        if rec.deposit_id.is_empty() {
            return Err(Error::invalid("imported deposit needs a deposit id"));
        }
        put_json(&self.kv, &Self::key(&rec.deposit_id), rec).await
    }

    async fn modify(&self, deposit_id: &str, f: impl FnOnce(&mut DepositRecord)) -> Result<()> {
        let key = Self::key(deposit_id);
        let Some(mut rec) = get_json::<K, DepositRecord>(&self.kv, &key).await? else {
            return Ok(());
        };
        f(&mut rec);
        put_json(&self.kv, &key, &rec).await
    }

    /// Sets the status.
    pub async fn update_deposit_status(&self, deposit_id: &str, status: &str) -> Result<()> {
        let status = status.to_owned();
        self.modify(deposit_id, move |r| r.status = status).await
    }

    /// Sets the status, and the amount and txid when present.
    pub async fn update_deposit(
        &self,
        deposit_id: &str,
        status: &str,
        asset_amount: Option<u64>,
        blockchain_txid: Option<&str>,
    ) -> Result<()> {
        let status = status.to_owned();
        let txid = blockchain_txid.map(str::to_owned);
        self.modify(deposit_id, move |r| {
            r.status = status;
            if asset_amount.is_some() {
                r.asset_amount = asset_amount;
            }
            if txid.is_some() {
                r.blockchain_txid = txid;
            }
        })
        .await
    }

    /// Sets the amount and txid. Leaves the status as is, as in Dart.
    pub async fn mark_deposit_as_completed(
        &self,
        deposit_id: &str,
        asset_amount: u64,
        blockchain_txid: &str,
    ) -> Result<()> {
        let txid = blockchain_txid.to_owned();
        self.modify(deposit_id, move |r| {
            r.asset_amount = Some(asset_amount);
            r.blockchain_txid = Some(txid);
        })
        .await
    }

    /// Reads one deposit.
    pub async fn get_deposit(&self, deposit_id: &str) -> Result<Option<DepositRecord>> {
        get_json(&self.kv, &Self::key(deposit_id)).await
    }

    /// Lists deposits, newest first. `offset` applies only with a `limit`.
    pub async fn get_deposits(
        &self,
        limit: Option<usize>,
        offset: Option<usize>,
    ) -> Result<Vec<DepositRecord>> {
        let mut all = Vec::new();
        for key in self.kv.list_keys(DEPOSIT_PREFIX).await? {
            if let Some(rec) = get_json::<K, DepositRecord>(&self.kv, &key).await? {
                all.push(rec);
            }
        }
        all.sort_by_key(|r| std::cmp::Reverse(r.created_at_ms));
        Ok(match limit {
            Some(l) => all.into_iter().skip(offset.unwrap_or(0)).take(l).collect(),
            None => all,
        })
    }

    /// Deletes every deposit (wallet delete or import).
    pub async fn clear_all_deposits(&self) -> Result<()> {
        delete_prefix(&self.kv, DEPOSIT_PREFIX).await
    }
}

// ---------------------------------------------------------------- favorite payers

/// Why a favorite payer save was refused.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FavoritePayerSaveError {
    /// Another payer already has this CPF/CNPJ.
    DuplicateCpf,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
struct PayerRecord {
    id: u64,
    label: String,
    cpf: String,
    created_at_ms: u64,
}

/// Favorite payer store. Port of the datasource, repository and controller.
#[derive(Debug, Clone)]
pub struct FavoritePayerStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> FavoritePayerStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    fn key(id: u64) -> String {
        format!("{PAYER_PREFIX}{id:020}")
    }

    /// Column limits of the drift table: label 1 to 255 chars, cpf 11 to 14.
    fn check_columns(label: &str, cpf: &str) -> Result<()> {
        let l = label.chars().count();
        if !(1..=255).contains(&l) {
            return Err(Error::invalid(
                "favorite payer label must have 1 to 255 characters",
            ));
        }
        let c = cpf.chars().count();
        if !(11..=14).contains(&c) {
            return Err(Error::invalid(
                "favorite payer cpf must have 11 to 14 characters",
            ));
        }
        Ok(())
    }

    async fn records(&self) -> Result<Vec<PayerRecord>> {
        let mut out = Vec::new();
        for key in self.kv.list_keys(PAYER_PREFIX).await? {
            if let Some(r) = get_json::<K, PayerRecord>(&self.kv, &key).await? {
                out.push(r);
            }
        }
        Ok(out)
    }

    /// Every payer, newest first (ties: higher id first).
    pub async fn get_all(&self) -> Result<Vec<FavoritePayer>> {
        let mut recs = self.records().await?;
        recs.sort_by(|a, b| b.created_at_ms.cmp(&a.created_at_ms).then(b.id.cmp(&a.id)));
        Ok(recs
            .into_iter()
            .map(|r| FavoritePayer {
                id: Some(r.id),
                label: r.label,
                cpf: r.cpf,
            })
            .collect())
    }

    /// Inserts a payer and returns its new id. Ids are never reused.
    pub async fn insert(&self, label: &str, cpf: &str, now_ms: u64) -> Result<u64> {
        Self::check_columns(label, cpf)?;
        let last: u64 = get_json(&self.kv, PAYER_SEQ_KEY).await?.unwrap_or(0);
        let id = last + 1;
        put_json(&self.kv, PAYER_SEQ_KEY, &id).await?;
        let rec = PayerRecord {
            id,
            label: label.to_owned(),
            cpf: cpf.to_owned(),
            created_at_ms: now_ms,
        };
        put_json(&self.kv, &Self::key(id), &rec).await?;
        Ok(id)
    }

    /// Writes an existing payer with its original id and creation time,
    /// for a data migration. Replaces a payer with the same id. Later
    /// inserts get higher ids.
    pub async fn import(&self, id: u64, label: &str, cpf: &str, created_at_ms: u64) -> Result<()> {
        Self::check_columns(label, cpf)?;
        if id == 0 {
            return Err(Error::invalid(
                "imported favorite payer needs a positive id",
            ));
        }
        let rec = PayerRecord {
            id,
            label: label.to_owned(),
            cpf: cpf.to_owned(),
            created_at_ms,
        };
        put_json(&self.kv, &Self::key(id), &rec).await?;
        let last: u64 = get_json(&self.kv, PAYER_SEQ_KEY).await?.unwrap_or(0);
        if id > last {
            put_json(&self.kv, PAYER_SEQ_KEY, &id).await?;
        }
        Ok(())
    }

    /// Updates label and cpf. A missing id does nothing.
    pub async fn update(&self, id: u64, label: &str, cpf: &str) -> Result<()> {
        Self::check_columns(label, cpf)?;
        let key = Self::key(id);
        let Some(mut rec) = get_json::<K, PayerRecord>(&self.kv, &key).await? else {
            return Ok(());
        };
        rec.label = label.to_owned();
        rec.cpf = cpf.to_owned();
        put_json(&self.kv, &key, &rec).await
    }

    /// Inserts when `payer.id` is `None`, else updates.
    pub async fn save(&self, payer: &FavoritePayer, now_ms: u64) -> Result<()> {
        match payer.id {
            None => self
                .insert(&payer.label, &payer.cpf, now_ms)
                .await
                .map(|_| ()),
            Some(id) => self.update(id, &payer.label, &payer.cpf).await,
        }
    }

    /// Deletes one payer.
    pub async fn delete(&self, id: u64) -> Result<()> {
        self.kv.delete(&Self::key(id)).await
    }

    /// True if a payer other than `excluding_id` has `cpf`.
    pub async fn cpf_exists(&self, cpf: &str, excluding_id: Option<u64>) -> Result<bool> {
        Ok(self
            .records()
            .await?
            .iter()
            .any(|r| r.cpf == cpf && Some(r.id) != excluding_id))
    }

    /// Controller save: strips the CPF mask, rejects duplicates, trims the label.
    pub async fn save_checked(
        &self,
        id: Option<u64>,
        label: &str,
        cpf: &str,
        now_ms: u64,
    ) -> Result<Option<FavoritePayerSaveError>> {
        let digits = tax_id::strip(cpf);
        if self.cpf_exists(&digits, id).await? {
            return Ok(Some(FavoritePayerSaveError::DuplicateCpf));
        }
        self.save(
            &FavoritePayer {
                id,
                label: label.trim().to_owned(),
                cpf: digits,
            },
            now_ms,
        )
        .await?;
        Ok(None)
    }

    /// Deletes every payer (wallet delete or import). Keeps the id sequence.
    pub async fn clear_all(&self) -> Result<()> {
        delete_prefix(&self.kv, PAYER_PREFIX).await
    }
}

// ---------------------------------------------------------------- flags

/// One-time PIX flags, formerly in `SharedPreferences`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PixFlag {
    /// L-BTC price fluctuation warning shown.
    LbtcWarningShown,
    /// Main PIX first-time dialog accepted.
    MainFirstTimeDialogShown,
    /// Merchant PIX first-time dialog accepted.
    MerchantFirstTimeDialogShown,
    /// PIX tutorial finished or skipped.
    TutorialShown,
}

impl PixFlag {
    /// Dart `SharedPreferences` key.
    pub fn prefs_key(self) -> &'static str {
        match self {
            PixFlag::LbtcWarningShown => "lbtc_fluctuation_warning_shown",
            PixFlag::MainFirstTimeDialogShown => "pix_main_first_time_dialog_shown",
            PixFlag::MerchantFirstTimeDialogShown => "pix_merchant_first_time_dialog_shown",
            PixFlag::TutorialShown => "hasSeenPixTutorial",
        }
    }
}

/// Flag store. Port of `LbtcWarningService`, `PixOnboardingService` and
/// `PixTutorialService`.
#[derive(Debug, Clone)]
pub struct PixFlagsStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> PixFlagsStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    fn key(flag: PixFlag) -> String {
        format!("{FLAG_PREFIX}{}", flag.prefs_key())
    }

    /// True if set. Absent means false.
    pub async fn is_set(&self, flag: PixFlag) -> Result<bool> {
        Ok(get_json::<K, bool>(&self.kv, &Self::key(flag))
            .await?
            .unwrap_or(false))
    }

    /// Sets the flag.
    pub async fn set(&self, flag: PixFlag) -> Result<()> {
        put_json(&self.kv, &Self::key(flag), &true).await
    }

    /// Clears the flag.
    pub async fn reset(&self, flag: PixFlag) -> Result<()> {
        self.kv.delete(&Self::key(flag)).await
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::domain::DEPIX_ASSET_ID;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn deposit_roundtrip_and_updates() {
        let s = DepositStore::new(MemoryKv::new());
        block_on(async {
            s.add_new_deposit("dep-1", "qr-1", DEPIX_ASSET_ID, 1000, 100)
                .await
                .unwrap();
            s.add_new_deposit("dep-2", "qr-2", "bogus-asset", 2000, 200)
                .await
                .unwrap();
            let all = s.get_deposits(None, None).await.unwrap();
            assert_eq!(
                all.iter()
                    .map(|r| r.deposit_id.as_str())
                    .collect::<Vec<_>>(),
                vec!["dep-2", "dep-1"]
            );
            assert_eq!(all[0].to_deposit().asset, Asset::Btc);
            assert_eq!(all[1].to_deposit().asset, Asset::Depix);
            assert_eq!(all[1].to_deposit().status, DepositStatus::Pending);

            s.update_deposit("dep-1", "depix_sent", Some(990), None)
                .await
                .unwrap();
            s.update_deposit("dep-1", "finished", None, Some("tx1"))
                .await
                .unwrap();
            let r = s.get_deposit("dep-1").await.unwrap().unwrap();
            assert_eq!(
                (
                    r.status.as_str(),
                    r.asset_amount,
                    r.blockchain_txid.as_deref()
                ),
                ("finished", Some(990), Some("tx1"))
            );

            s.mark_deposit_as_completed("dep-2", 5, "tx2")
                .await
                .unwrap();
            s.update_deposit_status("dep-2", "expired").await.unwrap();
            s.update_deposit_status("missing", "expired").await.unwrap();
            assert!(s.get_deposit("missing").await.unwrap().is_none());

            let page = s.get_deposits(Some(1), Some(1)).await.unwrap();
            assert_eq!(page[0].deposit_id, "dep-1");
            assert_eq!(s.get_deposits(None, Some(1)).await.unwrap().len(), 2);

            s.clear_all_deposits().await.unwrap();
            assert!(s.get_deposits(None, None).await.unwrap().is_empty());
            assert!(s.get_deposit("dep-1").await.unwrap().is_none());
        });
    }

    #[test]
    fn favorite_payers_controller_flow() {
        let s = FavoritePayerStore::new(MemoryKv::new());
        block_on(async {
            assert!(s.get_all().await.unwrap().is_empty());
            assert_eq!(
                s.save_checked(None, " João ", "529.982.247-25", 1)
                    .await
                    .unwrap(),
                None
            );
            let list = s.get_all().await.unwrap();
            assert_eq!(
                (list[0].label.as_str(), list[0].cpf.as_str()),
                ("João", "52998224725")
            );
            assert_eq!(
                s.save_checked(None, "Outro", "52998224725", 2)
                    .await
                    .unwrap(),
                Some(FavoritePayerSaveError::DuplicateCpf)
            );
            let id = list[0].id.unwrap();
            assert_eq!(
                s.save_checked(Some(id), "João S.", "52998224725", 3)
                    .await
                    .unwrap(),
                None
            );
            assert_eq!(s.get_all().await.unwrap()[0].label, "João S.");

            s.save_checked(None, "Empresa", "11222333000181", 4)
                .await
                .unwrap();
            let all = s.get_all().await.unwrap();
            assert_eq!(all[0].label, "Empresa");
            assert!(s.insert("", "52998224725", 5).await.is_err());
            assert!(s.insert("x", "123", 5).await.is_err());

            s.delete(id).await.unwrap();
            assert_eq!(s.get_all().await.unwrap().len(), 1);
            s.clear_all().await.unwrap();
            assert!(s.get_all().await.unwrap().is_empty());
            // Ids are never reused after a clear.
            assert_eq!(s.insert("y", "52998224725", 6).await.unwrap(), 3);
        });
    }

    #[test]
    fn flags() {
        let s = PixFlagsStore::new(MemoryKv::new());
        block_on(async {
            assert!(!s.is_set(PixFlag::TutorialShown).await.unwrap());
            s.set(PixFlag::TutorialShown).await.unwrap();
            assert!(s.is_set(PixFlag::TutorialShown).await.unwrap());
            assert!(!s.is_set(PixFlag::LbtcWarningShown).await.unwrap());
            s.reset(PixFlag::TutorialShown).await.unwrap();
            assert!(!s.is_set(PixFlag::TutorialShown).await.unwrap());
        });
    }
}
