//! Plain data types that cross the bridge.
//!
//! flutter_rust_bridge generates a Dart class for each type here. They copy
//! the mooze-core domain types field by field, so the Dart side never
//! depends on core internals. Times are ms since the Unix epoch.

use mooze_core::domain as d;
use mooze_core::migration::MigrationReport;

/// Network the wallet runs on.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NetworkDto {
    Mainnet,
    Testnet,
    Regtest,
}

impl From<NetworkDto> for d::AppNetwork {
    fn from(n: NetworkDto) -> Self {
        match n {
            NetworkDto::Mainnet => d::AppNetwork::Mainnet,
            NetworkDto::Testnet => d::AppNetwork::Testnet,
            NetworkDto::Regtest => d::AppNetwork::Regtest,
        }
    }
}

/// Protocol used to reach the chains.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BackendDto {
    Esplora,
    Electrum,
}

/// Settings for [`super::core::MoozeCore::open`].
#[derive(Debug, Clone)]
pub struct CoreConfig {
    /// Directory the core may own. The app support directory is a good choice.
    pub data_dir: String,
    pub network: NetworkDto,
    pub backend: BackendDto,
    /// Custom Bitcoin node. Empty uses the default servers.
    pub bitcoin_node_url: String,
    /// Custom Liquid node. Empty uses the default servers.
    pub liquid_node_url: String,
}

/// Chain of a balance or transaction.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
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
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DirectionDto {
    Incoming,
    Outgoing,
    Internal,
    SelfTransfer,
    Swap,
}

/// Transaction status.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StatusDto {
    Pending,
    Confirmed,
    Failed,
}

/// Backend that produced a transaction record.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SourceDto {
    Lwk,
    Breez,
    Bdk,
}

/// One wallet transaction.
#[derive(Debug, Clone)]
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

impl TransactionDto {
    /// Back to the core type, for calls that take a transaction.
    pub(crate) fn to_domain(&self) -> d::Transaction {
        let mut t = d::Transaction::new(
            self.id.clone(),
            self.chain.into(),
            match self.direction {
                DirectionDto::Incoming => d::TransactionDirection::Incoming,
                DirectionDto::Outgoing => d::TransactionDirection::Outgoing,
                DirectionDto::Internal => d::TransactionDirection::Internal,
                DirectionDto::SelfTransfer => d::TransactionDirection::SelfTransfer,
                DirectionDto::Swap => d::TransactionDirection::Swap,
            },
            match self.status {
                StatusDto::Pending => d::TransactionStatus::Pending,
                StatusDto::Confirmed => d::TransactionStatus::Confirmed,
                StatusDto::Failed => d::TransactionStatus::Failed,
            },
            self.amount_sat,
            self.fee_sat,
            self.timestamp_ms,
        );
        t.confirmations = self.confirmations;
        t.asset_id = self.asset_id.clone();
        t.address = self.address.clone();
        t.label = self.label.clone();
        t.from_asset_id = self.from_asset_id.clone();
        t.to_asset_id = self.to_asset_id.clone();
        t.sent_amount_sat = self.sent_amount_sat;
        t.received_amount_sat = self.received_amount_sat;
        t.source = self.source.map(|s| match s {
            SourceDto::Lwk => d::TransactionSource::Lwk,
            SourceDto::Breez => d::TransactionSource::Breez,
            SourceDto::Bdk => d::TransactionSource::Bdk,
        });
        t.swap_lockup_tx_id = self.swap_lockup_tx_id.clone();
        t.swap_claim_tx_id = self.swap_claim_tx_id.clone();
        t
    }
}

/// Kind of transaction change found by a sync.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TransactionEventKindDto {
    Created,
    StatusChanged,
    ConfirmationsChanged,
}

/// A transaction appeared or changed.
#[derive(Debug, Clone)]
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
                d::TransactionEventKind::ConfirmationsChanged => TransactionEventKindDto::ConfirmationsChanged,
            },
            transaction: (&e.transaction).into(),
            observed_at_ms: e.observed_at_ms,
            previous_status: e.previous_status.map(status),
            previous_confirmations: e.previous_confirmations,
        }
    }
}

/// Balance of one asset.
#[derive(Debug, Clone)]
pub struct AssetBalanceDto {
    pub chain: ChainDto,
    pub asset_id: Option<String>,
    pub amount_sat: u64,
    pub precision: u8,
    pub ticker: Option<String>,
    pub pending_sat: u64,
}

/// Snapshot of all balances of one wallet.
#[derive(Debug, Clone)]
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
#[derive(Debug, Clone)]
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
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FeePriorityDto {
    Low,
    Medium,
    High,
}

/// Request to send on-chain. The chain follows from the method called.
#[derive(Debug, Clone)]
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

impl SendRequestDto {
    pub(crate) fn to_domain(&self, chain: d::ChainId) -> d::SendRequest {
        let mut r = d::SendRequest::new(chain, self.destination.clone(), self.amount_sat);
        r.asset_id = self.asset_id.clone();
        r.fee_priority = match self.fee_priority {
            FeePriorityDto::Low => d::FeePriority::Low,
            FeePriorityDto::Medium => d::FeePriority::Medium,
            FeePriorityDto::High => d::FeePriority::High,
        };
        r.label = self.label.clone();
        r.subtract_fee_from_amount = self.subtract_fee_from_amount;
        r.fee_rate_override_sat_per_vbyte = self.fee_rate_override_sat_per_vbyte;
        r.drain = self.drain;
        r
    }
}

/// Fee estimate for one send.
#[derive(Debug, Clone)]
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
#[derive(Debug, Clone)]
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
#[derive(Debug, Clone)]
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
#[derive(Debug, Clone)]
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
#[derive(Debug, Clone)]
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

/// Rows copied from one source table.
#[derive(Debug, Clone)]
pub struct TableCountDto {
    pub table: String,
    pub count: u32,
}

/// A row the import left out.
#[derive(Debug, Clone)]
pub struct SkippedRowDto {
    pub table: String,
    pub key: String,
    pub reason: String,
}

/// Result of the one-time data import.
#[derive(Debug, Clone)]
pub struct MigrationReportDto {
    pub already_done: bool,
    pub copied: Vec<TableCountDto>,
    pub skipped: Vec<SkippedRowDto>,
}

impl From<MigrationReport> for MigrationReportDto {
    fn from(r: MigrationReport) -> Self {
        Self {
            already_done: r.already_done,
            copied: r.copied.into_iter().map(|(table, count)| TableCountDto { table, count: count as u32 }).collect(),
            skipped: r
                .skipped
                .into_iter()
                .map(|s| SkippedRowDto { table: s.table, key: s.key, reason: s.reason })
                .collect(),
        }
    }
}

/// Category of a bridge error. Dart maps it to its failure classes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CoreErrorKind {
    Service,
    Storage,
    Credential,
    Network,
    InvalidInput,
    InvalidState,
    Timeout,
    Other,
}

/// Error thrown on the Dart side by every failing bridge call.
#[derive(Debug, Clone)]
pub struct CoreError {
    pub kind: CoreErrorKind,
    pub message: String,
}

impl std::fmt::Display for CoreError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}: {}", self.kind, self.message)
    }
}

impl std::error::Error for CoreError {}

impl From<mooze_core::Error> for CoreError {
    fn from(e: mooze_core::Error) -> Self {
        use mooze_core::Error as E;
        let kind = match &e {
            E::Service { .. } | E::Sync { .. } => CoreErrorKind::Service,
            E::Storage(_) => CoreErrorKind::Storage,
            E::Credential(_) => CoreErrorKind::Credential,
            E::Network(_) | E::Http { .. } => CoreErrorKind::Network,
            E::InvalidInput(_) => CoreErrorKind::InvalidInput,
            E::InvalidState(_) => CoreErrorKind::InvalidState,
            E::Timeout(_) => CoreErrorKind::Timeout,
            _ => CoreErrorKind::Other,
        };
        Self { kind, message: e.to_string() }
    }
}
