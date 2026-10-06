//! Pure mapping of LWK data to domain types.

use crate::domain::{
    AssetBalance, Balance, ChainId, Transaction, TransactionDirection, TransactionSource, TransactionStatus,
    LBTC_ASSET_ID,
};

const CHAIN: ChainId = ChainId::Liquid;

/// Net change of one asset in a transaction, wallet side.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LwkBalance {
    pub asset_id: String,
    pub value: i64,
}

/// One unblinded wallet output (or spent wallet input).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LwkTxOut {
    pub asset_id: String,
    pub value: u64,
}

/// Flat view of an LWK wallet transaction.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LwkTxView {
    pub txid: String,
    pub height: Option<u32>,
    /// Block time in seconds, when confirmed.
    pub timestamp_s: Option<u64>,
    /// Fee in L-BTC sats.
    pub fee: u64,
    /// LWK type: incoming, outgoing, redeposit, issuance, reissuance, burn, unknown.
    pub kind: String,
    /// Net balance per asset, in LWK order (sorted by asset id).
    pub balances: Vec<LwkBalance>,
    /// Wallet-owned inputs.
    pub inputs: Vec<LwkTxOut>,
    /// Wallet-owned outputs.
    pub outputs: Vec<LwkTxOut>,
}

impl LwkTxView {
    /// Builds the view from an LWK wallet transaction.
    pub fn from_wallet_tx(t: &lwk_wollet::WalletTx) -> Self {
        let txout = |o: &lwk_wollet::WalletTxOut| LwkTxOut {
            asset_id: o.unblinded.asset.to_string(),
            value: o.unblinded.value,
        };
        Self {
            txid: t.txid.to_string(),
            height: t.height,
            timestamp_s: t.timestamp.map(u64::from),
            fee: t.fee,
            kind: t.type_.clone(),
            balances: t.balance.iter().map(|(a, v)| LwkBalance { asset_id: a.to_string(), value: *v }).collect(),
            inputs: t.inputs.iter().flatten().map(txout).collect(),
            outputs: t.outputs.iter().flatten().map(txout).collect(),
        }
    }
}

/// Item with the largest key. Ties keep the later item.
fn reduce_max<'a, T>(items: &[&'a T], key: impl Fn(&T) -> i64) -> &'a T {
    let mut acc = items[0];
    for b in &items[1..] {
        if key(acc) <= key(b) {
            acc = b;
        }
    }
    acc
}

/// Headline balance: the single entry, else the largest non-L-BTC entry,
/// else the largest entry (by absolute value).
fn pick_main<'a>(balances: &[&'a LwkBalance], policy_asset: &str) -> &'a LwkBalance {
    if balances.len() == 1 {
        return balances[0];
    }
    let non_lbtc: Vec<&LwkBalance> = balances.iter().copied().filter(|b| b.asset_id != policy_asset).collect();
    if !non_lbtc.is_empty() {
        return reduce_max(&non_lbtc, |b| b.value.abs());
    }
    reduce_max(balances, |b| b.value.abs())
}

/// The non-L-BTC asset that moved the most (gross of inputs or outputs).
fn self_transfer_subject(t: &LwkTxView, policy_asset: &str) -> Option<(String, i64)> {
    let mut candidates: Vec<&str> = Vec::new();
    let ids = t
        .balances
        .iter()
        .map(|b| b.asset_id.as_str())
        .chain(t.outputs.iter().map(|o| o.asset_id.as_str()))
        .chain(t.inputs.iter().map(|o| o.asset_id.as_str()));
    for id in ids {
        if id != policy_asset && !candidates.contains(&id) {
            candidates.push(id);
        }
    }
    let mut winner: Option<&str> = None;
    let mut winner_gross: i64 = 0;
    for id in candidates {
        let sum = |v: &[LwkTxOut]| v.iter().filter(|o| o.asset_id == id).map(|o| o.value as i64).sum::<i64>();
        let gross = sum(&t.inputs).max(sum(&t.outputs));
        if gross > winner_gross {
            winner_gross = gross;
            winner = Some(id);
        }
    }
    match winner {
        Some(id) if winner_gross != 0 => Some((id.to_owned(), winner_gross)),
        _ => None,
    }
}

/// Classifies an LWK transaction with rules P1 to P7.
///
pub fn map_tx(t: &LwkTxView, now_ms: u64) -> Transaction {
    map_tx_with_policy(t, now_ms, LBTC_ASSET_ID)
}

/// Maps transactions using the fee asset of the wallet's network.
pub fn map_tx_with_policy(t: &LwkTxView, now_ms: u64, policy_asset: &str) -> Transaction {
    let fee = t.fee as i64;
    let status = if t.height.is_some() { TransactionStatus::Confirmed } else { TransactionStatus::Pending };
    let ts = t.timestamp_s.map(|s| s * 1000).unwrap_or(now_ms);

    let non_zero: Vec<&LwkBalance> = t.balances.iter().filter(|b| b.value != 0).collect();
    let positives: Vec<&LwkBalance> = non_zero.iter().copied().filter(|b| b.value > 0).collect();
    let negatives: Vec<&LwkBalance> = non_zero.iter().copied().filter(|b| b.value < 0).collect();
    let mut unique: Vec<&str> = Vec::new();
    for b in &non_zero {
        if !unique.contains(&b.asset_id.as_str()) {
            unique.push(&b.asset_id);
        }
    }

    let mut from_asset = None;
    let mut to_asset = None;
    let mut sent = None;
    let mut received = None;

    let self_transfer = || {
        let subject = self_transfer_subject(t, policy_asset);
        let amount = subject.as_ref().map(|s| s.1).unwrap_or(fee);
        let asset = subject.map(|s| s.0).unwrap_or_else(|| policy_asset.to_owned());
        (TransactionDirection::SelfTransfer, amount, Some(asset))
    };

    let (direction, amount, main_asset): (TransactionDirection, i64, Option<String>) = if t.kind == "redeposit" {
        // P1: explicit LWK redeposit.
        self_transfer()
    } else if non_zero.is_empty() && fee > 0 {
        // P2: nothing moved net, a fee was paid.
        self_transfer()
    } else if non_zero.len() == 1 && non_zero[0].asset_id == policy_asset && non_zero[0].value == -fee && fee > 0 {
        // P3: only the L-BTC fee left the wallet.
        self_transfer()
    } else if !positives.is_empty() && !negatives.is_empty() && unique.len() >= 2 {
        // P4: mixed signs over two or more assets: swap.
        let pos_non_lbtc: Vec<&LwkBalance> = positives.iter().copied().filter(|b| b.asset_id != policy_asset).collect();
        let neg_non_lbtc: Vec<&LwkBalance> = negatives.iter().copied().filter(|b| b.asset_id != policy_asset).collect();
        let to = reduce_max(if pos_non_lbtc.is_empty() { &positives } else { &pos_non_lbtc }, |b| b.value);
        let from = reduce_max(if neg_non_lbtc.is_empty() { &negatives } else { &neg_non_lbtc }, |b| b.value.abs());
        from_asset = Some(from.asset_id.clone());
        to_asset = Some(to.asset_id.clone());
        sent = Some(from.value.abs());
        received = Some(to.value);
        (TransactionDirection::Swap, from.value.abs(), Some(from.asset_id.clone()))
    } else if !non_zero.is_empty() && non_zero.iter().all(|b| b.value > 0) {
        // P5: pure incoming.
        let main = pick_main(&non_zero, policy_asset);
        (TransactionDirection::Incoming, main.value.abs(), Some(main.asset_id.clone()))
    } else if !non_zero.is_empty() && non_zero.iter().all(|b| b.value < 0) {
        // P6: pure outgoing.
        let main = pick_main(&non_zero, policy_asset);
        (TransactionDirection::Outgoing, main.value.abs(), Some(main.asset_id.clone()))
    } else {
        // P7: catch-all (issuance, burn, unknown).
        let source: Vec<&LwkBalance> = if non_zero.is_empty() { t.balances.iter().collect() } else { non_zero.clone() };
        if source.is_empty() {
            (TransactionDirection::Internal, 0, None)
        } else {
            let main = pick_main(&source, policy_asset);
            (TransactionDirection::Internal, main.value.abs(), Some(main.asset_id.clone()))
        }
    };

    let mut tx = Transaction::new(t.txid.clone(), CHAIN, direction, status, amount, fee, ts);
    tx.confirmations = if t.height.is_some() { 1 } else { 0 };
    tx.asset_id = main_asset;
    tx.from_asset_id = from_asset;
    tx.to_asset_id = to_asset;
    tx.sent_amount_sat = sent;
    tx.received_amount_sat = received;
    tx.source = Some(TransactionSource::Lwk);
    tx
}

/// Maps LWK balances (asset id, sats).
pub fn map_balance(balances: &[(String, u64)], now_ms: u64) -> Balance {
    Balance {
        assets: balances
            .iter()
            .map(|(id, v)| AssetBalance {
                chain: CHAIN,
                asset_id: Some(id.clone()),
                amount_sat: *v,
                precision: 8,
                ticker: None,
                pending_sat: 0,
            })
            .collect(),
        snapshot_at_ms: now_ms,
    }
}

/// Applies per-asset deltas to a cached balance for instant UI feedback.
/// Amounts floor at zero. Only a positive delta adds a new asset.
/// Empty deltas return `prev`.
pub fn apply_optimistic_delta(prev: &Balance, deltas: &[(String, i64)], now_ms: u64) -> Balance {
    if deltas.is_empty() {
        return prev.clone();
    }
    let mut by_id: Vec<AssetBalance> = Vec::new();
    for ab in &prev.assets {
        match by_id.iter_mut().find(|x| x.asset_id == ab.asset_id) {
            Some(slot) => *slot = ab.clone(),
            None => by_id.push(ab.clone()),
        }
    }
    for (asset_id, delta) in deltas {
        match by_id.iter_mut().find(|x| x.asset_id.as_deref() == Some(asset_id.as_str())) {
            Some(existing) => {
                let next = existing.amount_sat as i64 + delta;
                existing.amount_sat = next.max(0) as u64;
            }
            None if *delta > 0 => by_id.push(AssetBalance {
                chain: CHAIN,
                asset_id: Some(asset_id.clone()),
                amount_sat: *delta as u64,
                precision: 8,
                ticker: if asset_id == LBTC_ASSET_ID { Some("L-BTC".to_owned()) } else { None },
                pending_sat: 0,
            }),
            None => {}
        }
    }
    Balance { assets: by_id, snapshot_at_ms: now_ms }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{DEPIX_ASSET_ID, USDT_ASSET_ID};

    fn bal(id: &str, v: i64) -> LwkBalance {
        LwkBalance { asset_id: id.into(), value: v }
    }
    fn out(id: &str, v: u64) -> LwkTxOut {
        LwkTxOut { asset_id: id.into(), value: v }
    }
    fn view(kind: &str, fee: u64, balances: Vec<LwkBalance>) -> LwkTxView {
        LwkTxView {
            txid: "tx".into(),
            height: Some(10),
            timestamp_s: Some(1_700_000_000),
            fee,
            kind: kind.into(),
            balances,
            inputs: vec![],
            outputs: vec![],
        }
    }

    #[test]
    fn testnet_policy_asset_is_used_for_fee_only_and_asset_selection() {
        let policy = crate::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET;
        let fee_only = map_tx_with_policy(&view("unknown", 26, vec![bal(policy, -26)]), 1, policy);
        assert_eq!(fee_only.direction, TransactionDirection::SelfTransfer);
        assert_eq!(fee_only.asset_id.as_deref(), Some(policy));
        let outgoing =
            map_tx_with_policy(&view("outgoing", 500, vec![bal(policy, -500), bal("custom", -20)]), 1, policy);
        assert_eq!(outgoing.asset_id.as_deref(), Some("custom"));
        assert_eq!(outgoing.amount_sat, 20);
    }

    #[test]
    fn incoming_and_outgoing_prefer_non_lbtc() {
        let t = map_tx(&view("incoming", 0, vec![bal(LBTC_ASSET_ID, 5_000)]), 1);
        assert_eq!(
            (t.direction, t.amount_sat, t.asset_id.as_deref()),
            (TransactionDirection::Incoming, 5_000, Some(LBTC_ASSET_ID))
        );
        assert_eq!((t.status, t.confirmations, t.timestamp_ms), (TransactionStatus::Confirmed, 1, 1_700_000_000_000));
        assert_eq!(t.source, Some(TransactionSource::Lwk));

        let t = map_tx(&view("outgoing", 30, vec![bal(LBTC_ASSET_ID, -30), bal(USDT_ASSET_ID, -100_000_000)]), 1);
        assert_eq!(
            (t.direction, t.amount_sat, t.asset_id.as_deref()),
            (TransactionDirection::Outgoing, 100_000_000, Some(USDT_ASSET_ID))
        );
        assert_eq!(t.fee_sat, 30);
    }

    #[test]
    fn pending_uses_now() {
        let mut v = view("incoming", 0, vec![bal(LBTC_ASSET_ID, 1)]);
        v.height = None;
        v.timestamp_s = None;
        let t = map_tx(&v, 42);
        assert_eq!((t.status, t.confirmations, t.timestamp_ms), (TransactionStatus::Pending, 0, 42));
    }

    #[test]
    fn redeposit_and_fee_only_are_self_transfers() {
        let t = map_tx(&view("redeposit", 26, vec![bal(LBTC_ASSET_ID, -26)]), 1);
        assert_eq!(
            (t.direction, t.amount_sat, t.asset_id.as_deref()),
            (TransactionDirection::SelfTransfer, 26, Some(LBTC_ASSET_ID))
        );

        let t = map_tx(&view("unknown", 26, vec![]), 1);
        assert_eq!((t.direction, t.amount_sat), (TransactionDirection::SelfTransfer, 26));

        // P3 with a USDT subject on inputs/outputs.
        let mut v = view("outgoing", 26, vec![bal(LBTC_ASSET_ID, -26), bal(USDT_ASSET_ID, 0)]);
        v.inputs = vec![out(USDT_ASSET_ID, 700), out(LBTC_ASSET_ID, 1_000)];
        v.outputs = vec![out(USDT_ASSET_ID, 300), out(USDT_ASSET_ID, 400), out(LBTC_ASSET_ID, 974)];
        let t = map_tx(&v, 1);
        assert_eq!(
            (t.direction, t.amount_sat, t.asset_id.as_deref()),
            (TransactionDirection::SelfTransfer, 700, Some(USDT_ASSET_ID))
        );
    }

    #[test]
    fn mixed_signs_are_swaps() {
        let t = map_tx(&view("unknown", 40, vec![bal(LBTC_ASSET_ID, -100_040), bal(USDT_ASSET_ID, 60_000_000)]), 1);
        assert_eq!(t.direction, TransactionDirection::Swap);
        assert_eq!(t.from_asset_id.as_deref(), Some(LBTC_ASSET_ID));
        assert_eq!(t.to_asset_id.as_deref(), Some(USDT_ASSET_ID));
        assert_eq!((t.sent_amount_sat, t.received_amount_sat), (Some(100_040), Some(60_000_000)));
        assert_eq!((t.amount_sat, t.asset_id.as_deref()), (100_040, Some(LBTC_ASSET_ID)));

        // Non-L-BTC legs win over the L-BTC fee leg.
        let t = map_tx(
            &view("unknown", 40, vec![bal(LBTC_ASSET_ID, -40), bal(DEPIX_ASSET_ID, -500), bal(USDT_ASSET_ID, 90)]),
            1,
        );
        assert_eq!(t.from_asset_id.as_deref(), Some(DEPIX_ASSET_ID));
        assert_eq!(t.to_asset_id.as_deref(), Some(USDT_ASSET_ID));
    }

    #[test]
    fn catch_all_and_ties() {
        // Zero balances, zero fee: internal with the first-picked zero entry.
        let t = map_tx(&view("unknown", 0, vec![bal(LBTC_ASSET_ID, 0)]), 1);
        assert_eq!(
            (t.direction, t.amount_sat, t.asset_id.as_deref()),
            (TransactionDirection::Internal, 0, Some(LBTC_ASSET_ID))
        );
        let t = map_tx(&view("unknown", 0, vec![]), 1);
        assert_eq!((t.direction, t.asset_id), (TransactionDirection::Internal, None));
        // Tie between two non-L-BTC incoming assets keeps the later one.
        let t = map_tx(&view("incoming", 0, vec![bal(DEPIX_ASSET_ID, 5), bal(USDT_ASSET_ID, 5)]), 1);
        assert_eq!(t.asset_id.as_deref(), Some(USDT_ASSET_ID));
    }

    #[test]
    fn balance_and_optimistic_delta() {
        let b = map_balance(&[(LBTC_ASSET_ID.into(), 1_000), (USDT_ASSET_ID.into(), 50)], 3);
        assert_eq!(b.amount_for_asset(LBTC_ASSET_ID), 1_000);
        assert_eq!(b.assets[0].precision, 8);
        assert_eq!(apply_optimistic_delta(&b, &[], 9), b);

        let d = apply_optimistic_delta(
            &b,
            &[(LBTC_ASSET_ID.into(), -2_000), (USDT_ASSET_ID.into(), 25), (DEPIX_ASSET_ID.into(), 7), ("x".into(), -1)],
            9,
        );
        assert_eq!(d.amount_for_asset(LBTC_ASSET_ID), 0);
        assert_eq!(d.amount_for_asset(USDT_ASSET_ID), 75);
        assert_eq!(d.amount_for_asset(DEPIX_ASSET_ID), 7);
        assert_eq!(d.assets.len(), 3);
        assert_eq!(d.snapshot_at_ms, 9);

        let fresh = apply_optimistic_delta(&Balance::default(), &[(LBTC_ASSET_ID.into(), 5)], 1);
        assert_eq!(fresh.assets[0].ticker.as_deref(), Some("L-BTC"));
    }
}
