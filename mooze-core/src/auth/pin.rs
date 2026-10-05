//! PIN hash and local unlock session. Port of `lib/services/auth.dart`.
//!
//! Secrets (`hashedPin`, `pinSalt`) go to [`SecureStore`]. Counters
//! (`pinAttempts`, `lastAuthTime`, `sessionLockTimeout`) go to [`KvStore`],
//! where Dart used SharedPreferences. Integers are stored as decimal text.

use bdk_wallet::bitcoin::hashes::{sha256, Hash};
use bdk_wallet::bitcoin::hex::DisplayHex;

use super::b64;
use super::lock::SessionLockTimeout;
use crate::ports::{Clock, KvStore, SecureStore};
use crate::{Error, Result};

/// Secure-store key of the PIN hash.
pub const HASHED_PIN_KEY: &str = "hashedPin";
/// Secure-store key of the PIN salt.
pub const PIN_SALT_KEY: &str = "pinSalt";
/// Preferences key of the failed attempt counter.
pub const PIN_ATTEMPTS_KEY: &str = "pinAttempts";
/// Preferences key of the last successful authentication time (ms).
pub const LAST_AUTH_TIME_KEY: &str = "lastAuthTime";
/// Maximum PIN attempts (Dart `maxPinAttemps`).
pub const MAX_PIN_ATTEMPTS: u32 = 5;
/// Minimum PIN length.
pub const MIN_PIN_LENGTH: usize = 4;

/// Hex SHA-256 of `pin + salt`, as Dart stores it.
pub fn hash_pin(pin: &str, salt: &str) -> String {
    sha256::Hash::hash(format!("{pin}{salt}").as_bytes()).to_byte_array().to_lower_hex_string()
}

/// PIN creation and checks.
pub struct PinService<S: SecureStore, K: KvStore, C: Clock> {
    secure: S,
    prefs: K,
    clock: C,
}

impl<S: SecureStore, K: KvStore, C: Clock> PinService<S, K, C> {
    /// New service.
    pub fn new(secure: S, prefs: K, clock: C) -> Self {
        Self { secure, prefs, clock }
    }

    /// True if a PIN hash is stored.
    pub async fn is_pin_setup(&self) -> Result<bool> {
        Ok(self.secure.get(HASHED_PIN_KEY).await?.is_some())
    }

    /// Creates a PIN with a random 16-byte salt. Returns `false` if the PIN
    /// has fewer than 4 characters.
    pub async fn create_pin(&self, pin: &str) -> Result<bool> {
        let salt: [u8; 16] = bdk_wallet::bitcoin::secp256k1::rand::random();
        self.create_pin_with_salt(pin, &salt).await
    }

    /// [`Self::create_pin`] with a caller-supplied salt.
    pub async fn create_pin_with_salt(&self, pin: &str, salt: &[u8]) -> Result<bool> {
        // NOTE(port): Dart checks `String.length` (UTF-16 units); digits make it equal.
        if pin.chars().count() < MIN_PIN_LENGTH {
            return Ok(false);
        }
        let salt = b64::encode(salt);
        self.secure.put(PIN_SALT_KEY, salt.as_bytes().to_vec()).await?;
        self.secure.put(HASHED_PIN_KEY, hash_pin(pin, &salt).into_bytes()).await?;
        self.put_int(PIN_ATTEMPTS_KEY, 0).await?;
        self.update_last_auth_time().await?;
        Ok(true)
    }

    /// Checks `pin`. Updates the attempt counter and, on success, the last
    /// auth time. Errors if no PIN or salt is stored.
    pub async fn authenticate(&self, pin: &str) -> Result<bool> {
        let hashed = self.read_secret(HASHED_PIN_KEY).await?.ok_or_else(|| Error::Credential("No pin set".into()))?;
        let salt = self.read_secret(PIN_SALT_KEY).await?.ok_or_else(|| Error::Credential("No salt set".into()))?;
        let success = hash_pin(pin, &salt) == hashed;
        if success {
            self.update_last_auth_time().await?;
            self.put_int(PIN_ATTEMPTS_KEY, 0).await?;
        } else {
            let attempts = self.attempts().await?;
            self.put_int(PIN_ATTEMPTS_KEY, attempts + 1).await?;
        }
        Ok(success)
    }

    /// Clears the unlock session so the next open requires the PIN.
    pub async fn invalidate_session(&self) -> Result<()> {
        self.prefs.delete(LAST_AUTH_TIME_KEY).await
    }

    /// True if the last authentication is within the configured lock timeout.
    pub async fn has_valid_session(&self) -> Result<bool> {
        let Some(last) = self.get_int(LAST_AUTH_TIME_KEY).await? else {
            return Ok(false);
        };
        let timeout = SessionLockTimeout::from_storage(self.get_text(SessionLockTimeout::PREFS_KEY).await?.as_deref());
        let elapsed = self.clock.now_ms() as i64 - last;
        Ok(elapsed < timeout.duration_ms() as i64)
    }

    /// Failed attempts since the last success.
    pub async fn attempts(&self) -> Result<i64> {
        Ok(self.get_int(PIN_ATTEMPTS_KEY).await?.unwrap_or(0))
    }

    async fn update_last_auth_time(&self) -> Result<()> {
        self.put_int(LAST_AUTH_TIME_KEY, self.clock.now_ms() as i64).await
    }

    async fn read_secret(&self, key: &str) -> Result<Option<String>> {
        match self.secure.get(key).await? {
            None => Ok(None),
            Some(b) => String::from_utf8(b).map(Some).map_err(Error::storage),
        }
    }

    async fn get_text(&self, key: &str) -> Result<Option<String>> {
        match self.prefs.get(key).await? {
            None => Ok(None),
            Some(b) => String::from_utf8(b).map(Some).map_err(Error::storage),
        }
    }

    async fn get_int(&self, key: &str) -> Result<Option<i64>> {
        match self.get_text(key).await? {
            None => Ok(None),
            Some(t) => t.trim().parse().map(Some).map_err(Error::storage),
        }
    }

    async fn put_int(&self, key: &str, value: i64) -> Result<()> {
        self.prefs.put(key, value.to_string().into_bytes()).await
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::testing::{block_on, FixedClock, MemoryKv};
    use std::sync::Arc;

    fn service() -> (PinService<MemoryKv, MemoryKv, Arc<FixedClock>>, MemoryKv, Arc<FixedClock>) {
        let prefs = MemoryKv::new();
        let clock = Arc::new(FixedClock::new(1_000_000));
        (PinService::new(MemoryKv::new(), prefs.clone(), clock.clone()), prefs, clock)
    }

    #[test]
    fn hash_format() {
        // sha256("1234salt")
        assert_eq!(hash_pin("1234", "salt"), sha256::Hash::hash(b"1234salt").to_byte_array().to_lower_hex_string());
        assert_eq!(hash_pin("1234", "salt").len(), 64);
    }

    #[test]
    fn create_and_authenticate() {
        let (svc, _, _) = service();
        block_on(async {
            assert!(!svc.is_pin_setup().await.unwrap());
            assert!(matches!(svc.authenticate("1234").await, Err(Error::Credential(_))));
            assert!(!svc.create_pin_with_salt("123", &[1; 16]).await.unwrap());
            assert!(svc.create_pin_with_salt("1234", &[1; 16]).await.unwrap());
            assert!(svc.is_pin_setup().await.unwrap());
            assert!(!svc.authenticate("0000").await.unwrap());
            assert!(!svc.authenticate("0000").await.unwrap());
            assert_eq!(svc.attempts().await.unwrap(), 2);
            assert!(svc.authenticate("1234").await.unwrap());
            assert_eq!(svc.attempts().await.unwrap(), 0);
            assert!(svc.create_pin("5678").await.unwrap());
            assert!(svc.authenticate("5678").await.unwrap());
        });
    }

    #[test]
    fn unlock_session_window() {
        let (svc, prefs, clock) = service();
        block_on(async {
            assert!(!svc.has_valid_session().await.unwrap());
            svc.create_pin_with_salt("1234", &[0; 16]).await.unwrap();
            // Immediate timeout: never valid.
            assert!(!svc.has_valid_session().await.unwrap());
            prefs.put(SessionLockTimeout::PREFS_KEY, b"seconds30".to_vec()).await.unwrap();
            clock.advance(29_999);
            assert!(svc.has_valid_session().await.unwrap());
            clock.advance(1);
            assert!(!svc.has_valid_session().await.unwrap());
            svc.authenticate("1234").await.unwrap();
            svc.invalidate_session().await.unwrap();
            assert!(!svc.has_valid_session().await.unwrap());
        });
    }
}
