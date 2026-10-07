use super::*;

// Public application key shared with the mobile client. Native overrides remain available.
const DEFAULT_SIDESWAP_API_KEY: &str =
    "5c85504bf60e13e0d58614cb9ed86cb2c163cfa402fb3a9e63cf76c7a7af46a1";

#[derive(Clone, Default)]
pub struct ServiceConfig {
    pub api_base_url: Option<String>,
    pub sideswap_api_key: Option<String>,
}
impl ServiceConfig {
    pub fn from_env() -> Self {
        Self {
            api_base_url: std::env::var("MOOZE_BACKEND_API_URL").ok(),
            sideswap_api_key: resolve_sideswap_api_key(
                std::env::var("SIDESWAP_API_KEY").ok().as_deref(),
                option_env!("SIDESWAP_API_KEY"),
            ),
        }
    }
    pub fn api_url(&self) -> Result<String> {
        let raw = self
            .api_base_url
            .as_deref()
            .unwrap_or(mooze_core::api::DEFAULT_BASE_URL)
            .trim_end_matches('/');
        let url = tauri::Url::parse(raw)
            .map_err(|_| DesktopError::new("configuration", "URL do backend inválida."))?;
        if url.scheme() != "https"
            || url.host_str().is_none()
            || !url.username().is_empty()
            || url.password().is_some()
            || url.query().is_some()
            || url.fragment().is_some()
        {
            return Err(DesktopError::new(
                "configuration",
                "Use uma URL HTTPS válida para o backend.",
            ));
        }
        Ok(url.as_str().trim_end_matches('/').to_owned())
    }
}
impl<P: Platform + Clone> WalletSession<P> {
    pub fn with_services(mut self, config: ServiceConfig) -> Self {
        self.services = config;
        self
    }
    pub(super) async fn service_app(&self) -> Result<(u32, App<P>)> {
        let generation = self.authorize()?;
        if !crate::network::production_services_enabled() {
            return Err(DesktopError::new(
                "unavailable",
                "Este serviço está disponível apenas na mainnet.",
            ));
        }
        let app = self
            .inner
            .lock()
            .await
            .app
            .clone()
            .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?;
        self.same_generation(generation)?;
        Ok((generation, app))
    }
    pub(super) fn same_generation(&self, expected: u32) -> Result<()> {
        if self.authorize()? != expected {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(())
    }
    // Auth is a single caller-owned future. Each poll is serialized with session transitions:
    // a delayed HTTP/storage response cannot resume signing or persistence after a lock.
    // A timer wakes pending operations so cancellation also drops stalled transports promptly.
    pub(super) async fn run_session_service<F: std::future::Future>(
        &self,
        expected: u32,
        operation: F,
    ) -> Result<F::Output> {
        let mut operation = std::pin::pin!(operation);
        let mut cancellation_tick = tokio::time::interval(std::time::Duration::from_millis(100));
        std::future::poll_fn(|cx| {
            while cancellation_tick.poll_tick(cx).is_ready() {}
            self.same_generation(expected)?;
            let _transition = self.transition.lock().unwrap();
            if !self.unlocked.load(Ordering::SeqCst)
                || self.generation.load(Ordering::SeqCst) != expected
            {
                return std::task::Poll::Ready(Err(DesktopError::new(
                    "locked",
                    "Sessão alterada.",
                )));
            }
            operation.as_mut().poll(cx).map(Ok)
        })
        .await
    }
    pub async fn backend_status(&self) -> Result<BackendSessionDto> {
        let generation = self.authorize()?;
        if let Some((g, state)) = &*self.backend_state.lock().await {
            if *g == generation {
                return Ok(state.clone());
            }
        }
        self.backend_retry().await
    }
    pub async fn backend_retry(&self) -> Result<BackendSessionDto> {
        let generation = self.authorize()?;
        if !crate::network::production_services_enabled() {
            return Ok(BackendSessionDto {
                state: "Disabled".into(),
                retryable: false,
            });
        }
        let (_, app) = self.service_app().await?;
        let mut state = self.backend_state.lock().await;
        self.same_generation(generation)?;
        let ready = self
            .run_session_service(generation, async {
                // URL changes must never forward credentials minted by another backend.
                let url = self.services.api_url()?;
                let secure = self.platform.secure();
                if secure.get("desktop/authOrigin").await?.as_deref() != Some(url.as_bytes()) {
                    app.auth_invalidate().await?;
                    app.auth_reset().await?;
                    secure
                        .put("desktop/authOrigin", url.as_bytes().to_vec())
                        .await?;
                }
                Ok::<_, DesktopError>(matches!(
                    app.auth_ensure_session().await,
                    Ok(AuthEnsureDto {
                        kind: AuthEnsureKind::Ready,
                        ..
                    })
                ))
            })
            .await??;
        self.same_generation(generation)?;
        let out = BackendSessionDto {
            state: if ready { "Ready" } else { "Unavailable" }.into(),
            retryable: !ready,
        };
        *state = Some((generation, out.clone()));
        Ok(out)
    }
}

fn resolve_sideswap_api_key(runtime: Option<&str>, build: Option<&str>) -> Option<String> {
    runtime
        .or(build)
        .or(Some(DEFAULT_SIDESWAP_API_KEY))
        .filter(|key| !key.trim().is_empty())
        .map(str::to_owned)
}

#[cfg(test)]
mod config_tests {
    use super::*;
    #[test]
    fn desktop_embeds_the_same_default_key_as_mobile() {
        let key = resolve_sideswap_api_key(None, None).expect("desktop must ship a default key");
        let mobile = include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../../mobile/lib/features/swap/data/services/core_sideswap_session.dart"
        ));
        assert!(mobile.contains(&format!("'{}'", key)));
    }
    #[test]
    fn explicit_overrides_take_precedence_and_empty_runtime_disables_swaps() {
        assert_eq!(
            resolve_sideswap_api_key(Some("runtime"), Some("build")).as_deref(),
            Some("runtime")
        );
        assert_eq!(
            resolve_sideswap_api_key(None, Some("build")).as_deref(),
            Some("build")
        );
        assert_eq!(resolve_sideswap_api_key(Some(" "), Some("build")), None);
    }
}
