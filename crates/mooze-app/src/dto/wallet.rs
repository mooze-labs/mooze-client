//! Wallet, auth and migration DTOs.
//!
//! They copy the mooze-core domain types field by field, so no host
//! depends on core internals. Times are ms since the Unix epoch.

use serde::{Deserialize, Serialize};

use mooze_core::domain as d;
use mooze_core::migration::MigrationReport;
use mooze_core::wallet as w;

/// Chain of a balance or transaction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum ChainDto {
    Liquid,
    Bitcoin,
    Lightning,
    Aggregate,
}

impl From<d::ChainId> for ChainDto {
    fn from(c: d::ChainId) -> Self {
        match c {
            d::ChainId::Liquid => ChainDto::Liquid,
            d::ChainId::Bitcoin => ChainDto::Bitcoin,
            d::ChainId::Lightning => ChainDto::Lightning,
            d::ChainId::Aggregate => ChainDto::Aggregate,
        }
    }
}

impl From<ChainDto> for d::ChainId {
    fn from(c: ChainDto) -> Self {
        match c {
            ChainDto::Liquid => d::ChainId::Liquid,
            ChainDto::Bitcoin => d::ChainId::Bitcoin,
            ChainDto::Lightning => d::ChainId::Lightning,
            ChainDto::Aggregate => d::ChainId::Aggregate,
        }
    }
}

/// Transaction direction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum DirectionDto {
    Incoming,
    Outgoing,
    Internal,
    SelfTransfer,
    Swap,
}

/// Transaction status.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum StatusDto {
    Pending,
    Confirmed,
    Failed,
}

/// Backend that produced a transaction record.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum SourceDto {
    Lwk,
    Breez,
    Bdk,
}

/// One wallet transaction.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct TransactionDto {
    pub id: String,
    pub chain: ChainDto,
    pub direction: DirectionDto,
    pub status: StatusDto,
    pub amount_sat: i64,
    pub fee_sat: i64,
    pub timestamp_ms: u64,
    pub confirmations: u32,
    pub asset_id: Option<String>,
    pub address: Option<String>,
    pub label: Option<String>,
    pub from_asset_id: Option<String>,
    pub to_asset_id: Option<String>,
    pub sent_amount_sat: Option<i64>,
    pub received_amount_sat: Option<i64>,
    pub source: Option<SourceDto>,
    pub swap_lockup_tx_id: Option<String>,
    pub swap_claim_tx_id: Option<String>,
}

impl From<&d::Transaction> for TransactionDto {
    fn from(t: &d::Transaction) -> Self {
        Self {
            id: t.id.clone(),
            chain: t.chain.into(),
            direction: match t.direction {
                d::TransactionDirection::Incoming => DirectionDto::Incoming,
                d::TransactionDirection::Outgoing => DirectionDto::Outgoing,
                d::TransactionDirection::Internal => DirectionDto::Internal,
                d::TransactionDirection::SelfTransfer => DirectionDto::SelfTransfer,
                d::TransactionDirection::Swap => DirectionDto::Swap,
            },
            status: match t.status {
                d::TransactionStatus::Pending => StatusDto::Pending,
                d::TransactionStatus::Confirmed => StatusDto::Confirmed,
                d::TransactionStatus::Failed => StatusDto::Failed,
            },
            amount_sat: t.amount_sat,
            fee_sat: t.fee_sat,
            timestamp_ms: t.timestamp_ms,
            confirmations: t.confirmations,
            asset_id: t.asset_id.clone(),
            address: t.address.clone(),
            label: t.label.clone(),
            from_asset_id: t.from_asset_id.clone(),
            to_asset_id: t.to_asset_id.clone(),
            sent_amount_sat: t.sent_amount_sat,
            received_amount_sat: t.received_amount_sat,
            source: t.source.map(|s| match s {
                d::TransactionSource::Lwk => SourceDto::Lwk,
                d::TransactionSource::Breez => SourceDto::Breez,
                d::TransactionSource::Bdk => SourceDto::Bdk,
            }),
            swap_lockup_tx_id: t.swap_lockup_tx_id.clone(),
            swap_claim_tx_id: t.swap_claim_tx_id.clone(),
        }
    }
}

impl From<&TransactionDto> for d::Transaction {
    /// Back to the core type, for calls that take a transaction.
    fn from(dto: &TransactionDto) -> Self {
        let mut t = d::Transaction::new(
            dto.id.clone(),
            dto.chain.into(),
            match dto.direction {
                DirectionDto::Incoming => d::TransactionDirection::Incoming,
                DirectionDto::Outgoing => d::TransactionDirection::Outgoing,
                DirectionDto::Internal => d::TransactionDirection::Internal,
                DirectionDto::SelfTransfer => d::TransactionDirection::SelfTransfer,
                DirectionDto::Swap => d::TransactionDirection::Swap,
            },
            match dto.status {
                StatusDto::Pending => d::TransactionStatus::Pending,
                StatusDto::Confirmed => d::TransactionStatus::Confirmed,
                StatusDto::Failed => d::TransactionStatus::Failed,
            },
            dto.amount_sat,
            dto.fee_sat,
            dto.timestamp_ms,
        );
        t.confirmations = dto.confirmations;
        t.asset_id = dto.asset_id.clone();
        t.address = dto.address.clone();
        t.label = dto.label.clone();
        t.from_asset_id = dto.from_asset_id.clone();
        t.to_asset_id = dto.to_asset_id.clone();
        t.sent_amount_sat = dto.sent_amount_sat;
        t.received_amount_sat = dto.received_amount_sat;
        t.source = dto.source.map(|s| match s {
            SourceDto::Lwk => d::TransactionSource::Lwk,
            SourceDto::Breez => d::TransactionSource::Breez,
            SourceDto::Bdk => d::TransactionSource::Bdk,
        });
        t.swap_lockup_tx_id = dto.swap_lockup_tx_id.clone();
        t.swap_claim_tx_id = dto.swap_claim_tx_id.clone();
        t
    }
}

/// Kind of transaction change found by a sync.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum TransactionEventKindDto {
    Created,
    StatusChanged,
    ConfirmationsChanged,
}

/// A transaction appeared or changed.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct TransactionEventDto {
    pub kind: TransactionEventKindDto,
    pub transaction: TransactionDto,
    pub observed_at_ms: u64,
    pub previous_status: Option<StatusDto>,
    pub previous_confirmations: Option<u32>,
}

impl From<&d::TransactionEvent> for TransactionEventDto {
    fn from(e: &d::TransactionEvent) -> Self {
        let status = |s: d::TransactionStatus| match s {
            d::TransactionStatus::Pending => StatusDto::Pending,
            d::TransactionStatus::Confirmed => StatusDto::Confirmed,
            d::TransactionStatus::Failed => StatusDto::Failed,
        };
        Self {
            kind: match e.kind {
                d::TransactionEventKind::Created => TransactionEventKindDto::Created,
                d::TransactionEventKind::StatusChanged => TransactionEventKindDto::StatusChanged,
                d::TransactionEventKind::ConfirmationsChanged => {
                    TransactionEventKindDto::ConfirmationsChanged
                }
            },
            transaction: (&e.transaction).into(),
            observed_at_ms: e.observed_at_ms,
            previous_status: e.previous_status.map(status),
            previous_confirmations: e.previous_confirmations,
        }
    }
}

/// Balance of one asset.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct AssetBalanceDto {
    pub chain: ChainDto,
    pub asset_id: Option<String>,
    pub amount_sat: u64,
    pub precision: u8,
    pub ticker: Option<String>,
    pub pending_sat: u64,
}

/// Snapshot of all balances of one wallet.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct BalanceDto {
    pub assets: Vec<AssetBalanceDto>,
    pub snapshot_at_ms: u64,
}

impl From<&d::Balance> for BalanceDto {
    fn from(b: &d::Balance) -> Self {
        Self {
            assets: b
                .assets
                .iter()
                .map(|a| AssetBalanceDto {
                    chain: a.chain.into(),
                    asset_id: a.asset_id.clone(),
                    amount_sat: a.amount_sat,
                    precision: a.precision,
                    ticker: a.ticker.clone(),
                    pending_sat: a.pending_sat,
                })
                .collect(),
            snapshot_at_ms: b.snapshot_at_ms,
        }
    }
}

/// Result of one sync.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct SyncOutcomeDto {
    pub chain: ChainDto,
    pub fetched: u32,
    pub changed: u32,
    pub duration_ms: u64,
}

impl From<&d::SyncOutcome> for SyncOutcomeDto {
    fn from(o: &d::SyncOutcome) -> Self {
        Self {
            chain: o.chain.into(),
            fetched: o.fetched as u32,
            changed: o.changed as u32,
            duration_ms: o.duration_ms,
        }
    }
}

/// Fee priority.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum FeePriorityDto {
    Low,
    Medium,
    High,
}

/// Request to send on-chain. The chain follows from the method called.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct SendRequestDto {
    pub destination: String,
    pub amount_sat: u64,
    pub asset_id: Option<String>,
    pub fee_priority: FeePriorityDto,
    pub label: Option<String>,
    pub subtract_fee_from_amount: bool,
    pub fee_rate_override_sat_per_vbyte: Option<f64>,
    pub drain: bool,
}

/// Fee estimate for one send.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct FeeEstimateDto {
    pub chain: ChainDto,
    pub priority: FeePriorityDto,
    pub absolute_fee_sat: u64,
    pub fee_rate_sat_per_vbyte: Option<f64>,
    pub estimated_blocks: Option<u16>,
}

impl From<&d::FeeEstimate> for FeeEstimateDto {
    fn from(f: &d::FeeEstimate) -> Self {
        Self {
            chain: f.chain.into(),
            priority: match f.priority {
                d::FeePriority::Low => FeePriorityDto::Low,
                d::FeePriority::Medium => FeePriorityDto::Medium,
                d::FeePriority::High => FeePriorityDto::High,
            },
            absolute_fee_sat: f.absolute_fee_sat,
            fee_rate_sat_per_vbyte: f.fee_rate_sat_per_vbyte,
            estimated_blocks: f.estimated_blocks,
        }
    }
}

/// Address or invoice to receive funds.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct ReceiveAddressDto {
    pub chain: ChainDto,
    pub address: Option<String>,
    pub asset_id: Option<String>,
    pub label: Option<String>,
    pub amount_sat: Option<u64>,
}

impl From<&d::ReceiveAddress> for ReceiveAddressDto {
    fn from(r: &d::ReceiveAddress) -> Self {
        Self {
            chain: r.chain.into(),
            address: r.address.clone(),
            asset_id: r.asset_id.clone(),
            label: r.label.clone(),
            amount_sat: r.amount_sat,
        }
    }
}

/// Result of a broadcast.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct BroadcastResultDto {
    pub chain: ChainDto,
    pub tx_id: String,
    pub transaction: TransactionDto,
    pub fee_paid_sat: Option<u64>,
}

impl From<&d::BroadcastResult> for BroadcastResultDto {
    fn from(b: &d::BroadcastResult) -> Self {
        Self {
            chain: b.chain.into(),
            tx_id: b.tx_id.clone(),
            transaction: (&b.transaction).into(),
            fee_paid_sat: b.fee_paid_sat,
        }
    }
}

/// Unsigned L-BTC send, ready for review and signing.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct LiquidSendDraftDto {
    pub pset: String,
    pub destination: String,
    pub amount_sat: u64,
    pub fee_sat: u64,
    pub fee_rate_sat_per_kvb: f64,
    pub drain: bool,
}

impl From<&d::LiquidSendDraft> for LiquidSendDraftDto {
    fn from(s: &d::LiquidSendDraft) -> Self {
        Self {
            pset: s.pset.clone(),
            destination: s.destination.clone(),
            amount_sat: s.amount_sat,
            fee_sat: s.fee_sat,
            fee_rate_sat_per_kvb: s.fee_rate_sat_per_kvb,
            drain: s.drain,
        }
    }
}

/// Unblinded Liquid output.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct LiquidUtxoDto {
    pub txid: String,
    pub vout: u32,
    pub asset_id: String,
    pub asset_blinding_factor: String,
    pub value_sat: u64,
    pub value_blinding_factor: String,
}

impl From<&d::LiquidUtxo> for LiquidUtxoDto {
    fn from(u: &d::LiquidUtxo) -> Self {
        Self {
            txid: u.txid.clone(),
            vout: u.vout,
            asset_id: u.asset_id.clone(),
            asset_blinding_factor: u.asset_blinding_factor.clone(),
            value_sat: u.value_sat,
            value_blinding_factor: u.value_blinding_factor.clone(),
        }
    }
}

/// Keychain of a derived address.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum KeychainDto {
    /// Receive chain.
    External,
    /// Change chain.
    Internal,
}

impl From<w::Keychain> for KeychainDto {
    fn from(k: w::Keychain) -> Self {
        match k {
            w::Keychain::External => KeychainDto::External,
            w::Keychain::Internal => KeychainDto::Internal,
        }
    }
}

impl From<KeychainDto> for w::Keychain {
    fn from(k: KeychainDto) -> Self {
        match k {
            KeychainDto::External => w::Keychain::External,
            KeychainDto::Internal => w::Keychain::Internal,
        }
    }
}

/// One derived wallet address.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct DerivedAddressDto {
    pub keychain: KeychainDto,
    pub index: u32,
    /// Address the UI shows. Liquid: the confidential address.
    pub address: String,
    /// Liquid: the unconfidential address. Bitcoin: `None`.
    pub unconfidential: Option<String>,
    /// Hex of the script pubkey.
    pub script_hex: String,
    /// True if a wallet transaction ever paid to the address.
    pub used: bool,
}

impl From<&w::DerivedAddressInfo> for DerivedAddressDto {
    fn from(a: &w::DerivedAddressInfo) -> Self {
        Self {
            keychain: a.keychain.into(),
            index: a.index,
            address: a.address.clone(),
            unconfidential: a.unconfidential.clone(),
            script_hex: a.script_hex.clone(),
            used: a.used,
        }
    }
}

/// One unspent wallet output.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct WalletUtxoDto {
    pub txid: String,
    pub vout: u32,
    /// Address of the output. Liquid: the confidential address.
    pub address: String,
    /// Liquid: the unconfidential address. Bitcoin: `None`.
    pub unconfidential: Option<String>,
    /// Hex of the script pubkey.
    pub script_hex: String,
    pub keychain: KeychainDto,
    pub index: u32,
    /// Value in sats (Bitcoin) or asset base units (Liquid).
    pub amount_sat: u64,
    /// Liquid asset id. Bitcoin: `None`.
    pub asset_id: Option<String>,
    /// Height of the confirming block. `None` while unconfirmed.
    pub confirmation_height: Option<u32>,
    /// Block time (seconds) of the confirming block, if known.
    pub confirmation_time_s: Option<u64>,
}

impl From<&w::WalletUtxoInfo> for WalletUtxoDto {
    fn from(u: &w::WalletUtxoInfo) -> Self {
        Self {
            txid: u.txid.clone(),
            vout: u.vout,
            address: u.address.clone(),
            unconfidential: u.unconfidential.clone(),
            script_hex: u.script_hex.clone(),
            keychain: u.keychain.into(),
            index: u.index,
            amount_sat: u.amount_sat,
            asset_id: u.asset_id.clone(),
            confirmation_height: u.confirmation_height,
            confirmation_time_s: u.confirmation_time_s,
        }
    }
}

/// Derivation of an address the wallet owns.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct AddressOwnershipDto {
    pub keychain: KeychainDto,
    pub index: u32,
}

impl From<w::AddressOwnership> for AddressOwnershipDto {
    fn from(o: w::AddressOwnership) -> Self {
        Self {
            keychain: o.keychain.into(),
            index: o.index,
        }
    }
}

/// Next receive address with its index.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct NextUnusedAddressDto {
    pub index: u32,
    /// Address the UI shows. Liquid: the confidential address.
    pub address: String,
    /// True if a wallet transaction already paid to it. Bitcoin: always false.
    pub used: bool,
}

impl From<&w::NextUnusedAddress> for NextUnusedAddressDto {
    fn from(n: &w::NextUnusedAddress) -> Self {
        Self {
            index: n.index,
            address: n.address.clone(),
            used: n.used,
        }
    }
}

/// Rows copied from one source table.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct TableCountDto {
    pub table: String,
    pub count: u32,
}

/// A row the import left out.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct SkippedRowDto {
    pub table: String,
    pub key: String,
    pub reason: String,
}

/// Result of the one-time data import.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct MigrationReportDto {
    pub already_done: bool,
    pub copied: Vec<TableCountDto>,
    pub skipped: Vec<SkippedRowDto>,
}

impl From<MigrationReport> for MigrationReportDto {
    fn from(r: MigrationReport) -> Self {
        Self {
            already_done: r.already_done,
            copied: r
                .copied
                .into_iter()
                .map(|(table, count)| TableCountDto {
                    table,
                    count: count as u32,
                })
                .collect(),
            skipped: r
                .skipped
                .into_iter()
                .map(|s| SkippedRowDto {
                    table: s.table,
                    key: s.key,
                    reason: s.reason,
                })
                .collect(),
        }
    }
}

/// Result of `MoozeCore.authEnsureSession`. Mirrors the flags of the Dart
/// `ensureAuthSessionProvider`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum AuthEnsureKind {
    /// A valid session exists.
    Ready,
    /// The secure store holds no mnemonic, so the core cannot sign in.
    MissingMnemonic,
    /// The backend looks down (Dart `apiDownProvider`).
    ApiDown,
    /// Any other failure (Dart `syncErrorMessageProvider`).
    Failed,
}

/// Outcome of the boot-time session check.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct AuthEnsureDto {
    pub kind: AuthEnsureKind,
    /// The 5xx status for `ApiDown`, if the error text holds one.
    pub status_code: Option<u16>,
    /// Error text for `Failed`.
    pub message: Option<String>,
}

impl From<mooze_core::auth::EnsureOutcome> for AuthEnsureDto {
    fn from(o: mooze_core::auth::EnsureOutcome) -> Self {
        use mooze_core::auth::EnsureOutcome as O;
        match o {
            O::Ready => Self {
                kind: AuthEnsureKind::Ready,
                status_code: None,
                message: None,
            },
            O::MissingMnemonic => Self {
                kind: AuthEnsureKind::MissingMnemonic,
                status_code: None,
                message: None,
            },
            O::ApiDown { status_code } => Self {
                kind: AuthEnsureKind::ApiDown,
                status_code,
                message: None,
            },
            O::Failed { message } => Self {
                kind: AuthEnsureKind::Failed,
                status_code: None,
                message: Some(message),
            },
        }
    }
}

/// HTTP method of `MoozeCore.apiRequest`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub enum HttpMethodDto {
    Get,
    Post,
    Put,
    Patch,
    Delete,
}

impl From<HttpMethodDto> for mooze_core::ports::HttpMethod {
    fn from(m: HttpMethodDto) -> Self {
        use mooze_core::ports::HttpMethod as M;
        match m {
            HttpMethodDto::Get => M::Get,
            HttpMethodDto::Post => M::Post,
            HttpMethodDto::Put => M::Put,
            HttpMethodDto::Patch => M::Patch,
            HttpMethodDto::Delete => M::Delete,
        }
    }
}

/// Response of `MoozeCore.apiRequest`. Non-2xx statuses are not errors.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct ApiResponseDto {
    pub status: u16,
    /// Body as UTF-8 text, lossy.
    pub body: String,
}

/// Device metrics the API client adds to JSON request bodies
/// (Dart `AuthInterceptor._collectMetrics`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(
    feature = "codegen",
    derive(ts_rs::TS),
    ts(export, export_to = "../generated/")
)]
pub struct DeviceMetricsDto {
    /// Value of `MoozeCore.authDeviceId`.
    pub device_id: String,
    /// Battery level, 0 to 100.
    pub battery_level: Option<i64>,
    /// Screen brightness, 0.0 to 1.0.
    pub screen_brightness: Option<f64>,
    /// Boot time as an ISO-8601 string.
    pub boot_time: Option<String>,
}
