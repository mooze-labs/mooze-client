//! Amount formatting and input normalization.
//!
//! The module covers the locales the app ships (en, pt_BR, es) without a locale crate.

use crate::domain::{Asset, SATS_PER_UNIT};

/// Locale for number grouping.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum Locale {
    /// `en_US`: `1,234.56`.
    #[default]
    En,
    /// `pt_BR`: `1.234,56`.
    PtBr,
    /// `es_ES`: `1.234,56`.
    Es,
}

impl Locale {
    /// Parses a tag such as `pt_BR`, `pt-BR`, `es` or `en_US`. Unknown languages give `En`.
    pub fn from_tag(tag: &str) -> Self {
        let lang = tag.split(['_', '-']).next().unwrap_or("").to_ascii_lowercase();
        match lang.as_str() {
            "pt" => Locale::PtBr,
            "es" => Locale::Es,
            _ => Locale::En,
        }
    }

    /// Tag with region: `en_US`, `pt_BR`, `es_ES`.
    pub fn tag(self) -> &'static str {
        match self {
            Locale::En => "en_US",
            Locale::PtBr => "pt_BR",
            Locale::Es => "es_ES",
        }
    }

    /// Thousands separator.
    pub fn group_separator(self) -> char {
        match self {
            Locale::En => ',',
            Locale::PtBr | Locale::Es => '.',
        }
    }

    /// Decimal separator.
    pub fn decimal_separator(self) -> char {
        match self {
            Locale::En => '.',
            Locale::PtBr | Locale::Es => ',',
        }
    }
}

/// Inserts `sep` every three digits from the right. `digits` holds ASCII digits only.
pub fn group_digits(digits: &str, sep: char) -> String {
    let len = digits.len();
    let mut out = String::with_capacity(len + len / 3);
    for (i, c) in digits.chars().enumerate() {
        if i > 0 && (len - i) % 3 == 0 {
            out.push(sep);
        }
        out.push(c);
    }
    out
}

/// Fixed-point string with `digits` decimals: exact decimal value, ties round away from zero.
/// NOTE: The output never switches to exponent form, also for large values.
pub fn to_fixed(value: f64, digits: usize) -> String {
    if !value.is_finite() {
        return if value.is_nan() {
            "NaN".into()
        } else if value > 0.0 {
            "Infinity".into()
        } else {
            "-Infinity".into()
        };
    }
    // 1080 places print every double exactly, so the tie test below is exact.
    let exact = format!("{:.1080}", value.abs());
    let (int_part, frac_part) = exact.split_once('.').unwrap_or((&exact, ""));
    let mut buf: Vec<u8> = int_part.bytes().chain(frac_part.bytes().take(digits)).collect();
    if frac_part.as_bytes().get(digits).is_some_and(|d| *d >= b'5') {
        let mut i = buf.len();
        loop {
            if i == 0 {
                buf.insert(0, b'1');
                break;
            }
            i -= 1;
            if buf[i] == b'9' {
                buf[i] = b'0';
            } else {
                buf[i] += 1;
                break;
            }
        }
    }
    let int_len = buf.len() - digits;
    let mut out = String::new();
    if value.is_sign_negative() {
        out.push('-');
    }
    out.push_str(std::str::from_utf8(&buf[..int_len]).unwrap_or("0"));
    if digits > 0 {
        out.push('.');
        out.push_str(std::str::from_utf8(&buf[int_len..]).unwrap_or(""));
    }
    out
}

/// Grouped number with `frac` decimals (pattern `#,##0.00`) for a non-negative value.
fn intl_fixed(value: f64, frac: u32, locale: Locale) -> String {
    let value = value.abs();
    let mut int_part = value.floor();
    let power = 10u64.pow(frac);
    let mut rem = ((value - int_part) * power as f64).round() as u64;
    if rem >= power {
        int_part += 1.0;
        rem -= power;
    }
    let int_str = format!("{int_part:.0}");
    let mut out = group_digits(&int_str, locale.group_separator());
    if frac > 0 {
        out.push(locale.decimal_separator());
        out.push_str(&format!("{rem:0width$}", width = frac as usize));
    }
    out
}

/// Balance with unit: `0 SATS`, `1 SAT`, `1500 SATS`, `12.5 USDT`, `3 DEPIX`.
pub fn format_balance(asset: Asset, sats: u64) -> String {
    match asset {
        Asset::Btc | Asset::Lbtc => match sats {
            0 => "0 SATS".into(),
            1 => "1 SAT".into(),
            n => format!("{n} SATS"),
        },
        Asset::Usdt | Asset::Depix => {
            let ticker = if asset == Asset::Usdt { "USDT" } else { "DEPIX" };
            if sats % SATS_PER_UNIT == 0 {
                return format!("{} {ticker}", sats / SATS_PER_UNIT);
            }
            let fixed = to_fixed(sats as f64 / SATS_PER_UNIT as f64, 8);
            let trimmed = fixed.trim_end_matches('0').trim_end_matches('.');
            format!("{trimmed} {ticker}")
        }
    }
}

/// Display value: sats for BTC and L-BTC, whole units for tokens.
pub fn from_satoshis(asset: Asset, sats: u64) -> f64 {
    match asset {
        Asset::Btc | Asset::Lbtc => sats as f64,
        Asset::Usdt | Asset::Depix => sats as f64 / SATS_PER_UNIT as f64,
    }
}

/// Fiat value: `"<symbol> <value with 2 decimals>"`.
pub fn format_as_fiat(asset: Asset, sats: u64, price: f64, currency_symbol: &str) -> String {
    format!("{currency_symbol} {}", to_fixed(asset.to_units(sats) * price, 2))
}

/// Amount with 8 decimals plus the ticker (`BTC` for on-chain bitcoin).
pub fn format_as_asset(asset: Asset, sats: u64) -> String {
    if asset == Asset::Btc {
        return format!("{} BTC", to_fixed(sats as f64 / SATS_PER_UNIT as f64, 8));
    }
    // NOTE: L-BTC is not divided by 1e8 here, so 1 sat prints "1.00000000 BTC L2".
    format!("{} {}", to_fixed(from_satoshis(asset, sats), 8), asset.ticker())
}

/// Amount in sats: `1 sat`, `5 sats`, or [`format_as_asset`] for tokens.
pub fn format_as_satoshis(asset: Asset, sats: u64) -> String {
    if asset.is_bitcoin() {
        format!("{sats} {}", if sats == 1 { "sat" } else { "sats" })
    } else {
        format_as_asset(asset, sats)
    }
}

/// Amount without unit: grouped sats for BTC/L-BTC, 2 decimals for tokens. No unit.
pub fn format_amount(asset: Asset, sats: u64, locale: Locale) -> String {
    match asset {
        Asset::Btc | Asset::Lbtc => group_digits(&sats.to_string(), locale.group_separator()),
        Asset::Usdt | Asset::Depix => intl_fixed(sats as f64 / SATS_PER_UNIT as f64, 2, locale),
    }
}

/// Quote amount with unit. `amount` is in whole units.
pub fn format_quote_amount(asset: Asset, amount: f64, locale: Locale) -> String {
    match asset {
        Asset::Btc | Asset::Lbtc => {
            let sats = (amount * SATS_PER_UNIT as f64).round();
            let unit = if sats == 1.0 { "sat" } else { "sats" };
            let sign = if sats < 0.0 { "-" } else { "" };
            format!("≈ {sign}{} {unit}", intl_fixed(sats, 0, locale))
        }
        Asset::Depix => format!("{} DEPIX", to_fixed(amount, 2)),
        Asset::Usdt => format!("{} USDT", to_fixed(amount, 8)),
    }
}

pub fn display_name(asset: Asset) -> &'static str {
    match asset {
        Asset::Btc => "Bitcoin",
        Asset::Lbtc => "Bitcoin L2",
        Asset::Usdt => "USDT",
        Asset::Depix => "DEPIX",
    }
}

/// Signed transaction value: `+1.500 sats`, `-$ 2.50`, `+R$ 10.00`.
pub fn format_transaction_value(asset: Asset, amount_sats: u64, is_receive: bool) -> String {
    let sign = if is_receive { '+' } else { '-' };
    let units = amount_sats as f64 / SATS_PER_UNIT as f64;
    match asset {
        Asset::Btc | Asset::Lbtc => {
            let unit = if amount_sats == 1 { "sat" } else { "sats" };
            format!("{sign}{} {unit}", sats_format_value(amount_sats as i64))
        }
        Asset::Usdt => format!("{sign}$ {}", to_fixed(units, 2)),
        Asset::Depix => format!("{sign}R$ {}", to_fixed(units, 2)),
    }
}

/// Shortened id: `abcde...vwxyz` for ids longer than 15 characters.
pub fn truncate_hash_id(tx_id: &str, length: usize) -> String {
    let chars: Vec<char> = tx_id.chars().collect();
    if chars.len() <= 15 {
        return tx_id.to_owned();
    }
    let head: String = chars[..length.min(chars.len())].iter().collect();
    let tail: String = chars[chars.len().saturating_sub(length)..].iter().collect();
    format!("{head}...{tail}")
}

/// Keeps ASCII digits, strips leading zeros (keeps one `0`), caps at 16 digits.
fn input_digits(text: &str) -> Option<String> {
    let digits: String = text.chars().filter(char::is_ascii_digit).collect();
    if digits.is_empty() {
        return None;
    }
    let mut d = digits.trim_start_matches('0').to_owned();
    if d.is_empty() {
        d.push('0');
    }
    d.truncate(16);
    Some(d)
}

/// Fiat input mask: digits fill from the right, `1234` gives `12,34`.
pub fn fiat_format_input(text: &str) -> String {
    let Some(mut d) = input_digits(text) else { return "0,00".into() };
    if d.len() < 3 {
        d = format!("{d:0>3}");
    }
    let (int_part, dec) = d.split_at(d.len() - 2);
    let int_trim = int_part.trim_start_matches('0');
    format!("{},{dec}", group_digits(if int_trim.is_empty() { "0" } else { int_trim }, '.'))
}

/// Parses fiat input: `1.234,56` gives `1234.56`. Invalid text gives `0.0`.
pub fn fiat_parse_value(formatted: &str) -> f64 {
    parse_double(&formatted.replace('.', "").replace(',', ".")).unwrap_or(0.0)
}

/// Formats a fiat value: `1234.56` gives `1.234,56`. Non-positive gives `0,00`.
pub fn fiat_format_value(value: f64) -> String {
    if value <= 0.0 || value.is_nan() {
        return "0,00".into();
    }
    let cents = format!("{:0>3}", format!("{:.0}", (value * 100.0).round()));
    let (int_part, dec) = cents.split_at(cents.len() - 2);
    let int_trim = int_part.trim_start_matches('0');
    format!("{},{dec}", group_digits(if int_trim.is_empty() { "0" } else { int_trim }, '.'))
}

/// BTC input mask: digits fill 8 decimals from the right.
pub fn btc_format_input(text: &str) -> String {
    let Some(d) = input_digits(text) else { return "0.00000000".into() };
    if d.len() <= 8 {
        format!("0.{d:0>8}")
    } else {
        let (i, f) = d.split_at(d.len() - 8);
        format!("{i}.{f}")
    }
}

/// Parses BTC input: reads the digits as an 8-decimal number.
pub fn btc_parse_value(formatted: &str) -> f64 {
    let digits: String = formatted.chars().filter(char::is_ascii_digit).collect();
    let t = digits.trim_start_matches('0');
    if t.is_empty() {
        return 0.0;
    }
    let s = if t.len() <= 8 { format!("0.{t:0>8}") } else { format!("{}.{}", &t[..t.len() - 8], &t[t.len() - 8..]) };
    s.parse().unwrap_or(0.0)
}

/// Formats a BTC value: 8 decimals. Non-positive gives `0.00000000`.
pub fn btc_format_value(value: f64) -> String {
    if value <= 0.0 || value.is_nan() {
        return "0.00000000".into();
    }
    to_fixed(value, 8)
}

/// Sats input mask: digits grouped with `.`.
pub fn sats_format_input(text: &str) -> String {
    input_digits(text).map_or_else(|| "0".into(), |d| group_digits(&d, '.'))
}

/// Parses sats input: removes `.` and parses. Invalid text gives `0`.
pub fn sats_parse_value(formatted: &str) -> i64 {
    formatted.replace('.', "").parse().unwrap_or(0)
}

/// Formats a sats value: `1500000` gives `1.500.000`. Non-positive gives `0`.
pub fn sats_format_value(value: i64) -> String {
    if value <= 0 {
        return "0".into();
    }
    group_digits(&value.to_string(), '.')
}

/// Currency input mask (pt_BR, empty symbol).
/// Returns `None` when the text stays unchanged (empty input).
/// NOTE: The pt_BR currency pattern puts a no-break space before the number,
/// so the output starts with `\u{a0}`. A typed trailing comma is dropped. Both are intentional.
pub fn currency_input_format(text: &str) -> Option<String> {
    if text.is_empty() {
        return None;
    }
    let new_text: String = text.chars().filter(|c| c.is_ascii_digit() || *c == ',').collect();
    if new_text.is_empty() {
        return Some(String::new());
    }
    if new_text == "," {
        return Some("0,".into());
    }
    let currency = |v: f64| format!("\u{a0}{}", intl_fixed(v, 2, Locale::PtBr));
    if new_text.contains(',') {
        let mut parts = new_text.split(',');
        let int_part = parts.next().filter(|p| !p.is_empty()).unwrap_or("0");
        let dec: String = parts.next().unwrap_or("").chars().take(2).collect();
        let mut out = currency(int_part.parse().unwrap_or(0.0)).replace(",00", "");
        if !dec.is_empty() {
            out = format!("{out},{dec}");
        }
        Some(out)
    } else {
        Some(currency(parse_double(&new_text).unwrap_or(0.0) / 100.0))
    }
}

/// Parses a double: trims whitespace, accepts `NaN` and `Infinity`, rejects `inf`.
pub fn parse_double(s: &str) -> Option<f64> {
    let s = s.trim();
    match s {
        "NaN" => return Some(f64::NAN),
        "Infinity" | "+Infinity" => return Some(f64::INFINITY),
        "-Infinity" => return Some(f64::NEG_INFINITY),
        _ => {}
    }
    if s.chars().any(|c| !(c.is_ascii_digit() || matches!(c, '.' | 'e' | 'E' | '+' | '-'))) {
        return None;
    }
    s.parse().ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn locale_tags() {
        assert_eq!(Locale::from_tag("pt_BR"), Locale::PtBr);
        assert_eq!(Locale::from_tag("pt"), Locale::PtBr);
        assert_eq!(Locale::from_tag("es-ES"), Locale::Es);
        assert_eq!(Locale::from_tag("fr_FR"), Locale::En);
        assert_eq!(Locale::Es.tag(), "es_ES");
    }

    #[test]
    fn to_fixed_rounding() {
        assert_eq!(to_fixed(1.005, 2), "1.00"); // 1.005 is 1.00499999... in binary
        assert_eq!(to_fixed(0.125, 2), "0.13"); // exact tie rounds away from zero
        assert_eq!(to_fixed(2.5, 0), "3");
        assert_eq!(to_fixed(9.999, 2), "10.00");
        assert_eq!(to_fixed(-0.001, 2), "-0.00");
        assert_eq!(to_fixed(12.3456789, 8), "12.34567890");
        assert_eq!(to_fixed(0.00000001, 8), "0.00000001");
    }

    #[test]
    fn balances() {
        assert_eq!(format_balance(Asset::Btc, 0), "0 SATS");
        assert_eq!(format_balance(Asset::Lbtc, 1), "1 SAT");
        assert_eq!(format_balance(Asset::Btc, 4_080_401), "4080401 SATS");
        assert_eq!(format_balance(Asset::Usdt, 0), "0 USDT");
        assert_eq!(format_balance(Asset::Usdt, 300_000_000), "3 USDT");
        assert_eq!(format_balance(Asset::Usdt, 1_250_000_000), "12.5 USDT");
        assert_eq!(format_balance(Asset::Depix, 1), "0.00000001 DEPIX");
    }

    #[test]
    fn amount_per_locale() {
        assert_eq!(format_amount(Asset::Btc, 4_080_401, Locale::En), "4,080,401");
        assert_eq!(format_amount(Asset::Btc, 4_080_401, Locale::PtBr), "4.080.401");
        assert_eq!(format_amount(Asset::Lbtc, 999, Locale::Es), "999");
        assert_eq!(format_amount(Asset::Usdt, 312_096_000_000, Locale::En), "3,120.96");
        assert_eq!(format_amount(Asset::Usdt, 312_096_000_000, Locale::PtBr), "3.120,96");
        assert_eq!(format_amount(Asset::Depix, 1234, Locale::Es), "0,00");
        assert_eq!(format_amount(Asset::Depix, 99_999_999, Locale::En), "1.00");
        assert_eq!(format_amount(Asset::Usdt, 0, Locale::PtBr), "0,00");
    }

    #[test]
    fn quote_and_asset_strings() {
        assert_eq!(format_quote_amount(Asset::Btc, 0.01234567, Locale::PtBr), "≈ 1.234.567 sats");
        assert_eq!(format_quote_amount(Asset::Lbtc, 0.00000001, Locale::En), "≈ 1 sat");
        assert_eq!(format_quote_amount(Asset::Depix, 10.5, Locale::En), "10.50 DEPIX");
        assert_eq!(format_quote_amount(Asset::Usdt, 1.5, Locale::En), "1.50000000 USDT");
        assert_eq!(format_as_asset(Asset::Btc, 150_000_000), "1.50000000 BTC");
        assert_eq!(format_as_asset(Asset::Lbtc, 1), "1.00000000 BTC L2");
        assert_eq!(format_as_asset(Asset::Usdt, 250_000_000), "2.50000000 USDT");
        assert_eq!(format_as_satoshis(Asset::Btc, 1), "1 sat");
        assert_eq!(format_as_satoshis(Asset::Lbtc, 21), "21 sats");
        assert_eq!(format_as_satoshis(Asset::Depix, 100_000_000), "1.00000000 Depix");
        assert_eq!(format_as_fiat(Asset::Btc, 100_000, 600_000.0, "R$"), "R$ 600.00");
        assert_eq!(display_name(Asset::Usdt), "USDT");
    }

    #[test]
    fn transaction_values_and_hash() {
        assert_eq!(format_transaction_value(Asset::Btc, 1_500_000, true), "+1.500.000 sats");
        assert_eq!(format_transaction_value(Asset::Lbtc, 1, false), "-1 sat");
        assert_eq!(format_transaction_value(Asset::Usdt, 250_000_000, false), "-$ 2.50");
        assert_eq!(format_transaction_value(Asset::Depix, 1_000_000_000, true), "+R$ 10.00");
        assert_eq!(truncate_hash_id("abc", 5), "abc");
        assert_eq!(truncate_hash_id("0123456789abcdefXYZ", 5), "01234...efXYZ");
    }

    #[test]
    fn fiat_input() {
        assert_eq!(fiat_format_input(""), "0,00");
        assert_eq!(fiat_format_input("abc"), "0,00");
        assert_eq!(fiat_format_input("1"), "0,01");
        assert_eq!(fiat_format_input("123"), "1,23");
        assert_eq!(fiat_format_input("100000"), "1.000,00");
        assert_eq!(fiat_format_input("100000000"), "1.000.000,00");
        assert_eq!(fiat_format_input("00000123"), "1,23");
        assert_eq!(fiat_format_input("12345678901234567"), "12.345.678.901.234,56");
        assert_eq!(fiat_parse_value("1.234,56"), 1234.56);
        assert_eq!(fiat_parse_value("x"), 0.0);
        assert_eq!(fiat_format_value(0.01), "0,01");
        assert_eq!(fiat_format_value(1234.56), "1.234,56");
        assert_eq!(fiat_format_value(1_000_000.0), "1.000.000,00");
        assert_eq!(fiat_format_value(-3.0), "0,00");
    }

    #[test]
    fn btc_and_sats_input() {
        assert_eq!(btc_format_input(""), "0.00000000");
        assert_eq!(btc_format_input("12"), "0.00000012");
        assert_eq!(btc_format_input("123456789"), "1.23456789");
        assert_eq!(btc_format_input("99999999999999999"), "99999999.99999999");
        assert_eq!(btc_format_input("00000123"), "0.00000123");
        assert_eq!(btc_parse_value("0.00000123"), 0.00000123);
        assert_eq!(btc_parse_value("123.45678901"), 123.45678901);
        assert_eq!(btc_parse_value("0.00000000"), 0.0);
        assert_eq!(btc_format_value(12.3456789), "12.34567890");
        assert_eq!(btc_format_value(0.0), "0.00000000");
        assert_eq!(sats_format_input("1234567"), "1.234.567");
        assert_eq!(sats_format_input("000"), "0");
        assert_eq!(sats_parse_value("1.234.567"), 1_234_567);
        assert_eq!(sats_parse_value("abc"), 0);
        assert_eq!(sats_format_value(1000), "1.000");
        assert_eq!(sats_format_value(-1), "0");
    }

    #[test]
    fn currency_input() {
        assert_eq!(currency_input_format(""), None);
        assert_eq!(currency_input_format("abc").as_deref(), Some(""));
        assert_eq!(currency_input_format(",").as_deref(), Some("0,"));
        assert_eq!(currency_input_format("123456").as_deref(), Some("\u{a0}1.234,56"));
        assert_eq!(currency_input_format("1234,5").as_deref(), Some("\u{a0}1.234,5"));
        assert_eq!(currency_input_format("1234,").as_deref(), Some("\u{a0}1.234"));
    }

    #[test]
    fn double_parsing() {
        assert_eq!(parse_double(" 0.5 "), Some(0.5));
        assert_eq!(parse_double("1e-3"), Some(0.001));
        assert_eq!(parse_double("inf"), None);
        assert!(parse_double("Infinity").unwrap().is_infinite());
        assert_eq!(parse_double("abc"), None);
    }
}
