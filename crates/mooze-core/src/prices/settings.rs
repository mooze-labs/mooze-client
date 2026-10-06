//! Price settings and the fiat currency selection. Port of `settings/price_settings_repository.dart`
//! and `providers/currency_controller_provider.dart`.

use super::{Currency, PriceServiceConfig, PriceSource};
use crate::ports::KvStore;
use crate::Result;

const KEY_SOURCE: &str = "price_source";
const KEY_CURRENCY: &str = "price_currency";
const KEY_VISIBILITY: &str = "balance_visibility";

/// Price settings in a [`KvStore`]. Values are UTF-8 strings; booleans are `true`/`false`.
#[derive(Debug, Clone)]
pub struct PriceSettingsRepository<K> {
    kv: K,
}

impl<K: KvStore> PriceSettingsRepository<K> {
    /// Repository over a store.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    async fn get_string(&self, key: &str) -> Result<Option<String>> {
        Ok(self
            .kv
            .get(key)
            .await?
            .map(|b| String::from_utf8_lossy(&b).into_owned()))
    }

    /// Saves the price source.
    pub async fn set_price_source(&self, source: PriceSource) -> Result<()> {
        self.kv
            .put(KEY_SOURCE, source.name().as_bytes().to_vec())
            .await
    }

    /// Saves the fiat currency.
    pub async fn set_price_currency(&self, currency: Currency) -> Result<()> {
        self.kv
            .put(KEY_CURRENCY, currency.name().as_bytes().to_vec())
            .await
    }

    /// Saves the balance visibility flag.
    pub async fn set_balance_visibility(&self, visible: bool) -> Result<()> {
        self.kv
            .put(KEY_VISIBILITY, visible.to_string().into_bytes())
            .await
    }

    /// Price source. NOTE(port): Dart always returns CoinGecko, even after `binance` is saved.
    pub async fn get_price_source(&self) -> Result<PriceSource> {
        let _stored = self.get_string(KEY_SOURCE).await?;
        Ok(PriceSource::Coingecko)
    }

    /// Fiat currency. Unknown or missing values give BRL.
    pub async fn get_price_currency(&self) -> Result<Currency> {
        Ok(match self.get_string(KEY_CURRENCY).await?.as_deref() {
            Some("usd") => Currency::Usd,
            _ => Currency::Brl,
        })
    }

    /// Balance visibility. Missing gives `true`.
    pub async fn get_balance_visibility(&self) -> Result<bool> {
        Ok(self
            .get_string(KEY_VISIBILITY)
            .await?
            .is_none_or(|v| v != "false"))
    }

    /// Source and currency together.
    pub async fn get_price_service_config(&self) -> Result<PriceServiceConfig> {
        let price_source = self.get_price_source().await?;
        let currency = self.get_price_currency().await?;
        Ok(PriceServiceConfig {
            currency,
            price_source,
        })
    }
}

/// One entry of the currency picker. The display name is an l10n string, so it is not here.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CurrencyItem {
    pub icon: &'static str,
    pub code: &'static str,
    pub currency: Currency,
}

/// Selected fiat currency. Dart `CurrencyNotifier`.
#[derive(Debug, Clone)]
pub struct CurrencyController<K> {
    repo: PriceSettingsRepository<K>,
    state: Currency,
}

impl<K: KvStore> CurrencyController<K> {
    /// Controller in its initial state (BRL). Call [`Self::load`] next.
    pub fn new(kv: K) -> Self {
        Self {
            repo: PriceSettingsRepository::new(kv),
            state: Currency::Brl,
        }
    }

    /// Current currency.
    pub fn state(&self) -> Currency {
        self.state
    }

    /// Currencies the picker shows.
    pub fn available_currencies() -> [CurrencyItem; 2] {
        [Currency::Brl, Currency::Usd].map(|c| CurrencyItem {
            icon: c.symbol(),
            code: c.code(),
            currency: c,
        })
    }

    /// True if `item` is the current currency.
    pub fn is_selected(&self, item: &CurrencyItem) -> bool {
        self.state == item.currency
    }

    /// Loads the saved currency. A read error gives BRL.
    pub async fn load(&mut self) -> Currency {
        self.state = self
            .repo
            .get_price_currency()
            .await
            .unwrap_or(Currency::Brl);
        self.state
    }

    /// Selects and saves `currency`. Returns `Ok(true)` when it changed; the caller then drops
    /// the price history cache. A save error restores the previous currency and is returned.
    pub async fn set_currency(&mut self, currency: Currency) -> Result<bool> {
        if self.state == currency {
            return Ok(false);
        }
        let previous = self.state;
        self.state = currency;
        if let Err(e) = self.repo.set_price_currency(currency).await {
            self.state = previous;
            return Err(e);
        }
        Ok(true)
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn repository_defaults_and_roundtrip() {
        let kv = MemoryKv::new();
        let repo = PriceSettingsRepository::new(kv.clone());
        block_on(async {
            assert_eq!(
                repo.get_price_service_config().await.unwrap(),
                PriceServiceConfig {
                    currency: Currency::Brl,
                    price_source: PriceSource::Coingecko
                }
            );
            assert!(repo.get_balance_visibility().await.unwrap());
            repo.set_price_currency(Currency::Usd).await.unwrap();
            repo.set_price_source(PriceSource::Binance).await.unwrap();
            repo.set_balance_visibility(false).await.unwrap();
            assert_eq!(kv.get("price_currency").await.unwrap().unwrap(), b"usd");
            assert_eq!(repo.get_price_currency().await.unwrap(), Currency::Usd);
            assert_eq!(
                repo.get_price_source().await.unwrap(),
                PriceSource::Coingecko
            );
            assert!(!repo.get_balance_visibility().await.unwrap());
            kv.put("price_currency", b"eur".to_vec()).await.unwrap();
            assert_eq!(repo.get_price_currency().await.unwrap(), Currency::Brl);
        });
    }

    #[test]
    fn controller_selects_and_persists() {
        let kv = MemoryKv::new();
        let mut c = CurrencyController::new(kv.clone());
        block_on(async {
            assert_eq!(c.load().await, Currency::Brl);
            assert!(!c.set_currency(Currency::Brl).await.unwrap());
            assert!(c.set_currency(Currency::Usd).await.unwrap());
            let mut again = CurrencyController::new(kv);
            assert_eq!(again.load().await, Currency::Usd);
        });
        let items = CurrencyController::<MemoryKv>::available_currencies();
        assert_eq!((items[0].icon, items[1].code), ("R$", "USD"));
        assert!(c.is_selected(&items[1]));
    }
}
