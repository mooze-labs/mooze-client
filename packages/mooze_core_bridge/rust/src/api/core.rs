//! The core handle Dart holds, and the calls behind the Dart wallet services.
//!
//! Every call runs on the shared tokio runtime (see [`crate::ports`]),
//! because reqwest and the Electrum spawner need a tokio context. Each
//! wallet sits behind its own async mutex, so calls on one wallet run one at
//! a time, as the Dart services expect.

use std::path::PathBuf;
use std::sync::Arc;

use flutter_rust_bridge::frb;
use mooze_core::domain::{AppNetwork, ChainId, WalletCredentials};
use mooze_core::migration::{import_flutter_data, is_migrated, parse_snapshot};
use mooze_core::wallet::{BitcoinWallet, ChainBackend, ElectrumConfig, EndpointResolver, LiquidWallet};
use tokio::sync::Mutex;

use super::types::*;
use crate::ports::{on_runtime, FileKv, SystemClock, TokioSpawner};

/// Subdirectory of `data_dir` that holds the key-value files.
const KV_DIR: &str = "core_kv";

type Bitcoin = BitcoinWallet<FileKv, SystemClock>;
type Liquid = LiquidWallet<FileKv, SystemClock>;

struct Inner {
    kv: FileKv,
    network: AppNetwork,
    backend: ChainBackend,
    endpoints: EndpointResolver,
    bitcoin: Mutex<Option<Bitcoin>>,
    liquid: Mutex<Option<Liquid>>,
}

fn not_connected(chain: ChainId) -> CoreError {
    CoreError { kind: CoreErrorKind::InvalidState, message: format!("{} wallet not connected", chain.as_str()) }
}

/// Handle to one opened core. Dart keeps one for the app's lifetime.
#[frb(opaque)]
pub struct MoozeCore {
    inner: Arc<Inner>,
}

impl MoozeCore {
    /// Opens the core in `config.data_dir`.
    pub async fn open(config: CoreConfig) -> Result<MoozeCore, CoreError> {
        let kv = FileKv::open(PathBuf::from(&config.data_dir).join(KV_DIR))?;
        let network: AppNetwork = config.network.into();
        let backend = match config.backend {
            BackendDto::Esplora => ChainBackend::Esplora,
            BackendDto::Electrum => ChainBackend::Electrum(ElectrumConfig::new(Arc::new(TokioSpawner))),
        };
        let endpoints = EndpointResolver::for_backend(network, &backend)
            .with_custom_node(ChainId::Bitcoin, &config.bitcoin_node_url)
            .with_custom_node(ChainId::Liquid, &config.liquid_node_url);
        Ok(MoozeCore {
            inner: Arc::new(Inner {
                kv,
                network,
                backend,
                endpoints,
                bitcoin: Mutex::new(None),
                liquid: Mutex::new(None),
            }),
        })
    }

    // ───────────────────────────── one-time import

    /// True once the Flutter data import finished.
    pub async fn is_migrated(&self) -> Result<bool, CoreError> {
        let kv = self.inner.kv.clone();
        Ok(on_runtime(async move { is_migrated(&kv).await }).await?)
    }

    /// Imports the snapshot from `FlutterDataExporter`, once.
    pub async fn import_flutter_snapshot(&self, snapshot_json: String) -> Result<MigrationReportDto, CoreError> {
        let kv = self.inner.kv.clone();
        let report = on_runtime(async move {
            let snapshot = parse_snapshot(snapshot_json.as_bytes())?;
            import_flutter_data(&kv, &SystemClock, &snapshot).await
        })
        .await?;
        Ok(report.into())
    }

    // ───────────────────────────── bitcoin

    /// Loads or creates the Bitcoin wallet for `mnemonic`.
    pub async fn bitcoin_connect(&self, mnemonic: String) -> Result<(), CoreError> {
        let inner = self.inner.clone();
        on_runtime(async move {
            let creds = WalletCredentials { mnemonic, network: inner.network };
            let mut wallet = BitcoinWallet::connect(&creds, inner.kv.clone(), SystemClock, inner.endpoints.clone()).await?;
            if inner.backend.is_electrum() {
                wallet.set_backend(inner.backend.clone(), inner.endpoints.clone())?;
            }
            *inner.bitcoin.lock().await = Some(wallet);
            Ok(())
        })
        .await?;
        Ok(())
    }

    /// Drops the Bitcoin wallet. Idempotent.
    pub async fn bitcoin_disconnect(&self) {
        *self.inner.bitcoin.lock().await = None;
    }

    /// Syncs the Bitcoin wallet.
    pub async fn bitcoin_sync(&self) -> Result<SyncOutcomeDto, CoreError> {
        let inner = self.inner.clone();
        let outcome = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.sync().await
        })
        .await?;
        Ok((&outcome).into())
    }

    /// Bitcoin balance from local state.
    pub async fn bitcoin_balance(&self) -> Result<BalanceDto, CoreError> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.balance().into())
    }

    /// Bitcoin transactions from local state, newest first.
    pub async fn bitcoin_transactions(&self) -> Result<Vec<TransactionDto>, CoreError> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.list_transactions().iter().map(Into::into).collect())
    }

    /// Transaction changes since the last call.
    pub async fn bitcoin_take_events(&self) -> Result<Vec<TransactionEventDto>, CoreError> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.take_events().iter().map(Into::into).collect())
    }

    /// Next unused receive address.
    pub async fn bitcoin_receive_address(&self, label: Option<String>) -> Result<ReceiveAddressDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.next_receive_address(None, label.as_deref()).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Fee estimate for a send.
    pub async fn bitcoin_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto, CoreError> {
        let inner = self.inner.clone();
        let f = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.estimate_fee(&request.to_domain(ChainId::Bitcoin)).await
        })
        .await?;
        Ok((&f).into())
    }

    /// Builds, signs and broadcasts a send.
    pub async fn bitcoin_send(&self, request: SendRequestDto) -> Result<BroadcastResultDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.send_onchain(&request.to_domain(ChainId::Bitcoin)).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Chain tip height.
    pub async fn bitcoin_block_height(&self) -> Result<u32, CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move {
            let mut guard = inner.bitcoin.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("bitcoin wallet not connected".into()))?;
            w.block_height().await
        })
        .await?)
    }

    /// Adds a transaction broadcast elsewhere, for example a peg-in funding.
    pub async fn bitcoin_register_external_broadcast(&self, transaction: TransactionDto) -> Result<(), CoreError> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        w.register_external_broadcast(transaction.to_domain());
        Ok(())
    }

    // ───────────────────────────── liquid

    /// Loads or creates the Liquid wallet for `mnemonic`.
    pub async fn liquid_connect(&self, mnemonic: String) -> Result<(), CoreError> {
        let inner = self.inner.clone();
        on_runtime(async move {
            let creds = WalletCredentials { mnemonic, network: inner.network };
            let mut wallet = LiquidWallet::connect(&creds, inner.kv.clone(), SystemClock, inner.endpoints.clone()).await?;
            if inner.backend.is_electrum() {
                wallet.set_backend(inner.backend.clone(), inner.endpoints.clone())?;
            }
            *inner.liquid.lock().await = Some(wallet);
            Ok(())
        })
        .await?;
        Ok(())
    }

    /// Drops the Liquid wallet. Idempotent.
    pub async fn liquid_disconnect(&self) {
        *self.inner.liquid.lock().await = None;
    }

    /// Syncs the Liquid wallet.
    pub async fn liquid_sync(&self) -> Result<SyncOutcomeDto, CoreError> {
        let inner = self.inner.clone();
        let outcome = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.sync().await
        })
        .await?;
        Ok((&outcome).into())
    }

    /// Liquid balance from local state.
    pub async fn liquid_balance(&self) -> Result<BalanceDto, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.balance().into())
    }

    /// Re-reads balances from the local wallet, no network.
    pub async fn liquid_refresh_balance(&self) -> Result<BalanceDto, CoreError> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.refresh_balance()?.into())
    }

    /// Applies known per-asset deltas to the cached balance.
    pub async fn liquid_apply_balance_delta(&self, asset_ids: Vec<String>, deltas: Vec<i64>) -> Result<BalanceDto, CoreError> {
        if asset_ids.len() != deltas.len() {
            return Err(CoreError {
                kind: CoreErrorKind::InvalidInput,
                message: "asset_ids and deltas differ in length".into(),
            });
        }
        let pairs: Vec<(String, i64)> = asset_ids.into_iter().zip(deltas).collect();
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.apply_optimistic_balance_delta(&pairs).into())
    }

    /// Liquid transactions from local state, newest first.
    pub async fn liquid_transactions(&self) -> Result<Vec<TransactionDto>, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.list_transactions().iter().map(Into::into).collect())
    }

    /// Transaction changes since the last call.
    pub async fn liquid_take_events(&self) -> Result<Vec<TransactionEventDto>, CoreError> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.take_events().iter().map(Into::into).collect())
    }

    /// Receive address, optionally for one asset.
    pub async fn liquid_receive_address(
        &self,
        asset_id: Option<String>,
        label: Option<String>,
    ) -> Result<ReceiveAddressDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.next_receive_address(asset_id.as_deref(), label.as_deref()).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Unblinded UTXOs, for SideSwap.
    pub async fn liquid_utxos(&self) -> Result<Vec<LiquidUtxoDto>, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.utxos()?.iter().map(Into::into).collect())
    }

    /// Fee estimate for a send.
    pub async fn liquid_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto, CoreError> {
        let inner = self.inner.clone();
        let f = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.estimate_fee(&request.to_domain(ChainId::Liquid)).await
        })
        .await?;
        Ok((&f).into())
    }

    /// Builds an unsigned L-BTC send. A drain sends the whole L-BTC balance.
    pub async fn liquid_build_lbtc_send(
        &self,
        destination: String,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> Result<LiquidSendDraftDto, CoreError> {
        let inner = self.inner.clone();
        let d = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.build_lbtc_send(&destination, amount_sat, fee_rate_sat_per_vb, drain).await
        })
        .await?;
        Ok((&d).into())
    }

    /// Builds, signs and broadcasts a send.
    pub async fn liquid_send(&self, request: SendRequestDto, mnemonic: String) -> Result<BroadcastResultDto, CoreError> {
        let inner = self.inner.clone();
        let r = on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.send_onchain(&request.to_domain(ChainId::Liquid), &mnemonic).await
        })
        .await?;
        Ok((&r).into())
    }

    /// Signs a PSET with `mnemonic` and broadcasts it. Returns the txid.
    pub async fn liquid_sign_and_broadcast(&self, pset: String, mnemonic: String) -> Result<String, CoreError> {
        let inner = self.inner.clone();
        Ok(on_runtime(async move {
            let mut guard = inner.liquid.lock().await;
            let w = guard.as_mut().ok_or_else(|| mooze_core::Error::InvalidState("liquid wallet not connected".into()))?;
            w.sign_and_broadcast_pset(&pset, &mnemonic).await
        })
        .await?)
    }

    /// Signs a SideSwap swap PSET. Returns the signed PSET.
    pub async fn liquid_sign_swap_pset(&self, pset: String, mnemonic: String) -> Result<String, CoreError> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.sign_swap_pset(&pset, &mnemonic)?)
    }
}
