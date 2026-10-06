//! Exact desktop activity projections, before the legacy single-asset mapping.
#[cfg(test)]
mod tests {
    use super::*;
    use mooze_core::wallet::liquid::classify::{LwkBalance, LwkTxOut, LwkTxView};
    #[test]
    fn multi_asset_movement_has_one_separate_fee() {
        let policy = mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET;
        let view = LwkTxView {
            txid: "tx".into(),
            height: Some(100),
            timestamp_s: Some(10),
            fee: 100,
            kind: "outgoing".into(),
            balances: vec![
                LwkBalance { asset_id: crate::assets::TEST_ASSET_ID.into(), value: -100_000_000 },
                LwkBalance { asset_id: policy.into(), value: -100 },
            ],
            inputs: vec![LwkTxOut { asset_id: policy.into(), value: 100 }],
            outputs: vec![],
        };
        let row = liquid_activity(&view, 105, policy);
        assert_eq!(row.movements.len(), 2);
        assert_eq!(row.movements[0].delta_units, "-100000000");
        assert_eq!(row.movements[1].delta_units, "0");
        assert_eq!(row.fee.unwrap().units, "100");
        assert_eq!(row.confirmations, 6);
    }
}
use crate::dto::*;
use mooze_core::wallet::{bitcoin::BdkTxView, liquid::classify::LwkTxView};
fn confirmations(height: Option<u32>, tip: u32) -> u32 {
    height.map(|h| tip.saturating_sub(h) + 1).unwrap_or(0)
}
pub fn bitcoin_activity(t: &BdkTxView, tip: u32) -> WalletActivityDto {
    let fee = if t.sent_sat > 0 { t.fee_sat } else { None };
    let delta = t.received_sat as i128 - t.sent_sat as i128 + fee.unwrap_or(0) as i128;
    let asset = AssetKeyDto { chain: ChainDto::Bitcoin, asset_id: None };
    WalletActivityDto {
        id: t.txid.clone(),
        chain: ChainDto::Bitcoin,
        timestamp_ms: t.confirmation_time_s.map(|v| v * 1000),
        status: if t.is_confirmed() { StatusDto::Confirmed } else { StatusDto::Pending },
        confirmations: confirmations(t.confirmation_height, tip),
        movements: vec![AssetMovementDto { asset: asset.clone(), delta_units: delta.to_string() }],
        fee: fee.map(|f| AssetAmountDto { asset, units: f.to_string() }),
        addresses: vec![],
    }
}
pub fn liquid_activity(t: &LwkTxView, tip: u32, policy: &str) -> WalletActivityDto {
    let paid = t.inputs.iter().any(|input| input.asset_id == policy);
    let mut movements: Vec<_> = t
        .balances
        .iter()
        .map(|b| AssetMovementDto {
            asset: AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some(b.asset_id.clone()) },
            delta_units: (b.value as i128 + if paid && b.asset_id == policy { t.fee as i128 } else { 0 }).to_string(),
        })
        .collect();
    if paid && !t.balances.iter().any(|b| b.asset_id == policy) {
        movements.push(AssetMovementDto {
            asset: AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some(policy.into()) },
            delta_units: t.fee.to_string(),
        });
    }
    WalletActivityDto {
        id: t.txid.clone(),
        chain: ChainDto::Liquid,
        timestamp_ms: t.timestamp_s.map(|v| v * 1000),
        status: if t.height.is_some() { StatusDto::Confirmed } else { StatusDto::Pending },
        confirmations: confirmations(t.height, tip),
        movements,
        fee: paid.then(|| AssetAmountDto {
            asset: AssetKeyDto { chain: ChainDto::Liquid, asset_id: Some(policy.into()) },
            units: t.fee.to_string(),
        }),
        addresses: vec![],
    }
}

#[cfg(test)]
mod projection_tests {
    use super::*;
    use mooze_core::wallet::liquid::classify::{LwkBalance, LwkTxOut};
    #[test]
    fn incoming_asset_does_not_claim_sender_fee() {
        let policy = mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET;
        let t = LwkTxView {
            txid: "incoming".into(),
            height: None,
            timestamp_s: None,
            fee: 100,
            kind: "incoming".into(),
            balances: vec![LwkBalance { asset_id: crate::assets::TEST_ASSET_ID.into(), value: 1 }],
            inputs: vec![],
            outputs: vec![LwkTxOut { asset_id: crate::assets::TEST_ASSET_ID.into(), value: 1 }],
        };
        let row = liquid_activity(&t, 100, policy);
        assert!(row.timestamp_ms.is_none());
        assert!(row.fee.is_none());
        assert_eq!(row.movements[0].delta_units, "1");
        assert_eq!(row.confirmations, 0);
    }
    #[test]
    fn self_transfer_separates_fee_from_zero_movement() {
        let policy = mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET;
        let t = LwkTxView {
            txid: "self".into(),
            height: Some(9),
            timestamp_s: None,
            fee: 100,
            kind: "redeposit".into(),
            balances: vec![LwkBalance { asset_id: policy.into(), value: -100 }],
            inputs: vec![LwkTxOut { asset_id: policy.into(), value: 1000 }],
            outputs: vec![LwkTxOut { asset_id: policy.into(), value: 900 }],
        };
        let row = liquid_activity(&t, 10, policy);
        assert_eq!(row.movements[0].delta_units, "0");
        assert_eq!(row.fee.unwrap().units, "100");
    }
}
