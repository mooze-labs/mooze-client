//! The ports a host supplies.

use std::sync::Arc;

use mooze_core::ports::{
    BlockingSpawner, Clock, HttpClient, KvStore, SecureStore, Spawner, Timer, WsConnector,
};
use mooze_core::{MaybeSend, MaybeSync};

/// Port implementations of one host. Each accessor returns a cheap clone.
pub trait Platform: MaybeSend + MaybeSync + 'static {
    type Kv: KvStore + Clone + 'static;
    type Secure: SecureStore + Clone + 'static;
    type Http: HttpClient + Clone + 'static;
    type Ws: WsConnector + Clone + 'static;
    type Clock: Clock + Clone + 'static;

    fn kv(&self) -> Self::Kv;
    fn secure(&self) -> Self::Secure;
    fn http(&self) -> Self::Http;
    fn ws(&self) -> Self::Ws;
    fn clock(&self) -> Self::Clock;
    fn spawner(&self) -> Arc<dyn Spawner>;
    fn timer(&self) -> Arc<dyn Timer>;
    /// Blocking pool for the Electrum clients. `None` on hosts without Electrum.
    fn blocking(&self) -> Option<Arc<dyn BlockingSpawner>>;
}
