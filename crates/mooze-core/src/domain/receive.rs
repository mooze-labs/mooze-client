use serde::{Deserialize, Serialize};

use super::ChainId;

/// Address or invoice to receive funds.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReceiveAddress {
    pub chain: ChainId,
    pub address: Option<String>,
    pub bolt11: Option<String>,
    pub asset_id: Option<String>,
    pub label: Option<String>,
    pub expires_at_ms: Option<u64>,
    pub amount_sat: Option<u64>,
}

impl ReceiveAddress {
    /// On-chain address without amount or label.
    pub fn onchain(chain: ChainId, address: impl Into<String>) -> Self {
        Self {
            chain,
            address: Some(address.into()),
            bolt11: None,
            asset_id: None,
            label: None,
            expires_at_ms: None,
            amount_sat: None,
        }
    }

    /// True for Lightning invoices.
    pub fn is_lightning(&self) -> bool {
        self.chain == ChainId::Lightning
    }
}
