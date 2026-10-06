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
pub async fn holdings(state: State<'_>) -> Result<HoldingsSnapshotDto> { state.holdings().await }
#[tauri::command]
pub fn approved_assets(state: State<'_>) -> Result<Vec<mooze_app::dto::AssetMetadataDto>> { state.approved_assets() }
