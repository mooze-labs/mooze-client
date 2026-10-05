//! flutter_rust_bridge bindings for mooze-core.
//!
//! `api` is the surface Dart sees. `ports`, `secure_store` and `ws` hold the
//! native implementations of the core's platform traits. `glue` connects
//! the bridge wallets and the SideSwap connection to the core features.

pub mod api;
mod frb_generated;
pub(crate) mod glue;
pub mod ports;
pub mod secure_store;
pub mod ws;
