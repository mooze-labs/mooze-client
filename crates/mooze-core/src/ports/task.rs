//! Task ports: spawn a future, sleep for a duration.
//!
//! The core and the facade own no executor and no timers. A host runs
//! tasks on tokio, on `wasm_bindgen_futures::spawn_local`, or on a test
//! executor. `std::thread::sleep` and `tokio::time::sleep` both fail on
//! wasm, so sleeping is a port too.

use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;

use super::{MaybeSend, MaybeSync};

/// Boxed future a port returns or accepts. `Send` on native targets only.
#[cfg(not(target_arch = "wasm32"))]
pub type TaskFuture<'a, T> = Pin<Box<dyn Future<Output = T> + Send + 'a>>;
/// Boxed future a port returns or accepts. `Send` on native targets only.
#[cfg(target_arch = "wasm32")]
pub type TaskFuture<'a, T> = Pin<Box<dyn Future<Output = T> + 'a>>;

/// Runs a future to completion in the background. Fire and forget.
pub trait Spawner: MaybeSend + MaybeSync {
    fn spawn(&self, task: TaskFuture<'static, ()>);
}

impl<T: Spawner + ?Sized> Spawner for Arc<T> {
    fn spawn(&self, task: TaskFuture<'static, ()>) {
        (**self).spawn(task)
    }
}

/// Resolves after `ms` milliseconds.
///
/// Contract: `sleep(0)` yields once to other tasks and then resolves. The
/// facade uses it to let a waiting command take a fair lock. Hosts whose
/// zero-duration sleep resolves at once, or waits on a driver thread, must
/// map it to their executor's yield.
pub trait Timer: MaybeSend + MaybeSync {
    fn sleep(&self, ms: u64) -> TaskFuture<'static, ()>;
}

impl<T: Timer + ?Sized> Timer for Arc<T> {
    fn sleep(&self, ms: u64) -> TaskFuture<'static, ()> {
        (**self).sleep(ms)
    }
}
