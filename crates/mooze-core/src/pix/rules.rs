//! Pure PIX business rules: fees, amount validation, polling policy,
//! status notifications, history refresh, filters and paging.
//!
//! Sources: `fee_rate_provider.dart`, `pix_fee_info_card.dart`,
//! `deposit_validation_provider.dart`, `pix_repository_impl.dart` (polling),
//! `pix_status_listener.dart`, `pix_history_controller.dart`,
//! `pix_filter_entity.dart`, `pix_history_state_notifier.dart`,
//! `send_controller.dart` (withdraw polling).
//!
//! BRL amounts are `f64` reais, as in Dart. Stored amounts use integer cents.

use std::collections::BTreeSet;

use super::entities::{
    DepositStatus, PixDeposit, PixStatusEvent, PixTransactionDetails, WithdrawStatus,
};

// ---------------------------------------------------------------- fees

/// Deposits up to this BRL amount pay the fixed fees.
pub const FIXED_FEE_RATE_THRESHOLD: f64 = 55.00;
/// Fixed Mooze fee in BRL.
pub const FIXED_FEE_MOOZE: f64 = 1.00;
/// Fixed payment processor fee in BRL.
pub const FIXED_FEE_PROCESSOR: f64 = 1.00;
/// Fee multiplier for users with a referral (15% off).
pub const REFERRAL_FEE_FACTOR: f64 = 0.85;
/// Deposits below this BRL amount pay [`FEE_RATE_LOW_PERCENT`].
pub const FEE_RATE_TIER_LIMIT: f64 = 500.0;
/// Percent fee below [`FEE_RATE_TIER_LIMIT`].
pub const FEE_RATE_LOW_PERCENT: f64 = 3.5;
/// Percent fee at or above [`FEE_RATE_TIER_LIMIT`].
pub const FEE_RATE_HIGH_PERCENT: f64 = 3.0;
/// Fee tier bounds `(min, max)` in BRL, as shown in the fee card.
pub const FEE_TIER_BOUNDS: [(f64, f64); 3] = [(20.0, 55.0), (55.0, 500.0), (500.0, 3000.0)];

/// Percent fee rate for a deposit amount in BRL.
pub fn fee_rate_percent(deposit_amount: f64, has_referral: bool) -> f64 {
    let mut rate = if deposit_amount < FEE_RATE_TIER_LIMIT {
        FEE_RATE_LOW_PERCENT
    } else {
        FEE_RATE_HIGH_PERCENT
    };
    if has_referral {
        rate *= REFERRAL_FEE_FACTOR;
    }
    rate
}

/// Fee in BRL for a deposit amount in BRL.
pub fn fee_amount(deposit_amount: f64, has_referral: bool) -> f64 {
    if deposit_amount <= FIXED_FEE_RATE_THRESHOLD {
        return FIXED_FEE_MOOZE + FIXED_FEE_PROCESSOR;
    }
    deposit_amount / 100.0 * fee_rate_percent(deposit_amount, has_referral)
}

/// BRL amount left after fees. The asset amount is computed from this.
pub fn discounted_deposit_amount(deposit_amount: f64, has_referral: bool) -> f64 {
    if deposit_amount <= FIXED_FEE_RATE_THRESHOLD {
        return deposit_amount - (FIXED_FEE_MOOZE + FIXED_FEE_PROCESSOR);
    }
    deposit_amount - fee_amount(deposit_amount, has_referral) - FIXED_FEE_PROCESSOR
}

/// Fee before the referral discount, from a discounted fee (UI "saved" math).
pub fn fee_before_referral(discounted_fee: f64) -> f64 {
    discounted_fee / REFERRAL_FEE_FACTOR
}

/// Estimated asset amount in whole units: discounted BRL / BRL price.
pub fn estimated_asset_units(deposit_amount: f64, has_referral: bool, quote_brl: f64) -> f64 {
    discounted_deposit_amount(deposit_amount, has_referral) / quote_brl
}

/// Index into [`FEE_TIER_BOUNDS`] for the fee card, or `None` for no amount.
pub fn active_fee_tier(amount: f64) -> Option<usize> {
    if amount <= 0.0 {
        return None;
    }
    if amount <= FIXED_FEE_RATE_THRESHOLD {
        return Some(0);
    }
    let last = FEE_TIER_BOUNDS.len() - 1;
    (1..FEE_TIER_BOUNDS.len()).find(|&i| i == last || amount < FEE_TIER_BOUNDS[i].1)
}

/// BRL amount to cents, truncated like Dart `(amount * 100).toInt()`.
///
// NOTE(port): truncation can lose one cent (e.g. 0.29 * 100 = 28.999...).
// Dart does the same. Negative or NaN input returns 0.
pub fn amount_in_cents(amount_brl: f64) -> u64 {
    let c = amount_brl * 100.0;
    if c.is_finite() && c > 0.0 {
        c as u64
    } else {
        0
    }
}

// ---------------------------------------------------------------- validation

/// User level limits in BRL, from the user module (`levelsProvider`).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct DepositLimits {
    /// Lowest deposit allowed.
    pub absolute_min_limit: f64,
    /// Highest deposit allowed now.
    pub allowed_spending: f64,
}

/// Why a deposit amount is not valid.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DepositValidationError {
    /// Zero or negative amount.
    InvalidAmount,
    /// Below the minimum.
    BelowMinimum,
    /// Above the per-transaction limit.
    AboveTransaction,
    /// Above the remaining limit. Dart declares it but never returns it.
    AboveRemaining,
}

/// Result of [`validate_deposit_amount`].
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct DepositValidation {
    /// `None` when valid.
    pub error: Option<DepositValidationError>,
    /// The limit that the amount broke, in BRL.
    pub limit_amount: Option<f64>,
}

impl DepositValidation {
    /// True if no error.
    pub fn is_valid(&self) -> bool {
        self.error.is_none()
    }

    fn valid() -> Self {
        Self {
            error: None,
            limit_amount: None,
        }
    }

    fn err(error: DepositValidationError, limit: Option<f64>) -> Self {
        Self {
            error: Some(error),
            limit_amount: limit,
        }
    }
}

/// Validates a deposit amount in BRL.
///
/// Pass `None` for `limits` while levels load or after they fail: Dart then
/// treats every positive amount as valid.
pub fn validate_deposit_amount(amount: f64, limits: Option<&DepositLimits>) -> DepositValidation {
    if amount <= 0.0 || amount.is_nan() {
        return DepositValidation::err(DepositValidationError::InvalidAmount, None);
    }
    let Some(l) = limits else {
        return DepositValidation::valid();
    };
    if amount < l.absolute_min_limit {
        return DepositValidation::err(
            DepositValidationError::BelowMinimum,
            Some(l.absolute_min_limit),
        );
    }
    if amount > l.allowed_spending {
        return DepositValidation::err(
            DepositValidationError::AboveTransaction,
            Some(l.allowed_spending),
        );
    }
    DepositValidation::valid()
}

// ---------------------------------------------------------------- deposit polling

/// Time between deposit status polls.
pub const DEPOSIT_POLL_INTERVAL_MS: u64 = 30_000;
/// Polling stops and the deposit expires after this time.
pub const DEPOSIT_POLL_MAX_DURATION_MS: u64 = 21 * 60_000;

/// What the platform must do on a poll tick.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PollTick {
    /// Fetch the status and pass the result to [`DepositPoll::on_fetch`].
    Fetch,
    /// Time is up. Emit and persist this event. Polling is over.
    Expired(PixStatusEvent),
    /// Polling is already over. Do nothing.
    Done,
}

/// Result of one status fetch.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PollStep {
    /// Status still pending, or the fetch failed. Poll again later.
    Continue,
    /// The backend returned no item. Polling stops without an event.
    Stop,
    /// Status changed. Emit and persist this event. Polling is over.
    Changed(PixStatusEvent),
}

/// Polling state of one new deposit. Port of `_startPollingPixStatus`.
///
/// The platform calls [`DepositPoll::tick`] every
/// [`DEPOSIT_POLL_INTERVAL_MS`], starting one interval after creation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DepositPoll {
    /// Deposit being polled.
    pub deposit_id: String,
    /// Polling start time.
    pub started_ms: u64,
    finished: bool,
}

impl DepositPoll {
    /// Starts polling at `now_ms`.
    pub fn new(deposit_id: impl Into<String>, now_ms: u64) -> Self {
        Self {
            deposit_id: deposit_id.into(),
            started_ms: now_ms,
            finished: false,
        }
    }

    /// True after expiry, a status change or an empty answer.
    pub fn is_finished(&self) -> bool {
        self.finished
    }

    /// Time of the first tick.
    pub fn first_tick_at_ms(&self) -> u64 {
        self.started_ms + DEPOSIT_POLL_INTERVAL_MS
    }

    /// Stops polling (repository disposed).
    pub fn cancel(&mut self) {
        self.finished = true;
    }

    /// Decides what one tick does.
    pub fn tick(&mut self, now_ms: u64) -> PollTick {
        if self.finished {
            return PollTick::Done;
        }
        if now_ms.saturating_sub(self.started_ms) > DEPOSIT_POLL_MAX_DURATION_MS {
            self.finished = true;
            return PollTick::Expired(PixStatusEvent::new(
                self.deposit_id.clone(),
                DepositStatus::Expired,
            ));
        }
        PollTick::Fetch
    }

    /// Applies a fetch result. Pass `None` when the fetch failed.
    ///
    // NOTE(port): Dart reads `deposits.first`, not the item with this id.
    pub fn on_fetch(&mut self, result: Option<&[PixTransactionDetails]>) -> PollStep {
        if self.finished {
            return PollStep::Stop;
        }
        let Some(list) = result else {
            return PollStep::Continue;
        };
        let Some(first) = list.first() else {
            self.finished = true;
            return PollStep::Stop;
        };
        let status = DepositStatus::from_api_str(&first.status);
        if status == DepositStatus::Pending {
            return PollStep::Continue;
        }
        self.finished = true;
        PollStep::Changed(PixStatusEvent {
            deposit_id: self.deposit_id.clone(),
            status,
            blockchain_txid: first.blockchain_txid.clone(),
            asset_amount: first.asset_amount,
            error_message: None,
        })
    }
}

// ---------------------------------------------------------------- notifications

/// Screen the app shows for a status event.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PixNotification {
    /// Show the success screen and refresh user data.
    Success { deposit_id: String },
    /// Show the error screen and refresh user data.
    Failure {
        deposit_id: String,
        error_message: Option<String>,
    },
}

/// Statuses that trigger the success screen.
pub const SUCCESS_NOTIFY_STATUSES: [DepositStatus; 3] = [
    DepositStatus::UnderReview,
    DepositStatus::DepixSent,
    DepositStatus::Paid,
];

/// Deduplicating status listener. Port of `PixStatusListener` logic.
#[derive(Debug, Clone, Default)]
pub struct PixNotificationFilter {
    processed: BTreeSet<String>,
}

impl PixNotificationFilter {
    /// Empty filter.
    pub fn new() -> Self {
        Self::default()
    }

    /// Returns the notification for `event`, at most once per deposit.
    pub fn on_event(&mut self, event: &PixStatusEvent) -> Option<PixNotification> {
        if self.processed.contains(&event.deposit_id) {
            return None;
        }
        if SUCCESS_NOTIFY_STATUSES.contains(&event.status) {
            self.processed.insert(event.deposit_id.clone());
            Some(PixNotification::Success {
                deposit_id: event.deposit_id.clone(),
            })
        } else if event.status == DepositStatus::Failed {
            self.processed.insert(event.deposit_id.clone());
            Some(PixNotification::Failure {
                deposit_id: event.deposit_id.clone(),
                error_message: event.error_message.clone(),
            })
        } else {
            None
        }
    }
}

// ---------------------------------------------------------------- history

/// Statuses the history screen does not refresh from the backend.
pub const HISTORY_TERMINAL_STATUSES: [DepositStatus; 2] =
    [DepositStatus::Expired, DepositStatus::Refunded];

/// History page size.
pub const HISTORY_PAGE_SIZE: u64 = 50;

/// Ids of deposits the history screen refreshes.
///
// NOTE(port): Dart refreshes every non-expired, non-refunded deposit,
// including finished ones.
pub fn deposits_to_refresh(deposits: &[PixDeposit]) -> Vec<String> {
    deposits
        .iter()
        .filter(|d| !HISTORY_TERMINAL_STATUSES.contains(&d.status))
        .map(|d| d.deposit_id.clone())
        .collect()
}

/// True if a page of `count` items can have a next page.
pub fn history_has_more(count: usize) -> bool {
    count as u64 == HISTORY_PAGE_SIZE
}

/// Offset of the page after `offset`.
pub fn history_next_offset(offset: u64) -> u64 {
    offset + HISTORY_PAGE_SIZE
}

/// History filters. Port of `PixFiltersEntity`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PixFilters {
    /// Dart enum name (`underReview`) or `all`. `None` keeps every status.
    pub status: Option<String>,
    /// Asset ids to keep. Empty keeps every asset.
    pub asset_ids: Vec<String>,
    /// Keep deposits created at or after this time.
    pub start_ms: Option<u64>,
    /// Keep deposits created at or before this time. Pass the end of the
    /// selected day (23:59:59.999 local time); the platform knows the zone.
    pub end_of_day_ms: Option<u64>,
    /// Newest first when `None` or `true`.
    pub order_by_most_recent: Option<bool>,
}

/// Filters and sorts deposits. Port of `applyFilters`.
pub fn apply_filters(deposits: &[PixDeposit], f: &PixFilters) -> Vec<PixDeposit> {
    let mut out: Vec<PixDeposit> = deposits
        .iter()
        .filter(|d| match f.status.as_deref() {
            Some(s) if s != "all" => d.status.dart_name() == s,
            _ => true,
        })
        .filter(|d| f.asset_ids.is_empty() || f.asset_ids.iter().any(|a| a == d.asset.id()))
        .filter(|d| f.start_ms.is_none_or(|s| d.created_at_ms >= s))
        .filter(|d| f.end_of_day_ms.is_none_or(|e| d.created_at_ms <= e))
        .cloned()
        .collect();
    if f.order_by_most_recent.unwrap_or(true) {
        out.sort_by_key(|d| std::cmp::Reverse(d.created_at_ms));
    } else {
        out.sort_by_key(|d| d.created_at_ms);
    }
    out
}

// ---------------------------------------------------------------- withdraw polling

/// Time between withdraw status polls.
pub const WITHDRAW_POLL_INTERVAL_MS: u64 = 3_000;
/// Maximum withdraw status polls.
pub const WITHDRAW_POLL_MAX_ATTEMPTS: u32 = 60;

/// True for `completed` and `failed`.
pub fn is_withdraw_terminal(status: &str) -> bool {
    status == "completed" || status == "failed"
}

/// Withdraw polling state. Port of `pollWithdrawStatus`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct WithdrawPoll {
    attempts: u32,
    done: bool,
}

impl WithdrawPoll {
    /// Fresh state.
    pub fn new() -> Self {
        Self::default()
    }

    /// True if the platform must fetch the status now.
    pub fn should_poll(&self) -> bool {
        !self.done && self.attempts < WITHDRAW_POLL_MAX_ATTEMPTS
    }

    /// Records a result (`None` on error). Returns true to poll again after
    /// [`WITHDRAW_POLL_INTERVAL_MS`].
    pub fn on_result(&mut self, status: Option<&WithdrawStatus>) -> bool {
        if status.is_some_and(|s| is_withdraw_terminal(&s.status)) {
            self.done = true;
            return false;
        }
        self.attempts += 1;
        self.should_poll()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::Asset;

    fn close(a: f64, b: f64) -> bool {
        (a - b).abs() < 1e-9
    }

    #[test]
    fn fee_math() {
        assert!(close(fee_amount(55.0, false), 2.0));
        assert!(close(discounted_deposit_amount(50.0, true), 48.0));
        assert!(close(fee_rate_percent(100.0, false), 3.5));
        assert!(close(fee_rate_percent(500.0, false), 3.0));
        assert!(close(fee_rate_percent(100.0, true), 2.975));
        assert!(close(fee_amount(100.0, false), 3.5));
        assert!(close(discounted_deposit_amount(100.0, false), 95.5));
        assert!(close(discounted_deposit_amount(1000.0, false), 969.0));
        assert!(close(fee_before_referral(2.975), 3.5));
        assert!(close(estimated_asset_units(100.0, false, 5.0), 19.1));
    }

    #[test]
    fn fee_tiers() {
        assert_eq!(active_fee_tier(0.0), None);
        assert_eq!(active_fee_tier(55.0), Some(0));
        assert_eq!(active_fee_tier(55.01), Some(1));
        assert_eq!(active_fee_tier(499.99), Some(1));
        assert_eq!(active_fee_tier(500.0), Some(2));
        assert_eq!(active_fee_tier(9000.0), Some(2));
    }

    #[test]
    fn cents() {
        assert_eq!(amount_in_cents(10.0), 1000);
        assert_eq!(amount_in_cents(0.29), 28);
        assert_eq!(amount_in_cents(-1.0), 0);
    }

    #[test]
    fn validation() {
        let l = DepositLimits {
            absolute_min_limit: 20.0,
            allowed_spending: 3000.0,
        };
        assert_eq!(
            validate_deposit_amount(0.0, Some(&l)).error,
            Some(DepositValidationError::InvalidAmount)
        );
        assert!(validate_deposit_amount(1.0, None).is_valid());
        let v = validate_deposit_amount(19.99, Some(&l));
        assert_eq!(v.error, Some(DepositValidationError::BelowMinimum));
        assert_eq!(v.limit_amount, Some(20.0));
        assert!(validate_deposit_amount(20.0, Some(&l)).is_valid());
        assert!(validate_deposit_amount(3000.0, Some(&l)).is_valid());
        assert_eq!(
            validate_deposit_amount(3000.01, Some(&l)).error,
            Some(DepositValidationError::AboveTransaction)
        );
    }

    fn details(status: &str) -> PixTransactionDetails {
        PixTransactionDetails {
            id: "dep-1".into(),
            status: status.into(),
            amount_in_cents: 1000,
            blockchain_txid: Some("tx".into()),
            asset_amount: Some(42),
        }
    }

    #[test]
    fn poll_transitions() {
        let mut p = DepositPoll::new("dep-1", 0);
        assert_eq!(p.first_tick_at_ms(), 30_000);
        assert_eq!(p.tick(30_000), PollTick::Fetch);
        assert_eq!(p.on_fetch(None), PollStep::Continue);
        assert_eq!(p.on_fetch(Some(&[details("pending")])), PollStep::Continue);
        match p.on_fetch(Some(&[details("depix_sent")])) {
            PollStep::Changed(e) => {
                assert_eq!(e.status, DepositStatus::DepixSent);
                assert_eq!(e.asset_amount, Some(42));
            }
            other => panic!("{other:?}"),
        }
        assert!(p.is_finished());
        assert_eq!(p.tick(60_000), PollTick::Done);

        let mut p = DepositPoll::new("dep-2", 1_000);
        assert_eq!(p.on_fetch(Some(&[])), PollStep::Stop);

        let mut p = DepositPoll::new("dep-3", 0);
        assert_eq!(p.tick(DEPOSIT_POLL_MAX_DURATION_MS), PollTick::Fetch);
        assert_eq!(
            p.tick(DEPOSIT_POLL_MAX_DURATION_MS + 1),
            PollTick::Expired(PixStatusEvent::new("dep-3", DepositStatus::Expired))
        );
    }

    #[test]
    fn notifications_dedupe() {
        let mut f = PixNotificationFilter::new();
        assert_eq!(
            f.on_event(&PixStatusEvent::new("a", DepositStatus::Pending)),
            None
        );
        assert_eq!(
            f.on_event(&PixStatusEvent::new("a", DepositStatus::Paid)),
            Some(PixNotification::Success {
                deposit_id: "a".into()
            })
        );
        assert_eq!(
            f.on_event(&PixStatusEvent::new("a", DepositStatus::Failed)),
            None
        );
        let mut e = PixStatusEvent::new("b", DepositStatus::Failed);
        e.error_message = Some("boom".into());
        assert_eq!(
            f.on_event(&e),
            Some(PixNotification::Failure {
                deposit_id: "b".into(),
                error_message: Some("boom".into())
            })
        );
    }

    fn dep(id: &str, status: DepositStatus, asset: Asset, at: u64) -> PixDeposit {
        PixDeposit {
            deposit_id: id.into(),
            pix_key: "k".into(),
            asset,
            amount_in_cents: 100,
            network: "liquid".into(),
            status,
            created_at_ms: at,
            blockchain_txid: None,
            asset_amount: None,
        }
    }

    #[test]
    fn history_and_filters() {
        let list = vec![
            dep("a", DepositStatus::Expired, Asset::Depix, 10),
            dep("b", DepositStatus::UnderReview, Asset::Lbtc, 30),
            dep("c", DepositStatus::Finished, Asset::Depix, 20),
        ];
        assert_eq!(deposits_to_refresh(&list), vec!["b", "c"]);
        assert!(history_has_more(50));
        assert!(!history_has_more(49));
        assert_eq!(history_next_offset(50), 100);

        let ids = |v: Vec<PixDeposit>| v.into_iter().map(|d| d.deposit_id).collect::<Vec<_>>();
        assert_eq!(
            ids(apply_filters(&list, &PixFilters::default())),
            vec!["b", "c", "a"]
        );
        let f = PixFilters {
            status: Some("underReview".into()),
            ..Default::default()
        };
        assert_eq!(ids(apply_filters(&list, &f)), vec!["b"]);
        let f = PixFilters {
            asset_ids: vec![Asset::Depix.id().into()],
            start_ms: Some(10),
            end_of_day_ms: Some(20),
            order_by_most_recent: Some(false),
            ..Default::default()
        };
        assert_eq!(ids(apply_filters(&list, &f)), vec!["a", "c"]);
    }

    #[test]
    fn withdraw_poll() {
        let mut p = WithdrawPoll::new();
        let processing = WithdrawStatus {
            status: "processing".into(),
            withdraw_id: "w".into(),
            txid: None,
            error_message: None,
            completed_at: None,
        };
        assert!(p.should_poll());
        assert!(p.on_result(Some(&processing)));
        assert!(p.on_result(None));
        let done = WithdrawStatus {
            status: "completed".into(),
            ..processing.clone()
        };
        assert!(!p.on_result(Some(&done)));
        assert!(!p.should_poll());

        let mut p = WithdrawPoll::new();
        for _ in 0..59 {
            assert!(p.on_result(None));
        }
        assert!(!p.on_result(None));
    }
}
