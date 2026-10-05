use serde::{Deserialize, Serialize};

use super::ChainId;

/// Direction of a transaction from the wallet's point of view.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum TransactionDirection {
    Incoming,
    Outgoing,
    Internal,
    SelfTransfer,
    Swap,
}

/// Confirmation state.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TransactionStatus {
    Pending,
    Confirmed,
    Failed,
}

/// Backend that produced the record.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TransactionSource {
    Lwk,
    Breez,
    Bdk,
}

/// One wallet transaction. JSON field names match the Dart `toMap` keys,
/// so records written by the Flutter app read back unchanged.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Transaction {
    pub id: String,
    pub chain: ChainId,
    pub direction: TransactionDirection,
    pub status: TransactionStatus,
    /// Amount in base units. Signed to match the Dart `int`.
    pub amount_sat: i64,
    pub fee_sat: i64,
    pub timestamp_ms: u64,
    #[serde(default)]
    pub confirmations: u32,
    #[serde(default)]
    pub asset_id: Option<String>,
    #[serde(default)]
    pub address: Option<String>,
    #[serde(default)]
    pub label: Option<String>,
    #[serde(default)]
    pub from_asset_id: Option<String>,
    #[serde(default)]
    pub to_asset_id: Option<String>,
    #[serde(default)]
    pub sent_amount_sat: Option<i64>,
    #[serde(default)]
    pub received_amount_sat: Option<i64>,
    #[serde(default, deserialize_with = "lenient_source")]
    pub source: Option<TransactionSource>,
    #[serde(default)]
    pub swap_lockup_tx_id: Option<String>,
    #[serde(default)]
    pub swap_claim_tx_id: Option<String>,
    #[serde(default)]
    pub breez_swap_id: Option<String>,
}

/// Unknown source names map to `None`, like the Dart `fromMap`.
fn lenient_source<'de, D: serde::Deserializer<'de>>(d: D) -> Result<Option<TransactionSource>, D::Error> {
    let raw: Option<String> = Option::deserialize(d)?;
    Ok(raw.and_then(|s| serde_json::from_value(serde_json::Value::String(s)).ok()))
}

impl Transaction {
    /// Minimal record. Optional fields start empty.
    pub fn new(
        id: impl Into<String>,
        chain: ChainId,
        direction: TransactionDirection,
        status: TransactionStatus,
        amount_sat: i64,
        fee_sat: i64,
        timestamp_ms: u64,
    ) -> Self {
        Self {
            id: id.into(),
            chain,
            direction,
            status,
            amount_sat,
            fee_sat,
            timestamp_ms,
            confirmations: 0,
            asset_id: None,
            address: None,
            label: None,
            from_asset_id: None,
            to_asset_id: None,
            sent_amount_sat: None,
            received_amount_sat: None,
            source: None,
            swap_lockup_tx_id: None,
            swap_claim_tx_id: None,
            breez_swap_id: None,
        }
    }

    /// True if the record is confirmed.
    pub fn is_confirmed(&self) -> bool {
        self.status == TransactionStatus::Confirmed
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_dart_map() {
        let json = r#"{"id":"ab","chain":"liquid","direction":"selfTransfer","status":"pending",
            "amount_sat":1000,"fee_sat":30,"timestamp_ms":1700000000000,"confirmations":0,
            "asset_id":null,"source":"unknown_backend"}"#;
        let tx: Transaction = serde_json::from_str(json).unwrap();
        assert_eq!(tx.direction, TransactionDirection::SelfTransfer);
        assert_eq!(tx.source, None);
        let back = serde_json::to_value(&tx).unwrap();
        assert_eq!(back["direction"], "selfTransfer");
        assert_eq!(back["chain"], "liquid");
    }
}
