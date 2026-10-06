//! One flat error for every facade method.

use serde::{Deserialize, Serialize};

/// Stable error category. Serialized as `snake_case` text.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    Service,
    Storage,
    Credential,
    Network,
    InvalidInput,
    InvalidState,
    Timeout,
    Session,
    /// The secure store is locked. Web hosts set it; see the spec.
    Locked,
    /// The host transport failed. Hosts set it; the facade never does.
    Transport,
    Other,
}

/// Error every facade method returns.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, thiserror::Error)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
#[error("{code:?}: {message}")]
pub struct AppError {
    pub code: ErrorCode,
    pub message: String,
    /// Extra text for logs and support, never shown as the main message.
    pub details: Option<String>,
}

pub type Result<T> = std::result::Result<T, AppError>;

impl AppError {
    pub fn new(code: ErrorCode, message: impl Into<String>) -> Self {
        Self { code, message: message.into(), details: None }
    }

    pub fn invalid_input(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::InvalidInput, message)
    }

    pub fn invalid_state(message: impl Into<String>) -> Self {
        Self::new(ErrorCode::InvalidState, message)
    }
}

impl From<mooze_core::Error> for AppError {
    fn from(e: mooze_core::Error) -> Self {
        use mooze_core::Error as E;
        let code = match &e {
            E::Service { .. } | E::Sync { .. } => ErrorCode::Service,
            E::Storage(_) => ErrorCode::Storage,
            E::Credential(_) => ErrorCode::Credential,
            E::Network(_) | E::Http { .. } => ErrorCode::Network,
            E::InvalidInput(_) => ErrorCode::InvalidInput,
            E::InvalidState(_) => ErrorCode::InvalidState,
            E::Timeout(_) => ErrorCode::Timeout,
            E::Session(_) => ErrorCode::Session,
            _ => ErrorCode::Other,
        };
        let details = match &e {
            E::InsufficientFeeAsset { .. } => Some("insufficient_fee_asset".into()),
            E::FeeLimitExceeded { .. } => Some("fee_changed".into()),
            E::AmountChanged { .. } => Some("amount_changed".into()),
            E::SubmissionUnknown { .. } => Some("submission_unknown".into()),
            _ => None,
        };
        Self { code, message: e.to_string(), details }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use mooze_core::domain::ChainId;
    use mooze_core::Error as E;

    #[test]
    fn bounded_send_errors_preserve_stable_detail_tags() {
        let fee = AppError::from(mooze_core::Error::FeeLimitExceeded { actual_sat: 101, max_sat: 100 });
        assert_eq!(fee.details.as_deref(), Some("fee_changed"));
        let uncertain =
            AppError::from(mooze_core::Error::SubmissionUnknown { chain: ChainId::Liquid, message: "timeout".into() });
        assert_eq!(uncertain.details.as_deref(), Some("submission_unknown"));
        assert_ne!(AppError::from(mooze_core::Error::Network("timeout".into())).details, uncertain.details);
    }

    #[test]
    fn core_errors_map_to_stable_codes() {
        let cases: Vec<(E, ErrorCode)> = vec![
            (E::service(ChainId::Liquid, "x"), ErrorCode::Service),
            (E::storage("x"), ErrorCode::Storage),
            (E::Credential("x".into()), ErrorCode::Credential),
            (E::Network("x".into()), ErrorCode::Network),
            (E::Http { status: 500, body: "x".into() }, ErrorCode::Network),
            (E::InvalidInput("x".into()), ErrorCode::InvalidInput),
            (E::InvalidState("x".into()), ErrorCode::InvalidState),
            (E::Timeout("x".into()), ErrorCode::Timeout),
            (E::Session("x".into()), ErrorCode::Session),
            (E::Unexpected("x".into()), ErrorCode::Other),
        ];
        for (e, code) in cases {
            assert_eq!(AppError::from(e).code, code);
        }
    }

    #[test]
    fn code_serializes_as_snake_case() {
        assert_eq!(serde_json::to_string(&ErrorCode::InvalidInput).unwrap(), "\"invalid_input\"");
    }
}
