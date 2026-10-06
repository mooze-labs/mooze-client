//! PIX deposits, favorite payers and PIX flags.
//!
//! Deposits pay to the connected Liquid wallet. Backend calls use the
//! session of [`super::auth`]. The facade runs no timers here: a host or
//! the runtime calls `pix_poll_tick` every `rules::pix_poll_interval_ms`.

use std::sync::Arc;

use mooze_core::adapters::SessionTokens;
use mooze_core::domain::Asset;
use mooze_core::pix::client::create_deposit_error_message;
use mooze_core::pix::store::FavoritePayerSaveError;
use mooze_core::pix::tax_id;
use mooze_core::pix::{DepositStore, FavoritePayerStore, PixClient, PixFlagsStore, PixService};
use mooze_core::ports::Clock;

use mooze_core::pix::rules::DepositPoll;

use super::{auth, App, Inner, SerializedSession};
use crate::dto::*;
use crate::glue::LiquidPort;
use crate::{AppError, ErrorCode, Platform, Result};

type Pix<P> =
    PixService<<P as Platform>::Http, SessionTokens<SerializedSession<P>>, <P as Platform>::Kv, LiquidPort<P>>;

/// PIX service with the current session, base URL and Liquid wallet.
async fn pix_service<P: Platform>(inner: &Arc<Inner<P>>) -> Result<Pix<P>> {
    let auth = auth(inner).await?;
    let client = PixClient::new(inner.platform.http(), SessionTokens(auth.session.clone()), inner.api_base_url());
    Ok(PixService::new(client, DepositStore::new(inner.platform.kv()), LiquidPort::new(inner)))
}

impl<P: Platform> App<P> {
    /// Creates a PIX deposit (Dart `PixRepository.newDeposit`).
    ///
    /// Pays to `address`, or to a new address of the connected Liquid wallet
    /// when `None`. Stores the deposit and starts polling its status. A
    /// backend failure fails with the Portuguese text the Dart UI showed.
    pub async fn pix_create_deposit(
        &self,
        amount_in_cents: u64,
        asset_id: String,
        tax_id_number: Option<String>,
        address: Option<String>,
    ) -> Result<PixDepositDto> {
        let asset =
            Asset::from_id(&asset_id).ok_or_else(|| AppError::invalid_input(format!("unknown asset id {asset_id}")))?;
        let inner = &self.inner;
        let service = pix_service(inner).await?;
        let now = inner.platform.clock().now_ms();
        let created = match address {
            Some(a) => service.new_deposit_to_address(amount_in_cents, &a, asset, tax_id_number, now).await,
            None => service.new_deposit(amount_in_cents, asset, tax_id_number, now).await,
        };
        match created {
            Ok(outcome) => {
                inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()).polls.push(outcome.poll);
                Ok(outcome.deposit.into())
            }
            Err(e @ (mooze_core::Error::Network(_) | mooze_core::Error::Http { .. })) => {
                Err(AppError::new(ErrorCode::Network, create_deposit_error_message(&e)))
            }
            Err(e @ mooze_core::Error::Timeout(_)) => {
                Err(AppError::new(ErrorCode::Timeout, create_deposit_error_message(&e)))
            }
            Err(e) => Err(e.into()),
        }
    }

    /// Runs one poll tick for every deposit created in this session and
    /// returns the status changes. Expired and changed deposits stop polling.
    pub async fn pix_poll_tick(&self) -> Result<Vec<PixStatusEventDto>> {
        let inner = &self.inner;
        let (mut polls, generation) = self.pix_take_polls();
        if polls.is_empty() {
            return Ok(Vec::new());
        }
        let service = match pix_service(inner).await {
            Ok(s) => s,
            Err(e) => {
                // Keep the polls for the next tick.
                self.pix_restore_polls(polls, generation);
                return Err(e);
            }
        };
        let mut events = Vec::new();
        for poll in &mut polls {
            events.extend(service.poll_tick(poll, inner.platform.clock().now_ms()).await);
        }
        polls.retain(|p| !p.is_finished());
        self.pix_restore_polls(polls, generation);
        Ok(events.into_iter().map(Into::into).collect())
    }

    /// Takes every active poll with the current cancel generation.
    pub(crate) fn pix_take_polls(&self) -> (Vec<DepositPoll>, u64) {
        let mut state = self.inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner());
        (std::mem::take(&mut state.polls), state.generation)
    }

    /// Puts polls back unless `pix_cancel_polls` ran since they were taken.
    pub(crate) fn pix_restore_polls(&self, polls: Vec<DepositPoll>, generation: u64) {
        let mut state = self.inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner());
        if state.generation == generation {
            state.polls.extend(polls);
        }
    }

    /// Number of deposits still polled.
    pub async fn pix_active_polls(&self) -> Result<u32> {
        Ok(self.inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner()).polls.len() as u32)
    }

    /// Stops polling every deposit, including the ones a running tick holds.
    pub async fn pix_cancel_polls(&self) -> Result<()> {
        let mut state = self.inner.pix_polls.lock().unwrap_or_else(|e| e.into_inner());
        state.polls.clear();
        state.generation += 1;
        Ok(())
    }

    /// Reads one stored deposit.
    pub async fn pix_get_deposit(&self, deposit_id: String) -> Result<Option<PixDepositDto>> {
        let rec = DepositStore::new(self.inner.platform.kv()).get_deposit(&deposit_id).await?;
        Ok(rec.map(|r| r.to_deposit().into()))
    }

    /// Stored deposits, newest first. `offset` applies only with a `limit`.
    pub async fn pix_list_deposits(&self, limit: Option<u32>, offset: Option<u32>) -> Result<Vec<PixDepositDto>> {
        let recs = DepositStore::new(self.inner.platform.kv())
            .get_deposits(limit.map(|l| l as usize), offset.map(|o| o as usize))
            .await?;
        Ok(recs.iter().map(|r| r.to_deposit().into()).collect())
    }

    /// Refreshes deposits from the backend and returns the stored ones with
    /// these ids (Dart `updateDepositDetails`).
    pub async fn pix_update_deposit_details(&self, deposit_ids: Vec<String>) -> Result<Vec<PixDepositDto>> {
        let list = pix_service(&self.inner).await?.update_deposit_details(&deposit_ids).await?;
        Ok(list.into_iter().map(Into::into).collect())
    }

    /// History page: stored deposits, with a backend refresh of the
    /// non-terminal ones. A failed refresh returns the local data.
    pub async fn pix_history(&self, limit: Option<u32>, offset: Option<u32>) -> Result<Vec<PixDepositDto>> {
        let (limit, offset) = (limit.map(|l| l as usize), offset.map(|o| o as usize));
        let list = match pix_service(&self.inner).await {
            Ok(service) => service.get_pix_history(limit, offset).await?,
            // Without a session, show what is stored.
            Err(_) => DepositStore::new(self.inner.platform.kv())
                .get_deposits(limit, offset)
                .await?
                .iter()
                .map(|r| r.to_deposit())
                .collect(),
        };
        Ok(list.into_iter().map(Into::into).collect())
    }

    /// Deletes every stored deposit and stops polling (wallet delete or import).
    pub async fn pix_clear_deposits(&self) -> Result<()> {
        self.pix_cancel_polls().await?;
        Ok(DepositStore::new(self.inner.platform.kv()).clear_all_deposits().await?)
    }

    // ───────────────────────────── favorite payers

    /// Every favorite payer, newest first.
    pub async fn favorite_payers_list(&self) -> Result<Vec<FavoritePayerDto>> {
        let list = FavoritePayerStore::new(self.inner.platform.kv()).get_all().await?;
        Ok(list.into_iter().map(Into::into).collect())
    }

    /// Inserts (`id` null) or updates a payer: strips the CPF mask, trims the
    /// label, refuses a CPF that another payer has. Returns the refusal
    /// reason, or `None` when saved.
    pub async fn favorite_payer_save(
        &self,
        id: Option<u64>,
        label: String,
        cpf: String,
    ) -> Result<Option<FavoritePayerSaveErrorDto>> {
        let refused = FavoritePayerStore::new(self.inner.platform.kv())
            .save_checked(id, &label, &cpf, self.inner.platform.clock().now_ms())
            .await?;
        Ok(refused.map(|FavoritePayerSaveError::DuplicateCpf| FavoritePayerSaveErrorDto::DuplicateCpf))
    }

    /// Deletes one payer.
    pub async fn favorite_payer_delete(&self, id: u64) -> Result<()> {
        Ok(FavoritePayerStore::new(self.inner.platform.kv()).delete(id).await?)
    }

    /// True if a payer other than `excluding_id` has `cpf` (digits, or masked).
    pub async fn favorite_payer_cpf_exists(&self, cpf: String, excluding_id: Option<u64>) -> Result<bool> {
        Ok(FavoritePayerStore::new(self.inner.platform.kv()).cpf_exists(&tax_id::strip(&cpf), excluding_id).await?)
    }

    /// Deletes every payer (wallet delete or import).
    pub async fn favorite_payers_clear(&self) -> Result<()> {
        Ok(FavoritePayerStore::new(self.inner.platform.kv()).clear_all().await?)
    }

    // ───────────────────────────── flags

    /// True if `flag` is set.
    pub async fn pix_flag_is_set(&self, flag: PixFlagDto) -> Result<bool> {
        Ok(PixFlagsStore::new(self.inner.platform.kv()).is_set(flag.into()).await?)
    }

    /// Sets `flag`.
    pub async fn pix_flag_set(&self, flag: PixFlagDto) -> Result<()> {
        Ok(PixFlagsStore::new(self.inner.platform.kv()).set(flag.into()).await?)
    }

    /// Clears `flag`.
    pub async fn pix_flag_reset(&self, flag: PixFlagDto) -> Result<()> {
        Ok(PixFlagsStore::new(self.inner.platform.kv()).reset(flag.into()).await?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{open_test_app, ABANDON, JWT_1};
    use crate::ErrorCode;
    use mooze_core::domain::DEPIX_ASSET_ID;
    use mooze_core::ports::HttpMethod;
    use mooze_core::testing::block_on;
    use serde_json::json;

    fn ready_session(plat: &crate::testing::TestPlatform) {
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        plat.secure_insert("jwt", JWT_1);
        plat.secure_insert("refresh_token", "rt");
    }

    #[test]
    fn deposit_create_poll_and_read_back() {
        let (app, plat) = open_test_app();
        ready_session(&plat);
        let base = mooze_core::api::DEFAULT_BASE_URL;
        // Same answers as the bridge mock backend in api/pix.rs `pix_backend`.
        plat.http.on_json(
            HttpMethod::Post,
            &format!("{base}/v2/transactions"),
            200,
            json!({"data": {"transaction_id": "dep-1", "qr_copy_paste": "qr-copy", "qr_image_url": "https://img"}}),
        );
        plat.http.on_json(
            HttpMethod::Get,
            &format!("{base}/transactions/status?ids=dep-1"),
            200,
            json!({"data": [{"id": "dep-1", "status": "depix_sent", "amount_in_cents": 1000,
                             "blockchain_txid": "tx9", "asset_amount": 970000}]}),
        );

        // Without a Liquid wallet there is no address.
        let err = block_on(app.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), None, None)).unwrap_err();
        assert!(err.message.contains("Erro ao gerar endereço"), "{}", err.message);
        let err = block_on(app.pix_create_deposit(1000, "nope".into(), None, None)).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidInput);

        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let dep =
            block_on(app.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), Some("52998224725".into()), None)).unwrap();
        assert_eq!((dep.deposit_id.as_str(), dep.pix_key.as_str()), ("dep-1", "qr-copy"));
        assert_eq!(dep.status, DepositStatusDto::Pending);
        assert_eq!(block_on(app.pix_active_polls()).unwrap(), 1);

        let events = block_on(app.pix_poll_tick()).unwrap();
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].status, DepositStatusDto::DepixSent);
        assert_eq!(events[0].asset_amount, Some(970_000));
        assert_eq!(block_on(app.pix_active_polls()).unwrap(), 0);
        assert!(block_on(app.pix_poll_tick()).unwrap().is_empty());

        let stored = block_on(app.pix_get_deposit("dep-1".into())).unwrap().unwrap();
        assert_eq!((stored.status, stored.blockchain_txid.as_deref()), (DepositStatusDto::DepixSent, Some("tx9")));
        assert_eq!(block_on(app.pix_list_deposits(Some(10), None)).unwrap().len(), 1);

        let reqs = plat.http.requests();
        assert_eq!(reqs[0].method, HttpMethod::Post);
        assert_eq!(reqs[0].headers.get("Authorization").map(String::as_str), Some(format!("Bearer {JWT_1}").as_str()));
        let body: serde_json::Value = serde_json::from_slice(reqs[0].body.as_deref().unwrap()).unwrap();
        assert!(body["address"].as_str().unwrap().starts_with("lq1"), "{body}");
        assert_eq!((body["tax_id"].as_str(), body["network"].as_str()), (Some("52998224725"), Some("liquid")));
        assert!(reqs[1].url.ends_with("/transactions/status?ids=dep-1"));

        block_on(app.pix_clear_deposits()).unwrap();
        assert!(block_on(app.pix_list_deposits(None, None)).unwrap().is_empty());
    }

    #[test]
    fn cancel_during_an_in_flight_tick_wins() {
        let (app, plat) = open_test_app();
        ready_session(&plat);
        let base = mooze_core::api::DEFAULT_BASE_URL;
        plat.http.on_json(
            HttpMethod::Post,
            &format!("{base}/v2/transactions"),
            200,
            json!({"data": {"transaction_id": "dep-2", "qr_copy_paste": "qr", "qr_image_url": "https://img"}}),
        );
        block_on(app.pix_create_deposit(1000, DEPIX_ASSET_ID.into(), None, Some("lq1test".into()))).unwrap();
        // A tick takes the polls, then the user cancels before the tick puts them back.
        let (polls, generation) = app.pix_take_polls();
        assert_eq!(polls.len(), 1);
        block_on(app.pix_cancel_polls()).unwrap();
        app.pix_restore_polls(polls, generation);
        assert_eq!(block_on(app.pix_active_polls()).unwrap(), 0, "the cancel must not be undone");
    }

    #[test]
    fn favorite_payers_and_flags() {
        let (app, _plat) = open_test_app();
        let refused = block_on(app.favorite_payer_save(None, "Ana".into(), "529.982.247-25".into())).unwrap();
        assert!(refused.is_none());
        let dup = block_on(app.favorite_payer_save(None, "Bia".into(), "52998224725".into())).unwrap();
        assert_eq!(dup, Some(FavoritePayerSaveErrorDto::DuplicateCpf));
        assert_eq!(block_on(app.favorite_payers_list()).unwrap().len(), 1);
        assert!(block_on(app.favorite_payer_cpf_exists("52998224725".into(), None)).unwrap());
        assert!(!block_on(app.pix_flag_is_set(PixFlagDto::TutorialShown)).unwrap());
        block_on(app.pix_flag_set(PixFlagDto::TutorialShown)).unwrap();
        assert!(block_on(app.pix_flag_is_set(PixFlagDto::TutorialShown)).unwrap());
    }
}
