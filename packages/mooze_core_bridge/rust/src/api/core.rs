//! The core handle Dart holds. Every method delegates to `mooze_app::App`.
//!
//! Calls run on the shared tokio runtime (see [`crate::ports`]) because
//! reqwest and the Electrum spawner need a tokio context. The Dart-facing
//! names, parameters and error kinds are frozen; see
//! `docs/desktop-mvp.md`.

use std::path::PathBuf;
use std::sync::Mutex as StdMutex;

use flutter_rust_bridge::{frb, DartFnFuture};
use mooze_app::dto::AppConfig;
use mooze_app::events::SubscriptionId;
use mooze_app::App;

use super::types::*;
use crate::frb_generated::StreamSink;
use crate::ports::{install_crypto_provider, on_runtime, FileKv, NativePlatform};
use crate::secure_store::{DartSecureStore, LateSecureStore};

/// Subdirectory of `data_dir` that holds the key-value files.
const KV_DIR: &str = "core_kv";

/// Secure-store key of the wallet mnemonic.
const MNEMONIC_KEY: &str = mooze_core::store::MNEMONIC_KEY;

/// Handle to one opened core. Dart keeps one for the app's lifetime.
#[frb(opaque)]
pub struct MoozeCore {
    pub(crate) app: App<NativePlatform>,
    pub(crate) secure: LateSecureStore,
    /// Current `sideswapEvents` subscription, see `api::swap`.
    pub(crate) events: StdMutex<Option<(SubscriptionId, StreamSink<SideSwapEventDto>)>>,
}

/// Runs one `App` method on the runtime and maps its error.
macro_rules! delegate {
    ($self:ident . $method:ident ( $($arg:expr),* $(,)? )) => {{
        let app = $self.app.clone();
        on_runtime(async move { app.$method($($arg),*).await }).await
    }};
}
pub(crate) use delegate;

impl MoozeCore {
    /// Opens the core in `config.data_dir`.
    ///
    /// Also installs ring as the rustls crypto provider of the process,
    /// before any TLS use. Opening more than once is safe.
    pub async fn open(config: CoreConfig) -> Result<MoozeCore, CoreError> {
        install_crypto_provider();
        let kv = FileKv::open(PathBuf::from(&config.data_dir).join(KV_DIR))?;
        let secure = LateSecureStore::default();
        let app_config = AppConfig {
            network: config.network,
            backend: config.backend,
            bitcoin_node_url: config.bitcoin_node_url,
            liquid_node_url: config.liquid_node_url,
            api_base_url: None,
        };
        let platform = NativePlatform { kv, secure: secure.clone() };
        let app = on_runtime(App::open(app_config, platform)).await?;
        Ok(MoozeCore { app, secure, events: StdMutex::new(None) })
    }

    /// Runs a Liquid signing call whose Dart signature still carries the
    /// mnemonic. The facade signs with the stored mnemonic; this helper
    /// keeps the parameter honest:
    ///
    /// - A stored mnemonic must equal the parameter, else `invalidInput`.
    /// - With no stored mnemonic the call runs first, so a missing wallet
    ///   reports `invalidState` without writing anything. Only a
    ///   `credential` failure seeds the store from the parameter and retries.
    async fn with_mnemonic<T, F, Fut>(&self, mnemonic: String, call: F) -> Result<T, CoreError>
    where
        F: Fn() -> Fut,
        Fut: std::future::Future<Output = Result<T, CoreError>>,
    {
        match delegate!(self.secure_get(MNEMONIC_KEY.to_owned()))? {
            Some(stored) if stored != mnemonic => Err(CoreError {
                kind: CoreErrorKind::InvalidInput,
                message: "mnemonic parameter does not match the stored wallet".into(),
            }),
            Some(_) => call().await,
            None => match call().await {
                Err(e) if e.kind == CoreErrorKind::Credential => {
                    delegate!(self.secure_put(MNEMONIC_KEY.to_owned(), mnemonic))?;
                    call().await
                }
                r => r,
            },
        }
    }

    // ───────────────────────────── one-time import

    /// True once the Flutter data import finished.
    pub async fn is_migrated(&self) -> Result<bool, CoreError> {
        delegate!(self.is_migrated())
    }

    /// Imports the snapshot from `FlutterDataExporter`, once.
    pub async fn import_flutter_snapshot(&self, snapshot_json: String) -> Result<MigrationReportDto, CoreError> {
        delegate!(self.import_flutter_snapshot(snapshot_json))
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
        self.secure.set(DartSecureStore::new(read, write, delete, list_keys));
        let _ = delegate!(self.auth_reset());
    }

    /// Reads `key` from the secure store, through the Dart callbacks.
    pub async fn secure_get(&self, key: String) -> Result<Option<String>, CoreError> {
        delegate!(self.secure_get(key))
    }

    /// Writes `key` to the secure store, through the Dart callbacks.
    pub async fn secure_put(&self, key: String, value: String) -> Result<(), CoreError> {
        delegate!(self.secure_put(key, value))
    }

    /// Deletes `key` from the secure store, through the Dart callbacks.
    pub async fn secure_delete(&self, key: String) -> Result<(), CoreError> {
        delegate!(self.secure_delete(key))
    }

    /// Keys of the secure store that start with `prefix`, sorted.
    pub async fn secure_list_keys(&self, prefix: String) -> Result<Vec<String>, CoreError> {
        delegate!(self.secure_list_keys(prefix))
    }

    // ───────────────────────────── auth

    /// Sets the backend base URL (Dart `BACKEND_API_URL`). Default
    /// `https://api.mooze.app`. Drops the session manager.
    pub async fn api_set_base_url(&self, base_url: String) {
        let _ = delegate!(self.api_set_base_url(base_url));
    }

    /// Boot-time session check (Dart `ensureAuthSessionProvider`). Signs a
    /// login challenge with the stored mnemonic if needed and stores the
    /// tokens under `jwt` and `refresh_token`.
    pub async fn auth_ensure_session(&self) -> Result<AuthEnsureDto, CoreError> {
        delegate!(self.auth_ensure_session())
    }

    /// A valid JWT: stored, refreshed or newly created
    /// (Dart `SessionManagerService.getSession`).
    pub async fn auth_access_token(&self) -> Result<String, CoreError> {
        delegate!(self.auth_access_token())
    }

    /// Refreshes the session regardless of local expiry and returns the new
    /// JWT (Dart `SessionManagerService.forceRefresh`).
    pub async fn auth_force_refresh(&self) -> Result<String, CoreError> {
        delegate!(self.auth_force_refresh())
    }

    /// Manual refresh (Dart `refreshAuthSessionProvider`). Returns success.
    pub async fn auth_refresh_current(&self) -> Result<bool, CoreError> {
        delegate!(self.auth_refresh_current())
    }

    /// Deletes the stored session (Dart `SessionAuthenticator.invalidate`).
    pub async fn auth_invalidate(&self) -> Result<(), CoreError> {
        delegate!(self.auth_invalidate())
    }

    /// Drops the session manager, so the next auth call reads the mnemonic
    /// again. Call it after the wallet mnemonic changes or is deleted.
    pub async fn auth_reset(&self) {
        let _ = delegate!(self.auth_reset());
    }

    /// Sets the device integrity result (Dart `SafeDevice.isSafeDevice`).
    /// Unsafe devices cannot sign in and send API requests without a token.
    pub async fn auth_set_device_safe(&self, safe: bool) {
        let _ = delegate!(self.auth_set_device_safe(safe));
    }

    /// The persisted device id, or a new one derived from `serial`
    /// (`UniqueIdentifier.serial`) or `platform_id` (Android id or iOS
    /// identifierForVendor), else a random UUID (Dart `DeviceIdService`).
    pub async fn auth_device_id(
        &self,
        serial: Option<String>,
        platform_id: Option<String>,
    ) -> Result<String, CoreError> {
        delegate!(self.auth_device_id(serial, platform_id))
    }

    /// Sets the metrics the API client adds to JSON request bodies.
    /// `None` stops adding them.
    pub async fn api_set_metrics(&self, metrics: Option<DeviceMetricsDto>) {
        let _ = delegate!(self.api_set_metrics(metrics));
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
        delegate!(self.api_request(method, path, json_body))
    }

    // ───────────────────────────── bitcoin

    /// Loads or creates the Bitcoin wallet for `mnemonic`.
    pub async fn bitcoin_connect(&self, mnemonic: String) -> Result<(), CoreError> {
        delegate!(self.bitcoin_connect(mnemonic))
    }

    /// Drops the Bitcoin wallet. Idempotent.
    pub async fn bitcoin_disconnect(&self) {
        let _ = delegate!(self.bitcoin_disconnect());
    }

    /// Syncs the Bitcoin wallet.
    pub async fn bitcoin_sync(&self) -> Result<SyncOutcomeDto, CoreError> {
        delegate!(self.bitcoin_sync())
    }

    /// Bitcoin balance from local state.
    pub async fn bitcoin_balance(&self) -> Result<BalanceDto, CoreError> {
        delegate!(self.bitcoin_balance())
    }

    /// Bitcoin transactions from local state, newest first.
    pub async fn bitcoin_transactions(&self) -> Result<Vec<TransactionDto>, CoreError> {
        delegate!(self.bitcoin_transactions())
    }

    /// Transaction changes since the last call.
    pub async fn bitcoin_take_events(&self) -> Result<Vec<TransactionEventDto>, CoreError> {
        delegate!(self.bitcoin_take_events())
    }

    /// Next unused receive address.
    pub async fn bitcoin_receive_address(&self, label: Option<String>) -> Result<ReceiveAddressDto, CoreError> {
        delegate!(self.bitcoin_receive_address(label))
    }

    /// Fee estimate for a send.
    pub async fn bitcoin_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto, CoreError> {
        delegate!(self.bitcoin_estimate_fee(request))
    }

    /// Builds, signs and broadcasts a send.
    pub async fn bitcoin_send(&self, request: SendRequestDto) -> Result<BroadcastResultDto, CoreError> {
        delegate!(self.bitcoin_send(request))
    }

    /// Chain tip height.
    pub async fn bitcoin_block_height(&self) -> Result<u32, CoreError> {
        delegate!(self.bitcoin_block_height())
    }

    /// Addresses of `keychain` at `start..start + count`. Reveals nothing.
    pub async fn bitcoin_derived_addresses(
        &self,
        keychain: KeychainDto,
        start: u32,
        count: u32,
    ) -> Result<Vec<DerivedAddressDto>, CoreError> {
        delegate!(self.bitcoin_derived_addresses(keychain, start, count))
    }

    /// Unspent outputs with address, derivation and confirmation.
    pub async fn bitcoin_unspent_outputs(&self) -> Result<Vec<WalletUtxoDto>, CoreError> {
        delegate!(self.bitcoin_unspent_outputs())
    }

    /// Derivation of `address` if the wallet owns it. Throws
    /// `CoreErrorKind.invalidInput` for an address it cannot parse.
    pub async fn bitcoin_is_mine(&self, address: String) -> Result<Option<AddressOwnershipDto>, CoreError> {
        delegate!(self.bitcoin_is_mine(address))
    }

    /// Next receive address with no history. Reveals up to it and persists.
    pub async fn bitcoin_next_unused_address(&self) -> Result<NextUnusedAddressDto, CoreError> {
        delegate!(self.bitcoin_next_unused_address())
    }

    /// Adds a transaction broadcast elsewhere, for example a peg-in funding.
    pub async fn bitcoin_register_external_broadcast(&self, transaction: TransactionDto) -> Result<(), CoreError> {
        delegate!(self.bitcoin_register_external_broadcast(transaction))
    }

    // ───────────────────────────── liquid

    /// Loads or creates the Liquid wallet for `mnemonic`.
    pub async fn liquid_connect(&self, mnemonic: String) -> Result<(), CoreError> {
        delegate!(self.liquid_connect(mnemonic))
    }

    /// Drops the Liquid wallet. Idempotent.
    pub async fn liquid_disconnect(&self) {
        let _ = delegate!(self.liquid_disconnect());
    }

    /// Syncs the Liquid wallet.
    pub async fn liquid_sync(&self) -> Result<SyncOutcomeDto, CoreError> {
        delegate!(self.liquid_sync())
    }

    /// Liquid balance from local state.
    pub async fn liquid_balance(&self) -> Result<BalanceDto, CoreError> {
        delegate!(self.liquid_balance())
    }

    /// Re-reads balances from the local wallet, no network.
    pub async fn liquid_refresh_balance(&self) -> Result<BalanceDto, CoreError> {
        delegate!(self.liquid_refresh_balance())
    }

    /// Applies known per-asset deltas to the cached balance.
    pub async fn liquid_apply_balance_delta(
        &self,
        asset_ids: Vec<String>,
        deltas: Vec<i64>,
    ) -> Result<BalanceDto, CoreError> {
        delegate!(self.liquid_apply_balance_delta(asset_ids, deltas))
    }

    /// Liquid transactions from local state, newest first.
    pub async fn liquid_transactions(&self) -> Result<Vec<TransactionDto>, CoreError> {
        delegate!(self.liquid_transactions())
    }

    /// Transaction changes since the last call.
    pub async fn liquid_take_events(&self) -> Result<Vec<TransactionEventDto>, CoreError> {
        delegate!(self.liquid_take_events())
    }

    /// Receive address, optionally for one asset.
    pub async fn liquid_receive_address(
        &self,
        asset_id: Option<String>,
        label: Option<String>,
    ) -> Result<ReceiveAddressDto, CoreError> {
        delegate!(self.liquid_receive_address(asset_id, label))
    }

    /// Addresses of `keychain` at `start..start + count`. Reveals nothing.
    pub async fn liquid_derived_addresses(
        &self,
        keychain: KeychainDto,
        start: u32,
        count: u32,
    ) -> Result<Vec<DerivedAddressDto>, CoreError> {
        delegate!(self.liquid_derived_addresses(keychain, start, count))
    }

    /// Unspent outputs with address, derivation, asset and confirmation.
    pub async fn liquid_unspent_outputs(&self) -> Result<Vec<WalletUtxoDto>, CoreError> {
        delegate!(self.liquid_unspent_outputs())
    }

    /// Derivation of `address` among the first `scan_limit` addresses of
    /// each chain. Throws `CoreErrorKind.invalidInput` for an address it
    /// cannot parse.
    pub async fn liquid_is_mine(
        &self,
        address: String,
        scan_limit: u32,
    ) -> Result<Option<AddressOwnershipDto>, CoreError> {
        delegate!(self.liquid_is_mine(address, scan_limit))
    }

    /// LWK's last unused receive address, with a history check.
    pub async fn liquid_next_unused_address(&self) -> Result<NextUnusedAddressDto, CoreError> {
        delegate!(self.liquid_next_unused_address())
    }

    /// Unblinded UTXOs, for SideSwap.
    pub async fn liquid_utxos(&self) -> Result<Vec<LiquidUtxoDto>, CoreError> {
        delegate!(self.liquid_utxos())
    }

    /// Fee estimate for a send.
    pub async fn liquid_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto, CoreError> {
        delegate!(self.liquid_estimate_fee(request))
    }

    /// Builds an unsigned L-BTC send. A drain sends the whole L-BTC balance.
    pub async fn liquid_build_lbtc_send(
        &self,
        destination: String,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> Result<LiquidSendDraftDto, CoreError> {
        delegate!(self.liquid_build_lbtc_send(destination, amount_sat, fee_rate_sat_per_vb, drain))
    }

    /// Builds, signs and broadcasts a send. Signing reads the stored
    /// mnemonic; see `with_mnemonic` for the parameter rule.
    pub async fn liquid_send(
        &self,
        request: SendRequestDto,
        mnemonic: String,
    ) -> Result<BroadcastResultDto, CoreError> {
        self.with_mnemonic(mnemonic, || {
            let request = request.clone();
            async move { delegate!(self.liquid_send(request)) }
        })
        .await
    }

    /// Signs a PSET and broadcasts it. Returns the txid. Signing reads the
    /// stored mnemonic; see `with_mnemonic` for the parameter rule.
    pub async fn liquid_sign_and_broadcast(&self, pset: String, mnemonic: String) -> Result<String, CoreError> {
        self.with_mnemonic(mnemonic, || {
            let pset = pset.clone();
            async move { delegate!(self.liquid_sign_and_broadcast(pset)) }
        })
        .await
    }

    /// Signs a SideSwap swap PSET. Returns the signed PSET. Signing reads
    /// the stored mnemonic; see `with_mnemonic` for the parameter rule.
    pub async fn liquid_sign_swap_pset(&self, pset: String, mnemonic: String) -> Result<String, CoreError> {
        self.with_mnemonic(mnemonic, || {
            let pset = pset.clone();
            async move { delegate!(self.liquid_sign_swap_pset(pset)) }
        })
        .await
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::ports::runtime;
    use crate::secure_store::tests::memory_store;
    use mooze_core::ports::KvStore;
    use std::collections::BTreeMap;

    pub(crate) const ABANDON: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    /// Unsigned JWT that expires in 2100.
    pub(crate) const JWT_1: &str = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUxIn0.sig";

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
    pub(crate) fn with_memory_store(core: &MoozeCore) -> std::sync::Arc<StdMutex<BTreeMap<String, String>>> {
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

    #[test]
    fn liquid_signing_parameter_must_match_a_stored_mnemonic() {
        let core = open_core("mismatch-mnemonic");
        let map = with_memory_store(&core);
        map.lock().unwrap().insert("mnemonic_mainWallet".into(), ABANDON.into());
        runtime().block_on(core.liquid_connect(ABANDON.into())).unwrap();
        let err =
            runtime().block_on(core.liquid_sign_swap_pset("not-a-pset".into(), "other words".into())).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::InvalidInput);
        assert_eq!(map.lock().unwrap().get("mnemonic_mainWallet").map(String::as_str), Some(ABANDON));
    }

    #[test]
    fn liquid_signing_without_a_wallet_writes_nothing() {
        let core = open_core("no-wallet-no-write");
        let map = with_memory_store(&core);
        let err = runtime().block_on(core.liquid_sign_swap_pset("not-a-pset".into(), ABANDON.into())).unwrap_err();
        assert_eq!(err.kind, CoreErrorKind::InvalidState);
        assert!(!map.lock().unwrap().contains_key("mnemonic_mainWallet"));
    }

    #[test]
    fn liquid_signing_parameter_seeds_an_empty_secure_store() {
        let core = open_core("seed-mnemonic");
        let map = with_memory_store(&core);
        runtime().block_on(core.liquid_connect(ABANDON.into())).unwrap();
        // The PSET is garbage: the call fails after the mnemonic is in place.
        let _ = runtime().block_on(core.liquid_sign_swap_pset("not-a-pset".into(), ABANDON.into()));
        assert_eq!(map.lock().unwrap().get("mnemonic_mainWallet").map(String::as_str), Some(ABANDON));
        // A stored mnemonic wins over the parameter.
        let _ = runtime().block_on(core.liquid_sign_swap_pset("not-a-pset".into(), "other words".into()));
        assert_eq!(map.lock().unwrap().get("mnemonic_mainWallet").map(String::as_str), Some(ABANDON));
    }

    #[test]
    fn derives_the_same_first_addresses_as_the_flutter_app() {
        let core = open_core("addresses");
        runtime().block_on(core.bitcoin_connect(ABANDON.into())).unwrap();
        let ext = runtime().block_on(core.bitcoin_derived_addresses(KeychainDto::External, 0, 1)).unwrap();
        assert_eq!(ext[0].address, "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu");
    }
}
