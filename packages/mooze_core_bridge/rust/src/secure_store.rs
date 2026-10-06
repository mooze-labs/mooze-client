//! [`SecureStore`] backed by Dart callbacks, and the slot that holds it.
//!
//! The Dart app keeps its secrets in `flutter_secure_storage` (Keychain on
//! iOS, Keystore on Android). The core reads and writes them through four
//! callbacks that Dart registers with `MoozeCore.setSecureStorage`:
//!
//! - `read(key)` returns the value or `null`.
//! - `write(key, value)` stores a value.
//! - `delete(key)` removes a value. Absent keys are not an error.
//! - `listKeys(prefix)` returns the keys that start with `prefix`.
//!   `flutter_secure_storage` has no prefix query, so Dart filters the keys
//!   of `readAll()`.
//!
//! Values are UTF-8 strings, the same values `flutter_secure_storage` holds.
//! A non-UTF-8 value from the core is a storage error, never a lossy write.

use std::future::Future;
use std::sync::Arc;

use flutter_rust_bridge::DartFnFuture;
use mooze_core::ports::{KvStore, MaybeSend, SecureStore};
use mooze_core::{Error, Result};

use crate::ports::runtime;

type ReadFn = dyn Fn(String) -> DartFnFuture<Option<String>> + Send + Sync;
type WriteFn = dyn Fn(String, String) -> DartFnFuture<()> + Send + Sync;
type DeleteFn = dyn Fn(String) -> DartFnFuture<()> + Send + Sync;
type ListFn = dyn Fn(String) -> DartFnFuture<Vec<String>> + Send + Sync;

/// [`SecureStore`] that calls the Dart secure-storage callbacks.
#[derive(Clone)]
pub struct DartSecureStore {
    read: Arc<ReadFn>,
    write: Arc<WriteFn>,
    delete: Arc<DeleteFn>,
    list_keys: Arc<ListFn>,
}

impl std::fmt::Debug for DartSecureStore {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("DartSecureStore")
    }
}

impl DartSecureStore {
    /// Store over the four callbacks.
    pub fn new(
        read: impl Fn(String) -> DartFnFuture<Option<String>> + Send + Sync + 'static,
        write: impl Fn(String, String) -> DartFnFuture<()> + Send + Sync + 'static,
        delete: impl Fn(String) -> DartFnFuture<()> + Send + Sync + 'static,
        list_keys: impl Fn(String) -> DartFnFuture<Vec<String>> + Send + Sync + 'static,
    ) -> Self {
        Self { read: Arc::new(read), write: Arc::new(write), delete: Arc::new(delete), list_keys: Arc::new(list_keys) }
    }
}

/// Converts a value from the core to the string Dart stores.
pub(crate) fn value_to_string(key: &str, value: Vec<u8>) -> Result<String> {
    String::from_utf8(value).map_err(|_| Error::storage(format!("secure value for {key} is not UTF-8")))
}

/// Keeps the keys that start with `prefix`, sorted and without duplicates.
/// The [`KvStore`] contract requires it; the Dart side may not sort.
pub(crate) fn normalize_keys(mut keys: Vec<String>, prefix: &str) -> Vec<String> {
    keys.retain(|k| k.starts_with(prefix));
    keys.sort();
    keys.dedup();
    keys
}

/// Awaits one Dart callback.
///
/// flutter_rust_bridge panics on the Rust side when the Dart callback
/// throws. The call runs as its own task, so a throw becomes a storage
/// error instead of a crash of the caller.
async fn call<T: Send + 'static>(what: &str, key: &str, fut: DartFnFuture<T>) -> Result<T> {
    runtime().spawn(fut).await.map_err(|_| Error::storage(format!("secure storage {what} failed for {key}")))
}

impl KvStore for DartSecureStore {
    fn get(&self, key: &str) -> impl Future<Output = Result<Option<Vec<u8>>>> + MaybeSend {
        let key = key.to_owned();
        let fut = (self.read)(key.clone());
        async move { Ok(call("read", &key, fut).await?.map(String::into_bytes)) }
    }

    fn put(&self, key: &str, value: Vec<u8>) -> impl Future<Output = Result<()>> + MaybeSend {
        let key = key.to_owned();
        let write = self.write.clone();
        async move {
            let value = value_to_string(&key, value)?;
            call("write", &key, write(key.clone(), value)).await
        }
    }

    fn delete(&self, key: &str) -> impl Future<Output = Result<()>> + MaybeSend {
        let key = key.to_owned();
        let fut = (self.delete)(key.clone());
        async move { call("delete", &key, fut).await }
    }

    fn list_keys(&self, prefix: &str) -> impl Future<Output = Result<Vec<String>>> + MaybeSend {
        let prefix = prefix.to_owned();
        let fut = (self.list_keys)(prefix.clone());
        async move { Ok(normalize_keys(call("listKeys", &prefix, fut).await?, &prefix)) }
    }
}

impl SecureStore for DartSecureStore {}

/// Secure store slot that Dart fills after `open`.
///
/// Every call before `set` fails with `InvalidState`, the error the Dart
/// code expects from `secureGet` and the auth calls before registration.
#[derive(Clone, Default, Debug)]
pub struct LateSecureStore {
    inner: Arc<std::sync::RwLock<Option<DartSecureStore>>>,
}

impl LateSecureStore {
    /// Installs or replaces the Dart callbacks.
    pub fn set(&self, store: DartSecureStore) {
        *self.inner.write().unwrap_or_else(|e| e.into_inner()) = Some(store);
    }

    fn current(&self) -> Result<DartSecureStore> {
        self.inner
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .clone()
            .ok_or_else(|| Error::InvalidState("secure storage not set; call setSecureStorage first".into()))
    }
}

impl KvStore for LateSecureStore {
    fn get(&self, key: &str) -> impl Future<Output = Result<Option<Vec<u8>>>> + MaybeSend {
        let store = self.current();
        let key = key.to_owned();
        async move { store?.get(&key).await }
    }

    fn put(&self, key: &str, value: Vec<u8>) -> impl Future<Output = Result<()>> + MaybeSend {
        let store = self.current();
        let key = key.to_owned();
        async move { store?.put(&key, value).await }
    }

    fn delete(&self, key: &str) -> impl Future<Output = Result<()>> + MaybeSend {
        let store = self.current();
        let key = key.to_owned();
        async move { store?.delete(&key).await }
    }

    fn list_keys(&self, prefix: &str) -> impl Future<Output = Result<Vec<String>>> + MaybeSend {
        let store = self.current();
        let prefix = prefix.to_owned();
        async move { store?.list_keys(&prefix).await }
    }
}

impl SecureStore for LateSecureStore {}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use std::collections::BTreeMap;
    use std::sync::Mutex;

    /// Store over an in-memory map, with the callback shapes Dart uses.
    pub(crate) fn memory_store() -> (DartSecureStore, Arc<Mutex<BTreeMap<String, String>>>) {
        let map = Arc::new(Mutex::new(BTreeMap::<String, String>::new()));
        let (m1, m2, m3, m4) = (map.clone(), map.clone(), map.clone(), map.clone());
        let store = DartSecureStore::new(
            move |k| {
                let v = m1.lock().unwrap().get(&k).cloned();
                Box::pin(async move { v })
            },
            move |k, v| {
                m2.lock().unwrap().insert(k, v);
                Box::pin(async {})
            },
            move |k| {
                m3.lock().unwrap().remove(&k);
                Box::pin(async {})
            },
            // Unsorted and unfiltered on purpose: the adapter must fix both.
            move |_prefix| {
                let mut keys: Vec<String> = m4.lock().unwrap().keys().cloned().collect();
                keys.reverse();
                Box::pin(async move { keys })
            },
        );
        (store, map)
    }

    #[test]
    fn utf8_values_round_trip_and_others_fail() {
        assert_eq!(value_to_string("k", "çü ✓ words".as_bytes().to_vec()).unwrap(), "çü ✓ words");
        let err = value_to_string("k", vec![0xff, 0xfe]).unwrap_err();
        assert!(matches!(err, Error::Storage(ref m) if m.contains("not UTF-8")), "{err}");
    }

    #[test]
    fn keys_are_filtered_and_sorted() {
        let keys = vec!["b/2".into(), "a/1".into(), "b/1".into(), "b/1".into()];
        assert_eq!(normalize_keys(keys, "b/"), vec!["b/1", "b/2"]);
    }

    #[test]
    fn kv_contract_through_callbacks() {
        let (store, map) = memory_store();
        runtime().block_on(async {
            assert_eq!(store.get("jwt").await.unwrap(), None);
            store.put("jwt", b"token".to_vec()).await.unwrap();
            store.put("a/1", "ç".as_bytes().to_vec()).await.unwrap();
            store.put("a/2", b"x".to_vec()).await.unwrap();
            assert_eq!(store.get("jwt").await.unwrap(), Some(b"token".to_vec()));
            assert_eq!(store.get("a/1").await.unwrap(), Some("ç".as_bytes().to_vec()));
            assert_eq!(store.list_keys("a/").await.unwrap(), vec!["a/1", "a/2"]);
            assert!(store.put("bin", vec![0xc3]).await.is_err());
            store.delete("jwt").await.unwrap();
            store.delete("jwt").await.unwrap();
        });
        let keys: Vec<String> = map.lock().unwrap().keys().cloned().collect();
        assert_eq!(keys, vec!["a/1", "a/2"]);
    }

    #[test]
    fn late_secure_store_errors_until_set_then_works() {
        let late = LateSecureStore::default();
        let err = runtime().block_on(late.get("jwt")).unwrap_err();
        assert!(
            matches!(&err, Error::InvalidState(m) if m == "secure storage not set; call setSecureStorage first"),
            "{err}"
        );
        let (store, map) = memory_store();
        late.set(store);
        runtime().block_on(late.put("jwt", b"t".to_vec())).unwrap();
        assert_eq!(map.lock().unwrap().get("jwt").map(String::as_str), Some("t"));
    }

    #[test]
    fn throwing_callback_becomes_storage_error() {
        let store = DartSecureStore::new(
            |_| Box::pin(async { panic!("dart threw") }),
            |_, _| Box::pin(async {}),
            |_| Box::pin(async {}),
            |_| Box::pin(async { Vec::new() }),
        );
        let err = runtime().block_on(store.get("k")).unwrap_err();
        assert!(matches!(err, Error::Storage(_)), "{err}");
    }
}
