use serde::{Deserialize, Serialize};

use super::{ChainId, FeePriority, Transaction};

/// Request to send funds on-chain.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SendRequest {
    pub chain: ChainId,
    pub destination: String,
    pub amount_sat: u64,
    /// Liquid asset id. `None` means the chain's native asset.
    pub asset_id: Option<String>,
    pub fee_priority: FeePriority,
    pub label: Option<String>,
    pub subtract_fee_from_amount: bool,
    pub fee_rate_override_sat_per_vbyte: Option<f64>,
    /// Send the whole balance of the asset.
    pub drain: bool,
}

impl SendRequest {
    /// Request with default options.
    pub fn new(chain: ChainId, destination: impl Into<String>, amount_sat: u64) -> Self {
        Self {
            chain,
            destination: destination.into(),
            amount_sat,
            asset_id: None,
            fee_priority: FeePriority::Medium,
            label: None,
            subtract_fee_from_amount: false,
            fee_rate_override_sat_per_vbyte: None,
            drain: false,
        }
    }
}

/// Result of a broadcast.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BroadcastResult {
    pub chain: ChainId,
    pub tx_id: String,
    pub transaction: Transaction,
    pub fee_paid_sat: Option<u64>,
}

/// Unsigned Liquid send, ready for review and signing.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LiquidSendDraft {
    /// Base64 PSET.
    pub pset: String,
    pub destination: String,
    pub amount_sat: u64,
    pub fee_sat: u64,
    pub fee_rate_sat_per_kvb: f64,
    pub drain: bool,
}

impl LiquidSendDraft {
    /// Amount plus fee.
    pub fn total_sat(&self) -> u64 {
        self.amount_sat + self.fee_sat
    }
}

/// Send and receive limits for a chain.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct PaymentLimits {
    pub chain: ChainId,
    pub send_min_sat: u64,
    pub send_max_sat: u64,
    pub receive_min_sat: Option<u64>,
    pub receive_max_sat: Option<u64>,
}
