//! Push events from the facade to the host.
//!
//! A host registers an [`EventSink`] with `App::subscribe`. The runtime
//! and the SideSwap driver call [`Subscribers::emit`]. A sink that returns
//! false is dropped: the host side went away.

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Mutex;

use mooze_core::{MaybeSend, MaybeSync};
use serde::{Deserialize, Serialize};

use crate::dto::*;

/// One event. Serialized as `{"type": "...", "data": ...}`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "codegen", derive(ts_rs::TS))]
#[serde(tag = "type", content = "data", rename_all = "snake_case")]
pub enum AppEvent {
    SideSwap(SideSwapEventDto),
    Transactions(Vec<TransactionEventDto>),
    PixStatus(Vec<PixStatusEventDto>),
    SyncState(SyncStateDto),
    PegProgress(PegRefreshDto),
    SessionLock(SessionLockStateDto),
    AuthSession(AuthEnsureDto),
}

/// Receives events. Runs under the subscriber lock, so it must not call
/// `subscribe` or `unsubscribe` and must return fast.
pub trait EventSink: MaybeSend + MaybeSync {
    /// Delivers one event. False means the receiver is gone.
    fn send(&self, event: AppEvent) -> bool;
}

pub type SubscriptionId = u64;

/// Registered sinks of one `App`.
#[derive(Default)]
pub struct Subscribers {
    next_id: AtomicU64,
    sinks: Mutex<Vec<(SubscriptionId, Box<dyn EventSink>)>>,
}

impl Subscribers {
    pub fn subscribe(&self, sink: Box<dyn EventSink>) -> SubscriptionId {
        let id = self.next_id.fetch_add(1, Ordering::SeqCst) + 1;
        self.sinks.lock().unwrap_or_else(|e| e.into_inner()).push((id, sink));
        id
    }

    pub fn unsubscribe(&self, id: SubscriptionId) {
        self.sinks.lock().unwrap_or_else(|e| e.into_inner()).retain(|(i, _)| *i != id);
    }

    /// Sends `event` to every sink. Removes sinks that return false.
    /// Returns the number of sinks still registered.
    pub fn emit(&self, event: AppEvent) -> usize {
        let mut sinks = self.sinks.lock().unwrap_or_else(|e| e.into_inner());
        sinks.retain(|(_, s)| s.send(event.clone()));
        sinks.len()
    }

    pub fn len(&self) -> usize {
        self.sinks.lock().unwrap_or_else(|e| e.into_inner()).len()
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dto::SessionLockStateDto;
    use std::sync::atomic::{AtomicBool, Ordering};
    use std::sync::{Arc, Mutex};

    struct Collect(Arc<Mutex<Vec<AppEvent>>>, Arc<AtomicBool>);
    impl EventSink for Collect {
        fn send(&self, e: AppEvent) -> bool {
            self.0.lock().unwrap().push(e);
            self.1.load(Ordering::SeqCst)
        }
    }

    #[test]
    fn emit_reaches_live_sinks_and_drops_dead_ones() {
        let subs = Subscribers::default();
        let (a, alive_a) = (Arc::new(Mutex::new(vec![])), Arc::new(AtomicBool::new(true)));
        let (b, alive_b) = (Arc::new(Mutex::new(vec![])), Arc::new(AtomicBool::new(false)));
        let id_a = subs.subscribe(Box::new(Collect(a.clone(), alive_a)));
        subs.subscribe(Box::new(Collect(b.clone(), alive_b)));
        assert_eq!(subs.emit(AppEvent::SessionLock(SessionLockStateDto::Locked)), 1);
        assert_eq!(a.lock().unwrap().len(), 1);
        assert_eq!(b.lock().unwrap().len(), 1);
        assert_eq!(subs.emit(AppEvent::SessionLock(SessionLockStateDto::Unlocked)), 1);
        assert_eq!(b.lock().unwrap().len(), 1, "dead sink removed after first false");
        subs.unsubscribe(id_a);
        assert_eq!(subs.emit(AppEvent::SessionLock(SessionLockStateDto::Unlocked)), 0);
    }

    #[test]
    fn app_event_serializes_tagged() {
        let v = serde_json::to_value(AppEvent::SessionLock(SessionLockStateDto::Locked)).unwrap();
        assert_eq!(v, serde_json::json!({"type": "session_lock", "data": "Locked"}));
    }
}
