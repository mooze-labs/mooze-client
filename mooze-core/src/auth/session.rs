//! API session model. Port of `models/session.dart` and `models/auth_challenge.dart`.

use serde::{Deserialize, Serialize};
use serde_json::Value;

use super::b64;
use crate::api::data_or_self;
use crate::{Error, Result};

/// JWT plus refresh token. `Debug` hides both tokens.
#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Session {
    /// Access token (JWT).
    pub jwt: String,
    /// Refresh token.
    pub refresh_token: String,
}

impl std::fmt::Debug for Session {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Session").field("jwt", &"<redacted>").field("refresh_token", &"<redacted>").finish()
    }
}

impl Session {
    /// New session.
    pub fn new(jwt: impl Into<String>, refresh_token: impl Into<String>) -> Self {
        Self { jwt: jwt.into(), refresh_token: refresh_token.into() }
    }

    /// Parses `{data: {jwt, refresh_token}}` or the flat shape (Dart `Session.fromJson`).
    pub fn from_json(json: &Value) -> Result<Self> {
        let data = data_or_self(json);
        match (data.get("jwt").and_then(Value::as_str), data.get("refresh_token").and_then(Value::as_str)) {
            (Some(jwt), Some(rt)) => Ok(Self::new(jwt, rt)),
            _ => Err(Error::Session("Session.fromJson: jwt or refresh_token is null".into())),
        }
    }

    /// JWT `exp` claim in milliseconds, rounded as Dart does.
    pub fn expires_at_ms(&self) -> Result<i64> {
        let payload = parse_jwt_payload(&self.jwt)?;
        let exp = payload.get("exp").ok_or_else(|| Error::Session("Token does not contain expiry date".into()))?;
        let exp = exp.as_f64().ok_or_else(|| Error::Session("Token expiry date is not a valid number".into()))?;
        Ok((exp * 1000.0).round() as i64)
    }

    /// True if the JWT expired before `now_ms` (Dart `isExpired`).
    /// Errors mean the JWT is unreadable; callers treat that as expired.
    pub fn is_expired(&self, now_ms: u64) -> Result<bool> {
        Ok(self.expires_at_ms()? < now_ms as i64)
    }

    /// Same refresh token, new JWT.
    pub fn with_new_jwt(&self, jwt: impl Into<String>) -> Self {
        Self::new(jwt, self.refresh_token.clone())
    }
}

/// Decodes the JWT payload object.
fn parse_jwt_payload(jwt: &str) -> Result<serde_json::Map<String, Value>> {
    let parts: Vec<&str> = jwt.split('.').collect();
    if parts.len() != 3 {
        return Err(Error::Session("Failed to parse token: invalid token".into()));
    }
    let bytes = b64::decode_jwt_segment(parts[1])?;
    let text = String::from_utf8(bytes).map_err(|e| Error::Session(format!("jwt utf8: {e}")))?;
    match serde_json::from_str::<Value>(&text) {
        Ok(Value::Object(map)) => Ok(map),
        Ok(_) => Err(Error::Session("Failed to parse token: invalid payload".into())),
        Err(e) => Err(Error::Session(format!("Failed to parse token: {e}"))),
    }
}

/// Login challenge from `POST /auth/challenge`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AuthChallenge {
    /// Challenge id (JSON `id`).
    pub challenge_id: String,
    /// Base64 message to sign.
    pub message: String,
}

impl AuthChallenge {
    /// Parses `{data: {id, message}}` or the flat shape.
    pub fn from_json(json: &Value) -> Result<Self> {
        let data = data_or_self(json);
        match (data.get("id").and_then(Value::as_str), data.get("message").and_then(Value::as_str)) {
            (Some(id), Some(message)) => Ok(Self { challenge_id: id.to_owned(), message: message.to_owned() }),
            _ => Err(Error::protocol("AuthChallenge: id or message missing")),
        }
    }
}

/// Builds an unsigned JWT with the given payload. Test helper.
#[cfg(test)]
pub(crate) fn test_jwt(payload: &Value) -> String {
    use bdk_wallet::bitcoin::base64::engine::general_purpose::URL_SAFE_NO_PAD;
    use bdk_wallet::bitcoin::base64::Engine;
    let header = URL_SAFE_NO_PAD.encode(br#"{"alg":"none","typ":"JWT"}"#);
    let body = URL_SAFE_NO_PAD.encode(payload.to_string());
    format!("{header}.{body}.sig")
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn parses_both_envelopes() {
        let s = Session::from_json(&json!({"data": {"jwt": "a", "refresh_token": "b"}})).unwrap();
        assert_eq!(s, Session::new("a", "b"));
        let s = Session::from_json(&json!({"jwt": "a", "refresh_token": "b"})).unwrap();
        assert_eq!(s, Session::new("a", "b"));
        assert!(Session::from_json(&json!({"data": {"jwt": "a"}})).is_err());
        assert!(!format!("{s:?}").contains("\"b\""));
    }

    #[test]
    fn expiry_against_clock() {
        let s = Session::new(test_jwt(&json!({"exp": 1_700_000_000, "sub": "u"})), "r");
        assert_eq!(s.expires_at_ms().unwrap(), 1_700_000_000_000);
        assert!(!s.is_expired(1_700_000_000_000).unwrap());
        assert!(s.is_expired(1_700_000_000_001).unwrap());
        let frac = Session::new(test_jwt(&json!({"exp": 1.5})), "r");
        assert_eq!(frac.expires_at_ms().unwrap(), 1500);
    }

    #[test]
    fn expiry_errors() {
        assert!(Session::new("nope", "r").is_expired(0).is_err());
        assert!(Session::new(test_jwt(&json!({"sub": "u"})), "r").is_expired(0).is_err());
        assert!(Session::new(test_jwt(&json!({"exp": "soon"})), "r").is_expired(0).is_err());
        assert!(Session::new(test_jwt(&json!([1])), "r").is_expired(0).is_err());
    }

    #[test]
    fn challenge() {
        let c = AuthChallenge::from_json(&json!({"data": {"id": "c1", "message": "bXNn"}})).unwrap();
        assert_eq!(c.challenge_id, "c1");
        assert!(AuthChallenge::from_json(&json!({"id": 1})).is_err());
    }
}
