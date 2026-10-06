//! Merchant mode flags.
//!
//! Port of `MerchantModeLocalDataSource` and its use cases, plus
//! `StoreModeHandler` (`lib/utils/store_mode.dart`). Dart keeps these in
//! SharedPreferences. Here they are JSON values in a [`KvStore`] under the same keys.

use crate::ports::KvStore;
use crate::store::json::{delete_key, get_json, put_json};
use crate::Result;

/// Key of the merchant-mode flag.
pub const MERCHANT_MODE_ACTIVE_KEY: &str = "merchant_mode_active";
/// Key of the route to return to on exit.
pub const MERCHANT_MODE_ORIGIN_KEY: &str = "merchant_mode_origin";
/// Key of the legacy store-mode flag.
pub const STORE_MODE_KEY: &str = "storeMode";
/// Default origin route.
pub const DEFAULT_ORIGIN: &str = "/home";

/// Merchant mode state.
#[derive(Debug, Clone)]
pub struct MerchantModeStore<K: KvStore> {
    kv: K,
}

impl<K: KvStore> MerchantModeStore<K> {
    /// Store over `kv`.
    pub fn new(kv: K) -> Self {
        Self { kv }
    }

    /// True if merchant mode is on. Absent means off.
    pub async fn is_active(&self) -> Result<bool> {
        Ok(get_json(&self.kv, MERCHANT_MODE_ACTIVE_KEY)
            .await?
            .unwrap_or(false))
    }

    /// Sets the flag. Saves `origin` only when activating.
    pub async fn set_active(&self, active: bool, origin: &str) -> Result<()> {
        put_json(&self.kv, MERCHANT_MODE_ACTIVE_KEY, &active).await?;
        if active {
            put_json(&self.kv, MERCHANT_MODE_ORIGIN_KEY, &origin).await?;
        }
        Ok(())
    }

    /// Activates with `origin`, default [`DEFAULT_ORIGIN`]. Port of `ActivateMerchantModeUseCase`.
    pub async fn activate(&self, origin: Option<&str>) -> Result<()> {
        self.set_active(true, origin.unwrap_or(DEFAULT_ORIGIN))
            .await
    }

    /// Saved origin, default [`DEFAULT_ORIGIN`].
    pub async fn origin(&self) -> Result<String> {
        Ok(get_json(&self.kv, MERCHANT_MODE_ORIGIN_KEY)
            .await?
            .unwrap_or_else(|| DEFAULT_ORIGIN.to_owned()))
    }

    /// Removes flag and origin. Port of `DeactivateMerchantModeUseCase`.
    pub async fn clear(&self) -> Result<()> {
        delete_key(&self.kv, MERCHANT_MODE_ACTIVE_KEY).await?;
        delete_key(&self.kv, MERCHANT_MODE_ORIGIN_KEY).await
    }

    /// Legacy store-mode flag. Absent means off.
    pub async fn is_store_mode(&self) -> Result<bool> {
        Ok(get_json(&self.kv, STORE_MODE_KEY).await?.unwrap_or(false))
    }

    /// Sets the legacy store-mode flag.
    pub async fn set_store_mode(&self, value: bool) -> Result<()> {
        put_json(&self.kv, STORE_MODE_KEY, &value).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn activate_origin_and_clear() {
        block_on(async {
            let m = MerchantModeStore::new(MemoryKv::new());
            assert!(!m.is_active().await.unwrap());
            assert_eq!(m.origin().await.unwrap(), "/home");
            m.activate(Some("/wallet")).await.unwrap();
            assert!(m.is_active().await.unwrap());
            assert_eq!(m.origin().await.unwrap(), "/wallet");
            // Deactivating through set_active keeps the old origin, as in Dart.
            m.set_active(false, "/ignored").await.unwrap();
            assert_eq!(m.origin().await.unwrap(), "/wallet");
            m.clear().await.unwrap();
            assert!(!m.is_active().await.unwrap());
            assert_eq!(m.origin().await.unwrap(), "/home");
            m.set_store_mode(true).await.unwrap();
            assert!(m.is_store_mode().await.unwrap());
        });
    }
}
