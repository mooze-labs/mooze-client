use serde::{Deserialize, Serialize};

/// Phase of the sync orchestrator. Mirrors `mooze_core::sync::SyncPhase`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum SyncPhaseDto {
    Idle,
    Running,
    Cooling,
    Stopped,
}

/// Observable sync state after a refresh.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct SyncStateDto {
    pub phase: SyncPhaseDto,
    pub last_error: Option<String>,
    pub last_success_at_ms: Option<u64>,
    pub last_duration_ms: Option<u64>,
    /// Chains with at least one successful sync this session.
    pub first_synced_chains: Vec<super::ChainDto>,
}

/// Whether the host must show the PIN or biometric challenge.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum SessionLockStateDto {
    Unlocked,
    Locked,
}

/// Settings for `App::start`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct StartConfigDto {
    /// Periodic refresh cadence. `None` uses the core default (60 s).
    pub sync_tick_ms: Option<u64>,
    /// Per-chain sync timeout. `None` uses the core default (60 s).
    ///
    /// The timeout drops the sync future. Esplora requests stop with it.
    /// An Electrum call runs on the blocking pool and finishes on its own;
    /// the next tick may then wait on the same client.
    pub sync_timeout_ms: Option<u64>,
    /// Run one refresh inside `start`.
    pub startup_sync: bool,
    /// Wallet id under which pegs are stored. `None` disables the peg loop.
    pub peg_wallet_id: Option<String>,
}

/// Result of one chain in a refresh, independent of the other chain.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub struct ChainSyncStateDto {
    pub chain: super::ChainDto,
    pub succeeded: bool,
    pub observed_at_ms: u64,
}
