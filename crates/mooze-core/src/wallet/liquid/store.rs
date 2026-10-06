//! `lwk_common::Store` backed by a [`KvStore`].
//!
//! LWK calls its store synchronously; `KvStore` is async. The journal
//! keeps every entry in memory, records writes as dirty, and the wallet
//! flushes the dirty set to the `KvStore` after each operation. On connect
//! the wallet preloads the journal from the `KvStore`.
//!
//! LWK encrypts the values with a key derived from the descriptor, because
//! the store reports `is_persisted() == true`. This replaces the Dart
//! `lwk-db` directory.

use std::collections::BTreeMap;
use std::sync::{Arc, Mutex};

use crate::ports::KvStore;
use crate::{Error, Result};

/// KV prefix of the LWK store entries.
pub const STORE_PREFIX: &str = "wallet/liquid/store/";

/// Error of the journal store (only a poisoned lock).
#[derive(Debug, thiserror::Error)]
#[error("liquid journal store: {0}")]
pub struct JournalError(String);

#[derive(Debug, Default)]
struct Journal {
    data: BTreeMap<String, Vec<u8>>,
    /// `Some` = put, `None` = delete.
    dirty: BTreeMap<String, Option<Vec<u8>>>,
}

/// In-memory LWK store that tracks unsaved writes.
#[derive(Debug, Clone, Default)]
pub struct JournalStore {
    inner: Arc<Mutex<Journal>>,
}

impl JournalStore {
    /// Empty journal.
    pub fn new() -> Self {
        Self::default()
    }

    /// Journal preloaded with clean entries.
    pub fn from_entries(entries: impl IntoIterator<Item = (String, Vec<u8>)>) -> Self {
        let j = Journal {
            data: entries.into_iter().collect(),
            dirty: BTreeMap::new(),
        };
        Self {
            inner: Arc::new(Mutex::new(j)),
        }
    }

    fn lock(&self) -> std::result::Result<std::sync::MutexGuard<'_, Journal>, JournalError> {
        self.inner.lock().map_err(|e| JournalError(e.to_string()))
    }

    /// Number of entries.
    pub fn len(&self) -> usize {
        self.lock().map(|j| j.data.len()).unwrap_or(0)
    }

    /// True if there are no entries.
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Removes and returns the unsaved writes.
    pub fn take_dirty(&self) -> BTreeMap<String, Option<Vec<u8>>> {
        self.lock()
            .map(|mut j| std::mem::take(&mut j.dirty))
            .unwrap_or_default()
    }

    /// Puts unsaved writes back (after a failed flush). Newer writes win.
    pub fn restore_dirty(&self, dirty: BTreeMap<String, Option<Vec<u8>>>) {
        if let Ok(mut j) = self.lock() {
            for (k, v) in dirty {
                j.dirty.entry(k).or_insert(v);
            }
        }
    }
}

fn key_str(key: &[u8]) -> std::result::Result<String, JournalError> {
    String::from_utf8(key.to_vec()).map_err(|e| JournalError(e.to_string()))
}

impl lwk_common::Store for JournalStore {
    type Error = JournalError;

    fn get<K: AsRef<[u8]>>(&self, key: K) -> std::result::Result<Option<Vec<u8>>, Self::Error> {
        let k = key_str(key.as_ref())?;
        Ok(self.lock()?.data.get(&k).cloned())
    }

    fn put<K: AsRef<[u8]>, V: AsRef<[u8]>>(
        &self,
        key: K,
        value: V,
    ) -> std::result::Result<(), Self::Error> {
        let k = key_str(key.as_ref())?;
        let v = value.as_ref().to_vec();
        let mut j = self.lock()?;
        j.data.insert(k.clone(), v.clone());
        j.dirty.insert(k, Some(v));
        Ok(())
    }

    fn remove<K: AsRef<[u8]>>(&self, key: K) -> std::result::Result<(), Self::Error> {
        let k = key_str(key.as_ref())?;
        let mut j = self.lock()?;
        j.data.remove(&k);
        j.dirty.insert(k, None);
        Ok(())
    }

    fn is_persisted(&self) -> bool {
        true
    }
}

/// Loads every entry under `prefix` into a clean journal.
pub async fn load_journal<K: KvStore>(kv: &K, prefix: &str) -> Result<JournalStore> {
    let mut entries = Vec::new();
    for key in kv.list_keys(prefix).await? {
        if let Some(v) = kv.get(&key).await? {
            entries.push((key[prefix.len()..].to_owned(), v));
        }
    }
    Ok(JournalStore::from_entries(entries))
}

/// Writes the journal's unsaved changes under `prefix`. Returns the count.
pub async fn flush_journal<K: KvStore>(
    kv: &K,
    prefix: &str,
    journal: &JournalStore,
) -> Result<usize> {
    let dirty = journal.take_dirty();
    let total = dirty.len();
    let mut pending: Vec<(String, Option<Vec<u8>>)> = dirty.into_iter().collect();
    while let Some((k, v)) = pending.first().cloned() {
        let key = format!("{prefix}{k}");
        let r = match &v {
            Some(bytes) => kv.put(&key, bytes.clone()).await,
            None => kv.delete(&key).await,
        };
        if let Err(e) = r {
            journal.restore_dirty(pending.into_iter().collect());
            return Err(Error::storage(format!("liquid store flush: {e}")));
        }
        pending.remove(0);
    }
    Ok(total)
}

/// Deletes every key under `prefix`.
pub async fn wipe_prefix<K: KvStore>(kv: &K, prefix: &str) -> Result<usize> {
    let keys = kv.list_keys(prefix).await?;
    for k in &keys {
        kv.delete(k).await?;
    }
    Ok(keys.len())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};
    use lwk_common::Store;

    #[test]
    fn journal_roundtrip_through_kv() {
        let kv = MemoryKv::new();
        let j = JournalStore::new();
        j.put("a", b"1").unwrap();
        j.put("b", b"2").unwrap();
        j.remove("b").unwrap();
        assert_eq!(j.get("a").unwrap(), Some(b"1".to_vec()));
        assert_eq!(j.get("b").unwrap(), None);
        assert!(j.is_persisted());
        assert_eq!(block_on(flush_journal(&kv, STORE_PREFIX, &j)).unwrap(), 2);
        assert_eq!(block_on(flush_journal(&kv, STORE_PREFIX, &j)).unwrap(), 0);
        assert_eq!(
            block_on(kv.list_keys(STORE_PREFIX)).unwrap(),
            vec![format!("{STORE_PREFIX}a")]
        );

        let loaded = block_on(load_journal(&kv, STORE_PREFIX)).unwrap();
        assert_eq!(loaded.get("a").unwrap(), Some(b"1".to_vec()));
        assert_eq!(loaded.len(), 1);
        assert!(loaded.take_dirty().is_empty());

        assert_eq!(block_on(wipe_prefix(&kv, STORE_PREFIX)).unwrap(), 1);
        assert!(kv.is_empty());
    }

    #[test]
    fn restore_keeps_newer_writes() {
        let j = JournalStore::new();
        j.put("k", b"old").unwrap();
        let d = j.take_dirty();
        j.put("k", b"new").unwrap();
        j.restore_dirty(d);
        assert_eq!(
            j.take_dirty().get("k").cloned().flatten(),
            Some(b"new".to_vec())
        );
    }
}
