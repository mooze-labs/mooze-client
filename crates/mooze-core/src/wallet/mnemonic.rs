//! BIP39 mnemonic helpers.
//!
//! The app generates 12 words (128 bits of entropy) or 24 words
//! (256 bits) with the "extended phrase" option. Only English is supported.

use bdk_wallet::bitcoin::secp256k1::rand::{thread_rng, RngCore};
use bdk_wallet::keys::bip39::{Language, Mnemonic};

use crate::{Error, Result};

/// Entropy length in bytes for a 12-word phrase.
const ENTROPY_12_WORDS: usize = 16;
/// Entropy length in bytes for a 24-word phrase.
const ENTROPY_24_WORDS: usize = 32;

/// Generates a fresh English mnemonic. `extended` selects 24 words, else 12.
pub fn generate(extended: bool) -> String {
    let mut entropy = [0u8; ENTROPY_24_WORDS];
    let len = if extended { ENTROPY_24_WORDS } else { ENTROPY_12_WORDS };
    thread_rng().fill_bytes(&mut entropy[..len]);
    from_entropy(&entropy[..len]).expect("16 or 32 bytes is valid BIP39 entropy")
}

/// Builds the mnemonic for raw entropy (16 to 32 bytes, multiple of 4).
pub fn from_entropy(entropy: &[u8]) -> Result<String> {
    Mnemonic::from_entropy(entropy).map(|m| m.to_string()).map_err(|e| Error::invalid(format!("mnemonic: {e}")))
}

/// Trims the phrase and joins the words with single spaces.
pub fn normalize(phrase: &str) -> String {
    phrase.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Parses and checks a phrase (word list and checksum).
pub fn parse(phrase: &str) -> Result<Mnemonic> {
    Mnemonic::parse_normalized(&normalize(phrase)).map_err(|e| Error::invalid(format!("mnemonic: {e}")))
}

/// Standard English recovery words for local input assistance.
pub fn english_words() -> &'static [&'static str; 2048] {
    Language::English.word_list()
}

/// True if the phrase is a valid English BIP39 mnemonic.
pub fn is_valid(phrase: &str) -> bool {
    parse(phrase).is_ok()
}

/// BIP39 seed with an empty passphrase. The app never uses a passphrase.
pub fn to_seed(phrase: &str) -> Result<[u8; 64]> {
    Ok(parse(phrase)?.to_seed_normalized(""))
}

#[cfg(test)]
mod tests {
    use super::*;

    pub(crate) const ABANDON: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    #[test]
    fn generates_12_and_24_words() {
        let short = generate(false);
        let long = generate(true);
        assert_eq!(short.split(' ').count(), 12);
        assert_eq!(long.split(' ').count(), 24);
        assert!(is_valid(&short));
        assert!(is_valid(&long));
        assert_ne!(generate(false), short);
    }

    #[test]
    fn validates_checksum_and_whitespace() {
        assert!(is_valid(ABANDON));
        assert!(is_valid(&format!("  {}  ", ABANDON.replace(' ', "\n "))));
        let bad = ABANDON.replace("about", "abandon");
        assert!(!is_valid(&bad));
        assert!(!is_valid("abandon"));
        assert!(!is_valid(""));
    }

    #[test]
    fn zero_entropy_is_abandon_about() {
        assert_eq!(from_entropy(&[0u8; 16]).unwrap(), ABANDON);
        assert!(from_entropy(&[0u8; 15]).is_err());
    }
}
