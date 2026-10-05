//! PIX deposits, PIX send entities, taxpayer ids and favorite payers.
//!
//! Port of `lib/features/pix/**` (data and domain layers, plus the business
//! rules in its providers) and `lib/features/favorite_payers/**`.
//!
//! - [`entities`]: records with backend JSON field names.
//! - [`client`]: [`PixClient`] for every backend endpoint the Dart code calls.
//! - [`rules`]: fees, validation, polling, status notifications, filters.
//! - [`tax_id`]: CPF/CNPJ validation and masks, PIX key detection.
//! - [`store`]: deposit, favorite payer and flag stores over `KvStore`.
//! - [`service`]: repository and controller orchestration.

pub mod client;
pub mod entities;
pub mod rules;
pub mod service;
pub mod store;
pub mod tax_id;

pub use client::{PixClient, TokenProvider, DEFAULT_BACKEND_URL};
pub use entities::{
    DepositStatus, FavoritePayer, NewDepositRequest, PaymentDetails, PixDeposit, PixDepositResponse, PixPayment,
    PixPaymentQuote, PixPaymentRequest, PixStatusEvent, PixTransactionDetails, WithdrawStatus,
};
pub use service::{AddressProvider, PixService};
pub use store::{DepositRecord, DepositStore, FavoritePayerSaveError, FavoritePayerStore, PixFlag, PixFlagsStore};
