use super::*;
use mooze_core::ports::{BlockingSpawner, Spawner, TaskFuture, Timer};
use mooze_core::testing::{FixedClock, MemoryKv, MockHttp, MockWs};
#[derive(Clone)]
struct TestPlatform {
    http: MockHttp,
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
        self.http.clone()
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
        http: MockHttp::default(),
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
    deny_key: Arc<StdMutex<Option<String>>>,
    fail_delete: Arc<StdMutex<Option<String>>>,
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
        if self.deny_key.lock().unwrap().as_deref() == Some(key)
            || self.deny_reads.load(Ordering::SeqCst)
        {
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
        {
            let mut fail = self.fail_delete.lock().unwrap();
            if fail.as_deref() == Some(key) {
                *fail = None;
                return Err(mooze_core::Error::storage("injected delete failure"));
            }
        }
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
        transition: s.transition.clone(),
        expected: 0,
        swaps: s.swaps.clone(),
        clock: Arc::new(s.platform.clock()),
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
            version: 2,
            request: None,
            debits: None,
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
        asset: AssetKeyDto {
            chain: ChainDto::Bitcoin,
            asset_id: None,
        },
        destination: "tb1-test".into(),
        amount: SendAmountDto::Exact("1000".into()),
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

#[tokio::test]
async fn expired_command_locks_without_timer_tick() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    let session = s
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.clock.advance(60_000);
    assert!(s.approved_assets().is_err());
    assert_eq!(s.status().await.unwrap().status, "locked");
    assert!(s.record_activity(session.generation).is_err());
}
#[tokio::test]
async fn old_generation_activity_cannot_extend_session() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    let session = s
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.clock.advance(50_000);
    assert!(s.record_activity(session.generation - 1).is_err());
    p.clock.advance(10_000);
    assert!(s.approved_assets().is_err());
}

#[tokio::test]
async fn setup_verifies_backup_and_discards_cancelled_candidate() {
    let s = WalletSession::new(platform(), BackendDto::Esplora);
    let first = s.begin_setup(false).await.unwrap();
    assert_eq!(first.words.len(), 12);
    assert!(s
        .complete_setup(
            first.setup_id.clone(),
            vec!["wrong".into(); 3],
            "123456".into()
        )
        .await
        .is_err());
    s.cancel_setup(first.setup_id.clone()).unwrap();
    let answers = first
        .challenge_indices
        .iter()
        .map(|i| first.words[*i as usize].clone())
        .collect();
    assert!(s
        .complete_setup(first.setup_id, answers, "123456".into())
        .await
        .is_err());
    let second = s.begin_setup(true).await.unwrap();
    assert_eq!(second.words.len(), 24);
    let answers = second
        .challenge_indices
        .iter()
        .map(|i| second.words[*i as usize].clone())
        .collect();
    assert_eq!(
        s.complete_setup(second.setup_id, answers, "123456".into())
            .await
            .unwrap()
            .status,
        "unlocked"
    );
    assert!(s.begin_setup(false).await.is_err());
}

#[tokio::test]
async fn security_settings_and_fresh_pin_checks() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    assert_eq!(s.settings().await.unwrap().lock_minutes, 1);
    assert!(s.set_lock_minutes(2).await.is_err());
    assert_eq!(s.set_lock_minutes(15).await.unwrap().lock_minutes, 15);
    assert!(s.reveal_recovery_phrase("000000".into()).await.is_err());
    assert_eq!(
        s.reveal_recovery_phrase("123456".into())
            .await
            .unwrap()
            .join(" "),
        PHRASE
    );
    s.change_pin("123456".into(), "654321".into())
        .await
        .unwrap();
    s.lock().await.unwrap();
    assert!(s.reveal_recovery_phrase("654321".into()).await.is_err());
    assert!(s.unlock("123456".into()).await.is_err());
    assert!(s.unlock("654321".into()).await.is_ok());
}

#[tokio::test]
async fn display_preferences_validate_and_survive_restart() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    assert!(s
        .save_display("fr".into(), "BTC".into(), false)
        .await
        .is_err());
    assert!(s
        .save_display("en".into(), "TEST".into(), false)
        .await
        .is_err());
    s.save_display("en".into(), "sat".into(), true)
        .await
        .unwrap();
    s.lock().await.unwrap();
    let restarted = WalletSession::new(p, BackendDto::Esplora);
    restarted.unlock("123456".into()).await.unwrap();
    let settings = restarted.settings().await.unwrap();
    assert_eq!(settings.locale, "en");
    assert_eq!(settings.bitcoin_unit, "sat");
    assert!(settings.privacy);
}

#[tokio::test]
async fn invalid_node_keeps_settings_and_default_restore_revokes_review_generation() {
    let p = platform();
    let s = WalletSession::new(p, BackendDto::Esplora);
    let session = s
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    assert!(s
        .save_node(
            WalletChain::Bitcoin,
            Some("https://wrong:50002/path".into()),
            false
        )
        .await
        .is_err());
    assert!(s.settings().await.unwrap().bitcoin_node.is_none());
    assert_eq!(s.status().await.unwrap().generation, session.generation);
    s.save_node(WalletChain::Bitcoin, None, false)
        .await
        .unwrap();
    assert!(s.status().await.unwrap().generation > session.generation);
    assert!(s.snapshot().await.is_ok());
}

#[tokio::test]
async fn partial_removal_is_locked_and_can_resume_after_restart() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    assert!(s.remove_wallet("000000".into()).await.is_err());
    assert_eq!(s.status().await.unwrap().status, "unlocked");
    *p.secure.fail_delete.lock().unwrap() = Some("mnemonic_mainWallet".into());
    assert!(s.remove_wallet("123456".into()).await.is_err());
    assert_eq!(s.status().await.unwrap().status, "removal_pending");
    assert!(s.snapshot().await.is_err());
    let restarted = WalletSession::new(p.clone(), BackendDto::Esplora);
    assert_eq!(restarted.status().await.unwrap().status, "removal_pending");
    assert!(restarted.unlock("123456".into()).await.is_err());
    restarted.remove_wallet(String::new()).await.unwrap();
    assert_eq!(restarted.status().await.unwrap().status, "empty");
    assert!(p.secure.list_keys("").await.unwrap().is_empty());
    assert!(p.kv.list_keys("").await.unwrap().is_empty());
}

#[tokio::test]
async fn failed_pin_change_preserves_existing_pin() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.secure
        .fail_at
        .store(p.secure.writes.load(Ordering::SeqCst) + 1, Ordering::SeqCst);
    assert!(s
        .change_pin("123456".into(), "654321".into())
        .await
        .is_err());
    s.lock().await.unwrap();
    assert!(s.unlock("123456".into()).await.is_ok());
}

#[tokio::test]
async fn failed_node_replacement_and_restore_reconnects_on_unlock() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    *p.kv.deny_key.lock().unwrap() = Some("wallet/bitcoin/changeset".into());
    assert!(s
        .save_node(WalletChain::Bitcoin, None, false)
        .await
        .is_err());
    assert!(s.inner.lock().await.app.is_none());
    assert!(!s.unlocked.load(Ordering::SeqCst));
    *p.kv.deny_key.lock().unwrap() = None;
    s.unlock("123456".into()).await.unwrap();
    assert!(s.snapshot().await.is_ok());
}

#[tokio::test]
async fn service_calls_require_unlock_and_never_expose_tokens() {
    let s = WalletSession::new(platform(), BackendDto::Esplora);
    assert!(s.backend_status().await.is_err());
    assert!(s.pix_history().await.is_err());
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let status = s.backend_retry().await.unwrap();
    assert_ne!(status.state, "Ready");
    assert!(s.snapshot().await.is_ok());
    let json = serde_json::to_string(&status).unwrap();
    assert!(!json.contains("jwt"));
    assert!(!json.contains("refresh_token"));
}

#[tokio::test]
async fn uncertain_swap_survives_restart_and_blocks_onchain_send() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.kv.put(
        swaps::SWAP_SUBMISSION,
        serde_json::to_vec(&SwapStateDto::phase("Submitting")).unwrap(),
    )
    .await
    .unwrap();
    assert_eq!(s.swap_status().await.unwrap().phase, "Uncertain");
    assert!(s.swap_acknowledge().await.is_err());
    let error = s
        .review(ReviewRequestDto {
            asset: AssetKeyDto {
                chain: ChainDto::Bitcoin,
                asset_id: None,
            },
            destination: "address".into(),
            amount: SendAmountDto::Exact("1000".into()),
            fee_rate_sat_per_vbyte: 1.0,
        })
        .await
        .unwrap_err();
    assert_eq!(error.code, "submission_unknown");
    s.lock().await.unwrap();
    let restarted = WalletSession::new(p, BackendDto::Esplora);
    restarted.unlock("123456".into()).await.unwrap();
    assert_eq!(restarted.swap_status().await.unwrap().phase, "Uncertain");
}
#[tokio::test]
async fn idle_cleanup_drops_app_and_unlock_rebuilds_it() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.clock.advance(60_001);
    s.check_expiry();
    s.cleanup_locked().await;
    assert!(s.inner.lock().await.app.is_none());
    s.unlock("123456".into()).await.unwrap();
    assert!(s.snapshot().await.is_ok());
}
#[test]
fn obsolete_sink_does_not_update_new_session_state() {
    let s = WalletSession::new(platform(), BackendDto::Esplora);
    let sink = Sink {
        transition: s.transition.clone(),
        expected: 0,
        swaps: s.swaps.clone(),
        clock: Arc::new(s.platform.clock()),
        unlocked: s.unlocked.clone(),
        generation: s.generation.clone(),
        sync: s.sync.clone(),
        chains: s.chains.clone(),
        emit: s.emit.clone(),
    };
    s.generation.store(1, Ordering::SeqCst);
    assert!(!sink.send(AppEvent::ChainSyncState(ChainSyncStateDto {
        chain: ChainDto::Bitcoin,
        succeeded: true,
        observed_at_ms: 100
    })));
    assert!(s.chains.lock().unwrap().is_empty());
}

#[cfg(not(feature = "testnet"))]
fn authenticated_platform() -> TestPlatform {
    use mooze_core::ports::HttpMethod;
    let p = platform();
    let base = mooze_core::api::DEFAULT_BASE_URL;
    p.http.on_json(
        HttpMethod::Post,
        &format!("{base}/auth/challenge"),
        200,
        serde_json::json!({"data":{"id":"challenge","message":"SGVsbG8gV29ybGQ="}}),
    );
    p.http.on_json(HttpMethod::Post,&format!("{base}/auth/sign"),200,serde_json::json!({"data":{"jwt":"eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUxIn0.sig","refresh_token":"mock-refresh"}}));
    p
}
#[cfg(not(feature = "testnet"))]
#[tokio::test]
async fn pix_authenticates_creates_persists_and_does_not_retry_ambiguous_creation() {
    use mooze_core::ports::HttpMethod;
    let p = authenticated_platform();
    let base = mooze_core::api::DEFAULT_BASE_URL;
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    assert_eq!(s.backend_retry().await.unwrap().state, "Ready");
    p.http.on_json(HttpMethod::Post,&format!("{base}/v2/transactions"),200,serde_json::json!({"data":{"transaction_id":"dep1","qr_copy_paste":"qr-copy","qr_image_url":"https://unused.test"}}));
    let request = PixCreateRequestDto {
        amount_in_cents: "1234".into(),
        asset_id: mooze_core::domain::DEPIX_ASSET_ID.into(),
        tax_id_number: "52998224725".into(),
    };
    let deposit = s.pix_create(request.clone()).await.unwrap();
    assert_eq!(deposit.amount_in_cents, "1234");
    assert_eq!(deposit.pix_key, "qr-copy");
    assert_eq!(s.pix_history().await.unwrap().deposits.len(), 1);
    p.http.on_json(
        HttpMethod::Post,
        &format!("{base}/v2/transactions"),
        503,
        serde_json::json!({"error":"unavailable"}),
    );
    assert_eq!(
        s.pix_create(request.clone()).await.unwrap_err().code,
        "pix_uncertain"
    );
    let count = p.http.requests().len();
    assert_eq!(
        s.pix_create(request).await.unwrap_err().code,
        "pix_uncertain"
    );
    assert_eq!(p.http.requests().len(), count);
    assert!(s.pix_history().await.unwrap().creation_uncertain);
    s.lock().await.unwrap();
    s.unlock("123456".into()).await.unwrap();
    assert!(s.pix_history().await.unwrap().creation_uncertain);
}
#[cfg(feature = "testnet")]
#[tokio::test]
async fn testnet_never_contacts_production_payment_services() {
    let p = platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    assert_eq!(s.backend_retry().await.unwrap().state, "Disabled");
    assert!(s.pix_history().await.is_err());
    assert!(s.swap_markets().await.is_err());
    assert!(p.http.requests().is_empty());
}

#[cfg(not(feature = "testnet"))]
#[tokio::test]
async fn concurrent_pix_creation_is_rejected_without_waiting_or_posting() {
    let p = authenticated_platform();
    let s = WalletSession::new(p.clone(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    s.backend_retry().await.unwrap();
    let _pending = s.pix_gate.lock().await;
    let before = p.http.requests().len();
    let result = tokio::time::timeout(
        std::time::Duration::from_millis(50),
        s.pix_create(PixCreateRequestDto {
            amount_in_cents: "1234".into(),
            asset_id: mooze_core::domain::DEPIX_ASSET_ID.into(),
            tax_id_number: "52998224725".into(),
        }),
    )
    .await
    .expect("concurrent creation must not queue");
    assert_eq!(result.unwrap_err().code, "busy");
    assert_eq!(p.http.requests().len(), before);
}

#[tokio::test]
async fn authentication_continuation_is_dropped_after_lock() {
    let s = WalletSession::new(platform(), BackendDto::Esplora);
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let generation = s.authorize().unwrap();
    let (tx, rx) = tokio::sync::oneshot::channel::<()>();
    let continued = AtomicBool::new(false);
    let operation = async {
        rx.await.unwrap(); // e.g. an outstanding auth challenge or refresh
        continued.store(true, Ordering::SeqCst);
    };
    let guarded = s.run_session_service(generation, operation);
    tokio::pin!(guarded);
    assert!(futures::poll!(&mut guarded).is_pending());
    s.lock().await.unwrap();
    tx.send(()).unwrap();
    assert_eq!(guarded.await.unwrap_err().code, "locked");
    assert!(!continued.load(Ordering::SeqCst));
}

#[test]
fn sink_waiting_across_transition_cannot_mutate_the_new_session() {
    let s = WalletSession::new(platform(), BackendDto::Esplora);
    let sink = Sink {
        transition: s.transition.clone(),
        expected: 0,
        swaps: s.swaps.clone(),
        clock: Arc::new(s.platform.clock()),
        unlocked: s.unlocked.clone(),
        generation: s.generation.clone(),
        sync: s.sync.clone(),
        chains: s.chains.clone(),
        emit: s.emit.clone(),
    };
    let transition = s.transition.lock().unwrap();
    let (started_tx, started_rx) = std::sync::mpsc::channel();
    let worker = std::thread::spawn(move || {
        started_tx.send(()).unwrap();
        sink.send(AppEvent::ChainSyncState(ChainSyncStateDto {
            chain: ChainDto::Bitcoin,
            succeeded: true,
            observed_at_ms: 100,
        }))
    });
    started_rx.recv().unwrap();
    s.generation.store(1, Ordering::SeqCst);
    drop(transition);
    assert!(!worker.join().unwrap());
    assert!(s.chains.lock().unwrap().is_empty());
}

#[tokio::test]
async fn locked_service_cancels_without_a_transport_wake() {
    let s = Arc::new(WalletSession::new(platform(), BackendDto::Esplora));
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let generation = s.authorize().unwrap();
    let (started_tx, started_rx) = tokio::sync::oneshot::channel();
    let worker_session = s.clone();
    let worker = tokio::spawn(async move {
        worker_session
            .run_session_service(generation, async {
                started_tx.send(()).unwrap();
                std::future::pending::<()>().await;
            })
            .await
    });
    started_rx.await.unwrap();
    s.lock().await.unwrap();
    let result = tokio::time::timeout(std::time::Duration::from_millis(500), worker).await;
    assert_eq!(
        result
            .expect("stalled transport must be dropped promptly")
            .unwrap()
            .unwrap_err()
            .code,
        "locked"
    );
}

#[tokio::test]
async fn account_and_market_reads_require_an_unlocked_session() {
    let p = platform();
    let session = WalletSession::new(p.clone(), BackendDto::Esplora);
    assert_eq!(session.account_level().await.unwrap_err().code, "locked");
    assert_eq!(
        session
            .price_history(PriceMarketDto::Bitcoin, "brl".into(), 7)
            .await
            .unwrap_err()
            .code,
        "locked"
    );
    assert!(p.http.requests().is_empty());
}

#[cfg(not(feature = "testnet"))]
#[tokio::test]
async fn account_level_reads_authenticated_profile_and_shared_tiers() {
    use mooze_core::ports::HttpMethod;
    let p = authenticated_platform();
    p.http.on_json(HttpMethod::Get, &format!("{}/users/me", mooze_core::api::DEFAULT_BASE_URL), 200,
        serde_json::json!({"data":{"user_id":"test-user","verification_level":0,"allowed_spending":25000,"daily_spending":10000,"spending_level":0,"level_progress":0.2}}));
    p.http.on_json(HttpMethod::Get, mooze_core::user::WALLET_LEVELS_URL, 200,
        serde_json::json!({"data":{"bronze":{"min_limit":2000,"max_limit":25000},"silver":{"min_limit":2000,"max_limit":50000},"gold":{"min_limit":2000,"max_limit":100000},"diamond":{"min_limit":2000,"max_limit":300000}}}));
    let session = WalletSession::new(p.clone(), BackendDto::Esplora);
    session
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let result = session.account_level().await.unwrap();
    assert_eq!(result.current_level, "bronze");
    assert_eq!(result.per_transaction_brl, 250.0);
    assert_eq!(result.spent_today_brl, 100.0);
    let requests = p.http.requests();
    let profile = requests
        .iter()
        .find(|r| r.url.ends_with("/users/me"))
        .unwrap();
    assert!(profile
        .headers
        .keys()
        .any(|k| k.eq_ignore_ascii_case("authorization")));
    let tiers = requests
        .iter()
        .find(|r| r.url == mooze_core::user::WALLET_LEVELS_URL)
        .unwrap();
    assert!(!tiers
        .headers
        .keys()
        .any(|k| k.eq_ignore_ascii_case("authorization")));
}

#[tokio::test]
async fn market_history_returns_timestamps_without_wallet_data_or_auth() {
    use mooze_core::ports::HttpMethod;
    let p = platform();
    let url = "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=brl&days=7";
    p.http.on_json(
        HttpMethod::Get,
        url,
        200,
        serde_json::json!({"prices":[[1000,100.0],[2000,110.0]]}),
    );
    let session = WalletSession::new(p.clone(), BackendDto::Esplora);
    session
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    let result = session
        .price_history(PriceMarketDto::Bitcoin, "brl".into(), 7)
        .await
        .unwrap();
    assert_eq!(result.points[0].timestamp_ms, 1000);
    assert_eq!(result.points[1].price, 110.0);
    let requests = p.http.requests();
    let request = requests.iter().find(|r| r.url == url).unwrap();
    assert!(request.body.is_none());
    assert!(!request
        .headers
        .keys()
        .any(|k| k.eq_ignore_ascii_case("authorization")));
}
