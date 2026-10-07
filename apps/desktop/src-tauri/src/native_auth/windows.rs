use super::*;
use std::sync::{
    atomic::{AtomicU64, Ordering},
    Mutex,
};
use tauri::Manager;
use windows::{
    core::{factory, HSTRING},
    Security::Credentials::UI::{
        UserConsentVerificationResult as Verification, UserConsentVerifier,
        UserConsentVerifierAvailability as Availability,
    },
    Win32::System::WinRT::{
        IUserConsentVerifierInterop, RoInitialize, RoUninitialize, RO_INIT_MULTITHREADED,
    },
};
use windows_future::IAsyncOperation;

type Cancel = Box<dyn Fn() + Send + Sync>;
pub struct WindowsAuthenticator {
    app: tauri::AppHandle,
    cancellation: Arc<Mutex<Option<(u64, Cancel)>>>,
    cancelled_through: Arc<AtomicU64>,
}
impl WindowsAuthenticator {
    pub fn new(app: tauri::AppHandle) -> Self {
        Self {
            app,
            cancellation: Arc::new(Mutex::new(None)),
            cancelled_through: Arc::new(AtomicU64::new(0)),
        }
    }
}
struct Apartment;
impl Apartment {
    fn enter() -> windows::core::Result<Self> {
        unsafe {
            RoInitialize(RO_INIT_MULTITHREADED)?;
        }
        Ok(Self)
    }
}
impl Drop for Apartment {
    fn drop(&mut self) {
        unsafe {
            RoUninitialize();
        }
    }
}
fn outcome(value: Verification) -> NativeOutcome {
    match value {
        Verification::Verified => NativeOutcome::Verified,
        Verification::Canceled => NativeOutcome::Cancelled,
        Verification::RetriesExhausted => NativeOutcome::LockedOut,
        Verification::DeviceNotPresent
        | Verification::NotConfiguredForUser
        | Verification::DisabledByPolicy => NativeOutcome::Unavailable,
        _ => NativeOutcome::Failed,
    }
}
impl NativeAuthenticator for WindowsAuthenticator {
    fn capabilities(&self) -> BoxFuture<'_, NativeCapabilities> {
        Box::pin(async {
            let availability = tokio::task::spawn_blocking(|| {
                let Ok(_apartment) = Apartment::enter() else {
                    return NativeAvailability::Unavailable;
                };
                match UserConsentVerifier::CheckAvailabilityAsync().and_then(|op| op.join()) {
                    Ok(Availability::Available) => NativeAvailability::Available,
                    Ok(Availability::NotConfiguredForUser) => NativeAvailability::NotEnrolled,
                    _ => NativeAvailability::Unavailable,
                }
            })
            .await
            .unwrap_or(NativeAvailability::Unavailable);
            NativeCapabilities {
                kind: NativeKind::WindowsHello,
                availability,
            }
        })
    }
    fn verify(&self, id: u64, reason: String) -> BoxFuture<'_, NativeOutcome> {
        let app = self.app.clone();
        let cancellation = self.cancellation.clone();
        let cancelled = self.cancelled_through.clone();
        Box::pin(async move {
            tokio::task::spawn_blocking(move || {
                let Ok(_apartment) = Apartment::enter() else {
                    return NativeOutcome::Unavailable;
                };
                let result = (|| -> windows::core::Result<NativeOutcome> {
                    if cancelled.load(Ordering::SeqCst) >= id {
                        return Ok(NativeOutcome::Cancelled);
                    }
                    let Some(window) = app.get_webview_window("main") else {
                        return Ok(NativeOutcome::Unavailable);
                    };
                    let Ok(hwnd) = window.hwnd() else {
                        return Ok(NativeOutcome::Unavailable);
                    };
                    let interop = factory::<UserConsentVerifier, IUserConsentVerifierInterop>()?;
                    let operation: IAsyncOperation<Verification> = unsafe {
                        interop.RequestVerificationForWindowAsync(hwnd, &HSTRING::from(reason))?
                    };
                    {
                        let mut slot = cancellation.lock().unwrap();
                        let op = operation.clone();
                        *slot = Some((
                            id,
                            Box::new(move || {
                                let _ = op.Cancel();
                            }),
                        ));
                        if cancelled.load(Ordering::SeqCst) >= id {
                            let _ = operation.Cancel();
                        }
                    }
                    let result = operation.join().map(outcome);
                    cancellation.lock().unwrap().take();
                    result
                })();
                result.unwrap_or(NativeOutcome::Unavailable)
            })
            .await
            .unwrap_or(NativeOutcome::Failed)
        })
    }
    fn cancel(&self, id: u64) {
        self.cancelled_through.fetch_max(id, Ordering::SeqCst);
        if let Some((active, cancel)) = self.cancellation.lock().unwrap().as_ref() {
            if *active == id {
                cancel();
            }
        }
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn only_verified_can_unlock() {
        assert_eq!(outcome(Verification::Verified), NativeOutcome::Verified);
        assert_eq!(outcome(Verification::Canceled), NativeOutcome::Cancelled);
        assert_eq!(
            outcome(Verification::RetriesExhausted),
            NativeOutcome::LockedOut
        );
        assert_eq!(
            outcome(Verification::DeviceNotPresent),
            NativeOutcome::Unavailable
        );
        assert_eq!(outcome(Verification(999)), NativeOutcome::Failed);
    }
}
