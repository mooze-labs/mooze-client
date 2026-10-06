//! Authenticated client for the Mooze backend.
//!
//! Request flow:
//! - attach device metrics to JSON bodies,
//! - attach `Authorization: Bearer <jwt>` except on auth endpoints,
//! - on 401/403: force a session refresh once, then retry once.

use std::collections::BTreeMap;
use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use serde::de::DeserializeOwned;
use serde::Serialize;
use serde_json::Value;

use super::url::join_url;
use crate::ports::{HttpClient, HttpMethod, HttpRequest, HttpResponse, MaybeSend, MaybeSync};
use crate::{Error, Result};

/// Default backend base URL.
pub const DEFAULT_BASE_URL: &str = "https://api.mooze.app";

/// Name of the auth header.
pub const AUTHORIZATION_HEADER: &str = "Authorization";

/// Paths that never carry a token. Matched with `contains`.
pub const UNAUTHENTICATED_PATHS: [&str; 5] =
    ["/auth/challenge", "/auth/sign", "/auth/sign_challenge", "/auth/refresh", "/auth/login"];

/// True if `path` must skip the token.
pub fn should_skip_auth(path: &str) -> bool {
    UNAUTHENTICATED_PATHS.iter().any(|p| path.contains(p))
}

/// Supplies session tokens to [`MoozeApi`]. `auth::SessionManager` implements it.
pub trait SessionProvider: MaybeSend + MaybeSync {
    /// Returns a valid JWT.
    fn access_token(&self) -> impl Future<Output = Result<String>> + MaybeSend;

    /// Refreshes the session after the server rejected the JWT.
    fn force_refresh_token(&self) -> impl Future<Output = Result<String>> + MaybeSend;
}

impl<T: SessionProvider + ?Sized> SessionProvider for Arc<T> {
    fn access_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
        (**self).access_token()
    }
    fn force_refresh_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
        (**self).force_refresh_token()
    }
}

/// Client configuration.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApiConfig {
    /// Base URL without a trailing slash, for example `https://api.mooze.app`.
    pub base_url: String,
    /// Per-request timeout. `None` sets no timeout.
    pub timeout_ms: Option<u64>,
}

impl Default for ApiConfig {
    fn default() -> Self {
        Self { base_url: DEFAULT_BASE_URL.to_owned(), timeout_ms: None }
    }
}

/// Authenticated Mooze API client.
pub struct MoozeApi<H: HttpClient, S: SessionProvider> {
    http: H,
    session: S,
    config: ApiConfig,
    device_safe: AtomicBool,
    metrics: Mutex<Option<Value>>,
}

impl<H: HttpClient, S: SessionProvider> MoozeApi<H, S> {
    /// New client.
    pub fn new(http: H, session: S, config: ApiConfig) -> Self {
        Self { http, session, config, device_safe: AtomicBool::new(true), metrics: Mutex::new(None) }
    }

    /// The configuration.
    pub fn config(&self) -> &ApiConfig {
        &self.config
    }

    /// The HTTP client.
    pub fn http(&self) -> &H {
        &self.http
    }

    /// The session provider.
    pub fn session(&self) -> &S {
        &self.session
    }

    /// Sets the device integrity result. The platform runs the jailbreak/root
    /// check in release builds. Unsafe devices
    /// send requests without a token.
    pub fn set_device_safe(&self, safe: bool) {
        self.device_safe.store(safe, Ordering::SeqCst);
    }

    /// Sets the metrics object attached to request bodies (see
    /// `auth::metrics_json`). `None` or an empty object disables it.
    pub fn set_metrics(&self, metrics: Option<Value>) {
        *self.metrics.lock().unwrap_or_else(|e| e.into_inner()) = metrics;
    }

    /// Full URL for `path`.
    pub fn url(&self, path: &str) -> String {
        join_url(&self.config.base_url, path)
    }

    /// Adds `metrics` to the body.
    fn attach_metrics(&self, method: HttpMethod, body: Option<Value>) -> Option<Value> {
        let metrics = self.metrics.lock().unwrap_or_else(|e| e.into_inner()).clone();
        let metrics = match metrics {
            Some(Value::Object(m)) if !m.is_empty() => Value::Object(m),
            _ => return body,
        };
        match body {
            Some(Value::Object(mut map)) => {
                map.insert("metrics".to_owned(), metrics);
                Some(Value::Object(map))
            }
            // NOTE: GET/DELETE requests without data get no `{metrics}` body.
            // Browsers reject GET bodies.
            None if !matches!(method, HttpMethod::Get | HttpMethod::Delete) => {
                let mut map = serde_json::Map::new();
                map.insert("metrics".to_owned(), metrics);
                Some(Value::Object(map))
            }
            other => other,
        }
    }

    /// Builds the request for `path`, without the token.
    pub fn build_request(&self, method: HttpMethod, path: &str, body: Option<Value>) -> Result<HttpRequest> {
        let body = self.attach_metrics(method, body);
        let mut headers = BTreeMap::new();
        let body = match body {
            Some(value) => {
                headers.insert("Content-Type".to_owned(), "application/json".to_owned());
                Some(serde_json::to_vec(&value)?)
            }
            None => None,
        };
        Ok(HttpRequest { method, url: self.url(path), headers, body, timeout_ms: self.config.timeout_ms })
    }

    /// Sends one request with the auth flow. Non-2xx responses are returned,
    /// not turned into errors, except when the 401/403 recovery fails.
    ///
    /// Flow:
    /// 1. Auth paths go out without a token.
    /// 2. Safe devices attach the current JWT. A session error sends the
    ///    request without a token.
    /// 3. On 401/403: force a refresh. If it fails, return [`Error::Session`].
    ///    If it succeeds, retry once with the new JWT and return that response.
    pub async fn send(&self, method: HttpMethod, path: &str, body: Option<Value>) -> Result<HttpResponse> {
        let request = self.build_request(method, path, body)?;
        if should_skip_auth(path) {
            return self.http.send(request).await;
        }

        let mut request = request;
        if self.device_safe.load(Ordering::SeqCst) {
            if let Ok(token) = self.session.access_token().await {
                request.headers.insert(AUTHORIZATION_HEADER.to_owned(), bearer(&token));
            }
        }

        let response = self.http.send(request.clone()).await?;
        if response.status != 401 && response.status != 403 {
            return Ok(response);
        }

        match self.session.force_refresh_token().await {
            Err(e) => Err(Error::Session(format!("http {} and refresh failed: {e}", response.status))),
            Ok(token) => {
                request.headers.insert(AUTHORIZATION_HEADER.to_owned(), bearer(&token));
                self.http.send(request).await
            }
        }
    }

    /// GET `path` and parse a 2xx JSON body. Non-2xx becomes [`Error::Http`].
    pub async fn get_json<T: DeserializeOwned>(&self, path: &str) -> Result<T> {
        self.send(HttpMethod::Get, path, None).await?.json()
    }

    /// POST a JSON body and parse a 2xx JSON response.
    pub async fn post_json<B: Serialize + ?Sized, T: DeserializeOwned>(&self, path: &str, body: &B) -> Result<T> {
        let body = serde_json::to_value(body)?;
        self.send(HttpMethod::Post, path, Some(body)).await?.json()
    }

    /// POST a JSON body and require a 2xx status. Ignores the response body.
    pub async fn post_unit<B: Serialize + ?Sized>(&self, path: &str, body: &B) -> Result<HttpResponse> {
        let body = serde_json::to_value(body)?;
        self.send(HttpMethod::Post, path, Some(body)).await?.error_for_status()
    }
}

fn bearer(token: &str) -> String {
    format!("Bearer {token}")
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::testing::{block_on, MockHttp};
    use serde_json::json;
    use std::sync::atomic::AtomicUsize;

    #[derive(Default)]
    struct FakeSession {
        refreshes: AtomicUsize,
        refresh_fails: bool,
        no_token: bool,
    }

    impl SessionProvider for FakeSession {
        fn access_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            let r = if self.no_token { Err(Error::Session("none".into())) } else { Ok("old".to_owned()) };
            std::future::ready(r)
        }
        fn force_refresh_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            self.refreshes.fetch_add(1, Ordering::SeqCst);
            let r = if self.refresh_fails { Err(Error::Session("boom".into())) } else { Ok("new".to_owned()) };
            std::future::ready(r)
        }
    }

    const ME: &str = "https://api.mooze.app/users/me";

    #[test]
    fn attaches_token() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, ME, 200, json!({"ok": true}));
        let api = MoozeApi::new(http.clone(), FakeSession::default(), ApiConfig::default());
        let v: Value = block_on(api.get_json("/users/me")).unwrap();
        assert_eq!(v, json!({"ok": true}));
        let req = http.last_request().unwrap();
        assert_eq!(req.headers.get(AUTHORIZATION_HEADER).unwrap(), "Bearer old");
        assert!(req.body.is_none());
    }

    #[test]
    fn retries_once_after_401() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, ME, 200, json!({"ok": true}));
        http.once_json(HttpMethod::Get, ME, 401, json!({"error": "expired"}));
        let session = Arc::new(FakeSession::default());
        let api = MoozeApi::new(http.clone(), session.clone(), ApiConfig::default());
        let v: Value = block_on(api.get_json("/users/me")).unwrap();
        assert_eq!(v["ok"], true);
        let reqs = http.requests();
        assert_eq!(reqs.len(), 2);
        assert_eq!(reqs[0].headers[AUTHORIZATION_HEADER], "Bearer old");
        assert_eq!(reqs[1].headers[AUTHORIZATION_HEADER], "Bearer new");
        assert_eq!(session.refreshes.load(Ordering::SeqCst), 1);
    }

    #[test]
    fn second_401_is_returned_without_loop() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, ME, 403, json!({}));
        let session = Arc::new(FakeSession::default());
        let api = MoozeApi::new(http.clone(), session.clone(), ApiConfig::default());
        let err = block_on(api.get_json::<Value>("/users/me")).unwrap_err();
        assert!(matches!(err, Error::Http { status: 403, .. }));
        assert_eq!(http.requests().len(), 2);
        assert_eq!(session.refreshes.load(Ordering::SeqCst), 1);
    }

    #[test]
    fn refresh_failure_maps_to_session_error() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, ME, 401, json!({}));
        let session = FakeSession { refresh_fails: true, ..Default::default() };
        let api = MoozeApi::new(http.clone(), session, ApiConfig::default());
        let err = block_on(api.get_json::<Value>("/users/me")).unwrap_err();
        assert!(matches!(err, Error::Session(ref m) if m.contains("401")));
        assert_eq!(http.requests().len(), 1);
    }

    #[test]
    fn auth_paths_skip_token_and_refresh() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Post, "https://api.mooze.app/auth/refresh", 401, json!({}));
        let session = Arc::new(FakeSession::default());
        let api = MoozeApi::new(http.clone(), session.clone(), ApiConfig::default());
        let resp = block_on(api.send(HttpMethod::Post, "/auth/refresh", Some(json!({})))).unwrap();
        assert_eq!(resp.status, 401);
        assert!(!http.last_request().unwrap().headers.contains_key(AUTHORIZATION_HEADER));
        assert_eq!(session.refreshes.load(Ordering::SeqCst), 0);
    }

    #[test]
    fn unsafe_device_or_missing_session_sends_without_token() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, ME, 200, json!({}));
        let api = MoozeApi::new(http.clone(), FakeSession::default(), ApiConfig::default());
        api.set_device_safe(false);
        block_on(api.get_json::<Value>("/users/me")).unwrap();
        assert!(!http.last_request().unwrap().headers.contains_key(AUTHORIZATION_HEADER));

        let session = FakeSession { no_token: true, ..Default::default() };
        let api = MoozeApi::new(http.clone(), session, ApiConfig::default());
        block_on(api.get_json::<Value>("/users/me")).unwrap();
        assert!(!http.last_request().unwrap().headers.contains_key(AUTHORIZATION_HEADER));
    }

    #[test]
    fn metrics_are_merged_into_post_bodies() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Post, "https://api.mooze.app/users/me/referral", 200, json!({}));
        http.on_json(HttpMethod::Get, ME, 200, json!({}));
        let api = MoozeApi::new(http.clone(), FakeSession::default(), ApiConfig::default());
        api.set_metrics(Some(json!({"device_id": "abc", "battery_level": 80})));
        block_on(api.post_unit("/users/me/referral", &json!({"referral_code": "X"}))).unwrap();
        let body: Value = serde_json::from_slice(http.last_request().unwrap().body.as_ref().unwrap()).unwrap();
        assert_eq!(body, json!({"referral_code": "X", "metrics": {"device_id": "abc", "battery_level": 80}}));
        block_on(api.get_json::<Value>("/users/me")).unwrap();
        assert!(http.last_request().unwrap().body.is_none());
    }
}
