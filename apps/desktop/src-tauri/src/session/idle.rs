//! Pure foreground/background inactivity policy. Time is host-observed elapsed ms.
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn deadlines_do_not_extend_on_background_or_late_activity() {
        for minutes in [1, 5, 15, 30, 60] {
            let state = IdleState::new(minutes, 0).unwrap();
            assert!(!state.expired(minutes as u64 * 60_000 - 1));
            assert!(state.expired(minutes as u64 * 60_000));
        }
        let mut state = IdleState::new(1, 0).unwrap();
        assert!(state.background(50_000));
        assert!(state.expired(60_000));
        assert!(!state.activity(60_000));
    }
    #[test]
    fn foreground_return_is_not_activity_and_shorter_interval_applies() {
        let mut state = IdleState::new(5, 0).unwrap();
        state.background(10_000);
        assert!(state.foreground(20_000));
        assert!(state.expired(300_000));
        let mut state = IdleState::new(5, 0).unwrap();
        assert!(!state.set_interval(1, 70_000).unwrap());
        assert!(IdleState::new(2, 0).is_none());
    }
    #[test]
    fn background_input_cannot_extend_idle_deadline() {
        let mut state = IdleState::new(1, 0).unwrap();
        state.background(20_000);
        assert!(!state.activity(30_000));
        assert!(state.expired(60_000));
    }
}
#[derive(Clone, Debug)]
pub struct IdleState {
    interval_ms: u64,
    last_activity: u64,
    foreground: bool,
}
impl IdleState {
    pub fn new(minutes: u16, now: u64) -> Option<Self> {
        [1, 5, 15, 30, 60].contains(&minutes).then_some(Self {
            interval_ms: minutes as u64 * 60_000,
            last_activity: now,
            foreground: true,
        })
    }
    pub fn expired(&self, now: u64) -> bool {
        now < self.last_activity || now.saturating_sub(self.last_activity) >= self.interval_ms
    }
    pub fn activity(&mut self, now: u64) -> bool {
        if self.expired(now) || !self.foreground {
            return false;
        }
        self.last_activity = now;
        true
    }
    pub fn background(&mut self, now: u64) -> bool {
        self.foreground = false;
        !self.expired(now)
    }
    pub fn foreground(&mut self, now: u64) -> bool {
        self.foreground = true;
        !self.expired(now)
    }
    pub fn set_interval(&mut self, minutes: u16, now: u64) -> Option<bool> {
        if ![1, 5, 15, 30, 60].contains(&minutes) {
            return None;
        }
        self.interval_ms = minutes as u64 * 60_000;
        Some(!self.expired(now))
    }
}
