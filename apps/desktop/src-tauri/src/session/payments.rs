use super::*;
use mooze_core::payment_request::{self, ExactPaymentRequest};
impl<P: Platform + Clone> WalletSession<P> {
    pub fn parse_payment(&self, input: String) -> Result<ParsedPaymentDto> {
        self.authorize()?;
        let parsed = payment_request::parse(&input, crate::network::app_network())?;
        let chain = if parsed.chain == mooze_core::domain::ChainId::Bitcoin {
            WalletChain::Bitcoin
        } else {
            WalletChain::Liquid
        };
        let asset = if matches!(chain, WalletChain::Bitcoin) || parsed.asset_id.is_some() {
            Some(AssetKeyDto {
                chain: parsed.chain.into(),
                asset_id: parsed.asset_id,
            })
        } else {
            None
        };
        if asset.as_ref().is_some_and(|a| {
            !mooze_app::assets::asset_metadata(crate::network::network_dto(), a).approved
        }) {
            return Err(DesktopError::new(
                "unsupported_asset",
                "Este ativo não está aprovado para envio.",
            ));
        }
        Ok(ParsedPaymentDto {
            chain,
            address: parsed.address,
            asset,
            amount_units: parsed.amount_units.map(|v| v.to_string()),
            description: parsed.description,
        })
    }
    pub async fn receive_request(
        &self,
        asset: AssetKeyDto,
        amount_units: Option<String>,
        description: Option<String>,
    ) -> Result<ReceiveRequestDto> {
        let generation = self.authorize()?;
        if !mooze_app::assets::asset_metadata(crate::network::network_dto(), &asset).approved {
            return Err(DesktopError::new(
                "unsupported_asset",
                "Ativo não aprovado.",
            ));
        }
        let amount = amount_units
            .map(|v| {
                v.parse::<u64>()
                    .ok()
                    .filter(|n| *n > 0)
                    .ok_or_else(|| DesktopError::new("invalid_input", "Valor inválido."))
            })
            .transpose()?;
        if description.as_ref().is_some_and(|v| v.len() > 512) {
            return Err(DesktopError::new("invalid_input", "Descrição muito longa."));
        }
        let chain = if asset.chain == ChainDto::Bitcoin {
            WalletChain::Bitcoin
        } else {
            WalletChain::Liquid
        };
        let address = self
            .receive(chain)
            .await?
            .address
            .ok_or_else(|| DesktopError::new("invalid_input", "Endereço indisponível."))?;
        let request = ExactPaymentRequest {
            chain: asset.chain.into(),
            address: address.clone(),
            asset_id: asset.asset_id,
            amount_units: amount,
            description,
        };
        let uri = payment_request::encode(&request)?;
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(ReceiveRequestDto { address, uri })
    }
    pub async fn fee_options(&self, asset: AssetKeyDto) -> Result<FeeOptionsDto> {
        let generation = self.authorize()?;
        if !mooze_app::assets::asset_metadata(crate::network::network_dto(), &asset).approved {
            return Err(DesktopError::new(
                "unsupported_asset",
                "Ativo não aprovado.",
            ));
        }
        let app = self
            .inner
            .lock()
            .await
            .app
            .clone()
            .ok_or_else(|| DesktopError::new("locked", "Desbloqueie a carteira."))?;
        let (kind, source, rates) = if asset.chain == ChainDto::Liquid {
            ("configured", "Liquid", vec![0.1])
        } else {
            match app.desktop_fee_rates().await {
                Ok(rates) if !rates.is_empty() => ("live", "Nó Bitcoin", rates),
                _ => ("unavailable", "Nó Bitcoin", vec![]),
            }
        };
        if generation != self.authorize()? {
            return Err(DesktopError::new("locked", "Sessão alterada."));
        }
        Ok(FeeOptionsDto {
            kind: kind.into(),
            source: source.into(),
            rates,
            observed_at_ms: self.platform.clock().now_ms(),
        })
    }
}
