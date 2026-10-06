//! Additive exact-amount projections; legacy mobile DTOs stay compatible.
use super::ChainDto;
use serde::{Deserialize, Serialize};
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct AssetKeyDto {
    pub chain: ChainDto,
    pub asset_id: Option<String>,
}
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct AssetMetadataDto {
    pub key: AssetKeyDto,
    pub ticker: Option<String>,
    pub precision: Option<u8>,
    pub approved: bool,
}
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct AssetAmountDto {
    pub asset: AssetKeyDto,
    pub units: String,
}
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct HoldingDto {
    pub metadata: AssetMetadataDto,
    pub balance_units: String,
    pub available_units: Option<String>,
    pub pending_units: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct AssetMovementDto {
    pub asset: AssetKeyDto,
    pub delta_units: String,
}
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct WalletActivityDto {
    pub id: String,
    pub chain: ChainDto,
    pub timestamp_ms: Option<u64>,
    pub status: super::StatusDto,
    pub confirmations: u32,
    pub movements: Vec<AssetMovementDto>,
    pub fee: Option<AssetAmountDto>,
    pub addresses: Vec<String>,
}
