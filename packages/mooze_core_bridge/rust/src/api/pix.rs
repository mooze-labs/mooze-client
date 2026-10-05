//! PIX deposits, favorite payers, PIX flags and taxpayer ids.
//!
//! Replaces the Dart `PixRepositoryImpl`, `PixDepositDatabase`,
//! `FavoritePayersRepositoryImpl`, the PIX `SharedPreferences` flags and the
//! CPF/CNPJ helpers. Deposits pay to the connected Liquid wallet. Backend
//! calls use the core session (see `authEnsureSession`).
//!
//! The core runs no timers. After `pixCreateDeposit`, call `pixPollTick`
//! every `pixPollIntervalMs` and handle the events it returns.

use flutter_rust_bridge::frb;
use mooze_core::adapters::SessionTokens;
use mooze_core::domain::Asset;
use mooze_core::pix::client::create_deposit_error_message;
use mooze_core::pix::rules::{self, DepositLimits, DepositValidationError, DEPOSIT_POLL_INTERVAL_MS};
use mooze_core::pix::store::FavoritePayerSaveError;
use mooze_core::pix::tax_id::{self, CpfValidationError};
use mooze_core::pix::{DepositStore, FavoritePayerStore, PixClient, PixFlagsStore, PixService};
use mooze_core::ports::{Clock, ReqwestHttpClient};

use super::core::{auth, Inner, MoozeCore, SerializedSession};
pub use super::types::*;
use crate::glue::LiquidPort;
use crate::ports::{on_runtime, FileKv, SystemClock};

type Pix = PixService<ReqwestHttpClient, SessionTokens<SerializedSession>, FileKv, LiquidPort>;

/// PIX service with the current session, base URL and Liquid wallet.
async fn pix_service(inner: &std::sync::Arc<Inner>) -> mooze_core::Result<Pix> {
    let auth = auth(inner).await?;
    let client = PixClient::new(ReqwestHttpClient::default(), SessionTokens(auth.session.clone()), inner.api_base_url());
    Ok(PixService::new(client, DepositStore::new(inner.kv.clone()), LiquidPort::new(inner)))
}

fn invalid(message: impl Into<String>) -> CoreError {
    CoreError { kind: CoreErrorKind::InvalidInput, message: message.into() }
}

// ───────────────────────────── pure helpers

/// Time between `pixPollTick` calls, in ms.
#[frb(sync)]
pub fn pix_poll_interval_ms() -> u32 {
    DEPOSIT_POLL_INTERVAL_MS as u32
}

/// Fee breakdown for `amount_brl`. Pass the asset price in BRL to get the
/// estimated asset amount.
#[frb(sync)]
pub fn pix_fee(amount_brl: f64, has_referral: bool, quote_brl: Option<f64>) -> PixFeeDto {
    PixFeeDto {
        fee_rate_percent: rules::fee_rate_percent(amount_brl, has_referral),
        fee_amount: rules::fee_amount(amount_brl, has_referral),
        discounted_amount: rules::discounted_deposit_amount(amount_brl, has_referral),
        estimated_asset_units: quote_brl
            .filter(|q| *q > 0.0)
            .map(|q| rules::estimated_asset_units(amount_brl, has_referral, q)),
        active_tier: rules::active_fee_tier(amount_brl).map(|i| i as u32),
        amount_in_cents: rules::amount_in_cents(amount_brl),
    }
}

/// Validates a deposit amount in BRL. Pass `None` while the limits load:
/// every positive amount is then valid, as in Dart.
#[frb(sync)]
pub fn pix_validate_amount(amount_brl: f64, limits: Option<DepositLimitsDto>) -> DepositValidationDto {
    let limits = limits.map(|l| DepositLimits { absolute_min_limit: l.absolute_min_limit, allowed_spending: l.allowed_spending });
    let v = rules::validate_deposit_amount(amount_brl, limits.as_ref());
    DepositValidationDto {
        is_valid: v.is_valid(),
        error: v.error.map(|e| match e {
            DepositValidationError::InvalidAmount => DepositValidationErrorDto::InvalidAmount,
            DepositValidationError::BelowMinimum => DepositValidationErrorDto::BelowMinimum,
            DepositValidationError::AboveTransaction => DepositValidationErrorDto::AboveTransaction,
            DepositValidationError::AboveRemaining => DepositValidationErrorDto::AboveRemaining,
        }),
        limit_amount: v.limit_amount,
    }
}

/// Validates a CPF (11 digits) or CNPJ (14 digits), masked or raw.
/// Returns `None` when valid.
#[frb(sync)]
pub fn tax_id_validate(input: String) -> Option<CpfValidationErrorDto> {
    tax_id::validate(&input).map(|e| match e {
        CpfValidationError::Empty => CpfValidationErrorDto::Empty,
        CpfValidationError::Incomplete => CpfValidationErrorDto::Incomplete,
        CpfValidationError::Invalid => CpfValidationErrorDto::Invalid,
    })
}

/// True if `input` is a valid CPF or CNPJ.
#[frb(sync)]
pub fn tax_id_is_valid(input: String) -> bool {
    tax_id::is_valid(&input)
}

/// Keeps only the digits.
#[frb(sync)]
pub fn tax_id_strip(input: String) -> String {
    tax_id::strip(&input)
}

/// Formats digits as CPF (up to 11) or CNPJ (12 or more).
#[frb(sync)]
pub fn tax_id_format(digits: String) -> String {
    tax_id::format_cpf_cnpj(&digits)
}

/// Live input mask (Dart `CpfCnpjInputFormatter`): strips, caps at 14
/// digits, formats.
#[frb(sync)]
pub fn tax_id_mask_input(text: String) -> String {
    tax_id::mask_cpf_cnpj_input(&text)
}

/// True if `value` looks like a PIX key or a BR Code payload
/// (Dart `PixKeyDetector`).
#[frb(sync)]
pub fn pix_looks_like_key(value: String) -> bool {
    tax_id::looks_like_pix_key(&value)
}

// ───────────────────────────── MoozeCore

impl MoozeCore {
    /// Creates a PIX deposit (Dart `PixRepository.newDeposit`).
    ///
    /// Pays to `address`, or to a new address of the connected Liquid wallet
    /// when `None`. Stores the deposit and starts polling its status. A
    /// backend failure throws with the Portuguese text the Dart UI showed.
    pub async fn pix_create_deposit(
        &self,
        amount_in_cents: u64,
        asset_id: String,
        tax_id_number: Option<String>,
        address: Option<String>,
    ) -> Result<PixDepositDto, CoreError> {
        let asset = Asset::from_id(&asset_id).ok_or_else(|| invalid(format!("unknown asset id {asset_id}")))?;
        let inner = self.inner.clone();
        let result = on_runtime(async move {
            let service = pix_service(&inner).await?;
            let now = SystemClock.now_ms();
            let created = match address {
                Some(a) => service.new_deposit_to_address(amount_in_cents, &a, asset, tax_id_number, now).await,
                None => service.new_deposit(amount_in_cents, asset, tax_id_number, now).await,
            };
            let outcome = match created {
                Ok(o) => o,
                Err(e) => return Ok(Err(e)),
            };
            inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()).push(outcome.poll);
            Ok(Ok(outcome.deposit))
        })
        .await?;
        match result {
            Ok(deposit) => Ok(deposit.into()),
            Err(e @ (mooze_core::Error::Network(_) | mooze_core::Error::Http { .. })) => {
                Err(CoreError { kind: CoreErrorKind::Network, message: create_deposit_error_message(&e) })
            }
            Err(e @ mooze_core::Error::Timeout(_)) => {
                Err(CoreError { kind: CoreErrorKind::Timeout, message: create_deposit_error_message(&e) })
            }
            Err(e) => Err(e.into()),
        }
    }

    /// Runs one poll tick for every deposit created in this session and
    /// returns the status changes (Dart `statusUpdates` stream). Call it
    /// every `pixPollIntervalMs`. Expired and changed deposits stop polling.
    pub async fn pix_poll_tick(&self) -> Result<Vec<PixStatusEventDto>, CoreError> {
        let inner = self.inner.clone();
        let events = on_runtime(async move {
            let mut polls = std::mem::take(&mut *inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()));
            if polls.is_empty() {
                return Ok(Vec::new());
            }
            let service = match pix_service(&inner).await {
                Ok(s) => s,
                Err(e) => {
                    // Keep the polls for the next tick.
                    inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()).extend(polls);
                    return Err(e);
                }
            };
            let mut events = Vec::new();
            for poll in &mut polls {
                events.extend(service.poll_tick(poll, SystemClock.now_ms()).await);
            }
            polls.retain(|p| !p.is_finished());
            inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()).extend(polls);
            Ok(events)
        })
        .await?;
        Ok(events.into_iter().map(Into::into).collect())
    }

    /// Number of deposits still polled.
    pub async fn pix_active_polls(&self) -> u32 {
        self.inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()).len() as u32
    }

    /// Stops polling every deposit (Dart `PixRepository.dispose`).
    pub async fn pix_cancel_polls(&self) {
        self.inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()).clear();
    }

    /// Reads one stored deposit.
    pub async fn pix_get_deposit(&self, deposit_id: String) -> Result<Option<PixDepositDto>, CoreError> {
        let store = DepositStore::new(self.inner.kv.clone());
        let rec = on_runtime(async move { store.get_deposit(&deposit_id).await }).await?;
        Ok(rec.map(|r| r.to_deposit().into()))
    }

    /// Stored deposits, newest first. `offset` applies only with a `limit`.
    pub async fn pix_list_deposits(&self, limit: Option<u32>, offset: Option<u32>) -> Result<Vec<PixDepositDto>, CoreError> {
        let store = DepositStore::new(self.inner.kv.clone());
        let recs = on_runtime(async move { store.get_deposits(limit.map(|l| l as usize), offset.map(|o| o as usize)).await })
            .await?;
        Ok(recs.iter().map(|r| r.to_deposit().into()).collect())
    }

    /// Refreshes deposits from the backend and returns the stored ones with
    /// these ids (Dart `updateDepositDetails`).
    pub async fn pix_update_deposit_details(&self, deposit_ids: Vec<String>) -> Result<Vec<PixDepositDto>, CoreError> {
        let inner = self.inner.clone();
        let list = on_runtime(async move { pix_service(&inner).await?.update_deposit_details(&deposit_ids).await }).await?;
        Ok(list.into_iter().map(Into::into).collect())
    }

    /// History page: stored deposits, with a backend refresh of the
    /// non-terminal ones (Dart `PixHistoryController`). A failed refresh
    /// returns the local data.
    pub async fn pix_history(&self, limit: Option<u32>, offset: Option<u32>) -> Result<Vec<PixDepositDto>, CoreError> {
        let inner = self.inner.clone();
        let list = on_runtime(async move {
            let (limit, offset) = (limit.map(|l| l as usize), offset.map(|o| o as usize));
            match pix_service(&inner).await {
                Ok(service) => service.get_pix_history(limit, offset).await,
                // Without a session, show what is stored.
                Err(_) => Ok(DepositStore::new(inner.kv.clone())
                    .get_deposits(limit, offset)
                    .await?
                    .iter()
                    .map(|r| r.to_deposit())
                    .collect()),
            }
        })
        .await?;
        Ok(list.into_iter().map(Into::into).collect())
    }

    /// Deletes every stored deposit and stops polling (wallet delete or import).
    pub async fn pix_clear_deposits(&self) -> Result<(), CoreError> {
        self.pix_cancel_polls().await;
        let store = DepositStore::new(self.inner.kv.clone());
        Ok(on_runtime(async move { store.clear_all_deposits().await }).await?)
    }

    // ───────────────────────────── favorite payers

    /// Every favorite payer, newest first.
    pub async fn favorite_payers_list(&self) -> Result<Vec<FavoritePayerDto>, CoreError> {
        let store = FavoritePayerStore::new(self.inner.kv.clone());
        let list = on_runtime(async move { store.get_all().await }).await?;
        Ok(list.into_iter().map(Into::into).collect())
    }

    /// Inserts (`id` null) or updates a payer, as the Dart controller does:
    /// strips the CPF mask, trims the label, refuses a CPF that another
    /// payer has. Returns the refusal reason, or `null` when saved.
    pub async fn favorite_payer_save(
        &self,
        id: Option<u64>,
        label: String,
        cpf: String,
    ) -> Result<Option<FavoritePayerSaveErrorDto>, CoreError> {
        let store = FavoritePayerStore::new(self.inner.kv.clone());
        let refused = on_runtime(async move { store.save_checked(id, &label, &cpf, SystemClock.now_ms()).await }).await?;
        Ok(refused.map(|FavoritePayerSaveError::DuplicateCpf| FavoritePayerSaveErrorDto::DuplicateCpf))
    }

    /// Deletes one payer.
    pub async fn favorite_payer_delete(&self, id: u64) -> Result<(), CoreError> {
        let store = FavoritePayerStore::new(self.inner.kv.clone());
        Ok(on_runtime(async move { store.delete(id).await }).await?)
    }

    /// True if a payer other than `excluding_id` has `cpf` (digits, or masked).
    pub async fn favorite_payer_cpf_exists(&self, cpf: String, excluding_id: Option<u64>) -> Result<bool, CoreError> {
        let store = FavoritePayerStore::new(self.inner.kv.clone());
        Ok(on_runtime(async move { store.cpf_exists(&tax_id::strip(&cpf), excluding_id).await }).await?)
    }

    /// Deletes every payer (wallet delete or import).
    pub async fn favorite_payers_clear(&self) -> Result<(), CoreError> {
        let store = FavoritePayerStore::new(self.inner.kv.clone());
        Ok(on_runtime(async move { store.clear_all().await }).await?)
    }

    // ───────────────────────────── flags

    /// True if `flag` is set.
    pub async fn pix_flag_is_set(&self, flag: PixFlagDto) -> Result<bool, CoreError> {
        let store = PixFlagsStore::new(self.inner.kv.clone());
        Ok(on_runtime(async move { store.is_set(flag.into()).await }).await?)
    }

    /// Sets `flag`.
    pub async fn pix_flag_set(&self, flag: PixFlagDto) -> Result<(), CoreError> {
        let store = PixFlagsStore::new(self.inner.kv.clone());
        Ok(on_runtime(async move { store.set(flag.into()).await }).await?)
    }

    /// Clears `flag`.
    pub async fn pix_flag_reset(&self, flag: PixFlagDto) -> Result<(), CoreError> {
        let store = PixFlagsStore::new(self.inner.kv.clone());
        Ok(on_runtime(async move { store.reset(flag.into()).await }).await?)
    }
}

#[cfg(test)]
mod tests {
    use std::sync::{Arc, Mutex as StdMutex};

    use mooze_core::domain::DEPIX_ASSET_ID;
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use tokio::net::TcpListener;

    use super::*;
    use crate::api::core::tests::{open_core, with_memory_store, ABANDON, JWT_1};
    use crate::ports::runtime;

    /// One request the mock backend saw: method, path, authorization, body.
    type Seen = (String, String, Option<String>, String);

    /// HTTP/1.1 backend on 127.0.0.1, one request per connection.
    /// `POST /v2/transactions` creates `dep-1`; the status call reports it sent.
    async fn pix_backend() -> (String, Arc<StdMutex<Vec<Seen>>>) {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let base = format!("http://{}", listener.local_addr().unwrap());
        let seen = Arc::new(StdMutex::new(Vec::new()));
        let log = seen.clone();
        tokio::spawn(async move {
            loop {
                let (mut tcp, _) = listener.accept().await.unwrap();
                let log = log.clone();
                tokio::spawn(async move {
                    let mut buf = Vec::new();
                    let mut chunk = [0u8; 4096];
                    let head_end = loop {
                        let n = tcp.read(&mut chunk).await.unwrap();
                        buf.extend_from_slice(&chunk[..n]);
                        if let Some(i) = buf.windows(4).position(|w| w == b"\r\n\r\n") {
                            break i + 4;
                        }
                    };
                    let head = String::from_utf8_lossy(&buf[..head_end]).into_owned();
                    let header = |name: &str| {
                        head.lines()
                            .find_map(|l| l.split_once(':').filter(|(k, _)| k.eq_ignore_ascii_case(name)))
                            .map(|(_, v)| v.trim().to_owned())
                    };
                    let len: usize = header("content-length").and_then(|v| v.parse().ok()).unwrap_or(0);
                    while buf.len() < head_end + len {
                        let n = tcp.read(&mut chunk).await.unwrap();
                        buf.extend_from_slice(&chunk[..n]);
                    }
                    let mut first = head.lines().next().unwrap().split(' ');
                    let (method, path) = (first.next().unwrap().to_owned(), first.next().unwrap().to_owned());
                    let body = String::from_utf8_lossy(&buf[head_end..head_end + len]).into_owned();
                    let (status, reply) = match (method.as_str(), path.as_str()) {
                        ("POST", "/v2/transactions") => (
                            200,
                            r#"{"data":{"transaction_id":"dep-1","qr_copy_paste":"qr-copy","qr_image_url":"https://img"}}"#,
                        ),
                        ("GET", "/transactions/status?ids=dep-1") => (
                            200,
                            r#"{"data":[{"id":"dep-1","status":"depix_sent","amount_in_cents":1000,"blockchain_txid":"tx9","asset_amount":970000}]}"#,
                        ),
                        _ => (404, "{}"),
                    };
                    log.lock().unwrap().push((method, path, header("authorization"), body));
                    let out = format!(
                        "HTTP/1.1 {status} X\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{reply}",
                        reply.len()
                    );
                    tcp.write_all(out.as_bytes()).await.unwrap();
                    tcp.shutdown().await.unwrap();
                });
            }
        });
        (base, seen)
    }

    #[test]
    fn deposit_create_poll_and_read_back() {
        let core = open_core("pix-deposit");
        let map = with_memory_store(&core);
        // A fresh stored session: no auth round trip.
        map.lock().unwrap().insert("mnemonic_mainWallet".into(), ABANDON.into());
        map.lock().unwrap().insert("jwt".into(), JWT_1.into());
        map.lock().unwrap().insert("refresh_token".into(), "rt".into());
        let (base, seen) = runtime().block_on(pix_backend());
        runtime().block_on(core.api_set_base_url(base));

        // Without a Liquid wallet there is no address.
        let err = runtime()
            .block_on(core.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), None, None))
            .unwrap_err();
        assert!(err.message.contains("Erro ao gerar endereço"), "{}", err.message);
        let err = runtime().block_on(core.pix_create_deposit(1000, "nope".into(), None, None)).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::InvalidInput);

        runtime().block_on(core.liquid_connect(ABANDON.into())).unwrap();
        let dep = runtime()
            .block_on(core.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), Some("52998224725".into()), None))
            .unwrap();
        assert_eq!((dep.deposit_id.as_str(), dep.pix_key.as_str()), ("dep-1", "qr-copy"));
        assert_eq!(dep.status, DepositStatusDto::Pending);
        assert_eq!(runtime().block_on(core.pix_active_polls()), 1);

        let events = runtime().block_on(core.pix_poll_tick()).unwrap();
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].status, DepositStatusDto::DepixSent);
        assert_eq!(events[0].asset_amount, Some(970_000));
        assert_eq!(runtime().block_on(core.pix_active_polls()), 0);
        assert!(runtime().block_on(core.pix_poll_tick()).unwrap().is_empty());

        let stored = runtime().block_on(core.pix_get_deposit("dep-1".into())).unwrap().unwrap();
        assert_eq!((stored.status, stored.blockchain_txid.as_deref()), (DepositStatusDto::DepixSent, Some("tx9")));
        assert_eq!(runtime().block_on(core.pix_list_deposits(Some(10), None)).unwrap().len(), 1);

        let seen = seen.lock().unwrap().clone();
        assert_eq!(seen[0].0, "POST");
        assert_eq!(seen[0].2.as_deref(), Some(format!("Bearer {JWT_1}").as_str()));
        let body: serde_json::Value = serde_json::from_str(&seen[0].3).unwrap();
        assert!(body["address"].as_str().unwrap().starts_with("lq1"), "{body}");
        assert_eq!((body["tax_id"].as_str(), body["network"].as_str()), (Some("52998224725"), Some("liquid")));
        assert_eq!(seen[1].1, "/transactions/status?ids=dep-1");

        runtime().block_on(core.pix_clear_deposits()).unwrap();
        assert!(runtime().block_on(core.pix_list_deposits(None, None)).unwrap().is_empty());
    }

    #[test]
    fn backend_errors_use_the_dart_texts() {
        let core = open_core("pix-error");
        let map = with_memory_store(&core);
        map.lock().unwrap().insert("mnemonic_mainWallet".into(), ABANDON.into());
        map.lock().unwrap().insert("jwt".into(), JWT_1.into());
        map.lock().unwrap().insert("refresh_token".into(), "rt".into());
        let (base, _) = runtime().block_on(pix_backend());
        runtime().block_on(core.api_set_base_url(format!("{base}/missing")));
        let err = runtime()
            .block_on(core.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), None, Some("lq1qqaddr".into())))
            .unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::Network);
        assert_eq!(err.message, "Serviço não encontrado. Entre em contato com o suporte.");
    }

    #[test]
    fn favorite_payers_and_flags() {
        let core = open_core("pix-payers");
        let saved = runtime().block_on(core.favorite_payer_save(None, " Ana ".into(), "529.982.247-25".into())).unwrap();
        assert_eq!(saved, None);
        let dup = runtime().block_on(core.favorite_payer_save(None, "B".into(), "52998224725".into())).unwrap();
        assert_eq!(dup, Some(FavoritePayerSaveErrorDto::DuplicateCpf));
        let list = runtime().block_on(core.favorite_payers_list()).unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!((list[0].label.as_str(), list[0].masked_cpf.as_str()), ("Ana", "529.982.247-25"));
        let id = list[0].id.unwrap();
        assert!(runtime().block_on(core.favorite_payer_cpf_exists("529.982.247-25".into(), None)).unwrap());
        assert!(!runtime().block_on(core.favorite_payer_cpf_exists("52998224725".into(), Some(id))).unwrap());
        // Updating the same payer with its own CPF is allowed.
        assert_eq!(runtime().block_on(core.favorite_payer_save(Some(id), "Ana B".into(), "52998224725".into())).unwrap(), None);
        runtime().block_on(core.favorite_payer_delete(id)).unwrap();
        assert!(runtime().block_on(core.favorite_payers_list()).unwrap().is_empty());

        assert!(!runtime().block_on(core.pix_flag_is_set(PixFlagDto::TutorialShown)).unwrap());
        runtime().block_on(core.pix_flag_set(PixFlagDto::TutorialShown)).unwrap();
        assert!(runtime().block_on(core.pix_flag_is_set(PixFlagDto::TutorialShown)).unwrap());
        runtime().block_on(core.pix_flag_reset(PixFlagDto::TutorialShown)).unwrap();
        assert!(!runtime().block_on(core.pix_flag_is_set(PixFlagDto::TutorialShown)).unwrap());
    }

    #[test]
    fn pure_helpers() {
        assert_eq!(tax_id_validate("529.982.247-25".into()), None);
        assert_eq!(tax_id_validate("".into()), Some(CpfValidationErrorDto::Empty));
        assert_eq!(tax_id_validate("11111111111".into()), Some(CpfValidationErrorDto::Invalid));
        assert_eq!(tax_id_mask_input("52998224725999".into()), "52.998.224/7259-99");
        assert!(pix_looks_like_key("user@example.com".into()));
        let fee = pix_fee(50.0, false, Some(5.0));
        assert_eq!((fee.fee_amount, fee.discounted_amount, fee.active_tier), (2.0, 48.0, Some(0)));
        assert_eq!(fee.estimated_asset_units, Some(9.6));
        let v = pix_validate_amount(10.0, Some(DepositLimitsDto { absolute_min_limit: 20.0, allowed_spending: 100.0 }));
        assert_eq!((v.is_valid, v.error, v.limit_amount), (false, Some(DepositValidationErrorDto::BelowMinimum), Some(20.0)));
        assert!(pix_validate_amount(10.0, None).is_valid);
    }
}
