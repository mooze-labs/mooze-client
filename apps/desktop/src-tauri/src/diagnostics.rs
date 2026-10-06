#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn report_never_serializes_provider_text_or_wallet_identifiers() {
        let states = vec![crate::dto::ChainStateDto {
            chain: crate::dto::WalletChain::Liquid,
            phase: "error".into(),
            last_success_at_ms: Some(100),
            error: Some("secret mnemonic tlq-address txid custom-provider".into()),
        }];
        let text = serde_json::to_string(&report(&states)).unwrap();
        for private in [
            "secret",
            "mnemonic",
            "tlq-address",
            "txid",
            "custom-provider",
        ] {
            assert!(!text.contains(private));
        }
        assert!(text.contains("sync_failed"));
    }
}

/// Deliberate allowlist: never serialize the host snapshot or provider error.
pub fn report(chains: &[crate::dto::ChainStateDto]) -> serde_json::Value {
    serde_json::json!({"schema_version":1,"app_version":env!("CARGO_PKG_VERSION"),"platform":std::env::consts::OS,"architecture":std::env::consts::ARCH,"network":"testnet","chains":chains.iter().map(|state|serde_json::json!({"chain":state.chain,"phase":match state.phase.as_str(){"ready"=>"ready","error"=>"error",_=>"syncing"},"last_success_at_ms":state.last_success_at_ms,"error_code":state.error.as_ref().map(|_|"sync_failed")})).collect::<Vec<_>>()})
}
impl<P: mooze_app::Platform + Clone> crate::session::WalletSession<P> {
    pub async fn diagnostics(&self) -> crate::error::Result<serde_json::Value> {
        let snapshot = self.snapshot().await?;
        Ok(report(&snapshot.chains))
    }
}
