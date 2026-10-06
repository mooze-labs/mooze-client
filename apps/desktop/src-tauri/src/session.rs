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
    domain::{AppNetwork, WalletCredentials},
    ports::{Clock, KvStore},
    store::CredentialStore,
    wallet::mnemonic,
};
use std::sync::{
    atomic::{AtomicBool, AtomicU32, Ordering},
    Arc, Mutex as StdMutex,
};
use tokio::sync::Mutex;
const IMPORT: &str = "desktop/import";
const SUBMISSION: &str = "desktop/submission";
const RETRY: &str = "desktop/pinRetryAt";
pub type EventCallback = Arc<dyn Fn(serde_json::Value) + Send + Sync>;
struct Inner<P: Platform> {
    app: Option<App<P>>,
    reviews: ReviewBook,
}
pub struct WalletSession<P: Platform> {
    pub platform: P,
    backend: BackendDto,
    inner: Mutex<Inner<P>>,
    transition: StdMutex<()>,
    configured: AtomicBool,
    submitting: AtomicBool,
    unlocked: Arc<AtomicBool>,
    generation: Arc<AtomicU32>,
    sync: Arc<StdMutex<Option<SyncStateDto>>>,
    chains: Arc<StdMutex<Vec<ChainStateDto>>>,
    emit: Arc<StdMutex<Option<EventCallback>>>,
}
struct Sink {
    unlocked: Arc<AtomicBool>,
    generation: Arc<AtomicU32>,
    sync: Arc<StdMutex<Option<SyncStateDto>>>,
    chains: Arc<StdMutex<Vec<ChainStateDto>>>,
    emit: Arc<StdMutex<Option<EventCallback>>>,
}
impl EventSink for Sink {
    fn send(&self, event: AppEvent) -> bool {
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
        if self.unlocked.load(Ordering::SeqCst) {
            if let Some(callback) = self.emit.lock().unwrap().as_ref() {
                callback(
                    serde_json::json!({"type":"core","generation":self.generation.load(Ordering::SeqCst),"data":event}),
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
            backend,
            inner: Mutex::new(Inner {
                app: None,
                reviews: ReviewBook::default(),
            }),
            transition: StdMutex::new(()),
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
        let complete = self.platform.kv().get(IMPORT).await? == Some(b"complete".to_vec());
        self.configured.store(complete, Ordering::SeqCst);
        Ok(SessionDto {
            status: if self.unlocked.load(Ordering::SeqCst) {
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
    fn authorize(&self) -> Result<u32> {
        if !self.unlocked.load(Ordering::SeqCst) {
            return Err(DesktopError::new("locked", "Desbloqueie a carteira."));
        }
        Ok(self.generation.load(Ordering::SeqCst))
    }
    async fn connect(&self, phrase: String) -> Result<App<P>> {
        let app = App::open(
            AppConfig {
                network: NetworkDto::Testnet,
                backend: self.backend,
                bitcoin_node_url: String::new(),
                liquid_node_url: String::new(),
                api_base_url: None,
            },
            self.platform_clone(),
        )
        .await?;
        app.bitcoin_connect(phrase.clone()).await?;
        app.liquid_connect(phrase).await?;
        app.subscribe(Box::new(Sink {
            unlocked: self.unlocked.clone(),
            generation: self.generation.clone(),
            sync: self.sync.clone(),
            chains: self.chains.clone(),
            emit: self.emit.clone(),
        }));
        Ok(app)
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
            CredentialStore::new(self.platform.secure(), AppNetwork::Testnet)
                .save(&WalletCredentials {
                    mnemonic: phrase,
                    network: AppNetwork::Testnet,
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
        self.open_session(&mut inner, expected).await
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
        let mut inner = self.inner.lock().await;
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
        let now = self.platform.clock().now_ms();
        let retry = self.retry_at().await?;
        if retry > now {
            return Err(DesktopError::new(
                "rate_limited",
                "Aguarde 30 segundos antes de tentar novamente.",
            ));
        }
        if retry > 0 {
            self.platform.kv().delete(RETRY).await?;
            self.platform.kv().put("pinAttempts", b"0".to_vec()).await?;
        }
        let pins = PinService::new(
            self.platform.secure(),
            self.platform.kv(),
            self.platform.clock(),
        );
        if !pins.authenticate(&pin).await? {
            if pins.attempts().await? >= 5 {
                self.platform
                    .kv()
                    .put(RETRY, serde_json::to_vec(&(now + 30_000)).unwrap())
                    .await?;
            }
            return Err(DesktopError::new("invalid_input", "PIN incorreto."));
        }
        if inner.app.is_none() {
            let credentials = CredentialStore::new(self.platform.secure(), AppNetwork::Testnet)
                .load()
                .await?;
            inner.app = Some(self.connect(credentials.mnemonic).await?);
        }
        self.open_session(&mut inner, expected).await
    }
    async fn open_session(&self, inner: &mut Inner<P>, expected: u32) -> Result<SessionDto> {
        {
            let _transition = self.transition.lock().unwrap();
            if self.generation.load(Ordering::SeqCst) != expected {
                return Err(DesktopError::new(
                    "locked",
                    "A carteira foi bloqueada. Desbloqueie para continuar.",
                ));
            }
            self.generation.fetch_add(1, Ordering::SeqCst);
            inner.reviews.clear();
            self.unlocked.store(true, Ordering::SeqCst);
        }
        if let Some(app) = &inner.app {
            if let Err(e) = async {
                app.session_unlocked().await?;
                app.start(StartConfigDto {
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
        let (bitcoin, liquid) = tokio::try_join!(app.bitcoin_balance(), app.liquid_balance())?;
        let mut transactions = app.bitcoin_transactions().await?;
        transactions.extend(app.liquid_transactions().await?);
        transactions.sort_by(|a, b| b.timestamp_ms.cmp(&a.timestamp_ms));
        let submission = self.submission().await?;
        if self.authorize()? != generation {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        let snapshot = DesktopSnapshotDto {
            submission,
            bitcoin,
            liquid,
            transactions,
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
    pub async fn review(&self, request: ReviewRequestDto) -> Result<SendReviewDto> {
        let generation = self.authorize()?;
        if !rules::valid_amount(request.amount_sat)
            || !rules::valid_rate(request.fee_rate_sat_per_vbyte)
            || request.destination.trim().is_empty()
        {
            return Err(DesktopError::new(
                "invalid_input",
                "Confira o endereço, valor e taxa.",
            ));
        }
        let mut inner = self.inner.lock().await;
        if self.submission().await?.is_some() {
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
        let dto = send_request(&request);
        let fee = match request.chain {
            WalletChain::Bitcoin => app.bitcoin_estimate_fee(dto).await?,
            WalletChain::Liquid => app.liquid_estimate_fee(dto).await?,
        };
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        inner.reviews.insert(
            request,
            fee.absolute_fee_sat,
            generation,
            self.platform.clock().now_ms(),
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
            if self.submission().await?.is_some() {
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
                phase: "submitting".into(),
                chain: review.request.chain,
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
        let request = send_request(&review.request);
        let authorize = || {
            if self.unlocked.load(Ordering::SeqCst)
                && self.generation.load(Ordering::SeqCst) == generation
            {
                Ok(())
            } else {
                Err(mooze_core::Error::Session("locked".into()))
            }
        };
        let result = match review.request.chain {
            WalletChain::Bitcoin => {
                app.bitcoin_send_authorized(request, review.fee_sat, authorize)
                    .await
            }
            WalletChain::Liquid => {
                app.liquid_send_authorized(request, review.fee_sat, authorize)
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
                            phase: "sent".into(),
                            chain: review.request.chain,
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
    pub async fn stop(&self) {
        if let Some(app) = self.inner.lock().await.app.as_ref() {
            let _ = app.stop().await;
        }
    }
}
fn send_request(r: &ReviewRequestDto) -> SendRequestDto {
    SendRequestDto {
        destination: r.destination.trim().into(),
        amount_sat: r.amount_sat,
        asset_id: None,
        fee_priority: FeePriorityDto::Medium,
        label: None,
        subtract_fee_from_amount: false,
        fee_rate_override_sat_per_vbyte: Some(r.fee_rate_sat_per_vbyte),
        drain: false,
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
