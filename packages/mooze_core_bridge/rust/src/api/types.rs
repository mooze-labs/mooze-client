//! Plain data types that cross the bridge. The DTOs live in `mooze_app::dto`
//! and are re-exported here so the Dart class names stay unchanged.

pub use mooze_app::dto::*;

/// Settings for [`super::core::MoozeCore::open`].
#[derive(Debug, Clone)]
pub struct CoreConfig {
    /// Directory the core may own. The app support directory is a good choice.
    pub data_dir: String,
    pub network: NetworkDto,
    pub backend: BackendDto,
    /// Custom Bitcoin node. Empty uses the default servers.
    pub bitcoin_node_url: String,
    /// Custom Liquid node. Empty uses the default servers.
    pub liquid_node_url: String,
}

/// Category of a bridge error. Dart maps it to its failure classes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CoreErrorKind {
    Service,
    Storage,
    Credential,
    Network,
    InvalidInput,
    InvalidState,
    Timeout,
    Other,
    /// The API session is missing or could not be refreshed.
    Session,
}

/// Error thrown on the Dart side by every failing bridge call.
#[derive(Debug, Clone)]
pub struct CoreError {
    pub kind: CoreErrorKind,
    pub message: String,
}

impl std::fmt::Display for CoreError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}: {}", self.kind, self.message)
    }
}

impl std::error::Error for CoreError {}

impl From<mooze_core::Error> for CoreError {
    fn from(e: mooze_core::Error) -> Self {
        mooze_app::AppError::from(e).into()
    }
}

impl From<mooze_app::AppError> for CoreError {
    fn from(e: mooze_app::AppError) -> Self {
        use mooze_app::ErrorCode as C;
        let kind = match e.code {
            C::Service => CoreErrorKind::Service,
            C::Storage => CoreErrorKind::Storage,
            C::Credential => CoreErrorKind::Credential,
            C::Network => CoreErrorKind::Network,
            C::InvalidInput => CoreErrorKind::InvalidInput,
            C::InvalidState | C::Locked => CoreErrorKind::InvalidState,
            C::Timeout => CoreErrorKind::Timeout,
            C::Session => CoreErrorKind::Session,
            C::Transport | C::Other => CoreErrorKind::Other,
        };
        Self { kind, message: e.message }
    }
}
