//! Typed JSON helpers over [`KvStore`].
//!
//! Every store in the crate serializes its records as JSON under a key prefix.
//! Corrupt values surface as [`Error::Storage`].

use serde::de::DeserializeOwned;
use serde::Serialize;

use crate::ports::KvStore;
use crate::{Error, Result};

/// Reads and decodes one JSON value. `None` if the key is absent.
pub async fn get_json<K: KvStore, T: DeserializeOwned>(kv: &K, key: &str) -> Result<Option<T>> {
    match kv.get(key).await? {
        None => Ok(None),
        Some(bytes) => serde_json::from_slice(&bytes)
            .map(Some)
            .map_err(|e| Error::storage(format!("corrupt value at {key}: {e}"))),
    }
}

/// Encodes and writes one JSON value. Replaces an existing value.
pub async fn put_json<K: KvStore, T: Serialize>(kv: &K, key: &str, value: &T) -> Result<()> {
    let bytes = serde_json::to_vec(value).map_err(Error::storage)?;
    kv.put(key, bytes).await
}

/// Deletes one key. Absent keys are not an error.
pub async fn delete_key<K: KvStore>(kv: &K, key: &str) -> Result<()> {
    kv.delete(key).await
}

/// Reads every value under `prefix`, in ascending key order.
pub async fn list_json<K: KvStore, T: DeserializeOwned>(kv: &K, prefix: &str) -> Result<Vec<(String, T)>> {
    let keys = kv.list_keys(prefix).await?;
    let mut out = Vec::with_capacity(keys.len());
    for key in keys {
        // A key can disappear between list and get. Skip it.
        if let Some(v) = get_json(kv, &key).await? {
            out.push((key, v));
        }
    }
    Ok(out)
}

/// Deletes every key under `prefix`. Returns the number of deleted keys.
pub async fn delete_prefix<K: KvStore>(kv: &K, prefix: &str) -> Result<usize> {
    let keys = kv.list_keys(prefix).await?;
    for key in &keys {
        kv.delete(key).await?;
    }
    Ok(keys.len())
}

/// Reads a raw UTF-8 string value.
pub async fn get_string<K: KvStore>(kv: &K, key: &str) -> Result<Option<String>> {
    match kv.get(key).await? {
        None => Ok(None),
        Some(bytes) => String::from_utf8(bytes)
            .map(Some)
            .map_err(|e| Error::storage(format!("non utf-8 value at {key}: {e}"))),
    }
}

/// Writes a raw UTF-8 string value.
pub async fn put_string<K: KvStore>(kv: &K, key: &str, value: &str) -> Result<()> {
    kv.put(key, value.as_bytes().to_vec()).await
}

/// Allocates the next id of an auto-increment sequence stored at `seq_key`.
///
/// Ids start at 1 and never repeat, like SQLite `AUTOINCREMENT`.
pub async fn next_id<K: KvStore>(kv: &K, seq_key: &str) -> Result<i64> {
    let current: i64 = get_json(kv, seq_key).await?.unwrap_or(0);
    let next = current + 1;
    put_json(kv, seq_key, &next).await?;
    Ok(next)
}

/// Key for a row id. Zero padding keeps ascending key order equal to id order.
pub fn id_key(prefix: &str, id: i64) -> String {
    format!("{prefix}{id:020}")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn roundtrip_list_and_delete_prefix() {
        block_on(async {
            let kv = MemoryKv::new();
            put_json(&kv, "a/2", &2u32).await.unwrap();
            put_json(&kv, "a/1", &1u32).await.unwrap();
            put_json(&kv, "b/1", &9u32).await.unwrap();
            let all: Vec<(String, u32)> = list_json(&kv, "a/").await.unwrap();
            assert_eq!(all, vec![("a/1".into(), 1), ("a/2".into(), 2)]);
            assert_eq!(delete_prefix(&kv, "a/").await.unwrap(), 2);
            assert_eq!(kv.len(), 1);
        });
    }

    #[test]
    fn corrupt_value_is_storage_error() {
        block_on(async {
            let kv = MemoryKv::new();
            kv.put("x", b"{not json".to_vec()).await.unwrap();
            let r: Result<Option<u32>> = get_json(&kv, "x").await;
            assert!(matches!(r, Err(Error::Storage(_))));
        });
    }

    #[test]
    fn sequence_is_monotonic() {
        block_on(async {
            let kv = MemoryKv::new();
            assert_eq!(next_id(&kv, "seq").await.unwrap(), 1);
            assert_eq!(next_id(&kv, "seq").await.unwrap(), 2);
            assert!(id_key("p/", 2) < id_key("p/", 10));
        });
    }
}
