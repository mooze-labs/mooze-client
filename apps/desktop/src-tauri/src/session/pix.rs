use super::*;
const PIX_ATTEMPT: &str = "desktop/pix/createAttempt";
fn validate(request: &PixCreateRequestDto) -> Result<u64> {
    let amount = request
        .amount_in_cents
        .parse::<u64>()
        .ok()
        .filter(|n| rules::valid_amount(*n))
        .filter(|_| {
            !request.amount_in_cents.is_empty()
                && request.amount_in_cents.bytes().all(|b| b.is_ascii_digit())
        })
        .ok_or_else(|| DesktopError::new("invalid_input", "Informe um valor válido em reais."))?;
    if !matches!(
        mooze_core::domain::Asset::from_id(&request.asset_id),
        Some(
            mooze_core::domain::Asset::Lbtc
                | mooze_core::domain::Asset::Depix
                | mooze_core::domain::Asset::Usdt
        )
    ) {
        return Err(DesktopError::new(
            "invalid_input",
            "Ativo não suportado para Pix.",
        ));
    }
    if !mooze_app::rules::tax_id_is_valid(request.tax_id_number.clone()) {
        return Err(DesktopError::new(
            "invalid_input",
            "Informe um CPF ou CNPJ válido.",
        ));
    }
    Ok(amount)
}
impl<P: Platform + Clone> WalletSession<P> {
    pub async fn pix_create(&self, request: PixCreateRequestDto) -> Result<PixDepositViewDto> {
        let amount = validate(&request)?;
        let _gate = self
            .pix_gate
            .try_lock()
            .map_err(|_| DesktopError::new("busy", "Uma solicitação Pix já está em andamento."))?;
        let (generation, app) = self.service_app().await?;
        if self.backend_status().await?.state != "Ready" {
            return Err(DesktopError::new(
                "unavailable",
                "Conecte ao backend para usar Pix.",
            ));
        }
        self.same_generation(generation)?;
        if self.platform.kv().get(PIX_ATTEMPT).await?.is_some() {
            return Err(DesktopError::new(
                "pix_uncertain",
                "Confira a solicitação Pix anterior antes de criar outra.",
            ));
        }
        self.platform
            .kv()
            .put(PIX_ATTEMPT, b"pending".to_vec())
            .await?;
        self.same_generation(generation)?;
        let created = self
            .run_session_service(
                generation,
                app.pix_create_deposit(
                    amount,
                    request.asset_id,
                    Some(mooze_app::rules::tax_id_strip(request.tax_id_number)),
                    None,
                ),
            )
            .await?;
        // Only a durable returned deposit makes creation certain. A transport or local-storage
        // failure may follow server acceptance, so never automatically retry creation.
        match created {
            Ok(deposit) => {
                self.platform.kv().delete(PIX_ATTEMPT).await?;
                self.same_generation(generation)?;
                Ok(deposit.into())
            },
            Err(_) => Err(DesktopError::new("pix_uncertain", "Não foi possível confirmar a criação. Confira o histórico Pix antes de tentar novamente.")),
        }
    }
    pub async fn pix_history(&self) -> Result<PixHistoryDto> {
        let (generation, app) = self.service_app().await?;
        let _ = self.backend_status().await?;
        let _gate = self.pix_gate.lock().await;
        let deposits = self
            .run_session_service(generation, app.pix_history(Some(100), None))
            .await??
            .into_iter()
            .map(Into::into)
            .collect();
        let creation_uncertain = self.platform.kv().get(PIX_ATTEMPT).await?.is_some();
        self.same_generation(generation)?;
        Ok(PixHistoryDto {
            deposits,
            creation_uncertain,
        })
    }
    pub async fn pix_acknowledge_uncertain(&self) -> Result<()> {
        let _gate = self.pix_gate.lock().await;
        self.service_app().await?;
        self.platform.kv().delete(PIX_ATTEMPT).await?;
        Ok(())
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn validates_exact_cents_asset_and_tax_id() {
        let mut r = PixCreateRequestDto {
            amount_in_cents: "1234".into(),
            asset_id: mooze_core::domain::DEPIX_ASSET_ID.into(),
            tax_id_number: String::new(),
        };
        assert!(validate(&r).is_err(), "payer tax ID is required");
        r.tax_id_number = "52998224725".into();
        assert_eq!(validate(&r).unwrap(), 1234);
        for amount in ["0", "-1", "1.2", "9007199254740992", "18446744073709551616"] {
            r.amount_in_cents = amount.into();
            assert!(validate(&r).is_err());
        }
        r.amount_in_cents = "100".into();
        r.tax_id_number = "11111111111".into();
        assert!(validate(&r).is_err());
    }
}
