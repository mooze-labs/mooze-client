use serde::{Deserialize, Serialize};

use super::ChainId;

/// Balance of one asset on one chain.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AssetBalance {
    pub chain: ChainId,
    /// Liquid asset id. `None` for on-chain bitcoin.
    pub asset_id: Option<String>,
    pub amount_sat: u64,
    pub precision: u8,
    pub ticker: Option<String>,
    /// Unconfirmed incoming amount, not part of `amount_sat`.
    pub pending_sat: u64,
}

/// Snapshot of all balances.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub struct Balance {
    pub assets: Vec<AssetBalance>,
    pub snapshot_at_ms: u64,
}

impl Balance {
    /// Sum of confirmed amounts on `chain`.
    pub fn total_sat_for_chain(&self, chain: ChainId) -> u64 {
        self.assets.iter().filter(|a| a.chain == chain).map(|a| a.amount_sat).sum()
    }

    /// Sum of pending amounts on `chain`.
    pub fn pending_sat_for_chain(&self, chain: ChainId) -> u64 {
        self.assets.iter().filter(|a| a.chain == chain).map(|a| a.pending_sat).sum()
    }

    /// Confirmed amount of one asset id, 0 if absent.
    pub fn amount_for_asset(&self, asset_id: &str) -> u64 {
        self.assets.iter().filter(|a| a.asset_id.as_deref() == Some(asset_id)).map(|a| a.amount_sat).sum()
    }
}
