mod account;
pub mod backend;
pub mod idle;
mod native_auth;
mod payments;
mod pix;
mod prices;
mod security;
mod settings;
mod setup;
mod swaps;
use crate::{
    dto::*,
    error::{DesktopError, Result},
    rules,
    send_review::ReviewBook,
};
use mooze_app::{
    dto::*,
    events::{AppEvent, EventSink},
    App, Platform,
};
use mooze_core::{
    auth::PinService,
    domain::WalletCredentials,
    ports::{Clock, KvStore},
    store::CredentialStore,
    wallet::mnemonic,
};
use std::sync::{
    atomic::{AtomicBool, AtomicU32, Ordering},
    Arc, Mutex as StdMutex,
};
use tokio::sync::Mutex;
const REMOVAL: &str = "desktop/removal/v1";
const IMPORT: &str = "desktop/import";
const SUBMISSION: &str = "desktop/submission";
const RETRY: &str = "desktop/pinRetryAt";
pub type EventCallback = Arc<dyn Fn(serde_json::Value) + Send + Sync>;
struct Inner<P: Platform> {
    app: Option<App<P>>,
    reviews: ReviewBook,
}
pub struct WalletSession<P: Platform> {
    native: Arc<dyn crate::native_auth::NativeAuthenticator>,
    native_attempt: Arc<StdMutex<crate::native_auth::attempt::AttemptState>>,
    native_setup_generation: StdMutex<Option<u32>>,
    services: backend::ServiceConfig,
    backend_state: Mutex<Option<(u32, BackendSessionDto)>>,
    pix_gate: Mutex<()>,
    swap_gate: Mutex<()>,
    swaps: Arc<StdMutex<crate::swap_review::SwapBook>>,
    pub platform: P,
    backend: BackendDto,
    setup: StdMutex<Option<setup::SetupCandidate>>,
    inner: Mutex<Inner<P>>,
    idle: StdMutex<Option<(idle::IdleState, crate::platform::idle_clock::IdleClock)>>,
    transition: Arc<StdMutex<()>>,
    configured: AtomicBool,
    submitting: AtomicBool,
    unlocked: Arc<AtomicBool>,
    generation: Arc<AtomicU32>,
    sync: Arc<StdMutex<Option<SyncStateDto>>>,
    chains: Arc<StdMutex<Vec<ChainStateDto>>>,
    emit: Arc<StdMutex<Option<EventCallback>>>,
}
struct Sink {
    transition: Arc<StdMutex<()>>,
    swaps: Arc<StdMutex<crate::swap_review::SwapBook>>,
    clock: Arc<dyn Clock>,
    expected: u32,
    unlocked: Arc<AtomicBool>,
    generation: Arc<AtomicU32>,
    sync: Arc<StdMutex<Option<SyncStateDto>>>,
    chains: Arc<StdMutex<Vec<ChainStateDto>>>,
    emit: Arc<StdMutex<Option<EventCallback>>>,
}
impl EventSink for Sink {
    fn send(&self, event: AppEvent) -> bool {
        let transition = self.transition.lock().unwrap();
        if self.generation.load(Ordering::SeqCst) != self.expected {
            return false;
        }
        if let AppEvent::SideSwap(ref side) = event {
            if !self.unlocked.load(Ordering::SeqCst) {
                return true;
            }
            let view = {
                let mut book = self.swaps.lock().unwrap();
                if let Some(quote) = &side.quote {
                    book.quote(quote, self.expected, self.clock.now_ms());
                }
                if matches!(side.kind, SideSwapEventKind::Disconnected) {
                    book.disconnected();
                }
                book.view(self.clock.now_ms())
            };
            drop(transition);
            if let Some(callback) = self.emit.lock().unwrap().as_ref() {
                callback(serde_json::json!({"type":"swap","generation":self.expected,"data":view}));
            }
            return true;
        }
        if let AppEvent::ChainSyncState(ref s) = event {
            let chain = match s.chain {
                ChainDto::Bitcoin => WalletChain::Bitcoin,
                ChainDto::Liquid => WalletChain::Liquid,
                _ => return true,
            };
            let mut states = self.chains.lock().unwrap();
            let previous = states
                .iter()
                .find(|c| c.chain == chain)
                .and_then(|c| c.last_success_at_ms);
            states.retain(|c| c.chain != chain);
            states.push(ChainStateDto {
                chain,
                phase: if s.succeeded { "ready" } else { "error" }.into(),
                last_success_at_ms: if s.succeeded {
                    Some(s.observed_at_ms)
                } else {
                    previous
                },
                error: if s.succeeded {
                    None
                } else {
                    Some("Não foi possível sincronizar esta rede.".into())
                },
            });
        }
        if let AppEvent::SyncState(ref s) = event {
            *self.sync.lock().unwrap() = Some(s.clone());
        }
        let emit = self.unlocked.load(Ordering::SeqCst);
        drop(transition);
        if emit {
            if let Some(callback) = self.emit.lock().unwrap().as_ref() {
                callback(
                    serde_json::json!({"type":"core","generation":self.expected,"data":event}),
                );
            }
        }
        true
    }
}
impl<P: Platform + Clone> WalletSession<P> {
    pub fn new(platform: P, backend: BackendDto) -> Self {
        Self {
            platform,
            services: backend::ServiceConfig::default(),
            backend_state: Mutex::new(None),
            pix_gate: Mutex::new(()),
            swap_gate: Mutex::new(()),
            swaps: Arc::new(StdMutex::new(crate::swap_review::SwapBook::default())),
            native: crate::native_auth::unsupported(),
            native_attempt: Arc::new(StdMutex::new(Default::default())),
            native_setup_generation: StdMutex::new(None),
            setup: StdMutex::new(None),
            backend,
            inner: Mutex::new(Inner {
                app: None,
                reviews: ReviewBook::default(),
            }),
            transition: Arc::new(StdMutex::new(())),
            idle: StdMutex::new(None),
            configured: AtomicBool::new(false),
            submitting: AtomicBool::new(false),
            unlocked: Arc::new(AtomicBool::new(false)),
            generation: Arc::new(AtomicU32::new(0)),
            sync: Arc::new(StdMutex::new(None)),
            chains: Arc::new(StdMutex::new(vec![])),
            emit: Arc::new(StdMutex::new(None)),
        }
    }
    pub fn set_emitter(&self, callback: EventCallback) {
        *self.emit.lock().unwrap() = Some(callback);
    }
    fn emit_session(&self, s: &SessionDto) {
        if let Some(f) = self.emit.lock().unwrap().as_ref() {
            f(serde_json::json!({"type":"session","data":s}));
        }
    }
    async fn retry_at(&self) -> Result<u64> {
        let raw = self.platform.kv().get(RETRY).await?;
        match raw {
            None => Ok(0),
            Some(v) => serde_json::from_slice(&v)
                .map_err(|_| DesktopError::new("storage", "Estado de autenticação inválido.")),
        }
    }
    pub async fn status(&self) -> Result<SessionDto> {
        if self.unlocked.load(Ordering::SeqCst) {
            let _ = self.authorize();
        }
        let removing = self.platform.kv().get(REMOVAL).await?.is_some();
        let complete = self.platform.kv().get(IMPORT).await? == Some(b"complete".to_vec());
        self.configured.store(complete, Ordering::SeqCst);
        Ok(SessionDto {
            status: if removing {
                "removal_pending"
            } else if self.unlocked.load(Ordering::SeqCst) {
                "unlocked"
            } else if complete {
                "locked"
            } else {
                "empty"
            }
            .into(),
            generation: self.generation.load(Ordering::SeqCst),
            retry_after_ms: self
                .retry_at()
                .await?
                .saturating_sub(self.platform.clock().now_ms())
                .min(u32::MAX as u64) as u32,
        })
    }
    pub fn check_expiry(&self) {
        if self.unlocked.load(Ordering::SeqCst) {
            let _ = self.authorize();
        }
    }
    fn authorize(&self) -> Result<u32> {
        let transition = self.transition.lock().unwrap();
        if !self.unlocked.load(Ordering::SeqCst) {
            return Err(DesktopError::new("locked", "Desbloqueie a carteira."));
        }
        let expired = {
            let mut idle = self.idle.lock().unwrap();
            idle.as_mut().is_none_or(|(state, clock)| {
                clock
                    .elapsed_ms(self.platform.clock().now_ms())
                    .is_none_or(|now| state.expired(now))
            })
        };
        if expired {
            self.unlocked.store(false, Ordering::SeqCst);
            let generation = self.generation.fetch_add(1, Ordering::SeqCst) + 1;
            drop(transition);
            let _ = self.cancel_native_auth();
            *self.native_setup_generation.lock().unwrap() = None;
            self.emit_session(&SessionDto {
                status: "locked".into(),
                generation,
                retry_after_ms: 0,
            });
            return Err(DesktopError::new("locked", "A sessão expirou."));
        }
        Ok(self.generation.load(Ordering::SeqCst))
    }
    pub fn record_activity(&self, generation: u32) -> Result<()> {
        if self.authorize()? != generation {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        let _transition = self.transition.lock().unwrap();
        if !self.unlocked.load(Ordering::SeqCst)
            || generation != self.generation.load(Ordering::SeqCst)
        {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        let mut guard = self.idle.lock().unwrap();
        if let Some((state, clock)) = guard.as_mut() {
            if let Some(now) = clock.elapsed_ms(self.platform.clock().now_ms()) {
                state.activity(now);
            }
        }
        Ok(())
    }
    pub fn set_foreground(&self, foreground: bool) {
        {
            let mut guard = self.idle.lock().unwrap();
            if let Some((state, clock)) = guard.as_mut() {
                if let Some(now) = clock.elapsed_ms(self.platform.clock().now_ms()) {
                    if foreground {
                        state.foreground(now);
                    } else {
                        state.background(now);
                    }
                }
            }
        }
        self.check_expiry();
    }
    async fn connect(&self, phrase: String) -> Result<App<P>> {
        let settings = self.load_settings().await?;
        self.connect_with_settings(phrase, &settings).await
    }
    async fn connect_with_settings(
        &self,
        phrase: String,
        settings: &DesktopSettingsDto,
    ) -> Result<App<P>> {
        let app = App::open_with_public_fallback(
            AppConfig {
                network: crate::network::network_dto(),
                backend: self.backend,
                bitcoin_node_url: settings.bitcoin_node.clone().unwrap_or_default(),
                liquid_node_url: settings.liquid_node.clone().unwrap_or_default(),
                api_base_url: Some(self.services.api_url()?),
            },
            self.platform_clone(),
            settings.public_fallback,
        )
        .await?;
        app.bitcoin_connect(phrase.clone()).await?;
        app.liquid_connect(phrase).await?;
        Ok(app)
    }
    pub(super) fn subscribe_app(&self, app: &App<P>) {
        app.subscribe(Box::new(Sink {
            transition: self.transition.clone(),
            swaps: self.swaps.clone(),
            clock: Arc::new(self.platform.clock()),
            expected: self.generation.load(Ordering::SeqCst),
            unlocked: self.unlocked.clone(),
            generation: self.generation.clone(),
            sync: self.sync.clone(),
            chains: self.chains.clone(),
            emit: self.emit.clone(),
        }));
    }
    fn platform_clone(&self) -> P
    where
        P: Clone,
    {
        self.platform.clone()
    }
}
impl<P: Platform + Clone> WalletSession<P> {
    pub async fn import_wallet(&self, phrase: String, pin: String) -> Result<SessionDto> {
        let mut inner = self.inner.lock().await;
        if self.platform.kv().get(REMOVAL).await?.is_some() {
            return Err(DesktopError::new(
                "removal_pending",
                "Conclua a remoção local antes de continuar.",
            ));
        }
        let expected = self.generation.load(Ordering::SeqCst);
        if self.platform.kv().get(IMPORT).await? == Some(b"complete".to_vec()) {
            return Err(DesktopError::new(
                "invalid_input",
                "Uma carteira já foi importada.",
            ));
        }
        if !rules::valid_pin(&pin) {
            return Err(DesktopError::new(
                "invalid_input",
                "Use um PIN de 6 dígitos.",
            ));
        }
        let phrase = mnemonic::parse(&phrase)
            .map_err(|_| DesktopError::new("invalid_input", "Frase de recuperação inválida."))?
            .to_string();
        // A pending marker proves this namespace belongs to an interrupted MVP import.
        if self.platform.kv().get(IMPORT).await? == Some(b"pending".to_vec()) {
            self.clear_incomplete().await?;
        }
        self.platform.kv().put(IMPORT, b"pending".to_vec()).await?;
        let result: Result<App<P>> = async {
            let app = self.connect(phrase.clone()).await?;
            CredentialStore::new(self.platform.secure(), crate::network::app_network())
                .save(&WalletCredentials {
                    mnemonic: phrase,
                    network: crate::network::app_network(),
                })
                .await?;
            PinService::new(
                self.platform.secure(),
                self.platform.kv(),
                self.platform.clock(),
            )
            .create_pin(&pin)
            .await?;
            self.platform.kv().put(IMPORT, b"complete".to_vec()).await?;
            Ok(app)
        }
        .await;
        let app = match result {
            Ok(a) => a,
            Err(e) => {
                self.clear_incomplete().await?;
                return Err(e);
            }
        };
        inner.app = Some(app);
        self.open_session(&mut inner, expected, None, true).await
    }
    async fn clear_incomplete(&self) -> Result<()> {
        for k in self.platform.secure().list_keys("").await? {
            self.platform.secure().delete(&k).await?;
        }
        for k in self.platform.kv().list_keys("").await? {
            if k != IMPORT {
                self.platform.kv().delete(&k).await?;
            }
        }
        self.platform.kv().delete(IMPORT).await?;
        Ok(())
    }
    pub async fn unlock(&self, pin: String) -> Result<SessionDto> {
        self.cancel_native_auth()?;
        let mut inner = self.inner.lock().await;
        if self.platform.kv().get(REMOVAL).await?.is_some() {
            return Err(DesktopError::new(
                "removal_pending",
                "Conclua a remoção local antes de continuar.",
            ));
        }
        let expected = self.generation.load(Ordering::SeqCst);
        if self.platform.kv().get(IMPORT).await? != Some(b"complete".to_vec()) {
            return Err(DesktopError::new("invalid_input", "Importe uma carteira."));
        }
        if !rules::valid_pin(&pin) {
            return Err(DesktopError::new(
                "invalid_input",
                "Use um PIN de 6 dígitos.",
            ));
        }
        self.verify_pin(&pin).await?;
        self.load_and_open(&mut inner, expected, None).await
    }
    async fn load_and_open(
        &self,
        inner: &mut Inner<P>,
        expected: u32,
        attempt: Option<crate::native_auth::attempt::Attempt>,
    ) -> Result<SessionDto> {
        if let Some(old) = inner.app.take() {
            old.stop_and_wait().await?;
            old.sideswap_disconnect().await?;
        }
        {
            let credentials =
                CredentialStore::new(self.platform.secure(), crate::network::app_network())
                    .load()
                    .await?;
            inner.app = Some(self.connect(credentials.mnemonic).await?);
        }
        self.open_session(inner, expected, attempt, false).await
    }
    async fn open_session(
        &self,
        inner: &mut Inner<P>,
        expected: u32,
        attempt: Option<crate::native_auth::attempt::Attempt>,
        offer: bool,
    ) -> Result<SessionDto> {
        let minutes = self.load_settings().await?.lock_minutes;
        {
            let _transition = self.transition.lock().unwrap();
            if self.generation.load(Ordering::SeqCst) != expected {
                return Err(DesktopError::new(
                    "locked",
                    "A carteira foi bloqueada. Desbloqueie para continuar.",
                ));
            }
            if let Some(attempt) = attempt {
                self.validate_native_attempt(attempt)?;
            }
            let generation = self.generation.fetch_add(1, Ordering::SeqCst) + 1;
            *self.native_setup_generation.lock().unwrap() = offer.then_some(generation);
            inner.reviews.clear();
            *self.idle.lock().unwrap() = Some((
                idle::IdleState::new(minutes, 0).unwrap(),
                crate::platform::idle_clock::IdleClock::new(self.platform.clock().now_ms()),
            ));
            self.unlocked.store(true, Ordering::SeqCst);
        }
        if let Some(app) = &inner.app {
            if let Err(e) = async {
                self.subscribe_app(app);
                app.session_unlocked().await?;
                app.start_wallet_sync(StartConfigDto {
                    sync_tick_ms: None,
                    sync_timeout_ms: None,
                    startup_sync: true,
                    peg_wallet_id: None,
                })
                .await
            }
            .await
            {
                self.unlocked.store(false, Ordering::SeqCst);
                return Err(e.into());
            }
        }
        let s = self.status().await?;
        self.emit_session(&s);
        Ok(s)
    }
    pub async fn lock(&self) -> Result<SessionDto> {
        self.cancel_native_auth()?;
        *self.native_setup_generation.lock().unwrap() = None;
        *self.setup.lock().unwrap() = None;
        // Close authorization and notify the UI before waiting for a long wallet operation.
        {
            let _transition = self.transition.lock().unwrap();
            self.unlocked.store(false, Ordering::SeqCst);
            self.generation.fetch_add(1, Ordering::SeqCst);
        }
        let s = SessionDto {
            status: if self.configured.load(Ordering::SeqCst) {
                "locked"
            } else {
                "empty"
            }
            .into(),
            generation: self.generation.load(Ordering::SeqCst),
            retry_after_ms: 0,
        };
        self.emit_session(&s);
        let mut inner = self.inner.lock().await;
        inner.reviews.clear();
        self.swaps.lock().unwrap().clear();
        if let Some(app) = inner.app.take() {
            app.stop_and_wait().await?;
            app.sideswap_disconnect().await?;
        }
        Ok(s)
    }
    pub async fn snapshot(&self) -> Result<DesktopSnapshotDto> {
        let generation = self.authorize()?;
        let app = {
            let inner = self.inner.lock().await;
            inner
                .app
                .clone()
                .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?
        };
        let activity = app.wallet_activity().await?;
        let submission = self.submission().await?;
        if self.authorize()? != generation {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        let snapshot = DesktopSnapshotDto {
            submission,
            activity,
            sync: self.sync.lock().unwrap().clone(),
            chains: self.chains.lock().unwrap().clone(),
            generation,
        };
        check_safe(
            &serde_json::to_value(&snapshot)
                .map_err(|_| DesktopError::new("transport", "Dados inválidos."))?,
        )?;
        Ok(snapshot)
    }
    pub async fn holdings(&self) -> Result<HoldingsSnapshotDto> {
        let generation = self.authorize()?;
        let app = self
            .inner
            .lock()
            .await
            .app
            .clone()
            .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?;
        let holdings = app.wallet_holdings().await?;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(HoldingsSnapshotDto {
            generation,
            holdings,
            chains: self.chains.lock().unwrap().clone(),
        })
    }
    pub fn approved_assets(&self) -> Result<Vec<AssetMetadataDto>> {
        self.authorize()?;
        Ok(mooze_app::assets::approved_assets(
            crate::network::network_dto(),
        ))
    }
    pub async fn refresh(&self) -> Result<()> {
        self.authorize()?;
        let app = {
            let inner = self.inner.lock().await;
            inner
                .app
                .clone()
                .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?
        };
        app.refresh_now().await?;
        Ok(())
    }
    pub async fn receive(&self, chain: WalletChain) -> Result<ReceiveAddressDto> {
        let generation = self.authorize()?;
        let app = {
            let inner = self.inner.lock().await;
            inner
                .app
                .clone()
                .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?
        };
        let address = match chain {
            WalletChain::Bitcoin => app.bitcoin_receive_address(None).await?,
            WalletChain::Liquid => app.liquid_receive_address(None, None).await?,
        };
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(address)
    }
    pub async fn review(&self, mut request: ReviewRequestDto) -> Result<SendReviewDto> {
        let generation = self.authorize()?;
        if !mooze_app::assets::asset_metadata(crate::network::network_dto(), &request.asset)
            .approved
            || matches!(request.amount, SendAmountDto::Exact(_)) && request.exact_amount().is_none()
            || !rules::valid_rate(request.fee_rate_sat_per_vbyte)
            || request.destination.trim().is_empty()
        {
            return Err(DesktopError::new(
                "invalid_input",
                "Confira o endereço, valor e taxa.",
            ));
        }
        let mut inner = self.inner.lock().await;
        if self.submission().await?.is_some()
            || self
                .platform
                .kv()
                .get(swaps::SWAP_SUBMISSION)
                .await?
                .is_some()
        {
            return Err(DesktopError::new(
                "submission_unknown",
                "Confira o resultado do envio anterior.",
            ));
        }
        inner.reviews.clear();
        let app = inner
            .app
            .as_ref()
            .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?;
        let parsed = self.parse_payment(request.destination.clone())?;
        if parsed.chain != request.chain()
            || parsed.asset.as_ref().is_some_and(|a| *a != request.asset)
        {
            return Err(DesktopError::new(
                "invalid_input",
                "O pedido não corresponde ao ativo selecionado.",
            ));
        }
        request.destination = parsed.address;
        let dto = send_request(&request);
        let is_max = matches!(request.amount, SendAmountDto::Max);
        let (amount, fee) = app.prepare_desktop_send(request.asset.chain, dto).await?;
        request.amount = SendAmountDto::Exact(amount.to_string());
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        inner.reviews.insert_resolved(
            request,
            fee,
            generation,
            self.platform.clock().now_ms(),
            is_max,
        )
    }
    pub async fn submission(&self) -> Result<Option<SubmissionDto>> {
        let Some(raw) = self.platform.kv().get(SUBMISSION).await? else {
            return Ok(None);
        };
        let mut state: SubmissionDto = serde_json::from_slice(&raw)
            .map_err(|_| DesktopError::new("storage", "Resultado de envio inválido."))?;
        if state.phase == "submitting" && !self.submitting.load(Ordering::SeqCst) {
            state.phase = "uncertain".into();
        }
        Ok(Some(state))
    }
    fn emit_submission(&self) {
        if self.unlocked.load(Ordering::SeqCst) {
            if let Some(f) = self.emit.lock().unwrap().as_ref() {
                f(
                    serde_json::json!({"type":"submission","generation":self.generation.load(Ordering::SeqCst)}),
                );
            }
        }
    }
    pub async fn acknowledge_submission(&self) -> Result<()> {
        let _inner = self.inner.lock().await;
        self.authorize()?;
        if self.submitting.load(Ordering::SeqCst) {
            return Err(DesktopError::new(
                "submission_unknown",
                "O envio ainda está em andamento.",
            ));
        }
        self.platform.kv().delete(SUBMISSION).await?;
        self.emit_submission();
        Ok(())
    }
    pub async fn confirm(&self, id: String) -> Result<BroadcastResultDto> {
        let (app, review, generation) = {
            let mut inner = self.inner.lock().await;
            let generation = self.authorize()?;
            if self.submission().await?.is_some()
                || self
                    .platform
                    .kv()
                    .get(swaps::SWAP_SUBMISSION)
                    .await?
                    .is_some()
            {
                return Err(DesktopError::new(
                    "submission_unknown",
                    "Confira o resultado do envio anterior.",
                ));
            }
            let review = inner
                .reviews
                .take(&id, generation, self.platform.clock().now_ms())?;
            let app = inner
                .app
                .clone()
                .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?;
            let pending = SubmissionDto {
                version: 2,
                request: Some(review.request.clone()),
                debits: Some(review.debits.clone()),
                phase: "submitting".into(),
                chain: review.request.chain(),
                tx_id: None,
            };
            self.platform
                .kv()
                .put(SUBMISSION, serde_json::to_vec(&pending).unwrap())
                .await?;
            self.submitting.store(true, Ordering::SeqCst);
            (app, review, generation)
        };
        self.emit_submission();
        let mut request = send_request(&review.request);
        request.drain = review.is_max && matches!(review.request.chain(), WalletChain::Liquid);
        let authorize = || {
            if self.authorize().ok() == Some(generation) {
                Ok(())
            } else {
                Err(mooze_core::Error::Session("locked".into()))
            }
        };
        let result = match review.request.chain() {
            WalletChain::Bitcoin => {
                app.bitcoin_send_authorized(request, review.fee_sat, authorize)
                    .await
            }
            WalletChain::Liquid => {
                app.liquid_send_authorized_exact(
                    request,
                    review.fee_sat,
                    review.request.exact_amount().expect("resolved review"),
                    authorize,
                )
                .await
            }
        }
        .map_err(DesktopError::from);
        // Match submission creation/acknowledgment: a previous result cannot clear
        // the active flag of a subsequent submission.
        let _inner = self.inner.lock().await;
        // Persist the outcome independently of the initiating route or session.
        let persisted = match &result {
            Ok(sent) => {
                self.platform
                    .kv()
                    .put(
                        SUBMISSION,
                        serde_json::to_vec(&SubmissionDto {
                            version: 2,
                            request: Some(review.request.clone()),
                            debits: Some(review.debits.clone()),
                            phase: "sent".into(),
                            chain: review.request.chain(),
                            tx_id: Some(sent.tx_id.clone()),
                        })
                        .unwrap(),
                    )
                    .await
            }
            Err(e) if e.code == "submission_unknown" => Ok(()),
            Err(_) => self.platform.kv().delete(SUBMISSION).await,
        };
        self.submitting.store(false, Ordering::SeqCst);
        self.emit_submission();
        if persisted.is_err() {
            return Err(DesktopError::new(
                "submission_unknown",
                "Não foi possível salvar o resultado. Confira o histórico.",
            ));
        }
        result
    }
    pub async fn cleanup_locked(&self) {
        if self.unlocked.load(Ordering::SeqCst) {
            return;
        }
        let Ok(mut inner) = self.inner.try_lock() else {
            return;
        };
        if self.unlocked.load(Ordering::SeqCst) {
            return;
        }
        if let Some(app) = inner.app.take() {
            let _ = app.stop_and_wait().await;
            let _ = app.sideswap_disconnect().await;
        }
        inner.reviews.clear();
        self.swaps.lock().unwrap().clear();
    }
    pub async fn stop(&self) {
        if let Some(app) = self.inner.lock().await.app.as_ref() {
            let _ = app.stop().await;
        }
    }
}
fn send_request(r: &ReviewRequestDto) -> SendRequestDto {
    SendRequestDto {
        destination: r.destination.trim().into(),
        amount_sat: r.exact_amount().unwrap_or(0),
        asset_id: r.asset.asset_id.clone(),
        fee_priority: FeePriorityDto::Medium,
        label: None,
        subtract_fee_from_amount: false,
        fee_rate_override_sat_per_vbyte: Some(r.fee_rate_sat_per_vbyte),
        drain: matches!(r.amount, SendAmountDto::Max),
    }
}
fn check_safe(value: &serde_json::Value) -> Result<()> {
    match value {
        serde_json::Value::Number(n) => {
            if n.as_u64().is_some_and(|v| v > rules::MAX_SAFE)
                || n.as_i64()
                    .is_some_and(|v| v.unsigned_abs() > rules::MAX_SAFE)
            {
                return Err(DesktopError::new(
                    "unsupported_amount",
                    "Valor fora do intervalo permitido.",
                ));
            }
        }
        serde_json::Value::Array(a) => {
            for v in a {
                check_safe(v)?
            }
        }
        serde_json::Value::Object(o) => {
            for v in o.values() {
                check_safe(v)?
            }
        }
        _ => {}
    }
    Ok(())
}
#[cfg(test)]
mod tests;
