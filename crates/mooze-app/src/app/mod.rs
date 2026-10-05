//! The application handle and its state.
//!
//! Port of the bridge `Inner` and `MoozeCore`. Every method is a plain
//! `async fn`; the host decides which executor polls it. Each wallet sits
//! behind its own async mutex, so calls on one wallet run one at a time.

mod wallets;

use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, RwLock};

use mooze_core::api::{ApiConfig, MoozeApi, SessionProvider, DEFAULT_BASE_URL};
use mooze_core::auth::{get_device_id, metrics_json, DeviceInfo, SessionManager};
use mooze_core::domain::{AppNetwork, ChainId};
use mooze_core::migration::{import_flutter_data, is_migrated, parse_snapshot};
use mooze_core::pix::rules::DepositPoll;
use mooze_core::ports::{KvStore, MaybeSend};
use mooze_core::store::CredentialStore;
#[cfg(feature = "electrum")]
use mooze_core::wallet::ElectrumConfig;
use mooze_core::wallet::{BitcoinWallet, ChainBackend, EndpointResolver, LiquidWallet};
use serde_json::Value;
use tokio::sync::Mutex;

use crate::dto::*;
use crate::{AppError, ErrorCode, Platform, Result};

pub(crate) type Bitcoin<P> = BitcoinWallet<<P as Platform>::Kv, <P as Platform>::Clock>;
pub(crate) type Liquid<P> = LiquidWallet<<P as Platform>::Kv, <P as Platform>::Clock>;
type Sessions<P> =
    SessionManager<<P as Platform>::Http, <P as Platform>::Secure, <P as Platform>::Clock>;
type Api<P> = MoozeApi<<P as Platform>::Http, SerializedSession<P>>;

/// State shared by every clone of one [`App`].
pub(crate) struct Inner<P: Platform> {
    pub(crate) platform: P,
    pub(crate) network: AppNetwork,
    pub(crate) backend: ChainBackend,
    pub(crate) endpoints: EndpointResolver,
    pub(crate) bitcoin: Mutex<Option<Bitcoin<P>>>,
    pub(crate) liquid: Mutex<Option<Liquid<P>>>,
    /// Session manager and API client. Built on first use, see [`auth`].
    auth: Mutex<Option<Arc<Auth<P>>>>,
    api_base_url: RwLock<String>,
    device_safe: AtomicBool,
    metrics: RwLock<Option<Value>>,
    /// PIX deposits being polled, see `pix_poll_tick`.
    #[allow(dead_code)] // read by the PIX methods
    pub(crate) pix_polls: std::sync::Mutex<Vec<DepositPoll>>,
}

impl<P: Platform> Inner<P> {
    pub(crate) fn api_base_url(&self) -> String {
        self.api_base_url
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .clone()
    }

    /// Drops the session manager. The next auth call builds a new one.
    async fn reset_auth(&self) {
        *self.auth.lock().await = None;
    }
}

/// Session provider that runs one token operation at a time.
///
/// `SessionManager` expects the platform to serialize its calls (the Dart
/// code coalesced them). Concurrent API requests therefore wait here for
/// the token, then send their requests in parallel.
pub(crate) struct SerializedSession<P: Platform> {
    pub(crate) manager: Arc<Sessions<P>>,
    pub(crate) lock: Arc<Mutex<()>>,
}

impl<P: Platform> Clone for SerializedSession<P> {
    fn clone(&self) -> Self {
        Self {
            manager: self.manager.clone(),
            lock: self.lock.clone(),
        }
    }
}

impl<P: Platform> SessionProvider for SerializedSession<P> {
    fn access_token(&self) -> impl Future<Output = mooze_core::Result<String>> + MaybeSend {
        let this = self.clone();
        async move {
            let _guard = this.lock.lock().await;
            this.manager.access_token().await
        }
    }

    fn force_refresh_token(&self) -> impl Future<Output = mooze_core::Result<String>> + MaybeSend {
        let this = self.clone();
        async move {
            let _guard = this.lock.lock().await;
            this.manager.force_refresh_token().await
        }
    }
}

/// Auth objects for one mnemonic and one base URL.
pub(crate) struct Auth<P: Platform> {
    pub(crate) session: SerializedSession<P>,
    pub(crate) api: Api<P>,
    /// False if the secure store held no mnemonic at build time.
    has_signer: bool,
}

/// Returns the auth objects, building them if needed.
///
/// The build reads the mnemonic from the secure store under
/// `mnemonic_mainWallet`. Without a mnemonic the objects are rebuilt on the
/// next call, so a wallet created later signs in without `auth_reset`.
pub(crate) async fn auth<P: Platform>(inner: &Inner<P>) -> Result<Arc<Auth<P>>> {
    let mut slot = inner.auth.lock().await;
    if let Some(auth) = slot.as_ref().filter(|a| a.has_signer) {
        return Ok(auth.clone());
    }
    let store = inner.platform.secure();
    let credentials = CredentialStore::new(store.clone(), inner.network)
        .load()
        .await?;
    let base_url = inner.api_base_url();
    let http = inner.platform.http();
    let manager = SessionManager::for_credentials(
        http.clone(),
        store,
        inner.platform.clock(),
        &base_url,
        &credentials,
    )?;
    let safe = inner.device_safe.load(Ordering::SeqCst);
    manager.set_device_safe(safe);
    let session = SerializedSession {
        manager: Arc::new(manager),
        lock: Arc::new(Mutex::new(())),
    };
    let api = MoozeApi::new(
        http,
        session.clone(),
        ApiConfig {
            base_url,
            timeout_ms: None,
        },
    );
    api.set_device_safe(safe);
    api.set_metrics(
        inner
            .metrics
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .clone(),
    );
    let auth = Arc::new(Auth {
        session,
        api,
        has_signer: !credentials.is_absent(),
    });
    *slot = Some(auth.clone());
    Ok(auth)
}

pub(crate) fn not_connected(chain: ChainId) -> AppError {
    AppError::invalid_state(format!("{} wallet not connected", chain.as_str()))
}

/// Handle to one opened application. Clones share the state.
pub struct App<P: Platform> {
    pub(crate) inner: Arc<Inner<P>>,
}

impl<P: Platform> Clone for App<P> {
    fn clone(&self) -> Self {
        Self {
            inner: self.inner.clone(),
        }
    }
}

impl<P: Platform> App<P> {
    /// Opens the application over `platform`.
    pub async fn open(config: AppConfig, platform: P) -> Result<App<P>> {
        let network: AppNetwork = config.network.into();
        let backend = match config.backend {
            BackendDto::Esplora => ChainBackend::Esplora,
            #[cfg(feature = "electrum")]
            BackendDto::Electrum => {
                let spawner = platform.blocking().ok_or_else(|| {
                    AppError::invalid_state("electrum backend needs a blocking spawner")
                })?;
                ChainBackend::Electrum(ElectrumConfig::new(spawner))
            }
            #[cfg(not(feature = "electrum"))]
            BackendDto::Electrum => {
                return Err(AppError::invalid_state("electrum backend not compiled in"))
            }
        };
        let endpoints = EndpointResolver::for_backend(network, &backend)
            .with_custom_node(ChainId::Bitcoin, &config.bitcoin_node_url)
            .with_custom_node(ChainId::Liquid, &config.liquid_node_url);
        let api_base_url = match config.api_base_url {
            Some(url) if !url.is_empty() => url,
            _ => DEFAULT_BASE_URL.to_owned(),
        };
        Ok(App {
            inner: Arc::new(Inner {
                platform,
                network,
                backend,
                endpoints,
                bitcoin: Mutex::new(None),
                liquid: Mutex::new(None),
                auth: Mutex::new(None),
                api_base_url: RwLock::new(api_base_url),
                device_safe: AtomicBool::new(true),
                metrics: RwLock::new(None),
                pix_polls: std::sync::Mutex::new(Vec::new()),
            }),
        })
    }

    // ───────────────────────────── one-time import

    /// True once the Flutter data import finished.
    pub async fn is_migrated(&self) -> Result<bool> {
        Ok(is_migrated(&self.inner.platform.kv()).await?)
    }

    /// Imports the snapshot from `FlutterDataExporter`, once.
    pub async fn import_flutter_snapshot(
        &self,
        snapshot_json: String,
    ) -> Result<MigrationReportDto> {
        let snapshot = parse_snapshot(snapshot_json.as_bytes())?;
        let report = import_flutter_data(
            &self.inner.platform.kv(),
            &self.inner.platform.clock(),
            &snapshot,
        )
        .await?;
        Ok(report.into())
    }

    // ───────────────────────────── secure storage

    /// Reads `key` from the secure store.
    pub async fn secure_get(&self, key: String) -> Result<Option<String>> {
        match self.inner.platform.secure().get(&key).await? {
            None => Ok(None),
            Some(bytes) => String::from_utf8(bytes).map(Some).map_err(|_| {
                AppError::new(
                    ErrorCode::Storage,
                    format!("secure value for {key} is not UTF-8"),
                )
            }),
        }
    }

    /// Writes `key` to the secure store.
    pub async fn secure_put(&self, key: String, value: String) -> Result<()> {
        Ok(self
            .inner
            .platform
            .secure()
            .put(&key, value.into_bytes())
            .await?)
    }

    /// Deletes `key` from the secure store.
    pub async fn secure_delete(&self, key: String) -> Result<()> {
        Ok(self.inner.platform.secure().delete(&key).await?)
    }

    /// Keys of the secure store that start with `prefix`, sorted.
    pub async fn secure_list_keys(&self, prefix: String) -> Result<Vec<String>> {
        Ok(self.inner.platform.secure().list_keys(&prefix).await?)
    }

    // ───────────────────────────── auth

    /// Sets the backend base URL. Empty restores the default. Drops the session manager.
    pub async fn api_set_base_url(&self, base_url: String) -> Result<()> {
        let url = if base_url.is_empty() {
            DEFAULT_BASE_URL.to_owned()
        } else {
            base_url
        };
        *self
            .inner
            .api_base_url
            .write()
            .unwrap_or_else(|e| e.into_inner()) = url;
        self.inner.reset_auth().await;
        Ok(())
    }

    /// Boot-time session check. Signs a login challenge with the stored
    /// mnemonic if needed and stores the tokens under `jwt` and `refresh_token`.
    pub async fn auth_ensure_session(&self) -> Result<AuthEnsureDto> {
        let auth = auth(&self.inner).await?;
        let _guard = auth.session.lock.lock().await;
        Ok(auth.session.manager.ensure().await.into())
    }

    /// A valid JWT: stored, refreshed or newly created.
    pub async fn auth_access_token(&self) -> Result<String> {
        Ok(auth(&self.inner).await?.session.access_token().await?)
    }

    /// Refreshes the session regardless of local expiry and returns the new JWT.
    pub async fn auth_force_refresh(&self) -> Result<String> {
        Ok(auth(&self.inner)
            .await?
            .session
            .force_refresh_token()
            .await?)
    }

    /// Manual refresh. Returns success.
    pub async fn auth_refresh_current(&self) -> Result<bool> {
        let auth = auth(&self.inner).await?;
        let _guard = auth.session.lock.lock().await;
        Ok(auth.session.manager.refresh_current().await)
    }

    /// Deletes the stored session.
    pub async fn auth_invalidate(&self) -> Result<()> {
        let auth = auth(&self.inner).await?;
        let _guard = auth.session.lock.lock().await;
        Ok(auth.session.manager.invalidate().await?)
    }

    /// Drops the session manager, so the next auth call reads the mnemonic
    /// again. Call it after the wallet mnemonic changes or is deleted.
    pub async fn auth_reset(&self) -> Result<()> {
        self.inner.reset_auth().await;
        Ok(())
    }

    /// Sets the device integrity result. Unsafe devices cannot sign in and
    /// send API requests without a token.
    pub async fn auth_set_device_safe(&self, safe: bool) -> Result<()> {
        self.inner.device_safe.store(safe, Ordering::SeqCst);
        if let Some(auth) = self.inner.auth.lock().await.as_ref() {
            auth.session.manager.set_device_safe(safe);
            auth.api.set_device_safe(safe);
        }
        Ok(())
    }

    /// The persisted device id, or a new one derived from `serial` or
    /// `platform_id`, else a random UUID.
    pub async fn auth_device_id(
        &self,
        serial: Option<String>,
        platform_id: Option<String>,
    ) -> Result<String> {
        Ok(get_device_id(
            &self.inner.platform.secure(),
            serial.as_deref(),
            platform_id.as_deref(),
        )
        .await)
    }

    /// Sets the metrics the API client adds to JSON request bodies.
    /// `None` stops adding them.
    pub async fn api_set_metrics(&self, metrics: Option<DeviceMetricsDto>) -> Result<()> {
        let value = metrics.map(|m| {
            let info = DeviceInfo {
                battery_level: m.battery_level,
                screen_brightness: m.screen_brightness,
                boot_time: m.boot_time,
            };
            metrics_json(&m.device_id, &info)
        });
        *self
            .inner
            .metrics
            .write()
            .unwrap_or_else(|e| e.into_inner()) = value.clone();
        if let Some(auth) = self.inner.auth.lock().await.as_ref() {
            auth.api.set_metrics(value);
        }
        Ok(())
    }

    /// Sends one request to the Mooze backend with the session.
    ///
    /// Attaches `Authorization: Bearer <jwt>` except on `/auth/*` paths. On
    /// 401 or 403 it refreshes the session once and retries once. Returns
    /// non-2xx statuses; fails with `Session` if the refresh fails.
    /// `json_body` must be JSON text.
    pub async fn api_request(
        &self,
        method: HttpMethodDto,
        path: String,
        json_body: Option<String>,
    ) -> Result<ApiResponseDto> {
        let body = match json_body {
            None => None,
            Some(text) => Some(
                serde_json::from_str::<Value>(&text)
                    .map_err(|e| AppError::invalid_input(format!("json_body is not JSON: {e}")))?,
            ),
        };
        let auth = auth(&self.inner).await?;
        let response = auth.api.send(method.into(), &path, body).await?;
        Ok(ApiResponseDto {
            status: response.status,
            body: response.text(),
        })
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::testing::{open_test_app, ABANDON, JWT_1, JWT_2};
    use crate::ErrorCode;
    use mooze_core::ports::HttpMethod;
    use mooze_core::testing::block_on;
    use serde_json::json;

    #[test]
    fn no_mnemonic_reports_missing_then_signs_in_once_one_exists() {
        let (app, plat) = open_test_app();
        let out = block_on(app.auth_ensure_session()).unwrap();
        assert_eq!(out.kind, AuthEnsureKind::MissingMnemonic);
        assert_eq!(
            block_on(app.auth_access_token()).unwrap_err().code,
            ErrorCode::Session
        );
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        plat.secure_insert("jwt", JWT_1);
        plat.secure_insert("refresh_token", "rt");
        assert_eq!(block_on(app.auth_access_token()).unwrap(), JWT_1);
    }

    #[test]
    fn rejects_non_json_body() {
        let (app, _plat) = open_test_app();
        let err = block_on(app.api_request(HttpMethodDto::Post, "/x".into(), Some("{nope".into())))
            .unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidInput);
    }

    #[test]
    fn sign_in_then_api_request_refreshes_on_401() {
        let (app, plat) = open_test_app();
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        let base = "https://api.test";
        plat.http.on_json(
            HttpMethod::Post,
            &format!("{base}/auth/challenge"),
            200,
            json!({"data": {"id": "ch-1", "message": "SGVsbG8gV29ybGQ="}}),
        );
        plat.http.on_json(
            HttpMethod::Post,
            &format!("{base}/auth/sign"),
            200,
            json!({"data": {"jwt": JWT_1, "refresh_token": "rt-1"}}),
        );
        plat.http.on_json(
            HttpMethod::Post,
            &format!("{base}/auth/refresh"),
            200,
            json!({"data": {"jwt": JWT_2}}),
        );
        // Later routes win in MockHttp: the once-401 goes last so it fires first.
        plat.http.on_json(
            HttpMethod::Get,
            &format!("{base}/users/me"),
            200,
            json!({"id": "u2"}),
        );
        plat.http.once_json(
            HttpMethod::Get,
            &format!("{base}/users/me"),
            401,
            json!({"error": "expired"}),
        );

        block_on(app.api_set_base_url(base.into())).unwrap();
        block_on(app.api_set_metrics(Some(DeviceMetricsDto {
            device_id: "dev-1".into(),
            battery_level: Some(80),
            screen_brightness: None,
            boot_time: None,
        })))
        .unwrap();

        let out = block_on(app.auth_ensure_session()).unwrap();
        assert_eq!(out.kind, AuthEnsureKind::Ready, "{out:?}");
        assert_eq!(plat.secure_get("jwt").as_deref(), Some(JWT_1));
        assert_eq!(plat.secure_get("refresh_token").as_deref(), Some("rt-1"));

        let resp = block_on(app.api_request(HttpMethodDto::Get, "/users/me".into(), None)).unwrap();
        assert_eq!((resp.status, resp.body.as_str()), (200, r#"{"id":"u2"}"#));
        assert_eq!(plat.secure_get("jwt").as_deref(), Some(JWT_2));

        let reqs = plat.http.requests();
        let paths: Vec<String> = reqs
            .iter()
            .map(|r| r.url.trim_start_matches(base).to_owned())
            .collect();
        assert_eq!(
            paths,
            vec![
                "/auth/challenge",
                "/auth/sign",
                "/users/me",
                "/auth/refresh",
                "/users/me"
            ]
        );
        assert!(!reqs[0].headers.contains_key("Authorization"));
        assert_eq!(
            reqs[2].headers.get("Authorization").map(String::as_str),
            Some(format!("Bearer {JWT_1}").as_str())
        );

        block_on(app.auth_invalidate()).unwrap();
        assert!(plat.secure_get("jwt").is_none());
    }

    #[test]
    fn unsafe_device_cannot_sign_in() {
        let (app, plat) = open_test_app();
        plat.secure_insert("mnemonic_mainWallet", ABANDON);
        block_on(app.auth_set_device_safe(false)).unwrap();
        let err = block_on(app.auth_access_token()).unwrap_err();
        assert_eq!(err.code, ErrorCode::Session);
        assert!(err.message.contains("Unsafe device"), "{}", err.message);
    }

    #[test]
    fn secure_round_trip_and_device_id() {
        let (app, plat) = open_test_app();
        plat.secure_insert("from_host", "ç value");
        assert_eq!(
            block_on(app.secure_get("from_host".into()))
                .unwrap()
                .as_deref(),
            Some("ç value")
        );
        block_on(app.secure_put("from_core".into(), "v".into())).unwrap();
        assert_eq!(plat.secure_get("from_core").as_deref(), Some("v"));
        assert_eq!(
            block_on(app.secure_list_keys("from_".into())).unwrap(),
            vec!["from_core", "from_host"]
        );
        block_on(app.secure_delete("from_core".into())).unwrap();
        assert!(plat.secure_get("from_core").is_none());
        let id = block_on(app.auth_device_id(Some("SERIAL".into()), None)).unwrap();
        assert_eq!(id, mooze_core::auth::hash_device_id("SERIAL"));
    }
}
