use super::*;
use mooze_app::dto::SideswapMarketDto;
pub(super) const SWAP_SUBMISSION: &str = "desktop/swap/submission/v1";
impl<P: Platform + Clone> WalletSession<P> {
    async fn swap_app(&self) -> Result<(u32, App<P>)> {
        let (generation, app) = self.service_app().await?;
        let key = self.services.sideswap_api_key.clone().ok_or_else(|| {
            DesktopError::new(
                "unavailable",
                "Configure SIDESWAP_API_KEY para usar trocas.",
            )
        })?;
        app.sideswap_connect(key, None).await?;
        self.same_generation(generation)?;
        Ok((generation, app))
    }
    pub async fn swap_markets(&self) -> Result<Vec<SideswapMarketDto>> {
        let (generation, app) = self.swap_app().await?;
        let markets = app.sideswap_markets().await?;
        self.same_generation(generation)?;
        Ok(markets
            .into_iter()
            .filter(|m| {
                [m.base_asset_id.as_str(), m.quote_asset_id.as_str()]
                    .iter()
                    .all(|id| {
                        mooze_core::domain::Asset::from_id(id)
                            .is_some_and(|a| !a.is_native_bitcoin())
                    })
            })
            .collect())
    }
    pub async fn swap_start(&self, request: SwapRequestDto) -> Result<SwapStateDto> {
        let _gate = self.swap_gate.lock().await;
        let amount = request
            .amount_units
            .parse::<u64>()
            .ok()
            .filter(|n| *n > 0)
            .filter(|_| request.amount_units.bytes().all(|b| b.is_ascii_digit()))
            .ok_or_else(|| DesktopError::new("invalid_input", "Informe uma quantidade válida."))?;
        let (generation, app) = self.swap_app().await?;
        if self.platform.kv().get(SWAP_SUBMISSION).await?.is_some()
            || self.submission().await?.is_some()
        {
            return Err(DesktopError::new(
                "submission_unknown",
                "Confira a operação anterior antes de trocar.",
            ));
        }
        let markets = self.swap_markets().await?;
        let market = markets
            .iter()
            .find(|m| {
                (m.base_asset_id == request.send_asset_id
                    && m.quote_asset_id == request.receive_asset_id)
                    || (m.quote_asset_id == request.send_asset_id
                        && m.base_asset_id == request.receive_asset_id)
            })
            .ok_or_else(|| DesktopError::new("invalid_input", "Par de ativos indisponível."))?;
        let fee_asset = match market.fee_asset.as_str() {
            "Base" => &market.base_asset_id,
            "Quote" => &market.quote_asset_id,
            _ => {
                return Err(DesktopError::new(
                    "unavailable",
                    "Moeda da taxa indisponível.",
                ))
            }
        }
        .clone();
        app.sideswap_stop_events().await?;
        self.swaps.lock().unwrap().clear();
        let started = app
            .sideswap_start_quote(
                request.send_asset_id.clone(),
                request.receive_asset_id.clone(),
                amount,
            )
            .await?;
        self.same_generation(generation)?;
        let subscription = started
            .quote_sub_id
            .filter(|_| started.started)
            .ok_or_else(|| DesktopError::new("busy", "Aguarde a cotação atual."))?;
        self.swaps
            .lock()
            .unwrap()
            .begin(request, generation, subscription, fee_asset);
        app.sideswap_start_events().await?;
        self.swap_status().await
    }
    pub async fn swap_status(&self) -> Result<SwapStateDto> {
        let generation = self.authorize()?;
        if let Some(raw) = self.platform.kv().get(SWAP_SUBMISSION).await? {
            let mut state: SwapStateDto = serde_json::from_slice(&raw)
                .map_err(|_| DesktopError::new("storage", "Resultado de troca inválido."))?;
            if state.phase == "Submitting" && !self.submitting.load(Ordering::SeqCst) {
                state.phase = "Uncertain".into();
            }
            self.same_generation(generation)?;
            return Ok(state);
        }
        Ok(self
            .swaps
            .lock()
            .unwrap()
            .view(self.platform.clock().now_ms()))
    }
    pub async fn swap_stop(&self) -> Result<()> {
        let _gate = self.swap_gate.lock().await;
        let (_, app) = self.service_app().await?;
        self.swaps.lock().unwrap().clear();
        app.sideswap_stop_events().await?;
        app.sideswap_stop_quote().await?;
        Ok(())
    }
    pub async fn swap_acknowledge(&self) -> Result<()> {
        let _inner = self.inner.lock().await;
        self.authorize()?;
        if self.swap_status().await?.phase != "Succeeded" {
            return Err(DesktopError::new(
                "submission_unknown",
                "Confira o resultado da troca antes de continuar.",
            ));
        }
        self.platform.kv().delete(SWAP_SUBMISSION).await?;
        self.swaps.lock().unwrap().clear();
        Ok(())
    }
    pub async fn swap_confirm(&self, review_id: String) -> Result<SwapStateDto> {
        let _gate = self.swap_gate.lock().await;
        let (generation, app) = self.swap_app().await?;
        let (quote_id, mut outcome, deadline) = {
            let _inner = self.inner.lock().await;
            self.same_generation(generation)?;
            if self.submitting.load(Ordering::SeqCst)
                || self.submission().await?.is_some()
                || self.platform.kv().get(SWAP_SUBMISSION).await?.is_some()
            {
                return Err(DesktopError::new(
                    "submission_unknown",
                    "Confira a operação anterior antes de trocar.",
                ));
            }
            let (id, state, deadline) = {
                let mut book = self.swaps.lock().unwrap();
                let id = book.take(&review_id, generation, self.platform.clock().now_ms())?;
                (
                    id,
                    book.view(self.platform.clock().now_ms()),
                    book.deadline().unwrap(),
                )
            };
            self.platform
                .kv()
                .put(SWAP_SUBMISSION, serde_json::to_vec(&state).unwrap())
                .await?;
            self.submitting.store(true, Ordering::SeqCst);
            (id, state, deadline)
        };
        let authorize = || {
            if self.authorize().ok() == Some(generation) && std::time::Instant::now() < deadline {
                Ok(())
            } else {
                Err(mooze_core::Error::Session(
                    "review expired or wallet locked".into(),
                ))
            }
        };
        let result = tokio::time::timeout(
            std::time::Duration::from_secs(60),
            app.sideswap_execute_swap_authorized(quote_id, &authorize),
        )
        .await;
        match result {
            Ok(Ok(txid)) => {
                outcome.phase = "Succeeded".into();
                outcome.txid = Some(txid);
            }
            Ok(Err(e)) if e.details.as_deref() != Some("submission_unknown") => {
                outcome.phase = "Failed".into();
                outcome.message =
                    Some("A troca não foi enviada. Solicite uma nova cotação.".into());
            }
            _ => {
                outcome.phase = "Uncertain".into();
                outcome.message = Some(
                    "A troca pode ter sido enviada. Confira o histórico; não repita a operação."
                        .into(),
                );
            }
        }
        let _inner = self.inner.lock().await;
        let persisted = if outcome.phase == "Failed" {
            self.platform.kv().delete(SWAP_SUBMISSION).await
        } else {
            self.platform
                .kv()
                .put(SWAP_SUBMISSION, serde_json::to_vec(&outcome).unwrap())
                .await
        };
        self.submitting.store(false, Ordering::SeqCst);
        self.swaps.lock().unwrap().clear();
        self.emit_submission();
        if persisted.is_err() {
            return Err(DesktopError::new(
                "submission_unknown",
                "Não foi possível salvar o resultado. Confira o histórico.",
            ));
        }
        // The result remains durable even if the initiating view was locked.
        self.same_generation(generation)?;
        Ok(outcome)
    }
}
