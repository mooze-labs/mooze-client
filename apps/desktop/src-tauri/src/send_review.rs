#[cfg(test)]
mod tests {
    use super::*;
    use crate::dto::{ReviewRequestDto, WalletChain};
    fn request() -> ReviewRequestDto {
        ReviewRequestDto {
            chain: WalletChain::Bitcoin,
            destination: "test".into(),
            amount_sat: 1000,
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
        let total = request
            .amount_sat
            .checked_add(fee)
            .filter(|v| *v <= crate::rules::MAX_SAFE)
            .ok_or_else(|| {
                DesktopError::new("unsupported_amount", "Valor fora do intervalo permitido.")
            })?;
        let review = SendReviewDto {
            id: uuid::Uuid::new_v4().to_string(),
            request,
            fee_sat: fee,
            total_sat: total,
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
