//! Reconnect and keepalive policy. Port of `lib/utils/websocket.dart`.
//!
//! The core never sleeps. The platform reads the delays and schedules.

/// Connection state, same names as `WebSocketConnectionState`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Connected,
    Reconnecting,
    /// Reconnect budget exhausted.
    Error,
}

/// Timing constants of `WebSocketService`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ReconnectPolicy {
    /// Handshake timeout.
    pub connect_timeout_ms: u64,
    /// First reconnect delay.
    pub initial_reconnect_delay_ms: u64,
    /// Delay cap.
    pub max_reconnect_delay_ms: u64,
    /// Attempts before the state becomes [`ConnectionState::Error`].
    pub max_reconnect_attempts: u32,
    /// Silence after which the connection counts as dead.
    pub idle_timeout_ms: u64,
    /// How often the platform checks for idleness.
    pub idle_check_interval_ms: u64,
}

impl Default for ReconnectPolicy {
    fn default() -> Self {
        Self {
            connect_timeout_ms: 10_000,
            initial_reconnect_delay_ms: 2_000,
            max_reconnect_delay_ms: 30_000,
            max_reconnect_attempts: 8,
            idle_timeout_ms: 90_000,
            idle_check_interval_ms: 30_000,
        }
    }
}

impl ReconnectPolicy {
    /// Backoff for 1-based `attempt`: `initial * 2^(attempt-1)`, capped.
    /// The shift is clamped to 0..=20, like Dart.
    pub fn backoff_delay_ms(&self, attempt: u32) -> u64 {
        let shift = attempt.saturating_sub(1).min(20);
        let exp = self.initial_reconnect_delay_ms.saturating_mul(1u64 << shift);
        exp.min(self.max_reconnect_delay_ms)
    }

    /// Delay before reconnect `attempt`, or `None` when the budget is spent.
    pub fn next_delay_ms(&self, attempt: u32) -> Option<u64> {
        (attempt >= 1 && attempt <= self.max_reconnect_attempts).then(|| self.backoff_delay_ms(attempt))
    }

    /// Ping/idle check interval.
    pub fn ping_interval_ms(&self) -> u64 {
        self.idle_check_interval_ms
    }

    /// True if no frame arrived for longer than the idle timeout.
    pub fn is_idle(&self, last_message_ms: u64, now_ms: u64) -> bool {
        now_ms.saturating_sub(last_message_ms) > self.idle_timeout_ms
    }
}

/// What the platform must do after a drop.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ReconnectAction {
    /// Reconnect after `delay_ms`.
    Retry { attempt: u32, delay_ms: u64 },
    /// Stop. State is [`ConnectionState::Error`].
    GiveUp,
}

/// Pure reconnect state machine of `WebSocketService`.
#[derive(Debug, Clone)]
pub struct ReconnectTracker {
    policy: ReconnectPolicy,
    attempt: u32,
    state: ConnectionState,
}

impl ReconnectTracker {
    /// New tracker in [`ConnectionState::Disconnected`].
    pub fn new(policy: ReconnectPolicy) -> Self {
        Self { policy, attempt: 0, state: ConnectionState::Disconnected }
    }

    /// Current state.
    pub fn state(&self) -> ConnectionState {
        self.state
    }

    /// Failed attempts since the last success.
    pub fn attempt(&self) -> u32 {
        self.attempt
    }

    /// Call before dialing. Returns `Connecting` or `Reconnecting`.
    pub fn on_connect_start(&mut self) -> ConnectionState {
        self.state = if self.attempt == 0 { ConnectionState::Connecting } else { ConnectionState::Reconnecting };
        self.state
    }

    /// Call after a successful handshake. Resets the budget.
    pub fn on_connected(&mut self) {
        self.attempt = 0;
        self.state = ConnectionState::Connected;
    }

    /// Call after a failed dial or a dropped connection.
    pub fn on_drop(&mut self) -> ReconnectAction {
        if self.attempt >= self.policy.max_reconnect_attempts {
            self.state = ConnectionState::Error;
            return ReconnectAction::GiveUp;
        }
        self.attempt += 1;
        self.state = ConnectionState::Reconnecting;
        ReconnectAction::Retry { attempt: self.attempt, delay_ms: self.policy.backoff_delay_ms(self.attempt) }
    }

    /// `ensureConnected`: a user retry after `Error` gets a fresh budget.
    pub fn on_ensure_connected(&mut self) {
        if self.state == ConnectionState::Error {
            self.attempt = 0;
        }
    }

    /// `forceReconnect`: resets the budget and the state.
    pub fn on_force_reconnect(&mut self) {
        self.attempt = 0;
        self.state = ConnectionState::Disconnected;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn backoff_doubles_and_caps() {
        let p = ReconnectPolicy::default();
        let d: Vec<u64> = (1..=6).map(|a| p.backoff_delay_ms(a)).collect();
        assert_eq!(d, vec![2000, 4000, 8000, 16000, 30000, 30000]);
        assert_eq!(p.backoff_delay_ms(500), 30000);
        assert_eq!(p.next_delay_ms(8), Some(30000));
        assert_eq!(p.next_delay_ms(9), None);
        assert!(p.is_idle(0, 90_001));
        assert!(!p.is_idle(0, 90_000));
    }

    #[test]
    fn tracker_gives_up_after_budget() {
        let mut t = ReconnectTracker::new(ReconnectPolicy::default());
        assert_eq!(t.on_connect_start(), ConnectionState::Connecting);
        for i in 1..=8 {
            assert!(matches!(t.on_drop(), ReconnectAction::Retry { attempt, .. } if attempt == i));
        }
        assert_eq!(t.on_drop(), ReconnectAction::GiveUp);
        assert_eq!(t.state(), ConnectionState::Error);
        t.on_ensure_connected();
        assert_eq!(t.attempt(), 0);
        t.on_connected();
        assert_eq!(t.state(), ConnectionState::Connected);
    }
}
