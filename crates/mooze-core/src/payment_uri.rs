//! Payment request parsing for the send flow: QR codes, pasted text, clipboard and deep links.
//!
//! Port of `send_funds/{qr_validation_service,amount_detection_provider,network_detection_provider,
//! clean_address_provider,payment_request_applier}.dart`, `deep_links/pending_payment_link.dart`
//! and the clipboard detectors (`clipboard_address_suggestion.dart`, `PixKeyDetector`).
//! The Dart functions are prefix heuristics. They are kept as is. [`parse_payment_request`]
//! adds a strict check with `bitcoin::Address` and `elements::Address`.

use std::str::FromStr;

use bdk_wallet::bitcoin::{self, address::NetworkUnchecked};
use lwk_wollet::elements::{self, AddressParams};

use crate::domain::{AppNetwork, Asset, DEPIX_ASSET_ID, LBTC_ASSET_ID, USDT_ASSET_ID};
use crate::format::dart_parse_double;
use crate::{Error, Result};

/// Stable error codes for QR validation. Same names as the Dart enum.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum QrErrorCode {
    Empty,
    Unrecognized,
    LightningUnsupportedSymbols,
    LnurlBip353Unsupported,
    BoltzInvalid,
    BoltzNoAmount,
    LiquidInvalid,
    LiquidFormatError,
    BitcoinInvalid,
    BitcoinFormatError,
    LightningUnsupported,
    LnurlUnsupported,
}

/// Network a destination belongs to. Dart `NetworkType`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum NetworkType {
    Bitcoin,
    Liquid,
    Unknown,
}

const LIQUID_PREFIXES: [&str; 9] = ["lq1", "VJL", "VT", "VG", "H", "G", "Az", "AzQ", "ert1"];
const BITCOIN_PREFIXES: [&str; 7] = ["bc1", "3", "1", "tb1", "2", "m", "n"];
const URI_PREFIXES: [&str; 3] = ["bitcoin:", "liquidnetwork:", "liquid:"];

fn starts_any(s: &str, prefixes: &[&str]) -> bool {
    prefixes.iter().any(|p| s.starts_with(p))
}

/// Strips a case-insensitive `lightning:` prefix.
fn strip_lightning(s: &str) -> Option<&str> {
    s.get(..10)
        .filter(|p| p.eq_ignore_ascii_case("lightning:"))
        .map(|_| &s[10..])
}

fn all_digits(s: &str) -> bool {
    !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit())
}

/// Minimal Dart `Uri.parse` for `scheme:rest`: returns the path. `Err` means a format error.
fn uri_path(data: &str) -> std::result::Result<String, ()> {
    let rest = data.split_once(':').map_or(data, |(_, r)| r);
    let rest = rest.split('#').next().unwrap_or("");
    let rest = rest.split('?').next().unwrap_or("");
    match rest.strip_prefix("//") {
        Some(auth_path) => {
            let (auth, path) = auth_path
                .find('/')
                .map_or((auth_path, ""), |i| auth_path.split_at(i));
            let host_port = auth.rsplit('@').next().unwrap_or("");
            if let Some((_, port)) = host_port
                .rsplit_once(':')
                .filter(|_| !host_port.ends_with(']'))
            {
                if !port.is_empty() && !all_digits(port) {
                    return Err(());
                }
            }
            Ok(path.to_owned())
        }
        None => Ok(rest.to_owned()),
    }
}

/// Dart `QrValidationService.validateQrData`. `Ok` holds the cleaned data (the input itself).
pub fn validate_qr_data(data: &str) -> std::result::Result<String, QrErrorCode> {
    if data.is_empty() {
        return Err(QrErrorCode::Empty);
    }
    let lower = data.to_lowercase();
    let processed = strip_lightning(data).unwrap_or(data);
    let lower_processed = processed.to_lowercase();

    if lower_processed.starts_with("lnbc") && processed.chars().count() > 100 {
        return if bolt11_amount_section(&lower_processed[4..], true).is_some() {
            Ok(processed.to_owned())
        } else {
            Err(QrErrorCode::BoltzNoAmount)
        };
    }
    if ['₿', '#', '$'].iter().any(|c| data.contains(*c)) {
        return Err(QrErrorCode::LightningUnsupportedSymbols);
    }
    if lower.contains("@phoenixwallet.me")
        || (lower.starts_with("lnurl")
            && lower.contains('@')
            && !lower.contains("@walletofsatoshi.com"))
    {
        return Err(QrErrorCode::LnurlBip353Unsupported);
    }
    if lower.starts_with("liquidnetwork:") || lower.starts_with("liquid:") {
        return match uri_path(data) {
            Ok(p) if p.is_empty() => Err(QrErrorCode::LiquidInvalid),
            Ok(_) => Ok(data.to_owned()),
            Err(()) => Err(QrErrorCode::LiquidFormatError),
        };
    }
    if lower.starts_with("bitcoin:") {
        return match uri_path(data) {
            Ok(p) if p.is_empty() => Err(QrErrorCode::BitcoinInvalid),
            Ok(_) => Ok(data.to_owned()),
            Err(()) => Err(QrErrorCode::BitcoinFormatError),
        };
    }
    if lower_processed.starts_with("lnbc") {
        return Err(QrErrorCode::LightningUnsupported);
    }
    if lower.starts_with("lnurl") || lower.contains('@') {
        return Err(QrErrorCode::LnurlUnsupported);
    }
    // NOTE(port): Dart misses `ex1`, `tlq1`, `tex1`, `el1` and `Q` Liquid prefixes, and accepts
    // any text that starts with `m`, `n`, `H` or `G`. Kept for parity.
    if starts_any(data, &BITCOIN_PREFIXES) || starts_any(data, &LIQUID_PREFIXES) {
        return Ok(data.to_owned());
    }
    Err(QrErrorCode::Unrecognized)
}

/// Finds the BOLT11 amount section in `rest` (the invoice after `lnbc`, lower case).
/// Returns the section, multiplier included. `boltz_limit` caps the digit scan at 20 like
/// `_validateBoltzInvoice`.
fn bolt11_amount_section(rest: &str, boltz_limit: bool) -> Option<&str> {
    for m in ['m', 'u', 'n', 'p'] {
        if let Some(i) = rest.find(&format!("{m}1")) {
            if i > 0 && all_digits(&rest[..i]) {
                return Some(&rest[..=i]);
            }
        }
    }
    let bytes = rest.as_bytes();
    let limit = if boltz_limit {
        bytes.len().min(20)
    } else {
        bytes.len()
    };
    (1..limit)
        .find(|&i| bytes[i] == b'1' && i > 1 && all_digits(&rest[..i]))
        .map(|i| &rest[..i])
}

/// Dart `NetworkDetectionService.isLightningAddress`.
pub fn is_lightning_address(address: &str) -> bool {
    let a = address.trim().to_lowercase();
    if a.is_empty() {
        return false;
    }
    if ["lnbc", "lntb", "lnbcrt", "lightning:", "lnurl"]
        .iter()
        .any(|p| a.starts_with(p))
    {
        return true;
    }
    // ^[^@\s]+@[^@\s]+\.[^@\s]+$
    let Some((user, domain)) = a.split_once('@') else {
        return false;
    };
    let bad = |s: &str| s.is_empty() || s.chars().any(|c| c == '@' || c.is_whitespace());
    if bad(user) || bad(domain) {
        return false;
    }
    domain
        .char_indices()
        .any(|(i, c)| c == '.' && i > 0 && i + 1 < domain.len())
}

/// Dart `NetworkDetectionService.detectNetworkType`. Lightning gives `Unknown`.
pub fn detect_network_type(address: &str) -> NetworkType {
    if address.is_empty() || is_lightning_address(address) {
        return NetworkType::Unknown;
    }
    if starts_any(address, &LIQUID_PREFIXES) || starts_any(address, &["liquid:", "liquidnetwork:"])
    {
        return NetworkType::Liquid;
    }
    if starts_any(address, &BITCOIN_PREFIXES) || address.starts_with("bitcoin:") {
        return NetworkType::Bitcoin;
    }
    NetworkType::Unknown
}

fn is_liquid_address_with_params(address: &str) -> bool {
    address.contains('?') && starts_any(address.split('?').next().unwrap_or(""), &LIQUID_PREFIXES)
}

/// Dart `cleanAddressProvider`: the bare address from a URI, a `lightning:` link or `addr?query`.
pub fn clean_address(full: &str) -> String {
    if full.is_empty() {
        return String::new();
    }
    if starts_any(full, &URI_PREFIXES) {
        return uri_path(full).unwrap_or_else(|()| full.to_owned());
    }
    if let Some(rest) = strip_lightning(full) {
        return rest.to_owned();
    }
    if is_liquid_address_with_params(full) {
        return full.split('?').next().unwrap_or("").to_owned();
    }
    full.to_owned()
}

/// Dart `normalizedAddressForBreezProvider`: adds `liquidnetwork:` to `liquid-addr?query`.
pub fn normalized_address_for_breez(full: &str) -> String {
    if is_liquid_address_with_params(full)
        && !full.starts_with("liquidnetwork:")
        && !full.starts_with("liquid:")
    {
        format!("liquidnetwork:{full}")
    } else {
        full.to_owned()
    }
}

/// Dart `AmountDetectionResult`.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct AmountDetection {
    /// Amount in base units. `Some(0)` is possible for tiny amounts, as in Dart.
    pub amount_sats: Option<u64>,
    pub asset: Option<Asset>,
    pub label: Option<String>,
    pub message: Option<String>,
}

impl AmountDetection {
    /// True if the amount is present and positive.
    pub fn has_amount(&self) -> bool {
        self.amount_sats.is_some_and(|a| a > 0)
    }
}

/// Dart `AmountDetectionService.detectAmount`.
pub fn detect_amount(input: &str) -> AmountDetection {
    let clean = input.trim();
    if clean.to_lowercase().starts_with("lnbc") {
        return lightning_amount(&clean.to_lowercase());
    }
    if clean.contains('?') {
        return query_amount(clean).unwrap_or_default();
    }
    AmountDetection::default()
}

fn lightning_amount(lower: &str) -> AmountDetection {
    let base = AmountDetection {
        asset: Some(Asset::Lbtc),
        ..Default::default()
    };
    let Some(section) = bolt11_amount_section(&lower[4..], false) else {
        return AmountDetection::default();
    };
    let num = |s: &str| dart_parse_double(&s[..s.len() - 1]);
    // NOTE(port): Dart reads a bare amount as millisats; BOLT11 says whole BTC. Kept.
    let sats = match section.chars().last() {
        Some('m') => num(section).map(|b| (b * 100_000.0).round()),
        Some('u') => num(section).map(|b| (b * 100.0).round()),
        Some('n') => num(section).map(|b| (b * 0.1).round()),
        Some('p') => num(section).map(|b| (b * 0.0001).round()),
        _ => section
            .parse::<i64>()
            .ok()
            .map(|ms| (ms as f64 / 1000.0).round()),
    };
    match sats {
        Some(s) if s > 0.0 && s.is_finite() => AmountDetection {
            amount_sats: Some(s as u64),
            ..base
        },
        _ => base,
    }
}

/// Dart `Uri.decodeComponent`: strict `%XX` decoding, UTF-8 output, `+` stays `+`.
fn decode_component(s: &str) -> Option<String> {
    let b = s.as_bytes();
    let mut out = Vec::with_capacity(b.len());
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'%' {
            let hex = std::str::from_utf8(b.get(i + 1..i + 3)?).ok()?;
            out.push(u8::from_str_radix(hex, 16).ok()?);
            i += 3;
        } else {
            out.push(b[i]);
            i += 1;
        }
    }
    String::from_utf8(out).ok()
}

fn asset_from_hint(asset_id: &str, current: Asset) -> Asset {
    match asset_id {
        USDT_ASSET_ID => Asset::Usdt,
        DEPIX_ASSET_ID => Asset::Depix,
        LBTC_ASSET_ID => Asset::Lbtc,
        _ => current,
    }
}

/// Dart `_extractQueryParameters`. `None` stands for a Dart exception (empty result).
fn query_amount(address: &str) -> Option<AmountDetection> {
    let parts: Vec<&str> = address.split('?').collect();
    if parts.len() != 2 {
        return Some(AmountDetection::default());
    }
    let mut params = std::collections::HashMap::new();
    for param in parts[1].split('&') {
        let kv: Vec<&str> = param.split('=').collect();
        if kv.len() == 2 {
            params.insert(kv[0], decode_component(kv[1])?);
        }
    }
    let base = parts[0];
    let lower = base.to_lowercase();
    let bare = base.split_once(':').map_or(base, |(_, b)| b);
    let mut asset = Asset::Btc;
    if lower.starts_with("liquidnetwork:")
        || lower.starts_with("liquid:")
        || starts_any(bare, &["lq1", "VJL", "VT", "VG"])
    {
        asset = Asset::Lbtc;
    }
    if let Some(id) = params.get("assetid").filter(|s| !s.is_empty()) {
        asset = asset_from_hint(id, asset);
    }
    let mut amount_sats = None;
    if let Some(amount) = params
        .get("amount")
        .filter(|s| !s.is_empty())
        .and_then(|s| dart_parse_double(s))
    {
        if amount > 0.0 {
            let sats = (amount * 100_000_000.0).round();
            // Dart throws on Infinity.round() and the catch returns an empty result.
            if !sats.is_finite() || sats > i64::MAX as f64 {
                return None;
            }
            amount_sats = Some(sats as u64);
        }
    }
    Some(AmountDetection {
        amount_sats,
        asset: Some(asset),
        label: params.get("label").cloned(),
        message: params.get("message").cloned(),
    })
}

/// Dart `PaymentRequestApplier.displayAddress`: strips a BIP21 scheme and query.
pub fn display_address(data: &str) -> String {
    let lower = data.to_lowercase();
    if !starts_any(&lower, &URI_PREFIXES) {
        return data.to_owned();
    }
    uri_path(data).unwrap_or_else(|()| data.to_owned())
}

/// Dart `PaymentRequestApplier.autoSwitchAsset`. Returns the new selection, if it changes.
pub fn auto_switch_asset(data: &str, current: Asset) -> Option<Asset> {
    if data.is_empty() {
        return None;
    }
    if let Some(asset) = detect_amount(data).asset {
        return Some(asset);
    }
    if !current.is_bitcoin() {
        return None;
    }
    let next = match detect_network_type(data) {
        NetworkType::Bitcoin => Asset::Btc,
        NetworkType::Liquid => Asset::Lbtc,
        NetworkType::Unknown => return None,
    };
    (next != current).then_some(next)
}

/// What [`apply_payment_request`] writes into the send form.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppliedPayment {
    /// Full request kept in the address state (amount and asset detection read it).
    pub address_state: String,
    /// Bare address shown in the text field.
    pub display: String,
    /// New asset selection, if it changes.
    pub selected_asset: Option<Asset>,
}

/// Dart `PaymentRequestApplier.apply` without the widget glue.
pub fn apply_payment_request(
    raw: &str,
    current: Asset,
) -> std::result::Result<AppliedPayment, QrErrorCode> {
    let cleaned = validate_qr_data(raw.trim())?;
    Ok(AppliedPayment {
        display: display_address(&cleaned),
        selected_asset: auto_switch_asset(&cleaned, current),
        address_state: cleaned,
    })
}

/// Clipboard text worth offering in the send flow. Dart `ClipboardAddressSuggestion._checkClipboard`.
pub fn clipboard_address_candidate(clipboard: &str, address_state_empty: bool) -> Option<String> {
    let text = clipboard.trim();
    if text.is_empty()
        || text.chars().count() > 2048
        || validate_qr_data(text).is_err()
        || !address_state_empty
    {
        return None;
    }
    Some(text.to_owned())
}

/// Dart `PixKeyDetector.looksLikePixKey`: BR Code, e-mail, EVP, phone, CPF or CNPJ.
pub fn looks_like_pix_key(value: &str) -> bool {
    let v = value.trim();
    if v.is_empty() || v.chars().count() > 1024 {
        return false;
    }
    if v.starts_with("000201") || is_pix_email(v) || is_evp(v) || is_br_phone(v) {
        return true;
    }
    let digits: String = v
        .chars()
        .filter(|c| !matches!(c, '.' | '-' | '/' | '(' | ')' | '+') && !c.is_whitespace())
        .collect();
    all_digits(&digits) && matches!(digits.len(), 11 | 13 | 14)
}

/// `^[^\s@]+@[^\s@]+\.[^\s@]{2,}$`.
fn is_pix_email(v: &str) -> bool {
    let Some((user, domain)) = v.split_once('@') else {
        return false;
    };
    let ok = |s: &str| !s.is_empty() && !s.chars().any(|c| c == '@' || c.is_whitespace());
    ok(user)
        && ok(domain)
        && domain
            .char_indices()
            .any(|(i, c)| c == '.' && i > 0 && domain[i + 1..].chars().count() >= 2)
}

/// `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`, case-insensitive.
fn is_evp(v: &str) -> bool {
    let groups: Vec<&str> = v.split('-').collect();
    groups.len() == 5
        && groups
            .iter()
            .zip([8, 4, 4, 4, 12])
            .all(|(g, n)| g.len() == n && g.bytes().all(|b| b.is_ascii_hexdigit()))
}

/// `^\+?55?\s?\(?\d{2}\)?\s?9?\d{4}-?\d{4}$` with backtracking over the optional parts.
fn is_br_phone(v: &str) -> bool {
    fn m(s: &[u8], step: usize) -> bool {
        let opt = |c: u8, next: usize| (s.first() == Some(&c) && m(&s[1..], next)) || m(s, next);
        let opt_ws = |next: usize| {
            (s.first().is_some_and(u8::is_ascii_whitespace) && m(&s[1..], next)) || m(s, next)
        };
        let digits = |n: usize, next: usize| {
            s.len() >= n && s[..n].iter().all(u8::is_ascii_digit) && m(&s[n..], next)
        };
        match step {
            0 => opt(b'+', 1),
            1 => s.first() == Some(&b'5') && m(&s[1..], 2),
            2 => opt(b'5', 3),
            3 => opt_ws(4),
            4 => opt(b'(', 5),
            5 => digits(2, 6),
            6 => opt(b')', 7),
            7 => opt_ws(8),
            8 => opt(b'9', 9),
            9 => digits(4, 10),
            10 => opt(b'-', 11),
            11 => digits(4, 12),
            _ => s.is_empty(),
        }
    }
    m(v.as_bytes(), 0)
}

/// Dart `PendingPaymentLink.schemes`.
pub const PAYMENT_SCHEMES: [&str; 3] = ["bitcoin", "liquidnetwork", "liquid"];

/// Holds an incoming payment link until the send flow can use it. Dart `PendingPaymentLink`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PendingPaymentLink {
    value: Option<String>,
}

impl PendingPaymentLink {
    /// True if `uri` has a payment scheme (case-insensitive).
    pub fn is_payment_uri(uri: &str) -> bool {
        uri.split_once(':')
            .is_some_and(|(s, _)| PAYMENT_SCHEMES.contains(&s.to_lowercase().as_str()))
    }

    /// Rebuilds `scheme:address?query` and strips leading slashes from the path.
    /// NOTE(port): like Dart `Uri`, `bitcoin://addr` puts the address in the host and loses it.
    pub fn to_raw(uri: &str) -> String {
        let (scheme, rest) = uri.split_once(':').unwrap_or(("", uri));
        let path = uri_path(uri).unwrap_or_default();
        let query = rest
            .split('#')
            .next()
            .unwrap_or("")
            .split_once('?')
            .map(|(_, q)| q)
            .unwrap_or("");
        let q = if query.is_empty() {
            String::new()
        } else {
            format!("?{query}")
        };
        format!(
            "{}:{}{q}",
            scheme.to_lowercase(),
            path.trim_start_matches('/')
        )
    }

    /// Stores `uri` if it is a payment link. Returns false otherwise.
    pub fn try_capture(&mut self, uri: &str) -> bool {
        if !Self::is_payment_uri(uri) {
            return false;
        }
        self.value = Some(Self::to_raw(uri));
        true
    }

    /// Returns the pending link and clears it.
    pub fn take(&mut self) -> Option<String> {
        self.value.take()
    }
}

/// A validated payment request with a parsed address.
#[derive(Debug, Clone, PartialEq)]
pub struct PaymentRequest {
    pub network: NetworkType,
    /// Bare address, as typed.
    pub address: String,
    pub asset: Asset,
    pub amount_sats: Option<u64>,
    pub label: Option<String>,
    pub message: Option<String>,
}

fn bitcoin_network(n: AppNetwork) -> bitcoin::Network {
    match n {
        AppNetwork::Mainnet => bitcoin::Network::Bitcoin,
        AppNetwork::Testnet => bitcoin::Network::Testnet,
        AppNetwork::Regtest => bitcoin::Network::Regtest,
    }
}

fn liquid_params(n: AppNetwork) -> &'static AddressParams {
    match n {
        AppNetwork::Mainnet => &AddressParams::LIQUID,
        AppNetwork::Testnet => &AddressParams::LIQUID_TESTNET,
        AppNetwork::Regtest => &AddressParams::ELEMENTS,
    }
}

fn is_bitcoin_address(addr: &str, n: AppNetwork) -> bool {
    bitcoin::Address::<NetworkUnchecked>::from_str(addr)
        .is_ok_and(|a| a.is_valid_for_network(bitcoin_network(n)))
}

fn is_liquid_address(addr: &str, n: AppNetwork) -> bool {
    elements::Address::from_str(addr).is_ok_and(|a| a.params == liquid_params(n))
}

/// Strict parse: Dart validation and detection, then a real address parse and network check.
///
/// Text that Dart calls unrecognized is still accepted when it parses as an address of
/// `network` (for example `ex1...` or `tlq1...`). Lightning is rejected.
pub fn parse_payment_request(raw: &str, network: AppNetwork) -> Result<PaymentRequest> {
    let raw = raw.trim();
    let cleaned = match validate_qr_data(raw) {
        Ok(c) => c,
        Err(QrErrorCode::Unrecognized)
            if is_liquid_address(raw, network) || is_bitcoin_address(raw, network) =>
        {
            raw.to_owned()
        }
        Err(code) => {
            return Err(Error::invalid(format!(
                "payment request rejected: {code:?}"
            )))
        }
    };
    let address = clean_address(&cleaned);
    let mut kind = detect_network_type(&cleaned);
    if kind == NetworkType::Unknown && !is_lightning_address(&cleaned) {
        kind = if is_liquid_address(&address, network) {
            NetworkType::Liquid
        } else {
            NetworkType::Bitcoin
        };
    }
    let valid = match kind {
        NetworkType::Bitcoin => is_bitcoin_address(&address, network),
        NetworkType::Liquid => is_liquid_address(&address, network),
        NetworkType::Unknown => {
            return Err(Error::invalid("lightning destinations are not supported"))
        }
    };
    if !valid {
        return Err(Error::invalid(format!(
            "invalid {kind:?} address for {network:?}"
        )));
    }
    let detected = detect_amount(&cleaned);
    let default = if kind == NetworkType::Bitcoin {
        Asset::Btc
    } else {
        Asset::Lbtc
    };
    let asset = detected.asset.unwrap_or(default);
    if (kind == NetworkType::Bitcoin) != (asset == Asset::Btc) {
        return Err(Error::invalid(format!(
            "asset {asset:?} does not match {kind:?} address"
        )));
    }
    Ok(PaymentRequest {
        network: kind,
        address,
        asset,
        amount_sats: detected.amount_sats,
        label: detected.label,
        message: detected.message,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use QrErrorCode as E;

    const LQ: &str = "lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t";
    const BOLTZ: &str = "lnbc500u1p53etmlpp5wrrnh9lvr0ed4zvs6khdeyff9nl05r9udmej9sv07x7jnwa98uzqdql2djkuepqw3hjqsj5gvsxzerywfjhxuccqzylxqyp2xqsp56h4m2g04mpw4lfcx7au86h3cajhxj2mysjatlvfzm6cryzqac5tq9qxpqysgqn78d8dnkm8z76nywktl5yz66pzdcf9s27scjgr5c9rferjjjge4pg8rtkg6wp622u4yvvqw0xessyfu3jl9yynjzjnac4jyqx7s65zqpu48hu2";
    const BOLTZ_NO_AMOUNT: &str = "lnbc1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq8rkx3yf5tcsyz3d73gafnh3cax9rn449d9p5uxz9ezhhypd0elx87sjle52x86fux2ypatgddc6k63n7erqz25le42c4u4ecky03ylcqca784w";
    const BC1: &str = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh";

    /// Liquid addresses built from the secp256k1 generator point.
    fn liquid(params: &'static AddressParams, confidential: bool, nested: bool) -> String {
        use lwk_wollet::elements::bitcoin::{secp256k1, PublicKey};
        let g = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let pk = PublicKey::from_str(g).unwrap();
        let blinder = confidential.then(|| secp256k1::PublicKey::from_str(g).unwrap());
        let a = if nested {
            elements::Address::p2shwpkh(&pk, blinder, params)
        } else {
            elements::Address::p2wpkh(&pk, blinder, params)
        };
        a.to_string()
    }

    #[test]
    fn qr_validation_matches_dart_tests() {
        assert_eq!(validate_qr_data(BOLTZ).as_deref(), Ok(BOLTZ));
        assert_eq!(validate_qr_data(BOLTZ_NO_AMOUNT), Err(E::BoltzNoAmount));
        assert_eq!(
            validate_qr_data("lnbc1p0xlkhkpp5test"),
            Err(E::LightningUnsupported)
        );
        assert_eq!(
            validate_qr_data("lightning:lnbc10u1p0xlkhkpp5test123456789qwertyuiopasdfghjklzxcvbnm"),
            Err(E::LightningUnsupported)
        );
        for s in [
            "user₿@domain.com",
            "user#tag@domain.com",
            "user$payment@domain.com",
        ] {
            assert_eq!(validate_qr_data(s), Err(E::LightningUnsupportedSymbols));
        }
        assert_eq!(
            validate_qr_data("user@phoenixwallet.me"),
            Err(E::LnurlBip353Unsupported)
        );
        assert_eq!(
            validate_qr_data("lnurl1user@otherprovider.com"),
            Err(E::LnurlBip353Unsupported)
        );
        assert_eq!(
            validate_qr_data("user@walletofsatoshi.com"),
            Err(E::LnurlUnsupported)
        );
        assert_eq!(
            validate_qr_data("LNURL1DP68GURN8GHJ7"),
            Err(E::LnurlUnsupported)
        );
        let liq = format!("liquidnetwork:{LQ}?amount=0.00026312&label=Send%20to%20BTC%20address&assetid={LBTC_ASSET_ID}");
        assert_eq!(validate_qr_data(&liq).as_deref(), Ok(liq.as_str()));
        assert!(validate_qr_data(&format!("liquid:{LQ}?amount=0.001")).is_ok());
        assert_eq!(
            validate_qr_data("liquidnetwork:?amount=0.001"),
            Err(E::LiquidInvalid)
        );
        assert_eq!(
            validate_qr_data("liquidnetwork://host:abc/x"),
            Err(E::LiquidFormatError)
        );
        assert!(validate_qr_data(&format!("bitcoin:{BC1}?amount=0.001")).is_ok());
        assert!(validate_qr_data(
            "BITCOIN:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.5&label=Donation"
        )
        .is_ok());
        assert_eq!(
            validate_qr_data("bitcoin:?amount=0.001"),
            Err(E::BitcoinInvalid)
        );
        for s in [
            BC1,
            "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
            "3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy",
            LQ,
            "VJLCzH7NXR4xbD5jMqZmLz8yGxE6SqYk3P",
        ] {
            assert!(validate_qr_data(s).is_ok(), "{s}");
        }
        assert_eq!(validate_qr_data(""), Err(E::Empty));
        assert_eq!(
            validate_qr_data("random-invalid-qr-data-12345"),
            Err(E::Unrecognized)
        );
        assert_eq!(
            validate_qr_data(&liquid(&AddressParams::LIQUID, false, false)),
            Err(E::Unrecognized)
        ); // ex1: Dart gap
    }

    #[test]
    fn network_detection() {
        assert_eq!(detect_network_type(BC1), NetworkType::Bitcoin);
        assert_eq!(
            detect_network_type("tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"),
            NetworkType::Bitcoin
        );
        assert_eq!(
            detect_network_type(&format!("bitcoin:{BC1}")),
            NetworkType::Bitcoin
        );
        assert_eq!(detect_network_type(LQ), NetworkType::Liquid);
        assert_eq!(
            detect_network_type(&format!("liquidnetwork:{LQ}")),
            NetworkType::Liquid
        );
        assert_eq!(
            detect_network_type(&liquid(&AddressParams::LIQUID, true, true)),
            NetworkType::Liquid
        );
        assert_eq!(detect_network_type("lnbc10u1xyz"), NetworkType::Unknown);
        assert_eq!(
            detect_network_type("satoshi@bitcoin.org"),
            NetworkType::Unknown
        );
        assert_eq!(
            detect_network_type("BC1QXY2KGDYGJRSQTZQ2N0YRF2493P83KKFJHX0WLH"),
            NetworkType::Unknown
        );
        assert!(is_lightning_address(" LNURL1abc "));
        assert!(!is_lightning_address("a@b"));
        assert!(!is_lightning_address(BC1));
    }

    #[test]
    fn clean_and_display() {
        assert_eq!(clean_address(&format!("bitcoin:{BC1}?amount=1")), BC1);
        assert_eq!(clean_address(&format!("liquid:{LQ}")), LQ);
        assert_eq!(clean_address("LIGHTNING:lnbc1xyz"), "lnbc1xyz");
        assert_eq!(clean_address(&format!("{LQ}?amount=1")), LQ);
        assert_eq!(
            clean_address(&format!("{BC1}?amount=1")),
            format!("{BC1}?amount=1")
        );
        assert_eq!(clean_address(""), "");
        assert_eq!(
            normalized_address_for_breez(&format!("{LQ}?amount=1")),
            format!("liquidnetwork:{LQ}?amount=1")
        );
        assert_eq!(display_address(&format!("BITCOIN:{BC1}?amount=1")), BC1);
        assert_eq!(display_address(BC1), BC1);
    }

    #[test]
    fn amount_detection_matches_dart() {
        let d = detect_amount(BOLTZ);
        assert_eq!((d.amount_sats, d.asset), (Some(50_000), Some(Asset::Lbtc)));
        assert_eq!(
            detect_amount("lnbc500m1p0xlkhkpp5test").amount_sats,
            Some(50_000_000)
        );
        assert_eq!(
            detect_amount("lnbc50000n1p0xlkhkpp5test").amount_sats,
            Some(5_000)
        );
        assert_eq!(
            detect_amount("lnbc50000000p1p0xlkhkpp5test").amount_sats,
            Some(5_000)
        );
        assert_eq!(detect_amount("lnbc25000001pxyz").amount_sats, Some(2_500)); // millisats reading
        assert!(!detect_amount("lnbc1p0xlkhkpp5test").has_amount());
        let d = detect_amount("bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.5&label=Donation&message=Thank%20you");
        assert_eq!(
            d,
            AmountDetection {
                amount_sats: Some(50_000_000),
                asset: Some(Asset::Btc),
                label: Some("Donation".into()),
                message: Some("Thank you".into())
            }
        );
        // NOTE(port): Dart tests expect Asset::Btc here; the Dart code returns no asset without a query.
        assert_eq!(
            detect_amount(&format!("bitcoin:{BC1}")),
            AmountDetection::default()
        );
        assert_eq!(
            detect_amount(&format!("bitcoin:{BC1}?amount=0.00000001")).amount_sats,
            Some(1)
        );
        assert_eq!(
            detect_amount(&format!("bitcoin:{BC1}?amount=21")).amount_sats,
            Some(2_100_000_000)
        );
        let d = detect_amount(&format!("liquidnetwork:{LQ}?amount=0.00026312&label=Send%20to%20BTC%20address&assetid={LBTC_ASSET_ID}"));
        assert_eq!(
            (d.amount_sats, d.asset, d.label.as_deref()),
            (Some(26_312), Some(Asset::Lbtc), Some("Send to BTC address"))
        );
        assert_eq!(
            detect_amount(&format!(
                "liquidnetwork:{LQ}?amount=100&assetid={USDT_ASSET_ID}"
            ))
            .asset,
            Some(Asset::Usdt)
        );
        assert_eq!(
            detect_amount(&format!("liquid:{LQ}?assetid={DEPIX_ASSET_ID}")).asset,
            Some(Asset::Depix)
        );
        assert_eq!(
            detect_amount(&format!("liquid:{LQ}?amount=0.001&assetid=unknown")).asset,
            Some(Asset::Lbtc)
        );
        assert_eq!(
            detect_amount(&format!("{LQ}?amount=0.001")).asset,
            Some(Asset::Lbtc)
        );
        assert_eq!(
            detect_amount("VJLCzH7NXR4xbD5jMqZmLz8yGxE6SqYk3P?amount=0.5").amount_sats,
            Some(50_000_000)
        );
        assert_eq!(
            detect_amount(&format!("{BC1}?amount=0.002")).asset,
            Some(Asset::Btc)
        );
        for bad in ["0", "-0.001", "invalid", "inf"] {
            assert!(
                !detect_amount(&format!("bitcoin:{BC1}?amount={bad}")).has_amount(),
                "{bad}"
            );
        }
        assert_eq!(
            detect_amount(&format!("bitcoin:{BC1}?amount=Infinity")),
            AmountDetection::default()
        );
        assert_eq!(
            detect_amount(&format!("bitcoin:{BC1}?label=%zz")),
            AmountDetection::default()
        );
        assert_eq!(
            detect_amount(&format!("bitcoin:{BC1}?a=1?b=2")),
            AmountDetection::default()
        );
        assert_eq!(
            detect_amount("bitcoin:?amount=0.001").amount_sats,
            Some(100_000)
        );
        assert_eq!(detect_amount(""), AmountDetection::default());
    }

    #[test]
    fn applier_and_auto_switch() {
        let a = apply_payment_request(
            &format!("  liquidnetwork:{LQ}?assetid={USDT_ASSET_ID} "),
            Asset::Btc,
        )
        .unwrap();
        assert_eq!(
            (a.display.as_str(), a.selected_asset),
            (LQ, Some(Asset::Usdt))
        );
        assert_eq!(
            apply_payment_request("hello", Asset::Btc),
            Err(E::Unrecognized)
        );
        assert_eq!(auto_switch_asset(LQ, Asset::Btc), Some(Asset::Lbtc));
        assert_eq!(auto_switch_asset(LQ, Asset::Usdt), None); // user picked a token
        assert_eq!(auto_switch_asset(BC1, Asset::Btc), None);
        assert_eq!(
            auto_switch_asset(&format!("{BC1}?amount=1"), Asset::Depix),
            Some(Asset::Btc)
        );
        assert_eq!(
            clipboard_address_candidate(&format!(" {BC1}\n"), true).as_deref(),
            Some(BC1)
        );
        assert_eq!(clipboard_address_candidate(BC1, false), None);
        assert_eq!(clipboard_address_candidate("hello world", true), None);
        assert_eq!(clipboard_address_candidate(&"1".repeat(2049), true), None);
    }

    #[test]
    fn pix_keys() {
        for k in [
            "someone@example.com",
            "123.456.789-09",
            "12.345.678/0001-95",
            "+55 11 91234-5678",
            "(11) 91234-5678",
            "123e4567-e89b-12d3-a456-426614174000",
            "00020126580014br.gov.bcb.pix0136...",
        ] {
            assert!(looks_like_pix_key(k), "{k}");
        }
        for k in [
            "",
            "hello world",
            "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
            "1234",
            "a@b.c",
        ] {
            assert!(!looks_like_pix_key(k), "{k}");
        }
    }

    #[test]
    fn pending_link() {
        assert!(PendingPaymentLink::is_payment_uri("bitcoin:bc1qxyz"));
        assert!(PendingPaymentLink::is_payment_uri("LiquidNetwork:lq1abc"));
        assert!(!PendingPaymentLink::is_payment_uri("/home"));
        assert!(!PendingPaymentLink::is_payment_uri("https://x.y"));
        assert_eq!(
            PendingPaymentLink::to_raw("bitcoin:/bc1qxyz?amount=0.01"),
            "bitcoin:bc1qxyz?amount=0.01"
        );
        assert_eq!(
            PendingPaymentLink::to_raw("BITCOIN:bc1qxyz"),
            "bitcoin:bc1qxyz"
        );
        assert_eq!(
            PendingPaymentLink::to_raw("bitcoin:bc1qxyz?#frag"),
            "bitcoin:bc1qxyz"
        );
        let mut p = PendingPaymentLink::default();
        assert!(!p.try_capture("/unknown"));
        assert!(p.try_capture("bitcoin:bc1qxyz"));
        assert_eq!(p.take().as_deref(), Some("bitcoin:bc1qxyz"));
        assert_eq!(p.take(), None);
    }

    #[test]
    fn strict_bitcoin() {
        let m = AppNetwork::Mainnet;
        for a in [
            BC1,
            "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
            "32iVBEu4dxkUQk9dJbZUiBiQdmypcEyJRf",
            "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0",
        ] {
            let r = parse_payment_request(a, m).unwrap_or_else(|e| panic!("{a}: {e}"));
            assert_eq!(
                (r.network, r.asset, r.address.as_str()),
                (NetworkType::Bitcoin, Asset::Btc, a)
            );
        }
        let r =
            parse_payment_request(&format!("bitcoin:{BC1}?amount=0.001&label=Shop"), m).unwrap();
        assert_eq!(
            (r.amount_sats, r.label.as_deref()),
            (Some(100_000), Some("Shop"))
        );
        let tb = "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx";
        assert!(parse_payment_request(tb, m).is_err());
        assert_eq!(
            parse_payment_request(tb, AppNetwork::Testnet)
                .unwrap()
                .network,
            NetworkType::Bitcoin
        );
        assert!(parse_payment_request("bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlj", m).is_err()); // bad checksum
        assert!(parse_payment_request("mooze", m).is_err());
        assert!(
            parse_payment_request(&format!("bitcoin:{BC1}?assetid={USDT_ASSET_ID}"), m).is_err()
        );
        assert!(parse_payment_request(BOLTZ, m).is_err());
        assert!(parse_payment_request("user@walletofsatoshi.com", m).is_err());
    }

    #[test]
    fn strict_liquid() {
        let m = AppNetwork::Mainnet;
        let conf = liquid(&AddressParams::LIQUID, true, false);
        let nested = liquid(&AddressParams::LIQUID, true, true);
        let unconf = liquid(&AddressParams::LIQUID, false, false);
        assert!(conf.starts_with("lq1") && nested.starts_with("VJL") && unconf.starts_with("ex1"));
        for a in [&conf, &nested, &unconf] {
            let r = parse_payment_request(a, m).unwrap();
            assert_eq!(
                (r.network, r.asset),
                (NetworkType::Liquid, Asset::Lbtc),
                "{a}"
            );
        }
        let r = parse_payment_request(
            &format!("liquidnetwork:{conf}?amount=12.5&assetid={USDT_ASSET_ID}"),
            m,
        )
        .unwrap();
        assert_eq!(
            (r.asset, r.amount_sats, r.address.as_str()),
            (Asset::Usdt, Some(1_250_000_000), conf.as_str())
        );
        let r = parse_payment_request(&format!("{nested}?assetid={DEPIX_ASSET_ID}"), m).unwrap();
        assert_eq!(r.asset, Asset::Depix);
        let testnet = liquid(&AddressParams::LIQUID_TESTNET, true, false);
        assert!(testnet.starts_with("tlq1"));
        assert!(parse_payment_request(&testnet, m).is_err());
        assert_eq!(
            parse_payment_request(&testnet, AppNetwork::Testnet)
                .unwrap()
                .network,
            NetworkType::Liquid
        );
        assert!(parse_payment_request(&conf, AppNetwork::Testnet).is_err());
        let regtest = liquid(&AddressParams::ELEMENTS, false, false);
        assert_eq!(
            parse_payment_request(&regtest, AppNetwork::Regtest)
                .unwrap()
                .network,
            NetworkType::Liquid
        );
        assert!(parse_payment_request("VJLCzH7NXR4xbD5jMqZmLz8yGxE6SqYk3P", m).is_err()); // Dart test vector, not a real address
        assert!(parse_payment_request(&format!("liquidnetwork:{BC1}"), m).is_err());
    }
}
