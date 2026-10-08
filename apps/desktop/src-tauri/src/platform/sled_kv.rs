//! Desktop persistence using sled. Each successful mutation is flushed to disk.
use mooze_core::{ports::KvStore, Error, Result};
use std::{path::PathBuf, sync::Arc};

#[derive(Clone)]
pub struct SledKv {
    db: sled::Db,
    gate: Arc<tokio::sync::Mutex<()>>,
}

impl SledKv {
    pub fn open(dir: PathBuf) -> Result<Self> {
        std::fs::create_dir_all(&dir).map_err(Error::storage)?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&dir, std::fs::Permissions::from_mode(0o700))
                .map_err(Error::storage)?;
        }
        let db = sled::open(dir.join("wallet.sled")).map_err(Error::storage)?;
        Ok(Self {
            db,
            gate: Arc::new(tokio::sync::Mutex::new(())),
        })
    }

    async fn access<T: Send + 'static>(
        &self,
        f: impl FnOnce(&sled::Db) -> Result<T> + Send + 'static,
        write: bool,
    ) -> Result<T> {
        let guard = self.gate.clone().lock_owned().await;
        let db = self.db.clone();
        tokio::task::spawn_blocking(move || {
            // Keep operations serialized through the flush even if the caller
            // is cancelled: wallet cleanup must wait for in-flight writes.
            let _guard = guard;
            let result = f(&db)?;
            if write {
                // Submission journals must be durable before broadcast begins.
                db.flush().map_err(Error::storage)?;
            }
            Ok(result)
        })
        .await
        .map_err(Error::storage)?
    }
}

impl KvStore for SledKv {
    async fn get(&self, key: &str) -> Result<Option<Vec<u8>>> {
        let key = key.to_owned();
        self.access(
            move |db| {
                db.get(key)
                    .map(|value| value.map(|v| v.to_vec()))
                    .map_err(Error::storage)
            },
            false,
        )
        .await
    }

    async fn put(&self, key: &str, value: Vec<u8>) -> Result<()> {
        if key.is_empty() {
            return Err(Error::storage("empty key"));
        }
        let key = key.to_owned();
        self.access(
            move |db| db.insert(key, value).map(|_| ()).map_err(Error::storage),
            true,
        )
        .await
    }

    async fn delete(&self, key: &str) -> Result<()> {
        let key = key.to_owned();
        self.access(
            move |db| db.remove(key).map(|_| ()).map_err(Error::storage),
            true,
        )
        .await
    }

    async fn list_keys(&self, prefix: &str) -> Result<Vec<String>> {
        let prefix = prefix.to_owned();
        self.access(
            move |db| {
                db.scan_prefix(prefix)
                    .map(|entry| {
                        let (key, _) = entry.map_err(Error::storage)?;
                        String::from_utf8(key.to_vec()).map_err(Error::storage)
                    })
                    .collect()
            },
            false,
        )
        .await
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    use mooze_core::ports::KvStore;
    #[tokio::test]
    async fn fresh_database_ignores_legacy_json_and_persists_changes() {
        let dir = tempfile::tempdir().unwrap();
        let legacy = dir.path().join("wallet.json");
        let original = br#"{"tx/old":[1,2,3]}"#;
        std::fs::write(&legacy, original).unwrap();
        let store = SledKv::open(dir.path().to_owned()).unwrap();
        assert_eq!(store.get("tx/old").await.unwrap(), None);
        store.put("tx/new", vec![0, 255, 4]).await.unwrap();
        store.put("tx/deleted", vec![]).await.unwrap();
        store.delete("tx/deleted").await.unwrap();
        drop(store);
        assert_eq!(std::fs::read(&legacy).unwrap(), original);
        let reopened = SledKv::open(dir.path().to_owned()).unwrap();
        assert_eq!(reopened.get("tx/new").await.unwrap(), Some(vec![0, 255, 4]));
        assert_eq!(reopened.list_keys("").await.unwrap(), vec!["tx/new"]);
    }

    #[tokio::test]
    async fn blocking_job_retains_gate_until_completion() {
        let dir = tempfile::tempdir().unwrap();
        let store = SledKv::open(dir.path().join("isolated")).unwrap();
        let (entered_tx, entered_rx) = tokio::sync::oneshot::channel();
        let (release_tx, release_rx) = std::sync::mpsc::channel();
        let worker_store = store.clone();
        let worker = tokio::spawn(async move {
            worker_store
                .access(
                    move |db| {
                        let _ = entered_tx.send(());
                        release_rx.recv().unwrap();
                        db.insert("cancelled-write", vec![7])
                            .map_err(Error::storage)?;
                        Ok(())
                    },
                    true,
                )
                .await
        });
        entered_rx.await.unwrap();
        worker.abort();
        let _ = worker.await;
        let still_owned = store.gate.try_lock().is_err();
        release_tx.send(()).unwrap();
        // Always release the worker before asserting to avoid a hanging test runtime.
        assert!(still_owned);
        store.put("after-job", vec![1]).await.unwrap();
        assert_eq!(store.get("after-job").await.unwrap(), Some(vec![1]));
        assert_eq!(store.get("cancelled-write").await.unwrap(), Some(vec![7]));
    }
    #[tokio::test]
    async fn atomic_store_roundtrip_and_namespace() {
        let dir = tempfile::tempdir().unwrap();
        let store = SledKv::open(dir.path().join("testnet")).unwrap();
        assert_eq!(store.get("x").await.unwrap(), None);
        let (a, b) = tokio::join!(store.put("a/b", vec![1]), store.put("a/b", vec![2]));
        a.unwrap();
        b.unwrap();
        assert!(matches!(
            store.get("a/b").await.unwrap().as_deref(),
            Some([1]) | Some([2])
        ));
        store.put("a/é", vec![]).await.unwrap();
        store.put("a/a", vec![3]).await.unwrap();
        store.put("ab/other", vec![4]).await.unwrap();
        assert_eq!(store.get("a/é").await.unwrap(), Some(vec![]));
        assert_eq!(
            store.list_keys("a/").await.unwrap(),
            vec!["a/a", "a/b", "a/é"]
        );
        assert!(store.list_keys("missing/").await.unwrap().is_empty());
        store.delete("a/a").await.unwrap();
        store.delete("a/é").await.unwrap();
        store.delete("ab/other").await.unwrap();
        store.delete("missing").await.unwrap();
        store.delete("a/b").await.unwrap();
        assert!(store.list_keys("").await.unwrap().is_empty());
        assert!(store.put("", vec![]).await.is_err());
        store.put("../outside", vec![3]).await.unwrap();
        assert!(!dir.path().join("outside").exists());
    }
}
