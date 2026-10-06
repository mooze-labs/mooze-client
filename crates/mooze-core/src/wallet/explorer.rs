//! Address and UTXO inspection types shared by both wallets.
//!
//! [`super::BitcoinWallet`] and [`super::LiquidWallet`] return these types
//! from their explorer calls. The address explorer groups them into rows
//! (see [`crate::store::addresses`]).

/// Keychain of a derived address.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Keychain {
    /// Receive chain.
    External,
    /// Change chain.
    Internal,
}

/// One derived wallet address.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DerivedAddressInfo {
    pub keychain: Keychain,
    pub index: u32,
    /// Address the UI shows. Liquid: the confidential address.
    pub address: String,
    /// Liquid: the unconfidential address. Bitcoin: `None`.
    pub unconfidential: Option<String>,
    /// Hex of the script pubkey.
    pub script_hex: String,
    /// True if a wallet transaction ever paid to the script.
    pub used: bool,
}

/// One unspent wallet output.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WalletUtxoInfo {
    pub txid: String,
    pub vout: u32,
    /// Address of the output. Liquid: the confidential address.
    pub address: String,
    /// Liquid: the unconfidential address. Bitcoin: `None`.
    pub unconfidential: Option<String>,
    /// Hex of the script pubkey.
    pub script_hex: String,
    pub keychain: Keychain,
    pub index: u32,
    /// Value in sats (Bitcoin) or asset base units (Liquid).
    pub amount_sat: u64,
    /// Liquid asset id. Bitcoin: `None`.
    pub asset_id: Option<String>,
    /// Height of the confirming block. `None` while unconfirmed.
    pub confirmation_height: Option<u32>,
    /// Block time (seconds) of the confirming block, if the wallet knows it.
    pub confirmation_time_s: Option<u64>,
}

impl WalletUtxoInfo {
    /// `txid:vout`.
    pub fn outpoint(&self) -> String {
        format!("{}:{}", self.txid, self.vout)
    }

    /// True if the output is in a block.
    pub fn is_confirmed(&self) -> bool {
        self.confirmation_height.is_some()
    }
}

/// Derivation of an address the wallet owns.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AddressOwnership {
    pub keychain: Keychain,
    pub index: u32,
}

/// Next receive address with its index.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NextUnusedAddress {
    pub index: u32,
    /// Address the UI shows. Liquid: the confidential address.
    pub address: String,
    /// True if a wallet transaction already paid to it. Bitcoin: always false.
    pub used: bool,
}

/// Upper bound of `count` in one derived-address call.
pub const MAX_DERIVED_ADDRESSES: u32 = 10_000;

/// Indexes `start..start + count`, with `count` capped at [`MAX_DERIVED_ADDRESSES`].
pub(crate) fn index_range(start: u32, count: u32) -> std::ops::Range<u32> {
    start..start.saturating_add(count.min(MAX_DERIVED_ADDRESSES))
}

/// Lowercase hex of `bytes`.
pub(crate) fn hex(bytes: &[u8]) -> String {
    use std::fmt::Write;
    bytes
        .iter()
        .fold(String::with_capacity(bytes.len() * 2), |mut s, b| {
            let _ = write!(s, "{b:02x}");
            s
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn helpers() {
        assert_eq!(hex(&[0x00, 0x14, 0xab]), "0014ab");
        assert_eq!(index_range(5, 3), 5..8);
        assert_eq!(index_range(0, u32::MAX).end, MAX_DERIVED_ADDRESSES);
        assert_eq!(index_range(u32::MAX - 1, 10).end, u32::MAX);
        let u = WalletUtxoInfo {
            txid: "ab".into(),
            vout: 1,
            address: String::new(),
            unconfidential: None,
            script_hex: String::new(),
            keychain: Keychain::External,
            index: 0,
            amount_sat: 1,
            asset_id: None,
            confirmation_height: None,
            confirmation_time_s: None,
        };
        assert_eq!(u.outpoint(), "ab:1");
        assert!(!u.is_confirmed());
    }
}
