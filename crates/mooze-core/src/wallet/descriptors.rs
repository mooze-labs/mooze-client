//! Wallet descriptors. They must match the Flutter app byte for byte in
//! the addresses they produce, or users lose sight of their funds.
//!
//! - Bitcoin (BDK): `wpkh([fp/84'/0'/0'/0]xprv/*)` for receive and
//!   `wpkh([fp/84'/0'/0'/1]xprv/*)` for change. Coin type `0'` on every
//!   network, same as the old `bdk_flutter` derivation
//!   (`bitcoin_wallet_service_impl.dart`, `_buildDescriptor`).
//! - Liquid (LWK): `lwk_common::singlesig_desc` with `Wpkh` and `Slip77`,
//!   same as `lwk.Descriptor.newConfidential` in `packages/lwk-dart`.
//!   That is `ct(slip77(..),elwpkh([fp/84h/1776h/0h]xpub/<0;1>/*))` on
//!   mainnet and coin type `1h` on testnet.

use std::str::FromStr;

use bdk_wallet::bitcoin::bip32::{DerivationPath, Xpriv};
use bdk_wallet::bitcoin::secp256k1::Secp256k1;
use bdk_wallet::bitcoin::{Network as BtcNetwork, NetworkKind};
use lwk_common::{singlesig_desc, DescriptorBlindingKey, Singlesig};
use lwk_signer::SwSigner;
use lwk_wollet::WolletDescriptor;

use super::mnemonic;
use crate::domain::{AppNetwork, ChainId, LBTC_ASSET_ID};
use crate::{Error, Result};

/// L-BTC asset id on Liquid testnet (`lTestAssetId` in lwk-dart).
pub const LIQUID_TESTNET_POLICY_ASSET: &str =
    "144c654344aa716d6f3abcc1ca90e5641e4e2a7f633bc09fe3baf64585819a49";

/// External (receive) derivation path of the BDK wallet.
pub const BITCOIN_EXTERNAL_PATH: &str = "m/84'/0'/0'/0";
/// Internal (change) derivation path of the BDK wallet.
pub const BITCOIN_INTERNAL_PATH: &str = "m/84'/0'/0'/1";

/// Pair of private BDK descriptors.
#[derive(Clone, PartialEq, Eq)]
pub struct BitcoinDescriptors {
    /// Receive keychain.
    pub external: String,
    /// Change keychain.
    pub internal: String,
}

impl std::fmt::Debug for BitcoinDescriptors {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("BitcoinDescriptors(<redacted>)")
    }
}

/// BDK network for the app network.
pub fn bitcoin_network(network: AppNetwork) -> BtcNetwork {
    match network {
        AppNetwork::Mainnet => BtcNetwork::Bitcoin,
        AppNetwork::Testnet => BtcNetwork::Testnet,
        AppNetwork::Regtest => BtcNetwork::Regtest,
    }
}

/// BDK key network kind (xprv or tprv).
pub fn bitcoin_network_kind(network: AppNetwork) -> NetworkKind {
    match network {
        AppNetwork::Mainnet => NetworkKind::Main,
        AppNetwork::Testnet | AppNetwork::Regtest => NetworkKind::Test,
    }
}

/// LWK network. Regtest maps to Liquid testnet, as in the Dart `_toLwkNetwork`.
pub fn liquid_network(network: AppNetwork) -> lwk_wollet::Network {
    match network {
        AppNetwork::Mainnet => lwk_wollet::Network::Liquid,
        AppNetwork::Testnet | AppNetwork::Regtest => lwk_wollet::Network::TestnetLiquid,
    }
}

/// Policy asset (L-BTC) id for the network, as in the Dart `_policyAssetId`.
pub fn liquid_policy_asset(network: AppNetwork) -> &'static str {
    match network {
        AppNetwork::Mainnet => LBTC_ASSET_ID,
        AppNetwork::Testnet | AppNetwork::Regtest => LIQUID_TESTNET_POLICY_ASSET,
    }
}

/// Derives `wpkh(<root>/<path>/*)` with key origin, like bdk-ffi
/// `DescriptorSecretKey.derive` followed by `Descriptor('wpkh(...)')`.
fn bitcoin_descriptor(root: &Xpriv, path: &str) -> Result<String> {
    let secp = Secp256k1::new();
    let path = DerivationPath::from_str(path).map_err(|e| Error::service(ChainId::Bitcoin, e))?;
    let derived = root
        .derive_priv(&secp, &path)
        .map_err(|e| Error::service(ChainId::Bitcoin, e))?;
    let fingerprint = root.fingerprint(&secp);
    let origin = path.to_string();
    let origin = origin.trim_start_matches("m/");
    Ok(format!("wpkh([{fingerprint}/{origin}]{derived}/*)"))
}

/// Builds the BDK receive and change descriptors for a mnemonic.
pub fn bitcoin_descriptors(phrase: &str, network: AppNetwork) -> Result<BitcoinDescriptors> {
    let seed = mnemonic::to_seed(phrase)?;
    let root = Xpriv::new_master(bitcoin_network_kind(network), &seed)
        .map_err(|e| Error::service(ChainId::Bitcoin, e))?;
    Ok(BitcoinDescriptors {
        external: bitcoin_descriptor(&root, BITCOIN_EXTERNAL_PATH)?,
        internal: bitcoin_descriptor(&root, BITCOIN_INTERNAL_PATH)?,
    })
}

/// Software signer for the Liquid wallet.
pub fn liquid_signer(phrase: &str, network: AppNetwork) -> Result<SwSigner> {
    // Validate first so the error carries the BIP39 reason.
    mnemonic::parse(phrase)?;
    SwSigner::new(&mnemonic::normalize(phrase), network.is_mainnet())
        .map_err(|e| Error::service(ChainId::Liquid, e))
}

/// Confidential LWK descriptor string (with checksum) for a mnemonic.
pub fn liquid_descriptor_string(phrase: &str, network: AppNetwork) -> Result<String> {
    let signer = liquid_signer(phrase, network)?;
    singlesig_desc(&signer, Singlesig::Wpkh, DescriptorBlindingKey::Slip77)
        .map_err(|e| Error::service(ChainId::Liquid, e))
}

/// Parsed confidential LWK descriptor for a mnemonic.
pub fn liquid_descriptor(phrase: &str, network: AppNetwork) -> Result<WolletDescriptor> {
    let s = liquid_descriptor_string(phrase, network)?;
    WolletDescriptor::from_str(&s).map_err(|e| Error::service(ChainId::Liquid, e))
}

#[cfg(test)]
mod tests {
    use super::*;
    use bdk_wallet::{KeychainKind, Wallet};

    const ABANDON: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    fn btc_wallet(network: AppNetwork) -> Wallet {
        let d = bitcoin_descriptors(ABANDON, network).unwrap();
        Wallet::create(d.external, d.internal)
            .network(bitcoin_network(network))
            .create_wallet_no_persist()
            .unwrap()
    }

    #[test]
    fn bitcoin_mainnet_matches_bip84_vectors() {
        let w = btc_wallet(AppNetwork::Mainnet);
        // BIP84 test vectors for "abandon ... about".
        assert_eq!(
            w.peek_address(KeychainKind::External, 0)
                .address
                .to_string(),
            "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"
        );
        assert_eq!(
            w.peek_address(KeychainKind::External, 1)
                .address
                .to_string(),
            "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g"
        );
        assert_eq!(
            w.peek_address(KeychainKind::Internal, 0)
                .address
                .to_string(),
            "bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el"
        );
    }

    #[test]
    fn bitcoin_testnet_keeps_coin_type_zero() {
        let d = bitcoin_descriptors(ABANDON, AppNetwork::Testnet).unwrap();
        assert!(
            d.external.starts_with("wpkh([73c5da0a/84'/0'/0'/0]tprv"),
            "{}",
            d.external
        );
        let w = btc_wallet(AppNetwork::Testnet);
        let addr = w
            .peek_address(KeychainKind::External, 0)
            .address
            .to_string();
        // Same key as mainnet index 0, testnet HRP.
        assert!(
            addr.starts_with("tb1qcr8te4kr609gcawutmrza0j4xv80jy8z"),
            "{addr}"
        );
    }

    #[test]
    fn descriptors_debug_redacts_keys() {
        let d = bitcoin_descriptors(ABANDON, AppNetwork::Mainnet).unwrap();
        assert!(!format!("{d:?}").contains("xprv"));
    }

    #[test]
    fn liquid_descriptor_shape() {
        let s = liquid_descriptor_string(ABANDON, AppNetwork::Mainnet).unwrap();
        assert!(s.starts_with("ct(slip77("), "{s}");
        assert!(s.contains("elwpkh([73c5da0a/84h/1776h/0h]xpub"), "{s}");
        assert!(s.contains("/<0;1>/*))#"), "{s}");
        let t = liquid_descriptor_string(ABANDON, AppNetwork::Testnet).unwrap();
        assert!(t.contains("/84h/1h/0h]tpub"), "{t}");
    }

    #[test]
    fn liquid_first_address_is_deterministic() {
        // Expected values come from `fixed_addresses_test` in lwk_wollet
        // 0.9.0, the version lwk-dart pins (Wpkh + Slip77, same mnemonic).
        // NOTE(port): still cross-check against the Flutter app output.
        let addr = |n| {
            let desc = liquid_descriptor(ABANDON, n).unwrap();
            desc.address(0, liquid_network(n).address_params())
                .unwrap()
                .to_string()
        };
        let a = addr(AppNetwork::Mainnet);
        assert!(a.starts_with("lq1"), "{a}");
        assert_eq!(
            a,
            "lq1qqvxk052kf3qtkxmrakx50a9gc3smqad2ync54hzntjt980kfej9kkfe0247rp5h4yzmdftsahhw64uy8pzfe7cpg4fgykm7cv"
        );
        assert_eq!(
            addr(AppNetwork::Testnet),
            "tlq1qq2xvpcvfup5j8zscjq05u2wxxjcyewk7979f3mmz5l7uw5pqmx6xf5xy50hsn6vhkm5euwt72x878eq6zxx2z58hd7zrsg9qn"
        );
        // Regtest maps to Liquid testnet, as in Dart.
        assert_eq!(addr(AppNetwork::Regtest), addr(AppNetwork::Testnet));
    }

    #[test]
    fn invalid_mnemonic_is_rejected() {
        assert!(bitcoin_descriptors("abandon about", AppNetwork::Mainnet).is_err());
        assert!(liquid_descriptor("abandon about", AppNetwork::Mainnet).is_err());
    }
}
