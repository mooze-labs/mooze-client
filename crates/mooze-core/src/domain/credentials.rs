use std::fmt;

use serde::{Deserialize, Serialize};

use super::AppNetwork;

/// Mnemonic plus network. `Debug` never prints the mnemonic.
#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WalletCredentials {
    pub mnemonic: String,
    pub network: AppNetwork,
}

impl WalletCredentials {
    /// Credentials with an empty mnemonic.
    pub fn absent(network: AppNetwork) -> Self {
        Self { mnemonic: String::new(), network }
    }

    /// True if no mnemonic is set.
    pub fn is_absent(&self) -> bool {
        self.mnemonic.is_empty()
    }
}

impl fmt::Debug for WalletCredentials {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("WalletCredentials").field("network", &self.network).field("mnemonic", &"<redacted>").finish()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn debug_redacts() {
        let c = WalletCredentials { mnemonic: "secret words".into(), network: AppNetwork::Mainnet };
        assert!(!format!("{c:?}").contains("secret"));
    }
}
