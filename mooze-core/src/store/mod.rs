//! Persistence over [`crate::ports::KvStore`] and [`crate::ports::SecureStore`].
//!
//! Port of `lib/infra/storage/**`, `lib/infra/db/**`, `lib/database/**`
//! (records only, no migration machinery) and `lib/shared/key_management/**`.
//! Records are JSON values under prefixed keys.

pub mod addresses;
pub mod credentials;
pub mod json;
pub mod notified;
pub mod records;
pub mod transactions;

pub use credentials::{CredentialStore, PinStore, MNEMONIC_KEY};
pub use notified::NotifiedTxRegistry;
pub use records::{
    AppLogStore, DepositStore, FavoritePayerStore, PegAuditStore, SwapAuditStore, SyncMetadataStore,
};
pub use transactions::{merge_transaction, TransactionStore};
