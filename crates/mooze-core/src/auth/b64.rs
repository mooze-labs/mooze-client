//! Base64 helpers.

use bdk_wallet::bitcoin::base64::alphabet;
use bdk_wallet::bitcoin::base64::engine::general_purpose::{GeneralPurpose, GeneralPurposeConfig, STANDARD};
use bdk_wallet::bitcoin::base64::engine::DecodePaddingMode;
use bdk_wallet::bitcoin::base64::Engine;

use crate::{Error, Result};

const LENIENT: GeneralPurposeConfig =
    GeneralPurposeConfig::new().with_decode_padding_mode(DecodePaddingMode::Indifferent);
const LENIENT_STANDARD: GeneralPurpose = GeneralPurpose::new(&alphabet::STANDARD, LENIENT);
const LENIENT_URL_SAFE: GeneralPurpose = GeneralPurpose::new(&alphabet::URL_SAFE, LENIENT);

/// Standard padded base64.
pub fn encode(bytes: &[u8]) -> String {
    STANDARD.encode(bytes)
}

/// Decodes standard or URL-safe base64. Padding is optional.
pub fn decode(text: &str) -> Result<Vec<u8>> {
    LENIENT_STANDARD
        .decode(text)
        .or_else(|_| LENIENT_URL_SAFE.decode(text))
        .map_err(|e| Error::invalid(format!("base64: {e}")))
}

/// Decodes a base64url JWT segment.
pub fn decode_jwt_segment(segment: &str) -> Result<Vec<u8>> {
    let mut text = segment.replace('-', "+").replace('_', "/");
    match text.len() % 4 {
        0 => {}
        2 => text.push_str("=="),
        3 => text.push('='),
        _ => return Err(Error::Session("Illegal base64url string!".into())),
    }
    STANDARD.decode(text).map_err(|e| Error::Session(format!("jwt base64: {e}")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_and_leniency() {
        assert_eq!(encode(b"Hello World"), "SGVsbG8gV29ybGQ=");
        assert_eq!(decode("SGVsbG8gV29ybGQ=").unwrap(), b"Hello World");
        assert_eq!(decode("SGVsbG8gV29ybGQ").unwrap(), b"Hello World");
        assert_eq!(decode("-_8").unwrap(), vec![0xfb, 0xff]);
        assert!(decode("invalid-base64!@#").is_err());
    }

    #[test]
    fn jwt_segment() {
        assert_eq!(decode_jwt_segment("eyJhIjoxfQ").unwrap(), br#"{"a":1}"#);
        assert!(decode_jwt_segment("abcde").is_err());
    }
}
