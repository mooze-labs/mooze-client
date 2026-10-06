use std::collections::BTreeSet;

use serde::{Deserialize, Serialize};

/// Chain a balance, address or transaction belongs to.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ChainId {
    Liquid,
    Bitcoin,
    Lightning,
    /// Sum over all real chains. Never stored on a transaction.
    Aggregate,
}

impl ChainId {
    /// False only for [`ChainId::Aggregate`].
    pub fn is_real(self) -> bool {
        self != ChainId::Aggregate
    }

    /// Lower-case name.
    pub fn as_str(self) -> &'static str {
        match self {
            ChainId::Liquid => "liquid",
            ChainId::Bitcoin => "bitcoin",
            ChainId::Lightning => "lightning",
            ChainId::Aggregate => "aggregate",
        }
    }
}

/// Network the app runs on.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum AppNetwork {
    #[default]
    Mainnet,
    Testnet,
    Regtest,
}

impl AppNetwork {
    /// Parses a name. Unknown names fall back to mainnet.
    pub fn from_name(name: &str) -> Self {
        match name {
            "testnet" => AppNetwork::Testnet,
            "regtest" => AppNetwork::Regtest,
            _ => AppNetwork::Mainnet,
        }
    }

    /// True for mainnet.
    pub fn is_mainnet(self) -> bool {
        self == AppNetwork::Mainnet
    }
}

/// Set of chains to include in a query.
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct ChainFilter {
    pub chains: BTreeSet<ChainId>,
}

impl ChainFilter {
    /// Filter that matches one chain.
    pub fn only(chain: ChainId) -> Self {
        Self { chains: BTreeSet::from([chain]) }
    }

    /// True if `chain` is in the filter.
    pub fn matches(&self, chain: ChainId) -> bool {
        self.chains.contains(&chain)
    }
}
