//! User API calls and referral flow. Port of `UserServiceImpl`,
//! `UserLevelStorageService` and `features/referral_input/**` (data/domain).

use serde_json::{json, Value};

use super::entities::{LevelChange, User};
use crate::api::{encode_path_segment, MoozeApi, SessionProvider};
use crate::ports::{HttpClient, HttpMethod, KvStore};
use crate::{Error, Result};

/// Preferences key of the last seen spending level.
/// NOTE(port): Dart names it "verification level" but stores `spending_level`.
pub const STORED_LEVEL_KEY: &str = "user_verification_level";

/// `POST /users/me/referral` answered 400.
pub const REFERRAL_CODE_INVALID: &str = "referral_code_invalid";
/// `POST /users/me/referral` answered 409.
pub const REFERRAL_CODE_ALREADY_USED: &str = "referral_code_already_used";
/// Apply use case: empty code.
pub const REFERRAL_ERROR_EMPTY_CODE: &str = "referral_error_empty_code";
/// Apply use case: validation failed or the code is invalid.
pub const REFERRAL_ERROR_INVALID_CODE: &str = "referral_error_invalid_code";
/// Apply use case: the apply call failed.
pub const REFERRAL_ERROR_APPLY_FAILED: &str = "referral_error_apply_failed";

/// Result of [`UserService::get_user`].
#[derive(Debug, Clone, PartialEq)]
pub struct UserFetch {
    /// The user.
    pub user: User,
    /// Level change since the last fetch (Dart `levelChanges` stream event).
    pub level_change: Option<LevelChange>,
}

/// User endpoints on the authenticated API.
pub struct UserService<H: HttpClient, P: SessionProvider, K: KvStore> {
    api: MoozeApi<H, P>,
    prefs: K,
}

impl<H: HttpClient, P: SessionProvider, K: KvStore> UserService<H, P, K> {
    /// New service. `prefs` stores the last seen level.
    pub fn new(api: MoozeApi<H, P>, prefs: K) -> Self {
        Self { api, prefs }
    }

    /// The API client.
    pub fn api(&self) -> &MoozeApi<H, P> {
        &self.api
    }

    /// `GET /users/me`, then level change detection.
    pub async fn get_user(&self) -> Result<UserFetch> {
        let body: Value = self.api.get_json("/users/me").await?;
        let user = User::from_json(&body)?;
        let level_change = self.detect_level_change(user.spending_level).await?;
        Ok(UserFetch { user, level_change })
    }

    /// Compares `new_level` with the stored level. Stores the new level.
    /// First run stores silently and returns `None`.
    pub async fn detect_level_change(&self, new_level: i64) -> Result<Option<LevelChange>> {
        let stored = match self.prefs.get(STORED_LEVEL_KEY).await? {
            None => None,
            Some(b) => String::from_utf8(b)
                .ok()
                .and_then(|t| t.trim().parse::<i64>().ok()),
        };
        match stored {
            None => {
                self.store_level(new_level).await?;
                Ok(None)
            }
            Some(old) if old != new_level => {
                self.store_level(new_level).await?;
                Ok(Some(LevelChange::new(old, new_level)))
            }
            Some(_) => Ok(None),
        }
    }

    /// Removes the stored level.
    pub async fn clear_stored_level(&self) -> Result<()> {
        self.prefs.delete(STORED_LEVEL_KEY).await
    }

    async fn store_level(&self, level: i64) -> Result<()> {
        self.prefs
            .put(STORED_LEVEL_KEY, level.to_string().into_bytes())
            .await
    }

    /// `GET /users/referral/{code}`.
    ///
    /// 200: `valid` (flat or under `data`), else `true`. Other 2xx: `false`.
    /// 404: `false`. Other statuses: [`Error::Http`].
    pub async fn validate_referral_code(&self, code: &str) -> Result<bool> {
        let path = format!("/users/referral/{}", encode_path_segment(code));
        let response = self.api.send(HttpMethod::Get, &path, None).await?;
        if response.status == 404 {
            return Ok(false);
        }
        let response = response.error_for_status()?;
        if response.status != 200 {
            return Ok(false);
        }
        let body: Value = serde_json::from_slice(&response.body).unwrap_or(Value::Null);
        let valid = body.get("valid").or_else(|| {
            body.get("data")
                .filter(|d| d.is_object())
                .and_then(|d| d.get("valid"))
        });
        match valid {
            None => Ok(true),
            Some(v) => v
                .as_bool()
                .ok_or_else(|| Error::protocol("referral: `valid` is not a bool")),
        }
    }

    /// `POST /users/me/referral {referral_code}`.
    /// 400 gives [`REFERRAL_CODE_INVALID`], 409 gives [`REFERRAL_CODE_ALREADY_USED`].
    pub async fn add_referral(&self, code: &str) -> Result<()> {
        let response = self
            .api
            .send(
                HttpMethod::Post,
                "/users/me/referral",
                Some(json!({"referral_code": code})),
            )
            .await?;
        match response.status {
            400 => Err(Error::InvalidInput(REFERRAL_CODE_INVALID.into())),
            409 => Err(Error::InvalidState(REFERRAL_CODE_ALREADY_USED.into())),
            _ => response.error_for_status().map(|_| ()),
        }
    }

    /// The referral code on the account, if any (Dart `GetExistingReferralUseCase`).
    pub async fn get_existing_referral(&self) -> Result<Option<String>> {
        let fetch = self.get_user().await?;
        Ok(fetch.user.referred_by.filter(|c| !c.is_empty()))
    }

    /// Validates then applies a code (Dart `ApplyReferralCodeUseCase`).
    ///
    /// Errors: empty code ([`Error::InvalidInput`] with
    /// [`REFERRAL_ERROR_EMPTY_CODE`]), invalid code or failed validation
    /// ([`REFERRAL_ERROR_INVALID_CODE`]), failed apply ([`Error::InvalidState`]
    /// with [`REFERRAL_ERROR_APPLY_FAILED`]).
    pub async fn apply_referral_code(&self, code: &str) -> Result<()> {
        if code.is_empty() {
            return Err(Error::InvalidInput(REFERRAL_ERROR_EMPTY_CODE.into()));
        }
        match self.validate_referral_code(code).await {
            Ok(true) => {}
            _ => return Err(Error::InvalidInput(REFERRAL_ERROR_INVALID_CODE.into())),
        }
        self.add_referral(code)
            .await
            .map_err(|_| Error::InvalidState(REFERRAL_ERROR_APPLY_FAILED.into()))
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::api::ApiConfig;
    use crate::ports::MaybeSend;
    use crate::testing::{block_on, MemoryKv, MockHttp};
    use crate::user::entities::user_fixture;
    use std::future::Future;

    struct StaticToken;
    impl SessionProvider for StaticToken {
        fn access_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            std::future::ready(Ok("jwt".to_owned()))
        }
        fn force_refresh_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            std::future::ready(Err(Error::Session("no".into())))
        }
    }

    fn service(http: &MockHttp) -> UserService<MockHttp, StaticToken, MemoryKv> {
        UserService::new(
            MoozeApi::new(http.clone(), StaticToken, ApiConfig::default()),
            MemoryKv::new(),
        )
    }

    const ME: &str = "https://api.mooze.app/users/me";

    #[test]
    fn get_user_detects_level_changes() {
        let http = MockHttp::new();
        let svc = service(&http);
        http.on_json(HttpMethod::Get, ME, 200, user_fixture());
        let first = block_on(svc.get_user()).unwrap();
        assert_eq!(first.user.spending_level, 1);
        assert_eq!(first.level_change, None);
        assert_eq!(block_on(svc.get_user()).unwrap().level_change, None);

        let mut upgraded = user_fixture();
        upgraded["data"]["spending_level"] = json!(2);
        http.on_json(HttpMethod::Get, ME, 200, upgraded);
        let change = block_on(svc.get_user()).unwrap().level_change.unwrap();
        assert_eq!(change, LevelChange::new(1, 2));
        assert!(change.is_upgrade());
        assert_eq!(
            http.last_request().unwrap().headers["Authorization"],
            "Bearer jwt"
        );
    }

    #[test]
    fn validate_referral_variants() {
        let http = MockHttp::new();
        let svc = service(&http);
        let url = "https://api.mooze.app/users/referral/";
        http.on_json(
            HttpMethod::Get,
            &format!("{url}A1"),
            200,
            json!({"valid": false}),
        );
        http.on_json(
            HttpMethod::Get,
            &format!("{url}B2"),
            200,
            json!({"data": {"valid": true}}),
        );
        http.on_json(HttpMethod::Get, &format!("{url}C3"), 200, json!({"ok": 1}));
        http.on_json(HttpMethod::Get, &format!("{url}D4"), 404, json!({}));
        http.on_json(HttpMethod::Get, &format!("{url}E5"), 204, json!({}));
        http.on_json(HttpMethod::Get, &format!("{url}F6"), 500, json!({}));
        http.on_json(
            HttpMethod::Get,
            &format!("{url}a%20b"),
            200,
            json!({"valid": true}),
        );
        assert!(!block_on(svc.validate_referral_code("A1")).unwrap());
        assert!(block_on(svc.validate_referral_code("B2")).unwrap());
        assert!(block_on(svc.validate_referral_code("C3")).unwrap());
        assert!(!block_on(svc.validate_referral_code("D4")).unwrap());
        assert!(!block_on(svc.validate_referral_code("E5")).unwrap());
        assert!(matches!(
            block_on(svc.validate_referral_code("F6")),
            Err(Error::Http { status: 500, .. })
        ));
        assert!(block_on(svc.validate_referral_code("a b")).unwrap());
    }

    #[test]
    fn add_referral_status_mapping() {
        let http = MockHttp::new();
        let svc = service(&http);
        let url = "https://api.mooze.app/users/me/referral";
        http.once_json(HttpMethod::Post, url, 400, json!({}));
        assert_eq!(
            block_on(svc.add_referral("X")),
            Err(Error::InvalidInput(REFERRAL_CODE_INVALID.into()))
        );
        http.once_json(HttpMethod::Post, url, 409, json!({}));
        assert_eq!(
            block_on(svc.add_referral("X")),
            Err(Error::InvalidState(REFERRAL_CODE_ALREADY_USED.into()))
        );
        http.once_json(HttpMethod::Post, url, 201, json!({}));
        assert_eq!(block_on(svc.add_referral("X")), Ok(()));
        let body: Value =
            serde_json::from_slice(http.last_request().unwrap().body.as_ref().unwrap()).unwrap();
        assert_eq!(body, json!({"referral_code": "X"}));
    }

    #[test]
    fn apply_referral_use_case() {
        let http = MockHttp::new();
        let svc = service(&http);
        assert_eq!(
            block_on(svc.apply_referral_code("")),
            Err(Error::InvalidInput(REFERRAL_ERROR_EMPTY_CODE.into()))
        );
        http.on_json(
            HttpMethod::Get,
            "https://api.mooze.app/users/referral/BAD",
            200,
            json!({"valid": false}),
        );
        assert_eq!(
            block_on(svc.apply_referral_code("BAD")),
            Err(Error::InvalidInput(REFERRAL_ERROR_INVALID_CODE.into()))
        );
        http.on_json(
            HttpMethod::Get,
            "https://api.mooze.app/users/referral/OK",
            200,
            json!({"valid": true}),
        );
        http.once_json(
            HttpMethod::Post,
            "https://api.mooze.app/users/me/referral",
            409,
            json!({}),
        );
        assert_eq!(
            block_on(svc.apply_referral_code("OK")),
            Err(Error::InvalidState(REFERRAL_ERROR_APPLY_FAILED.into()))
        );
        http.once_json(
            HttpMethod::Post,
            "https://api.mooze.app/users/me/referral",
            200,
            json!({}),
        );
        assert_eq!(block_on(svc.apply_referral_code("OK")), Ok(()));
    }

    #[test]
    fn existing_referral() {
        let http = MockHttp::new();
        let svc = service(&http);
        http.on_json(HttpMethod::Get, ME, 200, user_fixture());
        assert_eq!(
            block_on(svc.get_existing_referral()).unwrap().as_deref(),
            Some("MOOZE10")
        );
        let mut empty = user_fixture();
        empty["data"]["referred_by"] = json!("");
        http.on_json(HttpMethod::Get, ME, 200, empty);
        assert_eq!(block_on(svc.get_existing_referral()).unwrap(), None);
    }
}
