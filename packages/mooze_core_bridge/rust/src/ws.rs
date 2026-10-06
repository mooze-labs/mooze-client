//! [`WsConnector`] over tokio-tungstenite.
//!
//! TLS uses rustls with the webpki root certificates. The connection runs
//! on the shared tokio runtime (see [`crate::ports::runtime`]).

use std::future::Future;
use std::time::Duration;

use futures::{SinkExt, StreamExt};
use mooze_core::ports::{MaybeSend, WsConnection, WsConnector, WsMessage};
use mooze_core::sideswap::protocol::DEFAULT_REQUEST_TIMEOUT_MS;
use mooze_core::{Error, Result};
use tokio::net::TcpStream;
use tokio_tungstenite::tungstenite::{self, Message};
use tokio_tungstenite::{MaybeTlsStream, WebSocketStream};

use crate::ports::{install_crypto_provider, runtime};

/// Opens WebSocket connections with tokio-tungstenite.
#[derive(Debug, Clone, Copy, Default)]
pub struct TungsteniteConnector;

/// One open tokio-tungstenite connection.
///
/// `recv` returns [`Error::Timeout`] when no frame arrives within the
/// timeout, as the core's SideSwap client expects. The connection stays
/// open after a timeout.
#[derive(Debug)]
pub struct TungsteniteConnection {
    stream: WebSocketStream<MaybeTlsStream<TcpStream>>,
    closed: bool,
    recv_timeout: Duration,
}

impl TungsteniteConnection {
    /// Replaces the receive timeout. Default: the core's request timeout.
    pub fn set_recv_timeout(&mut self, timeout: Duration) {
        self.recv_timeout = timeout;
    }

    async fn next_frame(&mut self) -> Option<std::result::Result<Message, tungstenite::Error>> {
        self.stream.next().await
    }
}

impl WsConnector for TungsteniteConnector {
    type Connection = TungsteniteConnection;

    fn connect(
        &self,
        url: &str,
    ) -> impl Future<Output = Result<TungsteniteConnection>> + MaybeSend {
        let url = url.to_owned();
        async move {
            install_crypto_provider();
            // The TCP socket must register with a tokio reactor. Spawn the
            // connect on the shared runtime, so any executor can call this.
            let (stream, _response) = runtime()
                .spawn(tokio_tungstenite::connect_async(url))
                .await
                .map_err(|e| Error::Unexpected(format!("ws connect task failed: {e}")))?
                .map_err(|e| Error::Network(format!("ws connect: {e}")))?;
            Ok(TungsteniteConnection {
                stream,
                closed: false,
                recv_timeout: Duration::from_millis(DEFAULT_REQUEST_TIMEOUT_MS),
            })
        }
    }
}

/// True for errors that only mean the connection is gone.
fn is_closed_error(e: &tungstenite::Error) -> bool {
    matches!(
        e,
        tungstenite::Error::ConnectionClosed | tungstenite::Error::AlreadyClosed
    )
}

// Explicit futures keep the MaybeSend bound visible at the impl site.
#[allow(clippy::manual_async_fn)]
impl WsConnection for TungsteniteConnection {
    fn send_text(&mut self, text: String) -> impl Future<Output = Result<()>> + MaybeSend {
        async move {
            if self.closed {
                return Err(Error::Network("ws send: connection closed".into()));
            }
            self.stream
                .send(Message::text(text))
                .await
                .map_err(|e| Error::Network(format!("ws send: {e}")))
        }
    }

    fn recv(&mut self) -> impl Future<Output = Result<WsMessage>> + MaybeSend {
        async move {
            if self.closed {
                return Ok(WsMessage::Closed);
            }
            loop {
                // Stream::next is cancel safe, so a timeout loses no frame.
                // Outside a tokio runtime there is no timer: wait without one.
                let next = if tokio::runtime::Handle::try_current().is_ok() {
                    let timeout = self.recv_timeout;
                    match tokio::time::timeout(timeout, self.next_frame()).await {
                        Ok(next) => next,
                        Err(_) => {
                            return Err(Error::Timeout(format!(
                                "ws recv: no frame in {} ms",
                                timeout.as_millis()
                            )))
                        }
                    }
                } else {
                    self.next_frame().await
                };
                let frame = match next {
                    None => None,
                    Some(Ok(frame)) => Some(frame),
                    Some(Err(e)) if is_closed_error(&e) => None,
                    Some(Err(e)) => return Err(Error::Network(format!("ws recv: {e}"))),
                };
                match frame {
                    Some(Message::Text(text)) => {
                        return Ok(WsMessage::Text(text.as_str().to_owned()))
                    }
                    Some(Message::Binary(bytes)) => return Ok(WsMessage::Binary(bytes.to_vec())),
                    // tungstenite answers pings by itself. Raw frames only appear on write.
                    Some(Message::Ping(_) | Message::Pong(_) | Message::Frame(_)) => continue,
                    Some(Message::Close(_)) | None => {
                        self.closed = true;
                        return Ok(WsMessage::Closed);
                    }
                }
            }
        }
    }

    fn close(&mut self) -> impl Future<Output = Result<()>> + MaybeSend {
        async move {
            if self.closed {
                return Ok(());
            }
            self.closed = true;
            match self.stream.close(None).await {
                Ok(()) => Ok(()),
                Err(e) if is_closed_error(&e) => Ok(()),
                Err(e) => Err(Error::Network(format!("ws close: {e}"))),
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::net::TcpListener;

    /// Echo server on 127.0.0.1. Echoes text and binary, closes on "bye".
    async fn echo_server() -> String {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            let (tcp, _) = listener.accept().await.unwrap();
            let mut ws = tokio_tungstenite::accept_async(tcp).await.unwrap();
            while let Some(Ok(msg)) = ws.next().await {
                match msg {
                    Message::Text(t) if t.as_str() == "bye" => {
                        ws.close(None).await.unwrap();
                        break;
                    }
                    Message::Text(t) => {
                        ws.send(Message::Ping(Vec::new().into())).await.unwrap();
                        ws.send(Message::Text(t)).await.unwrap();
                    }
                    Message::Binary(_) => {}
                    _ => {}
                }
            }
        });
        format!("ws://{addr}")
    }

    #[test]
    fn echo_round_trip_and_close() {
        runtime().block_on(async {
            let url = echo_server().await;
            let mut conn = TungsteniteConnector.connect(&url).await.unwrap();
            conn.send_text("hello ç".into()).await.unwrap();
            assert_eq!(
                conn.recv().await.unwrap(),
                WsMessage::Text("hello ç".into())
            );
            conn.send_text("bye".into()).await.unwrap();
            assert_eq!(conn.recv().await.unwrap(), WsMessage::Closed);
            assert_eq!(conn.recv().await.unwrap(), WsMessage::Closed);
            assert!(conn.send_text("late".into()).await.is_err());
            conn.close().await.unwrap();
        });
    }

    #[test]
    fn binary_frames_map_to_binary() {
        runtime().block_on(async {
            let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
            let addr = listener.local_addr().unwrap();
            tokio::spawn(async move {
                let (tcp, _) = listener.accept().await.unwrap();
                let mut ws = tokio_tungstenite::accept_async(tcp).await.unwrap();
                ws.send(Message::Binary(vec![1, 2, 3].into()))
                    .await
                    .unwrap();
                ws.close(None).await.unwrap();
            });
            let mut conn = TungsteniteConnector
                .connect(&format!("ws://{addr}"))
                .await
                .unwrap();
            assert_eq!(conn.recv().await.unwrap(), WsMessage::Binary(vec![1, 2, 3]));
            assert_eq!(conn.recv().await.unwrap(), WsMessage::Closed);
        });
    }

    #[test]
    fn recv_times_out_and_keeps_the_connection() {
        runtime().block_on(async {
            let url = echo_server().await;
            let mut conn = TungsteniteConnector.connect(&url).await.unwrap();
            conn.set_recv_timeout(Duration::from_millis(50));
            assert!(matches!(conn.recv().await, Err(Error::Timeout(_))));
            conn.send_text("still here".into()).await.unwrap();
            assert_eq!(
                conn.recv().await.unwrap(),
                WsMessage::Text("still here".into())
            );
        });
    }

    #[test]
    fn connect_failure_is_network_error() {
        let err = runtime()
            .block_on(TungsteniteConnector.connect("ws://127.0.0.1:1"))
            .unwrap_err();
        assert!(matches!(err, Error::Network(_)), "{err}");
    }

    #[test]
    fn connect_works_outside_the_runtime() {
        // An executor without a tokio reactor, like the flutter_rust_bridge
        // one: the connector moves the socket setup onto the shared runtime.
        let url = runtime().block_on(echo_server());
        let plain = tokio::runtime::Builder::new_current_thread()
            .build()
            .unwrap();
        let mut conn = plain.block_on(TungsteniteConnector.connect(&url)).unwrap();
        runtime().block_on(async {
            conn.send_text("x".into()).await.unwrap();
            assert_eq!(conn.recv().await.unwrap(), WsMessage::Text("x".into()));
        });
    }
}
