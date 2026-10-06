//! Backend authentication, device id, PIN and app lock logic.

mod b64;
mod device;
mod lock;
mod manager;
mod pin;
mod session;
mod signature;

pub use device::{
    clear_device_id, get_device_id, get_device_id_with_entropy, hardware_based_id, has_device_id, hash_device_id,
    metrics_json, random_uuid_v4, uuid_v4_from_bytes, DeviceInfo, DEVICE_ID_KEY,
};
pub use lock::{
    privacy_shield_on_leaving_foreground, resolve_lock_overlay, LockOverlay, PrivacyShieldState, SessionLockController,
    SessionLockState, SessionLockTimeout,
};
pub use manager::{
    challenge_request, refresh_request, sign_request, EnsureOutcome, SessionManager, AUTH_TIMEOUT_MS,
    JWT_KEY, JWT_NULL_IN_REFRESH_RESPONSE, REFRESH_TOKEN_KEY, REFRESH_TOKEN_NOT_FOUND, REFRESH_TOKEN_UNAUTHORIZED,
    REMOTE_AUTH_NOT_CONFIGURED, UNSAFE_DEVICE,
};
pub use pin::{
    hash_pin, PinService, HASHED_PIN_KEY, LAST_AUTH_TIME_KEY, MAX_PIN_ATTEMPTS, MIN_PIN_LENGTH, PIN_ATTEMPTS_KEY,
    PIN_SALT_KEY,
};
pub use session::{AuthChallenge, Session};
pub use signature::{
    verify_challenge_signature, AuthKeyPair, ChallengeSigner, KEY_DERIVATION_ITERATIONS, KEY_DERIVATION_SALT,
};
