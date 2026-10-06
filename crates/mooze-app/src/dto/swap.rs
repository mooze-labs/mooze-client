//! SideSwap swap and peg DTOs.

use serde::{Deserialize, Serialize};

use mooze_core::peg::entities::{PegDirection, PegOrder, PegPhase, PegProgress, PegServerLimits};
use mooze_core::peg::store::PegRecord;
use mooze_core::peg::tracker::TrackedPeg;
use mooze_core::peg::PegQuote;
use mooze_core::sideswap::protocol::{QuoteOutcome, QuoteResponse, SideswapAsset, SideswapMarket};

/// Status of one quote emission.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum QuoteStatusDto {
    Success,
    LowBalance,
    Error,
}

/// One SideSwap quote emission (Dart `QuoteResponse`). Amounts in base units.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct QuoteDto {
    pub status: QuoteStatusDto,
    /// Set on success. Pass it to `sideswapExecuteSwap`.
    pub quote_id: Option<u64>,
    pub base_amount: Option<u64>,
    pub quote_amount: Option<u64>,
    pub server_fee: Option<u64>,
    pub fixed_fee: Option<u64>,
    /// Quote lifetime in ms. Set on success.
    pub ttl_ms: Option<u64>,
    /// Server balance. Set on low balance.
    pub available: Option<u64>,
    /// Set on error.
    pub error_message: Option<String>,
    pub quote_sub_id: Option<u64>,
    pub requested_amount: Option<u64>,
    pub base_asset_id: Option<String>,
    pub quote_asset_id: Option<String>,
}

impl From<&QuoteResponse> for QuoteDto {
    fn from(q: &QuoteResponse) -> Self {
        let mut dto = QuoteDto {
            status: QuoteStatusDto::Error,
            quote_id: None,
            base_amount: None,
            quote_amount: None,
            server_fee: None,
            fixed_fee: None,
            ttl_ms: None,
            available: None,
            error_message: None,
            quote_sub_id: q.quote_sub_id,
            requested_amount: q.requested_amount,
            base_asset_id: q.base_asset_id.clone(),
            quote_asset_id: q.quote_asset_id.clone(),
        };
        match &q.outcome {
            QuoteOutcome::Success(s) => {
                dto.status = QuoteStatusDto::Success;
                dto.quote_id = Some(s.quote_id);
                dto.base_amount = Some(s.base_amount);
                dto.quote_amount = Some(s.quote_amount);
                dto.server_fee = Some(s.server_fee);
                dto.fixed_fee = Some(s.fixed_fee);
                dto.ttl_ms = Some(s.ttl);
            }
            QuoteOutcome::LowBalance(l) => {
                dto.status = QuoteStatusDto::LowBalance;
                dto.available = Some(l.available);
                dto.base_amount = Some(l.base_amount);
                dto.quote_amount = Some(l.quote_amount);
                dto.server_fee = Some(l.server_fee);
                dto.fixed_fee = Some(l.fixed_fee);
            }
            QuoteOutcome::Error(m) => dto.error_message = Some(m.clone()),
        }
        dto
    }
}

/// Kind of a `sideswapEvents` item.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum SideSwapEventKind {
    /// A quote for the active subscription, or a synthetic timeout error.
    Quote,
    PegInWalletBalance,
    PegOutWalletBalance,
    /// The socket dropped. The driver reconnects with backoff; quotes must
    /// be started again.
    Disconnected,
    /// Last item: the driver stopped (cancelled, or reconnects exhausted).
    Closed,
}

/// One item of the `sideswapEvents` stream.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct SideSwapEventDto {
    pub kind: SideSwapEventKind,
    pub quote: Option<QuoteDto>,
    pub balance_sat: Option<u64>,
    pub message: Option<String>,
}

/// Result of `sideswapStartQuote`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct StartQuoteDto {
    /// False when another quote request still holds the lock.
    pub started: bool,
    pub quote_sub_id: Option<u64>,
    /// Market base asset. Differs from the send asset on an inverse market.
    pub base_asset_id: Option<String>,
    pub quote_asset_id: Option<String>,
}

/// A SideSwap market.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct SideswapMarketDto {
    pub base_asset_id: String,
    pub quote_asset_id: String,
    /// `Base` or `Quote`.
    pub fee_asset: String,
    pub market_type: String,
}

impl From<&SideswapMarket> for SideswapMarketDto {
    fn from(m: &SideswapMarket) -> Self {
        Self {
            base_asset_id: m.base_asset_id().to_owned(),
            quote_asset_id: m.quote_asset_id().to_owned(),
            fee_asset: m.fee_asset.clone(),
            market_type: m.market_type.clone(),
        }
    }
}

/// A SideSwap asset.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct SideswapAssetDto {
    pub asset_id: String,
    pub name: String,
    pub ticker: String,
    pub precision: u8,
    pub icon_url: Option<String>,
    pub instant_swaps: Option<bool>,
}

impl From<&SideswapAsset> for SideswapAssetDto {
    fn from(a: &SideswapAsset) -> Self {
        Self {
            asset_id: a.asset_id.clone(),
            name: a.name.clone(),
            ticker: a.ticker.clone(),
            precision: a.precision,
            icon_url: a.icon_url.clone(),
            instant_swaps: a.instant_swaps,
        }
    }
}

/// Peg direction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum PegDirectionDto {
    /// BTC to L-BTC.
    PegIn,
    /// L-BTC to BTC.
    PegOut,
}

impl From<PegDirectionDto> for PegDirection {
    fn from(d: PegDirectionDto) -> Self {
        match d {
            PegDirectionDto::PegIn => PegDirection::PegIn,
            PegDirectionDto::PegOut => PegDirection::PegOut,
        }
    }
}

impl From<PegDirection> for PegDirectionDto {
    fn from(d: PegDirection) -> Self {
        match d {
            PegDirection::PegIn => PegDirectionDto::PegIn,
            PegDirection::PegOut => PegDirectionDto::PegOut,
        }
    }
}

/// Phase of a peg.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum PegPhaseDto {
    AwaitingDeposit,
    Detected,
    Processing,
    Completed,
    InsufficientAmount,
    Failed,
}

impl From<PegPhase> for PegPhaseDto {
    fn from(p: PegPhase) -> Self {
        match p {
            PegPhase::AwaitingDeposit => Self::AwaitingDeposit,
            PegPhase::Detected => Self::Detected,
            PegPhase::Processing => Self::Processing,
            PegPhase::Completed => Self::Completed,
            PegPhase::InsufficientAmount => Self::InsufficientAmount,
            PegPhase::Failed => Self::Failed,
        }
    }
}

/// SideSwap peg minimums and fees (Dart `PegServerLimits`).
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegServerLimitsDto {
    pub min_peg_in_sat: u64,
    pub min_peg_out_sat: u64,
    pub server_fee_percent_peg_in: f64,
    pub server_fee_percent_peg_out: f64,
}

impl From<PegServerLimits> for PegServerLimitsDto {
    fn from(l: PegServerLimits) -> Self {
        Self {
            min_peg_in_sat: l.min_peg_in_sat,
            min_peg_out_sat: l.min_peg_out_sat,
            server_fee_percent_peg_in: l.server_fee_percent_peg_in,
            server_fee_percent_peg_out: l.server_fee_percent_peg_out,
        }
    }
}

impl From<PegServerLimitsDto> for PegServerLimits {
    fn from(l: PegServerLimitsDto) -> Self {
        Self {
            min_peg_in_sat: l.min_peg_in_sat,
            min_peg_out_sat: l.min_peg_out_sat,
            server_fee_percent_peg_in: l.server_fee_percent_peg_in,
            server_fee_percent_peg_out: l.server_fee_percent_peg_out,
        }
    }
}

/// Price of a peg before confirming.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegQuoteDto {
    pub direction: PegDirectionDto,
    pub amount_sat: u64,
    pub network_fee_sat: u64,
    pub service_fee_sat: u64,
    pub minimum_sat: u64,
    pub total_fee_sat: u64,
    pub estimated_receive_sat: u64,
}

impl From<PegQuote> for PegQuoteDto {
    fn from(q: PegQuote) -> Self {
        Self {
            direction: q.direction.into(),
            amount_sat: q.amount_sat,
            network_fee_sat: q.network_fee_sat,
            service_fee_sat: q.service_fee_sat,
            minimum_sat: q.minimum_sat,
            total_fee_sat: q.total_fee_sat(),
            estimated_receive_sat: q.estimated_receive_sat(),
        }
    }
}

/// A created peg order.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegOrderDto {
    pub order_id: String,
    pub direction: PegDirectionDto,
    /// SideSwap address the funding pays to.
    pub deposit_address: String,
    pub payout_address: String,
    pub created_at_ms: u64,
    pub expires_at_ms: Option<u64>,
}

impl From<&PegOrder> for PegOrderDto {
    fn from(o: &PegOrder) -> Self {
        Self {
            order_id: o.order_id.clone(),
            direction: o.direction.into(),
            deposit_address: o.deposit_address.clone(),
            payout_address: o.payout_address.clone(),
            created_at_ms: o.created_at_ms,
            expires_at_ms: o.expires_at_ms,
        }
    }
}

/// A funded peg.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegExecutionDto {
    pub order: PegOrderDto,
    pub funding_tx_id: String,
}

/// A peg the tracker follows (Dart `TrackedPeg`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct TrackedPegDto {
    pub order_id: String,
    pub direction: PegDirectionDto,
    pub phase: PegPhaseDto,
    pub amount_sat: u64,
    pub deposit_address: String,
    pub funding_tx_id: Option<String>,
    pub payout_tx_id: Option<String>,
    pub confirmations: Option<u32>,
    pub required_confirmations: Option<u32>,
    pub error_message: Option<String>,
}

impl From<&TrackedPeg> for TrackedPegDto {
    fn from(p: &TrackedPeg) -> Self {
        Self {
            order_id: p.order_id.clone(),
            direction: p.direction.into(),
            phase: p.phase.into(),
            amount_sat: p.amount_sat,
            deposit_address: p.deposit_address.clone(),
            funding_tx_id: p.funding_tx_id.clone(),
            payout_tx_id: p.payout_tx_id.clone(),
            confirmations: p.confirmations,
            required_confirmations: p.required_confirmations,
            error_message: p.error_message.clone(),
        }
    }
}

/// Result of `pegRefreshDue`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegRefreshDto {
    /// Every tracked peg after the refresh.
    pub pegs: Vec<TrackedPegDto>,
    /// Order ids whose state changed.
    pub changed: Vec<String>,
    /// Pegs that reached a terminal phase in this refresh (persisted).
    pub finished: Vec<TrackedPegDto>,
    /// When to call `pegRefreshDue` again. `None`: nothing to poll.
    pub next_wakeup_ms: Option<u64>,
}

/// One-shot status of a peg order.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegProgressDto {
    pub order_id: String,
    pub direction: PegDirectionDto,
    pub phase: PegPhaseDto,
    pub deposit_address: String,
    pub payout_address: String,
    pub total_deposited_sat: u64,
    pub total_payout_sat: u64,
    pub payout_tx_id: Option<String>,
}

impl From<&PegProgress> for PegProgressDto {
    fn from(p: &PegProgress) -> Self {
        Self {
            order_id: p.order_id.clone(),
            direction: p.direction.into(),
            phase: p.phase.into(),
            deposit_address: p.deposit_address.clone(),
            payout_address: p.payout_address.clone(),
            total_deposited_sat: p.total_deposited_sat(),
            total_payout_sat: p.total_payout_sat(),
            payout_tx_id: p.payout_tx_id().map(str::to_owned),
        }
    }
}

/// A stored peg (Dart `PegSwapEntry` row).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegRecordDto {
    pub order_id: String,
    pub direction: PegDirectionDto,
    pub sideswap_address: String,
    pub payout_address: String,
    pub amount_sat: u64,
    pub created_at_ms: u64,
    pub wallet_id: String,
    /// `pending`, `completed`, `failed` or `insufficient_amount`.
    pub status: String,
    pub funding_tx_id: Option<String>,
    pub payout_tx_id: Option<String>,
    pub error_message: Option<String>,
    pub updated_at_ms: Option<u64>,
}

impl From<&PegRecord> for PegRecordDto {
    fn from(r: &PegRecord) -> Self {
        Self {
            order_id: r.order_id.clone(),
            direction: r.direction().into(),
            sideswap_address: r.sideswap_address.clone(),
            payout_address: r.payout_address.clone(),
            amount_sat: r.amount,
            created_at_ms: r.created_at_ms,
            wallet_id: r.wallet_id.clone(),
            status: r.status.clone(),
            funding_tx_id: r.funding_tx_id.clone(),
            payout_tx_id: r.payout_tx_id.clone(),
            error_message: r.error_message.clone(),
            updated_at_ms: r.updated_at_ms,
        }
    }
}

/// Why a peg amount cannot be used.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum PegAmountIssueDto {
    BelowMinimum,
    AboveBalance,
}

/// Result of `pegValidateAmount`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct PegAmountValidationDto {
    /// False when no amount was entered.
    pub has_amount: bool,
    pub is_valid: bool,
    pub issue: Option<PegAmountIssueDto>,
    pub minimum_sats: Option<u64>,
    pub maximum_sats: Option<u64>,
    /// True when the UI should show the issue.
    pub shows_issue: bool,
}
