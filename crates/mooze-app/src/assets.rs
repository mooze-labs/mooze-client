//! Network-scoped display and approval metadata for the desktop testnet product.
use crate::dto::*;
pub const TEST_ASSET_ID: &str = "38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5";
pub fn testnet_asset_metadata(key: &AssetKeyDto) -> AssetMetadataDto {
    use mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET;
    let ticker = match (key.chain, key.asset_id.as_deref()) {
        (ChainDto::Bitcoin, None) => Some("BTC"),
        (ChainDto::Liquid, Some(LIQUID_TESTNET_POLICY_ASSET)) => Some("L-BTC"),
        (ChainDto::Liquid, Some(TEST_ASSET_ID)) => Some("TEST"),
        _ => None,
    };
    AssetMetadataDto { key: key.clone(), ticker: ticker.map(str::to_owned), precision: ticker.map(|_| 8), approved: ticker.is_some() }
}
pub fn holding(balance: &AssetBalanceDto) -> HoldingDto {
    let key = AssetKeyDto { chain: balance.chain, asset_id: balance.asset_id.clone() };
    HoldingDto { metadata: testnet_asset_metadata(&key), balance_units: balance.amount_sat.to_string(), available_units: None, pending_units: (balance.chain == ChainDto::Bitcoin).then(|| balance.pending_sat.to_string()) }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn testnet_catalog_is_exact() {
        let test = testnet_asset_metadata(&AssetKeyDto {chain: ChainDto::Liquid, asset_id: Some(TEST_ASSET_ID.into())});
        assert!(test.approved);
        assert_eq!(test.precision, Some(8));
        assert!(!testnet_asset_metadata(&AssetKeyDto {chain: ChainDto::Bitcoin, asset_id: Some(TEST_ASSET_ID.into())}).approved);
        assert!(!testnet_asset_metadata(&AssetKeyDto {chain: ChainDto::Liquid, asset_id: Some(mooze_core::domain::LBTC_ASSET_ID.into())}).approved);
        assert!(testnet_asset_metadata(&AssetKeyDto {chain: ChainDto::Liquid, asset_id: Some(mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET.into())}).approved);
        assert!(testnet_asset_metadata(&AssetKeyDto {chain: ChainDto::Bitcoin, asset_id: None}).approved);
    }
    #[test]
    fn unknown_large_holding_roundtrips() {
        let result = holding(&AssetBalanceDto {chain:ChainDto::Liquid,asset_id:Some("ab".repeat(32)),amount_sat:9_007_199_254_740_993,precision:8,ticker:Some("TEST".into()),pending_sat:0});
        let value = serde_json::to_value(result).unwrap();
        assert_eq!(value["balance_units"], "9007199254740993");
        assert!(value["metadata"]["precision"].is_null());
        assert_eq!(value["metadata"]["approved"],false);
        assert!(value["metadata"]["ticker"].is_null());
    }
}

pub fn approved_testnet_assets() -> Vec<AssetMetadataDto> {
    [AssetKeyDto{chain:ChainDto::Bitcoin,asset_id:None}, AssetKeyDto{chain:ChainDto::Liquid,asset_id:Some(mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET.into())}, AssetKeyDto{chain:ChainDto::Liquid,asset_id:Some(TEST_ASSET_ID.into())}].iter().map(testnet_asset_metadata).collect()
}
