use std::future::Future;

use super::{MaybeSend, MaybeSync};
use crate::Result;

/// One WebSocket frame the core cares about.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum WsMessage {
    Text(String),
    Binary(Vec<u8>),
    /// The peer or the transport closed the connection.
    Closed,
}

/// Opens WebSocket connections.
pub trait WsConnector: MaybeSend + MaybeSync {
    type Connection: WsConnection;

    /// Opens a connection to `url` (`wss://...`).
    fn connect(&self, url: &str) -> impl Future<Output = Result<Self::Connection>> + MaybeSend;
}

/// One open WebSocket connection.
pub trait WsConnection: MaybeSend {
    /// Sends one text frame.
    fn send_text(&mut self, text: String) -> impl Future<Output = Result<()>> + MaybeSend;

    /// Waits for the next frame. Returns [`WsMessage::Closed`] after close.
    fn recv(&mut self) -> impl Future<Output = Result<WsMessage>> + MaybeSend;

    /// Closes the connection.
    fn close(&mut self) -> impl Future<Output = Result<()>> + MaybeSend;
}
