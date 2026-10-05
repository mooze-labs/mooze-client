//! Challenge signing key. Port of `EcdsaSignatureClient`.
//!
//! Derivation (exactly as Dart):
//! 1. `k = PBKDF2-HMAC-SHA256(password = mnemonic UTF-8, salt = "mooze-ecdsa-salt",
//!    iterations = 10000, length = 32)`. The mnemonic string is used as is,
//!    no BIP39 seed, no BIP32 path.
//! 2. `d = (k mod (n - 1)) + 1`, with `n` the secp256k1 order.
//!
//! Signing (`signMessage`, the one the backend uses):
//! - input is base64 text; the decoded bytes are the ECDSA message itself,
//!   no hashing. Messages shorter than 32 bytes act as left zero-padded,
//!   longer messages keep their leftmost 32 bytes (pointycastle `_calculateE`).
//! - output: compact 64-byte `r || s`, low-S, not recoverable, standard base64.
//!
//! The public key is the 33-byte compressed point in standard base64.

use std::fmt;

use bdk_wallet::bitcoin::hashes::hmac::{Hmac, HmacEngine};
use bdk_wallet::bitcoin::hashes::{sha256, Hash, HashEngine};
use bdk_wallet::bitcoin::secp256k1::{constants::CURVE_ORDER, ecdsa::Signature, All, Message, PublicKey, Secp256k1, SecretKey};

use super::b64;
use crate::{Error, Result};

/// PBKDF2 salt used by the Dart client.
pub const KEY_DERIVATION_SALT: &[u8] = b"mooze-ecdsa-salt";

/// PBKDF2 iteration count used by the Dart client.
pub const KEY_DERIVATION_ITERATIONS: u32 = 10_000;

/// Signs login challenges. Dart `SignatureClient`.
pub trait ChallengeSigner: crate::MaybeSend + crate::MaybeSync {
    /// Signs a base64 challenge message. Returns base64.
    fn sign_message(&self, message_b64: &str) -> Result<String>;
    /// Compressed public key in base64.
    fn public_key_base64(&self) -> String;
}

/// secp256k1 key pair derived from the mnemonic. `Debug` hides the secret.
#[derive(Clone)]
pub struct AuthKeyPair {
    secp: Secp256k1<All>,
    secret: SecretKey,
    public: PublicKey,
}

impl fmt::Debug for AuthKeyPair {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("AuthKeyPair").field("public", &self.public).field("secret", &"<redacted>").finish()
    }
}

impl AuthKeyPair {
    /// Derives the key pair from the user seed string (the mnemonic).
    pub fn from_seed(seed: &str) -> Result<Self> {
        let k = pbkdf2_sha256_32(seed.as_bytes(), KEY_DERIVATION_SALT, KEY_DERIVATION_ITERATIONS);
        let d = reduce_private_key(k);
        let secret = SecretKey::from_slice(&d).map_err(|e| Error::Credential(format!("auth key: {e}")))?;
        let secp = Secp256k1::new();
        let public = PublicKey::from_secret_key(&secp, &secret);
        Ok(Self { secp, secret, public })
    }

    /// The public key.
    pub fn public_key(&self) -> PublicKey {
        self.public
    }

    /// Compressed public key in base64 (Dart `getPublicKey`).
    pub fn public_key_base64(&self) -> String {
        b64::encode(&self.public.serialize())
    }

    /// Signs a base64 message (Dart `signMessage`). Returns compact base64.
    ///
    /// NOTE(port): Dart picks a random nonce (Fortuna). libsecp256k1 uses
    /// RFC 6979, so the core signature is deterministic. Both verify the same.
    pub fn sign_message(&self, message_b64: &str) -> Result<String> {
        let bytes = b64::decode(message_b64)?;
        Ok(b64::encode(&self.sign_digest(message_to_digest(&bytes)).serialize_compact()))
    }

    /// Signs `sha256(decoded message)` (Dart `signMessageHash`). Returns compact base64.
    pub fn sign_message_hash(&self, message_b64: &str) -> Result<String> {
        let bytes = b64::decode(message_b64)?;
        let hash = sha256::Hash::hash(&bytes).to_byte_array();
        Ok(b64::encode(&self.sign_digest(hash).serialize_compact()))
    }

    fn sign_digest(&self, digest: [u8; 32]) -> Signature {
        let mut sig = self.secp.sign_ecdsa(&Message::from_digest(digest), &self.secret);
        sig.normalize_s();
        sig
    }
}

impl ChallengeSigner for AuthKeyPair {
    fn sign_message(&self, message_b64: &str) -> Result<String> {
        AuthKeyPair::sign_message(self, message_b64)
    }
    fn public_key_base64(&self) -> String {
        AuthKeyPair::public_key_base64(self)
    }
}

/// Verifies a compact base64 signature over a base64 message, with the same
/// message-to-digest rule as [`AuthKeyPair::sign_message`].
pub fn verify_challenge_signature(public_key_b64: &str, message_b64: &str, signature_b64: &str) -> Result<bool> {
    let pk = PublicKey::from_slice(&b64::decode(public_key_b64)?).map_err(Error::invalid)?;
    let sig = Signature::from_compact(&b64::decode(signature_b64)?).map_err(Error::invalid)?;
    let msg = Message::from_digest(message_to_digest(&b64::decode(message_b64)?));
    Ok(Secp256k1::verification_only().verify_ecdsa(&msg, &sig, &pk).is_ok())
}

/// Maps message bytes to the 32-byte ECDSA input, as pointycastle does
/// with a null digest: big-endian integer, truncated to the leftmost 256 bits.
fn message_to_digest(bytes: &[u8]) -> [u8; 32] {
    let mut out = [0u8; 32];
    if bytes.len() >= 32 {
        out.copy_from_slice(&bytes[..32]);
    } else {
        out[32 - bytes.len()..].copy_from_slice(bytes);
    }
    out
}

/// PBKDF2-HMAC-SHA256 with a 32-byte output (one block).
fn pbkdf2_sha256_32(password: &[u8], salt: &[u8], iterations: u32) -> [u8; 32] {
    let keyed = HmacEngine::<sha256::Hash>::new(password);
    let mut engine = keyed.clone();
    engine.input(salt);
    engine.input(&1u32.to_be_bytes());
    let mut u = Hmac::<sha256::Hash>::from_engine(engine).to_byte_array();
    let mut out = u;
    for _ in 1..iterations {
        let mut engine = keyed.clone();
        engine.input(&u);
        u = Hmac::<sha256::Hash>::from_engine(engine).to_byte_array();
        for (o, b) in out.iter_mut().zip(u.iter()) {
            *o ^= b;
        }
    }
    out
}

/// Computes `(k mod (n - 1)) + 1` on 256-bit big-endian numbers.
fn reduce_private_key(k: [u8; 32]) -> [u8; 32] {
    let mut n_minus_1 = CURVE_ORDER;
    n_minus_1[31] -= 1; // order ends in 0x41, no borrow.
    // k < 2^256 < 2 (n - 1), so one subtraction is enough.
    let mut d = if k >= n_minus_1 { sub_be(k, n_minus_1) } else { k };
    // d < n - 1, so d + 1 < n and cannot overflow.
    for byte in d.iter_mut().rev() {
        let (v, carry) = byte.overflowing_add(1);
        *byte = v;
        if !carry {
            break;
        }
    }
    d
}

fn sub_be(a: [u8; 32], b: [u8; 32]) -> [u8; 32] {
    let mut out = [0u8; 32];
    let mut borrow = 0i16;
    for i in (0..32).rev() {
        let mut v = a[i] as i16 - b[i] as i16 - borrow;
        borrow = if v < 0 {
            v += 256;
            1
        } else {
            0
        };
        out[i] = v as u8;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use bdk_wallet::bitcoin::hex::DisplayHex;

    const MNEMONIC: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    #[test]
    fn pbkdf2_rfc7914_vector() {
        // RFC 7914 section 11: PBKDF2-HMAC-SHA256("passwd", "salt", 1, 64), first 32 bytes.
        let out = pbkdf2_sha256_32(b"passwd", b"salt", 1);
        assert_eq!(out.to_lower_hex_string(), "55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc");
        // RFC 7914: ("Password", "NaCl", 80000, 64), first 32 bytes.
        let out = pbkdf2_sha256_32(b"Password", b"NaCl", 80000);
        assert_eq!(out.to_lower_hex_string(), "4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56");
    }

    #[test]
    fn reduction_edges() {
        let mut n_minus_1 = CURVE_ORDER;
        n_minus_1[31] -= 1;
        // k = n - 1 maps to 1.
        let mut one = [0u8; 32];
        one[31] = 1;
        assert_eq!(reduce_private_key(n_minus_1), one);
        // k = 0 maps to 1, k = 0xff..ff maps to 2^256 - 1 - (n - 1) + 1.
        assert_eq!(reduce_private_key([0u8; 32]), one);
        let max = reduce_private_key([0xff; 32]);
        assert!(SecretKey::from_slice(&max).is_ok());
        let mut k = [0u8; 32];
        k[31] = 0xfe;
        let mut expected = [0u8; 32];
        expected[31] = 0xff;
        assert_eq!(reduce_private_key(k), expected);
    }

    #[test]
    fn derivation_is_fixed() {
        let key = AuthKeyPair::from_seed(MNEMONIC).unwrap();
        // Same PBKDF2 output as Python hashlib.pbkdf2_hmac('sha256', m, b'mooze-ecdsa-salt', 10000, 32).
        let k = pbkdf2_sha256_32(MNEMONIC.as_bytes(), KEY_DERIVATION_SALT, KEY_DERIVATION_ITERATIONS);
        assert_eq!(k.to_lower_hex_string(), PBKDF2_HEX);
        assert_eq!(key.secret.secret_bytes().to_lower_hex_string(), SECRET_HEX);
        assert_eq!(key.public_key_base64(), PUBKEY_B64);
        assert_eq!(b64::decode(&key.public_key_base64()).unwrap().len(), 33);
    }

    #[test]
    fn signing_is_deterministic_and_verifies() {
        let key = AuthKeyPair::from_seed(MNEMONIC).unwrap();
        let challenge = "SGVsbG8gV29ybGQ="; // "Hello World"
        let sig1 = key.sign_message(challenge).unwrap();
        let sig2 = AuthKeyPair::from_seed(MNEMONIC).unwrap().sign_message(challenge).unwrap();
        assert_eq!(sig1, sig2);
        assert_eq!(sig1, SIGNATURE_B64);
        assert_eq!(b64::decode(&sig1).unwrap().len(), 64);
        assert!(verify_challenge_signature(&key.public_key_base64(), challenge, &sig1).unwrap());
        // Independent check with the raw secp256k1 API.
        let secp = Secp256k1::verification_only();
        let sig = Signature::from_compact(&b64::decode(&sig1).unwrap()).unwrap();
        let mut digest = [0u8; 32];
        digest[32 - 11..].copy_from_slice(b"Hello World");
        assert!(secp.verify_ecdsa(&Message::from_digest(digest), &sig, &key.public_key()).is_ok());
        // Low-S.
        let mut normalized = sig;
        normalized.normalize_s();
        assert_eq!(normalized, sig);
        // Another message gives another signature that fails for this message.
        let other = key.sign_message("R29vZGJ5ZSBXb3JsZA==").unwrap();
        assert_ne!(other, sig1);
        assert!(!verify_challenge_signature(&key.public_key_base64(), challenge, &other).unwrap());
    }

    #[test]
    fn long_and_empty_messages() {
        let key = AuthKeyPair::from_seed(MNEMONIC).unwrap();
        let long = b64::encode(&[b'a'; 10_000]);
        let sig = key.sign_message(&long).unwrap();
        assert!(verify_challenge_signature(&key.public_key_base64(), &long, &sig).unwrap());
        // Only the leftmost 32 bytes count.
        let prefix = b64::encode(&[b'a'; 32]);
        assert!(verify_challenge_signature(&key.public_key_base64(), &prefix, &sig).unwrap());
        assert!(key.sign_message("").is_ok());
        assert!(key.sign_message("this is not base64!").is_err());
        let hashed = key.sign_message_hash("SGVsbG8gV29ybGQ=").unwrap();
        assert_ne!(hashed, key.sign_message("SGVsbG8gV29ybGQ=").unwrap());
    }

    #[test]
    fn odd_seeds_work() {
        assert!(AuthKeyPair::from_seed("").is_ok());
        assert!(AuthKeyPair::from_seed("test-🔐-unicode-seed-🚀").is_ok());
        assert!(!format!("{:?}", AuthKeyPair::from_seed("x").unwrap()).contains("SecretKey"));
    }

    const PBKDF2_HEX: &str = "e95eb9da1804a85757fcd16cd4f299a748fb16e213bdc947e663809be9067532";
    const SECRET_HEX: &str = "e95eb9da1804a85757fcd16cd4f299a748fb16e213bdc947e663809be9067533";
    const PUBKEY_B64: &str = "AlKvZeLLxAQvD5HOYyAdRbB11P6DURoGkAjFtS/1v7P1";
    const SIGNATURE_B64: &str =
        "Q+QfQonV5RuM2RnLbWkO+CrDtXsxb7Sl1hqiMZ4xY0USGindbJyIRxscl08hndEe+Sj/GVb7vTsTBRv6tnrbGA==";
}
