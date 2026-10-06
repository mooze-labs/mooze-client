//! Pure rules every host calls synchronously: PIX fees and limits,
//! taxpayer ids, peg amount checks, defaults.

use mooze_core::peg::entities::PegServerLimits;
use mooze_core::peg::{evaluate_peg_amount, PegAmountIssue};
use mooze_core::pix::rules::{self, DepositLimits, DepositValidationError, DEPOSIT_POLL_INTERVAL_MS};
use mooze_core::pix::tax_id::{self, CpfValidationError};
use mooze_core::sideswap::protocol::SIDESWAP_API_URL;

use crate::dto::*;

/// Interval between `pix_poll_tick` calls, in milliseconds.
pub fn pix_poll_interval_ms() -> u32 {
    DEPOSIT_POLL_INTERVAL_MS as u32
}

/// Fee breakdown for `amount_brl`. Pass the asset price in BRL to get the
/// estimated asset amount.
pub fn pix_fee(amount_brl: f64, has_referral: bool, quote_brl: Option<f64>) -> PixFeeDto {
    PixFeeDto {
        fee_rate_percent: rules::fee_rate_percent(amount_brl, has_referral),
        fee_amount: rules::fee_amount(amount_brl, has_referral),
        discounted_amount: rules::discounted_deposit_amount(amount_brl, has_referral),
        estimated_asset_units: quote_brl
            .filter(|q| *q > 0.0)
            .map(|q| rules::estimated_asset_units(amount_brl, has_referral, q)),
        active_tier: rules::active_fee_tier(amount_brl).map(|i| i as u32),
        amount_in_cents: rules::amount_in_cents(amount_brl),
    }
}

/// Validates a deposit amount in BRL. Pass `None` while the limits load:
/// every positive amount is then valid, as in Dart.
pub fn pix_validate_amount(amount_brl: f64, limits: Option<DepositLimitsDto>) -> DepositValidationDto {
    let limits = limits
        .map(|l| DepositLimits { absolute_min_limit: l.absolute_min_limit, allowed_spending: l.allowed_spending });
    let v = rules::validate_deposit_amount(amount_brl, limits.as_ref());
    DepositValidationDto {
        is_valid: v.is_valid(),
        error: v.error.map(|e| match e {
            DepositValidationError::InvalidAmount => DepositValidationErrorDto::InvalidAmount,
            DepositValidationError::BelowMinimum => DepositValidationErrorDto::BelowMinimum,
            DepositValidationError::AboveTransaction => DepositValidationErrorDto::AboveTransaction,
            DepositValidationError::AboveRemaining => DepositValidationErrorDto::AboveRemaining,
        }),
        limit_amount: v.limit_amount,
    }
}

/// Validates a CPF (11 digits) or CNPJ (14 digits), masked or raw.
/// Returns `None` when valid.
pub fn tax_id_validate(input: String) -> Option<CpfValidationErrorDto> {
    tax_id::validate(&input).map(|e| match e {
        CpfValidationError::Empty => CpfValidationErrorDto::Empty,
        CpfValidationError::Incomplete => CpfValidationErrorDto::Incomplete,
        CpfValidationError::Invalid => CpfValidationErrorDto::Invalid,
    })
}

/// True if `input` is a valid CPF or CNPJ.
pub fn tax_id_is_valid(input: String) -> bool {
    tax_id::is_valid(&input)
}

/// Keeps only the digits.
pub fn tax_id_strip(input: String) -> String {
    tax_id::strip(&input)
}

/// Formats digits as CPF (up to 11) or CNPJ (12 or more).
pub fn tax_id_format(digits: String) -> String {
    tax_id::format_cpf_cnpj(&digits)
}

/// Live input mask (Dart `CpfCnpjInputFormatter`): strips, caps at 14
/// digits, formats.
pub fn tax_id_mask_input(text: String) -> String {
    tax_id::mask_cpf_cnpj_input(&text)
}

/// True if `value` looks like a PIX key or a BR Code payload
/// (Dart `PixKeyDetector`).
pub fn pix_looks_like_key(value: String) -> bool {
    tax_id::looks_like_pix_key(&value)
}

/// Validates a peg amount (Dart `evaluatePegAmount`). The minimum comes
/// from `limits`, or `fallback_minimum_sats` when unknown. A drain is
/// always valid.
pub fn peg_validate_amount(
    direction: PegDirectionDto,
    amount_sat: Option<u64>,
    spendable_sat: u64,
    limits: Option<PegServerLimitsDto>,
    fallback_minimum_sats: u64,
    drain: bool,
) -> PegAmountValidationDto {
    let limits = limits.map(PegServerLimits::from);
    let v =
        evaluate_peg_amount(direction.into(), amount_sat, spendable_sat, limits.as_ref(), fallback_minimum_sats, drain);
    PegAmountValidationDto {
        has_amount: v.has_amount,
        is_valid: v.is_valid,
        issue: v.issue.map(|i| match i {
            PegAmountIssue::BelowMinimum => PegAmountIssueDto::BelowMinimum,
            PegAmountIssue::AboveBalance => PegAmountIssueDto::AboveBalance,
        }),
        minimum_sats: v.minimum_sats,
        maximum_sats: v.maximum_sats,
        shows_issue: v.shows_issue(),
    }
}

/// Default SideSwap endpoint.
pub fn sideswap_default_url() -> String {
    SIDESWAP_API_URL.to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pure_helpers_match_the_dart_rules() {
        assert!(tax_id_is_valid("529.982.247-25".into()));
        assert!(!tax_id_is_valid("111.111.111-11".into()));
        assert_eq!(tax_id_strip("529.982.247-25".into()), "52998224725");
        assert_eq!(tax_id_format("52998224725".into()), "529.982.247-25");
        assert_eq!(tax_id_mask_input("5299822472512345678".into()).len(), 18);
        assert_eq!(pix_poll_interval_ms(), 30_000);
        assert!(pix_fee(100.0, false, Some(5.0)).estimated_asset_units.is_some());
        assert!(!pix_validate_amount(0.0, None).is_valid);
        assert!(sideswap_default_url().starts_with("wss://"));
    }
}
