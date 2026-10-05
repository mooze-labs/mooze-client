//! SideSwap JSON-RPC wire types.
//!
//! Field names match the wire.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::domain::LiquidUtxo;

/// SideSwap WebSocket endpoint.
pub const SIDESWAP_API_URL: &str = "wss://api.sideswap.io/json-rpc-ws";

/// User agent sent in `login_client`.
pub const USER_AGENT: &str = "MoozeClient";

/// Client version sent in `login_client`.
pub const CLIENT_VERSION: &str = "1.0.0";

/// Default per-request timeout. The platform enforces it.
pub const DEFAULT_REQUEST_TIMEOUT_MS: u64 = 15_000;

/// Fallback text for an RPC error without a message.
pub const UNKNOWN_ERROR: &str = "Erro desconhecido";

/// Request method names.
pub mod method {
    /// Login with an API key.
    pub const LOGIN_CLIENT: &str = "login_client";
    /// Server limits and fee rates.
    pub const SERVER_STATUS: &str = "server_status";
    /// Create a peg order.
    pub const PEG: &str = "peg";
    /// Status of a peg order.
    pub const PEG_STATUS: &str = "peg_status";
    /// Subscribe to a server value.
    pub const SUBSCRIBE_VALUE: &str = "subscribe_value";
    /// Unsubscribe from a server value.
    pub const UNSUBSCRIBE_VALUE: &str = "unsubscribe_value";
    /// Push frame for a subscribed value.
    pub const SUBSCRIBED_VALUE: &str = "subscribed_value";
    /// Asset list.
    pub const ASSETS: &str = "assets";
    /// Market sub-protocol (quotes, markets, charts).
    pub const MARKET: &str = "market";
}

/// Value name for the peg-in wallet balance subscription.
pub const PEG_IN_WALLET_BALANCE: &str = "PegInWalletBalance";
/// Value name for the peg-out wallet balance subscription.
pub const PEG_OUT_WALLET_BALANCE: &str = "PegOutWalletBalance";

/// Allocates request ids. Starts at 1 and increments.
#[derive(Debug, Clone)]
pub struct RequestIdGen {
    next: u64,
}

impl Default for RequestIdGen {
    fn default() -> Self {
        Self { next: 1 }
    }
}

impl RequestIdGen {
    /// Returns the next id.
    pub fn allocate(&mut self) -> u64 {
        let id = self.next;
        self.next += 1;
        id
    }
}

/// One outgoing JSON-RPC request.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Request {
    /// Method name, for example `market`.
    pub method: String,
    /// Params object, or `null`.
    pub params: Value,
}

impl Request {
    /// Builds a request.
    pub fn new(method: &str, params: Value) -> Self {
        Self { method: method.to_owned(), params }
    }

    /// Encodes the frame `{"id","method","params"}`.
    pub fn encode(&self, id: u64) -> String {
        json!({ "id": id, "method": self.method, "params": self.params }).to_string()
    }

    /// `login_client` with the fixed user agent and version.
    pub fn login(api_key: &str) -> Self {
        Self::new(
            method::LOGIN_CLIENT,
            json!({ "api_key": api_key, "user_agent": USER_AGENT, "version": CLIENT_VERSION }),
        )
    }

    /// `server_status` with `null` params.
    pub fn server_status() -> Self {
        Self::new(method::SERVER_STATUS, Value::Null)
    }

    /// `peg`: creates an order. `peg_in` true means BTC to L-BTC.
    pub fn peg(peg_in: bool, recv_addr: &str) -> Self {
        Self::new(method::PEG, json!({ "peg_in": peg_in, "recv_addr": recv_addr }))
    }

    /// `peg_status` for one order.
    pub fn peg_status(peg_in: bool, order_id: &str) -> Self {
        Self::new(method::PEG_STATUS, json!({ "peg_in": peg_in, "order_id": order_id }))
    }

    /// `subscribe_value`.
    pub fn subscribe_value(value: &str) -> Self {
        Self::new(method::SUBSCRIBE_VALUE, json!({ "value": value }))
    }

    /// `unsubscribe_value`.
    pub fn unsubscribe_value(value: &str) -> Self {
        Self::new(method::UNSUBSCRIBE_VALUE, json!({ "value": value }))
    }

    /// `assets`.
    pub fn assets(all_assets: bool, embedded_icons: bool) -> Self {
        Self::new(method::ASSETS, json!({ "all_assets": all_assets, "embedded_icons": embedded_icons }))
    }

    /// `market` / `list_markets`.
    pub fn list_markets() -> Self {
        Self::new(method::MARKET, json!({ "list_markets": {} }))
    }

    /// `market` / `start_quotes`.
    pub fn start_quotes(req: &StartQuotes) -> Self {
        Self::new(method::MARKET, json!({ "start_quotes": req }))
    }

    /// `market` / `get_quote`.
    pub fn get_quote(quote_id: u64) -> Self {
        Self::new(method::MARKET, json!({ "get_quote": { "quote_id": quote_id } }))
    }

    /// `market` / `taker_sign`.
    pub fn taker_sign(quote_id: u64, pset: &str) -> Self {
        Self::new(method::MARKET, json!({ "taker_sign": { "quote_id": quote_id, "pset": pset } }))
    }

    /// `market` / `stop_quotes`.
    pub fn stop_quotes() -> Self {
        Self::new(method::MARKET, json!({ "stop_quotes": {} }))
    }

    /// `market` / `chart_sub`.
    pub fn chart_sub(base: &str, quote: &str) -> Self {
        Self::new(method::MARKET, json!({ "chart_sub": { "asset_pair": { "base": base, "quote": quote } } }))
    }

    /// `market` / `chart_unsub`.
    pub fn chart_unsub(base: &str, quote: &str) -> Self {
        Self::new(method::MARKET, json!({ "chart_unsub": { "asset_pair": { "base": base, "quote": quote } } }))
    }
}

/// Text of a JSON-RPC `error` member.
pub fn describe_rpc_error(error: &Value) -> String {
    match error {
        Value::Object(m) => m
            .get("message")
            .filter(|v| !v.is_null())
            .or_else(|| m.get("error").filter(|v| !v.is_null()))
            .map(value_to_string)
            .unwrap_or_else(|| UNKNOWN_ERROR.to_owned()),
        Value::Null => UNKNOWN_ERROR.to_owned(),
        other => value_to_string(other),
    }
}

fn value_to_string(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        other => other.to_string(),
    }
}

/// Base/quote asset ids of a market.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AssetPair {
    pub base: String,
    pub quote: String,
}

/// Trade direction on the wire.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TradeDir {
    Buy,
    Sell,
}

/// Which side of the pair `amount` refers to. Wire values `Base` and `Quote`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AssetType {
    Base,
    Quote,
}

impl AssetType {
    /// Parses a wire name. Invalid names fall back to `Base`.
    pub fn normalize(name: &str) -> Self {
        match name {
            "Quote" => AssetType::Quote,
            _ => AssetType::Base,
        }
    }
}

/// UTXO in the `start_quotes` request.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SwapUtxo {
    pub txid: String,
    pub vout: u32,
    pub asset: String,
    pub asset_bf: String,
    pub value: u64,
    pub value_bf: String,
    /// Always sent, `null` when absent.
    pub redeem_script: Option<String>,
}

impl From<&LiquidUtxo> for SwapUtxo {
    fn from(u: &LiquidUtxo) -> Self {
        Self {
            txid: u.txid.clone(),
            vout: u.vout,
            asset: u.asset_id.clone(),
            asset_bf: u.asset_blinding_factor.clone(),
            value: u.value_sat,
            value_bf: u.value_blinding_factor.clone(),
            redeem_script: None,
        }
    }
}

/// Params of `market` / `start_quotes`.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct StartQuotes {
    pub asset_pair: AssetPair,
    pub asset_type: AssetType,
    pub amount: u64,
    pub trade_dir: TradeDir,
    pub utxos: Vec<SwapUtxo>,
    pub receive_address: String,
    pub change_address: String,
}

/// Result of `server_status`. Unknown fields are ignored.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ServerStatus {
    pub elements_fee_rate: f64,
    pub min_peg_in_amount: u64,
    pub min_peg_out_amount: u64,
    pub server_fee_percent_peg_in: f64,
    pub server_fee_percent_peg_out: f64,
}

/// One entry of the `assets` result.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SideswapAsset {
    pub asset_id: String,
    #[serde(default)]
    pub always_show: Option<bool>,
    #[serde(default)]
    pub contract: Option<Value>,
    #[serde(default)]
    pub domain: Option<String>,
    #[serde(default)]
    pub icon_url: Option<String>,
    #[serde(default)]
    pub instant_swaps: Option<bool>,
    #[serde(default)]
    pub issuance_prevout: Option<Value>,
    #[serde(default)]
    pub issuer_pubkey: Option<String>,
    #[serde(default)]
    pub market_type: Option<String>,
    pub name: String,
    #[serde(default)]
    pub payjoin: Option<bool>,
    pub precision: u8,
    pub ticker: String,
}

/// One entry of `list_markets.markets`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SideswapMarket {
    pub asset_pair: AssetPair,
    /// `Base` or `Quote`.
    pub fee_asset: String,
    /// `Stablecoin`, `Amp` or `Token`.
    #[serde(rename = "type")]
    pub market_type: String,
}

impl SideswapMarket {
    /// Base asset id.
    pub fn base_asset_id(&self) -> &str {
        &self.asset_pair.base
    }

    /// Quote asset id.
    pub fn quote_asset_id(&self) -> &str {
        &self.asset_pair.quote
    }
}

/// One chart point from `chart_sub.data`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AssetPairMarketData {
    pub close: f64,
    pub high: f64,
    pub low: f64,
    pub open: f64,
    pub time: String,
    pub volume: f64,
}

/// Result of `peg`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegOrderResponse {
    pub order_id: String,
    pub peg_addr: String,
    pub created_at: u64,
    /// `0` means no expiry.
    pub expires_at: u64,
    #[serde(default)]
    pub recv_amount: Option<u64>,
}

impl PegOrderResponse {
    /// Expiry in ms, `None` when the wire value is `0`.
    pub fn expires_at_ms(&self) -> Option<u64> {
        (self.expires_at != 0).then_some(self.expires_at)
    }
}

/// State of one peg deposit on the wire.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TxState {
    InsufficientAmount,
    Detected,
    Processing,
    Done,
    /// Any unrecognized value.
    #[serde(other)]
    Unknown,
}

/// One deposit transaction inside `peg_status.list`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegTransaction {
    pub tx_hash: String,
    pub vout: u32,
    pub status: String,
    pub amount: u64,
    #[serde(default)]
    pub payout: Option<u64>,
    #[serde(default)]
    pub payout_txid: Option<String>,
    pub created_at: u64,
    pub tx_state: TxState,
    pub tx_state_code: i64,
    #[serde(default)]
    pub detected_confs: Option<u32>,
    #[serde(default)]
    pub total_confs: Option<u32>,
}

/// Result of `peg_status`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegOrderStatus {
    pub order_id: String,
    pub peg_in: bool,
    /// Deposit address.
    pub addr: String,
    /// Payout address.
    pub addr_recv: String,
    pub created_at: u64,
    /// `0` means no expiry.
    pub expires_at: u64,
    pub list: Vec<PegTransaction>,
}

impl PegOrderStatus {
    /// Expiry in ms, `None` when the wire value is `0`.
    pub fn expires_at_ms(&self) -> Option<u64> {
        (self.expires_at != 0).then_some(self.expires_at)
    }
}

/// Result of `market` / `start_quotes`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct StartQuotesResult {
    pub quote_sub_id: u64,
    #[serde(default)]
    pub fee_asset: Option<String>,
}

/// Successful quote (`status.Success`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SideswapQuote {
    pub quote_id: u64,
    pub base_amount: u64,
    pub quote_amount: u64,
    pub server_fee: u64,
    pub fixed_fee: u64,
    pub ttl: u64,
}

/// Low balance quote (`status.LowBalance`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QuoteLowBalance {
    pub available: u64,
    pub base_amount: u64,
    pub quote_amount: u64,
    pub server_fee: u64,
    pub fixed_fee: u64,
}

/// Outcome carried by one quote emission.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum QuoteOutcome {
    Success(SideswapQuote),
    LowBalance(QuoteLowBalance),
    /// `status.Error.error_msg`, or a synthetic message.
    Error(String),
}

/// Text for a quote with an unknown status.
pub const UNKNOWN_QUOTE_RESPONSE: &str = "Unknown quote response";
/// Synthetic error when the connection is down.
pub const QUOTE_CONNECTION_ERROR: &str = "Erro de conexão. Tente novamente.";
/// Synthetic error when no quote arrives in time.
pub const QUOTE_TIMEOUT_ERROR: &str = "Tempo limite excedido. Tente novamente.";

/// One quote emission plus the identity of its subscription.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct QuoteResponse {
    pub outcome: QuoteOutcome,
    pub quote_sub_id: Option<u64>,
    pub requested_amount: Option<u64>,
    pub base_asset_id: Option<String>,
    pub quote_asset_id: Option<String>,
}

impl QuoteResponse {
    /// Parses the `params.quote` object.
    ///
    /// Returns an error when a known status has missing fields.
    pub fn from_json(quote: &Value) -> crate::Result<Self> {
        let pair = quote.get("asset_pair");
        let mut resp = QuoteResponse {
            outcome: QuoteOutcome::Error(UNKNOWN_QUOTE_RESPONSE.to_owned()),
            quote_sub_id: quote.get("quote_sub_id").and_then(Value::as_u64),
            requested_amount: quote.get("amount").and_then(Value::as_u64),
            base_asset_id: pair.and_then(|p| p.get("base")).and_then(Value::as_str).map(str::to_owned),
            quote_asset_id: pair.and_then(|p| p.get("quote")).and_then(Value::as_str).map(str::to_owned),
        };
        if let Some(status) = quote.get("status").and_then(Value::as_object) {
            if let Some(s) = status.get("Success") {
                resp.outcome = QuoteOutcome::Success(serde_json::from_value(s.clone())?);
            } else if let Some(e) = status.get("Error") {
                let msg = e
                    .get("error_msg")
                    .and_then(Value::as_str)
                    .ok_or_else(|| crate::Error::protocol("quote error without error_msg"))?;
                resp.outcome = QuoteOutcome::Error(msg.to_owned());
            } else if let Some(l) = status.get("LowBalance") {
                resp.outcome = QuoteOutcome::LowBalance(serde_json::from_value(l.clone())?);
            }
        }
        Ok(resp)
    }

    /// Synthetic error emission with the request identity.
    pub fn synthetic_error(message: &str, base: &str, quote: &str, amount: u64) -> Self {
        Self {
            outcome: QuoteOutcome::Error(message.to_owned()),
            quote_sub_id: None,
            requested_amount: Some(amount),
            base_asset_id: Some(base.to_owned()),
            quote_asset_id: Some(quote.to_owned()),
        }
    }

    /// The quote on success.
    pub fn quote(&self) -> Option<&SideswapQuote> {
        match &self.outcome {
            QuoteOutcome::Success(q) => Some(q),
            _ => None,
        }
    }

    /// The error message, if any.
    pub fn error_message(&self) -> Option<&str> {
        match &self.outcome {
            QuoteOutcome::Error(m) => Some(m),
            _ => None,
        }
    }

    /// True on success.
    pub fn is_success(&self) -> bool {
        matches!(self.outcome, QuoteOutcome::Success(_))
    }

    /// True on error.
    pub fn is_error(&self) -> bool {
        matches!(self.outcome, QuoteOutcome::Error(_))
    }

    /// True on low balance.
    pub fn is_low_balance(&self) -> bool {
        matches!(self.outcome, QuoteOutcome::LowBalance(_))
    }

    /// Strict identity match. Missing identity fields never match.
    pub fn matches_request(&self, base_asset_id: &str, quote_asset_id: &str, requested_amount: u64) -> bool {
        self.base_asset_id.as_deref() == Some(base_asset_id)
            && self.quote_asset_id.as_deref() == Some(quote_asset_id)
            && self.requested_amount == Some(requested_amount)
    }

    /// Permissive match used by the swap controller: the pair in either order
    /// and the same amount.
    pub fn matches_intent(&self, send_asset: &str, receive_asset: &str, amount: u64) -> bool {
        let (Some(b), Some(q)) = (self.base_asset_id.as_deref(), self.quote_asset_id.as_deref()) else {
            return false;
        };
        let pair = (b == send_asset && q == receive_asset) || (b == receive_asset && q == send_asset);
        pair && self.requested_amount == Some(amount)
    }

    /// True when the emission's base differs from `send_asset` (inverse market).
    pub fn is_inverse_for(&self, send_asset: &str) -> bool {
        self.base_asset_id.as_deref() != Some(send_asset)
    }
}

/// True if a quote error message is a transient transport error.
pub fn is_transient_quote_error(message: &str) -> bool {
    let lower = message.to_lowercase();
    [
        "tempo limite",
        "timeout",
        "timed out",
        "tiempo límite",
        "tiempo agotado",
        "erro de conexão",
        "connection error",
        "disconnected",
    ]
    .iter()
    .any(|n| lower.contains(n))
}

/// Server push or uncorrelated frame, decoded.
#[derive(Debug, Clone, PartialEq)]
pub enum Notification {
    /// `market` frame with `params.quote`. Also synthesized from stray RPC errors.
    Quote(QuoteResponse),
    /// `subscribed_value` with `PegInWalletBalance.available`.
    PegInWalletBalance(u64),
    /// `subscribed_value` with `PegOutWalletBalance.available`.
    PegOutWalletBalance(u64),
    /// Uncorrelated `peg_status` result.
    PegStatus(PegOrderStatus),
    /// Uncorrelated `peg` result.
    PegOrder(PegOrderResponse),
    /// Uncorrelated `server_status` result.
    ServerStatus(ServerStatus),
    /// Any other frame, kept raw.
    Other(Value),
}

impl Notification {
    /// Decodes an uncorrelated frame by method.
    pub fn from_frame(frame: &Value) -> Option<Self> {
        if let Some(err) = frame.get("error") {
            // NOTE: every JSON-RPC error frame becomes a quote error on the market stream.
            // Consumers drop it by identity.
            let msg = describe_rpc_error(err);
            return Some(Notification::Quote(QuoteResponse {
                outcome: QuoteOutcome::Error(msg),
                quote_sub_id: None,
                requested_amount: None,
                base_asset_id: None,
                quote_asset_id: None,
            }));
        }
        let method = frame.get("method").and_then(Value::as_str);
        let params = frame.get("params");
        let result = frame.get("result");
        match method {
            Some(method::MARKET) => {
                if let Some(q) = params.and_then(|p| p.get("quote")) {
                    // Parse failures are dropped.
                    return QuoteResponse::from_json(q).ok().map(Notification::Quote);
                }
            }
            Some(method::SUBSCRIBED_VALUE) => {
                if let Some(v) = params.and_then(|p| p.get("value")) {
                    if let Some(a) = v.get(PEG_IN_WALLET_BALANCE).and_then(|b| b.get("available")) {
                        return a.as_u64().map(Notification::PegInWalletBalance);
                    }
                    if let Some(a) = v.get(PEG_OUT_WALLET_BALANCE).and_then(|b| b.get("available")) {
                        return a.as_u64().map(Notification::PegOutWalletBalance);
                    }
                }
            }
            Some(method::PEG_STATUS) => {
                if let Some(Ok(v)) = result.map(|r| serde_json::from_value(r.clone())) {
                    return Some(Notification::PegStatus(v));
                }
            }
            Some(method::PEG) => {
                if let Some(Ok(v)) = result.map(|r| serde_json::from_value(r.clone())) {
                    return Some(Notification::PegOrder(v));
                }
            }
            Some(method::SERVER_STATUS) => {
                if let Some(Ok(v)) = result.map(|r| serde_json::from_value(r.clone())) {
                    return Some(Notification::ServerStatus(v));
                }
            }
            _ => {}
        }
        Some(Notification::Other(frame.clone()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ids_increment_from_one() {
        let mut g = RequestIdGen::default();
        assert_eq!((g.allocate(), g.allocate(), g.allocate()), (1, 2, 3));
    }

    #[test]
    fn encodes_frames_exactly() {
        let f: Value = serde_json::from_str(&Request::peg(false, "bc1q").encode(7)).unwrap();
        assert_eq!(f, json!({"id":7,"method":"peg","params":{"peg_in":false,"recv_addr":"bc1q"}}));
        let f: Value = serde_json::from_str(&Request::server_status().encode(1)).unwrap();
        assert_eq!(f, json!({"id":1,"method":"server_status","params":null}));
        let f: Value = serde_json::from_str(&Request::login("k").encode(2)).unwrap();
        assert_eq!(f["params"], json!({"api_key":"k","user_agent":"MoozeClient","version":"1.0.0"}));
        assert_eq!(Request::taker_sign(5, "cHNl").params, json!({"taker_sign":{"quote_id":5,"pset":"cHNl"}}));
        assert_eq!(Request::stop_quotes().params, json!({"stop_quotes":{}}));
        assert_eq!(Request::list_markets().params, json!({"list_markets":{}}));
        assert_eq!(
            Request::subscribe_value(PEG_IN_WALLET_BALANCE).params,
            json!({"value":"PegInWalletBalance"})
        );
    }

    #[test]
    fn encodes_start_quotes() {
        let utxo = LiquidUtxo {
            txid: "aa".into(),
            vout: 1,
            asset_id: "lbtc".into(),
            asset_blinding_factor: "abf".into(),
            value_sat: 5000,
            value_blinding_factor: "vbf".into(),
        };
        let req = StartQuotes {
            asset_pair: AssetPair { base: "lbtc".into(), quote: "usdt".into() },
            asset_type: AssetType::Base,
            amount: 5000,
            trade_dir: TradeDir::Sell,
            utxos: vec![SwapUtxo::from(&utxo)],
            receive_address: "lq1r".into(),
            change_address: "lq1c".into(),
        };
        assert_eq!(
            Request::start_quotes(&req).params,
            json!({"start_quotes":{
                "asset_pair":{"base":"lbtc","quote":"usdt"},
                "asset_type":"Base","amount":5000,"trade_dir":"Sell",
                "utxos":[{"txid":"aa","vout":1,"asset":"lbtc","asset_bf":"abf","value":5000,"value_bf":"vbf","redeem_script":null}],
                "receive_address":"lq1r","change_address":"lq1c"}})
        );
        assert_eq!(AssetType::normalize("weird"), AssetType::Base);
        assert_eq!(AssetType::normalize("Quote"), AssetType::Quote);
    }

    #[test]
    fn parses_live_server_status() {
        let live = json!({
            "bitcoin_fee_rates": [{"blocks": 2, "value": 2.0}],
            "elements_fee_rate": 0.1,
            "min_peg_in_amount": 10000,
            "min_peg_out_amount": 25000,
            "min_submit_amount": 2000,
            "peg_out_bitcoin_tx_vsize": 141,
            "policy_asset": "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d",
            "price_band": 0.101,
            "server_fee_percent_peg_in": 0.1,
            "server_fee_percent_peg_out": 0.1,
            "upload_url": "https://api.sideswap.io/json-rpc"
        });
        let s: ServerStatus = serde_json::from_value(live).unwrap();
        assert_eq!((s.min_peg_in_amount, s.min_peg_out_amount), (10000, 25000));
        assert_eq!(s.server_fee_percent_peg_out, 0.1);
    }

    #[test]
    fn parses_live_peg_payloads() {
        let r: PegOrderResponse = serde_json::from_value(json!({
            "created_at": 1786210602834u64, "expires_at": 0,
            "order_id": "9f7c16e57a867249dd4db88ff2cf161014bd487ba2cc3d4d5ff000fa8eb0d394",
            "peg_addr": "bc1qmvl2pjc7q0rgv0hm0gadhfzn66hqxh8ft9p8g3quvhca6wysfj2svjwyxq",
            "recv_amount": null
        }))
        .unwrap();
        assert!(r.peg_addr.starts_with("bc1"));
        assert_eq!(r.order_id.len(), 64);
        assert_eq!(r.expires_at_ms(), None);

        let s: PegOrderStatus = serde_json::from_value(json!({
            "addr": "bc1qmvl2pjc7q0rgv0hm0gadhfzn66hqxh8ft9p8g3quvhca6wysfj2svjwyxq",
            "addr_recv": "lq1qqvxk052kf3qtkxmrakx50a9gc3smqad2ync54hzntjt980kfej9",
            "created_at": 1786210602834u64, "expires_at": 0, "fee_rate": null,
            "list": [], "order_id": "9f7c16e5", "peg_in": true, "return_address": null
        }))
        .unwrap();
        assert!(s.peg_in && s.list.is_empty());

        let tx: PegTransaction = serde_json::from_value(json!({
            "tx_hash": "ab", "vout": 0, "status": "Detected", "amount": 100000,
            "payout": null, "payout_txid": null, "created_at": 1, "tx_state": "SomethingNew",
            "tx_state_code": 3, "detected_confs": 1, "total_confs": 2
        }))
        .unwrap();
        assert_eq!(tx.tx_state, TxState::Unknown);
        assert_eq!(tx.total_confs, Some(2));
    }

    #[test]
    fn parses_quote_variants() {
        let ok = json!({"quote_sub_id": 9, "amount": 1000, "asset_pair": {"base":"B","quote":"Q"},
            "status": {"Success": {"quote_id": 7, "base_amount": 1000, "quote_amount": 600,
            "server_fee": 2, "fixed_fee": 30, "ttl": 30000}}});
        let r = QuoteResponse::from_json(&ok).unwrap();
        assert_eq!(r.quote().unwrap().quote_id, 7);
        assert!(r.matches_request("B", "Q", 1000));
        assert!(!r.matches_request("Q", "B", 1000));
        assert!(r.matches_intent("Q", "B", 1000));
        assert!(r.is_inverse_for("Q"));

        let low = json!({"status": {"LowBalance": {"available": 5, "base_amount": 1, "quote_amount": 2,
            "server_fee": 3, "fixed_fee": 4}}});
        assert!(QuoteResponse::from_json(&low).unwrap().is_low_balance());

        let err = json!({"status": {"Error": {"error_msg": "no liquidity"}}});
        assert_eq!(QuoteResponse::from_json(&err).unwrap().error_message(), Some("no liquidity"));

        let unknown = json!({"status": {"Weird": {}}});
        assert_eq!(QuoteResponse::from_json(&unknown).unwrap().error_message(), Some(UNKNOWN_QUOTE_RESPONSE));
        // Missing identity never matches.
        assert!(!QuoteResponse::from_json(&unknown).unwrap().matches_intent("B", "Q", 1));
        // Broken success payload is an error.
        assert!(QuoteResponse::from_json(&json!({"status":{"Success":{"quote_id":1}}})).is_err());
    }

    #[test]
    fn decodes_notifications() {
        let n = Notification::from_frame(&json!({"method":"subscribed_value",
            "params":{"value":{"PegOutWalletBalance":{"available": 42}}}}));
        assert_eq!(n, Some(Notification::PegOutWalletBalance(42)));
        let n = Notification::from_frame(&json!({"id": 3, "error": {"code": -1, "message": "boom"}}));
        match n {
            Some(Notification::Quote(q)) => assert_eq!(q.error_message(), Some("boom")),
            other => panic!("{other:?}"),
        }
        assert_eq!(describe_rpc_error(&json!({"error": "x"})), "x");
        assert_eq!(describe_rpc_error(&json!({})), UNKNOWN_ERROR);
        assert_eq!(describe_rpc_error(&json!("plain")), "plain");
    }

    #[test]
    fn transient_errors() {
        assert!(is_transient_quote_error(QUOTE_TIMEOUT_ERROR));
        assert!(is_transient_quote_error(QUOTE_CONNECTION_ERROR));
        assert!(!is_transient_quote_error("no liquidity"));
    }
}
