use super::{MaybeSend, MaybeSync};

/// Source of the current time.
///
/// `std::time::SystemTime::now` panics on `wasm32-unknown-unknown`.
/// The platform supplies the time instead (`Date.now()` in the browser).
pub trait Clock: MaybeSend + MaybeSync {
    /// Milliseconds since the Unix epoch.
    fn now_ms(&self) -> u64;
}

impl<T: Clock + ?Sized> Clock for std::sync::Arc<T> {
    fn now_ms(&self) -> u64 {
        (**self).now_ms()
    }
}
