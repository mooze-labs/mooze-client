//! App lock decisions: lock timeout, resume lock, privacy shield and overlay.

/// Grace period before a backgrounded app must re-authenticate.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SessionLockTimeout {
    /// Lock on any real backgrounding.
    Immediate,
    /// 15 seconds.
    Seconds15,
    /// 30 seconds.
    Seconds30,
    /// 1 minute.
    Minute1,
    /// 5 minutes.
    Minutes5,
}

impl SessionLockTimeout {
    /// Preferences key of the selected timeout.
    pub const PREFS_KEY: &'static str = "sessionLockTimeout";
    /// Value when the user never chose.
    pub const DEFAULT: SessionLockTimeout = SessionLockTimeout::Immediate;
    /// Every value, in display order.
    pub const ALL: [SessionLockTimeout; 5] = [
        SessionLockTimeout::Immediate,
        SessionLockTimeout::Seconds15,
        SessionLockTimeout::Seconds30,
        SessionLockTimeout::Minute1,
        SessionLockTimeout::Minutes5,
    ];

    /// Duration in milliseconds.
    pub fn duration_ms(self) -> u64 {
        match self {
            SessionLockTimeout::Immediate => 0,
            SessionLockTimeout::Seconds15 => 15_000,
            SessionLockTimeout::Seconds30 => 30_000,
            SessionLockTimeout::Minute1 => 60_000,
            SessionLockTimeout::Minutes5 => 300_000,
        }
    }

    /// Stable persisted token.
    pub fn storage_value(self) -> &'static str {
        match self {
            SessionLockTimeout::Immediate => "immediate",
            SessionLockTimeout::Seconds15 => "seconds15",
            SessionLockTimeout::Seconds30 => "seconds30",
            SessionLockTimeout::Minute1 => "minute1",
            SessionLockTimeout::Minutes5 => "minutes5",
        }
    }

    /// Parses a persisted token. Unknown or absent values give [`Self::DEFAULT`].
    pub fn from_storage(value: Option<&str>) -> Self {
        Self::ALL.into_iter().find(|t| Some(t.storage_value()) == value).unwrap_or(Self::DEFAULT)
    }
}

/// Whether the app owes an authentication right now.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SessionLockState {
    /// No authentication owed.
    #[default]
    Unlocked,
    /// A PIN or biometric challenge is required.
    Locked,
}

/// Decides whether a resume requires re-authentication.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SessionLockController {
    state: SessionLockState,
    backgrounded_at_ms: Option<u64>,
}

impl SessionLockController {
    /// Unlocked controller.
    pub fn new() -> Self {
        Self::default()
    }

    /// Current state.
    pub fn state(&self) -> SessionLockState {
        self.state
    }

    /// Records a real backgrounding (`paused`/`hidden`).
    /// Ignored when the lock is off, already locked, or an auth prompt is up.
    pub fn on_backgrounded(&mut self, now_ms: u64, lock_enabled: bool, auth_prompt_active: bool) {
        if !lock_enabled || self.state == SessionLockState::Locked || auth_prompt_active {
            return;
        }
        self.backgrounded_at_ms = Some(now_ms);
    }

    /// Resolves the lock on resume and returns the new state.
    pub fn on_resumed(
        &mut self,
        now_ms: u64,
        lock_enabled: bool,
        merchant_mode: bool,
        timeout: SessionLockTimeout,
    ) -> SessionLockState {
        let backgrounded_at = self.backgrounded_at_ms.take();
        if self.state == SessionLockState::Locked {
            return self.state;
        }
        self.state = match backgrounded_at {
            Some(at) if lock_enabled && !merchant_mode => {
                if now_ms as i64 - at as i64 >= timeout.duration_ms() as i64 {
                    SessionLockState::Locked
                } else {
                    SessionLockState::Unlocked
                }
            }
            _ => SessionLockState::Unlocked,
        };
        self.state
    }

    /// Clears the lock after a successful PIN/biometric check.
    pub fn unlock(&mut self) {
        self.state = SessionLockState::Unlocked;
    }
}

/// App-switcher privacy cover.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum PrivacyShieldState {
    /// App visible.
    #[default]
    Hidden,
    /// Opaque cover up.
    Visible,
}

/// Shield state when the app starts leaving the foreground.
pub fn privacy_shield_on_leaving_foreground(
    current: PrivacyShieldState,
    auth_prompt_active: bool,
    privacy_shield_enabled: bool,
    session_lock_enabled: bool,
) -> PrivacyShieldState {
    if auth_prompt_active {
        return current;
    }
    if privacy_shield_enabled || session_lock_enabled {
        PrivacyShieldState::Visible
    } else {
        current
    }
}

/// What the global overlay paints.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LockOverlay {
    /// Show an opaque cover.
    pub show_cover: bool,
    /// Show the authentication UI.
    pub show_authentication: bool,
}

pub fn resolve_lock_overlay(privacy_shield_visible: bool, session_locked: bool) -> LockOverlay {
    LockOverlay { show_cover: privacy_shield_visible || session_locked, show_authentication: session_locked }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn timeout_storage() {
        assert_eq!(SessionLockTimeout::from_storage(Some("minute1")), SessionLockTimeout::Minute1);
        assert_eq!(SessionLockTimeout::from_storage(Some("bogus")), SessionLockTimeout::Immediate);
        assert_eq!(SessionLockTimeout::from_storage(None), SessionLockTimeout::Immediate);
    }

    #[test]
    fn lock_after_timeout() {
        let mut c = SessionLockController::new();
        c.on_backgrounded(1_000, true, false);
        assert_eq!(c.on_resumed(10_000, true, false, SessionLockTimeout::Seconds15), SessionLockState::Unlocked);
        c.on_backgrounded(1_000, true, false);
        assert_eq!(c.on_resumed(16_000, true, false, SessionLockTimeout::Seconds15), SessionLockState::Locked);
        // Stays locked until unlock.
        assert_eq!(c.on_resumed(16_000, true, false, SessionLockTimeout::Seconds15), SessionLockState::Locked);
        c.unlock();
        assert_eq!(c.state(), SessionLockState::Unlocked);
    }

    #[test]
    fn lock_bypasses() {
        let mut c = SessionLockController::new();
        c.on_backgrounded(0, true, true); // auth prompt: ignored
        assert_eq!(c.on_resumed(99_000, true, false, SessionLockTimeout::Immediate), SessionLockState::Unlocked);
        c.on_backgrounded(0, true, false);
        assert_eq!(c.on_resumed(99_000, true, true, SessionLockTimeout::Immediate), SessionLockState::Unlocked);
        c.on_backgrounded(0, true, false);
        assert_eq!(c.on_resumed(0, true, false, SessionLockTimeout::Immediate), SessionLockState::Locked);
    }

    #[test]
    fn shield_and_overlay() {
        use PrivacyShieldState::*;
        assert_eq!(privacy_shield_on_leaving_foreground(Hidden, false, false, true), Visible);
        assert_eq!(privacy_shield_on_leaving_foreground(Hidden, true, true, true), Hidden);
        assert_eq!(privacy_shield_on_leaving_foreground(Hidden, false, false, false), Hidden);
        assert_eq!(resolve_lock_overlay(true, false), LockOverlay { show_cover: true, show_authentication: false });
        assert_eq!(resolve_lock_overlay(false, true), LockOverlay { show_cover: true, show_authentication: true });
    }
}
