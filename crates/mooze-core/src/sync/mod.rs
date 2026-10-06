//! Boot, sync orchestration, app lifecycle and notification decisions.
//!
//! Port of `lib/features/sync/**`, `lib/features/boot/**`,
//! `lib/app/lifecycle/app_lifecycle_controller_impl.dart` and the decision
//! logic of `lib/infra/notification/transaction_notifier_impl.dart`.
//! No timers or background tasks: the platform drives every step.

pub mod boot;
pub mod lifecycle;
pub mod notifier;
pub mod orchestrator;

pub use boot::{BootOrchestrator, BootPhase, BootServices, BootState};
pub use lifecycle::{AppLifecycle, AppPhase, AppState, BootOutcome, StartStep};
pub use notifier::{TransactionNotifier, TxNotification};
pub use orchestrator::{
    ChainSyncer, RefreshReport, SyncConfig, SyncOrchestrator, SyncPhase, SyncState, SyncStrategy,
};
