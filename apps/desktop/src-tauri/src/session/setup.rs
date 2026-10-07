use super::*;
pub(super) struct SetupCandidate {
    id: String,
    words: Vec<String>,
    indices: Vec<u32>,
    created: std::time::Instant,
}
impl<P: Platform + Clone> WalletSession<P> {
    pub async fn begin_setup(&self, extended: bool) -> Result<SetupDto> {
        let _inner = self.inner.lock().await;
        if self.platform.kv().get(REMOVAL).await?.is_some() {
            return Err(DesktopError::new(
                "removal_pending",
                "Conclua a remoção local antes de continuar.",
            ));
        }
        if self.platform.kv().get(IMPORT).await? == Some(b"complete".to_vec()) {
            return Err(DesktopError::new(
                "invalid_input",
                "Uma carteira já existe.",
            ));
        }
        let words: Vec<String> = mnemonic::generate(extended)
            .split_whitespace()
            .map(str::to_owned)
            .collect();
        let id = uuid::Uuid::new_v4().to_string();
        // Random ordering samples distinct positions without excluding repeated words.
        let mut positions: Vec<_> = (0..words.len() as u32)
            .map(|index| (uuid::Uuid::new_v4(), index))
            .collect();
        positions.sort_unstable();
        let mut indices: Vec<_> = positions
            .into_iter()
            .take(3)
            .map(|(_, index)| index)
            .collect();
        indices.sort_unstable();
        let result = SetupDto {
            setup_id: id.clone(),
            words: words.clone(),
            challenge_indices: indices.clone(),
            expires_at_ms: self.platform.clock().now_ms().saturating_add(600_000),
        };
        *self.setup.lock().unwrap() = Some(SetupCandidate {
            id,
            words,
            indices,
            created: std::time::Instant::now(),
        });
        Ok(result)
    }
    pub fn cancel_setup(&self, id: String) -> Result<()> {
        let mut candidate = self.setup.lock().unwrap();
        if candidate.as_ref().is_some_and(|c| c.id == id) {
            *candidate = None;
        }
        Ok(())
    }
    pub async fn complete_setup(
        &self,
        id: String,
        answers: Vec<String>,
        pin: String,
    ) -> Result<SessionDto> {
        if !rules::valid_pin(&pin) {
            return Err(DesktopError::new(
                "invalid_input",
                "Use um PIN de 6 dígitos.",
            ));
        }
        let phrase = {
            let mut guard = self.setup.lock().unwrap();
            let candidate = guard
                .as_ref()
                .ok_or_else(|| DesktopError::new("setup_expired", "Crie uma nova frase."))?;
            if candidate.id != id {
                return Err(DesktopError::new("setup_expired", "Crie uma nova frase."));
            }
            if candidate.created.elapsed() >= std::time::Duration::from_secs(600) {
                *guard = None;
                return Err(DesktopError::new("setup_expired", "Crie uma nova frase."));
            }
            if answers.len() != candidate.indices.len()
                || candidate
                    .indices
                    .iter()
                    .zip(&answers)
                    .any(|(i, a)| candidate.words[*i as usize] != a.trim())
            {
                return Err(DesktopError::new(
                    "invalid_input",
                    "Confira as palavras da recuperação.",
                ));
            }
            candidate.words.join(" ")
        };
        let result = self.import_wallet(phrase, pin).await;
        // Keep the same backup usable after a pre-commit failure. A saved wallet
        // must instead be unlocked; never overwrite it on a setup retry.
        let committed = self
            .platform
            .kv()
            .get(IMPORT)
            .await
            .is_ok_and(|value| value == Some(b"complete".to_vec()));
        if result.is_ok() || committed {
            self.cancel_setup(id)?;
        }
        result
    }
}
