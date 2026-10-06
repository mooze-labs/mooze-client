use super::*;
use mooze_core::ports::{BlockingSpawner, Spawner, TaskFuture, Timer};
use mooze_core::testing::{FixedClock, MemoryKv, MockHttp, MockWs};
#[derive(Clone)]
struct TestPlatform {
    kv: FaultStore,
    secure: FaultStore,
    clock: Arc<FixedClock>,
}
struct Idle;
impl Spawner for Idle {
    fn spawn(&self, _: TaskFuture<'static, ()>) {}
}
impl Timer for Idle {
    fn sleep(&self, _: u64) -> TaskFuture<'static, ()> {
        Box::pin(std::future::pending())
    }
}
impl Platform for TestPlatform {
    type Kv = FaultStore;
    type Secure = FaultStore;
    type Clock = Arc<FixedClock>;
    type Http = MockHttp;
    type Ws = MockWs;
    fn kv(&self) -> FaultStore {
        self.kv.clone()
    }
    fn secure(&self) -> FaultStore {
        self.secure.clone()
    }
    fn clock(&self) -> Self::Clock {
        self.clock.clone()
    }
    fn http(&self) -> MockHttp {
        MockHttp::default()
    }
    fn ws(&self) -> MockWs {
        MockWs::new(|_| vec![])
    }
    fn spawner(&self) -> Arc<dyn Spawner> {
        Arc::new(Idle)
    }
    fn timer(&self) -> Arc<dyn Timer> {
        Arc::new(Idle)
    }
    fn blocking(&self) -> Option<Arc<dyn BlockingSpawner>> {
        None
    }
}
fn platform() -> TestPlatform {
    TestPlatform {
        kv: FaultStore::default(),
        secure: FaultStore::default(),
        clock: Arc::new(FixedClock::new(1000)),
    }
}
const PHRASE: &str =
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
#[tokio::test]
async fn import_lock_restart_and_pin_retry() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    assert_eq!(s.status().await.unwrap().status, "empty");
    assert!(s.snapshot().await.is_err());
    assert!(s
        .import_wallet("bad words".into(), "123456".into())
        .await
        .is_err());
    assert_eq!(
        s.import_wallet(PHRASE.into(), "123456".into())
            .await
            .unwrap()
            .status,
        "unlocked"
    );
    assert!(s
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .is_err());
    assert_eq!(s.lock().await.unwrap().status, "locked");
    assert!(s.snapshot().await.is_err());
    for _ in 0..5 {
        assert!(s.unlock("000000".into()).await.is_err());
    }
    assert_eq!(
        s.unlock("123456".into()).await.unwrap_err().code,
        "rate_limited"
    );
    let restarted = WalletSession::new(p.clone(), BackendDto::Esplora);
    assert_eq!(restarted.status().await.unwrap().status, "locked");
    p.clock.advance(29_999);
    assert!(restarted.unlock("123456".into()).await.is_err());
    p.clock.advance(1);
    assert_eq!(
        restarted.unlock("123456".into()).await.unwrap().status,
        "unlocked"
    );
    for key in p.kv.list_keys("").await.unwrap() {
        let v = p.kv.get(&key).await.unwrap().unwrap();
        let text = String::from_utf8_lossy(&v);
        assert!(!text.contains(PHRASE));
        assert!(!text.contains("tprv"));
        assert!(!text.contains("xprv"));
    }
}

#[derive(Clone, Default)]
struct FaultStore {
    pause_submission: Arc<AtomicBool>,
    entered: Arc<tokio::sync::Notify>,
    release: Arc<tokio::sync::Notify>,
    deny_reads: Arc<AtomicBool>,
    data: MemoryKv,
    writes: Arc<std::sync::atomic::AtomicUsize>,
    fail_at: Arc<std::sync::atomic::AtomicUsize>,
}
impl KvStore for FaultStore {
    async fn get(&self, key: &str) -> mooze_core::Result<Option<Vec<u8>>> {
        if self.deny_reads.load(Ordering::SeqCst) {
            return Err(mooze_core::Error::storage("injected read denial"));
        }
        if key == SUBMISSION && self.pause_submission.swap(false, Ordering::SeqCst) {
            self.entered.notify_one();
            self.release.notified().await;
        }
        self.data.get(key).await
    }
    async fn put(&self, key: &str, value: Vec<u8>) -> mooze_core::Result<()> {
        let n = self.writes.fetch_add(1, Ordering::SeqCst) + 1;
        if self.fail_at.load(Ordering::SeqCst) == n {
            return Err(mooze_core::Error::storage("injected denial"));
        }
        self.data.put(key, value).await
    }
    async fn delete(&self, key: &str) -> mooze_core::Result<()> {
        self.data.delete(key).await
    }
    async fn list_keys(&self, prefix: &str) -> mooze_core::Result<Vec<String>> {
        self.data.list_keys(prefix).await
    }
}
impl mooze_core::ports::SecureStore for FaultStore {}

#[tokio::test]
async fn every_import_write_failure_can_be_retried_without_replacing_a_wallet() {
    let baseline = platform();
    let session = WalletSession::new(baseline.clone(), BackendDto::Esplora);
    session
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let writes = baseline.kv.writes.load(Ordering::SeqCst);
    let secure_writes = baseline.secure.writes.load(Ordering::SeqCst);
    for (secure, count) in [(false, writes), (true, secure_writes)] {
        for fail in 1..=count {
            let p = platform();
            let store = if secure { &p.secure } else { &p.kv };
            store.fail_at.store(fail, Ordering::SeqCst);
            let s = WalletSession::new(p.clone(), BackendDto::Esplora);
            assert!(
                s.import_wallet(PHRASE.into(), "123456".into())
                    .await
                    .is_err(),
                "write {fail}, secure {secure}"
            );
            assert!(!s.unlocked.load(Ordering::SeqCst));
            assert_eq!(s.status().await.unwrap().status, "empty");
            let restarted = WalletSession::new(p, BackendDto::Esplora);
            assert_eq!(
                restarted
                    .import_wallet(PHRASE.into(), "123456".into())
                    .await
                    .unwrap()
                    .status,
                "unlocked"
            );
        }
    }
}

#[tokio::test]
async fn lock_during_authentication_cannot_reopen_the_session() {
    let s = WalletSession::new(platform(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let expected = s.generation.load(Ordering::SeqCst);
    s.lock().await.unwrap();
    let mut inner = s.inner.lock().await;
    assert_eq!(
        s.open_session(&mut inner, expected).await.unwrap_err().code,
        "locked"
    );
    assert!(!s.unlocked.load(Ordering::SeqCst));
}

#[test]
fn chain_health_retains_last_good_snapshot_and_recovers_independently() {
    let s = WalletSession::new(platform(), BackendDto::Esplora);
    let sink = Sink {
        unlocked: s.unlocked.clone(),
        generation: s.generation.clone(),
        sync: s.sync.clone(),
        chains: s.chains.clone(),
        emit: s.emit.clone(),
    };
    for (chain, succeeded, observed_at_ms) in [
        (ChainDto::Bitcoin, true, 100),
        (ChainDto::Liquid, false, 101),
        (ChainDto::Bitcoin, false, 102),
    ] {
        sink.send(AppEvent::ChainSyncState(ChainSyncStateDto {
            chain,
            succeeded,
            observed_at_ms,
        }));
    }
    let states = s.chains.lock().unwrap();
    let btc = states
        .iter()
        .find(|c| c.chain == WalletChain::Bitcoin)
        .unwrap();
    assert_eq!(btc.phase, "error");
    assert_eq!(btc.last_success_at_ms, Some(100));
    assert_eq!(
        states
            .iter()
            .find(|c| c.chain == WalletChain::Liquid)
            .unwrap()
            .last_success_at_ms,
        None
    );
    drop(states);
    sink.send(AppEvent::ChainSyncState(ChainSyncStateDto {
        chain: ChainDto::Liquid,
        succeeded: true,
        observed_at_ms: 103,
    }));
    assert_eq!(
        s.chains
            .lock()
            .unwrap()
            .iter()
            .find(|c| c.chain == WalletChain::Liquid)
            .unwrap()
            .phase,
        "ready"
    );
}

#[test]
fn unsafe_wire_integers_are_rejected_including_negative_amounts() {
    assert!(check_safe(&serde_json::json!({"amount":rules::MAX_SAFE})).is_ok());
    assert!(check_safe(&serde_json::json!({"amount":rules::MAX_SAFE+1})).is_err());
    assert!(check_safe(&serde_json::json!({"amount":-((rules::MAX_SAFE+1) as i64)})).is_err());
}

#[tokio::test]
async fn lock_notification_survives_storage_failure() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let events = Arc::new(StdMutex::new(Vec::new()));
    let capture = events.clone();
    s.set_emitter(Arc::new(move |v| capture.lock().unwrap().push(v)));
    p.kv.deny_reads.store(true, Ordering::SeqCst);
    let state = s.lock().await.unwrap();
    assert_eq!(state.status, "locked");
    let events = events.lock().unwrap();
    assert_eq!(events.last().unwrap()["data"]["status"], "locked");
}

#[tokio::test]
async fn unfinished_submission_survives_restart_and_requires_acknowledgment() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.kv.put(
        SUBMISSION,
        serde_json::to_vec(&SubmissionDto {
            phase: "submitting".into(),
            chain: WalletChain::Bitcoin,
            tx_id: None,
        })
        .unwrap(),
    )
    .await
    .unwrap();
    let restarted = WalletSession::new(p, BackendDto::Esplora);
    restarted.unlock("123456".into()).await.unwrap();
    assert_eq!(
        restarted
            .snapshot()
            .await
            .unwrap()
            .submission
            .unwrap()
            .phase,
        "uncertain"
    );
    let request = ReviewRequestDto {
        chain: WalletChain::Bitcoin,
        destination: "tb1-test".into(),
        amount_sat: 1000,
        fee_rate_sat_per_vbyte: 1.,
    };
    assert_eq!(
        restarted.review(request).await.unwrap_err().code,
        "submission_unknown"
    );
    restarted.submitting.store(true, Ordering::SeqCst);
    assert!(restarted.acknowledge_submission().await.is_err());
    restarted.submitting.store(false, Ordering::SeqCst);
    restarted.acknowledge_submission().await.unwrap();
    assert!(restarted.submission().await.unwrap().is_none());
}

#[tokio::test]
async fn lock_while_reading_submission_rejects_snapshot() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.kv.pause_submission.store(true, Ordering::SeqCst);
    let (result, _) = tokio::join!(s.snapshot(), async {
        p.kv.entered.notified().await;
        s.lock().await.unwrap();
        p.kv.release.notify_one();
    });
    assert_eq!(result.unwrap_err().code, "locked");
}
