//! Error families for user-facing messages. The UI picks the copy.

use crate::Error;

/// Error family. Port of the branches in Dart `humanizeError`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorKind {
    /// Transport failure or timeout.
    NoInternet,
    /// HTTP 401, or a session/credential failure.
    AuthenticationFailed,
    /// HTTP 403.
    AccessDenied,
    /// HTTP 404.
    ServiceNotFound,
    /// HTTP 5xx.
    ServerUnavailable,
    /// Other HTTP statuses and service failures.
    ServerCommunication,
    /// Storage failure.
    LoadData,
    /// Anything else.
    SomethingWentWrong,
}

/// Maps a crate error to its family, as Dart `humanizeError` does.
pub fn classify_error(error: &Error) -> ErrorKind {
    match error {
        Error::Network(_) | Error::Timeout(_) => ErrorKind::NoInternet,
        Error::Http { status, .. } => match *status {
            401 => ErrorKind::AuthenticationFailed,
            403 => ErrorKind::AccessDenied,
            404 => ErrorKind::ServiceNotFound,
            s if s >= 500 => ErrorKind::ServerUnavailable,
            _ => ErrorKind::ServerCommunication,
        },
        Error::Sync { .. } | Error::Service { .. } => ErrorKind::ServerCommunication,
        Error::Credential(_) | Error::Session(_) => ErrorKind::AuthenticationFailed,
        Error::Storage(_) => ErrorKind::LoadData,
        Error::Boot { .. }
        | Error::Protocol(_)
        | Error::InvalidInput(_)
        | Error::InvalidState(_)
        | Error::Unexpected(_) => ErrorKind::SomethingWentWrong,
    }
}

/// Result of [`detect_server_error`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ServerErrorInfo {
    /// First `5xx` status found in the message, if any.
    pub status_code: Option<u16>,
}

/// Detects "API down" errors the way `ensureAuthSessionProvider` does.
///
/// The Dart code inspects the error text: it matches `500`, `502`, `503`,
/// `504`, "server error" or "service unavailable", then extracts the first
/// whole-word `5xx` number.
pub fn detect_server_error(error: &Error) -> Option<ServerErrorInfo> {
    let text = error.to_string();
    let lower = text.to_lowercase();
    let is_server = ["500", "502", "503", "504"].iter().any(|c| text.contains(c))
        || lower.contains("server error")
        || lower.contains("service unavailable");
    if !is_server {
        return None;
    }
    Some(ServerErrorInfo { status_code: first_5xx_word(&text) })
}

/// Finds the first `\b(5\d{2})\b` match.
fn first_5xx_word(text: &str) -> Option<u16> {
    let bytes = text.as_bytes();
    let is_word = |b: u8| b.is_ascii_alphanumeric() || b == b'_';
    for i in 0..bytes.len().saturating_sub(2) {
        let window = &bytes[i..i + 3];
        if window[0] != b'5' || !window[1].is_ascii_digit() || !window[2].is_ascii_digit() {
            continue;
        }
        let left_ok = i == 0 || !is_word(bytes[i - 1]);
        let right_ok = i + 3 == bytes.len() || !is_word(bytes[i + 3]);
        if left_ok && right_ok {
            return std::str::from_utf8(window).ok()?.parse().ok();
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classify_http() {
        let http = |status| Error::Http { status, body: String::new() };
        assert_eq!(classify_error(&http(401)), ErrorKind::AuthenticationFailed);
        assert_eq!(classify_error(&http(403)), ErrorKind::AccessDenied);
        assert_eq!(classify_error(&http(404)), ErrorKind::ServiceNotFound);
        assert_eq!(classify_error(&http(502)), ErrorKind::ServerUnavailable);
        assert_eq!(classify_error(&http(400)), ErrorKind::ServerCommunication);
        assert_eq!(classify_error(&Error::Timeout("x".into())), ErrorKind::NoInternet);
        assert_eq!(classify_error(&Error::Session("x".into())), ErrorKind::AuthenticationFailed);
    }

    #[test]
    fn server_error_detection() {
        let e = Error::Http { status: 503, body: "down".into() };
        assert_eq!(detect_server_error(&e), Some(ServerErrorInfo { status_code: Some(503) }));
        let e = Error::Network("Service Unavailable".into());
        assert_eq!(detect_server_error(&e), Some(ServerErrorInfo { status_code: None }));
        assert_eq!(detect_server_error(&Error::Http { status: 400, body: String::new() }), None);
        // "5000" contains "500" but has no whole-word 5xx.
        let e = Error::Unexpected("amount 5000".into());
        assert_eq!(detect_server_error(&e), Some(ServerErrorInfo { status_code: None }));
    }
}
