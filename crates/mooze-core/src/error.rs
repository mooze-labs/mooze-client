//! Error type for the whole crate. Variants match the Dart `Failure` classes.

use crate::domain::ChainId;

/// Result alias for the crate.
pub type Result<T> = std::result::Result<T, Error>;

/// Every error the core returns.
#[derive(Debug, thiserror::Error, Clone, PartialEq, Eq)]
pub enum Error {
    /// The app could not finish a boot phase.
    #[error("boot failed in phase {phase}: {message}")]
    Boot { phase: String, message: String },

    /// A chain sync failed.
    #[error("sync failed on {chain:?}: {message}")]
    Sync { chain: ChainId, message: String },

    /// A wallet service operation failed.
    #[error("wallet service failed on {chain:?}: {message}")]
    Service { chain: ChainId, message: String },

    /// The key-value store failed or holds corrupt data.
    #[error("storage: {0}")]
    Storage(String),

    /// Credentials are missing, invalid or unreadable.
    #[error("credentials: {0}")]
    Credential(String),

    /// The API session is missing or expired.
    #[error("session: {0}")]
    Session(String),

    /// A transport (HTTP or WebSocket) failed before a response arrived.
    #[error("network: {0}")]
    Network(String),

    /// The server answered with a non-success status.
    #[error("http {status}: {body}")]
    Http { status: u16, body: String },

    /// A remote peer sent data the core cannot parse.
    #[error("protocol: {0}")]
    Protocol(String),

    /// The caller passed invalid input.
    #[error("invalid input: {0}")]
    InvalidInput(String),

    /// The operation is not allowed in the current state.
    #[error("invalid state: {0}")]
    InvalidState(String),

    /// The operation timed out.
    #[error("timeout: {0}")]
    Timeout(String),

    /// Anything else.
    #[error("unexpected: {0}")]
    Unexpected(String),
}

impl Error {
    /// Builds a [`Error::Service`] from any displayable cause.
    pub fn service(chain: ChainId, cause: impl std::fmt::Display) -> Self {
        Error::Service {
            chain,
            message: cause.to_string(),
        }
    }

    /// Builds a [`Error::Storage`] from any displayable cause.
    pub fn storage(cause: impl std::fmt::Display) -> Self {
        Error::Storage(cause.to_string())
    }

    /// Builds a [`Error::Protocol`] from any displayable cause.
    pub fn protocol(cause: impl std::fmt::Display) -> Self {
        Error::Protocol(cause.to_string())
    }

    /// Builds a [`Error::InvalidInput`] from any displayable cause.
    pub fn invalid(cause: impl std::fmt::Display) -> Self {
        Error::InvalidInput(cause.to_string())
    }

    /// True if a retry can succeed (transport errors, timeouts, 5xx, 429).
    pub fn is_transient(&self) -> bool {
        match self {
            Error::Network(_) | Error::Timeout(_) => true,
            Error::Http { status, .. } => *status == 429 || *status >= 500,
            _ => false,
        }
    }
}

impl From<serde_json::Error> for Error {
    fn from(e: serde_json::Error) -> Self {
        Error::Protocol(format!("json: {e}"))
    }
}
