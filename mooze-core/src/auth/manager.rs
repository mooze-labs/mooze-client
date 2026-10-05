//! Session lifecycle. Port of `SessionManagerServiceImpl`,
//! `RemoteAuthServiceImpl` and the logic of `ensureAuthSessionProvider`.
//!
//! Storage: the JWT and the refresh token live in [`SecureStore`] under the
//! keys `jwt` and `refresh_token`, as raw UTF-8 strings. This matches the
//! Flutter secure storage layout, so existing installs keep their session.
//!
//! NOTE(port): Dart coalesces concurrent `getSession`/refresh/create calls
//! into one in-flight future. The core has no executor to share futures;
//! the platform should serialize calls. The generation counter is kept, so
//! a write from a request that started before `delete_session` is dropped.

use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Mutex;

use serde_json::{json, Value};

use super::session::{AuthChallenge, Session};
use super::signature::{AuthKeyPair, ChallengeSigner};
use crate::api::{data_object_or_self, detect_server_error, join_url, SessionProvider, DEFAULT_BASE_URL};
use crate::domain::WalletCredentials;
use crate::ports::{Clock, HttpClient, HttpMethod, HttpRequest, MaybeSend, SecureStore};
use crate::{Error, Result};

/// Secure-store key of the JWT.
pub const JWT_KEY: &str = "jwt";
/// Secure-store key of the refresh token.
pub const REFRESH_TOKEN_KEY: &str = "refresh_token";
/// Timeout of auth requests (Dart: 10 s connect/receive/send).
pub const AUTH_TIMEOUT_MS: u64 = 10_000;

/// Refresh answered 404.
pub const REFRESH_TOKEN_NOT_FOUND: &str = "REFRESH_TOKEN_NOT_FOUND";
/// Refresh answered 401.
pub const REFRESH_TOKEN_UNAUTHORIZED: &str = "REFRESH_TOKEN_UNAUTHORIZED";
/// Refresh answered without a JWT.
pub const JWT_NULL_IN_REFRESH_RESPONSE: &str = "JWT_NULL_IN_REFRESH_RESPONSE";
/// No signer configured (no mnemonic).
pub const REMOTE_AUTH_NOT_CONFIGURED: &str = "RemoteAuthService not configured to create new session";
/// The device failed the integrity check.
pub const UNSAFE_DEVICE: &str = "Unsafe device detected";

/// Result of [`SessionManager::ensure`]. Mirrors the flags the Dart provider sets.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum EnsureOutcome {
    /// A valid session exists.
    Ready,
    /// No mnemonic, so no signer (Dart "mnemonic not found" sync error).
    MissingMnemonic,
    /// The backend looks down (Dart `apiDownProvider`, `apiStatusCodeProvider`).
    ApiDown {
        /// The 5xx status, if the error text contains one.
        status_code: Option<u16>,
    },
    /// Any other failure (Dart `syncErrorMessageProvider`).
    Failed {
        /// Error text.
        message: String,
    },
}

/// Builds the `POST /auth/challenge` request.
pub fn challenge_request(base_url: &str, public_key_b64: &str) -> Result<HttpRequest> {
    Ok(HttpRequest::json(HttpMethod::Post, join_url(base_url, "/auth/challenge"), &json!({"public_key": public_key_b64}))?
        .header("Accept", "application/json")
        .timeout_ms(AUTH_TIMEOUT_MS))
}

/// Builds the `POST /auth/sign` request.
pub fn sign_request(base_url: &str, challenge_id: &str, signature_b64: &str) -> Result<HttpRequest> {
    Ok(HttpRequest::json(
        HttpMethod::Post,
        join_url(base_url, "/auth/sign"),
        &json!({"challenge_id": challenge_id, "signature": signature_b64}),
    )?
    .header("Accept", "application/json")
    .timeout_ms(AUTH_TIMEOUT_MS))
}

/// Builds the `POST /auth/refresh` request.
pub fn refresh_request(base_url: &str, refresh_token: &str) -> Result<HttpRequest> {
    Ok(HttpRequest::json(HttpMethod::Post, join_url(base_url, "/auth/refresh"), &json!({"refresh_token": refresh_token}))?
        .timeout_ms(AUTH_TIMEOUT_MS))
}

/// Owns the API session: read, refresh, create, persist.
pub struct SessionManager<H: HttpClient, S: SecureStore, C: Clock, G: ChallengeSigner = AuthKeyPair> {
    http: H,
    store: S,
    clock: C,
    base_url: String,
    signer: Option<G>,
    device_safe: AtomicBool,
    /// `None`: cache not loaded. `Some(x)`: last value read or written.
    cache: Mutex<Option<Option<Session>>>,
    generation: AtomicU64,
}

impl<H: HttpClient, S: SecureStore, C: Clock> SessionManager<H, S, C, AuthKeyPair> {
    /// Manager for the wallet credentials. Absent mnemonic means no signer,
    /// as in Dart `sessionManagerServiceProvider`.
    pub fn for_credentials(http: H, store: S, clock: C, base_url: &str, credentials: &WalletCredentials) -> Result<Self> {
        let signer = if credentials.is_absent() { None } else { Some(AuthKeyPair::from_seed(&credentials.mnemonic)?) };
        Ok(Self::new(http, store, clock, base_url, signer))
    }
}

impl<H: HttpClient, S: SecureStore, C: Clock, G: ChallengeSigner> SessionManager<H, S, C, G> {
    /// New manager. `base_url` defaults to [`DEFAULT_BASE_URL`] when empty.
    pub fn new(http: H, store: S, clock: C, base_url: &str, signer: Option<G>) -> Self {
        let base_url = if base_url.is_empty() { DEFAULT_BASE_URL } else { base_url };
        Self {
            http,
            store,
            clock,
            base_url: base_url.to_owned(),
            signer,
            device_safe: AtomicBool::new(true),
            cache: Mutex::new(None),
            generation: AtomicU64::new(0),
        }
    }

    /// Sets the device integrity result (Dart `SafeDevice.isSafeDevice`).
    /// Unsafe devices cannot request a login challenge.
    pub fn set_device_safe(&self, safe: bool) {
        self.device_safe.store(safe, Ordering::SeqCst);
    }

    /// Returns a valid session: stored and fresh, refreshed, or newly created.
    pub async fn get_session(&self) -> Result<Session> {
        let Some(stored) = self.read_session().await? else {
            return self.create().await;
        };
        if !self.is_expired(&stored) {
            return Ok(stored);
        }
        self.refresh_with_recovery(&stored).await
    }

    /// Refreshes `session`, falling back to a new session on failure.
    pub async fn refresh_session(&self, session: &Session) -> Result<Session> {
        self.refresh_with_recovery(session).await
    }

    /// Refreshes the stored session regardless of local expiry.
    /// Used after the server rejected a JWT with 401/403.
    pub async fn force_refresh(&self) -> Result<Session> {
        match self.read_session().await? {
            None => self.create().await,
            Some(stored) => self.refresh_with_recovery(&stored).await,
        }
    }

    /// Persists `session`.
    pub async fn save_session(&self, session: &Session) -> Result<()> {
        self.write_session(session, None).await
    }

    /// Erases the session and drops writes from older requests.
    pub async fn delete_session(&self) -> Result<()> {
        self.generation.fetch_add(1, Ordering::SeqCst);
        self.store.delete(JWT_KEY).await?;
        self.store.delete(REFRESH_TOKEN_KEY).await?;
        *self.cache.lock().unwrap_or_else(|e| e.into_inner()) = None;
        Ok(())
    }

    /// Dart `SessionAuthenticator.invalidate`: same as [`Self::delete_session`].
    pub async fn invalidate(&self) -> Result<()> {
        self.delete_session().await
    }

    /// Boot-time session check (Dart `ensureAuthSessionProvider`).
    ///
    /// Gets a session. On failure, deletes it and tries once more.
    /// Classifies the final failure as API-down or a plain error.
    pub async fn ensure(&self) -> EnsureOutcome {
        if self.signer.is_none() {
            return EnsureOutcome::MissingMnemonic;
        }
        if self.get_session().await.is_ok() {
            return EnsureOutcome::Ready;
        }
        // NOTE(port): Dart ignores the delete result here.
        let _ = self.delete_session().await;
        match self.get_session().await {
            Ok(_) => EnsureOutcome::Ready,
            Err(e) => match detect_server_error(&e) {
                Some(info) => EnsureOutcome::ApiDown { status_code: info.status_code },
                None => EnsureOutcome::Failed { message: e.to_string() },
            },
        }
    }

    /// Manual refresh (Dart `refreshAuthSessionProvider`). Returns success.
    pub async fn refresh_current(&self) -> bool {
        match self.get_session().await {
            Err(_) => self.get_session().await.is_ok(),
            Ok(current) => match self.refresh_session(&current).await {
                Err(_) => false,
                Ok(refreshed) => {
                    // NOTE(port): Dart ignores the save result.
                    let _ = self.save_session(&refreshed).await;
                    true
                }
            },
        }
    }

    /// Requests a login challenge for this signer's public key.
    pub async fn request_login_challenge(&self) -> Result<AuthChallenge> {
        if !self.device_safe.load(Ordering::SeqCst) {
            return Err(Error::Session(UNSAFE_DEVICE.into()));
        }
        let signer = self.signer.as_ref().ok_or_else(|| Error::Session(REMOTE_AUTH_NOT_CONFIGURED.into()))?;
        let request = challenge_request(&self.base_url, &signer.public_key_base64())?;
        let body: Value = self.http.send(request).await?.json()?;
        AuthChallenge::from_json(&body)
    }

    /// Signs `challenge` and exchanges it for a session.
    pub async fn sign_challenge(&self, challenge: &AuthChallenge) -> Result<Session> {
        let signer = self.signer.as_ref().ok_or_else(|| Error::Session(REMOTE_AUTH_NOT_CONFIGURED.into()))?;
        let signature = signer.sign_message(&challenge.message)?;
        let request = sign_request(&self.base_url, &challenge.challenge_id, &signature)?;
        let body: Value = self.http.send(request).await?.json()?;
        Session::from_json(&body)
    }

    fn is_expired(&self, session: &Session) -> bool {
        session.is_expired(self.clock.now_ms()).unwrap_or(true)
    }

    async fn refresh_with_recovery(&self, current: &Session) -> Result<Session> {
        match self.do_refresh(current).await {
            Ok(session) => Ok(session),
            Err(_) => {
                if let Some(reread) = self.load_from_storage().await? {
                    if !self.is_expired(&reread) {
                        return Ok(reread);
                    }
                }
                self.delete_session().await?;
                self.create().await
            }
        }
    }

    async fn do_refresh(&self, current: &Session) -> Result<Session> {
        let generation = self.generation.load(Ordering::SeqCst);
        let response = self.http.send(refresh_request(&self.base_url, &current.refresh_token)?).await?;
        match response.status {
            404 => return Err(Error::Session(REFRESH_TOKEN_NOT_FOUND.into())),
            401 => return Err(Error::Session(REFRESH_TOKEN_UNAUTHORIZED.into())),
            _ => {}
        }
        let response = response.error_for_status()?;
        let body: Value = serde_json::from_slice(&response.body).unwrap_or(Value::Null);
        let envelope = data_object_or_self(&body);
        let jwt = match envelope.get("jwt").and_then(Value::as_str) {
            Some(jwt) if !jwt.is_empty() => jwt.to_owned(),
            _ => return Err(Error::Session(JWT_NULL_IN_REFRESH_RESPONSE.into())),
        };
        let refresh_token = match envelope.get("refresh_token").and_then(Value::as_str) {
            Some(rt) if !rt.is_empty() => rt.to_owned(),
            _ => current.refresh_token.clone(),
        };
        let session = Session { jwt, refresh_token };
        self.write_session(&session, Some(generation)).await?;
        Ok(session)
    }

    async fn create(&self) -> Result<Session> {
        if self.signer.is_none() {
            return Err(Error::Session(REMOTE_AUTH_NOT_CONFIGURED.into()));
        }
        let generation = self.generation.load(Ordering::SeqCst);
        // A refresh may have stored a valid session already; bypass the cache.
        if let Some(stored) = self.load_from_storage().await? {
            if !self.is_expired(&stored) {
                return Ok(stored);
            }
        }
        let challenge = self.request_login_challenge().await?;
        let session = self.sign_challenge(&challenge).await?;
        self.write_session(&session, Some(generation)).await?;
        Ok(session)
    }

    async fn read_session(&self) -> Result<Option<Session>> {
        let cached = self.cache.lock().unwrap_or_else(|e| e.into_inner()).clone();
        match cached {
            Some(value) => Ok(value),
            None => self.load_from_storage().await,
        }
    }

    async fn load_from_storage(&self) -> Result<Option<Session>> {
        let jwt = read_string(&self.store, JWT_KEY).await?;
        let refresh_token = read_string(&self.store, REFRESH_TOKEN_KEY).await?;
        let session = match (jwt, refresh_token) {
            (Some(jwt), Some(refresh_token)) => Some(Session { jwt, refresh_token }),
            _ => None,
        };
        *self.cache.lock().unwrap_or_else(|e| e.into_inner()) = Some(session.clone());
        Ok(session)
    }

    async fn write_session(&self, session: &Session, generation: Option<u64>) -> Result<()> {
        if let Some(generation) = generation {
            if generation != self.generation.load(Ordering::SeqCst) {
                // NOTE(port): Dart drops the write silently and still returns the session.
                return Ok(());
            }
        }
        self.store.put(JWT_KEY, session.jwt.as_bytes().to_vec()).await?;
        self.store.put(REFRESH_TOKEN_KEY, session.refresh_token.as_bytes().to_vec()).await?;
        *self.cache.lock().unwrap_or_else(|e| e.into_inner()) = Some(Some(session.clone()));
        Ok(())
    }
}

async fn read_string<S: SecureStore>(store: &S, key: &str) -> Result<Option<String>> {
    match store.get(key).await? {
        None => Ok(None),
        Some(bytes) => String::from_utf8(bytes).map(Some).map_err(Error::storage),
    }
}

// Explicit futures keep the MaybeSend bound visible at the impl site.
#[allow(clippy::manual_async_fn)]
impl<H: HttpClient, S: SecureStore, C: Clock, G: ChallengeSigner> SessionProvider for SessionManager<H, S, C, G> {
    fn access_token(&self) -> impl std::future::Future<Output = Result<String>> + MaybeSend {
        async move { self.get_session().await.map(|s| s.jwt) }
    }

    fn force_refresh_token(&self) -> impl std::future::Future<Output = Result<String>> + MaybeSend {
        async move { self.force_refresh().await.map(|s| s.jwt) }
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::api::{ApiConfig, MoozeApi};
    use crate::auth::session::test_jwt;
    use crate::auth::signature::verify_challenge_signature;
    use crate::domain::AppNetwork;
    use crate::ports::KvStore;
    use crate::testing::{block_on, FixedClock, MemoryKv, MockHttp};
    use std::sync::Arc;

    const MNEMONIC: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    const NOW_MS: u64 = 1_750_000_000_000;
    const BASE: &str = "https://api.mooze.app";

    fn jwt(exp_s: u64) -> String {
        test_jwt(&json!({"exp": exp_s, "sub": "user"}))
    }

    fn manager(http: &MockHttp, kv: &MemoryKv, clock: Arc<FixedClock>) -> SessionManager<MockHttp, MemoryKv, Arc<FixedClock>> {
        let creds = WalletCredentials { mnemonic: MNEMONIC.into(), network: AppNetwork::Mainnet };
        SessionManager::for_credentials(http.clone(), kv.clone(), clock, BASE, &creds).unwrap()
    }

    fn mock_login(http: &MockHttp, session_jwt: &str) {
        http.on_json(
            HttpMethod::Post,
            "https://api.mooze.app/auth/challenge",
            200,
            json!({"data": {"id": "ch-1", "message": "SGVsbG8gV29ybGQ="}}),
        );
        http.on_json(
            HttpMethod::Post,
            "https://api.mooze.app/auth/sign",
            200,
            json!({"data": {"jwt": session_jwt, "refresh_token": "rt-1"}}),
        );
    }

    async fn stored(kv: &MemoryKv) -> (Option<String>, Option<String>) {
        let j = kv.get(JWT_KEY).await.unwrap().map(|b| String::from_utf8(b).unwrap());
        let r = kv.get(REFRESH_TOKEN_KEY).await.unwrap().map(|b| String::from_utf8(b).unwrap());
        (j, r)
    }

    #[test]
    fn creates_session_via_challenge_and_persists() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let fresh = jwt(NOW_MS / 1000 + 3600);
        mock_login(&http, &fresh);
        let m = manager(&http, &kv, Arc::new(FixedClock::new(NOW_MS)));
        let s = block_on(m.get_session()).unwrap();
        assert_eq!(s, Session::new(fresh.clone(), "rt-1"));
        assert_eq!(block_on(stored(&kv)), (Some(fresh), Some("rt-1".into())));

        let reqs = http.requests();
        let challenge: Value = serde_json::from_slice(reqs[0].body.as_ref().unwrap()).unwrap();
        let pk = challenge["public_key"].as_str().unwrap().to_owned();
        let sign: Value = serde_json::from_slice(reqs[1].body.as_ref().unwrap()).unwrap();
        assert_eq!(sign["challenge_id"], "ch-1");
        assert!(verify_challenge_signature(&pk, "SGVsbG8gV29ybGQ=", sign["signature"].as_str().unwrap()).unwrap());
    }

    #[test]
    fn fresh_stored_session_needs_no_network() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let fresh = jwt(NOW_MS / 1000 + 60);
        let m = manager(&http, &kv, Arc::new(FixedClock::new(NOW_MS)));
        block_on(m.save_session(&Session::new(fresh.clone(), "rt"))).unwrap();
        assert_eq!(block_on(m.get_session()).unwrap().jwt, fresh);
        assert!(http.requests().is_empty());
    }

    #[test]
    fn expiry_with_fixed_clock_triggers_refresh() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let clock = Arc::new(FixedClock::new(NOW_MS));
        let exp_s = NOW_MS / 1000 + 60;
        let m = manager(&http, &kv, clock.clone());
        block_on(m.save_session(&Session::new(jwt(exp_s), "rt-old"))).unwrap();
        let refreshed = jwt(exp_s + 3600);
        http.on_json(HttpMethod::Post, "https://api.mooze.app/auth/refresh", 200, json!({"jwt": refreshed}));

        // Exactly at exp: not expired.
        clock.set(exp_s * 1000);
        block_on(m.get_session()).unwrap();
        assert!(http.requests().is_empty());

        // One ms later: expired, refresh keeps the old refresh token.
        clock.advance(1);
        let s = block_on(m.get_session()).unwrap();
        assert_eq!(s, Session::new(refreshed.clone(), "rt-old"));
        let req = http.last_request().unwrap();
        assert_eq!(serde_json::from_slice::<Value>(req.body.as_ref().unwrap()).unwrap(), json!({"refresh_token": "rt-old"}));
        assert_eq!(req.timeout_ms, Some(AUTH_TIMEOUT_MS));
        assert_eq!(block_on(stored(&kv)).0, Some(refreshed));
    }

    #[test]
    fn refresh_failure_recreates_session() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let m = manager(&http, &kv, Arc::new(FixedClock::new(NOW_MS)));
        block_on(m.save_session(&Session::new(jwt(NOW_MS / 1000 - 10), "rt-dead"))).unwrap();
        http.on_json(HttpMethod::Post, "https://api.mooze.app/auth/refresh", 401, json!({}));
        let fresh = jwt(NOW_MS / 1000 + 3600);
        mock_login(&http, &fresh);
        let s = block_on(m.get_session()).unwrap();
        assert_eq!(s, Session::new(fresh, "rt-1"));
        let urls: Vec<String> = http.requests().into_iter().map(|r| r.url).collect();
        assert_eq!(
            urls,
            vec![
                "https://api.mooze.app/auth/refresh",
                "https://api.mooze.app/auth/challenge",
                "https://api.mooze.app/auth/sign"
            ]
        );
    }

    #[test]
    fn refresh_error_codes() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let m = manager(&http, &kv, Arc::new(FixedClock::new(NOW_MS)));
        let s = Session::new(jwt(0), "rt");
        http.once_json(HttpMethod::Post, "https://api.mooze.app/auth/refresh", 404, json!({}));
        assert_eq!(block_on(m.do_refresh(&s)).unwrap_err(), Error::Session(REFRESH_TOKEN_NOT_FOUND.into()));
        http.once_json(HttpMethod::Post, "https://api.mooze.app/auth/refresh", 200, json!({"data": {"jwt": ""}}));
        assert_eq!(block_on(m.do_refresh(&s)).unwrap_err(), Error::Session(JWT_NULL_IN_REFRESH_RESPONSE.into()));
        http.once_json(
            HttpMethod::Post,
            "https://api.mooze.app/auth/refresh",
            200,
            json!({"data": {"jwt": "j2", "refresh_token": "rt2"}}),
        );
        assert_eq!(block_on(m.do_refresh(&s)).unwrap(), Session::new("j2", "rt2"));
    }

    #[test]
    fn no_signer_cannot_create() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let creds = WalletCredentials::absent(AppNetwork::Mainnet);
        let m = SessionManager::for_credentials(http.clone(), kv, FixedClock::new(NOW_MS), "", &creds).unwrap();
        assert_eq!(block_on(m.get_session()).unwrap_err(), Error::Session(REMOTE_AUTH_NOT_CONFIGURED.into()));
        assert_eq!(block_on(m.ensure()), EnsureOutcome::MissingMnemonic);
    }

    #[test]
    fn unsafe_device_blocks_challenge() {
        let http = MockHttp::new();
        let m = manager(&http, &MemoryKv::new(), Arc::new(FixedClock::new(NOW_MS)));
        m.set_device_safe(false);
        assert_eq!(block_on(m.get_session()).unwrap_err(), Error::Session(UNSAFE_DEVICE.into()));
        assert!(http.requests().is_empty());
    }

    #[test]
    fn ensure_classifies_api_down() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Post, "https://api.mooze.app/auth/challenge", 503, json!({"error": "maintenance"}));
        let m = manager(&http, &MemoryKv::new(), Arc::new(FixedClock::new(NOW_MS)));
        assert_eq!(block_on(m.ensure()), EnsureOutcome::ApiDown { status_code: Some(503) });
        // Two attempts: first get, then get after delete.
        assert_eq!(http.requests().len(), 2);

        let http = MockHttp::new();
        http.on_json(HttpMethod::Post, "https://api.mooze.app/auth/challenge", 400, json!({}));
        let m = manager(&http, &MemoryKv::new(), Arc::new(FixedClock::new(NOW_MS)));
        assert!(matches!(block_on(m.ensure()), EnsureOutcome::Failed { .. }));

        let http = MockHttp::new();
        mock_login(&http, &jwt(NOW_MS / 1000 + 10));
        let m = manager(&http, &MemoryKv::new(), Arc::new(FixedClock::new(NOW_MS)));
        assert_eq!(block_on(m.ensure()), EnsureOutcome::Ready);
    }

    #[test]
    fn delete_clears_storage_and_cache() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let m = manager(&http, &kv, Arc::new(FixedClock::new(NOW_MS)));
        block_on(m.save_session(&Session::new(jwt(NOW_MS / 1000 + 10), "rt"))).unwrap();
        block_on(m.invalidate()).unwrap();
        assert!(kv.is_empty());
        assert!(block_on(m.read_session()).unwrap().is_none());
    }

    /// Full 401 flow: API call -> 401 -> force refresh -> retry with new JWT.
    #[test]
    fn api_401_forces_refresh_and_retries() {
        let http = MockHttp::new();
        let kv = MemoryKv::new();
        let clock = Arc::new(FixedClock::new(NOW_MS));
        let old = jwt(NOW_MS / 1000 + 3600);
        let new = jwt(NOW_MS / 1000 + 7200);
        let m = Arc::new(manager(&http, &kv, clock));
        block_on(m.save_session(&Session::new(old.clone(), "rt-1"))).unwrap();
        http.on_json(HttpMethod::Post, "https://api.mooze.app/auth/refresh", 200, json!({"data": {"jwt": new}}));
        http.on_json(HttpMethod::Get, "https://api.mooze.app/users/me", 200, json!({"ok": 1}));
        http.once_json(HttpMethod::Get, "https://api.mooze.app/users/me", 401, json!({}));

        let api = MoozeApi::new(http.clone(), m.clone(), ApiConfig::default());
        let v: Value = block_on(api.get_json("/users/me")).unwrap();
        assert_eq!(v["ok"], 1);
        let reqs = http.requests();
        assert_eq!(reqs.len(), 3);
        assert_eq!(reqs[0].headers["Authorization"], format!("Bearer {old}"));
        assert_eq!(reqs[1].url, "https://api.mooze.app/auth/refresh");
        assert_eq!(reqs[2].headers["Authorization"], format!("Bearer {new}"));
        assert_eq!(block_on(stored(&kv)).0, Some(new));
    }
}
