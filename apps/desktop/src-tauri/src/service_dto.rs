use serde::{Deserialize, Serialize};
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct BackendSessionDto {
    pub state: String,
    pub retryable: bool,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PixCreateRequestDto {
    pub amount_in_cents: String,
    pub asset_id: String,
    pub tax_id_number: String,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PixDepositViewDto {
    pub deposit_id: String,
    pub pix_key: String,
    pub asset_id: String,
    pub amount_in_cents: String,
    pub status: String,
    pub created_at_ms: u64,
    pub expires_at_ms: Option<u64>,
    pub blockchain_txid: Option<String>,
    pub asset_amount: Option<String>,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PixHistoryDto {
    pub deposits: Vec<PixDepositViewDto>,
    pub creation_uncertain: bool,
}
impl From<mooze_app::dto::PixDepositDto> for PixDepositViewDto {
    fn from(d: mooze_app::dto::PixDepositDto) -> Self {
        Self {
            deposit_id: d.deposit_id,
            pix_key: d.pix_key,
            asset_id: d.asset_id,
            amount_in_cents: d.amount_in_cents.to_string(),
            status: format!("{:?}", d.status),
            created_at_ms: d.created_at_ms,
            expires_at_ms: d
                .created_at_ms
                .checked_add(mooze_core::pix::rules::DEPOSIT_POLL_MAX_DURATION_MS),
            blockchain_txid: d.blockchain_txid,
            asset_amount: d.asset_amount.map(|v| v.to_string()),
        }
    }
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct SwapRequestDto {
    pub send_asset_id: String,
    pub receive_asset_id: String,
    pub amount_units: String,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct SwapReviewDto {
    pub id: String,
    pub generation: u32,
    pub send_asset_id: String,
    pub receive_asset_id: String,
    pub send_units: String,
    pub receive_units: String,
    pub fees: Vec<mooze_app::dto::AssetAmountDto>,
    pub expires_at_ms: u64,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct SwapStateDto {
    pub phase: String,
    pub review: Option<SwapReviewDto>,
    pub txid: Option<String>,
    pub message: Option<String>,
}
impl SwapStateDto {
    pub fn phase(phase: &str) -> Self {
        Self {
            phase: phase.into(),
            review: None,
            txid: None,
            message: None,
        }
    }
}
#[cfg(test)]
mod tests {
    #[test]
    fn pix_request_requires_payer_tax_id_on_the_wire() {
        assert!(serde_json::from_str::<super::PixCreateRequestDto>(
            r#"{"amount_in_cents":"100","asset_id":"depix"}"#
        )
        .is_err());
        assert!(serde_json::from_str::<super::PixCreateRequestDto>(
            r#"{"amount_in_cents":"100","asset_id":"depix","tax_id_number":null}"#
        )
        .is_err());
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct AccountTierDto {
    pub order: u32,
    pub key: String,
    pub minimum_brl: f64,
    pub maximum_brl: f64,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct AccountLevelDto {
    pub current_level: String,
    pub next_level: Option<String>,
    pub progress: f64,
    pub per_transaction_brl: f64,
    pub minimum_brl: f64,
    pub daily_limit_brl: f64,
    pub spent_today_brl: f64,
    pub remaining_today_brl: f64,
    pub tiers: Vec<AccountTierDto>,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum PriceMarketDto {
    Bitcoin,
    Tether,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PricePointDto {
    pub timestamp_ms: u64,
    pub price: f64,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PriceHistoryDto {
    pub points: Vec<PricePointDto>,
    pub source: String,
    pub fetched_at_ms: u64,
}
