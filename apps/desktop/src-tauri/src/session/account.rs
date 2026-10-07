use super::*;
use mooze_core::user::{
    compute_user_levels, fetch_wallet_levels, User, WalletLevelsResponse, DAILY_LIMIT_BRL,
};

fn account_view(user: &User, levels: &WalletLevelsResponse) -> Result<AccountLevelDto> {
    if !(0..=3).contains(&user.spending_level)
        || !user.level_progress.is_finite()
        || !(0.0..=1.0).contains(&user.level_progress)
        || !user.allowed_spending.is_finite()
        || user.allowed_spending < 0.0
        || !user.daily_spending.is_finite()
        || user.daily_spending < 0.0
        || levels.to_levels().iter().any(|level| {
            level.limits.min_limit < 0 || level.limits.max_limit < level.limits.min_limit
        })
    {
        return Err(DesktopError::new(
            "service",
            "Dados de nível indisponíveis.",
        ));
    }
    let data = compute_user_levels(user, levels)?;
    let mut tiers: Vec<_> = levels
        .to_levels()
        .into_iter()
        .map(|level| AccountTierDto {
            order: level.level_type.index() as u32,
            key: level.level_type.key().into(),
            minimum_brl: level.limits.min_limit_in_reais(),
            maximum_brl: level.limits.max_limit_in_reais(),
        })
        .collect();
    tiers.sort_by_key(|tier| tier.order);
    Ok(AccountLevelDto {
        current_level: data.current_level().key().into(),
        next_level: data.next_level().map(|level| level.key().into()),
        progress: data.level_progress,
        per_transaction_brl: data.allowed_spending,
        minimum_brl: data.absolute_min_limit,
        daily_limit_brl: DAILY_LIMIT_BRL,
        spent_today_brl: data.daily_spending,
        remaining_today_brl: data.remaining_limit,
        tiers,
    })
}

impl<P: Platform + Clone> WalletSession<P> {
    pub async fn account_level(&self) -> Result<AccountLevelDto> {
        let (generation, app) = self.service_app().await?;
        if self.backend_status().await?.state != "Ready" {
            return Err(DesktopError::new(
                "unavailable",
                "Dados de nível indisponíveis.",
            ));
        }
        let response = self
            .run_session_service(
                generation,
                app.api_request(HttpMethodDto::Get, "/users/me".into(), None),
            )
            .await??;
        if !(200..300).contains(&response.status) {
            return Err(DesktopError::new(
                "unavailable",
                "Dados de nível indisponíveis.",
            ));
        }
        let json = serde_json::from_str(&response.body)
            .map_err(|_| DesktopError::new("service", "Dados de nível indisponíveis."))?;
        let user = User::from_json(&json)?;
        let http = self.platform.http();
        let levels = self
            .run_session_service(generation, fetch_wallet_levels(&http))
            .await??;
        self.same_generation(generation)?;
        account_view(&user, &levels)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn fixtures() -> (User, WalletLevelsResponse) {
        let user = User::from_json(&serde_json::json!({"user_id":"preview", "verification_level":0,
            "allowed_spending":40000, "daily_spending":12500, "spending_level":1, "level_progress":0.4})).unwrap();
        let levels = WalletLevelsResponse::from_json_str(r#"{"data":{"bronze":{"min_limit":2000,"max_limit":25000},"silver":{"min_limit":2000,"max_limit":50000},"gold":{"min_limit":2000,"max_limit":100000},"diamond":{"min_limit":2000,"max_limit":300000}}}"#).unwrap();
        (user, levels)
    }
    #[test]
    fn uses_shared_rules_and_converts_cents_once() {
        let (user, levels) = fixtures();
        let view = account_view(&user, &levels).unwrap();
        assert_eq!(view.current_level, "silver");
        assert_eq!(view.next_level.as_deref(), Some("gold"));
        assert_eq!(view.per_transaction_brl, 400.0);
        assert_eq!(view.spent_today_brl, 125.0);
        assert_eq!(view.remaining_today_brl, DAILY_LIMIT_BRL - 125.0);
        assert_eq!(view.tiers[3].maximum_brl, 3000.0);
    }
    #[test]
    fn rejects_unknown_tiers_and_handles_max_level() {
        let (mut user, levels) = fixtures();
        user.spending_level = 4;
        assert!(account_view(&user, &levels).is_err());
        user.spending_level = 3;
        user.daily_spending = 900000.0;
        let view = account_view(&user, &levels).unwrap();
        assert!(view.next_level.is_none());
        assert_eq!(view.remaining_today_brl, 0.0);
    }
}
