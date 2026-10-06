//! Liquid destination helpers.

use crate::domain::LBTC_ASSET_ID;

/// Liquid BIP21 URI in the exact shape Breez produced. L-BTC with an
/// amount puts `assetid` first; other assets put `amount` first.
pub fn liquid_bip21(address: &str, asset_id: &str, amount_sat: Option<u64>) -> String {
    match amount_sat {
        None => format!("liquidnetwork:{address}?assetid={asset_id}"),
        Some(a) => {
            let value = format_units(a);
            if asset_id == LBTC_ASSET_ID {
                format!("liquidnetwork:{address}?assetid={asset_id}&amount={value}")
            } else {
                format!("liquidnetwork:{address}?amount={value}&assetid={asset_id}")
            }
        }
    }
}

/// Base units to an 8-decimal string without floating point.
fn format_units(units: u64) -> String {
    format!("{}.{:08}", units / 100_000_000, units % 100_000_000)
}

/// Address part of a destination: strips `liquidnetwork:` or `liquid:`
/// (any case) and any query.
pub fn bare_liquid_address(destination: &str) -> String {
    let mut d = destination.trim();
    for scheme in ["liquidnetwork:", "liquid:"] {
        if d.len() >= scheme.len() && d[..scheme.len()].eq_ignore_ascii_case(scheme) {
            d = &d[scheme.len()..];
            break;
        }
    }
    match d.find('?') {
        Some(q) => d[..q].to_owned(),
        None => d.to_owned(),
    }
}

fn is_base58(c: char) -> bool {
    matches!(c, '1'..='9' | 'A'..='H' | 'J'..='N' | 'P'..='Z' | 'a'..='k' | 'm'..='z')
}

/// True for a destination LWK can pay: a Liquid address, bare or BIP21.
pub fn is_liquid_destination(destination: &str) -> bool {
    let d = destination.trim().to_lowercase();
    if d.starts_with("liquidnetwork:") || d.starts_with("liquid:") {
        return true;
    }
    let a = bare_liquid_address(destination);
    let lower = a.to_lowercase();
    if ["lq1", "ex1", "tlq1", "tex1", "el1", "ert1"].iter().any(|p| lower.starts_with(p)) {
        return true;
    }
    // Base58 confidential (VJL..., Az...) and unconfidential (G, H, Q) forms:
    // ^(VJL|VT|VG|Az|G|H|Q)[base58]{25,}$
    ["VJL", "VT", "VG", "Az", "G", "H", "Q"].iter().any(|p| {
        a.strip_prefix(p).is_some_and(|rest| rest.chars().count() >= 25 && rest.chars().all(is_base58))
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::USDT_ASSET_ID;

    #[test]
    fn bip21_shapes() {
        assert_eq!(liquid_bip21("lq1abc", USDT_ASSET_ID, None), format!("liquidnetwork:lq1abc?assetid={USDT_ASSET_ID}"));
        assert_eq!(
            liquid_bip21("lq1abc", LBTC_ASSET_ID, Some(150_000_001)),
            format!("liquidnetwork:lq1abc?assetid={LBTC_ASSET_ID}&amount=1.50000001")
        );
        assert_eq!(
            liquid_bip21("lq1abc", USDT_ASSET_ID, Some(5)),
            format!("liquidnetwork:lq1abc?amount=0.00000005&assetid={USDT_ASSET_ID}")
        );
    }

    #[test]
    fn bare_address() {
        assert_eq!(bare_liquid_address("  LiquidNetwork:lq1xyz?amount=1 "), "lq1xyz");
        assert_eq!(bare_liquid_address("liquid:ex1q"), "ex1q");
        assert_eq!(bare_liquid_address("lq1plain"), "lq1plain");
    }

    #[test]
    fn destination_detection() {
        assert!(is_liquid_destination("liquidnetwork:whatever"));
        assert!(is_liquid_destination("LQ1QQ"));
        assert!(is_liquid_destination("tlq1qq"));
        assert!(is_liquid_destination("VJLCbLBTCdxhWyjVLdjcSmGAksVMtabYg15maSi93zknQD2ihC38R7CUd8KbDFnV8A4hiykxnRB3Uv6d"));
        assert!(is_liquid_destination("GswWrNwJpKdBaVLuHAeBzJwSxSuEYnHUvw"));
        assert!(!is_liquid_destination("bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"));
        assert!(!is_liquid_destination("1BoatSLRHtKNngkdXEeobR76b53LETtpyT"));
        // "G" plus fewer than 25 base58 chars.
        assert!(!is_liquid_destination("Gshort"));
        // "0" is not base58.
        assert!(!is_liquid_destination("G0wWrNwJpKdBaVLuHAeBzJwSxSuEYnHUvw"));
    }
}
