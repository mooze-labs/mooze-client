//! Pending values to receive. Port of `values_to_receive_provider.dart`
//! (computation only; currency formatting is the `format` module's job).

use super::entities::User;
use crate::domain::{Asset, DEPIX_ASSET_ID, LBTC_ASSET_ID};

/// One asset with a pending amount.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct AssetToReceive {
    /// The asset.
    pub asset: Asset,
    /// BRL cents, as the API sends them.
    pub value_in_cents: i64,
    /// Value in the display currency (BRL, or USD through the rate).
    pub display_value: f64,
}

impl AssetToReceive {
    /// Value in BRL.
    pub fn value_in_reais(&self) -> f64 {
        self.value_in_cents as f64 / 100.0
    }
}

/// Maps a `to_receive` key to an asset. Only L-BTC and DePix are known, as in Dart.
pub fn asset_from_receive_id(id: &str) -> Option<Asset> {
    match id {
        LBTC_ASSET_ID => Some(Asset::Lbtc),
        DEPIX_ASSET_ID => Some(Asset::Depix),
        _ => None,
    }
}

/// Positive pending values of known assets, highest first.
///
/// `brl_to_usd_rate` is `Some` when the display currency is USD (Dart uses the
/// DePix fiat price). Rates that are not positive fall back to 1.0.
pub fn values_to_receive(user: &User, brl_to_usd_rate: Option<f64>) -> Vec<AssetToReceive> {
    let rate = brl_to_usd_rate.filter(|r| *r > 0.0).unwrap_or(1.0);
    let mut out: Vec<AssetToReceive> = user
        .values_to_receive
        .iter()
        .filter(|(_, cents)| **cents > 0)
        .filter_map(|(id, cents)| {
            asset_from_receive_id(id).map(|asset| AssetToReceive {
                asset,
                value_in_cents: *cents,
                display_value: *cents as f64 / 100.0 * rate,
            })
        })
        .collect();
    out.sort_by_key(|i| std::cmp::Reverse(i.value_in_cents));
    out
}

/// Sum of display values (Dart `totalValueToReceiveProvider`).
pub fn total_value_to_receive(items: &[AssetToReceive]) -> f64 {
    items.iter().map(|i| i.display_value).sum()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::user::entities::user_fixture;

    #[test]
    fn filters_sorts_and_converts() {
        let user = User::from_json(&user_fixture()).unwrap();
        let brl = values_to_receive(&user, None);
        assert_eq!(brl.len(), 2); // USDT is not mapped.
        assert_eq!(brl[0].asset, Asset::Depix);
        assert_eq!(brl[0].value_in_cents, 15000);
        assert_eq!(brl[0].display_value, 150.0);
        assert_eq!(brl[1].asset, Asset::Lbtc);
        assert_eq!(total_value_to_receive(&brl), 175.0);

        let usd = values_to_receive(&user, Some(0.2));
        assert_eq!(usd[0].display_value, 30.0);
        assert_eq!(values_to_receive(&user, Some(0.0))[0].display_value, 150.0);
    }

    #[test]
    fn skips_non_positive() {
        let mut user = User::from_json(&user_fixture()).unwrap();
        user.values_to_receive.insert(DEPIX_ASSET_ID.into(), 0);
        let v = values_to_receive(&user, None);
        assert_eq!(v.len(), 1);
        assert_eq!(v[0].value_in_reais(), 25.0);
    }
}
