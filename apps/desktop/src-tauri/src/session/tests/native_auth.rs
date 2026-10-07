use super::*;
use crate::native_auth::{
    NativeAuthenticator, NativeAvailability, NativeCapabilities, NativeKind, NativeOutcome,
};
use futures::future::BoxFuture;
use tokio::sync::{mpsc, oneshot};
struct FakeAuth {
    requests: mpsc::UnboundedSender<oneshot::Sender<NativeOutcome>>,
}
impl NativeAuthenticator for FakeAuth {
    fn capabilities(&self) -> BoxFuture<'_, NativeCapabilities> {
        Box::pin(async {
            NativeCapabilities {
                kind: NativeKind::TouchId,
                availability: NativeAvailability::Available,
            }
        })
    }
    fn verify(&self, _: u64, _: String) -> BoxFuture<'_, NativeOutcome> {
        let (tx, rx) = oneshot::channel();
        self.requests.send(tx).unwrap();
        Box::pin(async { rx.await.unwrap_or(NativeOutcome::Failed) })
    }
    fn cancel(&self, _: u64) {} // Deliberately allow late completion to test Rust authorization.
}
async fn fixture() -> (
    Arc<WalletSession<TestPlatform>>,
    mpsc::UnboundedReceiver<oneshot::Sender<NativeOutcome>>,
) {
    let (tx, rx) = mpsc::unbounded_channel();
    let session = Arc::new(
        WalletSession::new(platform(), BackendDto::Esplora)
            .with_native_authenticator(Arc::new(FakeAuth { requests: tx })),
    );
    session
        .import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    (session, rx)
}
async fn enable(
    s: &Arc<WalletSession<TestPlatform>>,
    rx: &mut mpsc::UnboundedReceiver<oneshot::Sender<NativeOutcome>>,
) {
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Verified)
        .unwrap();
    assert!(task.await.unwrap().unwrap().enabled);
}
#[tokio::test]
async fn native_defaults_disabled_and_enrollment_requires_verified() {
    let (s, mut rx) = fixture().await;
    assert!(!s.native_auth_status().await.unwrap().enabled);
    assert!(s.native_auth_status().await.unwrap().setup_offer_pending);
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Cancelled)
        .unwrap();
    assert_eq!(task.await.unwrap().unwrap_err().code, "native_cancelled");
    assert!(!s.native_auth_status().await.unwrap().enabled);
    enable(&s, &mut rx).await;
    s.lock().await.unwrap();
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.unlock_native().await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Verified)
        .unwrap();
    assert_eq!(task.await.unwrap().unwrap().status, "unlocked");
}
#[tokio::test]
async fn cancellation_invalidates_late_success_and_allows_pin() {
    let (s, mut rx) = fixture().await;
    enable(&s, &mut rx).await;
    s.lock().await.unwrap();
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.unlock_native().await });
    let pending = rx.recv().await.unwrap();
    assert_eq!(s.unlock_native().await.unwrap_err().code, "native_busy");
    s.cancel_native_auth().unwrap();
    let pin_session = s.unlock("123456".into()).await.unwrap();
    pending.send(NativeOutcome::Verified).unwrap();
    assert!(task.await.unwrap().is_err());
    assert_eq!(s.status().await.unwrap().generation, pin_session.generation);
}
#[tokio::test]
async fn lock_during_enrollment_does_not_enable() {
    let (s, mut rx) = fixture().await;
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    let pending = rx.recv().await.unwrap();
    s.lock().await.unwrap();
    pending.send(NativeOutcome::Verified).unwrap();
    assert!(task.await.unwrap().is_err());
    assert!(!s.native_auth_status().await.unwrap().enabled);
}
#[tokio::test]
async fn settings_require_pin_and_skip_consumes_setup_grant() {
    let (s, _rx) = fixture().await;
    assert!(
        !s.complete_native_auth_offer(false)
            .await
            .unwrap()
            .setup_offer_pending
    );
    assert!(s.complete_native_auth_offer(true).await.is_err());
    assert!(s
        .set_native_auth_enabled(true, "000000".into())
        .await
        .is_err());
}
#[tokio::test]
async fn native_failures_never_unlock_or_modify_pin_throttle() {
    let (s, mut rx) = fixture().await;
    enable(&s, &mut rx).await;
    s.lock().await.unwrap();
    for _ in 0..5 {
        assert!(s.unlock("000000".into()).await.is_err());
    }
    for result in [
        NativeOutcome::Cancelled,
        NativeOutcome::Rejected,
        NativeOutcome::Unavailable,
        NativeOutcome::LockedOut,
        NativeOutcome::Failed,
        NativeOutcome::Verified,
    ] {
        let copy = s.clone();
        let task = tokio::spawn(async move { copy.unlock_native().await });
        rx.recv().await.unwrap().send(result).unwrap();
        let result = task.await.unwrap();
        if result.is_ok() {
            s.lock().await.unwrap();
        }
        assert_eq!(s.status().await.unwrap().status, "locked");
        assert_eq!(
            s.unlock("123456".into()).await.unwrap_err().code,
            "rate_limited"
        );
    }
}
#[tokio::test]
async fn storage_failure_does_not_enable_and_pin_survives() {
    let (s, mut rx) = fixture().await;
    let writes = s.platform.secure.writes.load(Ordering::SeqCst);
    s.platform
        .secure
        .fail_at
        .store(writes + 1, Ordering::SeqCst);
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Verified)
        .unwrap();
    assert_eq!(task.await.unwrap().unwrap_err().code, "storage");
    assert!(!s.native_auth_status().await.unwrap().enabled);
    s.lock().await.unwrap();
    assert_eq!(s.unlock("123456".into()).await.unwrap().status, "unlocked");
}
#[tokio::test]
async fn auto_lock_during_enrollment_rejects_success() {
    let (s, mut rx) = fixture().await;
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    let pending = rx.recv().await.unwrap();
    s.platform.clock.advance(60_001);
    s.check_expiry();
    pending.send(NativeOutcome::Verified).unwrap();
    assert!(task.await.unwrap().is_err());
    assert!(!s.native_auth_status().await.unwrap().enabled);
}
#[tokio::test]
async fn removal_recreation_rejects_old_callback() {
    let (s, mut rx) = fixture().await;
    enable(&s, &mut rx).await;
    s.lock().await.unwrap();
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.unlock_native().await });
    let pending = rx.recv().await.unwrap();
    s.unlock("123456".into()).await.unwrap();
    s.remove_wallet("123456".into()).await.unwrap();
    s.import_wallet(PHRASE.into(), "654321".into())
        .await
        .unwrap();
    s.lock().await.unwrap();
    pending.send(NativeOutcome::Verified).unwrap();
    assert!(task.await.unwrap().is_err());
    assert_eq!(s.status().await.unwrap().status, "locked");
    assert!(!s.native_auth_status().await.unwrap().enabled);
}
#[tokio::test]
async fn disabling_invalidates_pending_enrollment() {
    let (s, mut rx) = fixture().await;
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    let pending = rx.recv().await.unwrap();
    assert!(
        !s.set_native_auth_enabled(false, "123456".into())
            .await
            .unwrap()
            .enabled
    );
    pending.send(NativeOutcome::Verified).unwrap();
    assert!(task.await.unwrap().is_err());
    assert!(!s.native_auth_status().await.unwrap().enabled);
}
#[tokio::test]
async fn dropped_caller_retains_prompt_slot_until_callback() {
    let (s, mut rx) = fixture().await;
    enable(&s, &mut rx).await;
    s.lock().await.unwrap();
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.unlock_native().await });
    let pending = rx.recv().await.unwrap();
    task.abort();
    let _ = task.await;
    assert_eq!(s.unlock_native().await.unwrap_err().code, "native_busy");
    pending.send(NativeOutcome::Verified).unwrap();
    // Join the detached verification worker indirectly via deterministic scheduling.
    for _ in 0..20 {
        tokio::task::yield_now().await;
    }
    assert_eq!(s.status().await.unwrap().status, "locked");
    assert!(s
        .native_attempt
        .lock()
        .unwrap()
        .begin(s.generation.load(Ordering::SeqCst))
        .is_ok());
}
struct SlowCapabilities {
    entered: Arc<tokio::sync::Notify>,
    release: Arc<tokio::sync::Notify>,
}
impl NativeAuthenticator for SlowCapabilities {
    fn capabilities(&self) -> BoxFuture<'_, NativeCapabilities> {
        Box::pin(async {
            self.entered.notify_one();
            self.release.notified().await;
            NativeCapabilities {
                kind: NativeKind::TouchId,
                availability: NativeAvailability::Available,
            }
        })
    }
    fn verify(&self, _: u64, _: String) -> BoxFuture<'_, NativeOutcome> {
        Box::pin(async { NativeOutcome::Verified })
    }
    fn cancel(&self, _: u64) {}
}
#[tokio::test]
async fn cancellation_during_capability_probe_prevents_unlock() {
    let p = platform();
    let entered = Arc::new(tokio::sync::Notify::new());
    let release = Arc::new(tokio::sync::Notify::new());
    let s = Arc::new(
        WalletSession::new(p.clone(), BackendDto::Esplora).with_native_authenticator(Arc::new(
            SlowCapabilities {
                entered: entered.clone(),
                release: release.clone(),
            },
        )),
    );
    s.import_wallet(PHRASE.into(), "123456".into())
        .await
        .unwrap();
    p.secure
        .put("desktop/nativeAuth/v1", b"enabled-v1".to_vec())
        .await
        .unwrap();
    s.lock().await.unwrap();
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.unlock_native().await });
    entered.notified().await;
    s.cancel_native_auth().unwrap();
    release.notify_one();
    assert!(task.await.unwrap().is_err());
    assert_eq!(s.status().await.unwrap().status, "locked");
}
#[tokio::test]
async fn dropped_enrollment_and_failed_cleanup_cannot_enable_before_commit() {
    let (s, mut rx) = fixture().await;
    *s.platform.secure.pause_native_value.lock().unwrap() = Some(b"pending-v1".to_vec());
    *s.platform.secure.fail_delete.lock().unwrap() = Some("desktop/nativeAuth/v1".into());
    let copy = s.clone();
    let caller = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Verified)
        .unwrap();
    tokio::time::timeout(
        std::time::Duration::from_secs(2),
        s.platform.secure.entered.notified(),
    )
    .await
    .expect("enrollment must persist a disabled pending marker first");
    caller.abort();
    let _ = caller.await;
    let copy = s.clone();
    let locking = tokio::spawn(async move { copy.lock().await });
    while s.status().await.unwrap().status != "locked" {
        tokio::task::yield_now().await;
    }
    s.platform.secure.release.notify_one();
    locking.await.unwrap().unwrap();
    assert!(!s.native_auth_status().await.unwrap().enabled);
    assert_eq!(
        s.platform
            .secure
            .get("desktop/nativeAuth/v1")
            .await
            .unwrap(),
        Some(b"pending-v1".to_vec())
    );
    let restarted = WalletSession::new(s.platform.clone(), BackendDto::Esplora);
    assert!(!restarted.native_auth_status().await.unwrap().enabled);
}
#[tokio::test]
async fn final_enrollment_write_failure_leaves_durable_disabled_marker() {
    let (s, mut rx) = fixture().await;
    let writes = s.platform.secure.writes.load(Ordering::SeqCst);
    s.platform
        .secure
        .fail_at
        .store(writes + 2, Ordering::SeqCst);
    let copy = s.clone();
    let task = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Verified)
        .unwrap();
    assert!(task.await.unwrap().is_err());
    assert!(!s.native_auth_status().await.unwrap().enabled);
    assert_eq!(
        s.platform
            .secure
            .get("desktop/nativeAuth/v1")
            .await
            .unwrap(),
        Some(b"pending-v1".to_vec())
    );
}
#[tokio::test]
async fn accepted_commit_finishes_after_caller_disappears_and_lock() {
    let (s, mut rx) = fixture().await;
    *s.platform.secure.pause_native_value.lock().unwrap() = Some(b"enabled-v1".to_vec());
    let copy = s.clone();
    let caller = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Verified)
        .unwrap();
    s.platform.secure.entered.notified().await; // Authorization committed; final OS write suspended.
    caller.abort();
    let _ = caller.await;
    let copy = s.clone();
    let locking = tokio::spawn(async move { copy.lock().await });
    while s.status().await.unwrap().status != "locked" {
        tokio::task::yield_now().await;
    }
    s.platform.secure.release.notify_one();
    locking.await.unwrap().unwrap();
    assert!(s.native_auth_status().await.unwrap().enabled);
    assert_eq!(s.status().await.unwrap().status, "locked");
}
#[tokio::test]
async fn disable_serializes_behind_accepted_enrollment_write() {
    let (s, mut rx) = fixture().await;
    *s.platform.secure.pause_native_value.lock().unwrap() = Some(b"enabled-v1".to_vec());
    let copy = s.clone();
    let enabling = tokio::spawn(async move { copy.complete_native_auth_offer(true).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Verified)
        .unwrap();
    s.platform.secure.entered.notified().await;
    let copy = s.clone();
    let disabling =
        tokio::spawn(async move { copy.set_native_auth_enabled(false, "123456".into()).await });
    tokio::task::yield_now().await;
    s.platform.secure.release.notify_one();
    enabling.await.unwrap().unwrap();
    assert!(!disabling.await.unwrap().unwrap().enabled);
    assert!(!s.native_auth_status().await.unwrap().enabled);
}
#[tokio::test]
async fn redundant_enable_failure_preserves_existing_preference() {
    let (s, mut rx) = fixture().await;
    enable(&s, &mut rx).await;
    let copy = s.clone();
    let task =
        tokio::spawn(async move { copy.set_native_auth_enabled(true, "123456".into()).await });
    rx.recv()
        .await
        .unwrap()
        .send(NativeOutcome::Cancelled)
        .unwrap();
    assert!(task.await.unwrap().is_err());
    assert!(s.native_auth_status().await.unwrap().enabled);
}
