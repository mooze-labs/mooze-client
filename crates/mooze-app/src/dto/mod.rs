//! Plain data types that cross the host boundary.
//!
//! Every type derives serde. With the `codegen` feature it also derives
//! `ts_rs::TS`; `cargo run --features codegen --bin codegen` writes
//! `crates/mooze-app/generated/types.ts` and `client.ts` from them.

pub mod config;
pub mod pix;
pub mod runtime;
pub mod swap;
pub mod wallet;

pub use config::*;
pub use pix::*;
pub use runtime::*;
pub use swap::*;
pub use wallet::*;
