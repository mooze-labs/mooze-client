use serde::{Deserialize, Serialize};

/// Unblinded Liquid output. SideSwap swaps need these.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LiquidUtxo {
    pub txid: String,
    pub vout: u32,
    pub asset_id: String,
    pub asset_blinding_factor: String,
    pub value_sat: u64,
    pub value_blinding_factor: String,
}
