//! Asset swap flow: markets, quotes, accept, sign, submit.

use std::future::Future;

use super::client::SideSwapClient;
use super::protocol::{
    AssetPair, AssetType, Notification, QuoteResponse, SideswapAsset, SideswapMarket, StartQuotes, StartQuotesResult,
    SwapUtxo, TradeDir, QUOTE_TIMEOUT_ERROR,
};
use crate::domain::LiquidUtxo;
use crate::ports::{MaybeSend, MaybeSync, WsConnector};
use crate::{Error, Result};

/// Wallet operations a swap needs. The wallet module implements it.
pub trait SwapSigner: MaybeSend + MaybeSync {
    /// Spendable, unblinded Liquid UTXOs of the wallet.
    fn liquid_utxos(&self) -> impl Future<Output = Result<Vec<LiquidUtxo>>> + MaybeSend;

    /// Fresh Liquid address for swap proceeds (also used as change).
    fn swap_address(&self) -> impl Future<Output = Result<String>> + MaybeSend;

    /// Signs the SideSwap PSET (base64) and returns the signed PSET (base64).
    /// The implementation holds the Liquid spend lock while signing.
    fn sign_swap_pset(&self, pset_b64: &str) -> impl Future<Output = Result<String>> + MaybeSend;

    /// Native hosts recheck session authority inside the wallet signing lock.
    fn sign_swap_pset_authorized(
        &self,
        pset_b64: &str,
        authorize: &(dyn Fn() -> Result<()> + Send + Sync),
    ) -> impl Future<Output = Result<String>> + MaybeSend {
        async move {
            authorize()?;
            self.sign_swap_pset(pset_b64).await
        }
    }
}

/// A swap mapped onto a SideSwap market.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NormalizedSwap {
    pub base_asset: String,
    pub quote_asset: String,
    pub direction: TradeDir,
    pub asset_type: AssetType,
}

impl NormalizedSwap {
    /// Asset whose UTXOs fund the swap.
    pub fn utxo_asset(&self) -> &str {
        match self.asset_type {
            AssetType::Base => &self.base_asset,
            AssetType::Quote => &self.quote_asset,
        }
    }
}

/// Maps `send -> receive` onto a market. Direct market: sell base.
/// Inverse market: sell with `asset_type = Quote`.
pub fn normalize_swap_params(markets: &[SideswapMarket], send: &str, receive: &str) -> Option<NormalizedSwap> {
    if markets.iter().any(|m| m.base_asset_id() == send && m.quote_asset_id() == receive) {
        return Some(NormalizedSwap {
            base_asset: send.to_owned(),
            quote_asset: receive.to_owned(),
            direction: TradeDir::Sell,
            asset_type: AssetType::Base,
        });
    }
    if markets.iter().any(|m| m.base_asset_id() == receive && m.quote_asset_id() == send) {
        return Some(NormalizedSwap {
            base_asset: receive.to_owned(),
            quote_asset: send.to_owned(),
            direction: TradeDir::Sell,
            asset_type: AssetType::Quote,
        });
    }
    None
}

/// Picks UTXOs of `asset_id`, smallest first, until `amount` is covered.
pub fn select_utxos(utxos: &[LiquidUtxo], asset_id: &str, amount: u64) -> Result<Vec<SwapUtxo>> {
    if amount == 0 {
        return Ok(Vec::new());
    }
    let mut filtered: Vec<&LiquidUtxo> = utxos.iter().filter(|u| u.asset_id == asset_id).collect();
    filtered.sort_by_key(|u| u.value_sat);
    let mut selected = Vec::new();
    let mut remaining = amount as i128;
    for u in filtered {
        selected.push(SwapUtxo::from(u));
        remaining -= u.value_sat as i128;
        if remaining <= 0 {
            remaining = 0;
            break;
        }
    }
    if remaining > 0 {
        return Err(Error::invalid(format!("Insufficient funds: missing {remaining} sats for {asset_id}")));
    }
    Ok(selected)
}

/// Time after which a stuck quote lock is force-released.
pub const QUOTE_STALE_RESET_MS: u64 = 15_000;
/// Time after which a quote request counts as timed out.
pub const QUOTE_RESPONSE_TIMEOUT_MS: u64 = 8_000;

/// One-quote-at-a-time lock of `SideswapService`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct QuoteGate {
    in_progress: bool,
    last_quote_ms: Option<u64>,
}

impl QuoteGate {
    /// True while a quote request waits for its first response.
    pub fn in_progress(&self) -> bool {
        self.in_progress
    }

    /// Takes the lock. A lock older than 15 s (whole seconds) is reset first.
    /// Returns false when another quote is still in progress.
    pub fn try_begin(&mut self, now_ms: u64) -> bool {
        if let (true, Some(last)) = (self.in_progress, self.last_quote_ms) {
            // Compares whole seconds: reset when more than 15 s elapsed.
            if now_ms.saturating_sub(last) / 1000 > QUOTE_STALE_RESET_MS / 1000 {
                self.reset();
            }
        }
        if self.in_progress {
            return false;
        }
        self.in_progress = true;
        self.last_quote_ms = Some(now_ms);
        true
    }

    /// Any quote emission releases the lock.
    pub fn on_response(&mut self) {
        self.in_progress = false;
    }

    /// Releases the lock and forgets the timestamp.
    pub fn reset(&mut self) {
        self.in_progress = false;
        self.last_quote_ms = None;
    }

    /// True once if the lock is still held 8 s after the request. Releases it.
    pub fn check_timeout(&mut self, now_ms: u64) -> bool {
        match (self.in_progress, self.last_quote_ms) {
            (true, Some(last)) if now_ms.saturating_sub(last) >= QUOTE_RESPONSE_TIMEOUT_MS => {
                self.in_progress = false;
                true
            }
            _ => false,
        }
    }
}

/// The user's intent for the active quote subscription.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct QuoteIntent {
    pub send_asset: String,
    pub receive_asset: String,
    pub amount: u64,
    pub params: NormalizedSwap,
    pub quote_sub_id: Option<u64>,
}

/// Result of [`SwapService::start_quote`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StartQuoteOutcome {
    /// `start_quotes` was sent. Quotes follow as emissions.
    Started(QuoteIntent),
    /// Another quote holds the lock. Nothing was sent.
    AlreadyInProgress,
}

/// Swap orchestration over a [`SideSwapClient`] and a [`SwapSigner`].
pub struct SwapService<C: WsConnector, S: SwapSigner> {
    client: SideSwapClient<C>,
    signer: S,
    markets: Vec<SideswapMarket>,
    gate: QuoteGate,
    active: Option<QuoteIntent>,
}

impl<C: WsConnector, S: SwapSigner> SwapService<C, S> {
    /// New service. Markets load on first use.
    pub fn new(client: SideSwapClient<C>, signer: S) -> Self {
        Self { client, signer, markets: Vec::new(), gate: QuoteGate::default(), active: None }
    }

    /// The underlying client.
    pub fn client_mut(&mut self) -> &mut SideSwapClient<C> {
        &mut self.client
    }

    /// The active quote intent.
    pub fn active(&self) -> Option<&QuoteIntent> {
        self.active.as_ref()
    }

    /// Cached markets.
    pub fn cached_markets(&self) -> &[SideswapMarket] {
        &self.markets
    }

    /// Asset list.
    pub async fn get_assets(&mut self) -> Result<Vec<SideswapAsset>> {
        self.client.assets(true, false).await
    }

    /// Market list. Refreshes the cache.
    pub async fn get_markets(&mut self) -> Result<Vec<SideswapMarket>> {
        self.markets = self.client.list_markets().await?;
        Ok(self.markets.clone())
    }

    /// Normalizes against the cached markets.
    pub fn normalize(&self, send: &str, receive: &str) -> Option<NormalizedSwap> {
        normalize_swap_params(&self.markets, send, receive)
    }

    /// Opens a quote subscription for `amount` of `send_asset`.
    ///
    /// Follows the controller: stop the old subscription, normalize (reload
    /// markets once on a miss), take an address and UTXOs, then
    /// `start_quotes`. The receive address doubles as the change address.
    pub async fn start_quote(
        &mut self,
        send_asset: &str,
        receive_asset: &str,
        amount: u64,
        now_ms: u64,
    ) -> Result<StartQuoteOutcome> {
        self.stop_quote().await;

        let params = match self.normalize(send_asset, receive_asset) {
            Some(p) => p,
            None => {
                self.get_markets().await?;
                self.normalize(send_asset, receive_asset)
                    .ok_or_else(|| Error::invalid(format!("no market for {send_asset} -> {receive_asset}")))?
            }
        };
        if params.utxo_asset() != send_asset {
            return Err(Error::InvalidState(format!(
                "Internal normalization mismatch (utxo={}, send={send_asset})",
                params.utxo_asset()
            )));
        }

        let receive_address = self.signer.swap_address().await?;
        let all_utxos = self.signer.liquid_utxos().await?;
        let utxos = select_utxos(&all_utxos, send_asset, amount)?;

        if !self.gate.try_begin(now_ms) {
            return Ok(StartQuoteOutcome::AlreadyInProgress);
        }
        let req = StartQuotes {
            asset_pair: AssetPair { base: params.base_asset.clone(), quote: params.quote_asset.clone() },
            asset_type: params.asset_type,
            amount,
            trade_dir: params.direction,
            utxos,
            change_address: receive_address.clone(),
            receive_address,
        };
        // NOTE: when the socket is down, the transport error is returned. No synthetic quote is emitted.
        let result: StartQuotesResult = match self.client.start_quotes(&req).await {
            Ok(r) => r,
            Err(e) => {
                self.gate.reset();
                return Err(e);
            }
        };
        let intent = QuoteIntent {
            send_asset: send_asset.to_owned(),
            receive_asset: receive_asset.to_owned(),
            amount,
            params,
            quote_sub_id: Some(result.quote_sub_id),
        };
        self.active = Some(intent.clone());
        Ok(StartQuoteOutcome::Started(intent))
    }

    fn take_matching(&mut self, n: Notification) -> Option<QuoteResponse> {
        let Notification::Quote(q) = n else { return None };
        self.gate.on_response();
        let intent = self.active.as_ref()?;
        q.matches_intent(&intent.send_asset, &intent.receive_asset, intent.amount).then_some(q)
    }

    /// Quote emissions for the active intent that are already buffered.
    /// Non-quote notifications are dropped.
    pub fn drain_quotes(&mut self) -> Vec<QuoteResponse> {
        self.client.drain_notifications().into_iter().filter_map(|n| self.take_matching(n)).collect()
    }

    /// Waits for the next emission matching the active intent.
    pub async fn next_quote(&mut self) -> Result<QuoteResponse> {
        if self.active.is_none() {
            return Err(Error::InvalidState("no active quote".into()));
        }
        loop {
            let n = self.client.next_event().await?;
            if let Some(q) = self.take_matching(n) {
                return Ok(q);
            }
        }
    }

    /// Synthetic timeout emission when no quote arrived within 8 s.
    pub fn poll_quote_timeout(&mut self, now_ms: u64) -> Option<QuoteResponse> {
        if !self.gate.check_timeout(now_ms) {
            return None;
        }
        let intent = self.active.as_ref()?;
        Some(QuoteResponse::synthetic_error(
            QUOTE_TIMEOUT_ERROR,
            &intent.params.base_asset,
            &intent.params.quote_asset,
            intent.amount,
        ))
    }

    /// Releases the quote lock (error recovery).
    pub fn reset_quote_progress(&mut self) {
        self.gate.reset();
    }

    /// Stops the quote subscription. Best-effort: errors are ignored.
    pub async fn stop_quote(&mut self) {
        self.gate.reset();
        let had_active = self.active.take().is_some();
        if had_active || self.client.is_connected() {
            let _ = self.client.stop_quotes().await;
        }
    }

    /// Fetches the PSET of an accepted quote.
    pub async fn get_quote_pset(&mut self, quote_id: u64) -> Result<String> {
        self.client.get_quote_pset(quote_id).await
    }

    /// Signs `pset` and submits it with `taker_sign`. Returns the txid.
    pub async fn sign_and_broadcast(&mut self, quote_id: u64, pset: &str) -> Result<String> {
        let signed = self.signer.sign_swap_pset(pset).await?;
        self.client.taker_sign(quote_id, &signed).await
    }

    /// Confirms a quote: stop quotes, get the PSET, sign, submit.
    /// The platform enforces the 60 s cap.
    pub async fn execute_swap(&mut self, quote_id: u64) -> Result<String> {
        self.stop_quote().await;
        let pset = self.get_quote_pset(quote_id).await?;
        self.sign_and_broadcast(quote_id, &pset).await
    }

    /// Native confirmation: revocation is checked after preparation and before submission.
    /// Submission errors are ambiguous once signed material has been sent.
    pub async fn execute_swap_authorized(
        &mut self,
        quote_id: u64,
        authorize: &(dyn Fn() -> Result<()> + Send + Sync),
    ) -> Result<String> {
        authorize()?;
        self.stop_quote().await;
        let pset = self.get_quote_pset(quote_id).await?;
        let signed = self.signer.sign_swap_pset_authorized(&pset, authorize).await?;
        authorize()?;
        self.client
            .taker_sign(quote_id, &signed)
            .await
            .map_err(|e| Error::SubmissionUnknown { chain: crate::domain::ChainId::Liquid, message: e.to_string() })
    }

    /// Forces a reconnect and resets the quote lock.
    pub async fn force_reconnect(&mut self) -> Result<()> {
        self.gate.reset();
        self.client.force_reconnect().await
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use std::future::ready;
    use std::sync::{Arc, Mutex};

    use serde_json::{json, Value};

    use super::*;
    use crate::testing::{block_on, MockWs};

    const LBTC: &str = "lbtc";
    const USDT: &str = "usdt";

    fn utxo(asset: &str, v: u64, txid: &str) -> LiquidUtxo {
        LiquidUtxo {
            txid: txid.into(),
            vout: 0,
            asset_id: asset.into(),
            asset_blinding_factor: "abf".into(),
            value_sat: v,
            value_blinding_factor: "vbf".into(),
        }
    }

    fn market(base: &str, quote: &str) -> SideswapMarket {
        SideswapMarket {
            asset_pair: AssetPair { base: base.into(), quote: quote.into() },
            fee_asset: "Quote".into(),
            market_type: "Stablecoin".into(),
        }
    }

    #[test]
    fn normalizes_direct_and_inverse() {
        let m = vec![market(LBTC, USDT)];
        let d = normalize_swap_params(&m, LBTC, USDT).unwrap();
        assert_eq!((d.asset_type, d.direction, d.utxo_asset()), (AssetType::Base, TradeDir::Sell, LBTC));
        let i = normalize_swap_params(&m, USDT, LBTC).unwrap();
        assert_eq!((i.base_asset.as_str(), i.asset_type, i.utxo_asset()), (LBTC, AssetType::Quote, USDT));
        assert!(normalize_swap_params(&m, "x", USDT).is_none());
    }

    #[test]
    fn selects_smallest_first() {
        let u = vec![utxo(LBTC, 500, "a"), utxo(USDT, 9999, "u"), utxo(LBTC, 100, "b"), utxo(LBTC, 300, "c")];
        let s = select_utxos(&u, LBTC, 350).unwrap();
        assert_eq!(s.iter().map(|x| x.txid.as_str()).collect::<Vec<_>>(), vec!["b", "c"]);
        assert!(select_utxos(&u, LBTC, 0).unwrap().is_empty());
        let e = select_utxos(&u, LBTC, 1000).unwrap_err();
        assert_eq!(e, Error::InvalidInput("Insufficient funds: missing 100 sats for lbtc".into()));
    }

    #[test]
    fn gate_locks_resets_and_times_out() {
        let mut g = QuoteGate::default();
        assert!(g.try_begin(0));
        assert!(!g.try_begin(15_999));
        assert!(g.try_begin(16_000)); // stale lock reset
        assert!(!g.check_timeout(16_000 + 7_999));
        assert!(g.check_timeout(16_000 + 8_000));
        assert!(!g.check_timeout(16_000 + 9_000));
        assert!(g.try_begin(30_000));
        g.on_response();
        assert!(!g.in_progress());
    }

    struct FakeSigner {
        signed: Arc<Mutex<Vec<String>>>,
    }

    impl SwapSigner for FakeSigner {
        fn liquid_utxos(&self) -> impl Future<Output = Result<Vec<LiquidUtxo>>> + MaybeSend {
            ready(Ok(vec![utxo(LBTC, 50_000, "f")]))
        }
        fn swap_address(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            ready(Ok("lq1swap".to_owned()))
        }
        fn sign_swap_pset(&self, pset_b64: &str) -> impl Future<Output = Result<String>> + MaybeSend {
            self.signed.lock().unwrap().push(pset_b64.to_owned());
            ready(Ok(format!("signed:{pset_b64}")))
        }
    }

    fn server(frame: &str) -> Vec<String> {
        let v: Value = serde_json::from_str(frame).unwrap();
        let id = v["id"].clone();
        let m = v["method"].as_str().unwrap();
        let p = &v["params"];
        let reply = |r: Value| json!({"id": id, "method": m, "result": r}).to_string();
        if m == "login_client" {
            return vec![reply(json!({}))];
        }
        if p.get("list_markets").is_some() {
            return vec![reply(json!({"list_markets": {"markets": [
                {"asset_pair": {"base": LBTC, "quote": USDT}, "fee_asset": "Quote", "type": "Stablecoin"}]}}))];
        }
        if let Some(sq) = p.get("start_quotes") {
            let amount = sq["amount"].clone();
            let quote = |a: Value, base: &str, id: u64| {
                json!({"method": "market", "params": {"quote": {"quote_sub_id": 3, "amount": a,
                "asset_pair": {"base": base, "quote": USDT}, "status": {"Success": {"quote_id": id,
                "base_amount": 20000, "quote_amount": 1200000, "server_fee": 20, "fixed_fee": 30, "ttl": 30000}}}}})
                .to_string()
            };
            return vec![
                quote(json!(1), LBTC, 1), // stale: other amount
                quote(amount, LBTC, 2),
                reply(json!({"start_quotes": {"quote_sub_id": 3, "fee_asset": "Quote"}})),
            ];
        }
        if p.get("stop_quotes").is_some() {
            return vec![reply(json!({"stop_quotes": {}}))];
        }
        if p.get("get_quote").is_some() {
            return vec![reply(json!({"get_quote": {"pset": "cHNldA==", "ttl": 30000}}))];
        }
        if let Some(ts) = p.get("taker_sign") {
            assert_eq!(ts["pset"], "signed:cHNldA==");
            return vec![reply(json!({"taker_sign": {"txid": "swaptxid"}}))];
        }
        vec![]
    }

    #[test]
    fn revoked_authority_never_signs_a_swap() {
        let ws = MockWs::new(server);
        let signed = Arc::new(Mutex::new(Vec::new()));
        let mut svc = SwapService::new(SideSwapClient::new(ws, "k"), FakeSigner { signed: signed.clone() });
        block_on(svc.start_quote(LBTC, USDT, 20_000, 1000)).unwrap();
        assert!(block_on(svc.execute_swap_authorized(123, &|| Err(Error::Session("locked".into())))).is_err());
        assert!(signed.lock().unwrap().is_empty());
    }

    #[test]
    fn full_swap_flow() {
        let ws = MockWs::new(server);
        let signed = Arc::new(Mutex::new(Vec::new()));
        let mut svc = SwapService::new(SideSwapClient::new(ws.clone(), "k"), FakeSigner { signed: signed.clone() });
        let out = block_on(svc.start_quote(LBTC, USDT, 20_000, 1_000)).unwrap();
        let StartQuoteOutcome::Started(intent) = out else { panic!("not started") };
        assert_eq!(intent.quote_sub_id, Some(3));

        let sent: Vec<Value> = ws.sent().iter().map(|f| serde_json::from_str(f).unwrap()).collect();
        let sq = sent.iter().find(|f| f["params"].get("start_quotes").is_some()).unwrap();
        assert_eq!(sq["params"]["start_quotes"]["change_address"], "lq1swap");
        assert_eq!(sq["params"]["start_quotes"]["utxos"][0]["txid"], "f");

        // Stale amount is filtered out; the matching quote remains.
        let quotes = svc.drain_quotes();
        assert_eq!(quotes.len(), 1);
        let qid = quotes[0].quote().unwrap().quote_id;
        assert_eq!(qid, 2);
        assert!(svc.poll_quote_timeout(100_000).is_none(), "response released the lock");

        let txid = block_on(svc.execute_swap(qid)).unwrap();
        assert_eq!(txid, "swaptxid");
        assert_eq!(signed.lock().unwrap().as_slice(), ["cHNldA=="]);
        assert!(svc.active().is_none());
    }

    #[test]
    fn quote_timeout_emits_synthetic_error() {
        // Server never pushes quotes.
        let ws = MockWs::new(|f| {
            let v: Value = serde_json::from_str(f).unwrap();
            let p = &v["params"];
            if p.get("start_quotes").is_some() {
                return vec![json!({"id": v["id"], "method": "market",
                    "result": {"start_quotes": {"quote_sub_id": 1}}})
                .to_string()];
            }
            server(f)
        });
        let signed = Arc::new(Mutex::new(Vec::new()));
        let mut svc = SwapService::new(SideSwapClient::new(ws, "k"), FakeSigner { signed });
        block_on(svc.start_quote(USDT, LBTC, 1_000, 0)).unwrap_err(); // no USDT utxos
        let out = block_on(svc.start_quote(LBTC, USDT, 1_000, 0)).unwrap();
        assert!(matches!(out, StartQuoteOutcome::Started(_)));
        assert!(svc.drain_quotes().is_empty());
        let t = svc.poll_quote_timeout(8_000).unwrap();
        assert_eq!(t.error_message(), Some(QUOTE_TIMEOUT_ERROR));
        assert!(t.matches_intent(LBTC, USDT, 1_000));
    }
}
