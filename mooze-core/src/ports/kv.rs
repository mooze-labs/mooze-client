use std::future::Future;

use super::{MaybeSend, MaybeSync};
use crate::Result;

/// Byte store addressed by string keys.
///
/// The browser maps it to IndexedDB. Mobile maps it to SQLite or files.
/// Keys use `/` as a namespace separator, for example `tx/liquid/<txid>`.
pub trait KvStore: MaybeSend + MaybeSync {
    /// Reads one value. `None` if the key is absent.
    fn get(&self, key: &str) -> impl Future<Output = Result<Option<Vec<u8>>>> + MaybeSend;

    /// Writes one value. Replaces an existing value.
    fn put(&self, key: &str, value: Vec<u8>) -> impl Future<Output = Result<()>> + MaybeSend;

    /// Deletes one value. Absent keys are not an error.
    fn delete(&self, key: &str) -> impl Future<Output = Result<()>> + MaybeSend;

    /// Lists all keys that start with `prefix`, in ascending order.
    fn list_keys(&self, prefix: &str) -> impl Future<Output = Result<Vec<String>>> + MaybeSend;
}

impl<T: KvStore + ?Sized> KvStore for std::sync::Arc<T> {
    fn get(&self, key: &str) -> impl Future<Output = Result<Option<Vec<u8>>>> + MaybeSend {
        (**self).get(key)
    }
    fn put(&self, key: &str, value: Vec<u8>) -> impl Future<Output = Result<()>> + MaybeSend {
        (**self).put(key, value)
    }
    fn delete(&self, key: &str) -> impl Future<Output = Result<()>> + MaybeSend {
        (**self).delete(key)
    }
    fn list_keys(&self, prefix: &str) -> impl Future<Output = Result<Vec<String>>> + MaybeSend {
        (**self).list_keys(prefix)
    }
}

/// Store for secrets: mnemonic, API tokens, PIN hash.
///
/// Same contract as [`KvStore`]. The platform must encrypt it at rest:
/// Keychain or Keystore on mobile, a password-derived key in the browser.
pub trait SecureStore: KvStore {}

impl<T: SecureStore + ?Sized> SecureStore for std::sync::Arc<T> {}
