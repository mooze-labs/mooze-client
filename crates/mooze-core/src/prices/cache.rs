//! Persistent last-known prices. Port of `models/cached_price_data.dart`,
//! `services/price_cache_service.dart` and `services/cached_price_service.dart`.

use std::future::Future;

use serde::{Deserialize, Serialize};

use super::{Currency, PriceService};
use crate::domain::Asset;
use crate::ports::{Clock, KvStore, MaybeSend};
use crate::Result;

/// Key prefix of cached prices. Full key: `cached_price_<assetId>_<currency>`.
pub const CACHE_KEY_PREFIX: &str = "cached_price_";

/// One cached price. JSON shape matches the Dart `CachedPriceData.toJson`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CachedPriceData {
    pub price: f64,
    /// Milliseconds since the Unix epoch.
    pub timestamp: i64,
    pub currency: String,
    #[serde(rename = "assetId")]
    pub asset_id: String,
}

impl CachedPriceData {
    fn age_ms(&self, now_ms: u64) -> i64 {
        now_ms as i64 - self.timestamp
    }

    /// Dart `isValid`: age in whole minutes is at most 5.
    pub fn is_valid(&self, now_ms: u64) -> bool {
        self.age_ms(now_ms) / 60_000 <= 5
    }

    /// Dart `isRecentEnough`: age in whole hours is at most 1.
    pub fn is_recent_enough(&self, now_ms: u64) -> bool {
        self.age_ms(now_ms) / 3_600_000 <= 1
    }

    /// Age in whole minutes, truncated toward zero.
    pub fn age_minutes(&self, now_ms: u64) -> i64 {
        self.age_ms(now_ms) / 60_000
    }
}

/// Reads and writes [`CachedPriceData`] in a [`KvStore`]. Dart `PriceCacheService`.
#[derive(Debug, Clone)]
pub struct PriceCacheService<K, C> {
    kv: K,
    clock: C,
}

impl<K: KvStore, C: Clock> PriceCacheService<K, C> {
    /// Cache over a store and a clock.
    pub fn new(kv: K, clock: C) -> Self {
        Self { kv, clock }
    }

    /// Storage key for one asset and currency.
    pub fn cache_key(asset: Asset, currency: Currency) -> String {
        format!("{CACHE_KEY_PREFIX}{}_{}", asset.id(), currency.name())
    }

    /// Current time from the clock.
    pub fn now_ms(&self) -> u64 {
        self.clock.now_ms()
    }

    /// Stores `price` with the current time.
    pub async fn cache_price(&self, asset: Asset, price: f64, currency: Currency) -> Result<()> {
        let data = CachedPriceData {
            price,
            timestamp: self.clock.now_ms() as i64,
            currency: currency.name().to_owned(),
            asset_id: asset.id().to_owned(),
        };
        self.kv
            .put(
                &Self::cache_key(asset, currency),
                serde_json::to_vec(&data)?,
            )
            .await
    }

    /// Reads the entry. A corrupt entry is deleted and gives `None`.
    pub async fn get_cached_price(
        &self,
        asset: Asset,
        currency: Currency,
    ) -> Result<Option<CachedPriceData>> {
        let key = Self::cache_key(asset, currency);
        let Some(bytes) = self.kv.get(&key).await? else {
            return Ok(None);
        };
        match serde_json::from_slice(&bytes) {
            Ok(data) => Ok(Some(data)),
            Err(_) => {
                self.kv.delete(&key).await?;
                Ok(None)
            }
        }
    }

    async fn price_if(
        &self,
        asset: Asset,
        currency: Currency,
        ok: impl Fn(&CachedPriceData, u64) -> bool,
    ) -> Result<Option<f64>> {
        let now = self.clock.now_ms();
        Ok(self
            .get_cached_price(asset, currency)
            .await?
            .filter(|d| ok(d, now))
            .map(|d| d.price))
    }

    /// Price younger than 6 minutes. Dart `getValidCachedPrice`.
    pub async fn get_valid_cached_price(
        &self,
        asset: Asset,
        currency: Currency,
    ) -> Result<Option<f64>> {
        self.price_if(asset, currency, CachedPriceData::is_valid)
            .await
    }

    /// Price younger than 2 hours. Dart `getEmergencyCachedPrice`.
    pub async fn get_emergency_cached_price(
        &self,
        asset: Asset,
        currency: Currency,
    ) -> Result<Option<f64>> {
        self.price_if(asset, currency, CachedPriceData::is_recent_enough)
            .await
    }

    /// Any cached price. Dart `getAnyCachedPrice`.
    pub async fn get_any_cached_price(
        &self,
        asset: Asset,
        currency: Currency,
    ) -> Result<Option<f64>> {
        self.price_if(asset, currency, |_, _| true).await
    }

    /// Deletes corrupt entries. Dart `cleanExpiredCache` (it removes only corrupt data).
    pub async fn clean_expired_cache(&self) -> Result<()> {
        for key in self.kv.list_keys(CACHE_KEY_PREFIX).await? {
            if let Some(bytes) = self.kv.get(&key).await? {
                if serde_json::from_slice::<CachedPriceData>(&bytes).is_err() {
                    self.kv.delete(&key).await?;
                }
            }
        }
        Ok(())
    }
}

/// Wraps a [`PriceService`] and falls back to the cache. Dart `CachedPriceService`.
///
/// A fresh price is saved. Without a fresh price it tries the valid, then the emergency,
/// then any cached price. Errors from the wrapped service count as "no price".
#[derive(Debug, Clone)]
pub struct CachedPriceService<S, K, C> {
    inner: S,
    cache: PriceCacheService<K, C>,
    currency: Currency,
}

impl<S: PriceService, K: KvStore, C: Clock> CachedPriceService<S, K, C> {
    /// Wraps `inner`.
    pub fn new(inner: S, cache: PriceCacheService<K, C>, currency: Currency) -> Self {
        Self {
            inner,
            cache,
            currency,
        }
    }

    /// The cache this service writes to.
    pub fn cache(&self) -> &PriceCacheService<K, C> {
        &self.cache
    }

    /// Deletes corrupt cache entries.
    pub async fn clean_expired_cache(&self) -> Result<()> {
        self.cache.clean_expired_cache().await
    }

    /// True if any entry exists for the asset.
    pub async fn has_cached_price(&self, asset: Asset, currency: Option<Currency>) -> Result<bool> {
        Ok(self
            .cache
            .get_cached_price(asset, currency.unwrap_or(self.currency))
            .await?
            .is_some())
    }

    /// Age of the cached entry in whole minutes.
    pub async fn get_cache_age_in_minutes(
        &self,
        asset: Asset,
        currency: Option<Currency>,
    ) -> Result<Option<i64>> {
        let now = self.cache.now_ms();
        let data = self
            .cache
            .get_cached_price(asset, currency.unwrap_or(self.currency))
            .await?;
        Ok(data.map(|d| d.age_minutes(now)))
    }
}

impl<S: PriceService, K: KvStore, C: Clock> PriceService for CachedPriceService<S, K, C> {
    fn currency(&self) -> Currency {
        self.currency
    }

    fn get_coin_price(
        &self,
        asset: Asset,
        currency: Option<Currency>,
    ) -> impl Future<Output = Result<Option<f64>>> + MaybeSend {
        let target = currency.unwrap_or(self.currency);
        async move {
            if let Ok(Some(fresh)) = self.inner.get_coin_price(asset, Some(target)).await {
                let _ = self.cache.cache_price(asset, fresh, target).await;
                return Ok(Some(fresh));
            }
            if let Some(p) = self.cache.get_valid_cached_price(asset, target).await? {
                return Ok(Some(p));
            }
            if let Some(p) = self.cache.get_emergency_cached_price(asset, target).await? {
                return Ok(Some(p));
            }
            self.cache.get_any_cached_price(asset, target).await
        }
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
pub(crate) mod tests {
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::{Arc, Mutex};

    use super::*;
    use crate::testing::{block_on, FixedClock, MemoryKv};
    use crate::Error;

    /// Price service that answers from a script and counts calls.
    #[derive(Debug, Default)]
    pub(crate) struct ScriptedPrices {
        pub answer: Mutex<Option<Result<Option<f64>>>>,
        pub calls: AtomicUsize,
    }

    impl ScriptedPrices {
        pub(crate) fn new(answer: Result<Option<f64>>) -> Arc<Self> {
            Arc::new(Self {
                answer: Mutex::new(Some(answer)),
                calls: AtomicUsize::new(0),
            })
        }
        pub(crate) fn set(&self, answer: Result<Option<f64>>) {
            *self.answer.lock().unwrap() = Some(answer);
        }
    }

    impl PriceService for ScriptedPrices {
        fn currency(&self) -> Currency {
            Currency::Brl
        }
        fn get_coin_price(
            &self,
            _: Asset,
            _: Option<Currency>,
        ) -> impl Future<Output = Result<Option<f64>>> + MaybeSend {
            self.calls.fetch_add(1, Ordering::SeqCst);
            std::future::ready(self.answer.lock().unwrap().clone().unwrap_or(Ok(None)))
        }
    }

    const T0: u64 = 1_759_686_400_000;

    #[test]
    fn key_and_json_shape() {
        let key = PriceCacheService::<MemoryKv, FixedClock>::cache_key(Asset::Usdt, Currency::Brl);
        assert_eq!(
            key,
            format!("cached_price_{}_brl", crate::domain::USDT_ASSET_ID)
        );
        let kv = MemoryKv::new();
        let cache = PriceCacheService::new(kv.clone(), FixedClock::new(T0));
        block_on(async {
            cache
                .cache_price(Asset::Btc, 600_000.5, Currency::Brl)
                .await
                .unwrap();
            let raw = kv
                .get("cached_price_btc-native-blockchain_brl")
                .await
                .unwrap()
                .unwrap();
            let v: serde_json::Value = serde_json::from_slice(&raw).unwrap();
            assert_eq!(
                v,
                serde_json::json!({"price": 600000.5, "timestamp": T0, "currency": "brl", "assetId": "btc-native-blockchain"})
            );
        });
    }

    #[test]
    fn ttl_windows() {
        let d = CachedPriceData {
            price: 1.0,
            timestamp: T0 as i64,
            currency: "brl".into(),
            asset_id: "x".into(),
        };
        assert!(d.is_valid(T0 + 6 * 60_000 - 1));
        assert!(!d.is_valid(T0 + 6 * 60_000));
        assert!(d.is_recent_enough(T0 + 2 * 3_600_000 - 1));
        assert!(!d.is_recent_enough(T0 + 2 * 3_600_000));
        assert!(d.is_valid(T0 - 10 * 60_000)); // future timestamps count as valid, as in Dart
        assert_eq!(d.age_minutes(T0 + 125_000), 2);
    }

    #[test]
    fn corrupt_entries_are_removed() {
        let kv = MemoryKv::new();
        let cache = PriceCacheService::new(kv.clone(), FixedClock::new(T0));
        block_on(async {
            let key =
                PriceCacheService::<MemoryKv, FixedClock>::cache_key(Asset::Btc, Currency::Usd);
            kv.put(&key, b"{oops".to_vec()).await.unwrap();
            kv.put("cached_price_bad", b"[]".to_vec()).await.unwrap();
            kv.put("other", b"x".to_vec()).await.unwrap();
            assert_eq!(
                cache
                    .get_cached_price(Asset::Btc, Currency::Usd)
                    .await
                    .unwrap(),
                None
            );
            assert_eq!(kv.get(&key).await.unwrap(), None);
            cache.clean_expired_cache().await.unwrap();
            assert_eq!(kv.list_keys("").await.unwrap(), vec!["other"]);
        });
    }

    #[test]
    fn fresh_then_cache_fallback() {
        let clock = Arc::new(FixedClock::new(T0));
        let inner = ScriptedPrices::new(Ok(Some(100.0)));
        let svc = CachedPriceService::new(
            inner.clone(),
            PriceCacheService::new(MemoryKv::new(), clock.clone()),
            Currency::Brl,
        );
        block_on(async {
            assert_eq!(
                svc.get_coin_price(Asset::Btc, None).await.unwrap(),
                Some(100.0)
            );
            inner.set(Err(Error::Network("down".into())));
            clock.advance(3 * 3_600_000);
            assert_eq!(
                svc.get_coin_price(Asset::Btc, None).await.unwrap(),
                Some(100.0)
            ); // any-age fallback
            assert_eq!(
                svc.get_cache_age_in_minutes(Asset::Btc, None)
                    .await
                    .unwrap(),
                Some(180)
            );
            assert!(svc.has_cached_price(Asset::Btc, None).await.unwrap());
            assert!(!svc
                .has_cached_price(Asset::Btc, Some(Currency::Usd))
                .await
                .unwrap());
            inner.set(Ok(None));
            assert_eq!(svc.get_coin_price(Asset::Usdt, None).await.unwrap(), None);
        });
    }
}
