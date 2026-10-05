//! Platform traits. The core calls these for every side effect.
//!
//! Futures returned by port methods are bounded by [`MaybeSend`].
//! On native targets that means `Send`, so FFI runtimes can move them
//! across threads. On wasm there is one thread, so there is no bound.

mod blocking;
mod clock;
mod http;
mod kv;
mod task;
mod ws;

pub use blocking::{run_blocking, BlockingSpawner};
pub use clock::Clock;
pub use http::{HttpClient, HttpMethod, HttpRequest, HttpResponse};
pub use kv::{KvStore, SecureStore};
pub use task::{Spawner, TaskFuture, Timer};
pub use ws::{WsConnection, WsConnector, WsMessage};

#[cfg(feature = "http-reqwest")]
pub use http::ReqwestHttpClient;

/// `Send` on native targets, no bound on wasm.
#[cfg(not(target_arch = "wasm32"))]
pub trait MaybeSend: Send {}
#[cfg(not(target_arch = "wasm32"))]
impl<T: Send + ?Sized> MaybeSend for T {}

/// `Send` on native targets, no bound on wasm.
#[cfg(target_arch = "wasm32")]
pub trait MaybeSend {}
#[cfg(target_arch = "wasm32")]
impl<T: ?Sized> MaybeSend for T {}

/// `Sync` on native targets, no bound on wasm.
#[cfg(not(target_arch = "wasm32"))]
pub trait MaybeSync: Sync {}
#[cfg(not(target_arch = "wasm32"))]
impl<T: Sync + ?Sized> MaybeSync for T {}

/// `Sync` on native targets, no bound on wasm.
#[cfg(target_arch = "wasm32")]
pub trait MaybeSync {}
#[cfg(target_arch = "wasm32")]
impl<T: ?Sized> MaybeSync for T {}
