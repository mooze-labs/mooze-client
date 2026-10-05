//! flutter_rust_bridge bindings for mooze-core.
//!
//! `api` is the surface Dart sees. `ports` holds the native implementations
//! of the core's platform traits.

pub mod api;
mod frb_generated;
pub mod ports;
