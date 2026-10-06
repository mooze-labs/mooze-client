//! Esplora endpoints and failover.
//!
//! The lists hold esplora base URLs. The rotation rules: stick to the
//! current endpoint, rotate after `failure_threshold` consecutive failures, reset on success.

use std::collections::BTreeMap;

use crate::domain::{AppNetwork, ChainId};
use crate::{Error, Result};

/// Default number of consecutive failures before rotation.
pub const DEFAULT_FAILURE_THRESHOLD: u32 = 2;

/// Default esplora base URLs for a chain and network, preferred first.
///
/// These are the esplora APIs of the default Electrum operators where one
/// exists (Blockstream, mempool.space).
pub fn default_esplora_urls(chain: ChainId, network: AppNetwork) -> Vec<String> {
    let urls: &[&str] = match (chain, network) {
        (ChainId::Bitcoin, AppNetwork::Mainnet) => &["https://blockstream.info/api", "https://mempool.space/api"],
        (ChainId::Bitcoin, AppNetwork::Testnet) => {
            &["https://blockstream.info/testnet/api", "https://mempool.space/testnet/api"]
        }
        (ChainId::Liquid, AppNetwork::Mainnet) => {
            &["https://blockstream.info/liquid/api", "https://liquid.network/api"]
        }
        (ChainId::Liquid, AppNetwork::Testnet) => {
            &["https://blockstream.info/liquidtestnet/api", "https://liquid.network/liquidtestnet/api"]
        }
        // Local esplora (electrs default HTTP port).
        (ChainId::Bitcoin | ChainId::Liquid, AppNetwork::Regtest) => &["http://127.0.0.1:3002"],
        (ChainId::Lightning | ChainId::Aggregate, _) => &[],
    };
    urls.iter().map(|s| (*s).to_owned()).collect()
}

/// Round-robin endpoint resolver with stickiness on success.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EndpointResolver {
    endpoints: BTreeMap<ChainId, Vec<String>>,
    failure_threshold: u32,
    cursor: BTreeMap<ChainId, usize>,
    failures: BTreeMap<ChainId, u32>,
}

impl EndpointResolver {
    /// Resolver with explicit lists per chain.
    pub fn new(endpoints: BTreeMap<ChainId, Vec<String>>, failure_threshold: u32) -> Self {
        Self { endpoints, failure_threshold, cursor: BTreeMap::new(), failures: BTreeMap::new() }
    }

    /// Resolver with the default bitcoin and liquid lists for `network`.
    pub fn with_defaults(network: AppNetwork) -> Self {
        let endpoints =
            [ChainId::Bitcoin, ChainId::Liquid].into_iter().map(|c| (c, default_esplora_urls(c, network))).collect();
        Self::new(endpoints, DEFAULT_FAILURE_THRESHOLD)
    }

    /// Resolver with the default Electrum lists for `network`.
    pub fn with_electrum_defaults(network: AppNetwork) -> Self {
        let endpoints = [ChainId::Bitcoin, ChainId::Liquid]
            .into_iter()
            .map(|c| (c, super::backend::default_electrum_urls(c, network)))
            .collect();
        Self::new(endpoints, DEFAULT_FAILURE_THRESHOLD)
    }

    /// Resolver with the default lists of `backend` for `network`.
    pub fn for_backend(network: AppNetwork, backend: &super::backend::ChainBackend) -> Self {
        if backend.is_electrum() {
            Self::with_electrum_defaults(network)
        } else {
            Self::with_defaults(network)
        }
    }

    /// Applies the user's custom node setting for `chain`.
    ///
    /// Backs the `bitcoin_node_url` and `liquid_node_url` settings. A
    /// non-empty URL replaces the whole list, so the wallet uses only that
    /// node and never rotates away from it. An empty or blank URL keeps the
    /// defaults ("default mode").
    pub fn with_custom_node(mut self, chain: ChainId, url: &str) -> Self {
        let url = url.trim();
        if !url.is_empty() {
            self.endpoints.insert(chain, vec![url.to_owned()]);
            self.cursor.remove(&chain);
            self.failures.remove(&chain);
        }
        self
    }

    /// Configured list for a chain.
    pub fn endpoints(&self, chain: ChainId) -> &[String] {
        self.endpoints.get(&chain).map(Vec::as_slice).unwrap_or(&[])
    }

    /// Current endpoint for `chain`. Fails if the chain has no endpoints.
    pub fn current(&self, chain: ChainId) -> Result<&str> {
        let list = self.endpoints(chain);
        if list.is_empty() {
            return Err(Error::InvalidState(format!("no endpoints configured for {}", chain.as_str())));
        }
        let i = self.cursor.get(&chain).copied().unwrap_or(0);
        Ok(&list[i % list.len()])
    }

    /// Records a failure on the current endpoint. Rotates after the threshold.
    pub fn report_failure(&mut self, chain: ChainId) {
        let next = self.failures.get(&chain).copied().unwrap_or(0) + 1;
        self.failures.insert(chain, next);
        if next >= self.failure_threshold {
            let len = self.endpoints(chain).len();
            if len > 1 {
                let c = self.cursor.get(&chain).copied().unwrap_or(0);
                self.cursor.insert(chain, (c + 1) % len);
            }
            self.failures.insert(chain, 0);
        }
    }

    /// Records a success. Resets the failure counter.
    pub fn report_success(&mut self, chain: ChainId) {
        self.failures.insert(chain, 0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rotates_after_threshold_and_wraps() {
        let mut r = EndpointResolver::with_defaults(AppNetwork::Mainnet);
        assert_eq!(r.current(ChainId::Liquid).unwrap(), "https://blockstream.info/liquid/api");
        r.report_failure(ChainId::Liquid);
        assert_eq!(r.current(ChainId::Liquid).unwrap(), "https://blockstream.info/liquid/api");
        r.report_failure(ChainId::Liquid);
        assert_eq!(r.current(ChainId::Liquid).unwrap(), "https://liquid.network/api");
        // Bitcoin is independent.
        assert_eq!(r.current(ChainId::Bitcoin).unwrap(), "https://blockstream.info/api");
        r.report_failure(ChainId::Liquid);
        r.report_failure(ChainId::Liquid);
        assert_eq!(r.current(ChainId::Liquid).unwrap(), "https://blockstream.info/liquid/api");
    }

    #[test]
    fn success_resets_counter() {
        let mut r = EndpointResolver::with_defaults(AppNetwork::Mainnet);
        r.report_failure(ChainId::Bitcoin);
        r.report_success(ChainId::Bitcoin);
        r.report_failure(ChainId::Bitcoin);
        assert_eq!(r.current(ChainId::Bitcoin).unwrap(), "https://blockstream.info/api");
    }

    #[test]
    fn single_endpoint_never_rotates_and_missing_chain_errors() {
        let mut r = EndpointResolver::with_defaults(AppNetwork::Regtest);
        for _ in 0..5 {
            r.report_failure(ChainId::Bitcoin);
        }
        assert_eq!(r.current(ChainId::Bitcoin).unwrap(), "http://127.0.0.1:3002");
        assert!(r.current(ChainId::Lightning).is_err());
    }
}

#[cfg(test)]
mod backend_tests {
    use super::*;
    use crate::wallet::backend::ChainBackend;

    #[test]
    fn electrum_defaults_order() {
        let r = EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet);
        assert_eq!(r.current(ChainId::Bitcoin).unwrap(), "ssl://electrum.blockstream.info:50002");
        assert_eq!(r.current(ChainId::Liquid).unwrap(), "blockstream.info:995");
        let esplora = EndpointResolver::for_backend(AppNetwork::Mainnet, &ChainBackend::Esplora);
        assert_eq!(esplora.current(ChainId::Bitcoin).unwrap(), "https://blockstream.info/api");
    }

    #[test]
    fn custom_node_pins_and_never_rotates() {
        let mut r = EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet)
            .with_custom_node(ChainId::Bitcoin, " ssl://my.node:50002 ");
        for _ in 0..5 {
            r.report_failure(ChainId::Bitcoin);
        }
        assert_eq!(r.current(ChainId::Bitcoin).unwrap(), "ssl://my.node:50002");
        // Liquid keeps its default rotation.
        assert_eq!(r.endpoints(ChainId::Liquid).len(), 4);
    }

    #[test]
    fn blank_custom_node_keeps_defaults() {
        let r = EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet).with_custom_node(ChainId::Liquid, "  ");
        assert_eq!(r.endpoints(ChainId::Liquid).len(), 4);
    }
}
