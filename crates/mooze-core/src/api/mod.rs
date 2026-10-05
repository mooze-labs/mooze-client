//! Mooze backend HTTP client.
//!
//! Port of `lib/shared/network/**` (the authenticated Dio client and its
//! `AuthInterceptor`) and of the error-family mapping in
//! `lib/shared/utils/error_message.dart` and
//! `lib/shared/exceptions/user_friendly_exception.dart` (codes only, no copy).

mod client;
mod errors;
mod url;

pub use client::{
    should_skip_auth, ApiConfig, MoozeApi, SessionProvider, AUTHORIZATION_HEADER, DEFAULT_BASE_URL,
    UNAUTHENTICATED_PATHS,
};
pub use errors::{classify_error, detect_server_error, ErrorKind, ServerErrorInfo};
pub use url::{data_object_or_self, data_or_self, encode_path_segment, join_url};
