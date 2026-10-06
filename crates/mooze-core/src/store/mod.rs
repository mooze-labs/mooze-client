//! Persistence over [`crate::ports::KvStore`] and [`crate::ports::SecureStore`].
//!
//! Records are JSON values under prefixed keys.

pub mod addresses;
pub mod credentials;
pub mod json;
pub mod notified;
pub mod records;
pub mod settings;
pub mod transactions;

pub use credentials::{CredentialStore, PinStore, MNEMONIC_KEY};
pub use notified::NotifiedTxRegistry;
pub use records::{AppLogStore, SwapAuditStore, SyncMetadataStore};
pub use settings::NodeSettings;
pub use transactions::{merge_transaction, TransactionStore};
