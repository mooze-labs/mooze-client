pub mod file_kv;
pub mod idle_clock;
pub mod runtime;
pub mod secure_store;
pub mod ws;
use file_kv::FileKv;
use mooze_app::Platform;
use mooze_core::{ports::*, Result};
use secure_store::KeyringStore;
use std::{
    path::PathBuf,
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};
#[derive(Clone, Copy)]
pub struct SystemClock;
impl Clock for SystemClock {
    fn now_ms(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as u64
    }
}
#[derive(Clone)]
pub struct NativePlatform {
    pub kv: FileKv,
    pub secure: KeyringStore,
}
impl NativePlatform {
    pub fn open(dir: PathBuf) -> Result<Self> {
        Ok(Self {
            kv: FileKv::open(dir)?,
            secure: KeyringStore::new(crate::network::credential_service().into()),
        })
    }
}
impl Platform for NativePlatform {
    type Kv = FileKv;
    type Secure = KeyringStore;
    type Http = ReqwestHttpClient;
    type Ws = ws::TungsteniteConnector;
    type Clock = SystemClock;
    fn kv(&self) -> Self::Kv {
        self.kv.clone()
    }
    fn secure(&self) -> Self::Secure {
        self.secure.clone()
    }
    fn http(&self) -> Self::Http {
        ReqwestHttpClient::default()
    }
    fn ws(&self) -> Self::Ws {
        ws::TungsteniteConnector
    }
    fn clock(&self) -> Self::Clock {
        SystemClock
    }
    fn spawner(&self) -> Arc<dyn Spawner> {
        Arc::new(runtime::TokioTaskSpawner)
    }
    fn timer(&self) -> Arc<dyn Timer> {
        Arc::new(runtime::TokioTimer)
    }
    fn blocking(&self) -> Option<Arc<dyn BlockingSpawner>> {
        Some(Arc::new(runtime::TokioSpawner))
    }
}

#[cfg(debug_assertions)]
impl NativePlatform {
    /// Explicit isolated profile for native QA; release builds cannot select it.
    pub fn open_debug_profile(root: PathBuf, profile: &str) -> Result<Self> {
        if !cfg!(feature = "testnet")
            || profile.is_empty()
            || profile.len() > 64
            || !profile
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b == b'-')
        {
            return Err(mooze_core::Error::InvalidInput(
                "invalid validation profile".into(),
            ));
        }
        Ok(Self {
            kv: FileKv::open(root.join("testnet-validation").join(profile))?,
            secure: KeyringStore::new(format!("app.mooze.desktop.testnet.validation.{profile}")),
        })
    }
}
