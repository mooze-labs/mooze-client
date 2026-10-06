//! PIX deposits, favorite payers, PIX flags and taxpayer ids.
//!
//! Thin wrappers over `mooze_app`. The pure helpers call `mooze_app::rules`
//! synchronously; the `MoozeCore` methods delegate to the facade.
//!
//! The core runs no timers for Dart. After `pixCreateDeposit`, call
//! `pixPollTick` every `pixPollIntervalMs` and handle the events it returns.

use flutter_rust_bridge::frb;
use mooze_app::rules;

use super::core::{delegate, MoozeCore};
pub use super::types::*;
use crate::ports::on_runtime;

// ───────────────────────────── pure helpers

/// Interval between `pixPollTick` calls, in milliseconds.
#[frb(sync)]
pub fn pix_poll_interval_ms() -> u32 {
    rules::pix_poll_interval_ms()
}

/// Fee breakdown for `amount_brl`. Pass the asset price in BRL to get the
/// estimated asset amount.
#[frb(sync)]
pub fn pix_fee(amount_brl: f64, has_referral: bool, quote_brl: Option<f64>) -> PixFeeDto {
    rules::pix_fee(amount_brl, has_referral, quote_brl)
}

/// Validates a deposit amount in BRL. Pass `None` while the limits load:
/// every positive amount is then valid, as in Dart.
#[frb(sync)]
pub fn pix_validate_amount(
    amount_brl: f64,
    limits: Option<DepositLimitsDto>,
) -> DepositValidationDto {
    rules::pix_validate_amount(amount_brl, limits)
}

/// Validates a CPF (11 digits) or CNPJ (14 digits), masked or raw.
/// Returns `None` when valid.
#[frb(sync)]
pub fn tax_id_validate(input: String) -> Option<CpfValidationErrorDto> {
    rules::tax_id_validate(input)
}

/// True if `input` is a valid CPF or CNPJ.
#[frb(sync)]
pub fn tax_id_is_valid(input: String) -> bool {
    rules::tax_id_is_valid(input)
}

/// Keeps only the digits.
#[frb(sync)]
pub fn tax_id_strip(input: String) -> String {
    rules::tax_id_strip(input)
}

/// Formats digits as CPF (up to 11) or CNPJ (12 or more).
#[frb(sync)]
pub fn tax_id_format(digits: String) -> String {
    rules::tax_id_format(digits)
}

/// Live input mask (Dart `CpfCnpjInputFormatter`): strips, caps at 14
/// digits, formats.
#[frb(sync)]
pub fn tax_id_mask_input(text: String) -> String {
    rules::tax_id_mask_input(text)
}

/// True if `value` looks like a PIX key or a BR Code payload
/// (Dart `PixKeyDetector`).
#[frb(sync)]
pub fn pix_looks_like_key(value: String) -> bool {
    rules::pix_looks_like_key(value)
}

// ───────────────────────────── MoozeCore

impl MoozeCore {
    /// Creates a PIX deposit (Dart `PixRepository.newDeposit`).
    ///
    /// Pays to `address`, or to a new address of the connected Liquid wallet
    /// when `None`. Stores the deposit and starts polling its status. A
    /// backend failure throws with the Portuguese text the Dart UI showed.
    pub async fn pix_create_deposit(
        &self,
        amount_in_cents: u64,
        asset_id: String,
        tax_id_number: Option<String>,
        address: Option<String>,
    ) -> Result<PixDepositDto, CoreError> {
        delegate!(self.pix_create_deposit(amount_in_cents, asset_id, tax_id_number, address))
    }

    /// Runs one poll tick for every deposit created in this session and
    /// returns the status changes (Dart `statusUpdates` stream). Call it
    /// every `pixPollIntervalMs`. Expired and changed deposits stop polling.
    pub async fn pix_poll_tick(&self) -> Result<Vec<PixStatusEventDto>, CoreError> {
        delegate!(self.pix_poll_tick())
    }

    /// Number of deposits still polled.
    pub async fn pix_active_polls(&self) -> u32 {
        delegate!(self.pix_active_polls()).unwrap_or(0)
    }

    /// Stops polling every deposit (Dart `PixRepository.dispose`).
    pub async fn pix_cancel_polls(&self) {
        let _ = delegate!(self.pix_cancel_polls());
    }

    /// Reads one stored deposit.
    pub async fn pix_get_deposit(
        &self,
        deposit_id: String,
    ) -> Result<Option<PixDepositDto>, CoreError> {
        delegate!(self.pix_get_deposit(deposit_id))
    }

    /// Stored deposits, newest first. `offset` applies only with a `limit`.
    pub async fn pix_list_deposits(
        &self,
        limit: Option<u32>,
        offset: Option<u32>,
    ) -> Result<Vec<PixDepositDto>, CoreError> {
        delegate!(self.pix_list_deposits(limit, offset))
    }

    /// Refreshes deposits from the backend and returns the stored ones with
    /// these ids (Dart `updateDepositDetails`).
    pub async fn pix_update_deposit_details(
        &self,
        deposit_ids: Vec<String>,
    ) -> Result<Vec<PixDepositDto>, CoreError> {
        delegate!(self.pix_update_deposit_details(deposit_ids))
    }

    /// History page: stored deposits, with a backend refresh of the
    /// non-terminal ones (Dart `PixHistoryController`). A failed refresh
    /// returns the local data.
    pub async fn pix_history(
        &self,
        limit: Option<u32>,
        offset: Option<u32>,
    ) -> Result<Vec<PixDepositDto>, CoreError> {
        delegate!(self.pix_history(limit, offset))
    }

    /// Deletes every stored deposit and stops polling (wallet delete or import).
    pub async fn pix_clear_deposits(&self) -> Result<(), CoreError> {
        delegate!(self.pix_clear_deposits())
    }

    // ───────────────────────────── favorite payers

    /// Every favorite payer, newest first.
    pub async fn favorite_payers_list(&self) -> Result<Vec<FavoritePayerDto>, CoreError> {
        delegate!(self.favorite_payers_list())
    }

    /// Inserts (`id` null) or updates a payer, as the Dart controller does:
    /// strips the CPF mask, trims the label, refuses a CPF that another
    /// payer has. Returns the refusal reason, or `null` when saved.
    pub async fn favorite_payer_save(
        &self,
        id: Option<u64>,
        label: String,
        cpf: String,
    ) -> Result<Option<FavoritePayerSaveErrorDto>, CoreError> {
        delegate!(self.favorite_payer_save(id, label, cpf))
    }

    /// Deletes one payer.
    pub async fn favorite_payer_delete(&self, id: u64) -> Result<(), CoreError> {
        delegate!(self.favorite_payer_delete(id))
    }

    /// True if a payer other than `excluding_id` has `cpf` (digits, or masked).
    pub async fn favorite_payer_cpf_exists(
        &self,
        cpf: String,
        excluding_id: Option<u64>,
    ) -> Result<bool, CoreError> {
        delegate!(self.favorite_payer_cpf_exists(cpf, excluding_id))
    }

    /// Deletes every payer (wallet delete or import).
    pub async fn favorite_payers_clear(&self) -> Result<(), CoreError> {
        delegate!(self.favorite_payers_clear())
    }

    // ───────────────────────────── flags

    /// True if `flag` is set.
    pub async fn pix_flag_is_set(&self, flag: PixFlagDto) -> Result<bool, CoreError> {
        delegate!(self.pix_flag_is_set(flag))
    }

    /// Sets `flag`.
    pub async fn pix_flag_set(&self, flag: PixFlagDto) -> Result<(), CoreError> {
        delegate!(self.pix_flag_set(flag))
    }

    /// Clears `flag`.
    pub async fn pix_flag_reset(&self, flag: PixFlagDto) -> Result<(), CoreError> {
        delegate!(self.pix_flag_reset(flag))
    }
}
