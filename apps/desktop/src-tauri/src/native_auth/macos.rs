use super::*;
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn only_native_success_is_verified() {
        assert_eq!(outcome(true, None), NativeOutcome::Verified);
        assert_eq!(outcome(false, None), NativeOutcome::Failed);
        assert_eq!(outcome(false, Some(-1)), NativeOutcome::Rejected);
        assert_eq!(outcome(false, Some(-999)), NativeOutcome::Failed);
    }
    #[test]
    fn cancel_is_not_failure_or_success() {
        for code in [-2, -3, -4, -9] {
            assert_eq!(outcome(false, Some(code)), NativeOutcome::Cancelled);
        }
    }
    #[test]
    fn unavailable_after_probe_is_unavailable() {
        assert_eq!(outcome(false, Some(-6)), NativeOutcome::Unavailable);
        assert_eq!(outcome(false, Some(-7)), NativeOutcome::Unavailable);
        assert_eq!(outcome(false, Some(-8)), NativeOutcome::LockedOut);
    }
}
use block2::RcBlock;
use objc2::{rc::Retained, runtime::Bool};
use objc2_foundation::{NSError, NSString};
use objc2_local_authentication::{LAContext, LAPolicy};
use std::{
    cell::RefCell,
    sync::atomic::{AtomicU64, Ordering},
};
use tokio::sync::oneshot;

// Only accessed through AppHandle::run_on_main_thread; no ObjC object crosses threads.
thread_local! { static CONTEXT: RefCell<Option<(u64, Retained<LAContext>)>> = const { RefCell::new(None) }; }
pub struct MacAuthenticator {
    app: tauri::AppHandle,
    cancelled_through: Arc<AtomicU64>,
}
impl MacAuthenticator {
    pub fn new(app: tauri::AppHandle) -> Self {
        Self {
            app,
            cancelled_through: Arc::new(AtomicU64::new(0)),
        }
    }
}
fn outcome(success: bool, error: Option<isize>) -> NativeOutcome {
    if success && error.is_none() {
        return NativeOutcome::Verified;
    }
    match error {
        Some(-2 | -3 | -4 | -9) => NativeOutcome::Cancelled,
        Some(-1) => NativeOutcome::Rejected,
        Some(-5 | -6 | -7) => NativeOutcome::Unavailable,
        Some(-8) => NativeOutcome::LockedOut,
        _ => NativeOutcome::Failed,
    }
}
impl NativeAuthenticator for MacAuthenticator {
    fn capabilities(&self) -> BoxFuture<'_, NativeCapabilities> {
        Box::pin(async move {
            let (tx, rx) = oneshot::channel();
            let _ = self.app.run_on_main_thread(move || {
                // SAFETY: fresh context used only on the main thread.
                let available = unsafe {
                    LAContext::new()
                        .canEvaluatePolicy_error(LAPolicy::DeviceOwnerAuthenticationWithBiometrics)
                };
                let availability = match available {
                    Ok(()) => NativeAvailability::Available,
                    Err(e) => match e.code() {
                        -7 => NativeAvailability::NotEnrolled,
                        -8 => NativeAvailability::LockedOut,
                        _ => NativeAvailability::Unavailable,
                    },
                };
                let _ = tx.send(availability);
            });
            NativeCapabilities {
                kind: NativeKind::TouchId,
                availability: rx.await.unwrap_or(NativeAvailability::Unavailable),
            }
        })
    }
    fn verify(&self, id: u64, reason: String) -> BoxFuture<'_, NativeOutcome> {
        Box::pin(async move {
            let (tx, rx) = oneshot::channel();
            let app = self.app.clone();
            let cancelled = self.cancelled_through.clone();
            let _ = self.app.run_on_main_thread(move || {
                if cancelled.load(Ordering::SeqCst) >= id {
                    let _ = tx.send(NativeOutcome::Cancelled);
                    return;
                }
                // SAFETY: context is retained in main-thread local storage until callback cleanup.
                unsafe {
                    let context = LAContext::new();
                    if let Err(e) = context
                        .canEvaluatePolicy_error(LAPolicy::DeviceOwnerAuthenticationWithBiometrics)
                    {
                        let _ = tx.send(outcome(false, Some(e.code())));
                        return;
                    }
                    context.setLocalizedFallbackTitle(Some(&NSString::from_str("")));
                    let sender = std::sync::Mutex::new(Some(tx));
                    let callback = RcBlock::new(move |success: Bool, error: *mut NSError| {
                        // Apple supplies a valid NSError pointer for this callback only.
                        let code = error.as_ref().map(|e| e.code());
                        let result = outcome(success.as_bool(), code);
                        let sender = sender.lock().unwrap().take();
                        let _ = app.run_on_main_thread(move || {
                            CONTEXT.with(|slot| {
                                if slot
                                    .borrow()
                                    .as_ref()
                                    .is_some_and(|(active, _)| *active == id)
                                {
                                    slot.borrow_mut().take();
                                }
                            });
                            if let Some(tx) = sender {
                                let _ = tx.send(result);
                            }
                        });
                    });
                    CONTEXT.with(|slot| *slot.borrow_mut() = Some((id, context.clone())));
                    context.evaluatePolicy_localizedReason_reply(
                        LAPolicy::DeviceOwnerAuthenticationWithBiometrics,
                        &NSString::from_str(&reason),
                        &callback,
                    );
                }
            });
            rx.await.unwrap_or(NativeOutcome::Failed)
        })
    }
    fn cancel(&self, id: u64) {
        self.cancelled_through.fetch_max(id, Ordering::SeqCst);
        let _ = self.app.run_on_main_thread(move || {
            CONTEXT.with(|slot| {
                if let Some((active, context)) = slot.borrow().as_ref() {
                    if *active == id {
                        unsafe {
                            context.invalidate();
                        }
                    }
                }
            });
        });
    }
}
