use mooze_core::{
    ports::{KvStore, SecureStore},
    Error, Result,
};
use std::{collections::BTreeMap, sync::Arc};
/// One encrypted OS credential item. The index and values are committed together.
#[derive(Clone)]
pub struct KeyringStore {
    service: String,
    gate: Arc<tokio::sync::Mutex<()>>,
}
impl KeyringStore {
    pub fn new(service: String) -> Self {
        Self {
            service,
            gate: Arc::new(tokio::sync::Mutex::new(())),
        }
    }
    async fn access<T: Send + 'static>(
        &self,
        f: impl FnOnce(&mut BTreeMap<String, Vec<u8>>) -> Result<T> + Send + 'static,
        write: bool,
    ) -> Result<T> {
        let service = self.service.clone();
        self.blocking(move || {
            let entry = keyring::Entry::new(&service, "wallet-secrets")
                .map_err(|_| Error::storage("credential store unavailable"))?;
            let mut data: BTreeMap<String, Vec<u8>> = match entry.get_secret() {
                Ok(v) => serde_json::from_slice(&v)
                    .map_err(|_| Error::storage("invalid credential data"))?,
                Err(keyring::Error::NoEntry) => BTreeMap::new(),
                Err(_) => return Err(Error::storage("credential access denied")),
            };
            let result = f(&mut data)?;
            if write {
                let bytes = serde_json::to_vec(&data).map_err(Error::storage)?;
                entry
                    .set_secret(&bytes)
                    .map_err(|_| Error::storage("credential write denied"))?;
            }
            Ok(result)
        })
        .await
    }
    async fn blocking<T: Send + 'static>(
        &self,
        operation: impl FnOnce() -> Result<T> + Send + 'static,
    ) -> Result<T> {
        let guard = self.gate.clone().lock_owned().await;
        tokio::task::spawn_blocking(move || {
            // Cancellation must not release serialization while an OS credential
            // read/modify/write is still running. Removal waits for this guard too.
            let _guard = guard;
            operation()
        })
        .await
        .map_err(Error::storage)?
    }
}
impl KvStore for KeyringStore {
    async fn get(&self, key: &str) -> Result<Option<Vec<u8>>> {
        let key = key.to_owned();
        self.access(move |d| Ok(d.get(&key).cloned()), false).await
    }
    async fn put(&self, key: &str, value: Vec<u8>) -> Result<()> {
        let key = key.to_owned();
        self.access(
            move |d| {
                d.insert(key, value);
                Ok(())
            },
            true,
        )
        .await
    }
    async fn delete(&self, key: &str) -> Result<()> {
        let key = key.to_owned();
        self.access(
            move |d| {
                d.remove(&key);
                Ok(())
            },
            true,
        )
        .await
    }
    async fn list_keys(&self, prefix: &str) -> Result<Vec<String>> {
        let prefix = prefix.to_owned();
        self.access(
            move |d| {
                Ok(d.keys()
                    .filter(|k| k.starts_with(&prefix))
                    .cloned()
                    .collect())
            },
            false,
        )
        .await
    }
}
impl SecureStore for KeyringStore {}

#[cfg(test)]
mod tests {
    use super::*;
    #[tokio::test]
    async fn cancellation_preserves_serialization_until_blocking_write_finishes() {
        let store = KeyringStore::new("unused-test-no-keychain-access".into());
        let (started_tx, started_rx) = tokio::sync::oneshot::channel();
        let (finish_tx, finish_rx) = std::sync::mpsc::channel();
        let worker_store = store.clone();
        let worker = tokio::spawn(async move {
            worker_store
                .blocking(move || {
                    started_tx.send(()).unwrap();
                    finish_rx.recv().unwrap();
                    Ok(())
                })
                .await
        });
        started_rx.await.unwrap();
        worker.abort();
        let _ = worker.await;
        let gate_still_held = store.gate.try_lock().is_err();
        finish_tx.send(()).unwrap();
        store.blocking(|| Ok(())).await.unwrap();
        assert!(
            gate_still_held,
            "cancelled caller released an in-flight credential write"
        );
    }
}
