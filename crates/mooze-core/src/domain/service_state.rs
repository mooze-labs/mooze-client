use serde::{Deserialize, Serialize};

/// Lifecycle of a wallet service.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum ServiceLifecycle {
    #[default]
    Uninitialized,
    Connecting,
    Connected,
    Disconnecting,
    Disconnected,
    Errored,
}

/// Observable state of a wallet service.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub struct ServiceState {
    pub lifecycle: ServiceLifecycle,
    pub failure: Option<String>,
    pub last_sync_at_ms: Option<u64>,
}

impl ServiceState {
    /// True when connected.
    pub fn is_operational(&self) -> bool {
        self.lifecycle == ServiceLifecycle::Connected
    }
}
