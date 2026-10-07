use crate::{dto::*, error::Result, platform::NativePlatform, session::WalletSession};
use mooze_app::dto::{BroadcastResultDto, ReceiveAddressDto};
use mooze_core::{domain::ChainId, wallet::backend::default_electrum_urls};
type State<'a> = tauri::State<'a, std::sync::Arc<WalletSession<NativePlatform>>>;
#[tauri::command]
pub fn host_info() -> HostInfoDto {
    HostInfoDto {
        pix_enabled: crate::network::production_services_enabled(),
        swaps_enabled: crate::network::production_services_enabled()
            && crate::session::backend::ServiceConfig::from_env()
                .sideswap_api_key
                .is_some(),
        network: crate::network::name().into(),
        backend: "Electrum".into(),
        liquid_policy_asset: crate::network::policy_asset().into(),
        bitcoin_endpoints: default_electrum_urls(ChainId::Bitcoin, crate::network::app_network()),
        liquid_endpoints: default_electrum_urls(ChainId::Liquid, crate::network::app_network()),
    }
}
#[tauri::command]
pub async fn session_status(state: State<'_>) -> Result<SessionDto> {
    state.status().await
}
#[tauri::command]
pub async fn import_wallet(state: State<'_>, mnemonic: String, pin: String) -> Result<SessionDto> {
    state.import_wallet(mnemonic, pin).await
}
#[tauri::command]
pub async fn unlock(state: State<'_>, pin: String) -> Result<SessionDto> {
    state.unlock(pin).await
}
#[tauri::command]
pub async fn lock(state: State<'_>) -> Result<SessionDto> {
    state.lock().await
}
#[tauri::command]
pub async fn snapshot(state: State<'_>) -> Result<DesktopSnapshotDto> {
    state.snapshot().await
}
#[tauri::command]
pub async fn refresh(state: State<'_>) -> Result<()> {
    state.refresh().await
}
#[tauri::command]
pub async fn receive_address(state: State<'_>, chain: WalletChain) -> Result<ReceiveAddressDto> {
    state.receive(chain).await
}
#[tauri::command]
pub async fn review_send(state: State<'_>, request: ReviewRequestDto) -> Result<SendReviewDto> {
    state.review(request).await
}
#[tauri::command]
pub async fn confirm_send(state: State<'_>, review_id: String) -> Result<BroadcastResultDto> {
    state.confirm(review_id).await
}

#[tauri::command]
pub async fn acknowledge_submission(state: State<'_>) -> Result<()> {
    state.acknowledge_submission().await
}

#[tauri::command]
pub async fn holdings(state: State<'_>) -> Result<HoldingsSnapshotDto> {
    state.holdings().await
}
#[tauri::command]
pub fn approved_assets(state: State<'_>) -> Result<Vec<mooze_app::dto::AssetMetadataDto>> {
    state.approved_assets()
}

#[tauri::command]
pub fn record_activity(window: tauri::Window, state: State<'_>, generation: u32) -> Result<()> {
    if !window.is_focused().unwrap_or(false) {
        return Ok(());
    }
    state.record_activity(generation)
}
#[tauri::command]
pub async fn settings(state: State<'_>) -> Result<DesktopSettingsDto> {
    state.settings().await
}
#[tauri::command]
pub async fn set_lock_minutes(state: State<'_>, minutes: u16) -> Result<DesktopSettingsDto> {
    state.set_lock_minutes(minutes).await
}

#[tauri::command]
pub async fn begin_setup(state: State<'_>, extended: bool) -> Result<SetupDto> {
    state.begin_setup(extended).await
}
#[tauri::command]
pub fn cancel_setup(state: State<'_>, setup_id: String) -> Result<()> {
    state.cancel_setup(setup_id)
}
#[tauri::command]
pub async fn complete_setup(
    state: State<'_>,
    setup_id: String,
    answers: Vec<String>,
    pin: String,
) -> Result<SessionDto> {
    state.complete_setup(setup_id, answers, pin).await
}
#[tauri::command]
pub async fn reveal_recovery_phrase(state: State<'_>, pin: String) -> Result<Vec<String>> {
    state.reveal_recovery_phrase(pin).await
}
#[tauri::command]
pub async fn change_pin(state: State<'_>, current_pin: String, new_pin: String) -> Result<()> {
    state.change_pin(current_pin, new_pin).await
}

#[tauri::command]
pub fn parse_payment_request(state: State<'_>, input: String) -> Result<ParsedPaymentDto> {
    state.parse_payment(input)
}
#[tauri::command]
pub async fn receive_request(
    state: State<'_>,
    asset: mooze_app::dto::AssetKeyDto,
    amount_units: Option<String>,
    description: Option<String>,
) -> Result<ReceiveRequestDto> {
    state
        .receive_request(asset, amount_units, description)
        .await
}
#[tauri::command]
pub async fn fee_options(
    state: State<'_>,
    asset: mooze_app::dto::AssetKeyDto,
) -> Result<FeeOptionsDto> {
    state.fee_options(asset).await
}
#[tauri::command]
pub async fn save_display(
    state: State<'_>,
    locale: String,
    bitcoin_unit: String,
    privacy: bool,
) -> Result<DesktopSettingsDto> {
    state.save_display(locale, bitcoin_unit, privacy).await
}
#[tauri::command]
pub async fn test_node(state: State<'_>, chain: WalletChain, endpoint: String) -> Result<String> {
    state.test_node(chain, endpoint).await
}
#[tauri::command]
pub async fn save_node(
    state: State<'_>,
    chain: WalletChain,
    endpoint: Option<String>,
    public_fallback: bool,
) -> Result<DesktopSettingsDto> {
    state.save_node(chain, endpoint, public_fallback).await
}
#[tauri::command]
pub async fn remove_wallet(state: State<'_>, pin: String) -> Result<()> {
    state.remove_wallet(pin).await
}
#[tauri::command]
pub async fn diagnostics(state: State<'_>) -> Result<serde_json::Value> {
    state.diagnostics().await
}

#[tauri::command]
pub async fn export_diagnostics(app: tauri::AppHandle, state: State<'_>) -> Result<bool> {
    use tauri_plugin_dialog::DialogExt;
    state.diagnostics().await?;
    let (send, receive) = tokio::sync::oneshot::channel();
    app.dialog()
        .file()
        .add_filter("JSON", &["json"])
        .set_file_name("mooze-diagnostics.json")
        .save_file(move |path| {
            let _ = send.send(path);
        });
    let selected = receive.await.map_err(|_| {
        crate::error::DesktopError::new(
            "export_failed",
            "Não foi possível abrir o diálogo de exportação.",
        )
    })?;
    let Some(selected) = selected else {
        return Ok(false);
    };
    let path = selected
        .into_path()
        .map_err(|_| crate::error::DesktopError::new("export_failed", "Destino inválido."))?;
    let report = state.diagnostics().await?;
    tokio::task::spawn_blocking(move || {
        std::fs::write(
            path,
            serde_json::to_vec_pretty(&report).expect("JSON report"),
        )
    })
    .await
    .map_err(|_| {
        crate::error::DesktopError::new("export_failed", "Não foi possível exportar o diagnóstico.")
    })?
    .map_err(|_| {
        crate::error::DesktopError::new(
            "export_failed",
            "Não foi possível gravar no destino selecionado.",
        )
    })?;
    Ok(true)
}

#[cfg(test)]
mod network_tests {
    #[test]
    fn build_reports_selected_network_and_policy() {
        let host = super::host_info();
        if cfg!(feature = "testnet") {
            assert_eq!(host.network, "Testnet");
        } else {
            assert_eq!(host.network, "Mainnet");
            assert_eq!(host.liquid_policy_asset, mooze_core::domain::LBTC_ASSET_ID);
        }
    }
}

#[tauri::command]
pub async fn backend_status(state: State<'_>) -> Result<BackendSessionDto> {
    state.backend_status().await
}

#[tauri::command]
pub async fn backend_retry(state: State<'_>) -> Result<BackendSessionDto> {
    state.backend_retry().await
}

#[tauri::command]
pub async fn pix_history(state: State<'_>) -> Result<PixHistoryDto> {
    state.pix_history().await
}

#[tauri::command]
pub async fn pix_create(
    state: State<'_>,
    request: PixCreateRequestDto,
) -> Result<PixDepositViewDto> {
    state.pix_create(request).await
}

#[tauri::command]
pub async fn pix_acknowledge_uncertain(state: State<'_>) -> Result<()> {
    state.pix_acknowledge_uncertain().await
}

#[tauri::command]
pub async fn swap_markets(state: State<'_>) -> Result<Vec<mooze_app::dto::SideswapMarketDto>> {
    state.swap_markets().await
}

#[tauri::command]
pub async fn swap_start(state: State<'_>, request: SwapRequestDto) -> Result<SwapStateDto> {
    state.swap_start(request).await
}

#[tauri::command]
pub async fn swap_status(state: State<'_>) -> Result<SwapStateDto> {
    state.swap_status().await
}

#[tauri::command]
pub async fn swap_stop(state: State<'_>) -> Result<()> {
    state.swap_stop().await
}

#[tauri::command]
pub async fn swap_confirm(state: State<'_>, review_id: String) -> Result<SwapStateDto> {
    state.swap_confirm(review_id).await
}

#[tauri::command]
pub async fn swap_acknowledge(state: State<'_>) -> Result<()> {
    state.swap_acknowledge().await
}

#[tauri::command]
pub async fn account_level(state: State<'_>) -> Result<AccountLevelDto> {
    state.account_level().await
}
#[tauri::command]
pub async fn price_history(
    state: State<'_>,
    market: PriceMarketDto,
    currency: String,
    days: u32,
) -> Result<PriceHistoryDto> {
    state.price_history(market, currency, days).await
}

// Local-only input assistance: neither command persists or transmits the phrase.
#[tauri::command]
pub fn recovery_words() -> Vec<String> {
    mooze_core::wallet::mnemonic::english_words()
        .iter()
        .map(|word| (*word).to_owned())
        .collect()
}
#[tauri::command]
pub fn validate_recovery_phrase(phrase: String) -> Result<()> {
    use crate::error::DesktopError;
    use mooze_core::wallet::mnemonic;
    let normalized = mnemonic::normalize(&phrase).to_lowercase();
    let words: Vec<_> = normalized.split_whitespace().collect();
    if ![12, 15, 18, 21, 24].contains(&words.len()) {
        return Err(DesktopError::new(
            "invalid_word_count",
            "Use uma frase de 12, 15, 18, 21 ou 24 palavras.",
        ));
    }
    let invalid: Vec<_> = words
        .iter()
        .enumerate()
        .filter(|(_, word)| !mnemonic::english_words().contains(word))
        .map(|(index, _)| (index + 1).to_string())
        .collect();
    if !invalid.is_empty() {
        let mut error =
            DesktopError::new("invalid_recovery_words", "Confira as palavras indicadas.");
        error.details = Some(invalid.join(", "));
        return Err(error);
    }
    mnemonic::parse(&normalized).map(|_| ()).map_err(|_| {
        DesktopError::new(
            "invalid_checksum",
            "As palavras não formam uma frase válida. Confira a ordem e o conteúdo.",
        )
    })
}

#[cfg(test)]
mod recovery_tests {
    use super::*;
    #[test]
    fn validates_words_count_and_checksum_without_echoing_secrets() {
        assert_eq!(
            validate_recovery_phrase("abandon".into()).unwrap_err().code,
            "invalid_word_count"
        );
        assert_eq!(
            validate_recovery_phrase(vec!["abandon"; 12].join(" "))
                .unwrap_err()
                .code,
            "invalid_checksum"
        );
        let mut words = vec!["abandon"; 12];
        words[4] = "notaword";
        let error = validate_recovery_phrase(words.join(" ")).unwrap_err();
        assert_eq!(error.code, "invalid_recovery_words");
        assert_eq!(error.details.as_deref(), Some("5"));
        words[4] = "abandon";
        words[11] = "about";
        assert!(validate_recovery_phrase(words.join("\n").to_uppercase()).is_ok());
    }
}

#[tauri::command]
pub async fn native_auth_status(state: State<'_>) -> Result<crate::dto::NativeAuthStatusDto> {
    state.native_auth_status().await
}
#[tauri::command]
pub async fn unlock_native(state: State<'_>) -> Result<SessionDto> {
    state.unlock_native().await
}
#[tauri::command]
pub fn cancel_native_auth(state: State<'_>) -> Result<()> {
    state.cancel_native_auth()
}
#[tauri::command]
pub async fn set_native_auth_enabled(
    state: State<'_>,
    enabled: bool,
    pin: String,
) -> Result<crate::dto::NativeAuthStatusDto> {
    state.set_native_auth_enabled(enabled, pin).await
}
#[tauri::command]
pub async fn complete_native_auth_offer(
    state: State<'_>,
    enable: bool,
) -> Result<crate::dto::NativeAuthStatusDto> {
    state.complete_native_auth_offer(enable).await
}
