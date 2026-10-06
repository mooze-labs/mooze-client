use mooze_core::{ports::KvStore, Error, Result};
use std::{collections::BTreeMap, io::Write, path::PathBuf, sync::Arc};
#[derive(Clone)]
pub struct FileKv {
    file: Arc<PathBuf>,
    gate: Arc<tokio::sync::Mutex<()>>,
}
impl FileKv {
    pub fn open(dir: PathBuf) -> Result<Self> {
        std::fs::create_dir_all(&dir).map_err(Error::storage)?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&dir, std::fs::Permissions::from_mode(0o700))
                .map_err(Error::storage)?;
        }
        Ok(Self {
            file: Arc::new(dir.join("wallet.json")),
            gate: Arc::new(tokio::sync::Mutex::new(())),
        })
    }
    async fn access<T: Send + 'static>(
        &self,
        f: impl FnOnce(&mut BTreeMap<String, Vec<u8>>) -> Result<T> + Send + 'static,
        write: bool,
    ) -> Result<T> {
        let _guard = self.gate.lock().await;
        let file = self.file.clone();
        tokio::task::spawn_blocking(move || {
            let mut data: BTreeMap<String, Vec<u8>> = match std::fs::read(file.as_ref()) {
                Ok(v) => serde_json::from_slice(&v).map_err(Error::storage)?,
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => BTreeMap::new(),
                Err(e) => return Err(Error::storage(e)),
            };
            let result = f(&mut data)?;
            if write {
                let tmp = file.with_extension(format!("{}.tmp", uuid::Uuid::new_v4()));
                let bytes = serde_json::to_vec(&data).map_err(Error::storage)?;
                let mut options = std::fs::OpenOptions::new();
                options.write(true).create_new(true);
                #[cfg(unix)]
                {
                    use std::os::unix::fs::OpenOptionsExt;
                    options.mode(0o600);
                }
                let mut handle = options.open(&tmp).map_err(Error::storage)?;
                handle.write_all(&bytes).map_err(Error::storage)?;
                handle.sync_all().map_err(Error::storage)?;
                std::fs::rename(&tmp, file.as_ref()).map_err(Error::storage)?;
                // The submission journal must survive a crash before broadcast starts.
                #[cfg(unix)]
                std::fs::File::open(file.parent().expect("wallet directory"))
                    .and_then(|directory| directory.sync_all())
                    .map_err(Error::storage)?;
            }
            Ok(result)
        })
        .await
        .map_err(Error::storage)?
    }
}
impl KvStore for FileKv {
    async fn get(&self, key: &str) -> Result<Option<Vec<u8>>> {
        let key = key.to_owned();
        self.access(move |d| Ok(d.get(&key).cloned()), false).await
    }
    async fn put(&self, key: &str, value: Vec<u8>) -> Result<()> {
        if key.is_empty() {
            return Err(Error::storage("empty key"));
        }
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
#[cfg(test)]
mod tests {
    use super::*;
    use mooze_core::ports::KvStore;
    #[tokio::test]
    async fn atomic_store_roundtrip_and_namespace() {
        let dir = tempfile::tempdir().unwrap();
        let store = FileKv::open(dir.path().join("testnet")).unwrap();
        assert_eq!(store.get("x").await.unwrap(), None);
        let (a, b) = tokio::join!(store.put("a/b", vec![1]), store.put("a/b", vec![2]));
        a.unwrap();
        b.unwrap();
        assert!(matches!(
            store.get("a/b").await.unwrap().as_deref(),
            Some([1]) | Some([2])
        ));
        assert_eq!(store.list_keys("a/").await.unwrap(), vec!["a/b"]);
        store.delete("a/b").await.unwrap();
        assert!(store.list_keys("").await.unwrap().is_empty());
        assert!(store.put("", vec![]).await.is_err());
        store.put("../outside", vec![3]).await.unwrap();
        assert!(!dir.path().join("outside").exists());
    }
}
