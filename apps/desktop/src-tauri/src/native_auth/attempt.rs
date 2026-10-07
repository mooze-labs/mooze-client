//! Pure ownership and invalidation rules for a single native prompt.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Attempt {
    pub id: u64,
    pub generation: u32,
}
#[derive(Default)]
pub struct AttemptState {
    next: u64,
    active: Option<(Attempt, bool)>,
}
impl AttemptState {
    pub fn begin(&mut self, generation: u32) -> Result<Attempt, &'static str> {
        if self.active.is_some() {
            return Err("native_busy");
        }
        self.next = self.next.checked_add(1).ok_or("native_unavailable")?;
        let attempt = Attempt {
            id: self.next,
            generation,
        };
        self.active = Some((attempt, true));
        Ok(attempt)
    }
    pub fn invalidate(&mut self) -> Option<u64> {
        self.active.as_mut().map(|(attempt, valid)| {
            *valid = false;
            attempt.id
        })
    }
    pub fn accepts(&self, attempt: Attempt, generation: u32) -> bool {
        self.active == Some((attempt, true)) && attempt.generation == generation
    }
    pub fn finish(&mut self, id: u64) {
        if self.active.is_some_and(|(a, _)| a.id == id) {
            self.active = None;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn invalidated_attempt_is_never_accepted() {
        let mut state = AttemptState::default();
        let attempt = state.begin(7).unwrap();
        assert!(state.accepts(attempt, 7));
        assert_eq!(state.invalidate(), Some(attempt.id));
        assert!(!state.accepts(attempt, 7));
        assert!(state.begin(7).is_err());
        state.finish(attempt.id);
        assert!(state.begin(7).is_ok());
    }
    #[test]
    fn different_generation_is_rejected() {
        let mut state = AttemptState::default();
        let attempt = state.begin(7).unwrap();
        assert!(!state.accepts(attempt, 8));
    }
    #[test]
    fn duplicate_begin_is_busy() {
        let mut state = AttemptState::default();
        state.begin(1).unwrap();
        assert!(state.begin(1).is_err());
    }
    #[test]
    fn old_finish_does_not_clear_new_attempt() {
        let mut state = AttemptState::default();
        let first = state.begin(1).unwrap();
        state.finish(first.id);
        let next = state.begin(1).unwrap();
        state.finish(first.id);
        assert!(state.accepts(next, 1));
        assert!(state.begin(1).is_err());
    }
}
