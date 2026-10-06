//! Binance public market data.

use std::collections::HashMap;
use std::future::Future;
use std::sync::{Arc, Mutex};

use serde_json::Value;

use super::{pegged_price, Currency, KlineInterval, PriceService};
use crate::domain::Asset;
use crate::format::parse_double;
use crate::ports::{Clock, HttpClient, HttpRequest, MaybeSend};
use crate::{Error, Result};

/// Base URL of the Binance data API.
pub const BINANCE_API_URL: &str = "https://data-api.binance.vision/api/v3/";
/// Symbols the app queries in one `ticker/24hr` call.
pub const BINANCE_SYMBOLS: &str = "[\"BTCBRL\",\"BTCUSDT\",\"USDTBRL\"]";
/// Lifetime of the in-memory ticker and klines cache.
pub const BINANCE_CACHE_TTL_MS: u64 = 60_000;

const TICKER_URL: &str =
    "https://data-api.binance.vision/api/v3/ticker/24hr?symbols=%5B%22BTCBRL%22%2C%22BTCUSDT%22%2C%22USDTBRL%22%5D";
const UNSUPPORTED: &str = "Unsupported asset/currency combination";

type Klines = Vec<Vec<Value>>;

/// HTTP client plus the shared 60 s cache.
/// Share one instance (in an `Arc`) between the price and the variation services.
#[derive(Debug)]
pub struct BinanceClient<H, C> {
    http: H,
    clock: C,
    tickers: Mutex<Option<(u64, Vec<Value>)>>,
    klines: Mutex<HashMap<String, (u64, Klines)>>,
}

impl<H: HttpClient, C: Clock> BinanceClient<H, C> {
    /// Client with an empty cache.
    pub fn new(http: H, clock: C) -> Self {
        Self { http, clock, tickers: Mutex::new(None), klines: Mutex::new(HashMap::new()) }
    }

    fn fresh(&self, fetched_at: u64) -> bool {
        self.clock.now_ms().saturating_sub(fetched_at) <= BINANCE_CACHE_TTL_MS
    }

    async fn get_json(&self, url: String, what: &str) -> Result<Value> {
        let resp = self.http.send(HttpRequest::get(url)).await?;
        if resp.status != 200 {
            return Err(Error::Http {
                status: resp.status,
                body: format!("Failed to query Binance {what}: {}", resp.status),
            });
        }
        Ok(serde_json::from_slice(&resp.body)?)
    }

    /// 24 h tickers for [`BINANCE_SYMBOLS`], cached for [`BINANCE_CACHE_TTL_MS`].
    pub async fn tickers(&self) -> Result<Vec<Value>> {
        if let Some((at, data)) = self.tickers.lock().expect("poisoned").clone() {
            if self.fresh(at) {
                return Ok(data);
            }
        }
        let data = match self.get_json(TICKER_URL.to_owned(), "API").await? {
            Value::Array(items) if items.iter().all(Value::is_object) => items,
            other => return Err(Error::protocol(format!("binance tickers: expected list of objects, got {other}"))),
        };
        *self.tickers.lock().expect("poisoned") = Some((self.clock.now_ms(), data.clone()));
        Ok(data)
    }

    /// Klines for one symbol, cached per `(symbol, interval, start, end)` key.
    pub async fn klines(&self, symbol: &str, interval: &str, start_ms: i64, end_ms: i64) -> Result<Klines> {
        let key = format!("{symbol}_{interval}_{start_ms}_{end_ms}");
        if let Some((at, data)) = self.klines.lock().expect("poisoned").get(&key).cloned() {
            if self.fresh(at) {
                return Ok(data);
            }
        }
        let url = format!(
            "{BINANCE_API_URL}klines?symbol={symbol}&interval={interval}&startTime={start_ms}&endTime={end_ms}"
        );
        let data: Klines = serde_json::from_value(self.get_json(url, "Klines API").await?)?;
        self.klines.lock().expect("poisoned").insert(key, (self.clock.now_ms(), data.clone()));
        Ok(data)
    }

    async fn ticker_field(&self, symbol: &str, field: &str) -> Result<Option<f64>> {
        let tickers = self.tickers().await?;
        Ok(tickers
            .iter()
            .find(|t| t.get("symbol").and_then(Value::as_str) == Some(symbol))
            .and_then(|t| t.get(field))
            .and_then(Value::as_str)
            .and_then(parse_double))
    }

    /// `bidPrice` of `symbol`. `None` if the symbol or the field is missing.
    pub async fn bid_price(&self, symbol: &str) -> Result<Option<f64>> {
        self.ticker_field(symbol, "bidPrice").await
    }

    /// `priceChangePercent` of `symbol`. Missing data gives `0.0`.
    pub async fn price_change_percent(&self, symbol: &str) -> Result<f64> {
        Ok(self.ticker_field(symbol, "priceChangePercent").await?.unwrap_or(0.0))
    }

    /// Close prices of the klines between `now - period_ms` and now.
    /// Unparsable closes get the average of the valid ones.
    async fn closes(&self, symbol: &str, interval: &str, period_ms: i64) -> Result<Vec<f64>> {
        let now = self.clock.now_ms() as i64;
        let klines = self.klines(symbol, interval, now - period_ms, now).await?;
        let close = |k: &Vec<Value>| -> Result<Option<f64>> {
            let v = k.get(4).ok_or_else(|| Error::protocol("binance kline has fewer than 5 fields"))?;
            Ok(match v {
                Value::String(s) => parse_double(s),
                other => parse_double(&other.to_string()),
            })
        };
        let parsed = klines.iter().map(close).collect::<Result<Vec<_>>>()?;
        let valid: Vec<f64> = parsed.iter().flatten().copied().collect();
        let avg = if valid.is_empty() { 0.0 } else { valid.iter().sum::<f64>() / valid.len() as f64 };
        Ok(parsed.into_iter().map(|p| p.unwrap_or(avg)).collect())
    }
}

/// Binance symbol for a price, and whether to invert it. `None` for pegged or unsupported pairs.
fn symbol_for(asset: Asset, currency: Currency, btc_includes_lbtc: bool) -> Option<(&'static str, bool)> {
    match (asset, currency) {
        (Asset::Depix, Currency::Usd) => Some(("USDTBRL", true)),
        (Asset::Btc, Currency::Brl) => Some(("BTCBRL", false)),
        (Asset::Btc, Currency::Usd) => Some(("BTCUSDT", false)),
        (Asset::Lbtc, Currency::Brl) if btc_includes_lbtc => Some(("BTCBRL", false)),
        (Asset::Lbtc, Currency::Usd) if btc_includes_lbtc => Some(("BTCUSDT", false)),
        (Asset::Usdt, Currency::Brl) => Some(("USDTBRL", false)),
        _ => None,
    }
}

/// Spot prices from Binance `bidPrice`.
#[derive(Debug)]
pub struct BinancePriceService<H, C> {
    client: Arc<BinanceClient<H, C>>,
    default_currency: Currency,
}

impl<H, C> BinancePriceService<H, C> {
    /// Service over a shared client.
    pub fn new(client: Arc<BinanceClient<H, C>>, default_currency: Currency) -> Self {
        Self { client, default_currency }
    }
}

impl<H: HttpClient, C: Clock> PriceService for BinancePriceService<H, C> {
    fn currency(&self) -> Currency {
        self.default_currency
    }

    fn get_coin_price(
        &self,
        asset: Asset,
        currency: Option<Currency>,
    ) -> impl Future<Output = Result<Option<f64>>> + MaybeSend {
        let currency = currency.unwrap_or(self.default_currency);
        async move {
            if let Some(p) = pegged_price(asset, currency) {
                return Ok(Some(p));
            }
            let Some((symbol, invert)) = symbol_for(asset, currency, true) else {
                return Err(Error::invalid(UNSUPPORTED));
            };
            let bid = self.client.bid_price(symbol).await?;
            Ok(if invert { bid.map(|f| 1.0 / f) } else { bid })
        }
    }
}

/// 24 h change and price history from Binance.
/// NOTE: only on-chain BTC is supported here, not L-BTC.
#[derive(Debug)]
pub struct BinanceDailyPriceVariationService<H, C> {
    client: Arc<BinanceClient<H, C>>,
    default_currency: Currency,
}

impl<H: HttpClient, C: Clock> BinanceDailyPriceVariationService<H, C> {
    /// Service over a shared client.
    pub fn new(client: Arc<BinanceClient<H, C>>, default_currency: Currency) -> Self {
        Self { client, default_currency }
    }

    /// 24 h price change in percent.
    pub async fn get_percentage_variation(&self, asset: Asset, currency: Option<Currency>) -> Result<f64> {
        let currency = currency.unwrap_or(self.default_currency);
        if pegged_price(asset, currency).is_some() {
            return Ok(0.0);
        }
        let (symbol, invert) = symbol_for(asset, currency, false).ok_or_else(|| Error::invalid(UNSUPPORTED))?;
        let pct = self.client.price_change_percent(symbol).await?;
        Ok(if invert { -pct } else { pct })
    }

    /// Hourly close prices of the last 24 h.
    pub async fn get_24hr_klines(&self, asset: Asset, currency: Option<Currency>) -> Result<Vec<f64>> {
        self.history(asset, currency, KlineInterval::OneHour.value(), 24 * 3_600_000, 24).await
    }

    /// Close prices over `period_in_days` at `interval`.
    pub async fn get_klines_for_period(
        &self,
        asset: Asset,
        interval: KlineInterval,
        period_in_days: u32,
        currency: Option<Currency>,
    ) -> Result<Vec<f64>> {
        let days = i64::from(period_in_days);
        self.history(asset, currency, interval.value(), days * 86_400_000, period_in_days as usize * 24).await
    }

    async fn history(
        &self,
        asset: Asset,
        currency: Option<Currency>,
        interval: &str,
        period_ms: i64,
        pegged_len: usize,
    ) -> Result<Vec<f64>> {
        let currency = currency.unwrap_or(self.default_currency);
        if pegged_price(asset, currency).is_some() {
            return Ok(vec![1.0; pegged_len]);
        }
        let (symbol, invert) = symbol_for(asset, currency, false).ok_or_else(|| Error::invalid(UNSUPPORTED))?;
        let closes = self.client.closes(symbol, interval, period_ms).await?;
        Ok(if invert { closes.into_iter().map(|p| 1.0 / p).collect() } else { closes })
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::ports::HttpMethod;
    use crate::testing::{block_on, FixedClock, MockHttp};
    use serde_json::json;

    fn tickers() -> Value {
        json!([
            {"symbol":"BTCBRL","priceChange":"-1200.00","priceChangePercent":"-0.214","weightedAvgPrice":"560100.12",
             "prevClosePrice":"561000.00","lastPrice":"559800.00","bidPrice":"559750.00000000","bidQty":"0.01",
             "askPrice":"559900.00000000","openTime":1759600000000_u64,"closeTime":1759686400000_u64,"count":12345},
            {"symbol":"BTCUSDT","priceChangePercent":"1.500","bidPrice":"102345.67000000","askPrice":"102345.68"},
            {"symbol":"USDTBRL","priceChangePercent":"0.400","bidPrice":"5.40000000","askPrice":"5.401"}
        ])
    }

    type TestClient = Arc<BinanceClient<MockHttp, Arc<FixedClock>>>;

    fn setup() -> (MockHttp, Arc<FixedClock>, TestClient) {
        let http = MockHttp::new();
        let clock = Arc::new(FixedClock::new(1_759_686_400_000));
        http.on_json(HttpMethod::Get, TICKER_URL, 200, tickers());
        let client = Arc::new(BinanceClient::new(http.clone(), clock.clone()));
        (http, clock, client)
    }

    #[test]
    fn prices_per_pair() {
        let (http, _, client) = setup();
        let brl = BinancePriceService::new(client.clone(), Currency::Brl);
        block_on(async {
            assert_eq!(brl.get_coin_price(Asset::Btc, None).await.unwrap(), Some(559_750.0));
            assert_eq!(brl.get_coin_price(Asset::Lbtc, None).await.unwrap(), Some(559_750.0));
            assert_eq!(brl.get_coin_price(Asset::Usdt, None).await.unwrap(), Some(5.4));
            assert_eq!(brl.get_coin_price(Asset::Depix, None).await.unwrap(), Some(1.0));
            assert_eq!(brl.get_coin_price(Asset::Btc, Some(Currency::Usd)).await.unwrap(), Some(102_345.67));
            assert_eq!(brl.get_coin_price(Asset::Usdt, Some(Currency::Usd)).await.unwrap(), Some(1.0));
            assert_eq!(brl.get_coin_price(Asset::Depix, Some(Currency::Usd)).await.unwrap(), Some(1.0 / 5.4));
        });
        // One request: the 60 s cache serves every later call.
        assert_eq!(http.requests().len(), 1);
    }

    #[test]
    fn cache_expires_after_ttl() {
        let (http, clock, client) = setup();
        block_on(async {
            client.tickers().await.unwrap();
            clock.advance(BINANCE_CACHE_TTL_MS);
            client.tickers().await.unwrap();
            assert_eq!(http.requests().len(), 1);
            clock.advance(1);
            client.tickers().await.unwrap();
            assert_eq!(http.requests().len(), 2);
        });
    }

    #[test]
    fn errors_and_missing_symbols() {
        let http = MockHttp::new();
        let clock = Arc::new(FixedClock::new(0));
        http.on_json(HttpMethod::Get, TICKER_URL, 200, json!([{"symbol":"BTCBRL","bidPrice":12.5}]));
        http.once_json(HttpMethod::Get, TICKER_URL, 429, json!({"code":-1003,"msg":"Too many requests"}));
        let svc = BinancePriceService::new(Arc::new(BinanceClient::new(http, clock)), Currency::Brl);
        block_on(async {
            let err = svc.get_coin_price(Asset::Btc, None).await.unwrap_err();
            assert!(matches!(err, Error::Http { status: 429, .. }));
            // A numeric bidPrice is not a string, so it gives no price.
            assert_eq!(svc.get_coin_price(Asset::Btc, None).await.unwrap(), None);
            assert_eq!(svc.get_coin_price(Asset::Usdt, None).await.unwrap(), None);
        });
    }

    #[test]
    fn variation_and_klines() {
        let (http, clock, client) = setup();
        let now = clock.now_ms() as i64;
        let start = now - 24 * 3_600_000;
        let url = format!("{BINANCE_API_URL}klines?symbol=USDTBRL&interval=1h&startTime={start}&endTime={now}");
        let k = |close: Value| json!([1, "5.0", "5.5", "4.9", close, "100", 2, "500", 10, "50", "250", "0"]);
        http.on_json(HttpMethod::Get, &url, 200, json!([k(json!("5.0")), k(json!("bad")), k(json!(4.0))]));
        let svc = BinanceDailyPriceVariationService::new(client, Currency::Brl);
        block_on(async {
            assert_eq!(svc.get_percentage_variation(Asset::Btc, None).await.unwrap(), -0.214);
            assert_eq!(svc.get_percentage_variation(Asset::Depix, Some(Currency::Usd)).await.unwrap(), -0.4);
            assert_eq!(svc.get_percentage_variation(Asset::Depix, None).await.unwrap(), 0.0);
            assert!(svc.get_percentage_variation(Asset::Lbtc, None).await.is_err());
            assert_eq!(svc.get_24hr_klines(Asset::Usdt, None).await.unwrap(), vec![5.0, 4.5, 4.0]);
            assert_eq!(
                svc.get_24hr_klines(Asset::Depix, Some(Currency::Usd)).await.unwrap(),
                vec![0.2, 1.0 / 4.5, 0.25]
            );
            assert_eq!(
                svc.get_klines_for_period(Asset::Usdt, KlineInterval::OneDay, 2, Some(Currency::Usd))
                    .await
                    .unwrap()
                    .len(),
                48
            );
        });
        assert!(http.requests().iter().any(|r| r.url == url));
    }
}
