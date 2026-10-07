//! Network-scoped display and approval metadata for desktop wallets.
use crate::dto::*;
pub const TEST_ASSET_ID: &str = "38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5";
pub fn testnet_asset_metadata(key: &AssetKeyDto) -> AssetMetadataDto {
    asset_metadata(NetworkDto::Testnet, key)
}
pub fn asset_metadata(network: NetworkDto, key: &AssetKeyDto) -> AssetMetadataDto {
    use mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET;
    let ticker = match (key.chain, key.asset_id.as_deref()) {
        (ChainDto::Bitcoin, None) => Some("BTC"),
        (ChainDto::Liquid, Some(LIQUID_TESTNET_POLICY_ASSET)) if network == NetworkDto::Testnet => Some("L-BTC"),
        (ChainDto::Liquid, Some(TEST_ASSET_ID)) if network == NetworkDto::Testnet => Some("TEST"),
        (ChainDto::Liquid, Some(id)) if network == NetworkDto::Mainnet => match id {
            mooze_core::domain::LBTC_ASSET_ID => Some("L-BTC"),
            mooze_core::domain::DEPIX_ASSET_ID => Some("DEPIX"),
            mooze_core::domain::USDT_ASSET_ID => Some("USDT"),
            _ => None,
        },
        _ => None,
    };
    AssetMetadataDto {
        key: key.clone(),
        ticker: ticker.map(str::to_owned),
        precision: ticker.map(|_| 8),
        approved: ticker.is_some(),
    }
}
pub fn holding(balance: &AssetBalanceDto) -> HoldingDto {
    holding_for_network(NetworkDto::Testnet, balance)
}
pub fn holding_for_network(network: NetworkDto, balance: &AssetBalanceDto) -> HoldingDto {
    let key = AssetKeyDto { chain: balance.chain, asset_id: balance.asset_id.clone() };
    HoldingDto {
        metadata: asset_metadata(network, &key),
        balance_units: balance.amount_sat.to_string(),
        available_units: None,
        pending_units: (balance.chain == ChainDto::Bitcoin).then(|| balance.pending_sat.to_string()),
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn testnet_catalog_is_exact() {
        let test =
            testnet_asset_metadata(&AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some(TEST_ASSET_ID.into()) });
        assert!(test.approved);
        assert_eq!(test.precision, Some(8));
        assert!(
            !testnet_asset_metadata(&AssetKeyDto { chain: ChainDto::Bitcoin, asset_id: Some(TEST_ASSET_ID.into()) })
                .approved
        );
        assert!(
            !testnet_asset_metadata(&AssetKeyDto {
                chain: ChainDto::Liquid,
                asset_id: Some(mooze_core::domain::LBTC_ASSET_ID.into())
            })
            .approved
        );
        assert!(
            testnet_asset_metadata(&AssetKeyDto {
                chain: ChainDto::Liquid,
                asset_id: Some(mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET.into())
            })
            .approved
        );
        assert!(testnet_asset_metadata(&AssetKeyDto { chain: ChainDto::Bitcoin, asset_id: None }).approved);
    }
    #[test]
    fn unknown_large_holding_roundtrips() {
        let result = holding(&AssetBalanceDto {
            chain: ChainDto::Liquid,
            asset_id: Some("ab".repeat(32)),
            amount_sat: 9_007_199_254_740_993,
            precision: 8,
            ticker: Some("TEST".into()),
            pending_sat: 0,
        });
        let value = serde_json::to_value(result).unwrap();
        assert_eq!(value["balance_units"], "9007199254740993");
        assert!(value["metadata"]["precision"].is_null());
        assert_eq!(value["metadata"]["approved"], false);
        assert!(value["metadata"]["ticker"].is_null());
    }
}

pub fn approved_assets(network: NetworkDto) -> Vec<AssetMetadataDto> {
    if network == NetworkDto::Mainnet {
        return mooze_core::domain::Asset::ALL
            .iter()
            .map(|asset| {
                asset_metadata(
                    network,
                    &AssetKeyDto {
                        chain: if asset.is_native_bitcoin() { ChainDto::Bitcoin } else { ChainDto::Liquid },
                        asset_id: (!asset.is_native_bitcoin()).then(|| asset.id().to_owned()),
                    },
                )
            })
            .collect();
    }
    if network == NetworkDto::Regtest {
        return vec![asset_metadata(network, &AssetKeyDto { chain: ChainDto::Bitcoin, asset_id: None })];
    }
    approved_testnet_assets()
}
pub fn approved_testnet_assets() -> Vec<AssetMetadataDto> {
    [
        AssetKeyDto { chain: ChainDto::Bitcoin, asset_id: None },
        AssetKeyDto {
            chain: ChainDto::Liquid,
            asset_id: Some(mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET.into()),
        },
        AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some(TEST_ASSET_ID.into()) },
    ]
    .iter()
    .map(testnet_asset_metadata)
    .collect()
}

#[cfg(test)]
mod historical_tests {
    use super::*;
    #[test]
    fn historical_unknown_asset_stays_visible_at_zero() {
        let key = AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some("ab".repeat(32)) };
        let rows = include_historical_assets(vec![], [key.clone(), key.clone()]);
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].metadata.key, key);
        assert_eq!(rows[0].balance_units, "0");
        assert!(!rows[0].metadata.approved);
        assert!(rows[0].metadata.precision.is_none());
    }
}

/// Keep previously held assets discoverable after their last output is spent.
/// Catalog metadata is derived from identity, never historical ticker hints.
pub fn include_historical_assets(
    rows: Vec<HoldingDto>,
    keys: impl IntoIterator<Item = AssetKeyDto>,
) -> Vec<HoldingDto> {
    include_historical_assets_for_network(NetworkDto::Testnet, rows, keys)
}
pub fn include_historical_assets_for_network(
    network: NetworkDto,
    mut rows: Vec<HoldingDto>,
    keys: impl IntoIterator<Item = AssetKeyDto>,
) -> Vec<HoldingDto> {
    for key in keys {
        if !rows.iter().any(|row| row.metadata.key == key) {
            rows.push(HoldingDto {
                metadata: asset_metadata(network, &key),
                balance_units: "0".into(),
                available_units: None,
                pending_units: None,
            });
        }
    }
    rows
}

#[cfg(test)]
mod mainnet_tests {
    use super::*;
    #[test]
    fn mainnet_catalog_is_network_scoped_and_exact() {
        let rows = approved_assets(NetworkDto::Mainnet);
        assert_eq!(rows.len(), 4);
        for asset in mooze_core::domain::Asset::ALL {
            let key = AssetKeyDto {
                chain: if asset.is_native_bitcoin() { ChainDto::Bitcoin } else { ChainDto::Liquid },
                asset_id: (!asset.is_native_bitcoin()).then(|| asset.id().into()),
            };
            let metadata = asset_metadata(NetworkDto::Mainnet, &key);
            assert!(metadata.approved);
            assert_eq!(metadata.precision, Some(asset.precision()));
        }
        assert!(
            !asset_metadata(
                NetworkDto::Mainnet,
                &AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some(TEST_ASSET_ID.into()) }
            )
            .approved
        );
        assert!(
            !asset_metadata(
                NetworkDto::Testnet,
                &AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some(mooze_core::domain::DEPIX_ASSET_ID.into()) }
            )
            .approved
        );
    }
}
