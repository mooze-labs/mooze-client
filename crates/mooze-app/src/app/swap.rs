//! SideSwap asset swaps and Bitcoin <-> Liquid pegs.
//!
//! One WebSocket serves swaps and pegs. Server pushes reach the hosts as
//! `AppEvent::SideSwap` while the driver runs (`sideswap_start_events`).
//! Peg status is polled: call `peg_refresh_due` at `next_wakeup_ms`, or
//! let the runtime do it.

use std::sync::Arc;

use mooze_core::peg::{KvPegStore, PegError, PegOrchestrator, PegRepository};
use mooze_core::ports::Clock;
use mooze_core::sideswap::protocol::SIDESWAP_API_URL;
use mooze_core::sideswap::swap::StartQuoteOutcome;
use mooze_core::sideswap::{SideSwapClient, SwapService};

use super::{App, Inner};
use crate::dto::*;
use crate::events::AppEvent;
use crate::glue::{Emit, LiquidPort, Swap, WalletPegPort};
use crate::{AppError, ErrorCode, Platform, Result};

fn not_connected() -> AppError {
    AppError::invalid_state("sideswap not connected; call sideswap_connect first")
}

fn session<P: Platform>(guard: &mut Option<Swap<P>>) -> Result<&mut Swap<P>> {
    guard.as_mut().ok_or_else(not_connected)
}

fn peg_store<P: Platform>(inner: &Inner<P>, wallet_id: &str) -> KvPegStore<P::Kv, P::Clock> {
    KvPegStore::new(inner.platform.kv(), inner.platform.clock(), wallet_id)
}

/// Peg failure as a facade error. The message is the Portuguese UI text.
fn peg_app_error(e: PegError) -> AppError {
    let code = match &e {
        PegError::BelowMinimum { .. } | PegError::InsufficientFunds(_) => ErrorCode::InvalidInput,
        PegError::TransportFailure(_) => ErrorCode::Network,
        PegError::UnknownOutcome { .. } => ErrorCode::Timeout,
        PegError::WalletBusy(_) => ErrorCode::InvalidState,
        PegError::ProviderRejected(_) | PegError::OrderNotFound(_) | PegError::WalletFailure(_) => {
            ErrorCode::Service
        }
    };
    AppError::new(code, e.message())
}

impl<P: Platform> App<P> {
    /// Opens the SideSwap connection and logs in. `url` `None` uses the
    /// default endpoint. No-op when connected.
    pub async fn sideswap_connect(&self, api_key: String, url: Option<String>) -> Result<()> {
        let inner = &self.inner;
        let mut guard = inner.sideswap.lock().await;
        if let Some(swap) = guard.as_mut() {
            return Ok(swap.client_mut().connect().await?);
        }
        let client = SideSwapClient::new(inner.platform.ws(), api_key)
            .with_url(url.unwrap_or_else(|| SIDESWAP_API_URL.to_owned()))
            .with_clock(Arc::new(inner.platform.clock()));
        let mut swap = SwapService::new(client, LiquidPort::new(inner));
        swap.client_mut().connect().await?;
        *guard = Some(swap);
        Ok(())
    }

    /// Closes the connection and stops the event driver. Idempotent.
    pub async fn sideswap_disconnect(&self) -> Result<()> {
        let state = &self.inner.sideswap;
        state.stop_driver();
        if let Some(mut swap) = state.lock().await.take() {
            swap.stop_quote().await;
            swap.client_mut().dispose().await;
        }
        Ok(())
    }

    /// True while the socket is open.
    pub async fn sideswap_is_connected(&self) -> Result<bool> {
        Ok(self
            .inner
            .sideswap
            .lock()
            .await
            .as_mut()
            .is_some_and(|s| s.client_mut().is_connected()))
    }

    /// Starts the event driver: server pushes become `AppEvent::SideSwap`
    /// items for every subscriber. Replaces a running driver, which ends
    /// with a `closed` item. The driver stops when no subscriber is left.
    pub async fn sideswap_start_events(&self) -> Result<()> {
        let inner = &self.inner;
        let weak = Arc::downgrade(inner);
        let emit: Emit = Arc::new(move |event: SideSwapEventDto| {
            weak.upgrade()
                .is_some_and(|inner| inner.subscribers.emit(AppEvent::SideSwap(event)) > 0)
        });
        let clock: Arc<dyn mooze_core::ports::Clock> = Arc::new(inner.platform.clock());
        inner.sideswap.start_driver(
            inner.platform.spawner().as_ref(),
            inner.platform.timer(),
            clock,
            emit,
        );
        Ok(())
    }

    /// Stops the event driver. The stream ends with a `closed` item.
    pub async fn sideswap_stop_events(&self) -> Result<()> {
        self.inner.sideswap.stop_driver();
        Ok(())
    }

    /// True while the event driver runs.
    pub async fn sideswap_events_running(&self) -> Result<bool> {
        Ok(self.inner.sideswap.driver_running())
    }

    /// SideSwap markets.
    pub async fn sideswap_markets(&self) -> Result<Vec<SideswapMarketDto>> {
        let list = session(&mut *self.inner.sideswap.lock().await)?
            .get_markets()
            .await?;
        Ok(list.iter().map(Into::into).collect())
    }

    /// SideSwap assets.
    pub async fn sideswap_assets(&self) -> Result<Vec<SideswapAssetDto>> {
        let list = session(&mut *self.inner.sideswap.lock().await)?
            .get_assets()
            .await?;
        Ok(list.iter().map(Into::into).collect())
    }

    /// Starts a quote subscription for `amount` of `send_asset_id`. Stops
    /// the previous one. Funds it with the Liquid wallet UTXOs. Quotes
    /// arrive as `AppEvent::SideSwap`.
    pub async fn sideswap_start_quote(
        &self,
        send_asset_id: String,
        receive_asset_id: String,
        amount: u64,
    ) -> Result<StartQuoteDto> {
        let now = self.inner.platform.clock().now_ms();
        let mut guard = self.inner.sideswap.lock().await;
        let outcome = session(&mut guard)?
            .start_quote(&send_asset_id, &receive_asset_id, amount, now)
            .await?;
        Ok(match outcome {
            StartQuoteOutcome::Started(intent) => StartQuoteDto {
                started: true,
                quote_sub_id: intent.quote_sub_id,
                base_asset_id: Some(intent.params.base_asset),
                quote_asset_id: Some(intent.params.quote_asset),
            },
            StartQuoteOutcome::AlreadyInProgress => StartQuoteDto {
                started: false,
                quote_sub_id: None,
                base_asset_id: None,
                quote_asset_id: None,
            },
        })
    }

    /// Stops the quote subscription. Best-effort.
    pub async fn sideswap_stop_quote(&self) -> Result<()> {
        if let Some(swap) = self.inner.sideswap.lock().await.as_mut() {
            swap.stop_quote().await;
        }
        Ok(())
    }

    /// Accepts a quote: stops quotes, fetches the PSET, signs it with the
    /// Liquid wallet and the stored mnemonic, submits it. Returns the txid.
    pub async fn sideswap_execute_swap(&self, quote_id: u64) -> Result<String> {
        Ok(session(&mut *self.inner.sideswap.lock().await)?
            .execute_swap(quote_id)
            .await?)
    }

    // ───────────────────────────── pegs

    /// Peg minimums and fees from `server_status`.
    pub async fn peg_limits(&self) -> Result<PegServerLimitsDto> {
        let mut guard = self.inner.sideswap.lock().await;
        let r = session(&mut guard)?.client_mut().get_limits().await;
        r.map(Into::into).map_err(peg_app_error)
    }

    /// Prices a peg without creating an order.
    pub async fn peg_quote(
        &self,
        direction: PegDirectionDto,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
    ) -> Result<PegQuoteDto> {
        let inner = &self.inner;
        let store = peg_store(inner, "");
        let mut guard = inner.sideswap.lock().await;
        let client = session(&mut guard)?.client_mut();
        let mut orchestrator = PegOrchestrator::new(client, WalletPegPort::new(inner), store);
        let r = orchestrator
            .quote(direction.into(), amount_sat, fee_rate_sat_per_vbyte, drain)
            .await;
        r.map(Into::into).map_err(peg_app_error)
    }

    /// Creates a peg order, stores it under `wallet_id`, funds it from the
    /// wallet and starts tracking it. `external_payout_address` is allowed
    /// only for peg-outs; `None` pays to the own wallet.
    pub async fn peg_execute(
        &self,
        wallet_id: String,
        direction: PegDirectionDto,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
        external_payout_address: Option<String>,
    ) -> Result<PegExecutionDto> {
        let inner = &self.inner;
        let store = peg_store(inner, &wallet_id);
        let mut guard = inner.sideswap.lock().await;
        let client = session(&mut guard)?.client_mut();
        let mut orchestrator = PegOrchestrator::new(client, WalletPegPort::new(inner), store);
        let executed = orchestrator
            .execute(
                direction.into(),
                amount_sat,
                fee_rate_sat_per_vbyte,
                drain,
                external_payout_address.as_deref(),
            )
            .await;
        if let Ok(ex) = &executed {
            let store = peg_store(inner, &wallet_id);
            if let Ok(Some(rec)) = store.get(&ex.order.order_id).await {
                inner
                    .sideswap
                    .pegs
                    .lock()
                    .await
                    .track(rec.to_tracked(), inner.platform.clock().now_ms());
            }
        }
        let ex = executed.map_err(peg_app_error)?;
        Ok(PegExecutionDto {
            order: (&ex.order).into(),
            funding_tx_id: ex.funding_tx_id,
        })
    }

    /// One-shot status of an order.
    pub async fn peg_status(
        &self,
        direction: PegDirectionDto,
        order_id: String,
    ) -> Result<PegProgressDto> {
        let mut guard = self.inner.sideswap.lock().await;
        let r = session(&mut guard)?
            .client_mut()
            .get_status(direction.into(), &order_id)
            .await;
        r.map(|p| (&p).into()).map_err(peg_app_error)
    }

    /// Stored pegs of `wallet_id`, oldest first. Needs no connection.
    pub async fn peg_list(&self, wallet_id: String) -> Result<Vec<PegRecordDto>> {
        let list = peg_store(&self.inner, &wallet_id).list().await?;
        Ok(list.iter().map(Into::into).collect())
    }

    /// Resumes tracking of the pending pegs stored under `wallet_id`.
    /// Idempotent. Returns every tracked peg.
    pub async fn peg_restore(&self, wallet_id: String) -> Result<Vec<TrackedPegDto>> {
        let store = peg_store(&self.inner, &wallet_id);
        let mut tracker = self.inner.sideswap.pegs.lock().await;
        tracker
            .restore_from(&store, self.inner.platform.clock().now_ms())
            .await?;
        Ok(tracker.current().iter().map(TrackedPegDto::from).collect())
    }

    /// Every tracked peg.
    pub async fn peg_tracked(&self) -> Result<Vec<TrackedPegDto>> {
        Ok(self
            .inner
            .sideswap
            .pegs
            .lock()
            .await
            .current()
            .iter()
            .map(Into::into)
            .collect())
    }

    /// Stops tracking `order_id`. Storage is unchanged.
    pub async fn peg_untrack(&self, order_id: String) -> Result<()> {
        self.inner.sideswap.pegs.lock().await.untrack(&order_id);
        Ok(())
    }

    /// Polls every tracked peg whose time has come, persists terminal ones
    /// under `wallet_id`, and returns the new state. Transport errors only
    /// reschedule.
    pub async fn peg_refresh_due(&self, wallet_id: String) -> Result<PegRefreshDto> {
        let inner = &self.inner;
        let store = peg_store(inner, &wallet_id);
        let mut guard = inner.sideswap.lock().await;
        let swap = session(&mut guard)?;
        let mut tracker = inner.sideswap.pegs.lock().await;
        let mut changed = Vec::new();
        let mut finished = Vec::new();
        for order_id in tracker.due(inner.platform.clock().now_ms()) {
            let update = tracker
                .refresh(
                    swap.client_mut(),
                    &store,
                    &order_id,
                    inner.platform.clock().now_ms(),
                )
                .await;
            if update.changed {
                changed.push(order_id);
            }
            if let Some(t) = &update.terminal {
                finished.push(TrackedPegDto::from(t));
            }
        }
        Ok(PegRefreshDto {
            pegs: tracker.current().iter().map(Into::into).collect(),
            changed,
            finished,
            next_wakeup_ms: tracker.next_wakeup_ms(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::events::{AppEvent, EventSink};
    use crate::testing::{test_config, TestPlatform, ABANDON};
    use mooze_core::testing::{block_on, MockWs, TestExecutor};
    use serde_json::{json, Value};
    use std::sync::{Arc, Mutex};

    /// Replies of the mock SideSwap server. Same answers as the bridge
    /// `api/swap.rs` test module: login_client, server_status plus one
    /// PegInWalletBalance push.
    fn replies(frame: &str) -> Vec<String> {
        let v: Value = serde_json::from_str(frame).unwrap();
        let id = v["id"].clone();
        let method = v["method"].as_str().unwrap_or_default().to_owned();
        let reply = |r: Value| json!({"id": id, "method": method, "result": r}).to_string();
        match method.as_str() {
            "login_client" => vec![reply(json!({}))],
            "server_status" => vec![
                reply(json!({"elements_fee_rate": 0.1, "min_peg_in_amount": 10000, "min_peg_out_amount": 25000,
                    "server_fee_percent_peg_in": 0.1, "server_fee_percent_peg_out": 0.1})),
                json!({"method": "subscribed_value", "params": {"value": {"PegInWalletBalance": {"available": 777}}}})
                    .to_string(),
            ],
            _ => vec![reply(json!({}))],
        }
    }

    struct Collect(Arc<Mutex<Vec<AppEvent>>>);
    impl EventSink for Collect {
        fn send(&self, e: AppEvent) -> bool {
            self.0.lock().unwrap().push(e);
            true
        }
    }

    fn sideswap_kinds(events: &[AppEvent]) -> Vec<SideSwapEventKind> {
        events
            .iter()
            .filter_map(|e| match e {
                AppEvent::SideSwap(s) => Some(s.kind),
                _ => None,
            })
            .collect()
    }

    /// Advances virtual time in steps until the driver has stopped or `max_ms` passed.
    fn settle(plat: &TestPlatform, exec: &mut TestExecutor, app: &App<TestPlatform>, max_ms: u64) {
        let mut elapsed = 0;
        while elapsed < max_ms && block_on(app.sideswap_events_running()).unwrap() {
            plat.timer.advance(500);
            plat.clock.advance(500);
            exec.run_until_stalled();
            elapsed += 500;
        }
    }

    #[test]
    fn connect_limits_and_balance_push_reach_subscribers() {
        let (plat, mut exec) = TestPlatform::new();
        let plat = plat.with_ws(MockWs::new(replies));
        let app = block_on(App::open(test_config(), plat.clone())).unwrap();
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        block_on(app.sideswap_connect("key".into(), None)).unwrap();
        assert!(block_on(app.sideswap_is_connected()).unwrap());
        let limits = block_on(app.peg_limits()).unwrap();
        assert_eq!(limits.min_peg_in_sat, 10_000);

        let got = Arc::new(Mutex::new(vec![]));
        app.subscribe(Box::new(Collect(got.clone())));
        block_on(app.sideswap_start_events()).unwrap();
        exec.run_until_stalled();
        assert!(
            sideswap_kinds(&got.lock().unwrap()).contains(&SideSwapEventKind::PegInWalletBalance)
        );

        block_on(app.sideswap_stop_events()).unwrap();
        exec.run_until_stalled();
        assert_eq!(
            sideswap_kinds(&got.lock().unwrap()).last(),
            Some(&SideSwapEventKind::Closed)
        );
        assert!(!block_on(app.sideswap_events_running()).unwrap());
    }

    #[test]
    fn replacing_the_driver_sends_no_stale_closed() {
        let (plat, mut exec) = TestPlatform::new();
        let plat = plat.with_ws(MockWs::new(replies));
        let app = block_on(App::open(test_config(), plat.clone())).unwrap();
        block_on(app.sideswap_connect("key".into(), None)).unwrap();
        let got = Arc::new(Mutex::new(vec![]));
        app.subscribe(Box::new(Collect(got.clone())));
        block_on(app.sideswap_start_events()).unwrap();
        exec.run_until_stalled();
        // A second start replaces the driver. The old task's final `closed`
        // belongs to the old stream, never to the live subscriber.
        block_on(app.sideswap_start_events()).unwrap();
        exec.run_until_stalled();
        assert!(block_on(app.sideswap_events_running()).unwrap());
        assert!(
            !sideswap_kinds(&got.lock().unwrap()).contains(&SideSwapEventKind::Closed),
            "{:?}",
            got.lock().unwrap()
        );
        block_on(app.sideswap_stop_events()).unwrap();
        exec.run_until_stalled();
        let closed = sideswap_kinds(&got.lock().unwrap())
            .iter()
            .filter(|k| **k == SideSwapEventKind::Closed)
            .count();
        assert_eq!(closed, 1);
    }

    #[test]
    fn driver_stops_when_last_subscriber_leaves() {
        let (plat, mut exec) = TestPlatform::new();
        let plat = plat.with_ws(MockWs::new(replies));
        let app = block_on(App::open(test_config(), plat.clone())).unwrap();
        block_on(app.sideswap_connect("key".into(), None)).unwrap();
        let got = Arc::new(Mutex::new(vec![]));
        let id = app.subscribe(Box::new(Collect(got.clone())));
        block_on(app.sideswap_start_events()).unwrap();
        exec.run_until_stalled();
        assert!(block_on(app.sideswap_events_running()).unwrap());
        app.unsubscribe(id);
        settle(&plat, &mut exec, &app, 120_000);
        assert!(!block_on(app.sideswap_events_running()).unwrap());
        // A new subscription starts a fresh driver.
        let got2 = Arc::new(Mutex::new(vec![]));
        app.subscribe(Box::new(Collect(got2.clone())));
        block_on(app.sideswap_start_events()).unwrap();
        assert!(block_on(app.sideswap_events_running()).unwrap());
    }
}
