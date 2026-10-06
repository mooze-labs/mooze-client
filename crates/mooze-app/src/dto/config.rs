use serde::{Deserialize, Serialize};

use mooze_core::domain as d;

/// Network the wallet runs on.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum NetworkDto {
    Mainnet,
    Testnet,
    Regtest,
}

impl From<NetworkDto> for d::AppNetwork {
    fn from(n: NetworkDto) -> Self {
        match n {
            NetworkDto::Mainnet => d::AppNetwork::Mainnet,
            NetworkDto::Testnet => d::AppNetwork::Testnet,
            NetworkDto::Regtest => d::AppNetwork::Regtest,
        }
    }
}

/// Protocol used to reach the chains.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum BackendDto {
    Esplora,
    Electrum,
}

/// Settings for `App::open`. The host owns storage locations.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct AppConfig {
    pub network: NetworkDto,
    pub backend: BackendDto,
    /// Custom Bitcoin node. Empty uses the default servers.
    pub bitcoin_node_url: String,
    /// Custom Liquid node. Empty uses the default servers.
    pub liquid_node_url: String,
    /// Mooze backend base URL. `None` uses `mooze_core::api::DEFAULT_BASE_URL`.
    pub api_base_url: Option<String>,
}
