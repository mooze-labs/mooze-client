//! Application facade of the Mooze wallet.
//!
//! [`App`] holds the wallets, the API session, PIX, SideSwap and the peg
//! tracker, and exposes flat DTO methods that every host binds:
//! flutter_rust_bridge, Tauri, wasm-bindgen, UniFFI. The crate does no I/O
//! and starts no tasks by itself. A [`Platform`] supplies the ports.

pub mod convert;
pub mod dto;
pub mod error;
pub mod platform;

pub use error::{AppError, ErrorCode, Result};
pub use platform::Platform;
