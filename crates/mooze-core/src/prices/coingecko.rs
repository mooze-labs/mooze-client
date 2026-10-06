//! CoinGecko simple price API.

use std::collections::BTreeMap;
use std::future::Future;

use serde_json::Value;

use super::{pegged_price, Currency, PriceService};
use crate::domain::Asset;
use crate::ports::{HttpClient, HttpRequest, MaybeSend};
use crate::{Error, Result};

/// Base URL of the CoinGecko API.
pub const COINGECKO_BASE_URL: &str = "https://api.coingecko.com/api/v3";

/// Prices by coin id, then by currency.
type CoinPrices = BTreeMap<String, BTreeMap<String, f64>>;

/// Prices from CoinGecko.
#[derive(Debug, Clone)]
pub struct CoingeckoPriceService<H> {
    http: H,
    currency: Currency,
}

impl<H: HttpClient> CoingeckoPriceService<H> {
    /// Service with a default currency.
    pub fn new(http: H, currency: Currency) -> Self {
        Self { http, currency }
    }

    /// `GET /simple/price`. A non-200 status gives `Ok(None)`.
    pub async fn fetch_coin_prices(&self, coins: &[&str], currency: &str) -> Result<Option<CoinPrices>> {
        let url = format!("{COINGECKO_BASE_URL}/simple/price?ids={}&vs_currencies={currency}&precision=full", coins.join(","));
        let resp = self.http.send(HttpRequest::get(url)).await?;
        if resp.status != 200 {
            return Ok(None);
        }
        let raw: serde_json::Map<String, Value> = serde_json::from_slice(&resp.body)?;
        let mut out = CoinPrices::new();
        for (coin, data) in raw {
            if let Value::Object(map) = data {
                let prices = map.into_iter().filter_map(|(c, v)| v.as_f64().map(|p| (c, p))).collect();
                out.insert(coin, prices);
            }
        }
        Ok(Some(out))
    }
}

impl<H: HttpClient> PriceService for CoingeckoPriceService<H> {
    fn currency(&self) -> Currency {
        self.currency
    }

    fn get_coin_price(&self, asset: Asset, currency: Option<Currency>)
        -> impl Future<Output = Result<Option<f64>>> + MaybeSend {
        let currency = currency.unwrap_or(self.currency);
        async move {
            if let Some(p) = pegged_price(asset, currency) {
                return Ok(Some(p));
            }
            if (asset, currency) == (Asset::Depix, Currency::Usd) {
                let Some(prices) = self.fetch_coin_prices(&["tether"], "brl").await? else { return Ok(None) };
                // A missing tether/brl price is an error.
                let brl = prices.get("tether").and_then(|m| m.get("brl")).copied();
                return brl.map(|b| Some(1.0 / b)).ok_or_else(|| Error::protocol("coingecko: tether/brl missing"));
            }
            let ticker = match asset {
                Asset::Btc | Asset::Lbtc => "bitcoin",
                Asset::Usdt => "tether",
                Asset::Depix => return Err(Error::invalid("Depix is not a valid Coingecko asset.")),
            };
            let prices = self.fetch_coin_prices(&[ticker], currency.name()).await?;
            Ok(prices.and_then(|p| p.get(ticker).and_then(|m| m.get(currency.name())).copied()))
        }
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::ports::HttpMethod;
    use crate::testing::{block_on, MockHttp};
    use serde_json::json;

    fn url(ids: &str, cur: &str) -> String {
        format!("https://api.coingecko.com/api/v3/simple/price?ids={ids}&vs_currencies={cur}&precision=full")
    }

    #[test]
    fn parses_simple_price() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, &url("bitcoin", "brl"), 200, json!({"bitcoin": {"brl": 561234.123456789}}));
        http.on_json(HttpMethod::Get, &url("bitcoin", "usd"), 200, json!({"bitcoin": {"usd": 102345}}));
        http.on_json(HttpMethod::Get, &url("tether", "brl"), 200, json!({"tether": {"brl": 5.0}, "x": 1}));
        let svc = CoingeckoPriceService::new(http.clone(), Currency::Brl);
        block_on(async {
            assert_eq!(svc.get_coin_price(Asset::Btc, None).await.unwrap(), Some(561_234.123456789));
            assert_eq!(svc.get_coin_price(Asset::Lbtc, Some(Currency::Usd)).await.unwrap(), Some(102_345.0));
            assert_eq!(svc.get_coin_price(Asset::Usdt, None).await.unwrap(), Some(5.0));
            assert_eq!(svc.get_coin_price(Asset::Depix, Some(Currency::Usd)).await.unwrap(), Some(0.2));
            assert_eq!(svc.get_coin_price(Asset::Depix, None).await.unwrap(), Some(1.0));
            assert_eq!(svc.get_coin_price(Asset::Usdt, Some(Currency::Usd)).await.unwrap(), Some(1.0));
        });
        assert_eq!(http.requests()[0].url, url("bitcoin", "brl"));
    }

    #[test]
    fn non_200_is_none_and_garbage_is_error() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, &url("bitcoin", "brl"), 429, json!({"status": {"error_code": 429}}));
        http.once_raw(HttpMethod::Get, &url("tether", "brl"), 200, "not json");
        let svc = CoingeckoPriceService::new(http, Currency::Brl);
        block_on(async {
            assert_eq!(svc.get_coin_price(Asset::Btc, None).await.unwrap(), None);
            assert!(matches!(svc.get_coin_price(Asset::Usdt, None).await, Err(Error::Protocol(_))));
            assert!(svc.get_coin_price(Asset::Usdt, None).await.unwrap().is_none()); // 404 from mock
        });
    }
}
