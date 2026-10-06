//! Conservative session elapsed time: monotonic progress plus wall-clock suspend
//! progress. A backward wall clock invalidates the session rather than extending it.
use std::time::Instant;
pub struct IdleClock {
    origin: Instant,
    wall_origin: u64,
    last_wall: u64,
}
impl IdleClock {
    pub fn new(wall_ms: u64) -> Self {
        Self {
            origin: Instant::now(),
            wall_origin: wall_ms,
            last_wall: wall_ms,
        }
    }
    pub fn elapsed_ms(&mut self, wall_ms: u64) -> Option<u64> {
        if wall_ms < self.last_wall {
            return None;
        }
        self.last_wall = wall_ms;
        Some(
            (self.origin.elapsed().as_millis().min(u64::MAX as u128) as u64)
                .max(wall_ms - self.wall_origin),
        )
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn suspend_and_rollback_do_not_extend_time() {
        let mut c = IdleClock::new(1_000);
        assert!(c.elapsed_ms(121_000).unwrap() >= 120_000);
        assert!(c.elapsed_ms(120_999).is_none());
    }
}
