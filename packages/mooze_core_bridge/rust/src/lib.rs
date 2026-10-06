//! flutter_rust_bridge bindings for mooze-core.
//!
//! `api` is the surface Dart sees; every call delegates to `mooze_app::App`.
//! `ports`, `secure_store` and `ws` hold the native implementations of the
//! platform traits.

pub mod api;
pub(crate) mod forward;
mod frb_generated;
pub mod ports;
pub mod secure_store;
pub mod ws;
