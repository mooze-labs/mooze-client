//! PIX deposit, favorite payer, flag and taxpayer-id DTOs.

use serde::{Deserialize, Serialize};

use mooze_core::pix::store::PixFlag;
use mooze_core::pix::{DepositStatus, FavoritePayer, PixDeposit, PixStatusEvent};

/// Status of a PIX deposit (Dart `DepositStatus`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum DepositStatusDto {
    Pending,
    UnderReview,
    Processing,
    FundsPrepared,
    DepixSent,
    Paid,
    Broadcasted,
    Finished,
    Completed,
    Failed,
    Expired,
    Refunded,
    Med,
    ProcessingRefund,
    BroadcastedRefund,
    FinishedRefund,
    Timeout,
    Unknown,
}

impl From<DepositStatus> for DepositStatusDto {
    fn from(s: DepositStatus) -> Self {
        use DepositStatus as S;
        match s {
            S::Pending => Self::Pending,
            S::UnderReview => Self::UnderReview,
            S::Processing => Self::Processing,
            S::FundsPrepared => Self::FundsPrepared,
            S::DepixSent => Self::DepixSent,
            S::Paid => Self::Paid,
            S::Broadcasted => Self::Broadcasted,
            S::Finished => Self::Finished,
            S::Completed => Self::Completed,
            S::Failed => Self::Failed,
            S::Expired => Self::Expired,
            S::Refunded => Self::Refunded,
            S::Med => Self::Med,
            S::ProcessingRefund => Self::ProcessingRefund,
            S::BroadcastedRefund => Self::BroadcastedRefund,
            S::FinishedRefund => Self::FinishedRefund,
            S::Timeout => Self::Timeout,
            S::Unknown => Self::Unknown,
        }
    }
}

/// One PIX deposit (Dart `PixDeposit`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PixDepositDto {
    pub deposit_id: String,
    /// PIX "copia e cola" payload.
    pub pix_key: String,
    pub asset_id: String,
    pub amount_in_cents: u64,
    pub network: String,
    pub status: DepositStatusDto,
    pub created_at_ms: u64,
    pub blockchain_txid: Option<String>,
    /// Asset amount in base units, if known.
    pub asset_amount: Option<u64>,
}

impl From<PixDeposit> for PixDepositDto {
    fn from(d: PixDeposit) -> Self {
        Self {
            deposit_id: d.deposit_id,
            pix_key: d.pix_key,
            asset_id: d.asset.id().to_owned(),
            amount_in_cents: d.amount_in_cents,
            network: d.network,
            status: d.status.into(),
            created_at_ms: d.created_at_ms,
            blockchain_txid: d.blockchain_txid,
            asset_amount: d.asset_amount,
        }
    }
}

/// Status change of one deposit (Dart `PixStatusEvent`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PixStatusEventDto {
    pub deposit_id: String,
    pub status: DepositStatusDto,
    pub blockchain_txid: Option<String>,
    pub asset_amount: Option<u64>,
    pub error_message: Option<String>,
}

impl From<PixStatusEvent> for PixStatusEventDto {
    fn from(e: PixStatusEvent) -> Self {
        Self {
            deposit_id: e.deposit_id,
            status: e.status.into(),
            blockchain_txid: e.blockchain_txid,
            asset_amount: e.asset_amount,
            error_message: e.error_message,
        }
    }
}

/// Fee breakdown of a deposit amount in BRL (fee card and quote screen).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PixFeeDto {
    /// Percent rate, after the referral discount.
    pub fee_rate_percent: f64,
    /// Fee in BRL.
    pub fee_amount: f64,
    /// BRL left after fees. The asset amount is computed from it.
    pub discounted_amount: f64,
    /// Discounted amount divided by the asset price, if a price was given.
    pub estimated_asset_units: Option<f64>,
    /// Index into the fee tiers, or `None` for no amount.
    pub active_tier: Option<u32>,
    /// The amount in cents, truncated like Dart.
    pub amount_in_cents: u64,
}

/// User level limits in BRL (Dart `levelsProvider`).
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct DepositLimitsDto {
    pub absolute_min_limit: f64,
    pub allowed_spending: f64,
}

/// Why a deposit amount is not valid.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum DepositValidationErrorDto {
    InvalidAmount,
    BelowMinimum,
    AboveTransaction,
    AboveRemaining,
}

/// Result of `pixValidateAmount`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct DepositValidationDto {
    pub is_valid: bool,
    pub error: Option<DepositValidationErrorDto>,
    /// The limit that the amount broke, in BRL.
    pub limit_amount: Option<f64>,
}

/// A saved payer (Dart `FavoritePayer`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct FavoritePayerDto {
    pub id: Option<u64>,
    pub label: String,
    /// Unmasked digits.
    pub cpf: String,
    /// CPF/CNPJ formatted for display.
    pub masked_cpf: String,
}

impl From<FavoritePayer> for FavoritePayerDto {
    fn from(p: FavoritePayer) -> Self {
        Self { masked_cpf: p.masked_cpf(), id: p.id, label: p.label, cpf: p.cpf }
    }
}

/// Why a favorite payer save was refused.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum FavoritePayerSaveErrorDto {
    DuplicateCpf,
}

/// One-time PIX flags, formerly in `SharedPreferences`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum PixFlagDto {
    LbtcWarningShown,
    MainFirstTimeDialogShown,
    MerchantFirstTimeDialogShown,
    TutorialShown,
}

impl From<PixFlagDto> for PixFlag {
    fn from(f: PixFlagDto) -> Self {
        match f {
            PixFlagDto::LbtcWarningShown => PixFlag::LbtcWarningShown,
            PixFlagDto::MainFirstTimeDialogShown => PixFlag::MainFirstTimeDialogShown,
            PixFlagDto::MerchantFirstTimeDialogShown => PixFlag::MerchantFirstTimeDialogShown,
            PixFlagDto::TutorialShown => PixFlag::TutorialShown,
        }
    }
}

/// Why a CPF/CNPJ input is not valid.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum CpfValidationErrorDto {
    /// No digits.
    Empty,
    /// Fewer digits than a CPF, or 12 to 13 digits.
    Incomplete,
    /// Wrong check digits, repeated digits, or more than 14 digits.
    Invalid,
}
