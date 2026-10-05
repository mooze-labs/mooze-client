//! SideSwap WebSocket JSON-RPC client. Port of `SideswapApi` and the request
//! helpers of `SideswapService` in `sideswap.dart`.
//!
//! The client runs no background task. [`SideSwapClient::call`] reads frames
//! until the matching id arrives and queues every other frame as a
//! [`Notification`]. Callers drain the queue or wait with
//! [`SideSwapClient::next_event`].

use std::collections::VecDeque;
use std::sync::Arc;

use serde::de::DeserializeOwned;
use serde_json::Value;

use super::protocol::{
    describe_rpc_error, AssetPairMarketData, Notification, PegOrderResponse, PegOrderStatus, Request, RequestIdGen,
    ServerStatus, SideswapAsset, SideswapMarket, StartQuotes, StartQuotesResult, PEG_IN_WALLET_BALANCE,
    PEG_OUT_WALLET_BALANCE, SIDESWAP_API_URL,
};
use crate::ports::{Clock, WsConnection, WsConnector, WsMessage};
use crate::{Error, Result};

/// Message when the client is disposed.
pub const CLOSED_MESSAGE: &str = "conexão encerrada";
/// Message when `result` is not an object.
pub const UNEXPECTED_RESULT: &str = "resposta inesperada do servidor SideSwap";

/// JSON-RPC client over a [`WsConnector`].
pub struct SideSwapClient<C: WsConnector> {
    connector: C,
    url: String,
    api_key: String,
    conn: Option<C::Connection>,
    ids: RequestIdGen,
    notifications: VecDeque<Notification>,
    disposed: bool,
    clock: Option<Arc<dyn Clock>>,
    last_frame_ms: Option<u64>,
    login_result: Option<Value>,
}

impl<C: WsConnector> std::fmt::Debug for SideSwapClient<C> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SideSwapClient")
            .field("url", &self.url)
            .field("connected", &self.conn.is_some())
            .field("queued", &self.notifications.len())
            .field("disposed", &self.disposed)
            .finish_non_exhaustive()
    }
}

impl<C: WsConnector> SideSwapClient<C> {
    /// Client for the production endpoint. Does not connect yet.
    pub fn new(connector: C, api_key: impl Into<String>) -> Self {
        Self {
            connector,
            url: SIDESWAP_API_URL.to_owned(),
            api_key: api_key.into(),
            conn: None,
            ids: RequestIdGen::default(),
            notifications: VecDeque::new(),
            disposed: false,
            clock: None,
            last_frame_ms: None,
            login_result: None,
        }
    }

    /// Overrides the endpoint URL.
    pub fn with_url(mut self, url: impl Into<String>) -> Self {
        self.url = url.into();
        self
    }

    /// Records the time of each received frame for idle checks.
    pub fn with_clock(mut self, clock: Arc<dyn Clock>) -> Self {
        self.clock = Some(clock);
        self
    }

    /// True while a connection is open.
    pub fn is_connected(&self) -> bool {
        self.conn.is_some()
    }

    /// True after [`Self::dispose`].
    pub fn is_disposed(&self) -> bool {
        self.disposed
    }

    /// Time of the last received frame, if a clock is set.
    pub fn last_frame_ms(&self) -> Option<u64> {
        self.last_frame_ms
    }

    /// Result of the last `login_client`.
    pub fn login_result(&self) -> Option<&Value> {
        self.login_result.as_ref()
    }

    /// Opens the connection and sends `login_client`, like `SideswapService.init`.
    /// No-op when already connected.
    pub async fn connect(&mut self) -> Result<()> {
        if self.disposed {
            return Err(Error::Protocol(CLOSED_MESSAGE.into()));
        }
        if self.conn.is_some() {
            return Ok(());
        }
        let conn = self.connector.connect(&self.url).await?;
        self.conn = Some(conn);
        self.touch();
        let login = Request::login(&self.api_key);
        let result = self.call_connected(&login).await?;
        self.login_result = Some(result);
        Ok(())
    }

    /// Closes the transport and connects again with a fresh login.
    pub async fn force_reconnect(&mut self) -> Result<()> {
        if self.disposed {
            return Ok(());
        }
        self.close_transport().await;
        self.connect().await
    }

    /// Closes the connection for good. Later calls fail fast.
    pub async fn dispose(&mut self) {
        if self.disposed {
            return;
        }
        self.disposed = true;
        self.notifications.clear();
        self.close_transport().await;
    }

    async fn close_transport(&mut self) {
        if let Some(mut c) = self.conn.take() {
            // Best-effort close, like `_teardownTransport`.
            let _ = c.close().await;
        }
    }

    fn touch(&mut self) {
        if let Some(c) = &self.clock {
            self.last_frame_ms = Some(c.now_ms());
        }
    }

    /// Sends `req` and waits for the response with the same id.
    ///
    /// Connects first when needed. An RPC `error` or a non-object `result`
    /// becomes [`Error::Protocol`] with the server text. A closed transport
    /// becomes [`Error::Network`]. Timeouts are the platform's job: the
    /// connection's `recv` returns [`Error::Timeout`] after
    /// [`super::protocol::DEFAULT_REQUEST_TIMEOUT_MS`].
    pub async fn call(&mut self, req: &Request) -> Result<Value> {
        if self.disposed {
            return Err(Error::Protocol(CLOSED_MESSAGE.into()));
        }
        self.connect().await?;
        self.call_connected(req).await
    }

    async fn call_connected(&mut self, req: &Request) -> Result<Value> {
        let id = self.ids.allocate();
        self.send_raw(req.encode(id)).await?;
        loop {
            let Some(frame) = self.read_frame().await? else { continue };
            if frame.get("id").and_then(Value::as_u64) == Some(id) {
                if let Some(err) = frame.get("error").filter(|e| !e.is_null()) {
                    // Dart also fans the error out to the market stream.
                    if let Some(n) = Notification::from_frame(&frame) {
                        self.notifications.push_back(n);
                    }
                    return Err(Error::Protocol(describe_rpc_error(err)));
                }
                return match frame.get("result") {
                    Some(r @ Value::Object(_)) => Ok(r.clone()),
                    _ => Err(Error::Protocol(UNEXPECTED_RESULT.into())),
                };
            }
            // Unknown ids are not misrouted: they become notifications.
            if let Some(n) = Notification::from_frame(&frame) {
                self.notifications.push_back(n);
            }
        }
    }

    /// Calls and decodes the result as `T`.
    pub async fn call_typed<T: DeserializeOwned>(&mut self, req: &Request) -> Result<T> {
        let v = self.call(req).await?;
        Ok(serde_json::from_value(v)?)
    }

    async fn send_raw(&mut self, text: String) -> Result<()> {
        let conn = self.conn.as_mut().ok_or_else(|| Error::Network("sideswap not connected".into()))?;
        match conn.send_text(text).await {
            Ok(()) => Ok(()),
            Err(e) => {
                // Dart drops the transport on a send error.
                self.conn = None;
                Err(e)
            }
        }
    }

    /// Reads one frame. `None` for keepalive or non-JSON frames.
    async fn read_frame(&mut self) -> Result<Option<Value>> {
        let conn = self.conn.as_mut().ok_or_else(|| Error::Network("sideswap not connected".into()))?;
        let msg = match conn.recv().await {
            Ok(m) => m,
            Err(e) => {
                if !matches!(e, Error::Timeout(_)) {
                    self.conn = None;
                }
                return Err(e);
            }
        };
        let text = match msg {
            WsMessage::Text(t) => t,
            WsMessage::Binary(b) => String::from_utf8_lossy(&b).into_owned(),
            WsMessage::Closed => {
                self.conn = None;
                return Err(Error::Network("sideswap connection closed".into()));
            }
        };
        self.touch();
        let trimmed = text.trim();
        if trimmed == "ping" || trimmed == "pong" {
            return Ok(None);
        }
        // Non-JSON frames are ignored, like the Dart listener.
        match serde_json::from_str::<Value>(trimmed) {
            Ok(v @ Value::Object(_)) => Ok(Some(v)),
            _ => Ok(None),
        }
    }

    /// Takes every queued notification.
    pub fn drain_notifications(&mut self) -> Vec<Notification> {
        self.notifications.drain(..).collect()
    }

    /// Returns the next notification, reading frames if the queue is empty.
    pub async fn next_event(&mut self) -> Result<Notification> {
        if let Some(n) = self.notifications.pop_front() {
            return Ok(n);
        }
        if self.disposed {
            return Err(Error::Protocol(CLOSED_MESSAGE.into()));
        }
        self.connect().await?;
        // The login may have buffered pushes.
        if let Some(n) = self.notifications.pop_front() {
            return Ok(n);
        }
        loop {
            if let Some(frame) = self.read_frame().await? {
                if let Some(n) = Notification::from_frame(&frame) {
                    return Ok(n);
                }
            }
        }
    }

    /// `server_status`.
    pub async fn server_status(&mut self) -> Result<ServerStatus> {
        self.call_typed(&Request::server_status()).await
    }

    /// `assets`. Dart defaults: `all_assets` true, `embedded_icons` false.
    pub async fn assets(&mut self, all_assets: bool, embedded_icons: bool) -> Result<Vec<SideswapAsset>> {
        let v = self.call(&Request::assets(all_assets, embedded_icons)).await?;
        sub_field(&v, &["assets"])
    }

    /// `market` / `list_markets`.
    pub async fn list_markets(&mut self) -> Result<Vec<SideswapMarket>> {
        let v = self.call(&Request::list_markets()).await?;
        sub_field(&v, &["list_markets", "markets"])
    }

    /// `market` / `start_quotes`. Quotes then arrive as notifications.
    pub async fn start_quotes(&mut self, req: &StartQuotes) -> Result<StartQuotesResult> {
        let v = self.call(&Request::start_quotes(req)).await?;
        sub_field(&v, &["start_quotes"])
    }

    /// `market` / `stop_quotes`.
    pub async fn stop_quotes(&mut self) -> Result<()> {
        self.call(&Request::stop_quotes()).await.map(|_| ())
    }

    /// `market` / `get_quote`: returns the PSET to sign.
    pub async fn get_quote_pset(&mut self, quote_id: u64) -> Result<String> {
        let v = self.call(&Request::get_quote(quote_id)).await?;
        sub_field(&v, &["get_quote", "pset"])
    }

    /// `market` / `taker_sign`: submits the signed PSET, returns the txid.
    pub async fn taker_sign(&mut self, quote_id: u64, pset: &str) -> Result<String> {
        let v = self.call(&Request::taker_sign(quote_id, pset)).await?;
        sub_field(&v, &["taker_sign", "txid"])
    }

    /// `market` / `chart_sub`: returns the initial chart points.
    pub async fn chart_sub(&mut self, base: &str, quote: &str) -> Result<Vec<AssetPairMarketData>> {
        let v = self.call(&Request::chart_sub(base, quote)).await?;
        sub_field(&v, &["chart_sub", "data"])
    }

    /// `market` / `chart_unsub`.
    pub async fn chart_unsub(&mut self, base: &str, quote: &str) -> Result<()> {
        self.call(&Request::chart_unsub(base, quote)).await.map(|_| ())
    }

    /// `peg`: creates a peg order.
    pub async fn create_peg_order(&mut self, peg_in: bool, receive_address: &str) -> Result<PegOrderResponse> {
        self.call_typed(&Request::peg(peg_in, receive_address)).await
    }

    /// `peg_status` for one order.
    pub async fn fetch_peg_status(&mut self, peg_in: bool, order_id: &str) -> Result<PegOrderStatus> {
        self.call_typed(&Request::peg_status(peg_in, order_id)).await
    }

    /// Subscribes to `PegInWalletBalance` or `PegOutWalletBalance`.
    pub async fn subscribe_wallet_balance(&mut self, peg_in: bool) -> Result<Value> {
        let name = if peg_in { PEG_IN_WALLET_BALANCE } else { PEG_OUT_WALLET_BALANCE };
        self.call(&Request::subscribe_value(name)).await
    }

    /// Unsubscribes from a wallet balance value.
    pub async fn unsubscribe_wallet_balance(&mut self, peg_in: bool) -> Result<Value> {
        let name = if peg_in { PEG_IN_WALLET_BALANCE } else { PEG_OUT_WALLET_BALANCE };
        self.call(&Request::unsubscribe_value(name)).await
    }
}

fn sub_field<T: DeserializeOwned>(v: &Value, path: &[&str]) -> Result<T> {
    let mut cur = v;
    for p in path {
        cur = cur.get(*p).ok_or_else(|| Error::Protocol(format!("missing field {p}")))?;
    }
    Ok(serde_json::from_value(cur.clone())?)
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use serde_json::json;

    use super::*;
    use crate::sideswap::protocol::QuoteOutcome;
    use crate::testing::{block_on, FixedClock, MockWs};

    fn id_of(frame: &str) -> u64 {
        serde_json::from_str::<Value>(frame).unwrap()["id"].as_u64().unwrap()
    }
    fn method_of(frame: &str) -> String {
        serde_json::from_str::<Value>(frame).unwrap()["method"].as_str().unwrap().to_owned()
    }

    fn login_ok(frame: &str) -> Option<Vec<String>> {
        (method_of(frame) == "login_client")
            .then(|| vec![json!({"id": id_of(frame), "method": "login_client", "result": {}}).to_string()])
    }

    #[test]
    fn future_is_send() {
        fn assert_send<T: Send>(_: T) {}
        let mut c = SideSwapClient::new(MockWs::new(|_| vec![]), "k");
        assert_send(c.call(&Request::server_status()));
    }

    #[test]
    fn connect_logs_in_and_calls_with_distinct_ids() {
        let ws = MockWs::new(|f| {
            login_ok(f).unwrap_or_else(|| {
                vec![json!({"id": id_of(f), "method": "server_status", "result": {
                    "elements_fee_rate": 0.1, "min_peg_in_amount": 10000, "min_peg_out_amount": 25000,
                    "server_fee_percent_peg_in": 0.1, "server_fee_percent_peg_out": 0.1}})
                .to_string()]
            })
        });
        let clock = Arc::new(FixedClock::new(1234));
        let mut c = SideSwapClient::new(ws.clone(), "key").with_clock(clock);
        let s = block_on(c.server_status()).unwrap();
        assert_eq!(s.min_peg_out_amount, 25000);
        let sent = ws.sent();
        assert_eq!(method_of(&sent[0]), "login_client");
        assert_ne!(id_of(&sent[0]), id_of(&sent[1]));
        assert_eq!(c.last_frame_ms(), Some(1234));
    }

    #[test]
    fn out_of_order_responses_and_notifications_are_buffered() {
        // The server answers a stale id, pushes a quote and a balance, then answers.
        let ws = MockWs::new(|f| {
            login_ok(f).unwrap_or_else(|| {
                let id = id_of(f);
                vec![
                    "ping".to_owned(),
                    "garbage".to_owned(),
                    json!({"id": 999999, "method": "peg", "result": {"order_id": "X"}}).to_string(),
                    json!({"method": "market", "params": {"quote": {"quote_sub_id": 1, "amount": 10,
                        "asset_pair": {"base": "B", "quote": "Q"},
                        "status": {"Success": {"quote_id": 7, "base_amount": 10, "quote_amount": 6,
                        "server_fee": 1, "fixed_fee": 2, "ttl": 30000}}}}})
                    .to_string(),
                    json!({"method": "subscribed_value", "params": {"value": {"PegInWalletBalance": {"available": 5}}}})
                        .to_string(),
                    json!({"id": id, "method": "peg_status", "result": {"order_id": "B"}}).to_string(),
                ]
            })
        });
        let mut c = SideSwapClient::new(ws, "k");
        let r = block_on(c.call(&Request::peg_status(true, "B"))).unwrap();
        assert_eq!(r["order_id"], "B");
        let n = c.drain_notifications();
        assert_eq!(n.len(), 3);
        assert!(matches!(&n[0], Notification::Other(v) if v["id"] == 999999));
        match &n[1] {
            Notification::Quote(q) => assert!(matches!(q.outcome, QuoteOutcome::Success(ref s) if s.quote_id == 7)),
            other => panic!("{other:?}"),
        }
        assert_eq!(n[2], Notification::PegInWalletBalance(5));
        assert!(c.drain_notifications().is_empty());
    }

    #[test]
    fn rpc_error_and_bad_result_are_protocol_errors() {
        let ws = MockWs::new(|f| {
            login_ok(f).unwrap_or_else(|| {
                let id = id_of(f);
                if method_of(f) == "peg" {
                    vec![json!({"id": id, "error": {"code": -1, "message": "peg disabled"}}).to_string()]
                } else {
                    vec![json!({"id": id, "method": "peg_status", "result": "not-an-object"}).to_string()]
                }
            })
        });
        let mut c = SideSwapClient::new(ws, "k");
        assert_eq!(block_on(c.call(&Request::peg(true, "x"))), Err(Error::Protocol("peg disabled".into())));
        assert_eq!(block_on(c.call(&Request::peg_status(true, "x"))), Err(Error::Protocol(UNEXPECTED_RESULT.into())));
    }

    #[test]
    fn closed_transport_is_network_error_and_reconnects() {
        // Server answers login only, so the call sees the close.
        let ws = MockWs::new(|f| login_ok(f).unwrap_or_default());
        let mut c = SideSwapClient::new(ws.clone(), "k");
        assert!(matches!(block_on(c.call(&Request::server_status())), Err(Error::Network(_))));
        assert!(!c.is_connected());
        let _ = block_on(c.call(&Request::server_status()));
        let logins = ws.sent().iter().filter(|f| method_of(f) == "login_client").count();
        assert_eq!(logins, 2);
    }

    #[test]
    fn dispose_fails_fast() {
        let ws = MockWs::new(|f| login_ok(f).unwrap_or_default());
        let mut c = SideSwapClient::new(ws, "k");
        block_on(c.dispose());
        assert_eq!(block_on(c.call(&Request::server_status())), Err(Error::Protocol(CLOSED_MESSAGE.into())));
    }

    #[test]
    fn next_event_reads_pushes() {
        let ws = MockWs::new(|f| login_ok(f).unwrap_or_default()).with_preload(vec![json!({
            "method": "subscribed_value", "params": {"value": {"PegOutWalletBalance": {"available": 9}}}})
        .to_string()]);
        let mut c = SideSwapClient::new(ws, "k");
        // Login frame is answered after the preloaded push, which is buffered.
        assert_eq!(block_on(c.next_event()).unwrap(), Notification::PegOutWalletBalance(9));
    }

    #[test]
    fn market_helpers_extract_sub_results() {
        let ws = MockWs::new(|f| {
            login_ok(f).unwrap_or_else(|| {
                let v: Value = serde_json::from_str(f).unwrap();
                let id = v["id"].clone();
                let p = &v["params"];
                let result = if p.get("get_quote").is_some() {
                    json!({"get_quote": {"pset": "cHNldA==", "ttl": 30000}})
                } else if p.get("taker_sign").is_some() {
                    json!({"taker_sign": {"txid": "deadbeef"}})
                } else if p.get("list_markets").is_some() {
                    json!({"list_markets": {"markets": [{"asset_pair": {"base": "B", "quote": "Q"},
                        "fee_asset": "Quote", "type": "Stablecoin"}]}})
                } else {
                    json!({"assets": [{"asset_id": "A", "name": "Tether", "precision": 8, "ticker": "USDt",
                        "icon_url": null, "extra": 1}]})
                };
                vec![json!({"id": id, "method": v["method"], "result": result}).to_string()]
            })
        });
        let mut c = SideSwapClient::new(ws, "k");
        assert_eq!(block_on(c.get_quote_pset(7)).unwrap(), "cHNldA==");
        assert_eq!(block_on(c.taker_sign(7, "signed")).unwrap(), "deadbeef");
        let m = block_on(c.list_markets()).unwrap();
        assert_eq!((m[0].base_asset_id(), m[0].market_type.as_str()), ("B", "Stablecoin"));
        let a = block_on(c.assets(true, false)).unwrap();
        assert_eq!(a[0].ticker, "USDt");
    }
}
