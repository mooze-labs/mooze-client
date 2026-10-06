//! Fiat prices for the wallet assets.
//!
//! Sources: Binance (`data-api.binance.vision`) and CoinGecko. [`CachedPriceService`] keeps the
//! last price in a [`KvStore`](crate::ports::KvStore). [`HybridPriceService`] falls back from the
//! primary source to the other one. [`PriceQuotesStore`] holds the quotes the UI shows.

mod binance;
mod cache;
mod coingecko;
mod hybrid;
mod quotes;
mod settings;

use std::future::Future;

use serde::{Deserialize, Serialize};

pub use binance::{
    BinanceClient, BinanceDailyPriceVariationService, BinancePriceService, BINANCE_API_URL, BINANCE_CACHE_TTL_MS,
    BINANCE_SYMBOLS,
};
pub use cache::{CachedPriceData, CachedPriceService, PriceCacheService, CACHE_KEY_PREFIX};
pub use coingecko::{CoingeckoPriceService, COINGECKO_BASE_URL};
pub use hybrid::{Connectivity, HybridPriceService, StandardHybridPriceService};
pub use quotes::{PriceQuote, PriceQuotes, PriceQuotesStore, PRICE_REFRESH_INTERVAL_MS, QUOTE_ASSETS};
pub use settings::{CurrencyController, CurrencyItem, PriceSettingsRepository};

use crate::domain::Asset;
use crate::ports::{MaybeSend, MaybeSync};
use crate::Result;

/// Fiat currency for prices.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum Currency {
    #[default]
    Brl,
    Usd,
}

impl Currency {
    /// Lower-case name. Used in URLs and storage keys.
    pub fn name(self) -> &'static str {
        match self {
            Currency::Brl => "brl",
            Currency::Usd => "usd",
        }
    }

    /// Upper-case code: `BRL`, `USD`.
    pub fn code(self) -> &'static str {
        match self {
            Currency::Brl => "BRL",
            Currency::Usd => "USD",
        }
    }

    /// Symbol: `R$` or `$`.
    pub fn symbol(self) -> &'static str {
        match self {
            Currency::Brl => "R$",
            Currency::Usd => "$",
        }
    }

    /// Case-insensitive lookup by code.
    pub fn from_code(code: &str) -> Option<Currency> {
        match code.to_lowercase().as_str() {
            "brl" => Some(Currency::Brl),
            "usd" => Some(Currency::Usd),
            _ => None,
        }
    }
}

/// Price provider.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum PriceSource {
    Binance,
    #[default]
    Coingecko,
}

impl PriceSource {
    /// Lower-case name.
    pub fn name(self) -> &'static str {
        match self {
            PriceSource::Binance => "binance",
            PriceSource::Coingecko => "coingecko",
        }
    }
}

/// Currency and source the user picked.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct PriceServiceConfig {
    pub currency: Currency,
    pub price_source: PriceSource,
}

/// Candle interval for Binance klines.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum KlineInterval {
    OneHour,
    FourHours,
    OneDay,
    OneWeek,
    OneMonth,
}

impl KlineInterval {
    /// Binance interval string.
    pub fn value(self) -> &'static str {
        match self {
            KlineInterval::OneHour => "1h",
            KlineInterval::FourHours => "4h",
            KlineInterval::OneDay => "1d",
            KlineInterval::OneWeek => "1w",
            KlineInterval::OneMonth => "1M",
        }
    }
}

/// Price of one asset in a fiat currency.
pub trait PriceService: MaybeSend + MaybeSync {
    /// Default currency of the service.
    fn currency(&self) -> Currency;

    /// Price of one whole unit of `asset`. `None` means no price is known.
    /// `currency` overrides the default currency.
    fn get_coin_price(
        &self,
        asset: Asset,
        currency: Option<Currency>,
    ) -> impl Future<Output = Result<Option<f64>>> + MaybeSend;
}

impl<T: PriceService + ?Sized> PriceService for std::sync::Arc<T> {
    fn currency(&self) -> Currency {
        (**self).currency()
    }
    fn get_coin_price(
        &self,
        asset: Asset,
        currency: Option<Currency>,
    ) -> impl Future<Output = Result<Option<f64>>> + MaybeSend {
        (**self).get_coin_price(asset, currency)
    }
}

/// Fixed prices for the pairs that need no request: DePix/BRL and USDT/USD are 1.0.
pub(crate) fn pegged_price(asset: Asset, currency: Currency) -> Option<f64> {
    match (asset, currency) {
        (Asset::Depix, Currency::Brl) | (Asset::Usdt, Currency::Usd) => Some(1.0),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn currency_codes() {
        assert_eq!(Currency::from_code("BRL"), Some(Currency::Brl));
        assert_eq!(Currency::from_code("usd"), Some(Currency::Usd));
        assert_eq!(Currency::from_code("eur"), None);
        assert_eq!(Currency::Brl.symbol(), "R$");
        assert_eq!(serde_json::to_string(&Currency::Usd).unwrap(), "\"usd\"");
        assert_eq!(KlineInterval::OneMonth.value(), "1M");
        assert_eq!(pegged_price(Asset::Depix, Currency::Brl), Some(1.0));
        assert_eq!(pegged_price(Asset::Depix, Currency::Usd), None);
    }
}
