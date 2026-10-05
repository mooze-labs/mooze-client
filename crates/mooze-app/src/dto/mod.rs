//! Plain data types that cross the host boundary.
//!
//! Every type derives serde. With the `codegen` feature it also derives
//! `ts_rs::TS` and exports to `crates/mooze-app/generated/`.

pub mod config;
pub mod pix;
pub mod swap;
pub mod wallet;

pub use config::*;
pub use pix::*;
pub use swap::*;
pub use wallet::*;
