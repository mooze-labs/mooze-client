//! Wallet levels and spending limits.
//!
//! Titles, descriptions, icons and colors are UI and stay in the app.

use serde::de::{Deserializer, MapAccess, Visitor};
use serde::{Deserialize, Serialize};

use super::entities::User;
use crate::ports::{HttpClient, HttpRequest};
use crate::{Error, Result};

/// Public JSON with the limits of each level.
pub const WALLET_LEVELS_URL: &str = "https://mooze-public.s3.us-east-1.amazonaws.com/user_levels.json";

/// Fixed daily limit in BRL.
pub const DAILY_LIMIT_BRL: f64 = 5000.0;

/// Highest spending level (diamond).
pub const MAX_SPENDING_LEVEL: i64 = 3;

/// Per-level limits in BRL cents.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct WalletLevelLimits {
    /// JSON `max_limit`.
    pub max_limit: i64,
    /// JSON `min_limit`.
    pub min_limit: i64,
}

impl WalletLevelLimits {
    /// Max limit in BRL.
    pub fn max_limit_in_reais(&self) -> f64 {
        self.max_limit as f64 / 100.0
    }

    /// Min limit in BRL.
    pub fn min_limit_in_reais(&self) -> f64 {
        self.min_limit as f64 / 100.0
    }
}

/// Level tier.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum WalletLevelType {
    /// Level 0.
    Bronze,
    /// Level 1.
    Silver,
    /// Level 2.
    Gold,
    /// Level 3.
    Diamond,
}

impl WalletLevelType {
    /// Parses a JSON key, ignoring case. Unknown keys give `None`.
    pub fn from_key(key: &str) -> Option<Self> {
        match key.to_lowercase().as_str() {
            "bronze" => Some(Self::Bronze),
            "silver" => Some(Self::Silver),
            "gold" => Some(Self::Gold),
            "diamond" => Some(Self::Diamond),
            _ => None,
        }
    }

    /// Tier for a `spending_level`. Unknown levels map to bronze.
    pub fn from_spending_level(level: i64) -> Self {
        match level {
            1 => Self::Silver,
            2 => Self::Gold,
            3 => Self::Diamond,
            _ => Self::Bronze,
        }
    }

    /// Lower-case JSON key.
    pub fn key(self) -> &'static str {
        match self {
            Self::Bronze => "bronze",
            Self::Silver => "silver",
            Self::Gold => "gold",
            Self::Diamond => "diamond",
        }
    }

    /// Spending level number, 0 to 3.
    pub fn index(self) -> i64 {
        self as i64
    }
}

/// One tier with its limits, without UI text.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WalletLevel {
    /// Tier.
    pub level_type: WalletLevelType,
    /// Limits.
    pub limits: WalletLevelLimits,
}

/// Parsed `user_levels.json`. Keeps the JSON key order.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct WalletLevelsResponse {
    /// `(key, limits)` in document order.
    pub data: Vec<(String, WalletLevelLimits)>,
}

impl WalletLevelsResponse {
    /// Parses the JSON text.
    pub fn from_json_str(text: &str) -> Result<Self> {
        Ok(serde_json::from_str(text)?)
    }

    /// Limits for an exact key (case-sensitive).
    pub fn get(&self, key: &str) -> Option<&WalletLevelLimits> {
        self.data.iter().find(|(k, _)| k == key).map(|(_, v)| v)
    }

    /// Known tiers in document order. Unknown keys are skipped.
    pub fn to_levels(&self) -> Vec<WalletLevel> {
        self.data
            .iter()
            .filter_map(|(k, limits)| {
                WalletLevelType::from_key(k).map(|t| WalletLevel { level_type: t, limits: *limits })
            })
            .collect()
    }

    /// The first tier of `level_type`.
    pub fn level_by_type(&self, level_type: WalletLevelType) -> Result<WalletLevel> {
        self.to_levels()
            .into_iter()
            .find(|l| l.level_type == level_type)
            .ok_or_else(|| Error::protocol(format!("level {} not found", level_type.key())))
    }
}

impl<'de> Deserialize<'de> for WalletLevelsResponse {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> std::result::Result<Self, D::Error> {
        #[derive(Deserialize)]
        struct Raw {
            data: OrderedLimits,
        }
        let raw = Raw::deserialize(deserializer)?;
        Ok(Self { data: raw.data.0 })
    }
}

impl Serialize for WalletLevelsResponse {
    fn serialize<S: serde::Serializer>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error> {
        use serde::ser::SerializeMap;
        struct Data<'a>(&'a [(String, WalletLevelLimits)]);
        impl Serialize for Data<'_> {
            fn serialize<S: serde::Serializer>(&self, s: S) -> std::result::Result<S::Ok, S::Error> {
                let mut map = s.serialize_map(Some(self.0.len()))?;
                for (k, v) in self.0 {
                    map.serialize_entry(k, v)?;
                }
                map.end()
            }
        }
        let mut map = serializer.serialize_map(Some(1))?;
        map.serialize_entry("data", &Data(&self.data))?;
        map.end()
    }
}

struct OrderedLimits(Vec<(String, WalletLevelLimits)>);

impl<'de> Deserialize<'de> for OrderedLimits {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> std::result::Result<Self, D::Error> {
        struct V;
        impl<'de> Visitor<'de> for V {
            type Value = OrderedLimits;
            fn expecting(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
                f.write_str("a map of level limits")
            }
            fn visit_map<A: MapAccess<'de>>(self, mut map: A) -> std::result::Result<OrderedLimits, A::Error> {
                let mut out = Vec::new();
                while let Some((k, v)) = map.next_entry::<String, WalletLevelLimits>()? {
                    out.push((k, v));
                }
                Ok(OrderedLimits(out))
            }
        }
        deserializer.deserialize_map(V)
    }
}

/// Fetches `user_levels.json` (plain GET, no auth).
pub async fn fetch_wallet_levels<H: HttpClient>(http: &H) -> Result<WalletLevelsResponse> {
    http.send(HttpRequest::get(WALLET_LEVELS_URL)).await?.json()
}

/// User limits combined with the level table.
/// All amounts are BRL (cents divided by 100).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct UserLevelsData {
    /// 0 to 3.
    pub spending_level: i64,
    /// 0.0 to 1.0.
    pub level_progress: f64,
    /// Limit per transaction.
    pub allowed_spending: f64,
    /// Amount spent today.
    pub daily_spending: f64,
    /// Min limit of the current level.
    pub current_level_min_limit: f64,
    /// Max limit of the current level.
    pub current_level_max_limit: f64,
    /// Bronze min limit.
    pub absolute_min_limit: f64,
    /// Diamond max limit.
    pub absolute_max_limit: f64,
    /// `DAILY_LIMIT_BRL - daily_spending`, clamped to `[0, DAILY_LIMIT_BRL]`.
    pub remaining_limit: f64,
}

impl UserLevelsData {
    /// Current tier.
    pub fn current_level(&self) -> WalletLevelType {
        WalletLevelType::from_spending_level(self.spending_level)
    }

    /// Next tier, `None` at the top.
    pub fn next_level(&self) -> Option<WalletLevelType> {
        if self.spending_level >= MAX_SPENDING_LEVEL {
            return None;
        }
        match self.spending_level + 1 {
            1 => Some(WalletLevelType::Silver),
            2 => Some(WalletLevelType::Gold),
            3 => Some(WalletLevelType::Diamond),
            _ => None,
        }
    }

    /// `daily_spending / DAILY_LIMIT_BRL`, clamped to `[0, 1]`.
    pub fn daily_limit_progress(&self) -> f64 {
        (self.daily_spending / DAILY_LIMIT_BRL).clamp(0.0, 1.0)
    }

    /// True at diamond.
    pub fn is_max_level(&self) -> bool {
        self.spending_level >= MAX_SPENDING_LEVEL
    }
}

/// Combines the user with the level table.
/// Errors if the current level, `bronze` or `diamond` is missing.
pub fn compute_user_levels(user: &User, levels: &WalletLevelsResponse) -> Result<UserLevelsData> {
    let allowed_spending = user.allowed_spending / 100.0;
    let daily_spending = user.daily_spending / 100.0;
    let key = WalletLevelType::from_spending_level(user.spending_level).key();
    let current = levels.get(key).ok_or_else(|| Error::protocol(format!("Data for level {key} not found")))?;
    let diamond = levels.get("diamond").ok_or_else(|| Error::protocol("Data for diamond level not found"))?;
    let bronze = levels.get("bronze").ok_or_else(|| Error::protocol("Data for bronze level not found"))?;
    Ok(UserLevelsData {
        spending_level: user.spending_level,
        level_progress: user.level_progress,
        allowed_spending,
        daily_spending,
        current_level_min_limit: current.min_limit_in_reais(),
        current_level_max_limit: current.max_limit_in_reais(),
        absolute_min_limit: bronze.min_limit_in_reais(),
        absolute_max_limit: diamond.max_limit_in_reais(),
        remaining_limit: (DAILY_LIMIT_BRL - daily_spending).clamp(0.0, DAILY_LIMIT_BRL),
    })
}

/// One row of the built-in level table, without UI fields.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct DefaultUserLevel {
    /// 0 to 3.
    pub order: i64,
    /// English name.
    pub name: &'static str,
    /// Min amount in BRL.
    pub min_amount: f64,
    /// Max amount in BRL.
    pub max_amount: f64,
}

/// Built-in level table.
pub const DEFAULT_USER_LEVELS: [DefaultUserLevel; 4] = [
    DefaultUserLevel { order: 0, name: "Bronze", min_amount: 20.0, max_amount: 250.0 },
    DefaultUserLevel { order: 1, name: "Silver", min_amount: 20.0, max_amount: 500.0 },
    DefaultUserLevel { order: 2, name: "Gold", min_amount: 20.0, max_amount: 1000.0 },
    DefaultUserLevel { order: 3, name: "Diamond", min_amount: 20.0, max_amount: 3000.0 },
];

/// Default level by order. `None` out of range.
pub fn default_level_by_order(order: i64) -> Option<&'static DefaultUserLevel> {
    DEFAULT_USER_LEVELS.iter().find(|l| l.order == order)
}

/// Next default level. `None` at the top.
pub fn default_next_level(current_order: i64) -> Option<&'static DefaultUserLevel> {
    if current_order >= DEFAULT_USER_LEVELS.len() as i64 - 1 {
        return None;
    }
    default_level_by_order(current_order + 1)
}

/// First default level whose `[min, max]` contains `amount`, else the last one.
///
/// NOTE: every level starts at 20, so amounts 20..=250 always give bronze.
pub fn default_level_by_amount(amount: f64) -> &'static DefaultUserLevel {
    DEFAULT_USER_LEVELS
        .iter()
        .find(|l| amount >= l.min_amount && amount <= l.max_amount)
        .unwrap_or(&DEFAULT_USER_LEVELS[3])
}

/// Progress of `current` within `[min, max]`, clamped to `[0, 1]`.
/// Returns 0 for an empty or negative range.
pub fn calculate_progress(current_amount: f64, min_level_limit: f64, max_level_limit: f64) -> f64 {
    let range = max_level_limit - min_level_limit;
    if range <= 0.0 {
        return 0.0;
    }
    ((current_amount - min_level_limit) / range).clamp(0.0, 1.0)
}

/// Progress against the built-in table.
pub fn calculate_progress_legacy(current_amount: f64, current_order: i64) -> f64 {
    let Some(level) = default_level_by_order(current_order) else {
        return 0.0;
    };
    let range = level.max_amount - level.min_amount;
    if range == f64::INFINITY {
        return 1.0;
    }
    ((current_amount - level.min_amount) / range).clamp(0.0, 1.0)
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::ports::HttpMethod;
    use crate::testing::{block_on, MockHttp};
    use crate::user::entities::user_fixture;

    /// Shape of the S3 file. Key order is deliberately not alphabetical.
    const LEVELS_JSON: &str = r#"{
      "data": {
        "bronze":  {"max_limit": 25000,   "min_limit": 2000},
        "silver":  {"max_limit": 50000,   "min_limit": 2000},
        "gold":    {"max_limit": 100000,  "min_limit": 2000},
        "diamond": {"max_limit": 300000, "min_limit": 2000},
        "platinum": {"max_limit": 1, "min_limit": 1}
      }
    }"#;

    #[test]
    fn parses_levels_in_order() {
        let r = WalletLevelsResponse::from_json_str(LEVELS_JSON).unwrap();
        let keys: Vec<&str> = r.data.iter().map(|(k, _)| k.as_str()).collect();
        assert_eq!(keys, ["bronze", "silver", "gold", "diamond", "platinum"]);
        let levels = r.to_levels();
        assert_eq!(levels.len(), 4);
        assert_eq!(levels[3].level_type, WalletLevelType::Diamond);
        assert_eq!(levels[3].limits.max_limit_in_reais(), 3000.0);
        assert_eq!(r.level_by_type(WalletLevelType::Gold).unwrap().limits.max_limit, 100000);
        // Round trip keeps the order.
        let again = WalletLevelsResponse::from_json_str(&serde_json::to_string(&r).unwrap()).unwrap();
        assert_eq!(again, r);
    }

    #[test]
    fn rejects_bad_levels() {
        assert!(
            WalletLevelsResponse::from_json_str(r#"{"data": {"bronze": {"max_limit": 1.5, "min_limit": 0}}}"#).is_err()
        );
        assert!(WalletLevelsResponse::from_json_str(r#"{"levels": {}}"#).is_err());
    }

    #[test]
    fn fetches_from_s3() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, WALLET_LEVELS_URL, 200, serde_json::from_str(LEVELS_JSON).unwrap());
        let r = block_on(fetch_wallet_levels(&http)).unwrap();
        assert_eq!(r.data.len(), 5);
        assert!(!http.last_request().unwrap().headers.contains_key("Authorization"));
    }

    #[test]
    fn computes_limits() {
        let r = WalletLevelsResponse::from_json_str(LEVELS_JSON).unwrap();
        let user = User::from_json(&user_fixture()).unwrap();
        let d = compute_user_levels(&user, &r).unwrap();
        assert_eq!(d.allowed_spending, 500.0);
        assert_eq!(d.daily_spending, 123.45);
        assert_eq!(d.current_level_min_limit, 20.0);
        assert_eq!(d.current_level_max_limit, 500.0);
        assert_eq!(d.absolute_min_limit, 20.0);
        assert_eq!(d.absolute_max_limit, 3000.0);
        assert!((d.remaining_limit - 4876.55).abs() < 1e-9);
        assert!((d.daily_limit_progress() - 0.02469).abs() < 1e-9);
        assert_eq!(d.current_level(), WalletLevelType::Silver);
        assert_eq!(d.next_level(), Some(WalletLevelType::Gold));
        assert!(!d.is_max_level());
    }

    #[test]
    fn limit_clamps_and_fallbacks() {
        let r = WalletLevelsResponse::from_json_str(LEVELS_JSON).unwrap();
        let mut user = User::from_json(&user_fixture()).unwrap();
        user.daily_spending = 700_000.0; // R$ 7000 > daily limit
        user.spending_level = 9; // unknown -> bronze
        let d = compute_user_levels(&user, &r).unwrap();
        assert_eq!(d.remaining_limit, 0.0);
        assert_eq!(d.daily_limit_progress(), 1.0);
        assert_eq!(d.current_level_max_limit, 250.0);
        assert!(d.is_max_level());
        assert_eq!(d.next_level(), None);

        let no_diamond =
            WalletLevelsResponse::from_json_str(r#"{"data": {"bronze": {"max_limit": 1, "min_limit": 0}}}"#).unwrap();
        user.spending_level = 0;
        assert!(compute_user_levels(&user, &no_diamond).is_err());
    }

    #[test]
    fn default_table() {
        assert_eq!(default_level_by_order(2).unwrap().name, "Gold");
        assert!(default_level_by_order(4).is_none());
        assert_eq!(default_next_level(0).unwrap().order, 1);
        assert!(default_next_level(3).is_none());
        assert_eq!(default_level_by_amount(100.0).order, 0);
        assert_eq!(default_level_by_amount(800.0).order, 2);
        assert_eq!(default_level_by_amount(5.0).order, 3);
        assert_eq!(default_level_by_amount(99_999.0).order, 3);
    }

    #[test]
    fn progress() {
        assert_eq!(calculate_progress(260.0, 20.0, 500.0), 0.5);
        assert_eq!(calculate_progress(10.0, 20.0, 500.0), 0.0);
        assert_eq!(calculate_progress(900.0, 20.0, 500.0), 1.0);
        assert_eq!(calculate_progress(5.0, 10.0, 10.0), 0.0);
        assert_eq!(calculate_progress_legacy(135.0, 0), 0.5);
        assert_eq!(calculate_progress_legacy(135.0, 7), 0.0);
    }
}
