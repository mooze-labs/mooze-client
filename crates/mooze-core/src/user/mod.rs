//! User account: profile, spending levels, referral and phone verification.

mod entities;
mod levels;
mod phone;
mod receive;
mod service;

pub use entities::{LevelChange, LevelChangeType, User};
pub use levels::{
    calculate_progress, calculate_progress_legacy, compute_user_levels, default_level_by_amount, default_level_by_order,
    default_next_level, fetch_wallet_levels, DefaultUserLevel, UserLevelsData, WalletLevel, WalletLevelLimits,
    WalletLevelType, WalletLevelsResponse, DAILY_LIMIT_BRL, DEFAULT_USER_LEVELS, MAX_SPENDING_LEVEL, WALLET_LEVELS_URL,
};
pub use phone::{
    parse_status_event, sse_reconnect_delay_ms, status_subscribe_url, BeginVerificationRequest, PhoneDeviceInfo,
    PhoneVerificationClient, PhoneVerificationMethod, VerificationStatus, DEFAULT_PHONE_BASE_URL, IP_ADDRESS_URL,
    PHONE_TIMEOUT_MS, SSE_RECONNECT_INTERVAL_MS, SSE_RECONNECT_MAX_ATTEMPTS,
};
pub use receive::{asset_from_receive_id, total_value_to_receive, values_to_receive, AssetToReceive};
pub use service::{
    UserFetch, UserService, REFERRAL_CODE_ALREADY_USED, REFERRAL_CODE_INVALID, REFERRAL_ERROR_APPLY_FAILED,
    REFERRAL_ERROR_EMPTY_CODE, REFERRAL_ERROR_INVALID_CODE, STORED_LEVEL_KEY,
};
