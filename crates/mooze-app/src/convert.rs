//! Conversions and constructors that are not part of the host API.
//!
//! Hosts scan `dto` for types. Helper functions live here so no binding
//! generator exposes them.

use mooze_core::domain as d;

use crate::dto::*;

/// `SendRequestDto` to the core request. The chain follows from the method called.
pub fn send_request(dto: &SendRequestDto, chain: d::ChainId) -> d::SendRequest {
    let mut r = d::SendRequest::new(chain, dto.destination.clone(), dto.amount_sat);
    r.asset_id = dto.asset_id.clone();
    r.fee_priority = match dto.fee_priority {
        FeePriorityDto::Low => d::FeePriority::Low,
        FeePriorityDto::Medium => d::FeePriority::Medium,
        FeePriorityDto::High => d::FeePriority::High,
    };
    r.label = dto.label.clone();
    r.subtract_fee_from_amount = dto.subtract_fee_from_amount;
    r.fee_rate_override_sat_per_vbyte = dto.fee_rate_override_sat_per_vbyte;
    r.drain = dto.drain;
    r
}

/// A quote item of the SideSwap event stream.
pub fn sideswap_quote_event(q: QuoteDto) -> SideSwapEventDto {
    SideSwapEventDto {
        kind: SideSwapEventKind::Quote,
        quote: Some(q),
        balance_sat: None,
        message: None,
    }
}

/// A peg wallet balance item of the SideSwap event stream.
pub fn sideswap_balance_event(kind: SideSwapEventKind, sat: u64) -> SideSwapEventDto {
    SideSwapEventDto {
        kind,
        quote: None,
        balance_sat: Some(sat),
        message: None,
    }
}

/// The socket dropped. The driver reconnects with backoff.
pub fn sideswap_disconnected_event(message: String) -> SideSwapEventDto {
    SideSwapEventDto {
        kind: SideSwapEventKind::Disconnected,
        quote: None,
        balance_sat: None,
        message: Some(message),
    }
}

/// Last item: the driver stopped.
pub fn sideswap_closed_event() -> SideSwapEventDto {
    SideSwapEventDto {
        kind: SideSwapEventKind::Closed,
        quote: None,
        balance_sat: None,
        message: None,
    }
}
