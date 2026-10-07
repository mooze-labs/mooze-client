pub mod attempt;
#[cfg(target_os = "macos")]
mod macos;
mod unsupported;
#[cfg(target_os = "windows")]
mod windows;
use futures::future::BoxFuture;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum NativeKind {
    TouchId,
    WindowsHello,
    Unsupported,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
pub enum NativeAvailability {
    Available,
    NotEnrolled,
    LockedOut,
    Unavailable,
}
#[derive(Debug, Clone, Copy)]
pub struct NativeCapabilities {
    pub kind: NativeKind,
    pub availability: NativeAvailability,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NativeOutcome {
    Verified,
    Cancelled,
    Rejected,
    Unavailable,
    LockedOut,
    Failed,
}
/// Implementations retain the OS prompt until completion, even if cancellation
/// is requested. Only session orchestration can turn verification into unlock.
pub trait NativeAuthenticator: Send + Sync {
    fn capabilities(&self) -> BoxFuture<'_, NativeCapabilities>;
    fn verify(&self, attempt_id: u64, reason: String) -> BoxFuture<'_, NativeOutcome>;
    fn cancel(&self, attempt_id: u64);
}
pub fn unsupported() -> Arc<dyn NativeAuthenticator> {
    Arc::new(unsupported::Unsupported)
}
pub fn for_app(app: tauri::AppHandle) -> Arc<dyn NativeAuthenticator> {
    #[cfg(target_os = "macos")]
    return Arc::new(macos::MacAuthenticator::new(app));
    #[cfg(target_os = "windows")]
    return Arc::new(windows::WindowsAuthenticator::new(app));
    #[cfg(not(any(target_os = "macos", target_os = "windows")))]
    {
        let _ = app;
        unsupported()
    }
}
