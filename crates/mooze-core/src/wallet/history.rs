//! Pure history and balance logic over domain records.
//!
//! - [`pair_internal_swaps`]: port of `_identifyInternalSwapsStatic` in
//!   `wallet_repository_impl.dart` (BTC <-> L-BTC send/receive pairs).
//! - [`resolve_asset_balance`], [`balance_map`], [`aggregate_balance`]:
//!   port of the balance helpers in `data/v2/wallet_repository_impl.dart`.
//! - [`summarize_activity`]: port of `AssetActivityCalculator`.
//!
//! NOTE(port): the Dart pairing and calculator run on the legacy
//! `Transaction` entity. Here they run on `domain::Transaction`: "send" is
//! `Outgoing`, "receive" is `Incoming`, the asset comes from the chain and
//! `asset_id`.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use crate::domain::{
    Asset, AssetBalance, Balance, ChainId, Transaction, TransactionDirection, TransactionStatus, LBTC_ASSET_ID,
};
use crate::{Error, Result};

/// Minimum sent amount for a pair to count as a swap.
pub const SWAP_MIN_AMOUNT_SAT: i64 = 25_000;
/// Maximum time between the two legs of a swap (12 h).
pub const SWAP_MAX_DURATION_MS: u64 = 12 * 60 * 60 * 1000;

/// Asset of a domain record: BTC on the bitcoin chain, else by asset id.
pub fn asset_of(tx: &Transaction) -> Option<Asset> {
    match tx.chain {
        ChainId::Bitcoin => Some(Asset::Btc),
        _ => tx.asset_id.as_deref().and_then(Asset::from_id),
    }
}

fn is_lbtc_on_liquid(tx: &Transaction) -> bool {
    tx.chain == ChainId::Liquid && tx.asset_id.as_deref() == Some(LBTC_ASSET_ID)
}

/// Merges both chains, sorts newest first and collapses swap pairs.
/// Port of `_processTransactionsInIsolate`.
pub fn merge_and_pair(liquid: &[Transaction], bitcoin: &[Transaction]) -> Vec<Transaction> {
    let mut all: Vec<Transaction> = liquid.iter().chain(bitcoin.iter()).cloned().collect();
    super::tracker::sort_newest_first(&mut all);
    pair_internal_swaps(&all)
}

/// Collapses an outgoing BTC + incoming L-BTC pair (or the reverse) into
/// one `Swap` record when the received amount is 90 % to 101 % of the
/// sent amount, the sent amount is at least 25 000 sats and the legs are
/// at most 12 h apart.
///
/// NOTE(port): as in Dart, a receive leg that comes before its send leg in
/// the list (newer, in a newest-first list) is already emitted on its own
/// before the pair forms, so it appears twice: alone and inside the swap.
pub fn pair_internal_swaps(transactions: &[Transaction]) -> Vec<Transaction> {
    let mut result = Vec::with_capacity(transactions.len());
    let mut processed: Vec<&str> = Vec::new();
    for (i, tx1) in transactions.iter().enumerate() {
        if processed.contains(&tx1.id.as_str()) {
            continue;
        }
        if tx1.direction != TransactionDirection::Outgoing {
            result.push(tx1.clone());
            continue;
        }
        let mut paired = false;
        for (j, tx2) in transactions.iter().enumerate() {
            if j == i || processed.contains(&tx2.id.as_str()) || tx2.direction != TransactionDirection::Incoming {
                continue;
            }
            let btc_to_lbtc = tx1.chain == ChainId::Bitcoin && is_lbtc_on_liquid(tx2);
            let lbtc_to_btc = is_lbtc_on_liquid(tx1) && tx2.chain == ChainId::Bitcoin;
            if !btc_to_lbtc && !lbtc_to_btc {
                continue;
            }
            let sent = tx1.amount_sat;
            let received = tx2.amount_sat;
            let valid_amount =
                sent >= SWAP_MIN_AMOUNT_SAT && received >= sent * 90 / 100 && received <= sent * 101 / 100;
            let within_window = tx1.timestamp_ms.abs_diff(tx2.timestamp_ms) <= SWAP_MAX_DURATION_MS;
            if !(valid_amount && within_window) {
                continue;
            }
            let both_confirmed = tx1.status == TransactionStatus::Confirmed && tx2.status == TransactionStatus::Confirmed;
            let asset_id = |t: &Transaction| asset_of(t).map(|a| a.id().to_owned());
            let mut swap = Transaction::new(
                format!("{}_{}_swap", tx1.id, tx2.id),
                tx2.chain,
                TransactionDirection::Swap,
                if both_confirmed { TransactionStatus::Confirmed } else { TransactionStatus::Pending },
                received,
                0,
                tx1.timestamp_ms.min(tx2.timestamp_ms),
            );
            swap.confirmations = tx1.confirmations.min(tx2.confirmations);
            swap.asset_id = asset_id(tx2);
            swap.from_asset_id = asset_id(tx1);
            swap.to_asset_id = asset_id(tx2);
            swap.sent_amount_sat = Some(sent);
            swap.received_amount_sat = Some(received);
            // Legacy `sendTxId` / `receiveTxId`.
            swap.swap_lockup_tx_id = Some(tx1.id.clone());
            swap.swap_claim_tx_id = Some(tx2.id.clone());
            result.push(swap);
            processed.push(&tx1.id);
            processed.push(&tx2.id);
            paired = true;
            break;
        }
        if !paired {
            result.push(tx1.clone());
        }
    }
    result
}

/// Per-chain balance snapshot. `None` = service not operational.
#[derive(Debug, Clone, Default)]
pub struct ChainSnapshots {
    pub bitcoin: Option<Result<Balance>>,
    pub liquid: Option<Result<Balance>>,
}

impl ChainSnapshots {
    fn for_chain(&self, chain: ChainId) -> Option<&Result<Balance>> {
        match chain {
            ChainId::Bitcoin => self.bitcoin.as_ref(),
            ChainId::Liquid => self.liquid.as_ref(),
            ChainId::Lightning | ChainId::Aggregate => None,
        }
    }
}

/// Chains that can report an asset, in priority order (`resolutionChains`).
pub fn resolution_chains(asset: Asset) -> &'static [ChainId] {
    match asset {
        Asset::Btc => &[ChainId::Bitcoin],
        Asset::Lbtc | Asset::Usdt | Asset::Depix => &[ChainId::Liquid],
    }
}

fn extract_amount(balance: &Balance, asset: Asset, chain: ChainId) -> Option<u64> {
    let want: Option<&str> = if asset.is_native_bitcoin() { None } else { Some(asset.id()) };
    let mut sum = 0u64;
    let mut saw = false;
    for ab in balance.assets.iter().filter(|ab| ab.chain == chain && ab.asset_id.as_deref() == want) {
        sum += ab.amount_sat;
        saw = true;
    }
    saw.then_some(sum)
}

/// Balance of one asset. First chain that reports the asset wins. No
/// report means zero, unless every operational chain errored.
pub fn resolve_asset_balance(asset: Asset, snapshots: &ChainSnapshots) -> Result<u64> {
    let mut last_error: Option<Error> = None;
    let mut any_ok = false;
    for &chain in resolution_chains(asset) {
        match snapshots.for_chain(chain) {
            None => continue,
            Some(Err(e)) => last_error = Some(e.clone()),
            Some(Ok(b)) => {
                any_ok = true;
                if let Some(v) = extract_amount(b, asset, chain) {
                    return Ok(v);
                }
            }
        }
    }
    match last_error {
        Some(e) if !any_ok => Err(e),
        _ => Ok(0),
    }
}

/// Balances of several assets. Fails only if nothing resolved and an error
/// occurred; missing assets read as zero.
pub fn balance_map(assets: &[Asset], snapshots: &ChainSnapshots) -> Result<BTreeMap<Asset, u64>> {
    let mut out = BTreeMap::new();
    let mut first_failure = None;
    for &a in assets {
        match resolve_asset_balance(a, snapshots) {
            Ok(v) => {
                out.insert(a, v);
            }
            Err(e) => {
                first_failure.get_or_insert(e);
            }
        }
    }
    if out.is_empty() {
        if let Some(e) = first_failure {
            return Err(e);
        }
    }
    for &a in assets {
        out.entry(a).or_insert(0);
    }
    Ok(out)
}

/// Concatenates the asset rows of every operational service. Fails only
/// if no rows came back and some service failed. Port of `aggregateBalance`.
pub fn aggregate_balance(snapshots: &[Result<Balance>], now_ms: u64) -> Result<Balance> {
    let mut assets: Vec<AssetBalance> = Vec::new();
    let mut first_error = None;
    for s in snapshots {
        match s {
            Ok(b) => assets.extend(b.assets.iter().cloned()),
            Err(e) => {
                first_error.get_or_insert_with(|| e.clone());
            }
        }
    }
    if assets.is_empty() {
        if let Some(e) = first_error {
            return Err(e);
        }
    }
    Ok(Balance { assets, snapshot_at_ms: now_ms })
}

/// Activity metrics of one asset. Port of `AssetActivitySummary`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AssetActivitySummary {
    pub asset: Asset,
    pub transaction_count: usize,
    pub total_received: u64,
    pub total_sent: u64,
    pub total_volume: u64,
    pub largest_receive: u64,
    pub largest_send: u64,
    pub first_activity_ms: Option<u64>,
    pub last_activity_ms: Option<u64>,
}

impl AssetActivitySummary {
    /// Summary with no activity.
    pub fn empty(asset: Asset) -> Self {
        Self {
            asset,
            transaction_count: 0,
            total_received: 0,
            total_sent: 0,
            total_volume: 0,
            largest_receive: 0,
            largest_send: 0,
            first_activity_ms: None,
            last_activity_ms: None,
        }
    }
}

fn is_swap_shaped(tx: &Transaction) -> bool {
    tx.from_asset_id.is_some() && tx.to_asset_id.is_some() && tx.sent_amount_sat.is_some() && tx.received_amount_sat.is_some()
}

fn leg_asset(id: &Option<String>) -> Option<Asset> {
    id.as_deref().and_then(Asset::from_id)
}

/// Records that involve `asset`, as headline asset or as a swap leg.
pub fn filter_for_asset(asset: Asset, transactions: &[Transaction]) -> Vec<Transaction> {
    transactions
        .iter()
        .filter(|tx| {
            asset_of(tx) == Some(asset)
                || (is_swap_shaped(tx)
                    && (leg_asset(&tx.from_asset_id) == Some(asset) || leg_asset(&tx.to_asset_id) == Some(asset)))
        })
        .cloned()
        .collect()
}

/// Computes the activity summary. Counts and time bounds include every
/// relevant record. Sums skip failed records and records without clean
/// send or receive meaning (self-transfers, internal, half swaps).
pub fn summarize_activity(asset: Asset, transactions: &[Transaction]) -> AssetActivitySummary {
    let relevant = filter_for_asset(asset, transactions);
    if relevant.is_empty() {
        return AssetActivitySummary::empty(asset);
    }
    let mut s = AssetActivitySummary::empty(asset);
    s.transaction_count = relevant.len();
    let to_u64 = |v: i64| v.max(0) as u64;
    for tx in &relevant {
        let t = tx.timestamp_ms;
        s.first_activity_ms = Some(s.first_activity_ms.map_or(t, |f| f.min(t)));
        s.last_activity_ms = Some(s.last_activity_ms.map_or(t, |l| l.max(t)));
        if tx.status == TransactionStatus::Failed {
            continue;
        }
        let receive = |v: u64, s: &mut AssetActivitySummary| {
            s.total_received += v;
            s.largest_receive = s.largest_receive.max(v);
        };
        let send = |v: u64, s: &mut AssetActivitySummary| {
            s.total_sent += v;
            s.largest_send = s.largest_send.max(v);
        };
        if is_swap_shaped(tx) {
            if leg_asset(&tx.to_asset_id) == Some(asset) {
                receive(to_u64(tx.received_amount_sat.unwrap_or(0)), &mut s);
            }
            if leg_asset(&tx.from_asset_id) == Some(asset) {
                send(to_u64(tx.sent_amount_sat.unwrap_or(0)), &mut s);
            }
            continue;
        }
        match tx.direction {
            TransactionDirection::Incoming => receive(to_u64(tx.amount_sat), &mut s),
            TransactionDirection::Outgoing => send(to_u64(tx.amount_sat), &mut s),
            TransactionDirection::Swap | TransactionDirection::SelfTransfer | TransactionDirection::Internal => {}
        }
    }
    s.total_volume = s.total_received + s.total_sent;
    s
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{BTC_ASSET_ID, USDT_ASSET_ID};

    fn tx(id: &str, chain: ChainId, dir: TransactionDirection, amount: i64, ts: u64) -> Transaction {
        let mut t = Transaction::new(id, chain, dir, TransactionStatus::Confirmed, amount, 10, ts);
        if chain == ChainId::Liquid {
            t.asset_id = Some(LBTC_ASSET_ID.into());
        }
        t
    }

    #[test]
    fn pairs_btc_to_lbtc_peg() {
        let h = 3_600_000;
        let send = tx("s", ChainId::Bitcoin, TransactionDirection::Outgoing, 100_000, 10 * h);
        let recv = tx("r", ChainId::Liquid, TransactionDirection::Incoming, 99_000, 11 * h);
        let other = tx("o", ChainId::Liquid, TransactionDirection::Incoming, 5_000, 12 * h);
        let out = merge_and_pair(&[recv.clone(), other], std::slice::from_ref(&send));
        // Newest first: other, recv (emitted alone, Dart quirk), swap.
        assert_eq!(out.len(), 3);
        assert_eq!(out[1].id, "r");
        // Oldest-first input pairs without the duplicate.
        assert_eq!(pair_internal_swaps(&[send, recv]).len(), 1);
        let swap = out.iter().find(|t| t.direction == TransactionDirection::Swap).unwrap();
        assert_eq!(swap.id, "s_r_swap");
        assert_eq!(swap.chain, ChainId::Liquid);
        assert_eq!((swap.amount_sat, swap.sent_amount_sat, swap.received_amount_sat), (99_000, Some(100_000), Some(99_000)));
        assert_eq!(swap.from_asset_id.as_deref(), Some(BTC_ASSET_ID));
        assert_eq!(swap.to_asset_id.as_deref(), Some(LBTC_ASSET_ID));
        assert_eq!(swap.timestamp_ms, 10 * h);
        assert_eq!(swap.status, TransactionStatus::Confirmed);
        assert_eq!(swap.swap_lockup_tx_id.as_deref(), Some("s"));
    }

    #[test]
    fn rejects_bad_ratio_small_amount_and_late_legs() {
        let h = 3_600_000;
        let s = tx("s", ChainId::Liquid, TransactionDirection::Outgoing, 100_000, 0);
        let low = tx("r", ChainId::Bitcoin, TransactionDirection::Incoming, 89_999, h);
        assert_eq!(pair_internal_swaps(&[s.clone(), low]).len(), 2);
        let late = tx("r", ChainId::Bitcoin, TransactionDirection::Incoming, 95_000, 13 * h);
        assert_eq!(pair_internal_swaps(&[s.clone(), late]).len(), 2);
        let small = tx("s2", ChainId::Liquid, TransactionDirection::Outgoing, 24_999, 0);
        let r = tx("r", ChainId::Bitcoin, TransactionDirection::Incoming, 24_999, 0);
        assert_eq!(pair_internal_swaps(&[small, r]).len(), 2);
        // Same chain never pairs.
        let r = tx("r", ChainId::Liquid, TransactionDirection::Incoming, 99_000, 0);
        assert_eq!(pair_internal_swaps(&[s, r]).len(), 2);
    }

    fn snap(chain: ChainId, asset_id: Option<&str>, amount: u64) -> Balance {
        Balance {
            assets: vec![AssetBalance {
                chain,
                asset_id: asset_id.map(str::to_owned),
                amount_sat: amount,
                precision: 8,
                ticker: None,
                pending_sat: 0,
            }],
            snapshot_at_ms: 0,
        }
    }

    #[test]
    fn resolves_balances_and_errors() {
        let s = ChainSnapshots {
            bitcoin: Some(Ok(snap(ChainId::Bitcoin, None, 7))),
            liquid: Some(Ok(snap(ChainId::Liquid, Some(USDT_ASSET_ID), 9))),
        };
        assert_eq!(resolve_asset_balance(Asset::Btc, &s).unwrap(), 7);
        assert_eq!(resolve_asset_balance(Asset::Usdt, &s).unwrap(), 9);
        assert_eq!(resolve_asset_balance(Asset::Lbtc, &s).unwrap(), 0);

        let failed = ChainSnapshots { bitcoin: Some(Err(Error::Network("x".into()))), liquid: None };
        assert!(resolve_asset_balance(Asset::Btc, &failed).is_err());
        assert_eq!(resolve_asset_balance(Asset::Lbtc, &failed).unwrap(), 0);
        let m = balance_map(&[Asset::Btc, Asset::Lbtc], &failed).unwrap();
        assert_eq!(m[&Asset::Lbtc], 0);
        assert_eq!(m[&Asset::Btc], 0);
        assert!(balance_map(&[Asset::Btc], &failed).is_err());

        let agg = aggregate_balance(&[Ok(snap(ChainId::Bitcoin, None, 1)), Err(Error::Network("x".into()))], 5).unwrap();
        assert_eq!(agg.assets.len(), 1);
        assert!(aggregate_balance(&[Err(Error::Network("x".into()))], 5).is_err());
    }

    #[test]
    fn activity_summary() {
        let mut fail = tx("f", ChainId::Bitcoin, TransactionDirection::Incoming, 1_000_000, 50);
        fail.status = TransactionStatus::Failed;
        let mut swap = tx("w", ChainId::Liquid, TransactionDirection::Swap, 300, 40);
        swap.from_asset_id = Some(BTC_ASSET_ID.into());
        swap.to_asset_id = Some(LBTC_ASSET_ID.into());
        swap.sent_amount_sat = Some(300);
        swap.received_amount_sat = Some(290);
        let txs = vec![
            tx("a", ChainId::Bitcoin, TransactionDirection::Incoming, 500, 10),
            tx("b", ChainId::Bitcoin, TransactionDirection::Outgoing, 200, 20),
            tx("c", ChainId::Bitcoin, TransactionDirection::SelfTransfer, 10, 30),
            swap,
            fail,
            tx("l", ChainId::Liquid, TransactionDirection::Incoming, 9, 60),
        ];
        let s = summarize_activity(Asset::Btc, &txs);
        assert_eq!(s.transaction_count, 5);
        assert_eq!((s.total_received, s.total_sent, s.total_volume), (500, 500, 1_000));
        assert_eq!((s.largest_receive, s.largest_send), (500, 300));
        assert_eq!((s.first_activity_ms, s.last_activity_ms), (Some(10), Some(50)));
        let l = summarize_activity(Asset::Lbtc, &txs);
        assert_eq!((l.transaction_count, l.total_received), (2, 299));
        assert_eq!(summarize_activity(Asset::Depix, &txs), AssetActivitySummary::empty(Asset::Depix));
    }
}
