//! The core handle Dart holds, and the calls behind the Dart wallet services.
//!
//! Every call runs on the shared tokio runtime (see [`crate::ports`]),
//! because reqwest and the Electrum spawner need a tokio context. Each
//! wallet sits behind its own async mutex, so calls on one wallet run one at
//! a time, as the Dart services expect.

use std::future::Future;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, RwLock};

use flutter_rust_bridge::{frb, DartFnFuture};
use mooze_core::api::{ApiConfig, MoozeApi, SessionProvider, DEFAULT_BASE_URL};
use mooze_core::auth::{get_device_id, metrics_json, DeviceInfo, SessionManager};
use mooze_core::domain::{AppNetwork, ChainId, WalletCredentials};
use mooze_core::migration::{import_flutter_data, is_migrated, parse_snapshot};
use mooze_core::ports::{KvStore, MaybeSend, ReqwestHttpClient};
use mooze_core::store::CredentialStore;
use mooze_core::wallet::{BitcoinWallet, ChainBackend, ElectrumConfig, EndpointResolver, LiquidWallet};
use serde_json::Value;
use tokio::sync::Mutex;

use mooze_core::pix::rules::DepositPoll;

use super::types::*;
use crate::glue::SideSwapState;
use crate::ports::{install_crypto_provider, on_runtime, FileKv, SystemClock, TokioSpawner};
use crate::secure_store::DartSecureStore;

/// Subdirectory of `data_dir` that holds the key-value files.
const KV_DIR: &str = "core_kv";

pub(crate) type Bitcoin = BitcoinWallet<FileKv, SystemClock>;
pub(crate) type Liquid = LiquidWallet<FileKv, SystemClock>;
type Sessions = SessionManager<ReqwestHttpClient, DartSecureStore, SystemClock>;
type Api = MoozeApi<ReqwestHttpClient, SerializedSession>;

pub(crate) struct Inner {
    pub(crate) kv: FileKv,
    pub(crate) network: AppNetwork,
    backend: ChainBackend,
    endpoints: EndpointResolver,
    pub(crate) bitcoin: Mutex<Option<Bitcoin>>,
    pub(crate) liquid: Mutex<Option<Liquid>>,
    /// Dart secure-storage callbacks. `None` until Dart registers them.
    secure: RwLock<Option<DartSecureStore>>,
    /// Session manager and API client. Built on first use, see [`auth`].
    auth: Mutex<Option<Arc<Auth>>>,
    api_base_url: RwLock<String>,
    device_safe: AtomicBool,
    metrics: RwLock<Option<Value>>,
    /// PIX deposits being polled, see `pixPollTick`.
    pub(crate) pix_polls: std::sync::Mutex<Vec<DepositPoll>>,
    /// SideSwap client, peg tracker and event driver.
    pub(crate) sideswap: Arc<SideSwapState>,
}

impl Drop for Inner {
    fn drop(&mut self) {
        // The driver task holds only the SideSwap state. Stop it with the core.
        self.sideswap.stop_driver();
    }
}

impl Inner {
    pub(crate) fn api_base_url(&self) -> String {
        self.api_base_url.read().unwrap_or_else(|e| e.into_inner()).clone()
    }

    pub(crate) fn secure_store(&self) -> mooze_core::Result<DartSecureStore> {
        self.secure
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .clone()
            .ok_or_else(|| mooze_core::Error::InvalidState("secure storage not set; call setSecureStorage first".into()))
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
#[derive(Clone)]
pub(crate) struct SerializedSession {
    manager: Arc<Sessions>,
    lock: Arc<Mutex<()>>,
}

impl SessionProvider for SerializedSession {
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
pub(crate) struct Auth {
    pub(crate) session: SerializedSession,
    api: Api,
    /// False if the secure store held no mnemonic at build time.
    has_signer: bool,
}

/// Returns the auth objects, building them if needed.
///
/// The build reads the mnemonic from the secure store under
/// `mnemonic_mainWallet`. Without a mnemonic the objects are rebuilt on the
/// next call, so a wallet created later signs in without `authReset`.
pub(crate) async fn auth(inner: &Inner) -> mooze_core::Result<Arc<Auth>> {
    let mut slot = inner.auth.lock().await;
    if let Some(auth) = slot.as_ref().filter(|a| a.has_signer) {
        return Ok(auth.clone());
    }
    let store = inner.secure_store()?;
    let credentials = CredentialStore::new(store.clone(), inner.network).load().await?;
    let base_url = inner.api_base_url.read().unwrap_or_else(|e| e.into_inner()).clone();
    let http = ReqwestHttpClient::default();
    let manager = SessionManager::for_credentials(http.clone(), store, SystemClock, &base_url, &credentials)?;
    let safe = inner.device_safe.load(Ordering::SeqCst);
    manager.set_device_safe(safe);
    let session = SerializedSession { manager: Arc::new(manager), lock: Arc::new(Mutex::new(())) };
    let api = MoozeApi::new(http, session.clone(), ApiConfig { base_url, timeout_ms: None });
    api.set_device_safe(safe);
    api.set_metrics(inner.metrics.read().unwrap_or_else(|e| e.into_inner()).clone());
    let auth = Arc::new(Auth { session, api, has_signer: !credentials.is_absent() });
    *slot = Some(auth.clone());
    Ok(auth)
}

fn not_connected(chain: ChainId) -> CoreError {
    CoreError { kind: CoreErrorKind::InvalidState, message: format!("{} wallet not connected", chain.as_str()) }
}

/// Handle to one opened core. Dart keeps one for the app's lifetime.
#[frb(opaque)]
pub struct MoozeCore {
    pub(crate) inner: Arc<Inner>,
}

impl MoozeCore {
    /// Opens the core in `config.data_dir`.
    ///
    /// Also installs ring as the rustls crypto provider of the process,
    /// before any TLS use. Opening more than once is safe.
    pub async fn open(config: CoreConfig) -> Result<MoozeCore, CoreError> {
        install_crypto_provider();
        let kv = FileKv::open(PathBuf::from(&config.data_dir).join(KV_DIR))?;
        let network: AppNetwork = config.network.into();
        let backend = match config.backend {
            BackendDto::Esplora => ChainBackend::Esplora,
            BackendDto::Electrum => ChainBackend::Electrum(ElectrumConfig::new(Arc::new(TokioSpawner))),
        };
        let endpoints = EndpointResolver::for_backend(network, &backend)
            .with_custom_node(ChainId::Bitcoin, &config.bitcoin_node_url)
            .with_custom_node(ChainId::Liquid, &config.liquid_node_url);
        Ok(MoozeCore {
            inner: Arc::new(Inner {
                kv,
                network,
                backend,
                endpoints,
                bitcoin: Mutex::new(None),
                liquid: Mutex::new(None),
                secure: RwLock::new(None),
                auth: Mutex::new(None),
                api_base_url: RwLock::new(DEFAULT_BASE_URL.to_owned()),
                device_safe: AtomicBool::new(true),
                metrics: RwLock::new(None),
                pix_polls: std::sync::Mutex::new(Vec::new()),
                sideswap: Arc::new(SideSwapState::default()),
            }),
        })
    }

    // ───────────────────────────── one-time import

    /// True once the Flutter data import finished.
    pub async fn is_migrated(&self) -> Result<bool, CoreError> {
        let kv = self.inner.kv.clone();
        Ok(on_runtime(async move { is_migrated(&kv).await }).await?)
    }

    /// Imports the snapshot from `FlutterDataExporter`, once.
    pub async fn import_flutter_snapshot(&self, snapshot_json: String) -> Result<MigrationReportDto, CoreError> {
        let kv = self.inner.kv.clone();
        let report = on_runtime(async move {
            let snapshot = parse_snapshot(snapshot_json.as_bytes())?;
            import_flutter_data(&kv, &SystemClock, &snapshot).await
        })
        .await?;
        Ok(report.into())
    }

    // ───────────────────────────── secure storage

    /// Registers the Dart secure-storage callbacks (`flutter_secure_storage`).
    ///
    /// - `read(key)`: the value, or `null` if absent.
    /// - `write(key, value)`: stores the value.
    /// - `delete(key)`: removes the value. Absent keys are not an error.
    /// - `listKeys(prefix)`: keys that start with `prefix` (filter `readAll()`).
    ///
    /// Call it once after `open`, before any auth or `secure*` call.
    /// A second call replaces the callbacks and drops the session manager.
    pub async fn set_secure_storage(
        &self,
        read: impl Fn(String) -> DartFnFuture<Option<String>> + Send + Sync + 'static,
        write: impl Fn(String, String) -> DartFnFuture<()> + Send + Sync + 'static,
        delete: impl Fn(String) -> DartFnFuture<()> + Send + Sync + 'static,
        list_keys: impl Fn(String) -> DartFnFuture<Vec<String>> + Send + Sync + 'static,
    ) {
        let store = DartSecureStore::new(read, write, delete, list_keys);
        *self.inner.secure.write().unwrap_or_else(|e| e.into_inner()) = Some(store);
        self.inner.reset_auth().await;
    }

    /// Reads `key` from the secure store, through the Dart callbacks.
    pub async fn secure_get(&self, key: String) -> Result<Option<String>, CoreError> {
        let store = self.inner.secure_store()?;
        Ok(on_runtime(async move {
            match store.get(&key).await? {
                None => Ok(None),
                Some(bytes) => crate::secure_store::value_to_string(&key, bytes).map(Some),
            }
        })
        .await?)
    }

    /// Writes `key` to the secure store, through the Dart callbacks.
    pub async fn secure_put(&self, key: String, value: String) -> Result<(), CoreError> {
        let store = self.inner.secure_store()?;
        Ok(on_runtime(async move { store.put(&key, value.into_bytes()).await }).await?)
    }

    /// Deletes `key` from the secure store, through the Dart callbacks.
    pub async fn secure_delete(&self, key: String) -> Result<(), CoreError> {
        let store = self.inner.secure_store()?;
        Ok(on_runtime(async move { store.delete(&key).await }).await?)
    }

    /// Keys of the secure store that start with `prefix`, sorted.
    pub async fn secure_list_keys(&self, prefix: String) -> Result<Vec<String>, CoreError> {
        let store = self.inner.secure_store()?;
        Ok(on_runtime(async move { store.list_keys(&prefix).await }).await?)
    }

    // ───────────────────────────── auth

    /// Sets the backend base URL (Dart `BACKEND_API_URL`). Default
    /// `https://api.mooze.app`. Drops the session manager.
    pub async fn api_set_base_url(&self, base_url: String) {
        let url = if base_url.is_empty() { DEFAULT_BASE_URL.to_owned() } else { base_url };
        *self.inner.api_base_url.write().unwrap_or_else(|e| e.into_inner()) = url;
        self.inner.reset_auth().await;
    }

    /// Boot-time session check (Dart `ensureAuthSessionProvider`). Signs a
    /// login challenge with the stored mnemonic if needed and stores the
    /// tokens under `jwt` and `refresh_token`.
    pub async fn auth_ensure_session(&self) -> Result<AuthEnsureDto, CoreError> {
        let inner = self.inner.clone();
        let outcome = on_runtime(async move {
            let auth = auth(&inner).await?;
            let _guard = auth.session.lock.lock().await;
            Ok(auth.session.manager.ensure().await)
        })
        .await?;
        Ok(outcome.into())
    }

    /// A valid JWT: stored, refreshed or newly created
    /// (Dart `SessionManagerService.getSession`).
    pub async fn auth_access_token(&self) -> Result<String, CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move { auth(&inner).await?.session.access_token().await }).await?)
    }

    /// Refreshes the session regardless of local expiry and returns the new
    /// JWT (Dart `SessionManagerService.forceRefresh`).
    pub async fn auth_force_refresh(&self) -> Result<String, CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move { auth(&inner).await?.session.force_refresh_token().await }).await?)
    }

    /// Manual refresh (Dart `refreshAuthSessionProvider`). Returns success.
    pub async fn auth_refresh_current(&self) -> Result<bool, CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move {
            let auth = auth(&inner).await?;
            let _guard = auth.session.lock.lock().await;
            Ok(auth.session.manager.refresh_current().await)
        })
        .await?)
    }

    /// Deletes the stored session (Dart `SessionAuthenticator.invalidate`).
    pub async fn auth_invalidate(&self) -> Result<(), CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move {
            let auth = auth(&inner).await?;
            let _guard = auth.session.lock.lock().await;
            auth.session.manager.invalidate().await
        })
        .await?)
    }

    /// Drops the session manager, so the next auth call reads the mnemonic
    /// again. Call it after the wallet mnemonic changes or is deleted.
    pub async fn auth_reset(&self) {
        self.inner.reset_auth().await;
    }

    /// Sets the device integrity result (Dart `SafeDevice.isSafeDevice`).
    /// Unsafe devices cannot sign in and send API requests without a token.
    pub async fn auth_set_device_safe(&self, safe: bool) {
        self.inner.device_safe.store(safe, Ordering::SeqCst);
        if let Some(auth) = self.inner.auth.lock().await.as_ref() {
            auth.session.manager.set_device_safe(safe);
            auth.api.set_device_safe(safe);
        }
    }

    /// The persisted device id, or a new one derived from `serial`
    /// (`UniqueIdentifier.serial`) or `platform_id` (Android id or iOS
    /// identifierForVendor), else a random UUID (Dart `DeviceIdService`).
    pub async fn auth_device_id(&self, serial: Option<String>, platform_id: Option<String>) -> Result<String, CoreError> {
        let store = self.inner.secure_store()?;
        Ok(on_runtime(async move { Ok(get_device_id(&store, serial.as_deref(), platform_id.as_deref()).await) }).await?)
    }

    /// Sets the metrics the API client adds to JSON request bodies.
    /// `None` stops adding them.
    pub async fn api_set_metrics(&self, metrics: Option<DeviceMetricsDto>) {
        let value = metrics.map(|m| {
            let info = DeviceInfo {
                battery_level: m.battery_level,
                screen_brightness: m.screen_brightness,
                boot_time: m.boot_time,
            };
            metrics_json(&m.device_id, &info)
        });
        *self.inner.metrics.write().unwrap_or_else(|e| e.into_inner()) = value.clone();
        if let Some(auth) = self.inner.auth.lock().await.as_ref() {
            auth.api.set_metrics(value);
        }
    }

    /// Sends one request to the Mooze backend with the session
    /// (Dart authenticated Dio client).
    ///
    /// Attaches `Authorization: Bearer <jwt>` except on `/auth/*` paths. On
    /// 401 or 403 it refreshes the session once and retries once. Returns
    /// non-2xx statuses; throws `CoreErrorKind.session` if the refresh fails.
    /// `json_body` must be JSON text.
    pub async fn api_request(
        &self,
        method: HttpMethodDto,
        path: String,
        json_body: Option<String>,
    ) -> Result<ApiResponseDto, CoreError> {
        let body = match json_body {
            None => None,
            Some(text) => Some(serde_json::from_str::<Value>(&text).map_err(|e| CoreError {
                kind: CoreErrorKind::InvalidInput,
                message: format!("json_body is not JSON: {e}"),
            })?),
        };
        let inner = self.inner.clone();
        let response = on_runtime(async move {
            let auth = auth(&inner).await?;
            auth.api.send(method.into(), &path, body).await
        })
        .await?;
        Ok(ApiResponseDto { status: response.status, body: response.text() })
    }

    // ───────────────────────────── bitcoin

    /// Loads or creates the Bitcoin wallet for `mnemonic`.
    pub async fn bitcoin_connect(&self, mnemonic: String) -> Result<(), CoreError> {
        let inner = self.inner.clone();
        on_runtime(async move {
            let creds = WalletCredentials { mnemonic, network: inner.network };
            let mut wallet = BitcoinWallet::connect(&creds, inner.kv.clone(), SystemClock, inner.endpoints.clone()).await?;
            if inner.backend.is_electrum() {
                wallet.set_backend(inner.backend.clone(), inner.endpoints.clone())?;
            }
            *inner.bitcoin.lock().await = Some(wallet);
            Ok(())
        })
        .await?;
        Ok(())
    }

    /// Drops the Bitcoin wallet. Idempotent.
    pub async fn bitcoin_disconnect(&self) {
        *self.inner.bitcoin.lock().await = None;
    }

    /// Syncs the Bitcoin wallet.
    pub async fn bitcoin_sync(&self) -> Result<SyncOutcomeDto, CoreError> {
        let inner = self.inner.clone();
        let outcome = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.sync().await
        })
        .await?;
        Ok((&outcome).into())
    }

    /// Bitcoin balance from local state.
    pub async fn bitcoin_balance(&self) -> Result<BalanceDto, CoreError> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.balance().into())
    }

    /// Bitcoin transactions from local state, newest first.
    pub async fn bitcoin_transactions(&self) -> Result<Vec<TransactionDto>, CoreError> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.list_transactions().iter().map(Into::into).collect())
    }

    /// Transaction changes since the last call.
    pub async fn bitcoin_take_events(&self) -> Result<Vec<TransactionEventDto>, CoreError> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.take_events().iter().map(Into::into).collect())
    }

    /// Next unused receive address.
    pub async fn bitcoin_receive_address(&self, label: Option<String>) -> Result<ReceiveAddressDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.next_receive_address(None, label.as_deref()).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Fee estimate for a send.
    pub async fn bitcoin_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto, CoreError> {
        let inner = self.inner.clone();
        let f = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.estimate_fee(&mooze_app::convert::send_request(&request, ChainId::Bitcoin)).await
        })
        .await?;
        Ok((&f).into())
    }

    /// Builds, signs and broadcasts a send.
    pub async fn bitcoin_send(&self, request: SendRequestDto) -> Result<BroadcastResultDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.send_onchain(&mooze_app::convert::send_request(&request, ChainId::Bitcoin)).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Chain tip height.
    pub async fn bitcoin_block_height(&self) -> Result<u32, CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.block_height().await
        })
        .await?)
    }

    /// Addresses of `keychain` at `start..start + count`. Reveals nothing.
    pub async fn bitcoin_derived_addresses(
        &self,
        keychain: KeychainDto,
        start: u32,
        count: u32,
    ) -> Result<Vec<DerivedAddressDto>, CoreError> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.derived_addresses(keychain.into(), start, count).iter().map(Into::into).collect())
    }

    /// Unspent outputs with address, derivation and confirmation.
    pub async fn bitcoin_unspent_outputs(&self) -> Result<Vec<WalletUtxoDto>, CoreError> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.unspent_outputs().iter().map(Into::into).collect())
    }

    /// Derivation of `address` if the wallet owns it. Throws
    /// `CoreErrorKind.invalidInput` for an address it cannot parse.
    pub async fn bitcoin_is_mine(&self, address: String) -> Result<Option<AddressOwnershipDto>, CoreError> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.is_mine(&address)?.map(Into::into))
    }

    /// Next receive address with no history. Reveals up to it and persists.
    pub async fn bitcoin_next_unused_address(&self) -> Result<NextUnusedAddressDto, CoreError> {
        let inner = self.inner.clone();
        let n = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.next_unused_address().await
        })
        .await?;
        Ok((&n).into())
    }

    /// Adds a transaction broadcast elsewhere, for example a peg-in funding.
    pub async fn bitcoin_register_external_broadcast(&self, transaction: TransactionDto) -> Result<(), CoreError> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        w.register_external_broadcast((&transaction).into());
        Ok(())
    }

    // ───────────────────────────── liquid

    /// Loads or creates the Liquid wallet for `mnemonic`.
    pub async fn liquid_connect(&self, mnemonic: String) -> Result<(), CoreError> {
        let inner = self.inner.clone();
        on_runtime(async move {
            let creds = WalletCredentials { mnemonic, network: inner.network };
            let mut wallet = LiquidWallet::connect(&creds, inner.kv.clone(), SystemClock, inner.endpoints.clone()).await?;
            if inner.backend.is_electrum() {
                wallet.set_backend(inner.backend.clone(), inner.endpoints.clone())?;
            }
            *inner.liquid.lock().await = Some(wallet);
            Ok(())
        })
        .await?;
        Ok(())
    }

    /// Drops the Liquid wallet. Idempotent.
    pub async fn liquid_disconnect(&self) {
        *self.inner.liquid.lock().await = None;
    }

    /// Syncs the Liquid wallet.
    pub async fn liquid_sync(&self) -> Result<SyncOutcomeDto, CoreError> {
        let inner = self.inner.clone();
        let outcome = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.sync().await
        })
        .await?;
        Ok((&outcome).into())
    }

    /// Liquid balance from local state.
    pub async fn liquid_balance(&self) -> Result<BalanceDto, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.balance().into())
    }

    /// Re-reads balances from the local wallet, no network.
    pub async fn liquid_refresh_balance(&self) -> Result<BalanceDto, CoreError> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.refresh_balance()?.into())
    }

    /// Applies known per-asset deltas to the cached balance.
    pub async fn liquid_apply_balance_delta(&self, asset_ids: Vec<String>, deltas: Vec<i64>) -> Result<BalanceDto, CoreError> {
        if asset_ids.len() != deltas.len() {
            return Err(CoreError {
                kind: CoreErrorKind::InvalidInput,
                message: "asset_ids and deltas differ in length".into(),
            });
        }
        let pairs: Vec<(String, i64)> = asset_ids.into_iter().zip(deltas).collect();
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.apply_optimistic_balance_delta(&pairs).into())
    }

    /// Liquid transactions from local state, newest first.
    pub async fn liquid_transactions(&self) -> Result<Vec<TransactionDto>, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.list_transactions().iter().map(Into::into).collect())
    }

    /// Transaction changes since the last call.
    pub async fn liquid_take_events(&self) -> Result<Vec<TransactionEventDto>, CoreError> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.take_events().iter().map(Into::into).collect())
    }

    /// Receive address, optionally for one asset.
    pub async fn liquid_receive_address(
        &self,
        asset_id: Option<String>,
        label: Option<String>,
    ) -> Result<ReceiveAddressDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.next_receive_address(asset_id.as_deref(), label.as_deref()).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Addresses of `keychain` at `start..start + count`. Reveals nothing.
    pub async fn liquid_derived_addresses(
        &self,
        keychain: KeychainDto,
        start: u32,
        count: u32,
    ) -> Result<Vec<DerivedAddressDto>, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.derived_addresses(keychain.into(), start, count)?.iter().map(Into::into).collect())
    }

    /// Unspent outputs with address, derivation, asset and confirmation.
    pub async fn liquid_unspent_outputs(&self) -> Result<Vec<WalletUtxoDto>, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.unspent_outputs()?.iter().map(Into::into).collect())
    }

    /// Derivation of `address` among the first `scan_limit` addresses of
    /// each chain. Throws `CoreErrorKind.invalidInput` for an address it
    /// cannot parse.
    pub async fn liquid_is_mine(
        &self,
        address: String,
        scan_limit: u32,
    ) -> Result<Option<AddressOwnershipDto>, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.is_mine(&address, scan_limit)?.map(Into::into))
    }

    /// LWK's last unused receive address, with a history check.
    pub async fn liquid_next_unused_address(&self) -> Result<NextUnusedAddressDto, CoreError> {
        let inner = self.inner.clone();
        let n = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.next_unused_address().await
        })
        .await?;
        Ok((&n).into())
    }

    /// Unblinded UTXOs, for SideSwap.
    pub async fn liquid_utxos(&self) -> Result<Vec<LiquidUtxoDto>, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.utxos()?.iter().map(Into::into).collect())
    }

    /// Fee estimate for a send.
    pub async fn liquid_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto, CoreError> {
        let inner = self.inner.clone();
        let f = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.estimate_fee(&mooze_app::convert::send_request(&request, ChainId::Liquid)).await
        })
        .await?;
        Ok((&f).into())
    }

    /// Builds an unsigned L-BTC send. A drain sends the whole L-BTC balance.
    pub async fn liquid_build_lbtc_send(
        &self,
        destination: String,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> Result<LiquidSendDraftDto, CoreError> {
        let inner = self.inner.clone();
        let d = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.build_lbtc_send(&destination, amount_sat, fee_rate_sat_per_vb, drain).await
        })
        .await?;
        Ok((&d).into())
    }

    /// Builds, signs and broadcasts a send.
    pub async fn liquid_send(&self, request: SendRequestDto, mnemonic: String) -> Result<BroadcastResultDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.send_onchain(&mooze_app::convert::send_request(&request, ChainId::Liquid), &mnemonic).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Signs a PSET with `mnemonic` and broadcasts it. Returns the txid.
    pub async fn liquid_sign_and_broadcast(&self, pset: String, mnemonic: String) -> Result<String, CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.sign_and_broadcast_pset(&pset, &mnemonic).await
        })
        .await?)
    }

    /// Signs a SideSwap swap PSET. Returns the signed PSET.
    pub async fn liquid_sign_swap_pset(&self, pset: String, mnemonic: String) -> Result<String, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.sign_swap_pset(&pset, &mnemonic)?)
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::ports::runtime;
    use crate::secure_store::tests::memory_store;
    use std::collections::BTreeMap;
    use std::sync::Mutex as StdMutex;
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use tokio::net::TcpListener;

    pub(crate) const ABANDON: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    /// Unsigned JWTs that expire in 2100.
    pub(crate) const JWT_1: &str = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUxIn0.sig";
    const JWT_2: &str = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUyIn0.sig";

    pub(crate) fn open_core(name: &str) -> MoozeCore {
        let dir = std::env::temp_dir().join(format!("mooze-ffi-core-{name}-{}", std::process::id()));
        let config = CoreConfig {
            data_dir: dir.to_string_lossy().into_owned(),
            network: NetworkDto::Mainnet,
            backend: BackendDto::Esplora,
            bitcoin_node_url: String::new(),
            liquid_node_url: String::new(),
        };
        runtime().block_on(MoozeCore::open(config)).unwrap()
    }

    /// Registers the in-memory store as the Dart callbacks would.
    pub(crate) fn with_memory_store(core: &MoozeCore) -> Arc<StdMutex<BTreeMap<String, String>>> {
        let (store, map) = memory_store();
        let (r, w, d, l) = (store.clone(), store.clone(), store.clone(), store);
        runtime().block_on(core.set_secure_storage(
            move |k| {
                let s = r.clone();
                Box::pin(async move { s.get(&k).await.unwrap().map(|b| String::from_utf8(b).unwrap()) })
            },
            move |k, v| {
                let s = w.clone();
                Box::pin(async move { s.put(&k, v.into_bytes()).await.unwrap() })
            },
            move |k| {
                let s = d.clone();
                Box::pin(async move { s.delete(&k).await.unwrap() })
            },
            move |p| {
                let s = l.clone();
                Box::pin(async move { s.list_keys(&p).await.unwrap() })
            },
        ));
        map
    }

    #[test]
    fn opening_twice_installs_ring_once_without_panic() {
        let _a = open_core("twice-a");
        let _b = open_core("twice-b");
        assert!(rustls::crypto::CryptoProvider::get_default().is_some());
    }

    #[test]
    fn secure_calls_need_callbacks() {
        let core = open_core("no-store");
        let err = runtime().block_on(core.secure_get("jwt".into())).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::InvalidState);
        let err = runtime().block_on(core.auth_access_token()).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::InvalidState);
    }

    #[test]
    fn secure_round_trip_and_device_id() {
        let core = open_core("secure");
        let map = with_memory_store(&core);
        map.lock().unwrap().insert("from_dart".into(), "ç value".into());
        assert_eq!(runtime().block_on(core.secure_get("from_dart".into())).unwrap().as_deref(), Some("ç value"));
        runtime().block_on(core.secure_put("from_core".into(), "v".into())).unwrap();
        assert_eq!(map.lock().unwrap().get("from_core").map(String::as_str), Some("v"));
        assert_eq!(runtime().block_on(core.secure_list_keys("from_".into())).unwrap(), vec!["from_core", "from_dart"]);
        runtime().block_on(core.secure_delete("from_core".into())).unwrap();
        assert!(!map.lock().unwrap().contains_key("from_core"));

        let id = runtime().block_on(core.auth_device_id(Some("SERIAL".into()), None)).unwrap();
        assert_eq!(id, mooze_core::auth::hash_device_id("SERIAL"));
        assert_eq!(map.lock().unwrap().get("device_id"), Some(&id));
    }

    #[test]
    fn no_mnemonic_reports_missing_then_signs_in_once_one_exists() {
        let core = open_core("missing");
        let map = with_memory_store(&core);
        let out = runtime().block_on(core.auth_ensure_session()).unwrap();
        assert_eq!(out.kind, AuthEnsureKind::MissingMnemonic);
        let err = runtime().block_on(core.auth_access_token()).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::Session);
        // A stored, fresh session is enough once the mnemonic exists: no network.
        map.lock().unwrap().insert("mnemonic_mainWallet".into(), ABANDON.into());
        map.lock().unwrap().insert("jwt".into(), JWT_1.into());
        map.lock().unwrap().insert("refresh_token".into(), "rt".into());
        assert_eq!(runtime().block_on(core.auth_access_token()).unwrap(), JWT_1);
    }

    #[test]
    fn rejects_non_json_body() {
        let core = open_core("badjson");
        with_memory_store(&core);
        let err =
            runtime().block_on(core.api_request(HttpMethodDto::Post, "/x".into(), Some("{nope".into()))).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::InvalidInput);
    }

    /// One request the mock server saw.
    #[derive(Debug, Clone)]
    struct Seen {
        method: String,
        path: String,
        authorization: Option<String>,
        body: String,
    }

    /// Minimal HTTP/1.1 backend on 127.0.0.1. One request per connection.
    ///
    /// `/auth/challenge` and `/auth/sign` log in with `JWT_1`;
    /// `/auth/refresh` answers `JWT_2`; `/users/me` answers 401 to `JWT_1`
    /// and 200 to `JWT_2`.
    async fn mock_backend() -> (String, Arc<StdMutex<Vec<Seen>>>) {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let base = format!("http://{}", listener.local_addr().unwrap());
        let seen = Arc::new(StdMutex::new(Vec::new()));
        let log = seen.clone();
        tokio::spawn(async move {
            loop {
                let (mut tcp, _) = listener.accept().await.unwrap();
                let log = log.clone();
                tokio::spawn(async move {
                    let mut buf = Vec::new();
                    let mut chunk = [0u8; 4096];
                    let head_end = loop {
                        let n = tcp.read(&mut chunk).await.unwrap();
                        buf.extend_from_slice(&chunk[..n]);
                        if let Some(i) = buf.windows(4).position(|w| w == b"\r\n\r\n") {
                            break i + 4;
                        }
                    };
                    let head = String::from_utf8_lossy(&buf[..head_end]).into_owned();
                    let header = |name: &str| {
                        head.lines()
                            .find_map(|l| l.split_once(':').filter(|(k, _)| k.eq_ignore_ascii_case(name)))
                            .map(|(_, v)| v.trim().to_owned())
                    };
                    let len: usize = header("content-length").and_then(|v| v.parse().ok()).unwrap_or(0);
                    while buf.len() < head_end + len {
                        let n = tcp.read(&mut chunk).await.unwrap();
                        buf.extend_from_slice(&chunk[..n]);
                    }
                    let mut first = head.lines().next().unwrap().split(' ');
                    let s = Seen {
                        method: first.next().unwrap().to_owned(),
                        path: first.next().unwrap().to_owned(),
                        authorization: header("authorization"),
                        body: String::from_utf8_lossy(&buf[head_end..head_end + len]).into_owned(),
                    };
                    let (status, body) = match s.path.as_str() {
                        "/auth/challenge" => (200, r#"{"data":{"id":"ch-1","message":"SGVsbG8gV29ybGQ="}}"#.to_owned()),
                        "/auth/sign" => (200, format!(r#"{{"data":{{"jwt":"{JWT_1}","refresh_token":"rt-1"}}}}"#)),
                        "/auth/refresh" => (200, format!(r#"{{"data":{{"jwt":"{JWT_2}"}}}}"#)),
                        "/users/me" if s.authorization.as_deref() == Some(&format!("Bearer {JWT_2}")) => {
                            (200, r#"{"id":"u2"}"#.to_owned())
                        }
                        "/users/me" => (401, r#"{"error":"expired"}"#.to_owned()),
                        _ => (404, "{}".to_owned()),
                    };
                    log.lock().unwrap().push(s);
                    let reply = format!(
                        "HTTP/1.1 {status} X\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                        body.len()
                    );
                    tcp.write_all(reply.as_bytes()).await.unwrap();
                    tcp.shutdown().await.unwrap();
                });
            }
        });
        (base, seen)
    }

    #[test]
    fn sign_in_then_api_request_refreshes_on_401() {
        let core = open_core("auth");
        let map = with_memory_store(&core);
        map.lock().unwrap().insert("mnemonic_mainWallet".into(), ABANDON.into());
        let (base, seen) = runtime().block_on(mock_backend());
        runtime().block_on(core.api_set_base_url(base));
        runtime().block_on(core.api_set_metrics(Some(DeviceMetricsDto {
            device_id: "dev-1".into(),
            battery_level: Some(80),
            screen_brightness: None,
            boot_time: None,
        })));

        let out = runtime().block_on(core.auth_ensure_session()).unwrap();
        assert_eq!(out.kind, AuthEnsureKind::Ready, "{out:?}");
        assert_eq!(map.lock().unwrap().get("jwt").map(String::as_str), Some(JWT_1));
        assert_eq!(map.lock().unwrap().get("refresh_token").map(String::as_str), Some("rt-1"));

        let resp = runtime().block_on(core.api_request(HttpMethodDto::Get, "/users/me".into(), None)).unwrap();
        assert_eq!((resp.status, resp.body.as_str()), (200, r#"{"id":"u2"}"#));
        assert_eq!(map.lock().unwrap().get("jwt").map(String::as_str), Some(JWT_2));

        let resp = runtime()
            .block_on(core.api_request(HttpMethodDto::Post, "/missing".into(), Some(r#"{"a":1}"#.into())))
            .unwrap();
        assert_eq!(resp.status, 404);

        let seen = seen.lock().unwrap().clone();
        let paths: Vec<&str> = seen.iter().map(|s| s.path.as_str()).collect();
        assert_eq!(paths, vec!["/auth/challenge", "/auth/sign", "/users/me", "/auth/refresh", "/users/me", "/missing"]);
        assert!(seen[0].authorization.is_none() && seen[3].authorization.is_none());
        assert_eq!(seen[2].authorization.as_deref(), Some(format!("Bearer {JWT_1}").as_str()));
        assert_eq!(seen[5].method, "POST");
        let body: Value = serde_json::from_str(&seen[5].body).unwrap();
        assert_eq!(body["a"], 1);
        assert_eq!(body["metrics"]["device_id"], "dev-1");

        runtime().block_on(core.auth_invalidate()).unwrap();
        assert!(!map.lock().unwrap().contains_key("jwt"));
        assert!(!map.lock().unwrap().contains_key("refresh_token"));
    }

    #[test]
    fn unsafe_device_cannot_sign_in() {
        let core = open_core("unsafe");
        let map = with_memory_store(&core);
        map.lock().unwrap().insert("mnemonic_mainWallet".into(), ABANDON.into());
        runtime().block_on(core.api_set_base_url("http://127.0.0.1:1".into()));
        runtime().block_on(core.auth_set_device_safe(false));
        let err = runtime().block_on(core.auth_access_token()).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::Session);
        assert!(err.message.contains("Unsafe device"), "{}", err.message);
    }
}
