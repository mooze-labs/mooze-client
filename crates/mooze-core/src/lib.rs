//! Application logic for the Mooze wallet.
//!
//! The crate does no I/O by itself. It calls the traits in [`ports`].
//! Each platform (Flutter native, browser) supplies the implementations.
//! The crate compiles for native targets and for `wasm32-unknown-unknown`.

pub mod adapters;
pub mod api;
pub mod auth;
pub mod domain;
pub mod error;
pub mod format;
pub mod merchant;
pub mod migration;
pub mod payment_uri;
pub mod peg;
pub mod pix;
pub mod ports;
pub mod prices;
pub mod sideswap;
pub mod store;
pub mod sync;
pub mod testing;
pub mod user;
pub mod wallet;

pub use error::{Error, Result};
pub use ports::{MaybeSend, MaybeSync};
