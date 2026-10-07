use super::*;
use crate::native_auth::{
    attempt::{Attempt, AttemptState},
    NativeAuthenticator, NativeAvailability, NativeOutcome,
};
const ENABLED: &str = "desktop/nativeAuth/v1";

/// Lives through the OS request AND the authorization commit. If its receiver
/// disappears, the owned worker retains it until the native callback completes.
struct Verification {
    attempt: Attempt,
    state: Arc<StdMutex<AttemptState>>,
}
impl Drop for Verification {
    fn drop(&mut self) {
        self.state.lock().unwrap().finish(self.attempt.id);
    }
}
fn native_error(code: &str) -> DesktopError {
    DesktopError::new(
        code,
        match code {
            "native_cancelled" => "Autenticação cancelada.",
            "native_busy" => "Conclua a autenticação em andamento ou use o PIN da carteira.",
            "native_locked_out" => "Autenticação do dispositivo bloqueada. Use o PIN da carteira.",
            "native_disabled" => "Ative a autenticação do dispositivo nos ajustes.",
            "native_unavailable" => {
                "Autenticação do dispositivo indisponível. Use o PIN da carteira."
            }
            _ => "Não foi possível autenticar. Tente novamente ou use o PIN da carteira.",
        },
    )
}
fn reason(locale: &str) -> String {
    match locale {
        "en" => "unlock your Mooze wallet",
        "es" => "desbloquear tu cartera Mooze",
        _ => "desbloquear sua carteira Mooze",
    }
    .into()
}
impl<P: Platform + Clone> WalletSession<P> {
    pub fn with_native_authenticator(mut self, native: Arc<dyn NativeAuthenticator>) -> Self {
        self.native = native;
        self
    }
    async fn native_enabled(&self) -> Result<bool> {
        match self.platform.secure().get(ENABLED).await? {
            None => Ok(false),
            Some(value) if value == b"enabled-v1" => Ok(true),
            Some(value) if value == b"pending-v1" => Ok(false),
            Some(_) => Err(DesktopError::new(
                "storage",
                "Estado de autenticação inválido.",
            )),
        }
    }
    pub async fn native_auth_status(&self) -> Result<NativeAuthStatusDto> {
        let session = self.status().await?;
        let capabilities = self.native.capabilities().await;
        Ok(NativeAuthStatusDto {
            kind: capabilities.kind,
            availability: capabilities.availability,
            enabled: self.native_enabled().await?,
            setup_offer_pending: session.status == "unlocked"
                && *self.native_setup_generation.lock().unwrap() == Some(session.generation),
        })
    }
    pub fn cancel_native_auth(&self) -> Result<()> {
        let id = {
            let _transition = self.transition.lock().unwrap();
            self.native_attempt.lock().unwrap().invalidate()
        };
        if let Some(id) = id {
            self.native.cancel(id);
        }
        Ok(())
    }
    pub(super) fn validate_native_attempt(&self, attempt: Attempt) -> Result<()> {
        if self
            .native_attempt
            .lock()
            .unwrap()
            .accepts(attempt, self.generation.load(Ordering::SeqCst))
        {
            Ok(())
        } else {
            Err(native_error("native_cancelled"))
        }
    }
    fn begin_native(&self, generation: u32) -> Result<Verification> {
        let attempt = self
            .native_attempt
            .lock()
            .unwrap()
            .begin(generation)
            .map_err(native_error)?;
        Ok(Verification {
            attempt,
            state: self.native_attempt.clone(),
        })
    }
    async fn verify_native(&self, guard: Verification) -> Result<Verification> {
        let capabilities = self.native.capabilities().await;
        if capabilities.availability != NativeAvailability::Available {
            return Err(native_error("native_unavailable"));
        }
        let reason = reason(&self.load_settings().await?.locale);
        self.validate_native_attempt(guard.attempt)?;
        let attempt = guard.attempt;
        let native = self.native.clone();
        // Tokio's JoinHandle detaches on drop; the guard therefore outlives a cancelled IPC call.
        let (guard, outcome) = tokio::spawn(async move {
            let outcome = native.verify(attempt.id, reason).await;
            (guard, outcome)
        })
        .await
        .map_err(|_| native_error("native_failed"))?;
        self.validate_native_attempt(guard.attempt)?;
        match outcome {
            NativeOutcome::Verified => Ok(guard),
            NativeOutcome::Cancelled => Err(native_error("native_cancelled")),
            NativeOutcome::Unavailable => Err(native_error("native_unavailable")),
            NativeOutcome::LockedOut => Err(native_error("native_locked_out")),
            _ => Err(native_error("native_failed")),
        }
    }
    pub async fn unlock_native(&self) -> Result<SessionDto> {
        let guard = self.begin_native(self.generation.load(Ordering::SeqCst))?;
        let session = self.status().await?;
        if session.status != "locked" {
            return Err(DesktopError::new(
                "locked",
                "A carteira deve estar bloqueada.",
            ));
        }
        if !self.native_enabled().await? {
            return Err(native_error("native_disabled"));
        }
        let verification = self.verify_native(guard).await?;
        let mut inner = self.inner.lock().await;
        self.validate_native_attempt(verification.attempt)?;
        if !self.native_enabled().await?
            || self.platform.kv().get(REMOVAL).await?.is_some()
            || self.platform.kv().get(IMPORT).await? != Some(b"complete".to_vec())
        {
            return Err(native_error("native_disabled"));
        }
        self.load_and_open(&mut inner, session.generation, Some(verification.attempt))
            .await
    }
    pub async fn set_native_auth_enabled(
        self: &Arc<Self>,
        enabled: bool,
        pin: String,
    ) -> Result<NativeAuthStatusDto> {
        let guard = if enabled {
            Some(self.begin_native(self.generation.load(Ordering::SeqCst))?)
        } else {
            self.cancel_native_auth()?;
            None
        };
        let session = self.clone();
        // Own the entire transaction, including credential-store writes, even
        // when the IPC caller disappears while a blocking OS write is running.
        tokio::spawn(async move {
            let generation = {
                let _inner = session.inner.lock().await;
                let generation = session.authorize()?;
                session.verify_pin(&pin).await?;
                if generation != session.authorize()? {
                    return Err(native_error("native_cancelled"));
                }
                generation
            };
            session
                .change_native_preference(enabled, generation, guard)
                .await
        })
        .await
        .map_err(|_| native_error("native_failed"))?
    }
    pub async fn complete_native_auth_offer(
        self: &Arc<Self>,
        enable: bool,
    ) -> Result<NativeAuthStatusDto> {
        let generation = self.authorize()?;
        if *self.native_setup_generation.lock().unwrap() != Some(generation) {
            return Err(native_error("native_cancelled"));
        }
        if !enable {
            self.cancel_native_auth()?;
            *self.native_setup_generation.lock().unwrap() = None;
            return self.native_auth_status().await;
        }
        let guard = self.begin_native(generation)?;
        let session = self.clone();
        tokio::spawn(async move {
            session
                .change_native_preference(true, generation, Some(guard))
                .await
        })
        .await
        .map_err(|_| native_error("native_failed"))?
    }
    /// Linearization point for enrollment: after a durable DISABLED pending
    /// marker, atomically accept the fresh native proof. Cancellation before
    /// this check cannot enable access. After acceptance, the owned worker
    /// completes its final write; disable/removal serialize behind `inner`.
    fn commit_native_preference(
        &self,
        generation: u32,
        verification: Option<&Verification>,
    ) -> Result<()> {
        let _transition = self.transition.lock().unwrap();
        let live = self
            .idle
            .lock()
            .unwrap()
            .as_mut()
            .is_some_and(|(state, clock)| {
                clock
                    .elapsed_ms(self.platform.clock().now_ms())
                    .is_some_and(|now| !state.expired(now))
            });
        if !live
            || !self.unlocked.load(Ordering::SeqCst)
            || self.generation.load(Ordering::SeqCst) != generation
        {
            return Err(native_error("native_cancelled"));
        }
        if let Some(v) = verification {
            self.validate_native_attempt(v.attempt)?;
        }
        Ok(())
    }
    async fn change_native_preference(
        &self,
        enabled: bool,
        generation: u32,
        guard: Option<Verification>,
    ) -> Result<NativeAuthStatusDto> {
        let verification = if let Some(guard) = guard {
            Some(self.verify_native(guard).await?)
        } else {
            None
        };
        {
            let _inner = self.inner.lock().await;
            if generation != self.authorize()? {
                return Err(native_error("native_cancelled"));
            }
            if let Some(v) = &verification {
                self.validate_native_attempt(v.attempt)?;
            }
            let was_enabled = self.native_enabled().await?;
            if enabled && !was_enabled {
                // A crash, cancelled enrollment, or failed final write leaves
                // this marker disabled. No rollback deletion is required.
                self.platform
                    .secure()
                    .put(ENABLED, b"pending-v1".to_vec())
                    .await?;
            }
            self.commit_native_preference(generation, verification.as_ref())?;
            if enabled && !was_enabled {
                self.platform
                    .secure()
                    .put(ENABLED, b"enabled-v1".to_vec())
                    .await?;
            } else if !enabled {
                self.platform.secure().delete(ENABLED).await?;
            }
            let mut grant = self.native_setup_generation.lock().unwrap();
            if *grant == Some(generation) {
                *grant = None;
            }
        }
        self.native_auth_status().await
    }
}
