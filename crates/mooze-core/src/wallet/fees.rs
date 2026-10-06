//! Fee helpers: Bitcoin fee estimates from the Blockstream and BitGo
//! providers, Liquid fee rate rules and the Pix purchase fee.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use crate::domain::FeePriority;
use crate::ports::{HttpClient, HttpRequest};
use crate::Result;

/// Blockstream esplora fee endpoint.
pub const BLOCKSTREAM_FEE_URL: &str = "https://blockstream.info/api/fee-estimates";
/// BitGo fee endpoint.
pub const BITGO_FEE_URL: &str = "https://www.bitgo.com/api/v2/btc/tx/fee";
/// Timeout of one fee provider request (5 s).
pub const FEE_PROVIDER_TIMEOUT_MS: u64 = 5_000;

/// Bitcoin fee rates in sat/vB.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BitcoinFeeEstimate {
    pub low_fee_sat_per_vbyte: u64,
    pub medium_fee_sat_per_vbyte: u64,
    pub fast_fee_sat_per_vbyte: u64,
    /// Raw rate per confirmation target (blocks as string key).
    pub fee_by_block_target: BTreeMap<String, f64>,
}

fn ceil_u64(v: f64) -> u64 {
    if v.is_finite() && v > 0.0 {
        v.ceil() as u64
    } else {
        0
    }
}

impl BitcoinFeeEstimate {
    /// Parses an esplora `fee-estimates` map (target blocks -> sat/vB).
    ///
    /// fast = 1 or 2 blocks (else 4), medium = 3 or 6 (else 3), low = 144 (else 1).
    pub fn from_esplora(fee_by_block: BTreeMap<String, f64>) -> Self {
        let get = |k: &str| fee_by_block.get(k).copied();
        let fast = ceil_u64(get("1").or(get("2")).unwrap_or(4.0));
        let medium = ceil_u64(get("3").or(get("6")).unwrap_or(3.0));
        let low = ceil_u64(get("144").unwrap_or(1.0));
        Self {
            low_fee_sat_per_vbyte: low,
            medium_fee_sat_per_vbyte: medium,
            fast_fee_sat_per_vbyte: fast,
            fee_by_block_target: fee_by_block,
        }
    }

    /// Same as [`Self::from_esplora`] for the `u16` map `bdk_esplora` returns.
    pub fn from_esplora_targets(map: &std::collections::HashMap<u16, f64>) -> Self {
        Self::from_esplora(map.iter().map(|(k, v)| (k.to_string(), *v)).collect())
    }

    /// Parses the BitGo body. Values are sat/kvB; low is always 1.
    pub fn from_bitgo(body: &serde_json::Value) -> Result<Self> {
        let raw = body
            .get("feeByBlockTarget")
            .and_then(|v| v.as_object())
            .ok_or_else(|| crate::Error::protocol("bitgo: feeByBlockTarget missing"))?;
        let mut fee_by_block = BTreeMap::new();
        for (k, v) in raw {
            let n = v.as_i64().ok_or_else(|| crate::Error::protocol("bitgo: fee is not an int"))?;
            fee_by_block.insert(k.clone(), n as f64 / 1000.0);
        }
        let fast = fee_by_block.get("1").map(|v| ceil_u64(*v)).unwrap_or(4);
        let medium = fee_by_block.get("3").map(|v| ceil_u64(*v)).unwrap_or(3);
        Ok(Self {
            low_fee_sat_per_vbyte: 1,
            medium_fee_sat_per_vbyte: medium,
            fast_fee_sat_per_vbyte: fast,
            fee_by_block_target: fee_by_block,
        })
    }

    /// Fallback when every provider fails.
    pub fn default_estimate() -> Self {
        Self {
            low_fee_sat_per_vbyte: 1,
            medium_fee_sat_per_vbyte: 3,
            fast_fee_sat_per_vbyte: 5,
            fee_by_block_target: [("1", 5.0), ("3", 3.0), ("6", 2.0), ("144", 1.0)]
                .into_iter()
                .map(|(k, v)| (k.to_owned(), v))
                .collect(),
        }
    }

    /// Rate for a user priority: low, medium, or fast.
    pub fn rate_for(&self, priority: FeePriority) -> u64 {
        match priority {
            FeePriority::Low => self.low_fee_sat_per_vbyte,
            FeePriority::Medium => self.medium_fee_sat_per_vbyte,
            FeePriority::High => self.fast_fee_sat_per_vbyte,
        }
    }
}

/// Fetches fee estimates from Blockstream, then BitGo.
#[derive(Debug, Clone)]
pub struct BitcoinFeeService<H: HttpClient> {
    http: H,
}

impl<H: HttpClient> BitcoinFeeService<H> {
    /// Service over an HTTP client.
    pub fn new(http: H) -> Self {
        Self { http }
    }

    async fn fetch(&self, url: &str) -> Option<serde_json::Value> {
        let req = HttpRequest::get(url).timeout_ms(FEE_PROVIDER_TIMEOUT_MS);
        let resp = self.http.send(req).await.ok()?;
        if resp.status != 200 {
            return None;
        }
        serde_json::from_slice(&resp.body).ok()
    }

    /// First provider that answers. `None` if all fail.
    pub async fn fetch_fee_estimate(&self) -> Option<BitcoinFeeEstimate> {
        if let Some(body) = self.fetch(BLOCKSTREAM_FEE_URL).await {
            let map: Option<BTreeMap<String, f64>> = serde_json::from_value(body).ok();
            if let Some(map) = map {
                return Some(BitcoinFeeEstimate::from_esplora(map));
            }
        }
        if let Some(body) = self.fetch(BITGO_FEE_URL).await {
            if let Ok(e) = BitcoinFeeEstimate::from_bitgo(&body) {
                return Some(e);
            }
        }
        None
    }
}

/// Liquid fee rate rules.
pub mod liquid_fee_rate {
    /// Floor in sat/kvB.
    pub const MIN_SAT_PER_KVB: f64 = 100.0;
    /// Rate used when the caller gives none.
    pub const DEFAULT_SAT_PER_KVB: f64 = MIN_SAT_PER_KVB;

    /// sat/vB to sat/kvB, floored at [`MIN_SAT_PER_KVB`].
    pub fn from_sat_per_vb(sat_per_vb: Option<f64>) -> f64 {
        match sat_per_vb {
            Some(v) if v.is_finite() && v > 0.0 => (v * 1000.0).max(MIN_SAT_PER_KVB),
            _ => DEFAULT_SAT_PER_KVB,
        }
    }

    /// sat/kvB to sat/vB.
    pub fn to_sat_per_vb(sat_per_kvb: f64) -> f64 {
        sat_per_kvb / 1000.0
    }
}

/// Pix purchase fee as a fraction.
///
/// `fiat_amount_cents` is in BRL cents. For `asset_id == "lbtc"` the
/// amount is divided by 1.02 first (liquidity provider spread).
pub fn pix_fee_fraction(asset_id: &str, fiat_amount_cents: u64, has_referral: bool) -> f64 {
    let mut reais = fiat_amount_cents as f64 / 100.0;
    if asset_id == "lbtc" {
        reais /= 1.02;
    }
    let mut base = if reais >= 5000.0 {
        2.75
    } else if reais >= 500.0 {
        3.25
    } else {
        3.5
    };
    if has_referral {
        base -= 0.5;
    }
    base / 100.0
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ports::HttpMethod;
    use crate::testing::{block_on, MockHttp};

    #[test]
    fn esplora_parsing() {
        let body: BTreeMap<String, f64> =
            serde_json::from_str(r#"{"1":12.3,"2":10.0,"3":8.01,"6":5.0,"144":1.2}"#).unwrap();
        let e = BitcoinFeeEstimate::from_esplora(body);
        assert_eq!((e.fast_fee_sat_per_vbyte, e.medium_fee_sat_per_vbyte, e.low_fee_sat_per_vbyte), (13, 9, 2));
        assert_eq!(e.rate_for(FeePriority::High), 13);
        assert_eq!(e.rate_for(FeePriority::Low), 2);

        let sparse: BTreeMap<String, f64> = serde_json::from_str(r#"{"2":7.5,"6":4.2}"#).unwrap();
        let e = BitcoinFeeEstimate::from_esplora(sparse);
        assert_eq!((e.fast_fee_sat_per_vbyte, e.medium_fee_sat_per_vbyte, e.low_fee_sat_per_vbyte), (8, 5, 1));
        let empty = BitcoinFeeEstimate::from_esplora(BTreeMap::new());
        assert_eq!((empty.fast_fee_sat_per_vbyte, empty.medium_fee_sat_per_vbyte), (4, 3));
    }

    #[test]
    fn bitgo_parsing_divides_by_1000() {
        let body = serde_json::json!({"feeByBlockTarget": {"1": 15500, "3": 9000, "6": 4000}});
        let e = BitcoinFeeEstimate::from_bitgo(&body).unwrap();
        assert_eq!((e.fast_fee_sat_per_vbyte, e.medium_fee_sat_per_vbyte, e.low_fee_sat_per_vbyte), (16, 9, 1));
        assert!(BitcoinFeeEstimate::from_bitgo(&serde_json::json!({})).is_err());
    }

    #[test]
    fn service_falls_back_to_bitgo_then_none() {
        let http = MockHttp::new();
        http.once_raw(HttpMethod::Get, BLOCKSTREAM_FEE_URL, 500, "down");
        http.once_json(HttpMethod::Get, BITGO_FEE_URL, 200, serde_json::json!({"feeByBlockTarget": {"1": 2000}}));
        let svc = BitcoinFeeService::new(http.clone());
        let e = block_on(svc.fetch_fee_estimate()).unwrap();
        assert_eq!(e.fast_fee_sat_per_vbyte, 2);
        assert_eq!(http.requests()[0].timeout_ms, Some(FEE_PROVIDER_TIMEOUT_MS));

        let http = MockHttp::new();
        http.once_json(HttpMethod::Get, BLOCKSTREAM_FEE_URL, 200, serde_json::json!({"1": 3.0}));
        let e = block_on(BitcoinFeeService::new(http).fetch_fee_estimate()).unwrap();
        assert_eq!(e.fast_fee_sat_per_vbyte, 3);

        let http = MockHttp::new();
        http.once_raw(HttpMethod::Get, BLOCKSTREAM_FEE_URL, 404, "");
        http.once_raw(HttpMethod::Get, BITGO_FEE_URL, 404, "");
        assert!(block_on(BitcoinFeeService::new(http).fetch_fee_estimate()).is_none());
        assert_eq!(BitcoinFeeEstimate::default_estimate().fast_fee_sat_per_vbyte, 5);
    }

    #[test]
    fn liquid_fee_rate_floor() {
        use liquid_fee_rate::*;
        assert_eq!(from_sat_per_vb(None), 100.0);
        assert_eq!(from_sat_per_vb(Some(0.01)), 100.0);
        assert_eq!(from_sat_per_vb(Some(-1.0)), 100.0);
        assert_eq!(from_sat_per_vb(Some(f64::NAN)), 100.0);
        assert_eq!(from_sat_per_vb(Some(0.25)), 250.0);
        assert_eq!(to_sat_per_vb(250.0), 0.25);
    }

    #[test]
    fn pix_fee_tiers() {
        assert_eq!(pix_fee_fraction("depix", 10_000, false), 0.035);
        assert_eq!(pix_fee_fraction("depix", 50_000, false), 0.0325);
        assert_eq!(pix_fee_fraction("depix", 500_000, true), 0.0225);
        // 510.00 BRL / 1.02 = 500.00 -> middle tier.
        assert_eq!(pix_fee_fraction("lbtc", 51_000, false), 0.0325);
        assert_eq!(pix_fee_fraction("lbtc", 50_999, false), 0.035);
    }
}
