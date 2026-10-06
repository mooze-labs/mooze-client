use mooze_core::ports::{BlockingSpawner, Spawner, TaskFuture, Timer};
use std::sync::OnceLock;
/// Tokio runtime shared by every bridge call.
pub fn runtime() -> &'static tokio::runtime::Runtime {
    static RT: OnceLock<tokio::runtime::Runtime> = OnceLock::new();
    RT.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .thread_name("mooze-core")
            .enable_all()
            .build()
            .expect("tokio runtime")
    })
}

/// Installs ring as the process-wide rustls crypto provider.
///
/// The dependency tree compiles both rustls backends (ring and aws-lc).
/// rustls then cannot pick a default, and a TLS client built without an
/// explicit provider panics. Call this before any TLS use. Later calls,
/// and calls after another provider was installed, do nothing.
pub fn install_crypto_provider() {
    let _ = rustls::crypto::ring::default_provider().install_default();
}

/// [`BlockingSpawner`] over tokio's blocking thread pool.
#[derive(Debug, Clone, Copy, Default)]
pub struct TokioSpawner;

impl BlockingSpawner for TokioSpawner {
    fn spawn_blocking(&self, task: Box<dyn FnOnce() + Send + 'static>) {
        runtime().spawn_blocking(task);
    }
}

/// [`Spawner`] over the shared tokio runtime.
#[derive(Debug, Clone, Copy, Default)]
pub struct TokioTaskSpawner;

impl Spawner for TokioTaskSpawner {
    fn spawn(&self, task: TaskFuture<'static, ()>) {
        runtime().spawn(task);
    }
}

/// [`Timer`] over tokio time. Enters the shared runtime, so it works from
/// any executor.
#[derive(Debug, Clone, Copy, Default)]
pub struct TokioTimer;

impl Timer for TokioTimer {
    fn sleep(&self, ms: u64) -> TaskFuture<'static, ()> {
        if ms == 0 {
            // The port contract: a zero sleep yields once to other tasks.
            // A zero tokio sleep waits on the timer driver instead.
            return Box::pin(tokio::task::yield_now());
        }
        // `Sleep` binds to the runtime timer at creation, so the guard can
        // end before the await. The guard itself is not `Send`.
        let sleep = {
            let _guard = runtime().handle().enter();
            tokio::time::sleep(std::time::Duration::from_millis(ms))
        };
        Box::pin(sleep)
    }
}
