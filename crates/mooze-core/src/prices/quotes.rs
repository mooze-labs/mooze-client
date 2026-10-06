//! Quotes shown by the UI. Port of `store/price_quote.dart`, `store/price_quotes_notifier.dart`
//! and `store/price_sync_coordinator.dart`. The platform runs the 30 s timer and calls
//! [`PriceQuotesStore::refresh`].

use std::collections::BTreeMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Mutex;

use super::{Currency, PriceCacheService, PriceService};
use crate::domain::Asset;
use crate::ports::{Clock, KvStore};

/// Refresh period of the price sync coordinator.
pub const PRICE_REFRESH_INTERVAL_MS: u64 = 30_000;

/// Assets the store quotes, in Dart order.
pub const QUOTE_ASSETS: [Asset; 4] = [Asset::Btc, Asset::Usdt, Asset::Depix, Asset::Lbtc];

/// One price. Dart `PriceQuote`.
#[derive(Debug, Clone, PartialEq)]
pub struct PriceQuote {
    pub asset: Asset,
    pub currency: Currency,
    pub price: f64,
    pub fetched_at_ms: u64,
}

impl PriceQuote {
    /// Age at `now_ms`.
    pub fn age_ms(&self, now_ms: u64) -> u64 {
        now_ms.saturating_sub(self.fetched_at_ms)
    }
}

/// Store state. Dart `PriceQuotes`.
#[derive(Debug, Clone, PartialEq)]
pub struct PriceQuotes {
    pub currency: Currency,
    pub quotes: BTreeMap<Asset, PriceQuote>,
    pub last_success_at_ms: Option<u64>,
    /// True until the first cache read finishes.
    pub warming: bool,
    pub refreshing: bool,
}

impl PriceQuotes {
    /// State before boot.
    pub fn initial(currency: Currency) -> Self {
        Self {
            currency,
            quotes: BTreeMap::new(),
            last_success_at_ms: None,
            warming: true,
            refreshing: false,
        }
    }

    /// Price of `asset`, if known.
    pub fn price_for(&self, asset: Asset) -> Option<f64> {
        self.quotes.get(&asset).map(|q| q.price)
    }
}

/// Holds [`PriceQuotes`] and refreshes them from a [`PriceService`]. Dart `PriceQuotesNotifier`.
#[derive(Debug)]
pub struct PriceQuotesStore<S, K, C> {
    service: S,
    cache: PriceCacheService<K, C>,
    state: Mutex<PriceQuotes>,
    generation: AtomicU64,
}

impl<S: PriceService, K: KvStore, C: Clock> PriceQuotesStore<S, K, C> {
    /// Store in the initial (warming, BRL) state. `cache` must use the store the service writes.
    pub fn new(service: S, cache: PriceCacheService<K, C>) -> Self {
        Self {
            service,
            cache,
            state: Mutex::new(PriceQuotes::initial(Currency::Brl)),
            generation: AtomicU64::new(0),
        }
    }

    /// Snapshot of the state.
    pub fn state(&self) -> PriceQuotes {
        self.state.lock().expect("poisoned").clone()
    }

    async fn read_all_from_cache(&self, currency: Currency) -> BTreeMap<Asset, PriceQuote> {
        let mut out = BTreeMap::new();
        for asset in QUOTE_ASSETS {
            if let Ok(Some(d)) = self.cache.get_cached_price(asset, currency).await {
                let fetched_at_ms = u64::try_from(d.timestamp).unwrap_or(0);
                out.insert(
                    asset,
                    PriceQuote {
                        asset,
                        currency,
                        price: d.price,
                        fetched_at_ms,
                    },
                );
            }
        }
        out
    }

    /// Loads cached quotes for `currency` and ends warming. Call [`Self::refresh`] next.
    pub async fn initialize(&self, currency: Currency) -> PriceQuotes {
        let disk = self.read_all_from_cache(currency).await;
        let mut s = self.state.lock().expect("poisoned");
        s.currency = currency;
        s.quotes = disk;
        s.warming = false;
        s.clone()
    }

    /// Switches currency and loads its cached quotes. Call [`Self::refresh`] next.
    /// NOTE(port): with no cache for `next`, Dart keeps the old currency's quotes. Kept.
    pub async fn swap_currency(&self, next: Currency) -> PriceQuotes {
        let disk = self.read_all_from_cache(next).await;
        let mut s = self.state.lock().expect("poisoned");
        s.currency = next;
        if !disk.is_empty() {
            s.quotes = disk;
        }
        s.clone()
    }

    /// Fetches every asset in parallel and merges the fresh prices.
    /// A result is dropped if a newer refresh started or the currency changed meanwhile.
    pub async fn refresh(&self) -> PriceQuotes {
        let my_gen = self.generation.fetch_add(1, Ordering::SeqCst) + 1;
        let currency = {
            let mut s = self.state.lock().expect("poisoned");
            s.refreshing = true;
            s.currency
        };
        let fetches = QUOTE_ASSETS.map(|asset| self.service.get_coin_price(asset, Some(currency)));
        let results = futures::future::join_all(fetches).await;
        let now = self.cache.now_ms();
        let mut s = self.state.lock().expect("poisoned");
        if my_gen != self.generation.load(Ordering::SeqCst) || currency != s.currency {
            return s.clone();
        }
        let mut any_fresh = false;
        for (asset, result) in QUOTE_ASSETS.into_iter().zip(results) {
            if let Ok(Some(price)) = result {
                s.quotes.insert(
                    asset,
                    PriceQuote {
                        asset,
                        currency,
                        price,
                        fetched_at_ms: now,
                    },
                );
                any_fresh = true;
            }
        }
        if any_fresh {
            s.last_success_at_ms = Some(now);
        }
        s.refreshing = false;
        s.clone()
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use std::sync::Arc;

    use super::*;
    use crate::prices::cache::tests::ScriptedPrices;
    use crate::testing::{block_on, FixedClock, MemoryKv};
    use crate::Error;

    const T0: u64 = 1_759_686_400_000;

    #[test]
    fn boot_refresh_and_swap() {
        let kv = MemoryKv::new();
        let clock = Arc::new(FixedClock::new(T0));
        let cache = PriceCacheService::new(kv, clock.clone());
        let svc = ScriptedPrices::new(Err(Error::Network("offline".into())));
        let store = PriceQuotesStore::new(svc.clone(), cache.clone());
        assert!(store.state().warming);
        block_on(async {
            cache
                .cache_price(Asset::Btc, 500_000.0, Currency::Brl)
                .await
                .unwrap();
            let s = store.initialize(Currency::Brl).await;
            assert!(!s.warming);
            assert_eq!(s.price_for(Asset::Btc), Some(500_000.0));
            assert_eq!(s.quotes[&Asset::Btc].fetched_at_ms, T0);

            clock.advance(PRICE_REFRESH_INTERVAL_MS);
            let s = store.refresh().await;
            assert_eq!((s.last_success_at_ms, s.refreshing), (None, false));
            assert_eq!(s.price_for(Asset::Btc), Some(500_000.0));

            svc.set(Ok(Some(7.0)));
            let s = store.refresh().await;
            assert_eq!(s.last_success_at_ms, Some(T0 + PRICE_REFRESH_INTERVAL_MS));
            assert!(QUOTE_ASSETS.iter().all(|a| s.price_for(*a) == Some(7.0)));

            // USD has no cache: quotes stay, currency changes.
            let s = store.swap_currency(Currency::Usd).await;
            assert_eq!(
                (s.currency, s.price_for(Asset::Usdt)),
                (Currency::Usd, Some(7.0))
            );
            let s = store.refresh().await;
            assert_eq!(s.quotes[&Asset::Depix].currency, Currency::Usd);
        });
        assert_eq!(svc.calls.load(std::sync::atomic::Ordering::SeqCst), 12);
    }
}
