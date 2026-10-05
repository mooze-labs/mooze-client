//! Wallet state lifecycle: the wallet-state steps of wallet import and delete.
//!
//! The core keeps wallet state under `KvStore` prefixes. The guard tracks
//! held prefixes, and a wipe deletes their keys.
//!
//! NOTE: the rest of import/delete (transaction store, notified-tx
//! registry, credentials, PIN, session and pix cleanup) belongs to the
//! store, sync and auth modules. Those steps are out of scope here.

use std::collections::BTreeSet;

use super::bitcoin::CHANGESET_KEY;
use super::liquid::store::{wipe_prefix, STORE_PREFIX};
use crate::ports::KvStore;
use crate::{Error, Result};

/// Namespace of the BDK wallet state.
pub const BITCOIN_NAMESPACE: &str = "wallet/bitcoin/";
/// Namespace of the LWK wallet state.
pub const LIQUID_NAMESPACE: &str = "wallet/liquid/";

/// Every wallet namespace the import and delete flows wipe.
pub const WALLET_NAMESPACES: [&str; 2] = [BITCOIN_NAMESPACE, LIQUID_NAMESPACE];

/// Exclusive holds on wallet namespaces. Two wallet instances must not
/// write the same namespace at once.
#[derive(Debug, Clone, Default)]
pub struct NamespaceGuard {
    held: BTreeSet<String>,
}

impl NamespaceGuard {
    /// Guard with no holds.
    pub fn new() -> Self {
        Self::default()
    }

    /// Takes the namespace. Fails if it is already held.
    ///
    /// NOTE: the core has no executor, so it does not wait for the holder.
    /// It fails, and the caller retries.
    pub fn acquire(&mut self, namespace: &str) -> Result<()> {
        if !self.held.insert(namespace.to_owned()) {
            return Err(Error::InvalidState(format!("namespace {namespace} is in use")));
        }
        Ok(())
    }

    /// Releases the namespace. Never fails.
    pub fn release(&mut self, namespace: &str) {
        self.held.remove(namespace);
    }

    /// True while held.
    pub fn is_held(&self, namespace: &str) -> bool {
        self.held.contains(namespace)
    }

    /// Force-releases the namespace and deletes its keys. A stuck lock does
    /// not block the wipe.
    pub async fn wipe<K: KvStore>(&mut self, kv: &K, namespace: &str) -> Result<usize> {
        self.held.remove(namespace);
        wipe_prefix(kv, namespace).await
    }
}

/// Deletes the stored state of both wallets. Use before importing a new
/// mnemonic and after deleting the wallet. Returns the deleted key count.
pub async fn wipe_wallet_state<K: KvStore>(kv: &K) -> Result<usize> {
    debug_assert!(CHANGESET_KEY.starts_with(BITCOIN_NAMESPACE));
    debug_assert!(STORE_PREFIX.starts_with(LIQUID_NAMESPACE));
    let mut n = 0;
    for ns in WALLET_NAMESPACES {
        n += wipe_prefix(kv, ns).await?;
    }
    Ok(n)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn guard_acquire_release_wipe() {
        let kv = MemoryKv::new();
        block_on(kv.put(CHANGESET_KEY, b"{}".to_vec())).unwrap();
        block_on(kv.put("wallet/liquid/store/x", vec![1])).unwrap();
        block_on(kv.put("tx/liquid/abc", vec![2])).unwrap();
        let mut g = NamespaceGuard::new();
        g.acquire(BITCOIN_NAMESPACE).unwrap();
        assert!(g.acquire(BITCOIN_NAMESPACE).is_err());
        g.release(BITCOIN_NAMESPACE);
        g.acquire(BITCOIN_NAMESPACE).unwrap();
        assert_eq!(block_on(g.wipe(&kv, BITCOIN_NAMESPACE)).unwrap(), 1);
        assert!(!g.is_held(BITCOIN_NAMESPACE));
        assert_eq!(block_on(wipe_wallet_state(&kv)).unwrap(), 1);
        assert_eq!(block_on(kv.list_keys("")).unwrap(), vec!["tx/liquid/abc".to_owned()]);
    }
}
