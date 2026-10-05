//! Test platform over the mooze-core fakes.

use std::sync::Arc;

use mooze_core::ports::{BlockingSpawner, KvStore, Spawner, Timer};
use mooze_core::testing::{
    ChannelSpawner, FixedClock, InlineSpawner, ManualTimer, MemoryKv, MockHttp, MockWs,
    TestExecutor,
};

use crate::dto::{AppConfig, BackendDto, NetworkDto};
use crate::{App, Platform};

pub const ABANDON: &str =
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
/// Unsigned JWTs that expire in 2100.
pub const JWT_1: &str =
    "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUxIn0.sig";
pub const JWT_2: &str =
    "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUyIn0.sig";

#[derive(Clone)]
pub struct TestPlatform {
    pub kv: MemoryKv,
    pub secure: MemoryKv,
    pub http: MockHttp,
    pub ws: MockWs,
    pub clock: Arc<FixedClock>,
    pub spawner: ChannelSpawner,
    pub timer: Arc<ManualTimer>,
}

impl TestPlatform {
    /// Platform plus the executor that runs its spawned tasks.
    pub fn new() -> (Self, TestExecutor) {
        let (spawner, exec) = TestExecutor::new();
        let plat = Self {
            kv: MemoryKv::new(),
            secure: MemoryKv::new(),
            http: MockHttp::new(),
            ws: MockWs::new(|_| Vec::new()),
            clock: Arc::new(FixedClock::new(1_800_000_000_000)),
            spawner,
            timer: Arc::new(ManualTimer::new()),
        };
        (plat, exec)
    }

    pub fn with_ws(mut self, ws: MockWs) -> Self {
        self.ws = ws;
        self
    }

    pub fn secure_insert(&self, key: &str, value: &str) {
        mooze_core::testing::block_on(self.secure.put(key, value.as_bytes().to_vec())).unwrap();
    }

    pub fn secure_get(&self, key: &str) -> Option<String> {
        mooze_core::testing::block_on(self.secure.get(key))
            .unwrap()
            .map(|b| String::from_utf8(b).unwrap())
    }
}

impl Platform for TestPlatform {
    type Kv = MemoryKv;
    type Secure = MemoryKv;
    type Http = MockHttp;
    type Ws = MockWs;
    type Clock = Arc<FixedClock>;
    fn kv(&self) -> MemoryKv {
        self.kv.clone()
    }
    fn secure(&self) -> MemoryKv {
        self.secure.clone()
    }
    fn http(&self) -> MockHttp {
        self.http.clone()
    }
    fn ws(&self) -> MockWs {
        self.ws.clone()
    }
    fn clock(&self) -> Arc<FixedClock> {
        self.clock.clone()
    }
    fn spawner(&self) -> Arc<dyn Spawner> {
        Arc::new(self.spawner.clone())
    }
    fn timer(&self) -> Arc<dyn Timer> {
        self.timer.clone()
    }
    fn blocking(&self) -> Option<Arc<dyn BlockingSpawner>> {
        Some(Arc::new(InlineSpawner))
    }
}

pub fn test_config() -> AppConfig {
    AppConfig {
        network: NetworkDto::Mainnet,
        backend: BackendDto::Esplora,
        bitcoin_node_url: String::new(),
        liquid_node_url: String::new(),
        api_base_url: None,
    }
}

/// Open app over a fresh test platform. Drops the executor: tests that
/// need spawned tasks call `open_test_app_with_executor`.
pub fn open_test_app() -> (App<TestPlatform>, TestPlatform) {
    let (app, plat, _exec) = open_test_app_with_executor();
    (app, plat)
}

pub fn open_test_app_with_executor() -> (App<TestPlatform>, TestPlatform, TestExecutor) {
    let (plat, exec) = TestPlatform::new();
    let app = mooze_core::testing::block_on(App::open(test_config(), plat.clone())).unwrap();
    (app, plat, exec)
}
