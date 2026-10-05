//! SideSwap integration: JSON-RPC protocol, WebSocket client, reconnect
//! policy and the asset swap flow. Port of `lib/features/swap/data/**`.

pub mod client;
pub mod protocol;
pub mod reconnect;
pub mod swap;

pub use client::SideSwapClient;
pub use protocol::{Notification, QuoteOutcome, QuoteResponse, Request};
pub use reconnect::{ConnectionState, ReconnectAction, ReconnectPolicy, ReconnectTracker};
pub use swap::{SwapService, SwapSigner};
