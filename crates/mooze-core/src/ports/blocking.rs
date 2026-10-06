use futures::channel::oneshot;

use crate::{Error, Result};

/// Runs blocking work off the async executor.
///
/// Some libraries only offer blocking network calls. The Electrum clients
/// are an example. A blocking call inside an async task stalls the whole
/// executor thread, so the core hands that work to the platform instead.
/// Native platforms use a blocking-task pool, for example
/// `tokio::task::spawn_blocking`. The Dart app used `Isolate.run` for the
/// same reason.
///
/// The trait is object safe, so services can hold an `Arc<dyn BlockingSpawner>`.
pub trait BlockingSpawner: Send + Sync {
    /// Runs `task` to completion on a thread that may block.
    fn spawn_blocking(&self, task: Box<dyn FnOnce() + Send + 'static>);
}

/// Runs `f` through `spawner` and waits for its result.
///
/// Returns [`Error::Unexpected`] if the platform drops the task without
/// running it, for example during shutdown.
pub async fn run_blocking<T, F>(spawner: &dyn BlockingSpawner, f: F) -> Result<T>
where
    T: Send + 'static,
    F: FnOnce() -> T + Send + 'static,
{
    let (tx, rx) = oneshot::channel();
    spawner.spawn_blocking(Box::new(move || {
        // The receiver is gone only if the caller stopped waiting.
        let _ = tx.send(f());
    }));
    rx.await
        .map_err(|_| Error::Unexpected("blocking task dropped before it finished".into()))
}
