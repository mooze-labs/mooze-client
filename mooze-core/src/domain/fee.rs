use serde::{Deserialize, Serialize};

use super::ChainId;

/// Fee priority the user picks.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum FeePriority {
    Low,
    #[default]
    Medium,
    High,
}

impl FeePriority {
    /// Confirmation target in blocks used for fee estimation.
    pub fn target_blocks(self) -> u16 {
        match self {
            FeePriority::Low => 6,
            FeePriority::Medium => 3,
            FeePriority::High => 1,
        }
    }
}

/// Fee estimate for one send.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FeeEstimate {
    pub chain: ChainId,
    pub priority: FeePriority,
    pub absolute_fee_sat: u64,
    pub fee_rate_sat_per_vbyte: Option<f64>,
    pub estimated_blocks: Option<u16>,
}
