//! User entities. Port of `lib/shared/user/entities/**`.

use std::collections::BTreeMap;

use serde_json::Value;

use crate::api::data_or_self;
use crate::{Error, Result};

/// The backend user (`GET /users/me`).
///
/// NOTE(port): spending fields are BRL cents sent as JSON numbers; Dart keeps
/// them as `double`, so the core does too.
#[derive(Debug, Clone, PartialEq)]
pub struct User {
    /// JSON `user_id`.
    pub id: String,
    /// JSON `verification_level`.
    pub verification_level: i64,
    /// JSON `referred_by`.
    pub referred_by: Option<String>,
    /// JSON `allowed_spending`, BRL cents.
    pub allowed_spending: f64,
    /// JSON `daily_spending`, BRL cents.
    pub daily_spending: f64,
    /// JSON `spending_level`, 0 (bronze) to 3 (diamond).
    pub spending_level: i64,
    /// JSON `level_progress`, 0.0 to 1.0.
    pub level_progress: f64,
    /// JSON `to_receive`: asset id to BRL cents.
    pub values_to_receive: BTreeMap<String, i64>,
}

impl User {
    /// Parses `{data: {...}}` or the flat shape (Dart `User.fromJson`).
    pub fn from_json(json: &Value) -> Result<Self> {
        let data = data_or_self(json);
        let mut values_to_receive = BTreeMap::new();
        if let Some(map) = data.get("to_receive").and_then(Value::as_object) {
            for (key, value) in map {
                if let Some(i) = value.as_i64() {
                    values_to_receive.insert(key.clone(), i);
                } else if let Some(f) = value.as_f64() {
                    // Dart `num.toInt()` truncates.
                    values_to_receive.insert(key.clone(), f.trunc() as i64);
                }
            }
        }
        Ok(Self {
            id: req_str(data, "user_id")?,
            verification_level: req_int(data, "verification_level")?,
            referred_by: data.get("referred_by").and_then(Value::as_str).map(str::to_owned),
            allowed_spending: req_num(data, "allowed_spending")?,
            daily_spending: req_num(data, "daily_spending")?,
            spending_level: req_int(data, "spending_level")?,
            level_progress: req_num(data, "level_progress")?,
            values_to_receive,
        })
    }
}

fn req_str(v: &Value, key: &str) -> Result<String> {
    v.get(key).and_then(Value::as_str).map(str::to_owned).ok_or_else(|| missing(key))
}

fn req_int(v: &Value, key: &str) -> Result<i64> {
    v.get(key).and_then(Value::as_i64).ok_or_else(|| missing(key))
}

fn req_num(v: &Value, key: &str) -> Result<f64> {
    v.get(key).and_then(Value::as_f64).ok_or_else(|| missing(key))
}

fn missing(key: &str) -> Error {
    Error::protocol(format!("user: `{key}` missing or wrong type"))
}

/// Direction of a level change.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LevelChangeType {
    /// New level is higher.
    Upgrade,
    /// New level is lower (or equal, as in Dart).
    Downgrade,
}

/// A spending level change between two `/users/me` fetches.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LevelChange {
    /// Previous level.
    pub old_level: i64,
    /// Current level.
    pub new_level: i64,
    /// Direction.
    pub change_type: LevelChangeType,
}

impl LevelChange {
    /// New change. `new > old` is an upgrade, anything else a downgrade.
    pub fn new(old_level: i64, new_level: i64) -> Self {
        let change_type = if new_level > old_level { LevelChangeType::Upgrade } else { LevelChangeType::Downgrade };
        Self { old_level, new_level, change_type }
    }

    /// True for an upgrade.
    pub fn is_upgrade(&self) -> bool {
        self.change_type == LevelChangeType::Upgrade
    }

    /// True for a downgrade.
    pub fn is_downgrade(&self) -> bool {
        self.change_type == LevelChangeType::Downgrade
    }

    /// Absolute level difference.
    pub fn level_difference(&self) -> i64 {
        (self.new_level - self.old_level).abs()
    }
}

#[cfg(test)]
pub(crate) fn user_fixture() -> Value {
    serde_json::json!({
        "data": {
            "user_id": "8f14e45f-ceea-467f-a0e6-8b4f0e3c1a2b",
            "verification_level": 1,
            "referred_by": "MOOZE10",
            "allowed_spending": 50000,
            "daily_spending": 12345.0,
            "spending_level": 1,
            "level_progress": 0.42,
            "to_receive": {
                "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189": 15000,
                "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d": 2500.9,
                "ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2": 700,
                "bogus": "x"
            }
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_user() {
        let u = User::from_json(&user_fixture()).unwrap();
        assert_eq!(u.id, "8f14e45f-ceea-467f-a0e6-8b4f0e3c1a2b");
        assert_eq!(u.referred_by.as_deref(), Some("MOOZE10"));
        assert_eq!(u.allowed_spending, 50000.0);
        assert_eq!(u.daily_spending, 12345.0);
        assert_eq!(u.spending_level, 1);
        assert_eq!(u.values_to_receive.len(), 3);
        assert_eq!(u.values_to_receive["6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d"], 2500);
    }

    #[test]
    fn rejects_missing_fields() {
        assert!(User::from_json(&serde_json::json!({"user_id": "x"})).is_err());
        assert!(User::from_json(&serde_json::json!({
            "user_id": "x", "verification_level": 1.5, "allowed_spending": 1, "daily_spending": 1,
            "spending_level": 0, "level_progress": 0
        }))
        .is_err());
    }

    #[test]
    fn level_change() {
        let up = LevelChange::new(0, 2);
        assert!(up.is_upgrade());
        assert_eq!(up.level_difference(), 2);
        assert!(LevelChange::new(2, 1).is_downgrade());
        assert!(LevelChange::new(1, 1).is_downgrade());
    }
}
