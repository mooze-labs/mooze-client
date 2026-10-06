//! Address explorer records and listing logic.
//!
//! The wallet module derives addresses and lists UTXOs. These functions
//! group them into [`WalletAddress`] rows and answer ownership probes.

use std::collections::{BTreeMap, BTreeSet};

use serde::{Deserialize, Serialize};

/// Bitcoin scan cap when searching the next unused address or an index.
pub const BITCOIN_NEXT_UNUSED_SCAN_CAP: u32 = 100;
/// Liquid ownership scan limit.
pub const LIQUID_OWNERSHIP_SCAN_LIMIT: u32 = 200;
/// Default page size of the address list.
pub const DEFAULT_ADDRESS_LIST_LIMIT: u32 = 100;

/// Chain of an explorer address.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AddressChain {
    Bitcoin,
    Liquid,
}

/// Whether an address ever received funds.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AddressStatus {
    Used,
    Unused,
}

/// One unspent output held by an address.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AddressUtxo {
    pub address: String,
    pub chain: AddressChain,
    /// `txid:vout`.
    pub outpoint: String,
    pub value: u64,
    pub asset_id: Option<String>,
    pub confirmed: bool,
}

/// One derived wallet address with its status and UTXOs.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WalletAddress {
    pub address: String,
    pub chain: AddressChain,
    pub status: AddressStatus,
    pub derivation_index: u32,
    /// Sum of the current UTXO values (not lifetime received).
    pub received_sats: u64,
    pub utxos: Vec<AddressUtxo>,
}

impl WalletAddress {
    /// True if the address has history.
    pub fn is_used(&self) -> bool {
        self.status == AddressStatus::Used
    }
}

/// Result of an ownership probe.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AddressMatch {
    pub address: String,
    pub is_owned: bool,
    pub chain: Option<AddressChain>,
    pub status: Option<AddressStatus>,
    pub derivation_index: Option<u32>,
    pub utxos: Vec<AddressUtxo>,
}

impl AddressMatch {
    /// Address not owned by the wallet.
    pub fn not_owned(address: impl Into<String>) -> Self {
        Self { address: address.into(), is_owned: false, chain: None, status: None, derivation_index: None, utxos: vec![] }
    }

    /// Owned address.
    pub fn owned(
        address: impl Into<String>,
        chain: AddressChain,
        status: AddressStatus,
        derivation_index: Option<u32>,
        utxos: Vec<AddressUtxo>,
    ) -> Self {
        Self { address: address.into(), is_owned: true, chain: Some(chain), status: Some(status), derivation_index, utxos }
    }

    /// Number of unspent outputs.
    pub fn utxo_count(&self) -> usize {
        self.utxos.len()
    }
}

/// One derived address. `match_key` is the script hex (Bitcoin) or the
/// unconfidential address (Liquid). `display` is the address the UI shows.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DerivedAddress {
    pub index: u32,
    pub match_key: String,
    pub display: String,
}

/// One wallet output. `match_key` follows [`DerivedAddress::match_key`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WalletOutput {
    pub match_key: String,
    pub outpoint: String,
    pub value: u64,
    pub asset_id: Option<String>,
    pub is_spent: bool,
}

/// Builds the address list from derived addresses, outputs and history keys.
///
/// An address is used if it holds an unspent output or appears in `history_keys`.
/// Rows sort by derivation index. When two indexes share a key, the later one wins.
pub fn build_address_list(
    chain: AddressChain,
    derived: &[DerivedAddress],
    outputs: &[WalletOutput],
    history_keys: &BTreeSet<String>,
) -> Vec<WalletAddress> {
    let mut by_key: BTreeMap<&str, &DerivedAddress> = BTreeMap::new();
    for d in derived {
        by_key.insert(d.match_key.as_str(), d);
    }
    let mut utxos_by_key: BTreeMap<&str, Vec<&WalletOutput>> = BTreeMap::new();
    for o in outputs.iter().filter(|o| !o.is_spent) {
        if by_key.contains_key(o.match_key.as_str()) {
            utxos_by_key.entry(o.match_key.as_str()).or_default().push(o);
        }
    }
    let mut out: Vec<WalletAddress> = by_key
        .iter()
        .map(|(key, d)| {
            let utxos: Vec<AddressUtxo> = utxos_by_key
                .get(key)
                .map(|v| v.iter().map(|o| to_utxo(chain, &d.display, o)).collect())
                .unwrap_or_default();
            let used = !utxos.is_empty() || history_keys.contains(*key);
            WalletAddress {
                address: d.display.clone(),
                chain,
                status: if used { AddressStatus::Used } else { AddressStatus::Unused },
                derivation_index: d.index,
                received_sats: utxos.iter().map(|u| u.value).sum(),
                utxos,
            }
        })
        .collect();
    out.sort_by_key(|a| a.derivation_index);
    out
}

fn to_utxo(chain: AddressChain, address: &str, o: &WalletOutput) -> AddressUtxo {
    AddressUtxo {
        address: address.to_owned(),
        chain,
        outpoint: o.outpoint.clone(),
        value: o.value,
        asset_id: o.asset_id.clone(),
        confirmed: true,
    }
}

/// Probe result for a Bitcoin address the wallet reports as mine.
///
/// `index` is the first derived index whose script matches, or `None` past the scan cap.
pub fn bitcoin_owned_match(
    address: &str,
    script_key: &str,
    derived: &[DerivedAddress],
    outputs: &[WalletOutput],
    used_script_keys: &BTreeSet<String>,
) -> AddressMatch {
    let index = derived
        .iter()
        .filter(|d| d.index < BITCOIN_NEXT_UNUSED_SCAN_CAP)
        .find(|d| d.match_key == script_key)
        .map(|d| d.index);
    let utxos: Vec<AddressUtxo> = outputs
        .iter()
        .filter(|o| !o.is_spent && o.match_key == script_key)
        .map(|o| to_utxo(AddressChain::Bitcoin, address, o))
        .collect();
    // NOTE: The "used" status comes only from the used-script set, not from UTXOs.
    let status = if used_script_keys.contains(script_key) { AddressStatus::Used } else { AddressStatus::Unused };
    AddressMatch::owned(address, AddressChain::Bitcoin, status, index, utxos)
}

/// Liquid derived address: both forms.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LiquidDerived {
    pub index: u32,
    pub standard: String,
    pub confidential: String,
}

/// Liquid ownership probe over the first [`LIQUID_OWNERSHIP_SCAN_LIMIT`] derived addresses.
///
/// `outputs` use the unconfidential address as key. `history_keys` holds
/// the unconfidential addresses of every wallet tx output.
pub fn liquid_owned_match(
    address: &str,
    derived: &[LiquidDerived],
    outputs: &[WalletOutput],
    history_keys: &BTreeSet<String>,
) -> AddressMatch {
    let hit = derived
        .iter()
        .filter(|d| d.index < LIQUID_OWNERSHIP_SCAN_LIMIT)
        .find(|d| d.standard == address || d.confidential == address);
    let Some(d) = hit else {
        return AddressMatch::not_owned(address);
    };
    let utxos: Vec<AddressUtxo> = outputs
        .iter()
        .filter(|o| !o.is_spent && o.match_key == d.standard)
        .map(|o| to_utxo(AddressChain::Liquid, address, o))
        .collect();
    let used = !utxos.is_empty() || history_keys.contains(&d.standard);
    let status = if used { AddressStatus::Used } else { AddressStatus::Unused };
    AddressMatch::owned(address, AddressChain::Liquid, status, Some(d.index), utxos)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn d(i: u32, k: &str) -> DerivedAddress {
        DerivedAddress { index: i, match_key: k.into(), display: format!("addr{i}") }
    }

    fn o(k: &str, v: u64, spent: bool) -> WalletOutput {
        WalletOutput { match_key: k.into(), outpoint: format!("tx:{v}"), value: v, asset_id: None, is_spent: spent }
    }

    #[test]
    fn list_marks_used_and_sums_utxos() {
        let derived = [d(2, "s2"), d(0, "s0"), d(1, "s1")];
        let outputs = [o("s0", 10, false), o("s0", 5, false), o("s1", 7, true), o("zz", 1, false)];
        let history = BTreeSet::from(["s1".to_string()]);
        let list = build_address_list(AddressChain::Bitcoin, &derived, &outputs, &history);
        assert_eq!(list.iter().map(|a| a.derivation_index).collect::<Vec<_>>(), [0, 1, 2]);
        assert_eq!(list[0].received_sats, 15);
        assert!(list[0].is_used());
        assert!(list[1].is_used());
        assert_eq!(list[1].utxos.len(), 0);
        assert_eq!(list[2].status, AddressStatus::Unused);
    }

    #[test]
    fn ownership_probes() {
        let m = bitcoin_owned_match("bc1x", "s1", &[d(0, "s0"), d(1, "s1")], &[o("s1", 3, false)], &BTreeSet::new());
        assert_eq!((m.derivation_index, m.status, m.utxo_count()), (Some(1), Some(AddressStatus::Unused), 1));

        let ld = [LiquidDerived { index: 4, standard: "ex1".into(), confidential: "lq1".into() }];
        let m = liquid_owned_match("lq1", &ld, &[], &BTreeSet::from(["ex1".to_string()]));
        assert!(m.is_owned);
        assert_eq!((m.derivation_index, m.status), (Some(4), Some(AddressStatus::Used)));
        assert!(!liquid_owned_match("other", &ld, &[], &BTreeSet::new()).is_owned);
    }
}
