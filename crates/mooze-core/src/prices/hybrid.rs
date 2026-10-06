//! Primary source with fallback.

use std::future::Future;
use std::sync::Arc;

use super::{
    BinanceClient, BinancePriceService, CachedPriceService, CoingeckoPriceService, Currency, PriceCacheService,
    PriceService, PriceSource,
};
use crate::domain::Asset;
use crate::ports::{Clock, HttpClient, KvStore, MaybeSend};
use crate::Result;

/// Connectivity hint from [`HybridPriceService::get_coin_price_with_connectivity`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Connectivity {
    /// A price arrived.
    Online,
    /// No price, but a cached one exists.
    Offline,
}

/// Tries the primary source, then the other one.
///
/// `B` is the Binance service, `G` the CoinGecko service. Both are normally
/// [`CachedPriceService`]s. Errors from any source count as "no price".
#[derive(Debug, Clone)]
pub struct HybridPriceService<B, G> {
    binance: B,
    coingecko: G,
    primary: PriceSource,
    currency: Currency,
}

/// The service the app builds: both sources cached in the same [`KvStore`].
/// NOTE: both caches share one key per asset and currency.
/// A cached price from the primary source stops the fallback to the other source.
pub type StandardHybridPriceService<H, K, C> = HybridPriceService<
    CachedPriceService<BinancePriceService<H, C>, K, C>,
    CachedPriceService<CoingeckoPriceService<H>, K, C>,
>;

impl<B: PriceService, G: PriceService> HybridPriceService<B, G> {
    /// Hybrid over two services.
    pub fn new(binance: B, coingecko: G, currency: Currency, primary: PriceSource) -> Self {
        Self { binance, coingecko, primary, currency }
    }

    /// The primary source.
    pub fn primary(&self) -> PriceSource {
        self.primary
    }
}

impl<H, K, C> StandardHybridPriceService<H, K, C>
where
    H: HttpClient + Clone,
    K: KvStore + Clone,
    C: Clock + Clone,
{
    /// Builds Binance and CoinGecko services, each wrapped in a [`CachedPriceService`].
    pub fn standard(http: H, kv: K, clock: C, currency: Currency, primary: PriceSource) -> Self {
        let client = Arc::new(BinanceClient::new(http.clone(), clock.clone()));
        let cache = PriceCacheService::new(kv, clock);
        let binance = CachedPriceService::new(BinancePriceService::new(client, currency), cache.clone(), currency);
        let coingecko = CachedPriceService::new(CoingeckoPriceService::new(http, currency), cache, currency);
        Self::new(binance, coingecko, currency, primary)
    }

    /// Deletes corrupt cache entries.
    pub async fn clean_expired_cache(&self) -> Result<()> {
        self.binance.clean_expired_cache().await
    }

    /// True if the primary source's cache holds a price.
    pub async fn has_cached_price(&self, asset: Asset, currency: Option<Currency>) -> Result<bool> {
        let currency = Some(currency.unwrap_or(self.currency));
        match self.primary {
            PriceSource::Binance => self.binance.has_cached_price(asset, currency).await,
            PriceSource::Coingecko => self.coingecko.has_cached_price(asset, currency).await,
        }
    }

    /// Age of the primary source's cached price in minutes.
    pub async fn get_cache_age_in_minutes(&self, asset: Asset, currency: Option<Currency>) -> Result<Option<i64>> {
        let currency = Some(currency.unwrap_or(self.currency));
        match self.primary {
            PriceSource::Binance => self.binance.get_cache_age_in_minutes(asset, currency).await,
            PriceSource::Coingecko => self.coingecko.get_cache_age_in_minutes(asset, currency).await,
        }
    }

    /// Price plus a connectivity hint.
    pub async fn get_coin_price_with_connectivity(
        &self,
        asset: Asset,
        currency: Option<Currency>,
    ) -> Result<(Option<f64>, Option<Connectivity>)> {
        let price = self.get_coin_price(asset, currency).await?;
        let hint = match price {
            Some(_) => Some(Connectivity::Online),
            None => match self.has_cached_price(asset, currency).await {
                Ok(true) => Some(Connectivity::Offline),
                _ => None,
            },
        };
        Ok((price, hint))
    }
}

impl<B: PriceService, G: PriceService> PriceService for HybridPriceService<B, G> {
    fn currency(&self) -> Currency {
        self.currency
    }

    fn get_coin_price(
        &self,
        asset: Asset,
        currency: Option<Currency>,
    ) -> impl Future<Output = Result<Option<f64>>> + MaybeSend {
        let target = Some(currency.unwrap_or(self.currency));
        async move {
            let first = match self.primary {
                PriceSource::Binance => self.binance.get_coin_price(asset, target).await,
                PriceSource::Coingecko => self.coingecko.get_coin_price(asset, target).await,
            };
            if let Ok(Some(p)) = first {
                return Ok(Some(p));
            }
            let alt = match self.primary {
                PriceSource::Binance => self.coingecko.get_coin_price(asset, target).await,
                PriceSource::Coingecko => self.binance.get_coin_price(asset, target).await,
            };
            Ok(alt.ok().flatten())
        }
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::ports::HttpMethod;
    use crate::prices::cache::tests::ScriptedPrices;
    use crate::testing::{block_on, FixedClock, MemoryKv, MockHttp};
    use crate::Error;
    use serde_json::json;

    const CG_BTC_BRL: &str =
        "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=brl&precision=full";
    const BN: &str =
        "https://data-api.binance.vision/api/v3/ticker/24hr?symbols=%5B%22BTCBRL%22%2C%22BTCUSDT%22%2C%22USDTBRL%22%5D";

    #[test]
    fn fallback_order() {
        let b = ScriptedPrices::new(Ok(Some(2.0)));
        let g = ScriptedPrices::new(Err(Error::Network("x".into())));
        let h = HybridPriceService::new(b.clone(), g.clone(), Currency::Brl, PriceSource::Coingecko);
        block_on(async {
            assert_eq!(h.get_coin_price(Asset::Btc, None).await.unwrap(), Some(2.0));
            g.set(Ok(Some(1.0)));
            assert_eq!(h.get_coin_price(Asset::Btc, None).await.unwrap(), Some(1.0));
            g.set(Ok(None));
            b.set(Err(Error::Timeout("t".into())));
            assert_eq!(h.get_coin_price(Asset::Btc, None).await.unwrap(), None);
        });
        let calls = |s: &ScriptedPrices| s.calls.load(std::sync::atomic::Ordering::SeqCst);
        assert_eq!((calls(&g), calls(&b)), (3, 2));
    }

    #[test]
    fn standard_wiring_with_http() {
        let http = MockHttp::new();
        let clock = Arc::new(FixedClock::new(1_759_686_400_000));
        let kv = MemoryKv::new();
        http.on_json(HttpMethod::Get, CG_BTC_BRL, 500, json!({}));
        http.on_json(HttpMethod::Get, BN, 200, json!([{"symbol":"BTCBRL","bidPrice":"559750.00"}]));
        let h = StandardHybridPriceService::standard(
            http.clone(),
            kv.clone(),
            clock.clone(),
            Currency::Brl,
            PriceSource::Coingecko,
        );
        block_on(async {
            // CoinGecko answers 500 and the cache is empty, so Binance supplies the price.
            assert_eq!(
                h.get_coin_price_with_connectivity(Asset::Btc, None).await.unwrap(),
                (Some(559_750.0), Some(Connectivity::Online))
            );
            assert_eq!(h.get_cache_age_in_minutes(Asset::Btc, None).await.unwrap(), Some(0));
            // Both sources fail: the shared cache entry answers from the primary wrapper.
            http.on_json(HttpMethod::Get, BN, 503, json!({}));
            clock.advance(10 * 60_000);
            let n = http.requests().len();
            assert_eq!(h.get_coin_price(Asset::Btc, None).await.unwrap(), Some(559_750.0));
            assert_eq!(http.requests().len(), n + 1); // Binance not asked
                                                      // No cache for USD and no source: offline hint is absent.
            assert_eq!(
                h.get_coin_price_with_connectivity(Asset::Usdt, Some(Currency::Brl)).await.unwrap(),
                (None, None)
            );
            h.clean_expired_cache().await.unwrap();
        });
    }
}
