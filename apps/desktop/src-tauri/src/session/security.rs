use super::*;
impl<P: Platform + Clone> WalletSession<P> {
    pub(super) async fn verify_pin(&self, pin: &str) -> Result<()> {
        if !rules::valid_pin(pin) {
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
        if !pins.authenticate(pin).await? {
            if pins.attempts().await? >= 5 {
                self.platform
                    .kv()
                    .put(RETRY, serde_json::to_vec(&(now + 30_000)).unwrap())
                    .await?;
            }
            return Err(DesktopError::new("invalid_input", "PIN incorreto."));
        }
        Ok(())
    }
    pub async fn reveal_recovery_phrase(&self, pin: String) -> Result<Vec<String>> {
        let _inner = self.inner.lock().await;
        let generation = self.authorize()?;
        self.verify_pin(&pin).await?;
        let credentials = CredentialStore::new(self.platform.secure(), AppNetwork::Testnet)
            .load()
            .await?;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(credentials
            .mnemonic
            .split_whitespace()
            .map(str::to_owned)
            .collect())
    }
    pub async fn change_pin(&self, current_pin: String, new_pin: String) -> Result<()> {
        let _inner = self.inner.lock().await;
        let generation = self.authorize()?;
        if !rules::valid_pin(&new_pin) {
            return Err(DesktopError::new(
                "invalid_input",
                "Use um PIN de 6 dígitos.",
            ));
        }
        self.verify_pin(&current_pin).await?;
        let salt = self
            .platform
            .secure()
            .get("pinSalt")
            .await?
            .ok_or_else(|| DesktopError::new("storage", "PIN indisponível."))?;
        let salt =
            String::from_utf8(salt).map_err(|_| DesktopError::new("storage", "PIN inválido."))?;
        let hash = mooze_core::auth::hash_pin(&new_pin, &salt);
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        // A single atomic credential-map update preserves the old PIN on failure.
        self.platform
            .secure()
            .put("hashedPin", hash.into_bytes())
            .await?;
        Ok(())
    }
}

impl<P: Platform + Clone> WalletSession<P> {
    pub async fn remove_wallet(&self, pin: String) -> Result<()> {
        let mut inner = self.inner.lock().await;
        if self.submitting.load(Ordering::SeqCst) {
            return Err(DesktopError::new(
                "submission_unknown",
                "Aguarde o resultado do envio antes de remover a carteira.",
            ));
        }
        let marker = self.platform.kv().get(REMOVAL).await?;
        if marker.as_ref().is_some_and(|v| v != b"authorized-v1") {
            return Err(DesktopError::new("storage", "Estado de remoção inválido."));
        }
        if marker.is_none() {
            let generation = self.authorize()?;
            self.verify_pin(&pin).await?;
            if generation != self.authorize()? {
                return Err(DesktopError::new("locked", "Sessão alterada."));
            }
            // Durable authorization of this one destructive operation; retained until cleanup finishes.
            self.platform
                .kv()
                .put(REMOVAL, b"authorized-v1".to_vec())
                .await?;
        }
        {
            let _transition = self.transition.lock().unwrap();
            self.unlocked.store(false, Ordering::SeqCst);
            self.generation.fetch_add(1, Ordering::SeqCst);
        }
        inner.reviews.clear();
        *self.setup.lock().unwrap() = None;
        self.emit_session(&SessionDto {
            status: "removal_pending".into(),
            generation: self.generation.load(Ordering::SeqCst),
            retry_after_ms: 0,
        });
        if let Some(app) = &inner.app {
            app.stop_and_wait().await?;
            app.bitcoin_disconnect().await?;
            app.liquid_disconnect().await?;
        }
        inner.app = None;
        // These stores are scoped by NativePlatform to this wallet's own namespace.
        for key in self.platform.secure().list_keys("").await? {
            self.platform.secure().delete(&key).await?;
        }
        for key in self.platform.kv().list_keys("").await? {
            if key != REMOVAL {
                self.platform.kv().delete(&key).await?;
            }
        }
        self.platform.kv().delete(REMOVAL).await?;
        self.configured.store(false, Ordering::SeqCst);
        *self.idle.lock().unwrap() = None;
        *self.sync.lock().unwrap() = None;
        self.chains.lock().unwrap().clear();
        self.emit_session(&SessionDto {
            status: "empty".into(),
            generation: self.generation.load(Ordering::SeqCst),
            retry_after_ms: 0,
        });
        Ok(())
    }
}
