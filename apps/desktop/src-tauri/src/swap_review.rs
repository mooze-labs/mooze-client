#[cfg(test)]
mod tests {
    use super::*;
    use mooze_app::dto::*;
    fn request() -> crate::dto::SwapRequestDto {
        crate::dto::SwapRequestDto {
            send_asset_id: "quote".into(),
            receive_asset_id: "base".into(),
            amount_units: "100".into(),
        }
    }
    fn quote() -> QuoteDto {
        QuoteDto {
            status: QuoteStatusDto::Success,
            quote_id: Some(9),
            base_amount: Some(200),
            quote_amount: Some(100),
            server_fee: Some(2),
            fixed_fee: Some(1),
            ttl_ms: Some(1000),
            available: None,
            error_message: None,
            quote_sub_id: Some(5),
            requested_amount: Some(100),
            base_asset_id: Some("base".into()),
            quote_asset_id: Some("quote".into()),
        }
    }
    #[test]
    fn inverse_market_review_is_exact_and_single_use() {
        let mut book = SwapBook::default();
        book.begin(request(), 3, 5, "base".into());
        book.quote(&quote(), 3, 100);
        let review = book.view(100).review.unwrap();
        assert_eq!(review.send_units, "100");
        assert_eq!(review.receive_units, "200");
        assert_eq!(review.fees[0].asset.asset_id.as_deref(), Some("base"));
        assert_eq!(book.take(&review.id, 3, 101).unwrap(), 9);
        assert!(book.take(&review.id, 3, 102).is_err());
    }
    #[test]
    fn expiry_replacement_and_generation_invalidate_confirmation() {
        let mut book = SwapBook::default();
        book.begin(request(), 3, 5, "base".into());
        book.quote(&quote(), 3, 100);
        let first = book.view(100).review.unwrap();
        let mut next = quote();
        next.quote_id = Some(10);
        book.quote(&next, 3, 200);
        assert!(book.take(&first.id, 3, 201).is_err());
        let second = book.view(200).review.unwrap();
        assert!(book.take(&second.id, 4, 201).is_err());
        assert!(book.take(&second.id, 3, 1200).is_err());
    }
}

use crate::{
    dto::*,
    error::{DesktopError, Result},
};
use mooze_app::dto::{AssetAmountDto, AssetKeyDto, ChainDto, QuoteDto, QuoteStatusDto};
use std::time::{Duration, Instant};
pub struct SwapBook {
    state: SwapStateDto,
    intent: Option<(SwapRequestDto, u32, u64, String)>,
    quote_id: Option<u64>,
    deadline: Option<Instant>,
}
impl Default for SwapBook {
    fn default() -> Self {
        Self {
            state: SwapStateDto::phase("Idle"),
            intent: None,
            quote_id: None,
            deadline: None,
        }
    }
}
impl SwapBook {
    pub fn begin(
        &mut self,
        request: SwapRequestDto,
        generation: u32,
        subscription: u64,
        fee_asset: String,
    ) {
        *self = Self::default();
        self.state.phase = "Quoting".into();
        self.intent = Some((request, generation, subscription, fee_asset));
    }
    pub fn clear(&mut self) {
        *self = Self::default();
    }
    pub fn disconnected(&mut self) {
        if self.state.phase != "Submitting" {
            self.clear();
            self.state.phase = "Failed".into();
            self.state.message =
                Some("A conexão da cotação foi encerrada. Solicite uma nova cotação.".into());
        }
    }
    pub fn quote(&mut self, q: &QuoteDto, generation: u32, now: u64) {
        if self.state.phase == "Submitting" {
            return;
        }
        let Some((request, expected, subscription, fee_asset)) = &self.intent else {
            return;
        };
        if *expected != generation || q.quote_sub_id != Some(*subscription) {
            return;
        }
        if q.status != QuoteStatusDto::Success {
            self.state = SwapStateDto::phase("Failed");
            self.state.message =
                Some("Cotação indisponível. Confira o saldo e tente novamente.".into());
            self.quote_id = None;
            return;
        }
        let (
            Some(id),
            Some(base),
            Some(quote),
            Some(base_id),
            Some(quote_asset),
            Some(ttl),
            Some(server_fee),
            Some(fixed_fee),
        ) = (
            q.quote_id,
            q.base_amount,
            q.quote_amount,
            q.base_asset_id.as_ref(),
            q.quote_asset_id.as_ref(),
            q.ttl_ms,
            q.server_fee,
            q.fixed_fee,
        )
        else {
            return;
        };
        let pair_matches = (&request.send_asset_id == base_id
            && &request.receive_asset_id == quote_asset)
            || (&request.send_asset_id == quote_asset && &request.receive_asset_id == base_id);
        let (send, receive) = if &request.send_asset_id == base_id {
            (base, quote)
        } else {
            (quote, base)
        };
        if !pair_matches
            || q.requested_amount != request.amount_units.parse().ok()
            || send == 0
            || receive == 0
            || ttl == 0
        {
            return;
        }
        if self.quote_id == Some(id) {
            return;
        } // Duplicate frames cannot extend review authority.
        let Some(fee) = server_fee.checked_add(fixed_fee) else {
            return;
        };
        let ttl = ttl.min(60_000);
        self.deadline = Some(Instant::now() + Duration::from_millis(ttl));
        self.quote_id = Some(id);
        self.state = SwapStateDto {
            phase: "Review".into(),
            review: Some(SwapReviewDto {
                id: uuid::Uuid::new_v4().to_string(),
                generation,
                send_asset_id: request.send_asset_id.clone(),
                receive_asset_id: request.receive_asset_id.clone(),
                send_units: send.to_string(),
                receive_units: receive.to_string(),
                fees: vec![AssetAmountDto {
                    asset: AssetKeyDto {
                        chain: ChainDto::Liquid,
                        asset_id: Some(fee_asset.clone()),
                    },
                    units: fee.to_string(),
                }],
                expires_at_ms: now.saturating_add(ttl),
            }),
            txid: None,
            message: None,
        };
    }
    pub fn view(&self, now: u64) -> SwapStateDto {
        let mut out = self.state.clone();
        if out.phase == "Review"
            && (self.deadline.is_none_or(|d| Instant::now() >= d)
                || out.review.as_ref().is_some_and(|r| now >= r.expires_at_ms))
        {
            out.phase = "Expired".into();
            out.review = None;
        }
        out
    }
    pub fn deadline(&self) -> Option<Instant> {
        self.deadline
    }
    pub fn take(&mut self, id: &str, generation: u32, now: u64) -> Result<u64> {
        let view = self.view(now);
        let valid = view.phase == "Review"
            && view
                .review
                .as_ref()
                .is_some_and(|r| r.id == id && r.generation == generation);
        if !valid {
            return Err(DesktopError::new(
                "review_expired",
                "A cotação mudou ou expirou. Revise novamente.",
            ));
        }
        self.state.phase = "Submitting".into();
        self.quote_id
            .take()
            .ok_or_else(|| DesktopError::new("review_expired", "Solicite uma nova cotação."))
    }
}
