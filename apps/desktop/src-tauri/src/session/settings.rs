use super::*;
const SETTINGS: &str = "desktop/settings/v1";
impl<P: Platform + Clone> WalletSession<P> {
    pub(super) async fn load_settings(&self) -> Result<DesktopSettingsDto> {
        let settings: DesktopSettingsDto = match self.platform.kv().get(SETTINGS).await? {
            None => DesktopSettingsDto::default(),
            Some(raw) => serde_json::from_slice(&raw)
                .map_err(|_| DesktopError::new("storage", "Ajustes inválidos."))?,
        };
        if settings.version != 1 || ![1, 5, 15, 30, 60].contains(&settings.lock_minutes) {
            return Err(DesktopError::new("storage", "Ajustes inválidos."));
        }
        Ok(settings)
    }
    pub async fn settings(&self) -> Result<DesktopSettingsDto> {
        let generation = self.authorize()?;
        let settings = self.load_settings().await?;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(settings)
    }
    pub async fn set_lock_minutes(&self, minutes: u16) -> Result<DesktopSettingsDto> {
        let _inner = self.inner.lock().await;
        let generation = self.authorize()?;
        if ![1, 5, 15, 30, 60].contains(&minutes) {
            return Err(DesktopError::new("invalid_input", "Intervalo inválido."));
        }
        let mut settings = self.load_settings().await?;
        settings.lock_minutes = minutes;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        self.platform
            .kv()
            .put(SETTINGS, serde_json::to_vec(&settings).unwrap())
            .await?;
        {
            let mut idle = self.idle.lock().unwrap();
            if let Some((state, clock)) = idle.as_mut() {
                if let Some(now) = clock.elapsed_ms(self.platform.clock().now_ms()) {
                    state.set_interval(minutes, now);
                }
            }
        }
        self.check_expiry();
        Ok(settings)
    }
}

impl<P: Platform + Clone> WalletSession<P> {
    pub async fn save_display(
        &self,
        locale: String,
        bitcoin_unit: String,
        privacy: bool,
    ) -> Result<DesktopSettingsDto> {
        let _inner = self.inner.lock().await;
        let generation = self.authorize()?;
        if !["pt-BR", "en", "es"].contains(&locale.as_str())
            || !["BTC", "sat"].contains(&bitcoin_unit.as_str())
        {
            return Err(DesktopError::new(
                "invalid_input",
                "Preferências inválidas.",
            ));
        }
        let mut settings = self.load_settings().await?;
        settings.locale = locale;
        settings.bitcoin_unit = bitcoin_unit;
        settings.privacy = privacy;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        self.platform
            .kv()
            .put(SETTINGS, serde_json::to_vec(&settings).unwrap())
            .await?;
        Ok(settings)
    }
}

fn normalized_node(endpoint: &str) -> Result<String> {
    let value = mooze_core::wallet::backend::normalize_electrum_url(endpoint);
    let authority = value
        .strip_prefix("ssl://")
        .or_else(|| value.strip_prefix("tcp://"))
        .unwrap_or("");
    let valid = authority
        .rsplit_once(':')
        .is_some_and(|(host, port)| !host.is_empty() && port.parse::<u16>().is_ok_and(|p| p > 0));
    if !valid
        || authority
            .chars()
            .any(|c| c.is_whitespace() || "/@?#\\".contains(c))
        || authority.contains("://")
    {
        return Err(DesktopError::new(
            "invalid_input",
            "Use um nó Electrum no formato ssl://servidor:porta.",
        ));
    }
    Ok(value)
}
impl<P: Platform + Clone> WalletSession<P> {
    pub async fn test_node(&self, chain: WalletChain, endpoint: String) -> Result<String> {
        let generation = self.authorize()?;
        let endpoint = normalized_node(&endpoint)?;
        let spawner = self
            .platform
            .blocking()
            .ok_or_else(|| DesktopError::new("unsupported", "Electrum indisponível."))?;
        let config = mooze_core::wallet::ElectrumConfig::new(spawner);
        let chain = match chain {
            WalletChain::Bitcoin => mooze_core::domain::ChainId::Bitcoin,
            WalletChain::Liquid => mooze_core::domain::ChainId::Liquid,
        };
        let genesis = mooze_core::wallet::backend::probe_testnet_node(chain, &endpoint, &config)
            .await
            .map_err(|_| {
                DesktopError::new(
                    "invalid_node",
                    "Não foi possível verificar este nó na rede de teste selecionada.",
                )
            })?;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(genesis)
    }
    pub async fn save_node(
        &self,
        chain: WalletChain,
        endpoint: Option<String>,
        public_fallback: bool,
    ) -> Result<DesktopSettingsDto> {
        let mut inner = self.inner.lock().await;
        let generation = self.authorize()?;
        if self.submitting.load(Ordering::SeqCst) {
            return Err(DesktopError::new(
                "submission_unknown",
                "Aguarde o resultado do envio antes de alterar o nó.",
            ));
        }
        let mut next = self.load_settings().await?;
        let previous = next.clone();
        let endpoint = endpoint
            .filter(|value| !value.trim().is_empty())
            .map(|value| normalized_node(&value))
            .transpose()?;
        if let Some(value) = &endpoint {
            self.test_node(chain, value.clone()).await?;
        }
        match chain {
            WalletChain::Bitcoin => next.bitcoin_node = endpoint,
            WalletChain::Liquid => next.liquid_node = endpoint,
        };
        next.public_fallback = public_fallback;
        let credentials = CredentialStore::new(self.platform.secure(), AppNetwork::Testnet)
            .load()
            .await?;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        let old = inner
            .app
            .as_ref()
            .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?
            .clone();
        inner.reviews.clear();
        old.stop_and_wait().await?;
        // Drain all old wallet operations, including commands holding a cloned App.
        old.bitcoin_disconnect().await?;
        old.liquid_disconnect().await?;
        inner.app = None;
        let replacement = async {
            let app = self
                .connect_with_settings(credentials.mnemonic.clone(), &next)
                .await?;
            if generation != self.authorize()? {
                return Err(DesktopError::new("locked", "Sessão alterada."));
            }
            self.platform
                .kv()
                .put(SETTINGS, serde_json::to_vec(&next).unwrap())
                .await?;
            Ok::<_, DesktopError>(app)
        }
        .await;
        match replacement {
            Ok(app) => inner.app = Some(app),
            Err(error) => {
                // No new settings were persisted on these failure paths.
                match self
                    .connect_with_settings(credentials.mnemonic, &previous)
                    .await
                {
                    Ok(app) => inner.app = Some(app),
                    Err(restore_error) => {
                        let generation = {
                            let _transition = self.transition.lock().unwrap();
                            self.unlocked.store(false, Ordering::SeqCst);
                            self.generation.fetch_add(1, Ordering::SeqCst) + 1
                        };
                        self.emit_session(&SessionDto {
                            status: "locked".into(),
                            generation,
                            retry_after_ms: 0,
                        });
                        return Err(restore_error);
                    }
                }
                if let Some(app) = &inner.app {
                    app.start(StartConfigDto {
                        sync_tick_ms: None,
                        sync_timeout_ms: None,
                        startup_sync: true,
                        peg_wallet_id: None,
                    })
                    .await?;
                }
                return Err(error);
            }
        }
        *self.sync.lock().unwrap() = None;
        self.chains.lock().unwrap().clear();
        {
            let _transition = self.transition.lock().unwrap();
            self.generation.fetch_add(1, Ordering::SeqCst);
        }
        // Keep the existing idle deadline; reconfiguration is not an unlock.
        if let Some(app) = &inner.app {
            app.start(StartConfigDto {
                sync_tick_ms: None,
                sync_timeout_ms: None,
                startup_sync: true,
                peg_wallet_id: None,
            })
            .await?;
        }
        self.emit_session(&self.status().await?);
        Ok(next)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn node_input_does_not_accept_urls_with_paths_or_credentials() {
        assert_eq!(
            normalized_node("my.node:50002").unwrap(),
            "ssl://my.node:50002"
        );
        for value in [
            "https://my.node:50002",
            "ssl://user@my.node:50002",
            "ssl://my.node:50002/path",
            "tcp://host:0",
            "host",
            "tcp://host:65536",
        ] {
            assert!(normalized_node(value).is_err(), "{value}");
        }
    }
}
