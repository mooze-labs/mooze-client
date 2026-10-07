//! Chain backend selection: esplora (all targets) or Electrum (native only).
//!
//! Mobile clients talk Electrum. The browser cannot open TCP sockets, so
//! the core defaults to esplora over HTTP. Native builds can enable the
//! `electrum` feature to keep the servers the app uses today, including a
//! user's own node.
//!
//! The Electrum clients only offer blocking calls. Each call runs through a
//! [`BlockingSpawner`], so it never stalls the async executor.
//!
//! TLS note: LWK enables the default features of `electrum-client`, which
//! compile rustls with the aws-lc backend. Our `bdk_electrum` dependency
//! enables the ring backend. `electrum-client` installs ring as the process
//! default before it builds a TLS config, so the two never conflict at run
//! time. Native builds still compile aws-lc, which needs a C toolchain.

use std::fmt;
use std::sync::Arc;

use crate::domain::{AppNetwork, ChainId};
use crate::ports::BlockingSpawner;

/// Default timeout of one Electrum request, in seconds.
pub const ELECTRUM_TIMEOUT_S: u8 = 30;
/// Default Electrum retry count.
pub const ELECTRUM_RETRY: u8 = 5;
/// Scripts per Electrum batch request.
pub const ELECTRUM_BATCH_SIZE: usize = 100;

/// Settings of the Electrum backend.
#[derive(Clone)]
pub struct ElectrumConfig {
    /// Runs the blocking Electrum calls.
    pub spawner: Arc<dyn BlockingSpawner>,
    /// Timeout of one request, in seconds.
    pub timeout_s: u8,
    /// Connection retries.
    pub retry: u8,
    /// Checks the TLS certificate against the host name.
    pub validate_domain: bool,
}

impl ElectrumConfig {
    /// Defaults: 30 s timeout, 5 retries, domain validation on.
    pub fn new(spawner: Arc<dyn BlockingSpawner>) -> Self {
        Self { spawner, timeout_s: ELECTRUM_TIMEOUT_S, retry: ELECTRUM_RETRY, validate_domain: true }
    }
}

impl fmt::Debug for ElectrumConfig {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("ElectrumConfig")
            .field("timeout_s", &self.timeout_s)
            .field("retry", &self.retry)
            .field("validate_domain", &self.validate_domain)
            .finish_non_exhaustive()
    }
}

/// Which protocol a wallet uses to reach the chain.
#[derive(Debug, Clone, Default)]
pub enum ChainBackend {
    /// Esplora HTTP API. Works on every target.
    #[default]
    Esplora,
    /// Electrum over TCP or TLS. Native targets only.
    Electrum(ElectrumConfig),
}

impl ChainBackend {
    /// True for [`ChainBackend::Electrum`].
    pub fn is_electrum(&self) -> bool {
        matches!(self, ChainBackend::Electrum(_))
    }
}

/// Default Electrum servers for a chain and network, preferred first.
///
/// Liquid mainnet entries are bare `host:port` and use TLS. Testnet uses the
/// Blockstream testnet servers. Regtest uses a local electrs.
pub fn default_electrum_urls(chain: ChainId, network: AppNetwork) -> Vec<String> {
    let urls: &[&str] = match (chain, network) {
        (ChainId::Bitcoin, AppNetwork::Mainnet) => &[
            "ssl://electrum.blockstream.info:50002",
            "ssl://btc.aftrek.org:50002",
            "ssl://fulcrum.sethforprivacy.com:50002",
            "ssl://electrum.bitaroo.net:50002",
        ],
        (ChainId::Liquid, AppNetwork::Mainnet) => {
            &["blockstream.info:995", "electrs.blockstream.info:995", "liquid.network:995", "les.bullbitcoin.com:995"]
        }
        (ChainId::Bitcoin, AppNetwork::Testnet) => &["ssl://electrum.blockstream.info:60002"],
        (ChainId::Liquid, AppNetwork::Testnet) => &["blockstream.info:465"],
        (ChainId::Bitcoin | ChainId::Liquid, AppNetwork::Regtest) => &["tcp://127.0.0.1:60401"],
        (ChainId::Lightning | ChainId::Aggregate, _) => &[],
    };
    urls.iter().map(|s| (*s).to_owned()).collect()
}

/// Adds `ssl://` to a bare `host:port`. URLs with a scheme stay unchanged.
///
/// Default Liquid entries have no scheme and use TLS. A user's custom node
/// setting can also lack a scheme. TLS is the safe reading of both.
pub fn normalize_electrum_url(url: &str) -> String {
    let url = url.trim();
    if url.starts_with("ssl://") || url.starts_with("tcp://") {
        url.to_owned()
    } else {
        format!("ssl://{url}")
    }
}

#[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
pub use electrum::{BitcoinElectrum, LiquidElectrum};

#[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
mod electrum {
    use std::collections::HashMap;
    use std::sync::{Arc, Mutex};
    use std::time::Duration;

    use bdk_electrum::electrum_client::{self, ConfigBuilder, ElectrumApi};
    use bdk_electrum::BdkElectrumClient;
    use bdk_wallet::bitcoin::Transaction as BtcTransaction;
    use bdk_wallet::chain::spk_client::{FullScanRequest, SyncRequest};
    use bdk_wallet::KeychainKind;
    use lwk_wollet::clients::blocking::BlockchainBackend;
    use lwk_wollet::elements::Transaction as LiquidTransaction;
    use lwk_wollet::{ElectrumClientBuilder, Update, Wollet};

    use super::{normalize_electrum_url, ElectrumConfig, ELECTRUM_BATCH_SIZE};
    use crate::ports::run_blocking;
    use crate::{Error, Result};

    /// Electrum fee targets queried, in blocks. Covers every target the
    /// fee mapping reads.
    const FEE_TARGETS: [u16; 6] = [1, 2, 3, 6, 12, 25];

    fn net(e: impl std::fmt::Display) -> Error {
        Error::Network(e.to_string())
    }

    /// Blocking BDK Electrum client for one server. Clones share the connection.
    #[derive(Clone)]
    pub struct BitcoinElectrum {
        url: String,
        config: ElectrumConfig,
        client: Arc<BdkElectrumClient<electrum_client::Client>>,
    }

    impl BitcoinElectrum {
        /// Opens a connection to `url`. The connect itself blocks, so it
        /// runs through the spawner too.
        pub async fn connect(url: &str, config: &ElectrumConfig) -> Result<Self> {
            let normalized = normalize_electrum_url(url);
            let electrum_config = ConfigBuilder::new()
                .timeout(Some(Duration::from_secs(u64::from(config.timeout_s))))
                .retry(config.retry)
                .validate_domain(config.validate_domain)
                .build();
            let target = normalized.clone();
            let client = run_blocking(config.spawner.as_ref(), move || {
                electrum_client::Client::from_config(&target, electrum_config)
            })
            .await?
            .map_err(net)?;
            Ok(Self { url: url.to_owned(), config: config.clone(), client: Arc::new(BdkElectrumClient::new(client)) })
        }

        /// Server URL as configured, before normalization.
        pub fn url(&self) -> &str {
            &self.url
        }

        /// Full scan of both keychains.
        pub async fn full_scan(
            &self,
            request: FullScanRequest<KeychainKind>,
            stop_gap: usize,
        ) -> Result<bdk_wallet::Update> {
            let client = self.client.clone();
            let response = run_blocking(self.config.spawner.as_ref(), move || {
                client.full_scan(request, stop_gap, ELECTRUM_BATCH_SIZE, true)
            })
            .await?
            .map_err(net)?;
            Ok(response.into())
        }

        /// Sync of the revealed scripts.
        pub async fn sync(&self, request: SyncRequest<(KeychainKind, u32)>) -> Result<bdk_wallet::Update> {
            let client = self.client.clone();
            let response =
                run_blocking(self.config.spawner.as_ref(), move || client.sync(request, ELECTRUM_BATCH_SIZE, true))
                    .await?
                    .map_err(net)?;
            Ok(response.into())
        }

        /// Broadcasts a signed transaction. Returns the txid.
        pub async fn broadcast(&self, tx: BtcTransaction) -> Result<String> {
            let client = self.client.clone();
            let txid = run_blocking(self.config.spawner.as_ref(), move || client.transaction_broadcast(&tx))
                .await?
                .map_err(net)?;
            Ok(txid.to_string())
        }

        /// Chain tip height.
        pub async fn tip_height(&self) -> Result<u32> {
            let client = self.client.clone();
            let header = run_blocking(self.config.spawner.as_ref(), move || client.inner.block_headers_subscribe())
                .await?
                .map_err(net)?;
            u32::try_from(header.height).map_err(|_| Error::protocol("electrum tip height out of range"))
        }

        /// Fee rates in sat/vB per confirmation target.
        ///
        /// Electrum answers in BTC/kvB, so each value is multiplied by
        /// 100 000. Negative answers mean "no estimate" and are left out.
        pub async fn fee_estimates(&self) -> Result<HashMap<u16, f64>> {
            let client = self.client.clone();
            run_blocking(self.config.spawner.as_ref(), move || {
                let mut out = HashMap::new();
                for target in FEE_TARGETS {
                    let btc_per_kvb = client.inner.estimate_fee(usize::from(target), None).map_err(net)?;
                    if btc_per_kvb > 0.0 {
                        out.insert(target, btc_per_kvb * 100_000.0);
                    }
                }
                Ok(out)
            })
            .await?
        }
    }

    /// Blocking LWK Electrum client for one server. Clones share the connection.
    #[derive(Clone)]
    pub struct LiquidElectrum {
        url: String,
        config: ElectrumConfig,
        client: Arc<Mutex<lwk_wollet::ElectrumClient>>,
    }

    impl LiquidElectrum {
        /// Opens a connection to `url`.
        pub async fn connect(url: &str, config: &ElectrumConfig) -> Result<Self> {
            let normalized = normalize_electrum_url(url);
            let timeout = Duration::from_secs(u64::from(config.timeout_s));
            let client = run_blocking(config.spawner.as_ref(), move || {
                ElectrumClientBuilder::new(&normalized).timeout(timeout).build()
            })
            .await?
            .map_err(net)?;
            Ok(Self { url: url.to_owned(), config: config.clone(), client: Arc::new(Mutex::new(client)) })
        }

        /// Server URL as configured, before normalization.
        pub fn url(&self) -> &str {
            &self.url
        }

        /// Full scan of `wollet`. The caller applies the returned update.
        ///
        /// The scan works on a snapshot of the wollet state taken now, so the
        /// returned future does not borrow the wollet. LWK does not export the
        /// snapshot type, so it stays inferred inside this function.
        pub fn full_scan(
            &self,
            wollet: &Wollet,
        ) -> impl std::future::Future<Output = Result<Option<Update>>> + Send + 'static {
            let state = wollet.state();
            let client = self.client.clone();
            let spawner = self.config.spawner.clone();
            async move {
                run_blocking(spawner.as_ref(), move || {
                    let mut guard =
                        client.lock().map_err(|_| Error::Unexpected("electrum client lock poisoned".into()))?;
                    guard.full_scan(&state).map_err(net)
                })
                .await?
            }
        }

        /// Broadcasts a finalized transaction. Returns the txid.
        pub async fn broadcast(&self, tx: LiquidTransaction) -> Result<String> {
            let client = self.client.clone();
            run_blocking(self.config.spawner.as_ref(), move || {
                let guard = client.lock().map_err(|_| Error::Unexpected("electrum client lock poisoned".into()))?;
                guard.broadcast(&tx).map(|t| t.to_string()).map_err(net)
            })
            .await?
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mainnet_lists_order() {
        let btc = default_electrum_urls(ChainId::Bitcoin, AppNetwork::Mainnet);
        assert_eq!(btc[0], "ssl://electrum.blockstream.info:50002");
        assert_eq!(btc.len(), 4);
        let lq = default_electrum_urls(ChainId::Liquid, AppNetwork::Mainnet);
        assert_eq!(
            lq,
            ["blockstream.info:995", "electrs.blockstream.info:995", "liquid.network:995", "les.bullbitcoin.com:995"]
        );
        assert!(default_electrum_urls(ChainId::Lightning, AppNetwork::Mainnet).is_empty());
    }

    #[test]
    fn normalizes_bare_hosts_to_tls() {
        assert_eq!(normalize_electrum_url("blockstream.info:995"), "ssl://blockstream.info:995");
        assert_eq!(normalize_electrum_url(" tcp://10.0.0.2:50001 "), "tcp://10.0.0.2:50001");
        assert_eq!(normalize_electrum_url("ssl://x:1"), "ssl://x:1");
    }

    #[test]
    fn default_backend_is_esplora() {
        assert!(!ChainBackend::default().is_electrum());
    }
}

#[cfg(test)]
mod desktop_node_tests {
    use super::*;
    #[test]
    fn testnet_node_evidence_rejects_mainnet_and_wrong_chain() {
        let btc = bdk_wallet::bitcoin::constants::genesis_block(bdk_wallet::bitcoin::Network::Testnet)
            .block_hash()
            .to_string();
        let liquid = lwk_common::Network::TestnetLiquid.genesis_hash().to_string();
        assert!(validate_testnet_genesis(ChainId::Bitcoin, &btc).is_ok());
        assert!(validate_testnet_genesis(ChainId::Liquid, &liquid).is_ok());
        assert!(validate_testnet_genesis(ChainId::Bitcoin, &liquid).is_err());
        assert!(validate_testnet_genesis(ChainId::Liquid, &btc).is_err());
        assert!(validate_testnet_genesis(
            ChainId::Bitcoin,
            &bdk_wallet::bitcoin::constants::genesis_block(bdk_wallet::bitcoin::Network::Bitcoin)
                .block_hash()
                .to_string()
        )
        .is_err());
    }
}

/// Compare server-provided chain identity with the exact networks this desktop supports.
pub fn validate_testnet_genesis(chain: ChainId, genesis: &str) -> crate::Result<()> {
    validate_genesis(chain, AppNetwork::Testnet, genesis)
}
pub fn validate_genesis(chain: ChainId, network: AppNetwork, genesis: &str) -> crate::Result<()> {
    let expected = match chain {
        ChainId::Bitcoin => bdk_wallet::bitcoin::constants::genesis_block(match network {
            AppNetwork::Mainnet => bdk_wallet::bitcoin::Network::Bitcoin,
            AppNetwork::Testnet => bdk_wallet::bitcoin::Network::Testnet,
            AppNetwork::Regtest => bdk_wallet::bitcoin::Network::Regtest,
        })
        .block_hash()
        .to_string(),
        ChainId::Liquid => (match network {
            AppNetwork::Mainnet => lwk_common::Network::Liquid,
            AppNetwork::Testnet => lwk_common::Network::TestnetLiquid,
            AppNetwork::Regtest => lwk_common::Network::default_regtest(),
        })
        .genesis_hash()
        .to_string(),
        _ => return Err(crate::Error::InvalidInput("unsupported chain".into())),
    };
    if !genesis.eq_ignore_ascii_case(&expected) {
        return Err(crate::Error::InvalidInput("node is not on the requested network".into()));
    }
    Ok(())
}

/// Read public server metadata without sending any wallet address or descriptor.
#[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
pub async fn probe_testnet_node(chain: ChainId, url: &str, config: &ElectrumConfig) -> crate::Result<String> {
    probe_node(chain, AppNetwork::Testnet, url, config).await
}
#[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
pub async fn probe_node(
    chain: ChainId,
    network: AppNetwork,
    url: &str,
    config: &ElectrumConfig,
) -> crate::Result<String> {
    use bdk_electrum::electrum_client::{Client, ConfigBuilder, ElectrumApi};
    let target = normalize_electrum_url(url);
    let options =
        ConfigBuilder::new().timeout(Some(std::time::Duration::from_secs(5))).retry(0).validate_domain(true).build();
    let genesis = crate::ports::run_blocking(config.spawner.as_ref(), move || -> crate::Result<String> {
        let client = Client::from_config(&target, options).map_err(|e| crate::Error::Network(e.to_string()))?;
        let features =
            client.raw_call("server.features", std::iter::empty()).map_err(|e| crate::Error::Network(e.to_string()))?;
        features
            .get("genesis_hash")
            .and_then(|v| v.as_str())
            .map(str::to_owned)
            .ok_or_else(|| crate::Error::protocol("node did not provide a genesis hash"))
    })
    .await??;
    validate_genesis(chain, network, &genesis)?;
    Ok(genesis)
}
