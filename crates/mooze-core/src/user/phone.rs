//! Phone verification.
//!
//! These endpoints use a plain client without the session token.
//! The status stream is Server-Sent Events; the core builds the URL, parses
//! each event and gives the reconnect policy. The platform runs the stream.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::api::join_url;
use crate::ports::{HttpClient, HttpMethod, HttpRequest, HttpResponse};
use crate::{Error, Result};

/// Default base URL of the phone endpoints (note the `/v1/`).
pub const DEFAULT_PHONE_BASE_URL: &str = "https://api.mooze.app/v1/";

/// Public IP lookup.
pub const IP_ADDRESS_URL: &str = "https://api.ipify.org?format=json";

/// Timeout of phone requests.
pub const PHONE_TIMEOUT_MS: u64 = 10_000;

/// SSE reconnect: base interval.
pub const SSE_RECONNECT_INTERVAL_MS: u64 = 1_000;

/// SSE reconnect: max attempts.
pub const SSE_RECONNECT_MAX_ATTEMPTS: u32 = 5;

/// Delivery channel of the code.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PhoneVerificationMethod {
    /// SMS.
    Sms,
    /// Telegram.
    Telegram,
    /// WhatsApp.
    Whatsapp,
}

impl PhoneVerificationMethod {
    /// Wire name.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Sms => "sms",
            Self::Telegram => "telegram",
            Self::Whatsapp => "whatsapp",
        }
    }
}

/// Device data the platform collects. `None` fields are sent as `null`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PhoneDeviceInfo {
    /// `"android"` or `"ios"`.
    pub platform: Option<String>,
    /// Device model.
    pub device_model: Option<String>,
    /// OS version.
    pub os_version: Option<String>,
    /// `version+buildNumber`.
    pub app_version: Option<String>,
    /// Raw `UniqueIdentifier.serial` (`"unknown"` when absent).
    pub device_id: Option<String>,
}

/// Body of `POST /phone/begin_verification`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BeginVerificationRequest {
    /// Phone number.
    pub phone_number: String,
    /// Method wire name.
    pub method: String,
    /// Public IP.
    pub ip_address: Option<String>,
    /// Device id.
    pub device_id: Option<String>,
    /// Platform.
    pub platform: Option<String>,
    /// Device model.
    pub device_model: Option<String>,
    /// App version.
    pub app_version: Option<String>,
    /// OS version.
    pub os_version: Option<String>,
}

impl BeginVerificationRequest {
    /// Builds the body from its parts.
    pub fn new(phone_number: &str, method: PhoneVerificationMethod, ip_address: Option<String>, device: &PhoneDeviceInfo) -> Self {
        Self {
            phone_number: phone_number.to_owned(),
            method: method.as_str().to_owned(),
            ip_address,
            device_id: device.device_id.clone(),
            platform: device.platform.clone(),
            device_model: device.device_model.clone(),
            app_version: device.app_version.clone(),
            os_version: device.os_version.clone(),
        }
    }
}

/// One status event from the SSE stream.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VerificationStatus {
    /// Status text.
    pub status: String,
    /// Optional message.
    #[serde(default)]
    pub message: Option<String>,
}

/// Parses the `data` field of one SSE event.
pub fn parse_status_event(data: &str) -> Result<VerificationStatus> {
    Ok(serde_json::from_str(data)?)
}

/// SSE subscription URL for a verification.
///
/// NOTE: a base ending in `/` does not give `//subscribe`. The `event_id` value is the
/// verification id, not the phone number.
pub fn status_subscribe_url(base_url: &str, verification_id: &str) -> String {
    let base = join_url(base_url, "/subscribe");
    format!("{base}?event_type=phone_verification&event_id={}", crate::api::encode_path_segment(verification_id))
}

/// Delay before SSE reconnect `attempt` (1-based). `None` after the last attempt.
/// Exponential: 1 s, 2 s, 4 s, 8 s, 16 s.
pub fn sse_reconnect_delay_ms(attempt: u32) -> Option<u64> {
    if attempt == 0 || attempt > SSE_RECONNECT_MAX_ATTEMPTS {
        return None;
    }
    Some(SSE_RECONNECT_INTERVAL_MS << (attempt - 1))
}

/// Phone verification endpoints.
pub struct PhoneVerificationClient<H: HttpClient> {
    http: H,
    base_url: String,
}

impl<H: HttpClient> PhoneVerificationClient<H> {
    /// New client. Empty `base_url` means [`DEFAULT_PHONE_BASE_URL`].
    pub fn new(http: H, base_url: &str) -> Self {
        let base_url = if base_url.is_empty() { DEFAULT_PHONE_BASE_URL } else { base_url };
        Self { http, base_url: base_url.to_owned() }
    }

    /// Starts a verification and returns its id.
    /// A failed IP lookup sends `ip_address: null`.
    pub async fn begin_phone_verification(
        &self,
        phone_number: &str,
        method: PhoneVerificationMethod,
        device: &PhoneDeviceInfo,
    ) -> Result<String> {
        let ip = self.fetch_ip_address().await.ok();
        self.start_phone_verification(&BeginVerificationRequest::new(phone_number, method, ip, device)).await
    }

    /// `POST /phone/begin_verification`. Requires 200/201 and a `verification_id`.
    pub async fn start_phone_verification(&self, request: &BeginVerificationRequest) -> Result<String> {
        let response = self.post("/phone/begin_verification", &serde_json::to_value(request)?).await?;
        let data = decode_maybe_string_json(&response)?;
        data.get("verification_id")
            .and_then(Value::as_str)
            .map(str::to_owned)
            .ok_or_else(|| Error::protocol("phone verification service unavailable: no verification_id"))
    }

    /// `POST /phone/verify`. Returns the `success` flag.
    pub async fn verify_code(&self, verification_id: &str, code: &str) -> Result<bool> {
        let response = self.post("/phone/verify", &json!({"verification_id": verification_id, "code": code})).await?;
        let data = decode_maybe_string_json(&response)?;
        data.get("success").and_then(Value::as_bool).ok_or_else(|| Error::protocol("phone verify: `success` missing"))
    }

    /// Public IP from ipify.
    pub async fn fetch_ip_address(&self) -> Result<String> {
        let response = self.http.send(HttpRequest::get(IP_ADDRESS_URL)).await?;
        if response.status != 200 {
            return Err(Error::Http { status: response.status, body: response.text() });
        }
        let body: Value = serde_json::from_slice(&response.body)?;
        body.get("ip").and_then(Value::as_str).map(str::to_owned).ok_or_else(|| Error::protocol("ipify: `ip` missing"))
    }

    /// The SSE URL for `verification_id`.
    pub fn status_url(&self, verification_id: &str) -> String {
        status_subscribe_url(&self.base_url, verification_id)
    }

    async fn post(&self, path: &str, body: &Value) -> Result<HttpResponse> {
        let request = HttpRequest::json(HttpMethod::Post, join_url(&self.base_url, path), body)?.timeout_ms(PHONE_TIMEOUT_MS);
        let response = self.http.send(request).await?;
        if response.status == 200 || response.status == 201 {
            Ok(response)
        } else {
            Err(Error::Http { status: response.status, body: response.text() })
        }
    }
}

/// Parses a JSON body, unwrapping one level of JSON-in-a-string.
fn decode_maybe_string_json(response: &HttpResponse) -> Result<Value> {
    match serde_json::from_slice::<Value>(&response.body)? {
        Value::String(inner) => Ok(serde_json::from_str(&inner)?),
        other => Ok(other),
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::testing::{block_on, MockHttp};

    const BEGIN: &str = "https://api.mooze.app/v1/phone/begin_verification";
    const VERIFY: &str = "https://api.mooze.app/v1/phone/verify";

    fn device() -> PhoneDeviceInfo {
        PhoneDeviceInfo {
            platform: Some("android".into()),
            device_model: Some("Pixel 8".into()),
            os_version: Some("15".into()),
            app_version: Some("2.4.0+120".into()),
            device_id: None,
        }
    }

    #[test]
    fn begin_sends_full_body() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, IP_ADDRESS_URL, 200, json!({"ip": "203.0.113.7"}));
        http.on_json(HttpMethod::Post, BEGIN, 201, json!({"verification_id": "ver-123"}));
        let client = PhoneVerificationClient::new(http.clone(), "");
        let id = block_on(client.begin_phone_verification("+5511999990000", PhoneVerificationMethod::Whatsapp, &device()))
            .unwrap();
        assert_eq!(id, "ver-123");
        let req = http.last_request().unwrap();
        assert_eq!(req.timeout_ms, Some(PHONE_TIMEOUT_MS));
        assert!(!req.headers.contains_key("Authorization"));
        let body: Value = serde_json::from_slice(req.body.as_ref().unwrap()).unwrap();
        assert_eq!(
            body,
            json!({
                "phone_number": "+5511999990000", "method": "whatsapp", "ip_address": "203.0.113.7",
                "device_id": null, "platform": "android", "device_model": "Pixel 8",
                "app_version": "2.4.0+120", "os_version": "15"
            })
        );
    }

    #[test]
    fn begin_tolerates_ip_failure_and_requires_id() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Post, BEGIN, 200, json!({"status": "queued"}));
        let client = PhoneVerificationClient::new(http.clone(), "");
        let err = block_on(client.begin_phone_verification("1", PhoneVerificationMethod::Sms, &device())).unwrap_err();
        assert!(matches!(err, Error::Protocol(_)));
        let body: Value = serde_json::from_slice(http.last_request().unwrap().body.as_ref().unwrap()).unwrap();
        assert_eq!(body["ip_address"], Value::Null);
        http.on_json(HttpMethod::Post, BEGIN, 429, json!({}));
        assert!(matches!(
            block_on(client.begin_phone_verification("1", PhoneVerificationMethod::Sms, &device())),
            Err(Error::Http { status: 429, .. })
        ));
    }

    #[test]
    fn verify_accepts_object_or_string_body() {
        let http = MockHttp::new();
        let client = PhoneVerificationClient::new(http.clone(), "");
        http.once_json(HttpMethod::Post, VERIFY, 200, json!({"success": true}));
        assert!(block_on(client.verify_code("ver-1", "123456")).unwrap());
        http.once_json(HttpMethod::Post, VERIFY, 200, json!("{\"success\": false}"));
        assert!(!block_on(client.verify_code("ver-1", "000000")).unwrap());
        let body: Value = serde_json::from_slice(http.last_request().unwrap().body.as_ref().unwrap()).unwrap();
        assert_eq!(body, json!({"verification_id": "ver-1", "code": "000000"}));
    }

    #[test]
    fn status_stream_helpers() {
        assert_eq!(
            status_subscribe_url(DEFAULT_PHONE_BASE_URL, "ver-1"),
            "https://api.mooze.app/v1/subscribe?event_type=phone_verification&event_id=ver-1"
        );
        let s = parse_status_event(r#"{"status":"verified","message":"ok"}"#).unwrap();
        assert_eq!(s, VerificationStatus { status: "verified".into(), message: Some("ok".into()) });
        assert_eq!(parse_status_event(r#"{"status":"pending"}"#).unwrap().message, None);
        assert!(parse_status_event(r#"{"message":"x"}"#).is_err());
        assert_eq!(sse_reconnect_delay_ms(1), Some(1000));
        assert_eq!(sse_reconnect_delay_ms(5), Some(16000));
        assert_eq!(sse_reconnect_delay_ms(6), None);
        assert_eq!(sse_reconnect_delay_ms(0), None);
    }
}
