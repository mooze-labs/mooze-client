#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn pin_requires_six_ascii_digits() {
        assert!(valid_pin("123456"));
        for bad in ["12345", "1234567", "abcdef", "１２３４５６"] {
            assert!(!valid_pin(bad));
        }
    }
    #[test]
    fn review_rejects_unsafe_and_nonfinite_inputs() {
        assert!(valid_amount(1));
        assert!(!valid_amount(0));
        assert!(!valid_amount(9007199254740992));
        assert!(!valid_rate(f64::NAN));
        assert!(!valid_rate(0.));
        assert!(valid_rate(0.1));
    }
}
pub const MAX_SAFE: u64 = 9_007_199_254_740_991;
pub fn valid_pin(pin: &str) -> bool {
    pin.len() == 6 && pin.bytes().all(|b| b.is_ascii_digit())
}
pub fn valid_amount(amount: u64) -> bool {
    amount > 0 && amount <= MAX_SAFE
}
pub fn valid_rate(rate: f64) -> bool {
    rate.is_finite() && rate > 0. && rate <= 10000.
}
