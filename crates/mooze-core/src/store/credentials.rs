//! Secrets in the [`SecureStore`]: wallet mnemonic and PIN hash.
//!
//! Values are raw UTF-8 strings, the same bytes `flutter_secure_storage` holds,
//! so an existing wallet reads back without migration.

use bdk_wallet::bitcoin::hashes::{sha256, Hash};

use crate::domain::{AppNetwork, WalletCredentials};
use crate::ports::SecureStore;
use crate::{Error, Result};

use super::json::{get_string, put_string};

/// Secure-store key of the wallet mnemonic. The name is part of the stored data format.
pub const MNEMONIC_KEY: &str = "mnemonic_mainWallet";
/// Secure-store key of the PIN salt.
pub const PIN_SALT_KEY: &str = "pinSalt";
/// Secure-store key of the salted PIN hash.
pub const HASHED_PIN_KEY: &str = "hashedPin";
/// Minimum PIN length.
pub const MIN_PIN_LENGTH: usize = 6;

/// Loads and saves [`WalletCredentials`].
#[derive(Debug, Clone)]
pub struct CredentialStore<S: SecureStore> {
    store: S,
    network: AppNetwork,
    mnemonic_key: String,
}

impl<S: SecureStore> CredentialStore<S> {
    /// Store for `network` under [`MNEMONIC_KEY`].
    pub fn new(store: S, network: AppNetwork) -> Self {
        Self::with_key(store, network, MNEMONIC_KEY)
    }

    /// Store with a custom mnemonic key (tests, multi-wallet).
    pub fn with_key(store: S, network: AppNetwork, mnemonic_key: impl Into<String>) -> Self {
        Self { store, network, mnemonic_key: mnemonic_key.into() }
    }

    /// Loads the credentials. A missing or empty mnemonic gives absent credentials.
    ///
    /// A store that reports its own state (`InvalidState`: not registered
    /// yet, locked) passes that error through. Every other failure is a
    /// credential failure.
    pub async fn load(&self) -> Result<WalletCredentials> {
        let v = get_string(&self.store, &self.mnemonic_key).await.map_err(|e| match e {
            Error::InvalidState(_) => e,
            other => Error::Credential(format!("load failed: {other}")),
        })?;
        Ok(match v {
            Some(m) if !m.is_empty() => WalletCredentials { mnemonic: m, network: self.network },
            _ => WalletCredentials::absent(self.network),
        })
    }

    /// Saves the mnemonic. Refuses absent credentials.
    pub async fn save(&self, credentials: &WalletCredentials) -> Result<()> {
        if credentials.is_absent() {
            return Err(Error::Credential("refusing to save absent mnemonic".into()));
        }
        put_string(&self.store, &self.mnemonic_key, &credentials.mnemonic)
            .await
            .map_err(|e| Error::Credential(format!("save failed: {e}")))
    }

    /// Deletes the mnemonic.
    pub async fn delete(&self) -> Result<()> {
        self.store.delete(&self.mnemonic_key).await.map_err(|e| Error::Credential(format!("delete failed: {e}")))
    }

    /// True if a non-empty mnemonic is stored.
    pub async fn exists(&self) -> Result<bool> {
        let v = get_string(&self.store, &self.mnemonic_key)
            .await
            .map_err(|e| Error::Credential(format!("exists failed: {e}")))?;
        Ok(v.is_some_and(|s| !s.is_empty()))
    }
}

/// Validates and normalizes a mnemonic.
///
/// Trims the phrase and requires 12 or 24 words split on single spaces.
pub fn normalize_mnemonic(mnemonic: &str) -> Result<String> {
    let trimmed = mnemonic.trim();
    if trimmed.is_empty() {
        return Err(Error::invalid("A frase de recuperação não pode ser vazia"));
    }
    // NOTE: The split is on a single ' ', so double spaces count as extra words.
    let words = trimmed.split(' ').count();
    if words != 12 && words != 24 {
        return Err(Error::invalid("A frase de recuperação deve ter 12 ou 24 palavras"));
    }
    Ok(trimmed.to_owned())
}

/// Builds an English BIP39 phrase from entropy (32 bytes = 24 words, 16 bytes = 12 words).
///
/// The platform supplies the random bytes.
pub fn generate_mnemonic(entropy: &[u8]) -> Result<String> {
    bdk_wallet::keys::bip39::Mnemonic::from_entropy(entropy)
        .map(|m| m.to_string())
        .map_err(|e| Error::invalid(format!("bad entropy: {e}")))
}

/// Saves the legacy mnemonic key after validation.
pub async fn save_mnemonic<S: SecureStore>(store: &S, mnemonic: &str) -> Result<()> {
    let m = normalize_mnemonic(mnemonic)?;
    put_string(store, MNEMONIC_KEY, &m).await
}

/// Reads the legacy mnemonic key.
pub async fn get_mnemonic<S: SecureStore>(store: &S) -> Result<Option<String>> {
    get_string(store, MNEMONIC_KEY).await
}

/// Salted SHA-256 PIN hash.
#[derive(Debug, Clone)]
pub struct PinStore<S: SecureStore> {
    store: S,
}

impl<S: SecureStore> PinStore<S> {
    /// PIN store over `store`.
    pub fn new(store: S) -> Self {
        Self { store }
    }

    /// Saves the PIN hash. `salt` must be 16 random bytes from the platform.
    pub async fn save(&self, pin: &str, salt: &[u8; 16]) -> Result<()> {
        // NOTE: The length counts UTF-16 units. For digits, this equals the char count.
        if pin.encode_utf16().count() < MIN_PIN_LENGTH {
            return Err(Error::invalid("PIN deve ter pelo menos 6 caracteres"));
        }
        let salt_b64 = base64_encode(salt);
        let digest = hash_pin(pin, &salt_b64);
        put_string(&self.store, PIN_SALT_KEY, &salt_b64).await?;
        put_string(&self.store, HASHED_PIN_KEY, &digest).await
    }

    /// Checks `pin` against the stored hash.
    pub async fn validate(&self, pin: &str) -> Result<bool> {
        let salt = get_string(&self.store, PIN_SALT_KEY)
            .await?
            .ok_or_else(|| Error::InvalidState("Salt não encontrado.".into()))?;
        let hashed = get_string(&self.store, HASHED_PIN_KEY)
            .await?
            .ok_or_else(|| Error::InvalidState("PIN não configurado.".into()))?;
        Ok(hash_pin(pin, &salt) == hashed)
    }

    /// True if a salt is stored. Read errors count as no PIN.
    pub async fn has_pin(&self) -> bool {
        matches!(get_string(&self.store, PIN_SALT_KEY).await, Ok(Some(_)))
    }

    /// Deletes salt and hash.
    pub async fn delete_pin(&self) -> Result<()> {
        self.store.delete(PIN_SALT_KEY).await?;
        self.store.delete(HASHED_PIN_KEY).await
    }
}

/// Lower-case hex SHA-256 of `pin + salt`, as `sha256.convert(utf8.encode("$pin$salt"))`.
pub fn hash_pin(pin: &str, salt: &str) -> String {
    let digest = sha256::Hash::hash(format!("{pin}{salt}").as_bytes());
    digest.to_byte_array().iter().map(|b| format!("{b:02x}")).collect()
}

/// Standard base64 with padding.
pub fn base64_encode(bytes: &[u8]) -> String {
    use bdk_wallet::bitcoin::base64::Engine;
    bdk_wallet::bitcoin::base64::engine::general_purpose::STANDARD.encode(bytes)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ports::KvStore;
    use crate::testing::{block_on, MemoryKv};

    const WORDS12: &str = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    /// Store whose every call fails with a fixed error.
    #[derive(Clone)]
    struct FailingStore(fn() -> Error);
    impl KvStore for FailingStore {
        fn get(&self, _k: &str) -> impl std::future::Future<Output = Result<Option<Vec<u8>>>> + crate::MaybeSend {
            std::future::ready(Err((self.0)()))
        }
        fn put(&self, _k: &str, _v: Vec<u8>) -> impl std::future::Future<Output = Result<()>> + crate::MaybeSend {
            std::future::ready(Err((self.0)()))
        }
        fn delete(&self, _k: &str) -> impl std::future::Future<Output = Result<()>> + crate::MaybeSend {
            std::future::ready(Err((self.0)()))
        }
        fn list_keys(&self, _p: &str) -> impl std::future::Future<Output = Result<Vec<String>>> + crate::MaybeSend {
            std::future::ready(Err((self.0)()))
        }
    }
    impl crate::ports::SecureStore for FailingStore {}

    #[test]
    fn load_passes_store_state_errors_through_and_wraps_the_rest() {
        block_on(async {
            let locked = CredentialStore::new(FailingStore(|| Error::InvalidState("not set".into())), AppNetwork::Mainnet);
            assert!(matches!(locked.load().await, Err(Error::InvalidState(m)) if m == "not set"));
            let broken = CredentialStore::new(FailingStore(|| Error::storage("disk")), AppNetwork::Mainnet);
            assert!(matches!(broken.load().await, Err(Error::Credential(m)) if m.contains("disk")));
        });
    }

    #[test]
    fn credentials_roundtrip_raw_string() {
        block_on(async {
            let kv = MemoryKv::new();
            let s = CredentialStore::new(kv.clone(), AppNetwork::Mainnet);
            assert!(s.load().await.unwrap().is_absent());
            assert!(!s.exists().await.unwrap());
            assert!(matches!(s.save(&WalletCredentials::absent(AppNetwork::Mainnet)).await, Err(Error::Credential(_))));
            let c = WalletCredentials { mnemonic: WORDS12.into(), network: AppNetwork::Mainnet };
            s.save(&c).await.unwrap();
            assert_eq!(kv.get(MNEMONIC_KEY).await.unwrap().unwrap(), WORDS12.as_bytes());
            assert_eq!(s.load().await.unwrap(), c);
            assert!(s.exists().await.unwrap());
            s.delete().await.unwrap();
            assert!(!s.exists().await.unwrap());
            kv.put(MNEMONIC_KEY, Vec::new()).await.unwrap();
            assert!(s.load().await.unwrap().is_absent());
        });
    }

    #[test]
    fn mnemonic_validation() {
        assert_eq!(normalize_mnemonic(&format!("  {WORDS12} ")).unwrap(), WORDS12);
        assert!(normalize_mnemonic("   ").is_err());
        assert!(normalize_mnemonic("one two three").is_err());
        assert_eq!(generate_mnemonic(&[0u8; 16]).unwrap(), WORDS12);
        assert_eq!(generate_mnemonic(&[0u8; 32]).unwrap().split(' ').count(), 24);
    }

    #[test]
    fn pin_save_validate_delete() {
        block_on(async {
            let p = PinStore::new(MemoryKv::new());
            assert!(!p.has_pin().await);
            assert!(matches!(p.validate("123456").await, Err(Error::InvalidState(_))));
            assert!(p.save("12345", &[1; 16]).await.is_err());
            p.save("123456", &[7; 16]).await.unwrap();
            assert!(p.has_pin().await);
            assert!(p.validate("123456").await.unwrap());
            assert!(!p.validate("654321").await.unwrap());
            p.delete_pin().await.unwrap();
            assert!(!p.has_pin().await);
        });
    }

    #[test]
    fn credential_helpers() {
        assert_eq!(base64_encode(b"foobar"), "Zm9vYmFy");
        assert_eq!(base64_encode(b"fo"), "Zm8=");
        assert_eq!(base64_encode(&[0u8; 16]), "AAAAAAAAAAAAAAAAAAAAAA==");
        // sha256("abc")
        assert_eq!(hash_pin("a", "bc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    }
}
