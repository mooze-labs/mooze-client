//! Timestamped reference-market history. No wallet identifiers are sent to the provider.
use super::{Currency, COINGECKO_BASE_URL};
use crate::{
    domain::Asset,
    ports::{HttpClient, HttpRequest},
    Error, Result,
};

/// CoinGecko prices with their original observation timestamps in milliseconds.
pub async fn coingecko_history<H: HttpClient>(
    http: &H,
    asset: Asset,
    currency: Currency,
    days: u32,
    demo_key: Option<&str>,
) -> Result<Vec<(u64, f64)>> {
    if !matches!(days, 1 | 7 | 30) {
        return Err(Error::invalid("unsupported price history period"));
    }
    let coin = match asset {
        Asset::Btc | Asset::Lbtc => "bitcoin",
        Asset::Usdt => "tether",
        Asset::Depix => return Err(Error::invalid("no reference market for this asset")),
    };
    let mut request = HttpRequest::get(format!(
        "{COINGECKO_BASE_URL}/coins/{coin}/market_chart?vs_currency={}&days={days}",
        currency.name()
    ))
    .timeout_ms(15_000);
    if let Some(key) = demo_key.filter(|key| !key.is_empty()) {
        request = request.header("x-cg-demo-api-key", key);
    }
    #[derive(serde::Deserialize)]
    struct Response {
        prices: Vec<(u64, f64)>,
    }
    let mut points = http.send(request).await?.json::<Response>()?.prices;
    if points.len() < 2
        || points.len() > 20_000
        || points.iter().any(|(time, price)| *time == 0 || !price.is_finite() || *price <= 0.0)
    {
        return Err(Error::protocol("invalid market history"));
    }
    points.sort_by_key(|point| point.0);
    points.dedup_by_key(|point| point.0);
    if points.len() < 2 {
        return Err(Error::protocol("insufficient market history"));
    }
    Ok(points)
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::{
        ports::HttpMethod,
        testing::{block_on, MockHttp},
    };
    #[test]
    fn preserves_timestamps_sorts_and_deduplicates() {
        let http = MockHttp::new();
        http.on_json(
            HttpMethod::Get,
            &format!("{COINGECKO_BASE_URL}/coins/bitcoin/market_chart?vs_currency=brl&days=7"),
            200,
            serde_json::json!({"prices":[[2000,20],[1000,10],[1000,10]]}),
        );
        assert_eq!(
            block_on(coingecko_history(&http, Asset::Lbtc, Currency::Brl, 7, None)).unwrap(),
            vec![(1000, 10.0), (2000, 20.0)]
        );
    }
    #[test]
    fn rejects_invalid_period_asset_points_and_rate_limits() {
        let http = MockHttp::new();
        assert!(block_on(coingecko_history(&http, Asset::Btc, Currency::Usd, 365, None)).is_err());
        assert!(block_on(coingecko_history(&http, Asset::Depix, Currency::Usd, 1, None)).is_err());
        assert!(http.requests().is_empty());
        let url = format!("{COINGECKO_BASE_URL}/coins/tether/market_chart?vs_currency=usd&days=1");
        http.on_json(HttpMethod::Get, &url, 200, serde_json::json!({"prices":[[1000,-1],[2000,1]]}));
        assert!(block_on(coingecko_history(&http, Asset::Usdt, Currency::Usd, 1, None)).is_err());
        http.on_json(HttpMethod::Get, &url, 429, serde_json::json!({}));
        assert!(block_on(coingecko_history(&http, Asset::Usdt, Currency::Usd, 1, None)).is_err());
    }
}
