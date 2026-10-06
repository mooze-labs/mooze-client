use serde::{Deserialize, Serialize};

use super::ChainId;

/// Pseudo asset id the app uses for on-chain bitcoin.
pub const BTC_ASSET_ID: &str = "btc-native-blockchain";
/// Liquid bitcoin asset id.
pub const LBTC_ASSET_ID: &str = "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d";
/// Tether USD on Liquid.
pub const USDT_ASSET_ID: &str = "ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2";
/// DePix on Liquid.
pub const DEPIX_ASSET_ID: &str = "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189";

/// Base units per whole unit. All four assets use precision 8.
pub const SATS_PER_UNIT: u64 = 100_000_000;

/// Assets the wallet supports.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Asset {
    Btc,
    Lbtc,
    Depix,
    Usdt,
}

impl Asset {
    /// Every supported asset, in display order.
    pub const ALL: [Asset; 4] = [Asset::Btc, Asset::Lbtc, Asset::Depix, Asset::Usdt];

    /// Asset id: Liquid asset hash, or [`BTC_ASSET_ID`] for bitcoin.
    pub fn id(self) -> &'static str {
        match self {
            Asset::Btc => BTC_ASSET_ID,
            Asset::Lbtc => LBTC_ASSET_ID,
            Asset::Usdt => USDT_ASSET_ID,
            Asset::Depix => DEPIX_ASSET_ID,
        }
    }

    /// Strict lookup by id. Unknown ids return `None`.
    pub fn from_id(id: &str) -> Option<Asset> {
        match id {
            BTC_ASSET_ID => Some(Asset::Btc),
            LBTC_ASSET_ID => Some(Asset::Lbtc),
            USDT_ASSET_ID => Some(Asset::Usdt),
            DEPIX_ASSET_ID => Some(Asset::Depix),
            _ => None,
        }
    }

    /// Short ticker shown in the UI.
    pub fn ticker(self) -> &'static str {
        match self {
            Asset::Usdt => "USDT",
            Asset::Depix => "Depix",
            Asset::Lbtc => "BTC L2",
            Asset::Btc => "BTC",
        }
    }

    /// Long name shown in the UI.
    pub fn name(self) -> &'static str {
        match self {
            Asset::Usdt => "USDt",
            Asset::Depix => "Decentralized Pix",
            Asset::Lbtc => "Bitcoin L2",
            Asset::Btc => "Bitcoin",
        }
    }

    /// Unit label next to an amount from `format::format_amount`.
    pub fn display_unit(self) -> &'static str {
        match self {
            Asset::Btc | Asset::Lbtc => "SATS",
            Asset::Usdt => "USDT",
            Asset::Depix => "DEPIX",
        }
    }

    /// Decimal places of the natural unit.
    pub fn precision(self) -> u8 {
        8
    }

    /// True for on-chain bitcoin.
    pub fn is_native_bitcoin(self) -> bool {
        self == Asset::Btc
    }

    /// True for BTC and L-BTC.
    pub fn is_bitcoin(self) -> bool {
        matches!(self, Asset::Btc | Asset::Lbtc)
    }

    /// Chain that holds the asset.
    pub fn chain(self) -> ChainId {
        match self {
            Asset::Btc => ChainId::Bitcoin,
            Asset::Lbtc | Asset::Usdt | Asset::Depix => ChainId::Liquid,
        }
    }

    /// Converts base units to whole units (BTC, USDT).
    pub fn to_units(self, sats: u64) -> f64 {
        sats as f64 / SATS_PER_UNIT as f64
    }

    /// Converts whole units to base units, rounded to nearest.
    pub fn from_units(self, units: f64) -> u64 {
        if units <= 0.0 || !units.is_finite() {
            return 0;
        }
        (units * SATS_PER_UNIT as f64).round() as u64
    }

    /// USD value of `sats` at `price_usd` per whole unit.
    pub fn to_usd(self, sats: u64, price_usd: f64) -> f64 {
        self.to_units(sats) * price_usd
    }

    /// Base units worth `usd` at `price_usd` per whole unit.
    pub fn from_usd(self, usd: f64, price_usd: f64) -> u64 {
        if price_usd <= 0.0 {
            return 0;
        }
        self.from_units(usd / price_usd)
    }

    /// Converts an amount of `self` into `target` through USD prices.
    pub fn convert_to(self, sats: u64, target: Asset, from_price_usd: f64, to_price_usd: f64) -> u64 {
        if self == target {
            return sats;
        }
        target.from_usd(self.to_usd(sats, from_price_usd), to_price_usd)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn id_roundtrip() {
        for a in Asset::ALL {
            assert_eq!(Asset::from_id(a.id()), Some(a));
        }
        assert_eq!(Asset::from_id("nope"), None);
    }

    #[test]
    fn conversions() {
        assert_eq!(Asset::Btc.from_units(1.5), 150_000_000);
        assert_eq!(Asset::Usdt.to_usd(250_000_000, 1.0), 2.5);
        // 0.001 BTC at 60k USD = 60 USDT
        assert_eq!(Asset::Lbtc.convert_to(100_000, Asset::Usdt, 60_000.0, 1.0), 6_000_000_000);
        assert_eq!(Asset::Btc.from_usd(10.0, 0.0), 0);
    }
}
