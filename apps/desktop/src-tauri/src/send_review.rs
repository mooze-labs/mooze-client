#[cfg(test)]
mod tests {
    use super::*;
    use crate::dto::ReviewRequestDto;
    fn request() -> ReviewRequestDto {
        ReviewRequestDto {
            asset: mooze_app::dto::AssetKeyDto {
                chain: mooze_app::dto::ChainDto::Bitcoin,
                asset_id: None,
            },
            destination: "test".into(),
            amount: crate::dto::SendAmountDto::Exact("1000".into()),
            fee_rate_sat_per_vbyte: 1.,
        }
    }
    #[test]
    fn expiry_reuse_and_generation_are_enforced() {
        let mut book = ReviewBook::default();
        let r = book.insert(request(), 100, 2, 1000).unwrap();
        assert!(book.take(&r.id, 2, 60999).is_ok());
        assert!(book.take(&r.id, 2, 60999).is_err());
        let r = book.insert(request(), 100, 2, 1000).unwrap();
        assert!(book.take(&r.id, 2, 61000).is_err());
        let r = book.insert(request(), 100, 2, 1000).unwrap();
        assert!(book.take(&r.id, 3, 1001).is_err());
    }
}
use crate::{
    dto::{ReviewRequestDto, SendReviewDto},
    error::{DesktopError, Result},
};
#[derive(Default)]
pub struct ReviewBook {
    active: Option<(SendReviewDto, std::time::Instant)>,
}
impl ReviewBook {
    pub fn insert(
        &mut self,
        request: ReviewRequestDto,
        fee: u64,
        generation: u32,
        now: u64,
    ) -> Result<SendReviewDto> {
        self.insert_resolved(request, fee, generation, now, false)
    }
    pub fn insert_resolved(
        &mut self,
        request: ReviewRequestDto,
        fee: u64,
        generation: u32,
        now: u64,
        is_max: bool,
    ) -> Result<SendReviewDto> {
        if fee > crate::rules::MAX_SAFE {
            return Err(DesktopError::new(
                "unsupported_amount",
                "Valor fora do intervalo permitido.",
            ));
        }
        let amount = request
            .exact_amount()
            .ok_or_else(|| DesktopError::new("invalid_input", "Revise um valor exato."))?;
        let fee_asset = mooze_app::dto::AssetKeyDto {
            chain: request.asset.chain,
            asset_id: if request.asset.chain == mooze_app::dto::ChainDto::Liquid {
                Some(mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET.into())
            } else {
                None
            },
        };
        let mut debits = vec![mooze_app::dto::AssetAmountDto {
            asset: request.asset.clone(),
            units: amount.to_string(),
        }];
        if request.asset == fee_asset {
            debits[0].units = amount
                .checked_add(fee)
                .ok_or_else(|| {
                    DesktopError::new("unsupported_amount", "Valor fora do intervalo permitido.")
                })?
                .to_string();
        } else {
            debits.push(mooze_app::dto::AssetAmountDto {
                asset: fee_asset,
                units: fee.to_string(),
            });
        }
        let review = SendReviewDto {
            is_max,
            id: uuid::Uuid::new_v4().to_string(),
            request,
            fee_sat: fee,
            debits,
            expires_at_ms: now + 60_000,
            generation,
        };
        self.active = Some((review.clone(), std::time::Instant::now()));
        Ok(review)
    }
    pub fn clear(&mut self) {
        self.active = None;
    }
    pub fn take(&mut self, id: &str, generation: u32, now: u64) -> Result<SendReviewDto> {
        let (r, created) = self.active.take().ok_or_else(|| {
            DesktopError::new("already_submitted", "Revise a transação novamente.")
        })?;
        if created.elapsed() >= std::time::Duration::from_secs(60)
            || r.id != id
            || r.generation != generation
            || now >= r.expires_at_ms
        {
            return Err(DesktopError::new(
                "review_expired",
                "A revisão expirou. Revise novamente.",
            ));
        }
        Ok(r)
    }
}

#[cfg(test)]
mod asset_tests {
    use super::*;
    use crate::dto::SendAmountDto;
    use mooze_app::dto::{AssetKeyDto, ChainDto};
    #[test]
    fn test_debit_and_fee_never_add_unlike_units() {
        let request = ReviewRequestDto {
            asset: AssetKeyDto {
                chain: ChainDto::Liquid,
                asset_id: Some(mooze_app::assets::TEST_ASSET_ID.into()),
            },
            destination: "test".into(),
            amount: SendAmountDto::Exact("100000000".into()),
            fee_rate_sat_per_vbyte: 0.1,
        };
        let review = ReviewBook::default().insert(request, 100, 1, 0).unwrap();
        assert_eq!(review.debits.len(), 2);
        assert_eq!(review.debits[0].units, "100000000");
        assert_eq!(review.debits[1].units, "100");
        assert_ne!(review.debits[0].asset, review.debits[1].asset);
    }
}

#[cfg(test)]
mod precision_tests {
    use super::*;
    #[test]
    fn numeric_fee_does_not_cross_javascript_precision_boundary() {
        let request = ReviewRequestDto {
            asset: mooze_app::dto::AssetKeyDto {
                chain: mooze_app::dto::ChainDto::Bitcoin,
                asset_id: None,
            },
            destination: "test".into(),
            amount: crate::dto::SendAmountDto::Exact("1".into()),
            fee_rate_sat_per_vbyte: 1.0,
        };
        assert!(ReviewBook::default()
            .insert(request, crate::rules::MAX_SAFE + 1, 1, 0)
            .is_err());
    }
}
