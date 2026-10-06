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
        let indices = vec![0, words.len() as u32 / 2, words.len() as u32 - 1];
        let result = SetupDto {
            setup_id: id.clone(),
            words: words.clone(),
            challenge_indices: indices.clone(),
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
            if candidate.id != id
                || candidate.created.elapsed() >= std::time::Duration::from_secs(600)
            {
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
            let phrase = candidate.words.join(" ");
            *guard = None;
            phrase
        };
        self.import_wallet(phrase, pin).await
    }
}
