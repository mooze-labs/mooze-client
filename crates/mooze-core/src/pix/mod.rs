//! PIX deposits, PIX send entities, taxpayer ids and favorite payers.
//!
//! - [`entities`]: records with backend JSON field names.
//! - [`client`]: [`PixClient`] for the PIX backend endpoints.
//! - [`rules`]: fees, validation, polling, status notifications, filters.
//! - [`tax_id`]: CPF/CNPJ validation and masks, PIX key detection.
//! - [`store`]: deposit, favorite payer and flag stores over `KvStore`.
//! - [`service`]: deposit orchestration.

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
