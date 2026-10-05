//! Device id and request metrics.
//!
//! The platform reads the raw identifiers (unique serial, Android id,
//! iOS identifierForVendor) and the device info. The core derives and
//! persists the id.

use bdk_wallet::bitcoin::hashes::{sha256, Hash};
use bdk_wallet::bitcoin::hex::DisplayHex;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::ports::SecureStore;

/// Secure-store key of the device id.
pub const DEVICE_ID_KEY: &str = "device_id";

/// Hex SHA-256 of the raw id.
pub fn hash_device_id(raw: &str) -> String {
    sha256::Hash::hash(raw.as_bytes()).to_byte_array().to_lower_hex_string()
}

/// Hardware-based id.
///
/// `serial` is `UniqueIdentifier.serial`; it is skipped when empty or
/// `"unknown"`. `platform_id` is the Android id or the iOS
/// identifierForVendor; it is skipped when empty.
pub fn hardware_based_id(serial: Option<&str>, platform_id: Option<&str>) -> Option<String> {
    if let Some(s) = serial.filter(|s| !s.is_empty() && *s != "unknown") {
        return Some(hash_device_id(s));
    }
    platform_id.filter(|s| !s.is_empty()).map(hash_device_id)
}

/// Formats 16 random bytes as a UUID v4 string.
pub fn uuid_v4_from_bytes(mut bytes: [u8; 16]) -> String {
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    let h = bytes.to_lower_hex_string();
    format!("{}-{}-{}-{}-{}", &h[0..8], &h[8..12], &h[12..16], &h[16..20], &h[20..32])
}

/// Random UUID v4.
pub fn random_uuid_v4() -> String {
    uuid_v4_from_bytes(bdk_wallet::bitcoin::secp256k1::rand::random())
}

/// Returns the persisted device id, or derives and stores one.
///
/// Order: stored id, hardware-based id, random UUID.
/// Storage errors return a fresh UUID that is not persisted.
pub async fn get_device_id<S: SecureStore>(store: &S, serial: Option<&str>, platform_id: Option<&str>) -> String {
    get_device_id_with_entropy(store, serial, platform_id, bdk_wallet::bitcoin::secp256k1::rand::random()).await
}

/// [`get_device_id`] with caller-supplied randomness for the UUID fallback.
pub async fn get_device_id_with_entropy<S: SecureStore>(
    store: &S,
    serial: Option<&str>,
    platform_id: Option<&str>,
    entropy: [u8; 16],
) -> String {
    let fallback = uuid_v4_from_bytes(entropy);
    match store.get(DEVICE_ID_KEY).await {
        Ok(Some(bytes)) => match String::from_utf8(bytes) {
            Ok(saved) if !saved.is_empty() => return saved,
            Ok(_) => {}
            Err(_) => return fallback,
        },
        Ok(None) => {}
        Err(_) => return fallback,
    }
    let id = hardware_based_id(serial, platform_id).unwrap_or_else(|| fallback.clone());
    match store.put(DEVICE_ID_KEY, id.as_bytes().to_vec()).await {
        Ok(()) => id,
        Err(_) => fallback,
    }
}

/// Removes the stored device id. Errors are ignored by design.
pub async fn clear_device_id<S: SecureStore>(store: &S) {
    let _ = store.delete(DEVICE_ID_KEY).await;
}

/// True if a non-empty device id is stored. Errors give `false`.
pub async fn has_device_id<S: SecureStore>(store: &S) -> bool {
    matches!(store.get(DEVICE_ID_KEY).await, Ok(Some(b)) if !b.is_empty())
}

/// Device info the platform collects.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct DeviceInfo {
    /// Battery level, 0 to 100.
    pub battery_level: Option<i64>,
    /// Screen brightness, 0.0 to 1.0.
    pub screen_brightness: Option<f64>,
    /// Boot time as an ISO-8601 string.
    pub boot_time: Option<String>,
}

/// The `metrics` object the interceptor adds to request bodies.
pub fn metrics_json(device_id: &str, info: &DeviceInfo) -> Value {
    json!({
        "device_id": device_id,
        "battery_level": info.battery_level,
        "screen_brightness": info.screen_brightness,
        "boot_time": info.boot_time,
    })
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::ports::KvStore;
    use crate::testing::{block_on, MemoryKv};

    #[test]
    fn hash_matches_sha256_hex() {
        assert_eq!(hash_device_id("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    }

    #[test]
    fn hardware_id_rules() {
        assert_eq!(hardware_based_id(Some("abc"), Some("x")), Some(hash_device_id("abc")));
        assert_eq!(hardware_based_id(Some("unknown"), Some("x")), Some(hash_device_id("x")));
        assert_eq!(hardware_based_id(Some(""), None), None);
    }

    #[test]
    fn uuid_format() {
        let u = uuid_v4_from_bytes([0xff; 16]);
        assert_eq!(u, "ffffffff-ffff-4fff-bfff-ffffffffffff");
        assert_eq!(random_uuid_v4().len(), 36);
    }

    #[test]
    fn persists_first_id() {
        let kv = MemoryKv::new();
        block_on(async {
            assert!(!has_device_id(&kv).await);
            let id = get_device_id_with_entropy(&kv, None, None, [0; 16]).await;
            assert_eq!(id, "00000000-0000-4000-8000-000000000000");
            // Stored id wins over a new hardware id.
            assert_eq!(get_device_id(&kv, Some("serial"), None).await, id);
            clear_device_id(&kv).await;
            let hw = get_device_id(&kv, Some("serial"), None).await;
            assert_eq!(hw, hash_device_id("serial"));
            assert_eq!(kv.get(DEVICE_ID_KEY).await.unwrap().unwrap(), hw.as_bytes());
        });
    }

    #[test]
    fn metrics_shape() {
        let info = DeviceInfo { battery_level: Some(80), screen_brightness: Some(0.5), boot_time: None };
        assert_eq!(
            metrics_json("d", &info),
            json!({"device_id": "d", "battery_level": 80, "screen_brightness": 0.5, "boot_time": null})
        );
    }
}
