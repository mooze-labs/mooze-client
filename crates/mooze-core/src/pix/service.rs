//! PIX deposit orchestration.
//!
//! Each method returns the events it produced. The platform schedules poll ticks.

use std::future::Future;

use crate::domain::{Asset, ChainId};
use crate::ports::{HttpClient, KvStore, MaybeSend, MaybeSync};
use crate::{Error, Result};

use super::client::{PixClient, TokenProvider};
use super::entities::{DepositStatus, NewDepositRequest, PixDeposit, PixStatusEvent};
use super::rules::{deposits_to_refresh, DepositPoll, PollStep, PollTick};
use super::store::DepositStore;

/// Network the app sends for PIX deposits.
pub const PIX_DEPOSIT_NETWORK: &str = "liquid";

/// Supplies a fresh Liquid receive address. Integration wires it to the
/// Liquid wallet.
pub trait AddressProvider: MaybeSend + MaybeSync {
    /// Returns a new Liquid address. An empty string counts as a failure.
    fn liquid_receive_address(&self) -> impl Future<Output = Result<String>> + MaybeSend;
}

/// Result of [`PixService::new_deposit`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NewDepositOutcome {
    /// The created deposit.
    pub deposit: PixDeposit,
    /// `pending` event for listeners.
    pub event: PixStatusEvent,
    /// Poll state. Call [`PixService::poll_tick`] every poll interval.
    pub poll: DepositPoll,
}

/// PIX deposit service.
#[derive(Debug, Clone)]
pub struct PixService<H: HttpClient, T: TokenProvider, K: KvStore, A: AddressProvider> {
    client: PixClient<H, T>,
    deposits: DepositStore<K>,
    addresses: A,
}

impl<H: HttpClient, T: TokenProvider, K: KvStore, A: AddressProvider> PixService<H, T, K, A> {
    /// Builds the service.
    pub fn new(client: PixClient<H, T>, deposits: DepositStore<K>, addresses: A) -> Self {
        Self { client, deposits, addresses }
    }

    /// The deposit store.
    pub fn store(&self) -> &DepositStore<K> {
        &self.deposits
    }

    /// The backend client.
    pub fn client(&self) -> &PixClient<H, T> {
        &self.client
    }

    /// Creates a deposit: new address, backend request, local record.
    ///
    /// Use `client::create_deposit_error_message` to show a backend error.
    pub async fn new_deposit(
        &self,
        amount_in_cents: u64,
        asset: Asset,
        tax_id_number: Option<String>,
        now_ms: u64,
    ) -> Result<NewDepositOutcome> {
        let address = self
            .addresses
            .liquid_receive_address()
            .await
            .map_err(|e| Error::service(ChainId::Liquid, format!("Erro ao gerar endereço: {e}")))?;
        if address.is_empty() {
            return Err(Error::service(ChainId::Liquid, "Erro ao gerar endereço: empty address"));
        }
        self.new_deposit_to_address(amount_in_cents, &address, asset, tax_id_number, now_ms).await
    }

    /// Creates a deposit paying to `address`.
    pub async fn new_deposit_to_address(
        &self,
        amount_in_cents: u64,
        address: &str,
        asset: Asset,
        tax_id_number: Option<String>,
        now_ms: u64,
    ) -> Result<NewDepositOutcome> {
        let req = NewDepositRequest {
            address: address.to_owned(),
            amount_in_cents,
            asset: asset.id().to_owned(),
            network: PIX_DEPOSIT_NETWORK.to_owned(),
            tax_id_number,
        };
        let resp = self.client.create_deposit(&req).await?;
        self.deposits
            .add_new_deposit(&resp.deposit_id, &resp.qr_copy_paste, asset.id(), amount_in_cents, now_ms)
            .await?;
        Ok(NewDepositOutcome {
            event: PixStatusEvent::new(resp.deposit_id.clone(), DepositStatus::Pending),
            poll: DepositPoll::new(resp.deposit_id.clone(), now_ms),
            deposit: PixDeposit {
                deposit_id: resp.deposit_id,
                pix_key: resp.qr_copy_paste,
                asset,
                amount_in_cents,
                network: PIX_DEPOSIT_NETWORK.to_owned(),
                status: DepositStatus::Pending,
                created_at_ms: now_ms,
                blockchain_txid: None,
                asset_amount: None,
            },
        })
    }

    /// Runs one poll tick and returns the events to emit (zero or one).
    ///
    /// Fetch errors keep polling.
    // NOTE: the result of the local status update is ignored by design.
    pub async fn poll_tick(&self, poll: &mut DepositPoll, now_ms: u64) -> Vec<PixStatusEvent> {
        let event = match poll.tick(now_ms) {
            PollTick::Done => return Vec::new(),
            PollTick::Expired(e) => e,
            PollTick::Fetch => {
                let ids = [poll.deposit_id.clone()];
                let fetched = self.client.get_deposits_status(&ids).await.ok();
                match poll.on_fetch(fetched.as_deref()) {
                    PollStep::Changed(e) => e,
                    PollStep::Continue | PollStep::Stop => return Vec::new(),
                }
            }
        };
        let _ = self.apply_status_event(&event).await;
        vec![event]
    }

    /// Persists a status event.
    pub async fn apply_status_event(&self, event: &PixStatusEvent) -> Result<()> {
        self.deposits
            .update_deposit(&event.deposit_id, event.status.as_api_str(), event.asset_amount, event.blockchain_txid.as_deref())
            .await
    }

    /// Reads one deposit.
    pub async fn get_deposit(&self, deposit_id: &str) -> Result<Option<PixDeposit>> {
        Ok(self.deposits.get_deposit(deposit_id).await?.map(|r| r.to_deposit()))
    }

    /// Reads one deposit or fails with "Depósito não encontrado".
    pub async fn require_deposit(&self, deposit_id: &str) -> Result<PixDeposit> {
        self.get_deposit(deposit_id).await?.ok_or_else(|| Error::invalid("Depósito não encontrado"))
    }

    /// Lists deposits, newest first.
    pub async fn get_deposits(&self, limit: Option<usize>, offset: Option<usize>) -> Result<Vec<PixDeposit>> {
        Ok(self.deposits.get_deposits(limit, offset).await?.iter().map(|r| r.to_deposit()).collect())
    }

    /// Refreshes deposits from the backend and returns the stored ones with these ids.
    ///
    // NOTE: this stores the raw API status and writes asset amount 0
    // when the API sends none (unlike the polling path, which keeps it).
    pub async fn update_deposit_details(&self, ids: &[String]) -> Result<Vec<PixDeposit>> {
        let details = self.client.get_deposits_status(ids).await?;
        for d in &details {
            self.deposits
                .update_deposit(&d.id, &d.status, Some(d.asset_amount.unwrap_or(0)), d.blockchain_txid.as_deref())
                .await?;
        }
        Ok(self.get_deposits(None, None).await?.into_iter().filter(|d| ids.contains(&d.deposit_id)).collect())
    }

    /// History page with a backend refresh of non-terminal deposits.
    ///
    /// A refresh failure returns the first local read.
    pub async fn get_pix_history(&self, limit: Option<usize>, offset: Option<usize>) -> Result<Vec<PixDeposit>> {
        let deposits = self.get_deposits(limit, offset).await?;
        let pending = deposits_to_refresh(&deposits);
        if pending.is_empty() {
            return Ok(deposits);
        }
        match self.update_deposit_details(&pending).await {
            Ok(_) => match self.get_deposits(limit, offset).await {
                Ok(fresh) => Ok(fresh),
                Err(_) => Ok(deposits),
            },
            Err(_) => Ok(deposits),
        }
    }

    /// Deletes every local deposit (wallet delete or import).
    pub async fn clear_all_deposits(&self) -> Result<()> {
        self.deposits.clear_all_deposits().await
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::pix::client::tests::StaticToken;
    use crate::ports::HttpMethod;
    use crate::testing::{block_on, MemoryKv, MockHttp};
    use serde_json::json;
    use std::future::ready;

    struct FixedAddress(&'static str);

    impl AddressProvider for FixedAddress {
        fn liquid_receive_address(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            ready(Ok(self.0.to_owned()))
        }
    }

    type Svc = PixService<MockHttp, StaticToken, MemoryKv, FixedAddress>;

    fn svc(http: &MockHttp, addr: &'static str) -> Svc {
        PixService::new(
            PixClient::new(http.clone(), StaticToken("jwt"), "https://test"),
            DepositStore::new(MemoryKv::new()),
            FixedAddress(addr),
        )
    }

    fn mock_create(http: &MockHttp) {
        http.on_json(
            HttpMethod::Post,
            "https://test/v2/transactions",
            200,
            json!({"data": {"transaction_id": "dep-1", "qr_copy_paste": "qr-copy", "qr_image_url": "https://img"}}),
        );
    }

    fn assert_send<T: Send>(_: &T) {}

    #[test]
    fn futures_are_send() {
        let http = MockHttp::new();
        let s = svc(&http, "lq1");
        let mut p = DepositPoll::new("x", 0);
        assert_send(&s.new_deposit(1, Asset::Depix, None, 0));
        assert_send(&s.poll_tick(&mut p, 0));
        assert_send(&s.get_pix_history(None, None));
    }

    #[test]
    fn new_deposit_stores_and_emits_pending() {
        let http = MockHttp::new();
        mock_create(&http);
        let s = svc(&http, "lq1qqaddr");
        let out = block_on(s.new_deposit(1000, Asset::Depix, Some("52998224725".into()), 5_000)).unwrap();
        assert_eq!(out.deposit.pix_key, "qr-copy");
        assert_eq!(out.event, PixStatusEvent::new("dep-1", DepositStatus::Pending));
        assert_eq!(out.poll.first_tick_at_ms(), 35_000);
        let stored = block_on(s.get_deposit("dep-1")).unwrap().unwrap();
        assert_eq!(stored, out.deposit);
        let body: serde_json::Value = serde_json::from_slice(http.last_request().unwrap().body.as_ref().unwrap()).unwrap();
        assert_eq!(body["address"], "lq1qqaddr");
        assert_eq!(body["network"], "liquid");
    }

    #[test]
    fn empty_address_fails() {
        let http = MockHttp::new();
        let err = block_on(svc(&http, "").new_deposit(1000, Asset::Depix, None, 0)).unwrap_err();
        assert!(err.to_string().contains("empty address"));
        assert!(http.requests().is_empty());
    }

    #[test]
    fn poll_updates_store() {
        let http = MockHttp::new();
        mock_create(&http);
        let s = svc(&http, "lq1");
        let mut out = block_on(s.new_deposit(1000, Asset::Depix, None, 0)).unwrap();

        // Fetch error: keep polling.
        assert!(block_on(s.poll_tick(&mut out.poll, 30_000)).is_empty());
        assert!(!out.poll.is_finished());

        http.on_json(
            HttpMethod::Get,
            "https://test/transactions/status?ids=dep-1",
            200,
            json!({"data": [{"id": "dep-1", "status": "depix_sent", "amount_in_cents": 1000,
                              "blockchain_txid": "tx9", "asset_amount": 970000}]}),
        );
        let events = block_on(s.poll_tick(&mut out.poll, 60_000));
        assert_eq!(events[0].status, DepositStatus::DepixSent);
        let d = block_on(s.require_deposit("dep-1")).unwrap();
        assert_eq!((d.status, d.asset_amount, d.blockchain_txid.as_deref()), (DepositStatus::DepixSent, Some(970_000), Some("tx9")));
        assert!(block_on(s.poll_tick(&mut out.poll, 90_000)).is_empty());
    }

    #[test]
    fn poll_expires() {
        let http = MockHttp::new();
        mock_create(&http);
        let s = svc(&http, "lq1");
        let mut out = block_on(s.new_deposit(1000, Asset::Depix, None, 0)).unwrap();
        let events = block_on(s.poll_tick(&mut out.poll, 21 * 60_000 + 1));
        assert_eq!(events, vec![PixStatusEvent::new("dep-1", DepositStatus::Expired)]);
        assert_eq!(block_on(s.require_deposit("dep-1")).unwrap().status, DepositStatus::Expired);
        assert!(block_on(s.require_deposit("nope")).is_err());
    }

    #[test]
    fn history_refreshes_and_falls_back() {
        let http = MockHttp::new();
        let s = svc(&http, "lq1");
        block_on(async {
            s.store().add_new_deposit("a", "qa", crate::domain::DEPIX_ASSET_ID, 100, 10).await.unwrap();
            s.store().add_new_deposit("b", "qb", crate::domain::DEPIX_ASSET_ID, 200, 20).await.unwrap();
            s.store().update_deposit_status("a", "expired").await.unwrap();

            // Backend down: local data comes back unchanged.
            let h = s.get_pix_history(Some(50), Some(0)).await.unwrap();
            assert_eq!(h.len(), 2);
            assert_eq!(h[0].status, DepositStatus::Pending);

            http.on_json(
                HttpMethod::Get,
                "https://test/transactions/status?ids=b",
                200,
                json!({"data": [{"id": "b", "status": "finished", "amount_in_cents": 200}]}),
            );
            let h = s.get_pix_history(Some(50), Some(0)).await.unwrap();
            assert_eq!(h[0].status, DepositStatus::Finished);
            assert_eq!(h[0].asset_amount, Some(0));
            assert_eq!(h[1].status, DepositStatus::Expired);

            s.clear_all_deposits().await.unwrap();
            assert!(s.get_deposits(None, None).await.unwrap().is_empty());
        });
    }
}
