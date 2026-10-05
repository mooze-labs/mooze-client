//! Mooze backend HTTP client.
//!
//! The authenticated client and the error-family mapping (codes only, no copy).

mod client;
mod errors;
mod url;

pub use client::{
    should_skip_auth, ApiConfig, MoozeApi, SessionProvider, AUTHORIZATION_HEADER, DEFAULT_BASE_URL,
    UNAUTHENTICATED_PATHS,
};
pub use errors::{classify_error, detect_server_error, ErrorKind, ServerErrorInfo};
pub use url::{data_object_or_self, data_or_self, encode_path_segment, join_url};
