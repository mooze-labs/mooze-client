//! SideSwap asset swaps and Bitcoin <-> Liquid pegs.
//!
//! Replaces the Dart `SideswapApi`/`SideswapService`, `SwapRepositoryImpl`,
//! `PegRepositoryImpl`, `PegWalletImpl`, `DriftPegStore`, `PegOrchestrator`
//! and `PegTracker`. One WebSocket serves swaps and pegs.
//!
//! Server pushes reach Dart through `sideswapEvents`: a bridge task reads
//! the socket and adds quotes, peg wallet balances and connection changes
//! to the stream. Cancel it with `sideswapCloseEvents` or by closing the
//! Dart subscription. Peg status is polled: call `pegRefreshDue` at
//! `nextWakeupMs`.

use flutter_rust_bridge::frb;
use mooze_core::peg::entities::PegServerLimits;
use mooze_core::peg::{
    evaluate_peg_amount, KvPegStore, PegAmountIssue, PegError, PegOrchestrator, PegRepository,
};
use mooze_core::ports::Clock;
use mooze_core::sideswap::protocol::SIDESWAP_API_URL;
use mooze_core::sideswap::swap::StartQuoteOutcome;
use mooze_core::sideswap::{SideSwapClient, SwapService};

use super::core::MoozeCore;
pub use super::types::*;
use crate::frb_generated::StreamSink;
use crate::glue::{LiquidPort, Swap, WalletPegPort};
use crate::ports::{on_runtime, FileKv, SystemClock};
use crate::ws::TungsteniteConnector;

fn not_connected() -> mooze_core::Error {
    mooze_core::Error::InvalidState("sideswap not connected; call sideswapConnect first".into())
}

fn session(guard: &mut Option<Swap>) -> mooze_core::Result<&mut Swap> {
    guard.as_mut().ok_or_else(not_connected)
}

fn peg_store(core: &MoozeCore, wallet_id: &str) -> KvPegStore<FileKv, SystemClock> {
    KvPegStore::new(core.inner.kv.clone(), SystemClock, wallet_id)
}

/// Validates a peg amount (Dart `evaluatePegAmount`). The minimum comes
/// from `limits`, or `fallback_minimum_sats` when unknown. A drain is
/// always valid.
#[frb(sync)]
pub fn peg_validate_amount(
    direction: PegDirectionDto,
    amount_sat: Option<u64>,
    spendable_sat: u64,
    limits: Option<PegServerLimitsDto>,
    fallback_minimum_sats: u64,
    drain: bool,
) -> PegAmountValidationDto {
    let limits = limits.map(PegServerLimits::from);
    let v = evaluate_peg_amount(direction.into(), amount_sat, spendable_sat, limits.as_ref(), fallback_minimum_sats, drain);
    PegAmountValidationDto {
        has_amount: v.has_amount,
        is_valid: v.is_valid,
        issue: v.issue.map(|i| match i {
            PegAmountIssue::BelowMinimum => PegAmountIssueDto::BelowMinimum,
            PegAmountIssue::AboveBalance => PegAmountIssueDto::AboveBalance,
        }),
        minimum_sats: v.minimum_sats,
        maximum_sats: v.maximum_sats,
        shows_issue: v.shows_issue(),
    }
}

/// Default SideSwap endpoint.
#[frb(sync)]
pub fn sideswap_default_url() -> String {
    SIDESWAP_API_URL.to_owned()
}

/// Peg failure as a bridge error. The message is the Portuguese UI text.
fn peg_core_error(e: PegError) -> CoreError {
    let kind = match &e {
        PegError::BelowMinimum { .. } | PegError::InsufficientFunds(_) => CoreErrorKind::InvalidInput,
        PegError::TransportFailure(_) => CoreErrorKind::Network,
        PegError::UnknownOutcome { .. } => CoreErrorKind::Timeout,
        PegError::WalletBusy(_) => CoreErrorKind::InvalidState,
        PegError::ProviderRejected(_) | PegError::OrderNotFound(_) | PegError::WalletFailure(_) => CoreErrorKind::Service,
    };
    CoreError { kind, message: e.message() }
}

// ───────────────────────────── MoozeCore

impl MoozeCore {
    /// Opens the SideSwap connection and logs in (Dart `SideswapService.init`).
    /// `url` null uses `sideswapDefaultUrl`. No-op when connected.
    pub async fn sideswap_connect(&self, api_key: String, url: Option<String>) -> Result<(), CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move {
            let mut guard = inner.sideswap.lock().await;
            if let Some(swap) = guard.as_mut() {
                return swap.client_mut().connect().await;
            }
            let client = SideSwapClient::new(TungsteniteConnector, api_key)
                .with_url(url.unwrap_or_else(|| SIDESWAP_API_URL.to_owned()))
                .with_clock(std::sync::Arc::new(SystemClock));
            let mut swap = SwapService::new(client, LiquidPort::new(&inner));
            swap.client_mut().connect().await?;
            *guard = Some(swap);
            Ok(())
        })
        .await?)
    }

    /// Closes the connection and stops the event stream. Idempotent.
    pub async fn sideswap_disconnect(&self) {
        let state = self.inner.sideswap.clone();
        state.stop_driver();
        let _ = on_runtime(async move {
            if let Some(mut swap) = state.lock().await.take() {
                swap.stop_quote().await;
                swap.client_mut().dispose().await;
            }
            Ok(())
        })
        .await;
    }

    /// True while the socket is open.
    pub async fn sideswap_is_connected(&self) -> bool {
        self.inner.sideswap.lock().await.as_mut().is_some_and(|s| s.client_mut().is_connected())
    }

    /// Server pushes: quotes, peg wallet balances, disconnects. A bridge task
    /// reads the socket while the stream is open. Opening a new stream
    /// replaces the old one, which ends with a `closed` item. Close it with
    /// `sideswapCloseEvents`, `sideswapDisconnect` or by cancelling the Dart
    /// subscription (the task stops at its next item).
    pub async fn sideswap_events(&self, sink: StreamSink<SideSwapEventDto>) -> Result<(), CoreError> {
        let state = self.inner.sideswap.clone();
        Ok(on_runtime(async move {
            state.start_driver(Box::new(move |event| sink.add(event).is_ok()));
            Ok(())
        })
        .await?)
    }

    /// Stops the event stream task. The stream ends with a `closed` item.
    pub async fn sideswap_close_events(&self) {
        self.inner.sideswap.stop_driver();
    }

    /// True while the event stream task runs.
    pub async fn sideswap_events_running(&self) -> bool {
        self.inner.sideswap.driver_running()
    }

    /// SideSwap markets.
    pub async fn sideswap_markets(&self) -> Result<Vec<SideswapMarketDto>, CoreError> {
        let state = self.inner.sideswap.clone();
        let list = on_runtime(async move { session(&mut *state.lock().await)?.get_markets().await }).await?;
        Ok(list.iter().map(Into::into).collect())
    }

    /// SideSwap assets.
    pub async fn sideswap_assets(&self) -> Result<Vec<SideswapAssetDto>, CoreError> {
        let state = self.inner.sideswap.clone();
        let list = on_runtime(async move { session(&mut *state.lock().await)?.get_assets().await }).await?;
        Ok(list.iter().map(Into::into).collect())
    }

    /// Starts a quote subscription for `amount` of `send_asset_id`
    /// (Dart `SwapController.startQuote`). Stops the previous one. Funds it
    /// with the Liquid wallet UTXOs. Quotes arrive on `sideswapEvents`.
    pub async fn sideswap_start_quote(
        &self,
        send_asset_id: String,
        receive_asset_id: String,
        amount: u64,
    ) -> Result<StartQuoteDto, CoreError> {
        let state = self.inner.sideswap.clone();
        let outcome = on_runtime(async move {
            let mut guard = state.lock().await;
            session(&mut guard)?.start_quote(&send_asset_id, &receive_asset_id, amount, SystemClock.now_ms()).await
        })
        .await?;
        Ok(match outcome {
            StartQuoteOutcome::Started(intent) => StartQuoteDto {
                started: true,
                quote_sub_id: intent.quote_sub_id,
                base_asset_id: Some(intent.params.base_asset),
                quote_asset_id: Some(intent.params.quote_asset),
            },
            StartQuoteOutcome::AlreadyInProgress => {
                StartQuoteDto { started: false, quote_sub_id: None, base_asset_id: None, quote_asset_id: None }
            }
        })
    }

    /// Stops the quote subscription. Best-effort.
    pub async fn sideswap_stop_quote(&self) {
        let state = self.inner.sideswap.clone();
        let _ = on_runtime(async move {
            if let Some(swap) = state.lock().await.as_mut() {
                swap.stop_quote().await;
            }
            Ok(())
        })
        .await;
    }

    /// Accepts a quote: stops quotes, fetches the PSET, signs it with the
    /// Liquid wallet and the mnemonic from the secure store, submits it.
    /// Returns the txid.
    pub async fn sideswap_execute_swap(&self, quote_id: u64) -> Result<String, CoreError> {
        let state = self.inner.sideswap.clone();
        Ok(on_runtime(async move { session(&mut *state.lock().await)?.execute_swap(quote_id).await }).await?)
    }

    // ───────────────────────────── pegs

    /// Peg minimums and fees from `server_status`.
    pub async fn peg_limits(&self) -> Result<PegServerLimitsDto, CoreError> {
        let state = self.inner.sideswap.clone();
        let r = on_runtime(async move {
            let mut guard = state.lock().await;
            Ok(session(&mut guard)?.client_mut().get_limits().await)
        })
        .await?;
        r.map(Into::into).map_err(peg_core_error)
    }

    /// Prices a peg without creating an order.
    pub async fn peg_quote(
        &self,
        direction: PegDirectionDto,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
    ) -> Result<PegQuoteDto, CoreError> {
        let inner = self.inner.clone();
        let store = peg_store(self, "");
        let r = on_runtime(async move {
            let mut guard = inner.sideswap.lock().await;
            let client = session(&mut guard)?.client_mut();
            let mut orchestrator = PegOrchestrator::new(client, WalletPegPort::new(&inner), store);
            Ok(orchestrator.quote(direction.into(), amount_sat, fee_rate_sat_per_vbyte, drain).await)
        })
        .await?;
        r.map(Into::into).map_err(peg_core_error)
    }

    /// Creates a peg order, stores it under `wallet_id`, funds it from the
    /// wallet and starts tracking it. `external_payout_address` is allowed
    /// only for peg-outs; null pays to the own wallet.
    pub async fn peg_execute(
        &self,
        wallet_id: String,
        direction: PegDirectionDto,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
        external_payout_address: Option<String>,
    ) -> Result<PegExecutionDto, CoreError> {
        let inner = self.inner.clone();
        let store = peg_store(self, &wallet_id);
        let r = on_runtime(async move {
            let mut guard = inner.sideswap.lock().await;
            let client = session(&mut guard)?.client_mut();
            let mut orchestrator = PegOrchestrator::new(client, WalletPegPort::new(&inner), store);
            let executed = orchestrator
                .execute(direction.into(), amount_sat, fee_rate_sat_per_vbyte, drain, external_payout_address.as_deref())
                .await;
            if let Ok(ex) = &executed {
                let store = KvPegStore::new(inner.kv.clone(), SystemClock, wallet_id);
                if let Ok(Some(rec)) = store.get(&ex.order.order_id).await {
                    inner.sideswap.pegs.lock().await.track(rec.to_tracked(), SystemClock.now_ms());
                }
            }
            Ok(executed)
        })
        .await?;
        let ex = r.map_err(peg_core_error)?;
        Ok(PegExecutionDto { order: (&ex.order).into(), funding_tx_id: ex.funding_tx_id })
    }

    /// One-shot status of an order.
    pub async fn peg_status(&self, direction: PegDirectionDto, order_id: String) -> Result<PegProgressDto, CoreError> {
        let state = self.inner.sideswap.clone();
        let r = on_runtime(async move {
            let mut guard = state.lock().await;
            Ok(session(&mut guard)?.client_mut().get_status(direction.into(), &order_id).await)
        })
        .await?;
        r.map(|p| (&p).into()).map_err(peg_core_error)
    }

    /// Stored pegs of `wallet_id`, oldest first. Needs no connection.
    pub async fn peg_list(&self, wallet_id: String) -> Result<Vec<PegRecordDto>, CoreError> {
        let store = peg_store(self, &wallet_id);
        let list = on_runtime(async move { store.list().await }).await?;
        Ok(list.iter().map(Into::into).collect())
    }

    /// Resumes tracking of the pending pegs stored under `wallet_id`.
    /// Idempotent. Returns every tracked peg.
    pub async fn peg_restore(&self, wallet_id: String) -> Result<Vec<TrackedPegDto>, CoreError> {
        let state = self.inner.sideswap.clone();
        let store = peg_store(self, &wallet_id);
        let list = on_runtime(async move {
            let mut tracker = state.pegs.lock().await;
            tracker.restore_from(&store, SystemClock.now_ms()).await?;
            Ok(tracker.current().iter().map(TrackedPegDto::from).collect::<Vec<_>>())
        })
        .await?;
        Ok(list)
    }

    /// Every tracked peg.
    pub async fn peg_tracked(&self) -> Vec<TrackedPegDto> {
        self.inner.sideswap.pegs.lock().await.current().iter().map(Into::into).collect()
    }

    /// Stops tracking `order_id`. Storage is unchanged.
    pub async fn peg_untrack(&self, order_id: String) {
        self.inner.sideswap.pegs.lock().await.untrack(&order_id);
    }

    /// Polls every tracked peg whose time has come, persists terminal ones
    /// under `wallet_id`, and returns the new state (Dart `PegTracker`).
    /// Transport errors only reschedule.
    pub async fn peg_refresh_due(&self, wallet_id: String) -> Result<PegRefreshDto, CoreError> {
        let state = self.inner.sideswap.clone();
        let store = peg_store(self, &wallet_id);
        Ok(on_runtime(async move {
            let mut guard = state.lock().await;
            let swap = session(&mut guard)?;
            let mut tracker = state.pegs.lock().await;
            let mut changed = Vec::new();
            let mut finished = Vec::new();
            for order_id in tracker.due(SystemClock.now_ms()) {
                let update = tracker.refresh(swap.client_mut(), &store, &order_id, SystemClock.now_ms()).await;
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
        })
        .await?)
    }
}

#[cfg(test)]
mod tests {
    use std::sync::mpsc;
    use std::sync::{Arc, Mutex as StdMutex};
    use std::time::Duration;

    use futures::{SinkExt, StreamExt};
    use mooze_core::peg::store::{PegRecord, PEG_STATUS_PENDING};
    use serde_json::{json, Value};
    use tokio::net::TcpListener;
    use tokio_tungstenite::tungstenite::Message;

    use super::*;
    use crate::api::core::tests::{open_core, with_memory_store, ABANDON};
    use crate::ports::runtime;

    const LBTC: &str = "lbtc-asset";
    const USDT: &str = "usdt-asset";

    /// Replies of the mock SideSwap server to one request frame.
    fn replies(v: &Value) -> Vec<String> {
        let id = v["id"].clone();
        let method = v["method"].as_str().unwrap_or_default().to_owned();
        let p = &v["params"];
        let reply = |r: Value| json!({"id": id, "method": method, "result": r}).to_string();
        match method.as_str() {
            "login_client" => vec![reply(json!({}))],
            // Answer, then push one subscription value for the event stream.
            "server_status" => vec![
                reply(json!({"elements_fee_rate": 0.1, "min_peg_in_amount": 10000, "min_peg_out_amount": 25000,
                    "server_fee_percent_peg_in": 0.1, "server_fee_percent_peg_out": 0.1})),
                json!({"method": "subscribed_value", "params": {"value": {"PegInWalletBalance": {"available": 777}}}})
                    .to_string(),
            ],
            "peg_status" => vec![reply(json!({"order_id": p["order_id"], "peg_in": true, "addr": "bc1qdep",
                "addr_recv": "lq1recv", "created_at": 1, "expires_at": 0, "list": [
                {"tx_hash": "fund", "vout": 0, "status": "x", "amount": 60000, "payout": 59000,
                 "payout_txid": "payout-tx", "created_at": 2, "tx_state": "Done", "tx_state_code": 4}]}))],
            "market" if p.get("list_markets").is_some() => vec![reply(json!({"list_markets": {"markets": [
                {"asset_pair": {"base": LBTC, "quote": USDT}, "fee_asset": "Quote", "type": "Stablecoin"}]}}))],
            // A quote push arrives before the answer, as on the real server.
            "market" if p.get("start_quotes").is_some() => vec![
                json!({"method": "market", "params": {"quote": {"quote_sub_id": 5, "amount": p["start_quotes"]["amount"],
                    "asset_pair": {"base": LBTC, "quote": USDT}, "status": {"Success": {"quote_id": 42,
                    "base_amount": 0, "quote_amount": 0, "server_fee": 1, "fixed_fee": 2, "ttl": 30000}}}}})
                .to_string(),
                reply(json!({"start_quotes": {"quote_sub_id": 5, "fee_asset": "Quote"}})),
            ],
            "market" if p.get("stop_quotes").is_some() => vec![reply(json!({"stop_quotes": {}}))],
            "market" if p.get("get_quote").is_some() => vec![reply(json!({"get_quote": {"pset": "bm90LWEtcHNldA==", "ttl": 1}}))],
            _ => vec![json!({"id": id, "error": {"code": -1, "message": "unsupported"}}).to_string()],
        }
    }

    /// JSON-RPC WebSocket server on 127.0.0.1. Logs every request frame.
    async fn sideswap_server() -> (String, Arc<StdMutex<Vec<Value>>>) {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let url = format!("ws://{}", listener.local_addr().unwrap());
        let seen = Arc::new(StdMutex::new(Vec::new()));
        let log = seen.clone();
        tokio::spawn(async move {
            loop {
                let (tcp, _) = listener.accept().await.unwrap();
                let log = log.clone();
                tokio::spawn(async move {
                    let mut ws = tokio_tungstenite::accept_async(tcp).await.unwrap();
                    while let Some(Ok(Message::Text(text))) = ws.next().await {
                        let v: Value = serde_json::from_str(text.as_str()).unwrap();
                        log.lock().unwrap().push(v.clone());
                        for r in replies(&v) {
                            ws.send(Message::text(r)).await.unwrap();
                        }
                    }
                });
            }
        });
        (url, seen)
    }

    fn methods(seen: &StdMutex<Vec<Value>>) -> Vec<String> {
        seen.lock()
            .unwrap()
            .iter()
            .map(|v| {
                let m = v["method"].as_str().unwrap().to_owned();
                match v["params"].as_object().and_then(|p| p.keys().next().cloned()) {
                    Some(k) if m == "market" => format!("market/{k}"),
                    _ => m,
                }
            })
            .collect()
    }

    /// Next stream item of `kind`, skipping others.
    fn next_of(rx: &mpsc::Receiver<SideSwapEventDto>, kind: SideSwapEventKind) -> SideSwapEventDto {
        loop {
            let e = rx.recv_timeout(Duration::from_secs(10)).unwrap_or_else(|_| panic!("no {kind:?} event"));
            if e.kind == kind {
                return e;
            }
        }
    }

    #[test]
    fn calls_before_connect_fail() {
        let core = open_core("ss-none");
        let err = runtime().block_on(core.peg_limits()).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::InvalidState);
        assert!(!runtime().block_on(core.sideswap_is_connected()));
        let err = runtime().block_on(core.sideswap_connect("k".into(), Some("ws://127.0.0.1:1".into()))).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::Network);
    }

    #[test]
    fn requests_events_quotes_and_peg_tracking() {
        let core = open_core("ss-flow");
        let map = with_memory_store(&core);
        map.lock().unwrap().insert("mnemonic_mainWallet".into(), ABANDON.into());
        runtime().block_on(core.liquid_connect(ABANDON.into())).unwrap();
        let (url, seen) = runtime().block_on(sideswap_server());
        runtime().block_on(core.sideswap_connect("api-key".into(), Some(url))).unwrap();
        assert!(runtime().block_on(core.sideswap_is_connected()));
        assert_eq!(seen.lock().unwrap()[0]["params"]["api_key"], "api-key");

        // The event stream, as `sideswapEvents` wires it to a StreamSink.
        let (tx, rx) = mpsc::channel();
        let state = core.inner.sideswap.clone();
        runtime().block_on(async move { state.start_driver(Box::new(move |e| tx.send(e).is_ok())) });
        assert!(runtime().block_on(core.sideswap_events_running()));

        // Request/response while the driver reads the socket.
        let limits = runtime().block_on(core.peg_limits()).unwrap();
        assert_eq!((limits.min_peg_in_sat, limits.min_peg_out_sat), (10_000, 25_000));
        // The push after the answer reaches the stream.
        assert_eq!(next_of(&rx, SideSwapEventKind::PegInWalletBalance).balance_sat, Some(777));

        // Quote subscription. Amount 0 needs no UTXOs.
        let started = runtime().block_on(core.sideswap_start_quote(LBTC.into(), USDT.into(), 0)).unwrap();
        assert!(started.started);
        assert_eq!((started.quote_sub_id, started.base_asset_id.as_deref()), (Some(5), Some(LBTC)));
        let quote = next_of(&rx, SideSwapEventKind::Quote).quote.unwrap();
        assert_eq!((quote.status, quote.quote_id, quote.fixed_fee), (QuoteStatusDto::Success, Some(42), Some(2)));

        // Accepting signs with the stored mnemonic; this PSET is not valid.
        let err = runtime().block_on(core.sideswap_execute_swap(42)).unwrap_err();
        assert!(!err.message.is_empty());
        let m = methods(&seen);
        assert!(m.ends_with(&["market/stop_quotes".to_owned(), "market/get_quote".to_owned()]), "{m:?}");

        // Peg tracking: a funded peg-in becomes completed and is persisted.
        let store = peg_store(&core, "w1");
        let rec = PegRecord {
            order_id: "ord-1".into(),
            peg_in: true,
            sideswap_address: "bc1qdep".into(),
            payout_address: "lq1recv".into(),
            amount: 60_000,
            created_at_ms: 1,
            wallet_id: "w1".into(),
            status: PEG_STATUS_PENDING.into(),
            provider: "sideswap".into(),
            funding_tx_id: Some("fund".into()),
            payout_tx_id: None,
            error_message: None,
            updated_at_ms: None,
            metadata: None,
        };
        runtime().block_on(store.import(&rec)).unwrap();
        let tracked = runtime().block_on(core.peg_restore("w1".into())).unwrap();
        assert_eq!(tracked.len(), 1);
        assert_eq!(tracked[0].phase, PegPhaseDto::Detected);
        // Restored pegs wait one interval; a fresh one is due at once.
        let state = core.inner.sideswap.clone();
        runtime().block_on(async move { state.pegs.lock().await.track(rec.to_tracked(), 0) });
        let refresh = runtime().block_on(core.peg_refresh_due("w1".into())).unwrap();
        assert_eq!(refresh.changed, vec!["ord-1".to_owned()]);
        assert_eq!(refresh.finished[0].phase, PegPhaseDto::Completed);
        assert_eq!(refresh.finished[0].payout_tx_id.as_deref(), Some("payout-tx"));
        assert_eq!(refresh.next_wakeup_ms, None);
        let stored = runtime().block_on(core.peg_list("w1".into())).unwrap();
        assert_eq!((stored[0].status.as_str(), stored[0].payout_tx_id.as_deref()), ("completed", Some("payout-tx")));

        // Explicit cancel ends the stream with `closed`.
        runtime().block_on(core.sideswap_close_events());
        next_of(&rx, SideSwapEventKind::Closed);
        assert!(!runtime().block_on(core.sideswap_events_running()));
        runtime().block_on(core.sideswap_disconnect());
        assert!(!runtime().block_on(core.sideswap_is_connected()));
    }

    #[test]
    fn dropped_receiver_stops_the_driver() {
        let core = open_core("ss-drop");
        let (url, _) = runtime().block_on(sideswap_server());
        runtime().block_on(core.sideswap_connect("k".into(), Some(url))).unwrap();
        let (tx, rx) = mpsc::channel::<SideSwapEventDto>();
        let state = core.inner.sideswap.clone();
        runtime().block_on(async move { state.start_driver(Box::new(move |e| tx.send(e).is_ok())) });
        drop(rx);
        // The next item (the balance push) fails to send and ends the task.
        runtime().block_on(core.peg_limits()).unwrap();
        for _ in 0..100 {
            if !runtime().block_on(core.sideswap_events_running()) {
                return;
            }
            std::thread::sleep(Duration::from_millis(20));
        }
        panic!("driver still running");
    }

    #[test]
    fn peg_amount_validation() {
        let limits = PegServerLimitsDto {
            min_peg_in_sat: 10_000,
            min_peg_out_sat: 25_000,
            server_fee_percent_peg_in: 0.1,
            server_fee_percent_peg_out: 0.1,
        };
        let v = peg_validate_amount(PegDirectionDto::PegOut, Some(20_000), 100_000, Some(limits), 25_000, false);
        assert_eq!((v.is_valid, v.issue, v.minimum_sats), (false, Some(PegAmountIssueDto::BelowMinimum), Some(25_000)));
        assert!(v.shows_issue);
        assert!(peg_validate_amount(PegDirectionDto::PegIn, Some(20_000), 100_000, Some(limits), 25_000, false).is_valid);
    }
}
