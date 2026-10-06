//! Wallet engines. Port of `lib/infra/bdk/**`, `lib/infra/lwk/**` and the
//! wallet repositories.
//!
//! - [`bitcoin::BitcoinWallet`] wraps a BDK wallet and an esplora client.
//! - [`liquid::LiquidWallet`] wraps an LWK wollet and an esplora client.
//! - [`descriptors`] derives the same keys and addresses as the Flutter app.
//! - [`endpoints`] holds default esplora URLs and the failover policy.
//!
//! Network I/O goes through `bdk_esplora` and `lwk_wollet::asyncr`, which
//! use `reqwest`. On native targets the platform must poll those futures
//! inside a tokio runtime. On wasm they use `fetch`.

pub mod backend;
pub mod bitcoin;
pub mod descriptors;
pub mod endpoints;
pub mod explorer;
pub mod fees;
pub mod history;
pub mod lifecycle;
pub mod liquid;
pub mod mnemonic;
pub mod tracker;

pub use backend::{ChainBackend, ElectrumConfig};
pub use bitcoin::BitcoinWallet;
pub use endpoints::EndpointResolver;
pub use explorer::{
    AddressOwnership, DerivedAddressInfo, Keychain, NextUnusedAddress, WalletUtxoInfo,
};
pub use liquid::LiquidWallet;
