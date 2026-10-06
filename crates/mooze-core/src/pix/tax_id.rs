//! CPF/CNPJ validation and masks, and the PIX key heuristic.

/// Why a CPF/CNPJ input is not valid.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CpfValidationError {
    /// No digits.
    Empty,
    /// Fewer digits than a CPF, or 12 to 13 digits.
    Incomplete,
    /// Wrong check digits, repeated digits, or more than 14 digits.
    Invalid,
}

/// Payer CPF is required before a PIX deposit.
pub const PIX_CPF_REQUIRED: bool = true;

/// Keeps only ASCII digits.
pub fn strip(input: &str) -> String {
    input.chars().filter(|c| c.is_ascii_digit()).collect()
}

/// Validates a CPF (11 digits) or CNPJ (14 digits), masked or raw.
pub fn validate(input: &str) -> Option<CpfValidationError> {
    let digits: Vec<u32> = strip(input).chars().map(|c| c.to_digit(10).unwrap_or(0)).collect();
    match digits.len() {
        0 => Some(CpfValidationError::Empty),
        11 => (!is_valid_cpf(&digits)).then_some(CpfValidationError::Invalid),
        14 => (!is_valid_cnpj(&digits)).then_some(CpfValidationError::Invalid),
        n if n < 14 => Some(CpfValidationError::Incomplete),
        _ => Some(CpfValidationError::Invalid),
    }
}

/// True if [`validate`] returns no error.
pub fn is_valid(input: &str) -> bool {
    validate(input).is_none()
}

fn all_same(d: &[u32]) -> bool {
    d.iter().all(|x| *x == d[0])
}

fn is_valid_cpf(d: &[u32]) -> bool {
    if all_same(d) {
        return false;
    }
    let check = |len: usize| {
        let mut sum = 0;
        let mut weight = len as u32 + 1;
        for x in &d[..len] {
            sum += x * weight;
            weight -= 1;
        }
        let r = sum % 11;
        if r < 2 {
            0
        } else {
            11 - r
        }
    };
    check(9) == d[9] && check(10) == d[10]
}

fn is_valid_cnpj(d: &[u32]) -> bool {
    if all_same(d) {
        return false;
    }
    const BASE: [u32; 13] = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    let check = |len: usize| {
        let weights = &BASE[BASE.len() - len..];
        let sum: u32 = d[..len].iter().zip(weights).map(|(x, w)| x * w).sum();
        let r = sum % 11;
        if r < 2 {
            0
        } else {
            11 - r
        }
    };
    check(12) == d[12] && check(13) == d[13]
}

/// Formats digits progressively as CPF (`000.000.000-00`, up to 11) or
/// CNPJ (`00.000.000/0000-00`, 12 or more).
pub fn format_cpf_cnpj(digits: &str) -> String {
    let mut out = String::with_capacity(digits.len() + 4);
    let cpf = digits.chars().count() <= 11;
    for (i, c) in digits.chars().enumerate() {
        if cpf {
            if i == 3 || i == 6 {
                out.push('.');
            }
            if i == 9 {
                out.push('-');
            }
        } else {
            if i == 2 || i == 5 {
                out.push('.');
            }
            if i == 8 {
                out.push('/');
            }
            if i == 12 {
                out.push('-');
            }
        }
        out.push(c);
    }
    out
}

/// Live input mask: strips, caps at 14 digits, formats.
pub fn mask_cpf_cnpj_input(text: &str) -> String {
    let digits: String = strip(text).chars().take(14).collect();
    format_cpf_cnpj(&digits)
}

/// Heuristic: true if `value` looks like a PIX key or a BR Code payload.
///
/// Accepts e-mail, phone, CPF/CNPJ, random (EVP) keys and `000201...` payloads.
pub fn looks_like_pix_key(value: &str) -> bool {
    let v = value.trim();
    if v.is_empty() || v.encode_utf16().count() > 1024 {
        return false;
    }
    if v.starts_with("000201") {
        return true;
    }
    if is_email(v) || is_evp(v) || is_phone(v) {
        return true;
    }
    let digits: String =
        v.chars().filter(|c| !matches!(c, '.' | '-' | '/' | '(' | ')' | '+') && !c.is_whitespace()).collect();
    !digits.is_empty() && digits.chars().all(|c| c.is_ascii_digit()) && matches!(digits.len(), 11 | 13 | 14)
}

/// `^[^\s@]+@[^\s@]+\.[^\s@]{2,}$`
fn is_email(v: &str) -> bool {
    let ok = |c: char| c != '@' && !c.is_whitespace();
    let Some((local, domain)) = v.split_once('@') else { return false };
    if local.is_empty() || !local.chars().all(ok) || !domain.chars().all(ok) {
        return false;
    }
    let chars: Vec<char> = domain.chars().collect();
    (1..chars.len()).any(|i| chars[i] == '.' && chars.len() - i > 2)
}

/// `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`, any case.
fn is_evp(v: &str) -> bool {
    let parts: Vec<&str> = v.split('-').collect();
    parts.len() == 5
        && parts.iter().zip([8, 4, 4, 4, 12]).all(|(p, n)| p.len() == n && p.chars().all(|c| c.is_ascii_hexdigit()))
}

#[derive(Clone, Copy)]
enum Tok {
    Ch(char),
    Digit,
    Space,
}

/// `^\+?55?\s?\(?\d{2}\)?\s?9?\d{4}-?\d{4}$`
fn is_phone(v: &str) -> bool {
    use Tok::*;
    // (token, optional)
    let mut pat: Vec<(Tok, bool)> =
        vec![(Ch('+'), true), (Ch('5'), false), (Ch('5'), true), (Space, true), (Ch('('), true)];
    pat.extend([(Digit, false); 2]);
    pat.extend([(Ch(')'), true), (Space, true), (Ch('9'), true)]);
    pat.extend([(Digit, false); 4]);
    pat.push((Ch('-'), true));
    pat.extend([(Digit, false); 4]);
    let chars: Vec<char> = v.chars().collect();
    match_tokens(&pat, &chars)
}

fn match_tokens(pat: &[(Tok, bool)], s: &[char]) -> bool {
    let Some(((tok, optional), rest)) = pat.split_first() else { return s.is_empty() };
    let hit = s.first().is_some_and(|c| match tok {
        Tok::Ch(x) => c == x,
        Tok::Digit => c.is_ascii_digit(),
        Tok::Space => c.is_whitespace(),
    });
    (hit && match_tokens(rest, &s[1..])) || (*optional && match_tokens(rest, s))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strip_works() {
        assert_eq!(strip("529.982.247-25"), "52998224725");
        assert_eq!(strip("  529 982 247 25 "), "52998224725");
        assert_eq!(strip("abc"), "");
    }

    #[test]
    fn cpf_cases() {
        use CpfValidationError::*;
        assert_eq!(validate("529.982.247-25"), None);
        assert_eq!(validate("52998224725"), None);
        assert_eq!(validate("111.444.777-35"), None);
        assert_eq!(validate(""), Some(Empty));
        assert_eq!(validate("   "), Some(Empty));
        assert_eq!(validate("529.982.247"), Some(Incomplete));
        assert_eq!(validate("5299822472"), Some(Incomplete));
        assert_eq!(validate("000.000.000-00"), Some(Invalid));
        assert_eq!(validate("99999999999"), Some(Invalid));
        assert_eq!(validate("529.982.247-26"), Some(Invalid));
        assert_eq!(validate("111.444.777-30"), Some(Invalid));
    }

    #[test]
    fn cnpj_cases() {
        use CpfValidationError::*;
        assert_eq!(validate("11.222.333/0001-81"), None);
        assert_eq!(validate("11222333000181"), None);
        assert_eq!(validate("11222333000180"), Some(Invalid));
        assert_eq!(validate("00000000000000"), Some(Invalid));
        assert_eq!(validate("112223330001"), Some(Incomplete));
        assert_eq!(validate("1122233300018"), Some(Incomplete));
        assert_eq!(validate("112223330001811"), Some(Invalid));
        assert!(is_valid("11222333000181"));
        assert!(!is_valid(""));
    }

    #[test]
    fn formatting() {
        assert_eq!(format_cpf_cnpj("52998224725"), "529.982.247-25");
        assert_eq!(format_cpf_cnpj("11222333000181"), "11.222.333/0001-81");
        assert_eq!(format_cpf_cnpj("5299"), "529.9");
        assert_eq!(mask_cpf_cnpj_input("11.222.333/0001-8199"), "11.222.333/0001-81");
    }

    #[test]
    fn pix_key_detector() {
        assert!(looks_like_pix_key("someone@example.com"));
        assert!(looks_like_pix_key("123.456.789-09"));
        assert!(looks_like_pix_key("12.345.678/0001-95"));
        assert!(looks_like_pix_key("+55 11 91234-5678"));
        assert!(looks_like_pix_key("123e4567-e89b-12d3-a456-426614174000"));
        assert!(looks_like_pix_key("00020126580014br.gov.bcb.pix0136..."));
        assert!(!looks_like_pix_key(""));
        assert!(!looks_like_pix_key("hello world"));
        assert!(!looks_like_pix_key("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"));
        assert!(!looks_like_pix_key("1234"));
        assert!(!looks_like_pix_key("a@b.c"));
        assert!(!looks_like_pix_key(&"1".repeat(1025)));
    }
}
