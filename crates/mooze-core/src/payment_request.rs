//! Exact payment requests for asset-aware hosts; no floating point amounts.
#[cfg(test)]
mod tests {
    use super::*;
    const BTC: &str = "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx";
    #[test]
    fn amounts_are_exact_and_ambiguous_queries_rejected() {
        assert_eq!(parse_units("0.00000001").unwrap(), 1);
        assert_eq!(parse_units("90071992.54740993").unwrap(), 9_007_199_254_740_993);
        for bad in ["1e2", "-1", "0", "0.000000001", "18446744073709551616"] {
            assert!(parse_units(bad).is_err());
        }
        assert!(parse(&format!("bitcoin:{BTC}?amount=1&amount=2"), AppNetwork::Testnet).is_err());
        assert!(parse(&format!("bitcoin:{BTC}?req-unknown=1"), AppNetwork::Testnet).is_err());
        assert!(parse(&format!("liquidnetwork:{BTC}"), AppNetwork::Testnet).is_err());
    }
    #[test]
    fn description_roundtrip_and_wrong_network() {
        let req = ExactPaymentRequest {
            chain: ChainId::Bitcoin,
            address: BTC.into(),
            asset_id: None,
            amount_units: Some(1),
            description: Some("Café & pão + café".into()),
        };
        assert_eq!(parse(&encode(&req).unwrap(), AppNetwork::Testnet).unwrap(), req);
        assert!(parse(&encode(&req).unwrap(), AppNetwork::Mainnet).is_err());
    }
}
use crate::{
    domain::{AppNetwork, ChainId},
    payment_uri::{parse_payment_request, NetworkType},
    Error, Result,
};
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExactPaymentRequest {
    pub chain: ChainId,
    pub address: String,
    pub asset_id: Option<String>,
    pub amount_units: Option<u64>,
    pub description: Option<String>,
}
pub fn parse_units(value: &str) -> Result<u64> {
    let (whole, fraction) = value.split_once('.').unwrap_or((value, ""));
    if whole.is_empty()
        || !whole.bytes().all(|b| b.is_ascii_digit())
        || fraction.len() > 8
        || !fraction.bytes().all(|b| b.is_ascii_digit())
        || value.ends_with('.')
    {
        return Err(Error::invalid("invalid decimal amount"));
    }
    let whole = whole.parse::<u64>().map_err(|_| Error::invalid("amount overflow"))?;
    let frac =
        if fraction.is_empty() { 0 } else { fraction.parse::<u64>().map_err(|_| Error::invalid("invalid amount"))? };
    whole
        .checked_mul(100_000_000)
        .and_then(|w| w.checked_add(frac * 10u64.pow(8 - fraction.len() as u32)))
        .filter(|v| *v > 0)
        .ok_or_else(|| Error::invalid("amount overflow or zero"))
}
fn decode(value: &str) -> Result<String> {
    let mut bytes = Vec::new();
    let mut input = value.bytes();
    while let Some(b) = input.next() {
        if b == b'%' {
            let a = input.next().and_then(|v| (v as char).to_digit(16));
            let c = input.next().and_then(|v| (v as char).to_digit(16));
            match (a, c) {
                (Some(a), Some(c)) => bytes.push((a * 16 + c) as u8),
                _ => return Err(Error::invalid("invalid URI escape")),
            }
        } else {
            bytes.push(b)
        }
    }
    String::from_utf8(bytes).map_err(|_| Error::invalid("invalid URI text"))
}
fn escape(value: &str) -> String {
    value
        .bytes()
        .map(|b| {
            if b.is_ascii_alphanumeric() || b"-._~".contains(&b) {
                (b as char).to_string()
            } else {
                format!("%{b:02X}")
            }
        })
        .collect()
}
pub fn parse(input: &str, network: AppNetwork) -> Result<ExactPaymentRequest> {
    let raw = input.trim();
    if raw.len() > 8192 || raw.contains('#') {
        return Err(Error::invalid("invalid payment request"));
    }
    let (path, query) = raw.split_once('?').unwrap_or((raw, ""));
    let (scheme, address) = match path.split_once(':') {
        Some((s, a)) => (Some(s.to_ascii_lowercase()), a),
        None => (None, path),
    };
    let validated = parse_payment_request(address, network)?;
    let chain = match validated.network {
        NetworkType::Bitcoin => ChainId::Bitcoin,
        NetworkType::Liquid => ChainId::Liquid,
        _ => return Err(Error::invalid("unsupported network")),
    };
    if let Some(s) = scheme {
        if !matches!(
            (s.as_str(), chain),
            ("bitcoin", ChainId::Bitcoin) | ("liquidnetwork", ChainId::Liquid) | ("liquid", ChainId::Liquid)
        ) {
            return Err(Error::invalid("payment network mismatch"));
        }
    }
    let mut result = ExactPaymentRequest {
        chain,
        address: validated.address,
        asset_id: None,
        amount_units: None,
        description: None,
    };
    let mut seen = std::collections::BTreeSet::new();
    for parameter in query.split('&').filter(|p| !p.is_empty()) {
        let (key, value) = parameter.split_once('=').ok_or_else(|| Error::invalid("invalid URI parameter"))?;
        let key = decode(key)?;
        let value = decode(value)?;
        if !seen.insert(key.clone()) {
            return Err(Error::invalid("duplicate URI parameter"));
        }
        match key.as_str() {
            "amount" => result.amount_units = Some(parse_units(&value)?),
            "assetid" => {
                if chain != ChainId::Liquid || value.len() != 64 || !value.bytes().all(|b| b.is_ascii_hexdigit()) {
                    return Err(Error::invalid("invalid asset ID"));
                }
                result.asset_id = Some(value.to_ascii_lowercase());
            }
            "message" => result.description = Some(value),
            "label" => {}
            key if key.starts_with("req-") => return Err(Error::invalid("unsupported required URI parameter")),
            _ => {}
        }
    }
    Ok(result)
}
pub fn encode(request: &ExactPaymentRequest) -> Result<String> {
    let scheme = match request.chain {
        ChainId::Bitcoin => "bitcoin",
        ChainId::Liquid => "liquidnetwork",
        _ => return Err(Error::invalid("unsupported network")),
    };
    let mut params = Vec::new();
    if let Some(id) = &request.asset_id {
        params.push(format!("assetid={}", escape(id)));
    }
    if let Some(amount) = request.amount_units {
        if amount == 0 {
            return Err(Error::invalid("amount must be positive"));
        }
        params.push(format!("amount={}.{:08}", amount / 100_000_000, amount % 100_000_000));
    }
    if let Some(description) = &request.description {
        if !description.is_empty() {
            params.push(format!("message={}", escape(description)));
        }
    }
    Ok(format!(
        "{scheme}:{}{}",
        request.address,
        if params.is_empty() { String::new() } else { format!("?{}", params.join("&")) }
    ))
}
