//! Custom chain node settings.
//!
//! An empty value means "default mode": the wallet rotates through the
//! built-in servers. Pass the value to
//! `wallet::EndpointResolver::with_custom_node`, which treats an empty URL
//! the same way.

use crate::domain::ChainId;
use crate::ports::KvStore;
use crate::{Error, Result};

use super::json::{delete_key, get_json, put_json};

/// Key of the Bitcoin node URL. The name is part of the stored data format.
pub const BITCOIN_NODE_URL_KEY: &str = "bitcoin_node_url";
/// Key of the Liquid node URL. The name is part of the stored data format.
pub const LIQUID_NODE_URL_KEY: &str = "liquid_node_url";

/// Store of the user's custom node URLs.
#[derive(Debug, Clone)]
pub struct NodeSettings<K: KvStore> {
    kv: K,
}

impl<K: KvStore> NodeSettings<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// Key for a chain. Only Bitcoin and Liquid have node settings.
    pub fn key(chain: ChainId) -> Result<&'static str> {
        match chain {
            ChainId::Bitcoin => Ok(BITCOIN_NODE_URL_KEY),
            ChainId::Liquid => Ok(LIQUID_NODE_URL_KEY),
            other => Err(Error::invalid(format!("no node setting for {}", other.as_str()))),
        }
    }

    /// Custom node URL, or an empty string in default mode.
    pub async fn node_url(&self, chain: ChainId) -> Result<String> {
        Ok(get_json::<K, String>(&self.kv, Self::key(chain)?).await?.unwrap_or_default())
    }

    /// Sets the custom node URL. A blank URL returns to default mode.
    pub async fn set_node_url(&self, chain: ChainId, url: &str) -> Result<()> {
        let url = url.trim();
        if url.is_empty() {
            return self.clear(chain).await;
        }
        put_json(&self.kv, Self::key(chain)?, &url).await
    }

    /// Returns to default mode.
    pub async fn clear(&self, chain: ChainId) -> Result<()> {
        delete_key(&self.kv, Self::key(chain)?).await
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn node_url_roundtrip_and_default_mode() {
        let s = NodeSettings::new(MemoryKv::new());
        block_on(async {
            assert_eq!(s.node_url(ChainId::Bitcoin).await.unwrap(), "");
            s.set_node_url(ChainId::Bitcoin, " ssl://my.node:50002 ").await.unwrap();
            assert_eq!(s.node_url(ChainId::Bitcoin).await.unwrap(), "ssl://my.node:50002");
            assert_eq!(s.node_url(ChainId::Liquid).await.unwrap(), "");
            s.set_node_url(ChainId::Bitcoin, "   ").await.unwrap();
            assert_eq!(s.node_url(ChainId::Bitcoin).await.unwrap(), "");
            assert!(s.node_url(ChainId::Lightning).await.is_err());
        });
    }
}
