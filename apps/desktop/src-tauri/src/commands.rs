use crate::{dto::*, error::Result, platform::NativePlatform, session::WalletSession};
use mooze_app::dto::{BroadcastResultDto, ReceiveAddressDto};
use mooze_core::{
    domain::{AppNetwork, ChainId},
    wallet::{backend::default_electrum_urls, descriptors::LIQUID_TESTNET_POLICY_ASSET},
};
type State<'a> = tauri::State<'a, WalletSession<NativePlatform>>;
#[tauri::command]
pub fn host_info() -> HostInfoDto {
    HostInfoDto {
        network: "Testnet".into(),
        backend: "Electrum".into(),
        liquid_policy_asset: LIQUID_TESTNET_POLICY_ASSET.into(),
        bitcoin_endpoints: default_electrum_urls(ChainId::Bitcoin, AppNetwork::Testnet),
        liquid_endpoints: default_electrum_urls(ChainId::Liquid, AppNetwork::Testnet),
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
        .set_file_name("mooze-testnet-diagnostics.json")
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
