//! Peg amount validation.

use super::entities::{PegDirection, PegServerLimits};

/// Why an amount cannot be used.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PegAmountIssue {
    BelowMinimum,
    AboveBalance,
}

/// Result of [`evaluate_peg_amount`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PegAmountValidation {
    /// False when no amount was entered.
    pub has_amount: bool,
    pub is_valid: bool,
    pub issue: Option<PegAmountIssue>,
    pub minimum_sats: Option<u64>,
    pub maximum_sats: Option<u64>,
}

impl PegAmountValidation {
    /// No amount: not valid, no error shown.
    pub const EMPTY: Self =
        Self { has_amount: false, is_valid: false, issue: None, minimum_sats: None, maximum_sats: None };

    fn valid(min: u64, max: u64) -> Self {
        Self { has_amount: true, is_valid: true, issue: None, minimum_sats: Some(min), maximum_sats: Some(max) }
    }

    fn invalid(reason: PegAmountIssue, min: u64, max: u64) -> Self {
        Self { has_amount: true, is_valid: false, issue: Some(reason), minimum_sats: Some(min), maximum_sats: Some(max) }
    }

    /// True when an issue should be displayed.
    pub fn shows_issue(&self) -> bool {
        self.has_amount && self.issue.is_some()
    }
}

/// Validates a peg amount. Minimum comes from `limits`, or the fallback when
/// limits are unknown. The maximum is the spendable balance. Drain is always
/// valid. Below-minimum wins over above-balance.
pub fn evaluate_peg_amount(
    direction: PegDirection,
    amount_sat: Option<u64>,
    spendable_sat: u64,
    limits: Option<&PegServerLimits>,
    fallback_minimum_sats: u64,
    drain: bool,
) -> PegAmountValidation {
    let minimum = limits.map_or(fallback_minimum_sats, |l| l.minimum_for(direction));
    if drain {
        return PegAmountValidation::valid(minimum, spendable_sat);
    }
    let amount = match amount_sat {
        Some(a) if a > 0 => a,
        _ => return PegAmountValidation::EMPTY,
    };
    if amount < minimum {
        return PegAmountValidation::invalid(PegAmountIssue::BelowMinimum, minimum, spendable_sat);
    }
    if amount > spendable_sat {
        return PegAmountValidation::invalid(PegAmountIssue::AboveBalance, minimum, spendable_sat);
    }
    PegAmountValidation::valid(minimum, spendable_sat)
}

#[cfg(test)]
mod tests {
    use super::*;

    const LIMITS: PegServerLimits = PegServerLimits {
        min_peg_in_sat: 10_000,
        min_peg_out_sat: 25_000,
        server_fee_percent_peg_in: 0.1,
        server_fee_percent_peg_out: 0.1,
    };
    const IN: PegDirection = PegDirection::PegIn;
    const OUT: PegDirection = PegDirection::PegOut;

    fn eval(d: PegDirection, a: Option<u64>, bal: u64) -> PegAmountValidation {
        evaluate_peg_amount(d, a, bal, Some(&LIMITS), 25_000, false)
    }

    #[test]
    fn peg_in_edges() {
        let v = eval(IN, Some(50_000), 100_000);
        assert!(v.is_valid);
        assert_eq!((v.minimum_sats, v.maximum_sats), (Some(10_000), Some(100_000)));
        assert_eq!(eval(IN, Some(9_999), 100_000).issue, Some(PegAmountIssue::BelowMinimum));
        assert!(eval(IN, Some(10_000), 100_000).is_valid);
        assert!(eval(IN, Some(12_000), 100_000).is_valid);
        assert_eq!(eval(IN, Some(100_001), 100_000).issue, Some(PegAmountIssue::AboveBalance));
        assert!(eval(IN, Some(100_000), 100_000).is_valid);
        assert_eq!(eval(IN, Some(15_000), 5_000).issue, Some(PegAmountIssue::AboveBalance));
    }

    #[test]
    fn peg_out_edges() {
        assert!(eval(OUT, Some(30_000), 100_000).is_valid);
        assert_eq!(eval(OUT, Some(24_999), 100_000).issue, Some(PegAmountIssue::BelowMinimum));
        assert_eq!(eval(OUT, Some(12_000), 100_000).issue, Some(PegAmountIssue::BelowMinimum));
        assert_eq!(eval(OUT, Some(200_000), 100_000).issue, Some(PegAmountIssue::AboveBalance));
    }

    #[test]
    fn empty_drain_and_fallback() {
        let e = eval(IN, None, 100_000);
        assert!(!e.is_valid && !e.shows_issue());
        assert_eq!(eval(IN, Some(0), 100_000), PegAmountValidation::EMPTY);
        let d = evaluate_peg_amount(OUT, Some(1), 100_000, Some(&LIMITS), 25_000, true);
        assert!(d.is_valid);
        assert_eq!(d.maximum_sats, Some(100_000));
        let f = evaluate_peg_amount(IN, Some(12_000), 100_000, None, 25_000, false);
        assert_eq!((f.issue, f.minimum_sats), (Some(PegAmountIssue::BelowMinimum), Some(25_000)));
        assert!(evaluate_peg_amount(IN, Some(30_000), 100_000, None, 25_000, false).is_valid);
        // Below-minimum wins over above-balance.
        assert_eq!(eval(OUT, Some(20_000), 10_000).issue, Some(PegAmountIssue::BelowMinimum));
    }
}
