//! Liquid wallet. Port of `lib/infra/lwk/liquid_wallet_service_impl.dart`
//! and the Liquid parts of the wallet repositories.
//!
//! The LWK wollet persists its updates through a [`store::JournalStore`]
//! that the wallet flushes into a [`KvStore`]. Network calls use the LWK
//! async esplora client.

pub mod classify;
pub mod store;
pub mod uri;

use std::collections::HashSet;
use std::str::FromStr;
use std::sync::Arc;

use lwk_common::Signer;
use lwk_wollet::asyncr::EsploraClient;
use lwk_wollet::elements::pset::PartiallySignedTransaction;
use lwk_wollet::elements::{Address, AssetId, OutPoint, Txid};
use lwk_wollet::{Chain, Wollet, WolletBuilder, WolletDescriptor};

use self::classify::{apply_optimistic_delta, map_balance, map_tx, LwkTxView};
use self::store::{flush_journal, load_journal, wipe_prefix, JournalStore, STORE_PREFIX};
use super::descriptors::{liquid_descriptor, liquid_network, liquid_policy_asset, liquid_signer};
use super::endpoints::EndpointResolver;
use super::explorer::{hex, index_range, AddressOwnership, DerivedAddressInfo, Keychain, NextUnusedAddress, WalletUtxoInfo};
use crate::wallet::backend::ChainBackend;
#[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
use crate::wallet::backend::{ElectrumConfig, LiquidElectrum};
use super::fees::liquid_fee_rate;
use super::tracker::{sort_newest_first, TxTracker};
use crate::domain::{
    AppNetwork, Balance, BroadcastResult, ChainId, FeeEstimate, LiquidSendDraft, LiquidUtxo, ReceiveAddress,
    SendRequest, ServiceLifecycle, ServiceState, SyncOutcome, Transaction, TransactionDirection, TransactionEvent,
    TransactionSource, TransactionStatus, WalletCredentials, LBTC_ASSET_ID,
};
use crate::ports::{Clock, KvStore};
use crate::{Error, Result};

const CHAIN: ChainId = ChainId::Liquid;

fn svc(e: impl std::fmt::Display) -> Error {
    Error::service(CHAIN, e)
}

/// Message when a drain amount cannot be computed (kept from Dart).
pub const DRAIN_AMOUNT_ERROR: &str = "não foi possível calcular o valor do envio total";

/// True for LWK errors that mean the persisted state drifted and a wipe
/// plus rescan fixes it. Port of `_isRecoverableLwkPersistenceError`.
pub fn is_recoverable_persistence_error(desc: &str) -> bool {
    desc.contains("UpdateOnDifferentStatus") || desc.contains("UpdateHeightTooOld")
}

fn describe(e: &lwk_wollet::Error) -> String {
    format!("{e} ({e:?})")
}

/// Ownership scan limit per chain of the Liquid explorer (Dart `_kLiquidOwnershipScanLimit`).
pub const OWNERSHIP_SCAN_LIMIT: u32 = 200;

fn to_keychain(c: Chain) -> Keychain {
    match c {
        Chain::External => Keychain::External,
        Chain::Internal => Keychain::Internal,
    }
}

/// Unsigned send plus the numbers the UI shows. Port of `_BuiltSend`.
#[derive(Debug, Clone, PartialEq)]
pub struct BuiltLiquidSend {
    /// Base64 PSET.
    pub pset: String,
    /// Amount the destination receives, in the asset's base units.
    pub amount_sat: u64,
    /// Network fee, always in L-BTC sats.
    pub fee_sat: u64,
    pub fee_rate_sat_per_kvb: f64,
    pub asset_id: String,
}

/// LWK wollet plus esplora client. Port of `LiquidWalletServiceImpl`.
pub struct LiquidWallet<K: KvStore, C: Clock> {
    wollet: Wollet,
    journal: JournalStore,
    network: AppNetwork,
    kv: K,
    clock: C,
    endpoints: EndpointResolver,
    client: Option<(String, EsploraClient)>,
    backend: ChainBackend,
    #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
    electrum: Option<LiquidElectrum>,
    tracker: TxTracker,
    last_list: Vec<Transaction>,
    last_balance: Balance,
    state: ServiceState,
}

impl<K: KvStore, C: Clock> LiquidWallet<K, C> {
    /// Builds the descriptor and the wollet from the stored updates.
    /// Wipes the store once and retries if LWK reports drifted state.
    /// Port of `connect`.
    ///
    /// NOTE(port): like Dart, connect does not prime balance or history;
    /// the first [`Self::sync`] does (or [`Self::refresh_balance`]).
    pub async fn connect(credentials: &WalletCredentials, kv: K, clock: C, endpoints: EndpointResolver) -> Result<Self> {
        if credentials.is_absent() {
            return Err(Error::Credential("mnemonic is empty".into()));
        }
        let network = credentials.network;
        let descriptor = liquid_descriptor(&credentials.mnemonic, network)
            .map_err(|e| svc(format!("lwk init failed: {e}")))?;
        let journal = load_journal(&kv, STORE_PREFIX).await?;
        let (wollet, journal) = match Self::build_wollet(network, &descriptor, &journal) {
            Ok(w) => (w, journal),
            Err(desc) if is_recoverable_persistence_error(&desc) => {
                wipe_prefix(&kv, STORE_PREFIX).await?;
                let fresh = JournalStore::new();
                let w = Self::build_wollet(network, &descriptor, &fresh)
                    .map_err(|d| svc(format!("lwk init failed after wipe recovery: {d}")))?;
                (w, fresh)
            }
            Err(desc) => return Err(svc(format!("lwk init failed: {desc}"))),
        };
        flush_journal(&kv, STORE_PREFIX, &journal).await?;
        Ok(Self {
            wollet,
            journal,
            network,
            kv,
            clock,
            endpoints,
            client: None,
            backend: ChainBackend::Esplora,
            #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
            electrum: None,
            tracker: TxTracker::new(),
            last_list: Vec::new(),
            last_balance: Balance::default(),
            state: ServiceState { lifecycle: ServiceLifecycle::Connected, failure: None, last_sync_at_ms: None },
        })
    }

    fn build_wollet(
        network: AppNetwork,
        descriptor: &WolletDescriptor,
        journal: &JournalStore,
    ) -> std::result::Result<Wollet, String> {
        WolletBuilder::new(liquid_network(network), descriptor.clone())
            .with_stores(Arc::new(journal.clone()))
            .and_then(|b| b.build())
            .map_err(|e| describe(&e))
    }

    /// App network of the wallet.
    pub fn network(&self) -> AppNetwork {
        self.network
    }

    /// Service state.
    pub fn state(&self) -> &ServiceState {
        &self.state
    }

    /// Endpoint resolver (for diagnostics).
    pub fn endpoints(&self) -> &EndpointResolver {
        &self.endpoints
    }

    /// Underlying LWK wollet, read-only.
    pub fn wollet(&self) -> &Wollet {
        &self.wollet
    }

    /// Policy asset (L-BTC) id of the network.
    pub fn policy_asset(&self) -> &'static str {
        liquid_policy_asset(self.network)
    }

    /// Cached transaction list, newest first.
    pub fn list_transactions(&self) -> &[Transaction] {
        &self.last_list
    }

    /// Cached balance.
    pub fn balance(&self) -> &Balance {
        &self.last_balance
    }

    /// Drains queued transaction events.
    pub fn take_events(&mut self) -> Vec<TransactionEvent> {
        self.tracker.take_events()
    }

    async fn flush(&self) -> Result<()> {
        flush_journal(&self.kv, STORE_PREFIX, &self.journal).await.map(|_| ())
    }

    /// Switches the chain backend. Drops cached connections.
    ///
    /// Electrum needs the `electrum` feature and a native target. Pair the
    /// switch with matching endpoints, for example
    /// [`EndpointResolver::with_electrum_defaults`].
    pub fn set_backend(&mut self, backend: ChainBackend, endpoints: EndpointResolver) -> Result<()> {
        crate::wallet::bitcoin::ensure_backend_supported(&backend)?;
        self.backend = backend;
        self.endpoints = endpoints;
        self.client = None;
        #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
        {
            self.electrum = None;
        }
        Ok(())
    }

    /// Current chain backend.
    pub fn backend(&self) -> &ChainBackend {
        &self.backend
    }

    /// Electrum client for the current endpoint, connecting if needed.
    #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
    async fn electrum_client(&mut self, config: &ElectrumConfig) -> Result<LiquidElectrum> {
        let url = self.endpoints.current(CHAIN)?.to_owned();
        if let Some(c) = &self.electrum {
            if c.url() == url {
                return Ok(c.clone());
            }
        }
        match LiquidElectrum::connect(&url, config).await {
            Ok(c) => {
                self.electrum = Some(c.clone());
                Ok(c)
            }
            Err(e) => {
                self.endpoints.report_failure(CHAIN);
                Err(e)
            }
        }
    }

    /// Full scan through the configured backend.
    async fn fetch_update(&mut self) -> Result<Option<lwk_wollet::Update>> {
        #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
        if let ChainBackend::Electrum(config) = self.backend.clone() {
            let client = self
                .electrum_client(&config)
                .await
                .map_err(|e| svc(format!("lwk sync failed: {e}")))?;
            return match client.full_scan(&self.wollet).await {
                Ok(u) => Ok(u),
                Err(e) => {
                    self.electrum = None;
                    self.endpoints.report_failure(CHAIN);
                    Err(svc(format!("lwk sync failed: {e}")))
                }
            };
        }
        let (url, mut client) = self.take_client()?;
        let scanned = client.full_scan(&self.wollet).await;
        self.client = Some((url, client));
        scanned.map_err(|e| {
            self.endpoints.report_failure(CHAIN);
            svc(format!("lwk sync failed: {}", describe(&e)))
        })
    }

    /// Broadcasts through the configured backend. Returns the txid.
    async fn broadcast_tx(&mut self, tx: lwk_wollet::elements::Transaction) -> Result<String> {
        #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
        if let ChainBackend::Electrum(config) = self.backend.clone() {
            let client = self
                .electrum_client(&config)
                .await
                .map_err(|e| svc(format!("lwk broadcastSignedPset failed: {e}")))?;
            return client.broadcast(tx).await.map_err(|e| {
                self.electrum = None;
                svc(format!("lwk broadcastSignedPset failed: {e}"))
            });
        }
        let (url, client) = self.take_client()?;
        let r = client.broadcast(&tx).await;
        self.client = Some((url, client));
        r.map(|t| t.to_string()).map_err(|e| svc(format!("lwk broadcastSignedPset failed: {}", describe(&e))))
    }

    fn take_client(&mut self) -> Result<(String, EsploraClient)> {
        let url = self.endpoints.current(CHAIN)?.to_owned();
        match self.client.take() {
            Some((u, c)) if u == url => Ok((u, c)),
            _ => Ok((url.clone(), EsploraClient::new(liquid_network(self.network), &url))),
        }
    }

    fn balances_raw(&self) -> Result<Vec<(String, u64)>> {
        let b = self.wollet.balance().map_err(|e| svc(format!("lwk balances failed: {e}")))?;
        Ok(b.iter().map(|(a, v)| (a.to_string(), *v)).collect())
    }

    fn asset_balance(&self, asset_id: &str) -> Result<u64> {
        Ok(self.balances_raw()?.into_iter().find(|(a, _)| a == asset_id).map(|(_, v)| v).unwrap_or(0))
    }

    /// Full scan through esplora, then reads transactions and balances,
    /// diffs and queues events. Port of `sync`.
    pub async fn sync(&mut self) -> Result<SyncOutcome> {
        let t0 = self.clock.now_ms();
        let update = self.fetch_update().await?;
        self.endpoints.report_success(CHAIN);
        if let Some(update) = update {
            self.wollet.apply_update(update).map_err(|e| svc(format!("lwk sync failed: {}", describe(&e))))?;
            self.flush().await?;
        }
        let txs = self.wollet.transactions().map_err(|e| svc(format!("lwk sync failed: {e}")))?;
        let balances = self.balances_raw()?;
        let now = self.clock.now_ms();
        let mut mapped: Vec<Transaction> = txs.iter().map(|t| map_tx(&LwkTxView::from_wallet_tx(t), now)).collect();
        sort_newest_first(&mut mapped);
        let changed = self.tracker.diff(&mapped, now);
        self.last_list = mapped;
        self.last_balance = map_balance(&balances, now);
        let end = self.clock.now_ms();
        self.state =
            ServiceState { lifecycle: ServiceLifecycle::Connected, failure: None, last_sync_at_ms: Some(end) };
        Ok(SyncOutcome { chain: CHAIN, fetched: self.last_list.len(), changed, duration_ms: end.saturating_sub(t0) })
    }

    /// Re-reads balances from the local wollet, no network. Port of `refreshBalance`.
    pub fn refresh_balance(&mut self) -> Result<&Balance> {
        let balances = self.balances_raw().map_err(|e| svc(format!("lwk refreshBalance failed: {e}")))?;
        self.last_balance = map_balance(&balances, self.clock.now_ms());
        Ok(&self.last_balance)
    }

    /// Applies known per-asset deltas to the cached balance. Port of
    /// `applyOptimisticBalanceDelta`. The next sync overwrites it.
    pub fn apply_optimistic_balance_delta(&mut self, deltas: &[(String, i64)]) -> &Balance {
        self.last_balance = apply_optimistic_delta(&self.last_balance, deltas, self.clock.now_ms());
        &self.last_balance
    }

    /// Last unused confidential address. Port of `getReceiveAddress`.
    pub async fn receive_address(&mut self) -> Result<String> {
        let a = self.wollet.address(None).map_err(|e| svc(format!("lwk getReceiveAddress failed: {e}")))?;
        self.flush().await?;
        Ok(a.address().to_string())
    }

    /// Receive address for an asset. L-BTC gets a bare address, any other
    /// asset a `liquidnetwork:` URI with the asset id. Port of `nextReceiveAddress`.
    pub async fn next_receive_address(&mut self, asset_id: Option<&str>, label: Option<&str>) -> Result<ReceiveAddress> {
        let address = self.receive_address().await?;
        let is_asset = asset_id.is_some_and(|a| a != self.policy_asset());
        let mut r = ReceiveAddress::onchain(
            CHAIN,
            match asset_id {
                Some(a) if is_asset => format!("liquidnetwork:{address}?assetid={a}"),
                _ => address,
            },
        );
        r.asset_id = asset_id.map(str::to_owned);
        r.label = label.map(str::to_owned);
        Ok(r)
    }

    /// Unblinded UTXOs. Port of `getUtxos`.
    pub fn utxos(&self) -> Result<Vec<LiquidUtxo>> {
        let utxos = self.wollet.utxos().map_err(|e| svc(format!("lwk getUtxos failed: {e}")))?;
        Ok(utxos
            .into_iter()
            .map(|u| LiquidUtxo {
                txid: u.outpoint.txid.to_string(),
                vout: u.outpoint.vout,
                asset_id: u.unblinded.asset.to_string(),
                asset_blinding_factor: u.unblinded.asset_bf.to_string(),
                value_sat: u.unblinded.value,
                value_blinding_factor: u.unblinded.value_bf.to_string(),
            })
            .collect())
    }

    fn address_at(&self, keychain: Keychain, index: u32) -> Result<Address> {
        let r = match keychain {
            Keychain::External => self.wollet.address(Some(index)),
            Keychain::Internal => self.wollet.change(Some(index)),
        };
        r.map(|a| a.address().clone()).map_err(|e| svc(format!("lwk address failed: {e}")))
    }

    /// Scripts of every wallet output, spent or not (Dart: UTXO addresses
    /// plus the wallet outputs of every transaction).
    fn history_scripts(&self) -> Result<HashSet<lwk_wollet::elements::Script>> {
        let txos = self.wollet.txos().map_err(|e| svc(format!("lwk txos failed: {e}")))?;
        Ok(txos.into_iter().map(|t| t.script_pubkey).collect())
    }

    /// Addresses of `keychain` at `start..start + count`. LWK derives
    /// addresses on demand, so nothing is revealed or stored.
    pub fn derived_addresses(&self, keychain: Keychain, start: u32, count: u32) -> Result<Vec<DerivedAddressInfo>> {
        let used = self.history_scripts()?;
        index_range(start, count)
            .map(|i| {
                let a = self.address_at(keychain, i)?;
                let script = a.script_pubkey();
                Ok(DerivedAddressInfo {
                    keychain,
                    index: i,
                    address: a.to_string(),
                    unconfidential: Some(a.to_unconfidential().to_string()),
                    script_hex: hex(script.as_bytes()),
                    used: used.contains(&script),
                })
            })
            .collect()
    }

    /// Unspent unblinded outputs with address, derivation and asset.
    pub fn unspent_outputs(&self) -> Result<Vec<WalletUtxoInfo>> {
        let utxos = self.wollet.utxos().map_err(|e| svc(format!("lwk getUtxos failed: {e}")))?;
        Ok(utxos
            .into_iter()
            .filter(|u| !u.is_spent)
            .map(|u| WalletUtxoInfo {
                txid: u.outpoint.txid.to_string(),
                vout: u.outpoint.vout,
                address: u.address.to_string(),
                unconfidential: Some(u.address.to_unconfidential().to_string()),
                script_hex: hex(u.script_pubkey.as_bytes()),
                keychain: to_keychain(u.ext_int),
                index: u.wildcard_index,
                amount_sat: u.unblinded.value,
                asset_id: Some(u.unblinded.asset.to_string()),
                confirmation_height: u.height,
                // NOTE(core): LWK keeps block times per transaction, not per output.
                confirmation_time_s: None,
            })
            .collect())
    }

    /// Derivation of `address` if it is one of the first `scan_limit`
    /// addresses of the external chain, then of the internal chain.
    ///
    /// A confidential input must match the derived confidential address; an
    /// unconfidential input matches by script. This equals the Dart string
    /// compare against `standard` and `confidential`. Fails for an
    /// unparseable address or one of another network.
    pub fn is_mine(&self, address: &str, scan_limit: u32) -> Result<Option<AddressOwnership>> {
        let parsed = Address::from_str(address.trim()).map_err(|e| Error::invalid(format!("invalid liquid address: {e}")))?;
        if parsed.params != self.wollet.network().address_params() {
            return Err(Error::invalid("liquid address of another network"));
        }
        let script = parsed.script_pubkey();
        for keychain in [Keychain::External, Keychain::Internal] {
            for index in index_range(0, scan_limit) {
                let a = self.address_at(keychain, index)?;
                let blinding_ok = parsed.blinding_pubkey.is_none() || parsed.blinding_pubkey == a.blinding_pubkey;
                if a.script_pubkey() == script && blinding_ok {
                    return Ok(Some(AddressOwnership { keychain, index }));
                }
            }
        }
        Ok(None)
    }

    /// LWK's last unused external address, with a history check. Port of
    /// Dart `getNextUnusedLiquidAddress` (`addressLastUnused`). Reveals nothing.
    pub async fn next_unused_address(&mut self) -> Result<NextUnusedAddress> {
        let r = self.wollet.address(None).map_err(|e| svc(format!("lwk addressLastUnused failed: {e}")))?;
        let used = self.history_scripts()?.contains(&r.address().script_pubkey());
        self.flush().await?;
        Ok(NextUnusedAddress { index: r.index(), address: r.address().to_string(), used })
    }

    fn pset_fee(&self, pset: &PartiallySignedTransaction) -> std::result::Result<u64, lwk_wollet::Error> {
        let details = self.wollet.get_details(pset)?;
        Ok(details.fees_in(&self.wollet.policy_asset()))
    }

    /// Builds an unsigned L-BTC send. A drain sends the whole L-BTC balance
    /// minus the fee. Syncs first (best effort). Port of `buildLbtcSend`.
    pub async fn build_lbtc_send(
        &mut self,
        destination: &str,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> Result<LiquidSendDraft> {
        if !drain && amount_sat == 0 {
            return Err(svc("amount must be positive"));
        }
        if destination.trim().is_empty() {
            return Err(svc("destination is empty"));
        }
        // Best effort: a failed pre-sync builds on the last known state.
        let _ = self.sync().await;
        let fee_rate = liquid_fee_rate::from_sat_per_vb(fee_rate_sat_per_vb);
        let built = (|| -> std::result::Result<(PartiallySignedTransaction, u64), String> {
            let address = Address::from_str(destination).map_err(|e| e.to_string())?;
            let builder = self.wollet.tx_builder();
            let builder = if drain {
                builder.drain_lbtc_wallet().drain_lbtc_to(&address).map_err(|e| describe(&e))?
            } else {
                builder.add_lbtc_recipient(&address, amount_sat).map_err(|e| describe(&e))?
            };
            let pset =
                builder.enable_ct_discount().fee_rate(Some(fee_rate as f32)).finish().map_err(|e| describe(&e))?;
            let fee = self.pset_fee(&pset).map_err(|e| describe(&e))?;
            Ok((pset, fee))
        })();
        let (pset, fee) = built.map_err(|e| svc(format!("lwk buildLbtcSend failed: {e}")))?;
        let amount = if drain {
            let balance = self.asset_balance(self.policy_asset()).map_err(|_| svc(DRAIN_AMOUNT_ERROR))?;
            match balance.checked_sub(fee) {
                Some(v) if v > 0 => v,
                _ => return Err(svc(DRAIN_AMOUNT_ERROR)),
            }
        } else {
            amount_sat
        };
        self.flush().await?;
        Ok(LiquidSendDraft {
            pset: pset.to_string(),
            destination: destination.to_owned(),
            amount_sat: amount,
            fee_sat: fee,
            fee_rate_sat_per_kvb: fee_rate,
            drain,
        })
    }

    /// Builds (does not sign) the PSET for a request. Port of `_buildSend`.
    ///
    /// L-BTC (or no asset): [`Self::build_lbtc_send`]; `drain` or
    /// `subtract_fee_from_amount` drains. Other assets: the amount is in the
    /// asset's base units, `drain` sends the whole asset balance, and the
    /// fee is paid in L-BTC.
    pub async fn build_send(&mut self, request: &SendRequest) -> Result<BuiltLiquidSend> {
        if request.chain != CHAIN {
            return Err(svc(format!("liquid service only handles Liquid sends (got: {})", request.chain.as_str())));
        }
        let destination = request.destination.trim().to_owned();
        if destination.is_empty() {
            return Err(svc("destination is empty"));
        }
        let policy = self.policy_asset();
        let asset_id = match &request.asset_id {
            Some(a) if a != policy => a.clone(),
            _ => {
                let drain = request.drain || request.subtract_fee_from_amount;
                let d = self
                    .build_lbtc_send(&destination, request.amount_sat, request.fee_rate_override_sat_per_vbyte, drain)
                    .await?;
                // NOTE(port): Dart tags L-BTC sends with the mainnet id on every network.
                return Ok(BuiltLiquidSend {
                    pset: d.pset,
                    amount_sat: d.amount_sat,
                    fee_sat: d.fee_sat,
                    fee_rate_sat_per_kvb: d.fee_rate_sat_per_kvb,
                    asset_id: LBTC_ASSET_ID.to_owned(),
                });
            }
        };
        let _ = self.sync().await;
        let fee_rate = liquid_fee_rate::from_sat_per_vb(request.fee_rate_override_sat_per_vbyte);
        let amount = if request.drain {
            let balance = self.asset_balance(&asset_id).map_err(|e| svc(format!("lwk buildAssetTx failed: {e}")))?;
            if balance == 0 {
                return Err(svc("asset balance is zero"));
            }
            balance
        } else {
            request.amount_sat
        };
        if amount == 0 {
            return Err(svc("amount must be positive"));
        }
        let built = (|| -> std::result::Result<(PartiallySignedTransaction, u64), String> {
            let address = Address::from_str(&destination).map_err(|e| e.to_string())?;
            let asset = AssetId::from_str(&asset_id).map_err(|_| "Invalid asset".to_owned())?;
            let pset = self
                .wollet
                .tx_builder()
                .add_recipient(&address, amount, asset)
                .map_err(|e| describe(&e))?
                .enable_ct_discount()
                .fee_rate(Some(fee_rate as f32))
                .finish()
                .map_err(|e| describe(&e))?;
            let fee = self.pset_fee(&pset).map_err(|e| describe(&e))?;
            Ok((pset, fee))
        })();
        let (pset, fee) = built.map_err(|e| svc(format!("lwk buildAssetTx failed: {e}")))?;
        self.flush().await?;
        Ok(BuiltLiquidSend { pset: pset.to_string(), amount_sat: amount, fee_sat: fee, fee_rate_sat_per_kvb: fee_rate, asset_id })
    }

    /// Fee quote for a request. Port of `estimateFee`.
    pub async fn estimate_fee(&mut self, request: &SendRequest) -> Result<FeeEstimate> {
        let b = self.build_send(request).await?;
        Ok(FeeEstimate {
            chain: CHAIN,
            priority: request.fee_priority,
            absolute_fee_sat: b.fee_sat,
            fee_rate_sat_per_vbyte: Some(liquid_fee_rate::to_sat_per_vb(b.fee_rate_sat_per_kvb)),
            estimated_blocks: None,
        })
    }

    /// Signs the wallet inputs and finalizes. Returns the finalized PSET
    /// (base64). Port of lwk-dart `signTx`.
    ///
    /// NOTE(port): lwk-dart builds the signer with an inverted mainnet flag;
    /// it only changes the xprv prefix, so signatures are the same.
    pub fn sign_pset(&self, pset: &str, mnemonic: &str) -> Result<String> {
        if pset.trim().is_empty() {
            return Err(svc("pset is empty"));
        }
        if mnemonic.trim().is_empty() {
            return Err(svc("mnemonic is empty"));
        }
        let signer = liquid_signer(mnemonic, self.network).map_err(|e| svc(format!("lwk signTx failed: {e}")))?;
        let mut p = PartiallySignedTransaction::from_str(pset.trim()).map_err(|e| svc(format!("lwk signTx failed: {e}")))?;
        let _ = signer.sign(&mut p);
        let tx = self.wollet.finalize(&mut p).map_err(|e| svc(format!("lwk signTx failed: {}", describe(&e))))?;
        Ok(PartiallySignedTransaction::from_tx(tx).to_string())
    }

    /// Extracts and broadcasts a finalized PSET, then syncs (best effort).
    /// Port of `Blockchain.broadcastSignedPset` plus the post-sync.
    pub async fn broadcast_pset(&mut self, signed_pset: &str) -> Result<String> {
        let tx = PartiallySignedTransaction::from_str(signed_pset.trim())
            .map_err(|e| e.to_string())
            .and_then(|p| p.extract_tx().map_err(|e| e.to_string()))
            .map_err(|e| svc(format!("lwk broadcastSignedPset failed: {e}")))?;
        let txid = self.broadcast_tx(tx).await?;
        self.endpoints.report_success(CHAIN);
        let _ = self.sync().await;
        Ok(txid)
    }

    /// Signs, broadcasts and syncs. Port of `signAndBroadcastPset`.
    pub async fn sign_and_broadcast_pset(&mut self, pset: &str, mnemonic: &str) -> Result<String> {
        let signed = self.sign_pset(pset, mnemonic)?;
        self.broadcast_pset(&signed).await
    }

    /// Builds, signs and broadcasts a send. The caller passes the mnemonic
    /// per call; the wallet never stores it. Port of `sendOnchain`.
    pub async fn send_onchain(&mut self, request: &SendRequest, mnemonic: &str) -> Result<BroadcastResult> {
        let send = self.build_send(request).await?;
        if mnemonic.is_empty() {
            return Err(svc("mnemonic not available"));
        }
        let txid = self.sign_and_broadcast_pset(&send.pset, mnemonic).await?;
        let now = self.clock.now_ms();
        let mut tx = Transaction::new(
            txid.clone(),
            CHAIN,
            TransactionDirection::Outgoing,
            TransactionStatus::Pending,
            send.amount_sat as i64,
            send.fee_sat as i64,
            now,
        );
        tx.asset_id = Some(send.asset_id.clone());
        tx.address = Some(request.destination.clone());
        tx.label = request.label.clone();
        tx.source = Some(TransactionSource::Lwk);
        if self.tracker.register(&tx, now) {
            self.last_list.insert(0, tx.clone());
        }
        Ok(BroadcastResult { chain: CHAIN, tx_id: txid, transaction: tx, fee_paid_sat: Some(send.fee_sat) })
    }

    /// Signs the wallet inputs of an external (SideSwap) PSET and returns
    /// it unfinalized but with witnesses set. Port of lwk-dart
    /// `signedPsetWithExtraDetails`.
    pub fn sign_swap_pset(&self, pset: &str, mnemonic: &str) -> Result<String> {
        let signer =
            liquid_signer(mnemonic, self.network).map_err(|e| svc(format!("lwk signSwapPset failed: {e}")))?;
        let mut p =
            PartiallySignedTransaction::from_str(pset.trim()).map_err(|e| svc(format!("lwk signSwapPset failed: {e}")))?;
        for input in p.inputs_mut().iter_mut() {
            let outpoint = OutPoint { txid: input.previous_txid, vout: input.previous_output_index };
            if let Some(mut txout) = self.wallet_txout(&outpoint) {
                input.in_utxo_rangeproof = txout.witness.rangeproof.take();
                input.witness_utxo = Some(txout);
            }
        }
        self.wollet.add_details(&mut p).map_err(|e| svc(format!("lwk signSwapPset failed: {}", describe(&e))))?;
        let _ = signer.sign(&mut p);
        for input in p.inputs_mut() {
            if let Some((pk, sig)) = input.partial_sigs.iter().next() {
                input.final_script_witness = Some(vec![sig.clone(), pk.to_bytes()]);
            }
        }
        Ok(p.to_string())
    }

    fn wallet_txout(&self, outpoint: &OutPoint) -> Option<lwk_wollet::elements::TxOut> {
        let tx = self.wollet.transaction(&outpoint.txid).ok()??;
        tx.tx.output.get(outpoint.vout as usize).cloned()
    }

    /// Looks up a wallet transaction id, for callers holding hex strings.
    pub fn has_transaction(&self, txid: &str) -> bool {
        Txid::from_str(txid).ok().and_then(|t| self.wollet.transaction(&t).ok().flatten()).is_some()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, FixedClock, MemoryKv};

    const ABANDON: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    fn connect(kv: MemoryKv) -> LiquidWallet<MemoryKv, FixedClock> {
        let creds = WalletCredentials { mnemonic: ABANDON.into(), network: AppNetwork::Mainnet };
        block_on(LiquidWallet::connect(&creds, kv, FixedClock::new(1_000), EndpointResolver::with_defaults(AppNetwork::Mainnet)))
            .unwrap()
    }

    #[test]
    fn connect_receive_and_reload() {
        let kv = MemoryKv::new();
        let mut w = connect(kv.clone());
        assert!(w.state().is_operational());
        assert_eq!(w.policy_asset(), LBTC_ASSET_ID);
        let a = block_on(w.receive_address()).unwrap();
        assert!(a.starts_with("lq1"), "{a}");
        // Unused address repeats.
        assert_eq!(block_on(w.receive_address()).unwrap(), a);
        let r = block_on(w.next_receive_address(Some(crate::domain::USDT_ASSET_ID), Some("l"))).unwrap();
        assert_eq!(r.address, Some(format!("liquidnetwork:{a}?assetid={}", crate::domain::USDT_ASSET_ID)));
        let r = block_on(w.next_receive_address(Some(LBTC_ASSET_ID), None)).unwrap();
        assert_eq!(r.address.as_deref(), Some(a.as_str()));
        assert!(w.utxos().unwrap().is_empty());
        assert!(w.refresh_balance().unwrap().assets.iter().all(|b| b.amount_sat == 0));
        drop(w);
        let w2 = connect(kv);
        assert!(w2.list_transactions().is_empty());
    }

    #[test]
    fn recovers_from_drifted_store() {
        // A store entry LWK cannot decrypt must not wedge connect forever:
        // either LWK ignores it or connect fails with a service error.
        let kv = MemoryKv::new();
        block_on(kv.put(&format!("{STORE_PREFIX}garbage"), vec![1, 2, 3])).unwrap();
        let creds = WalletCredentials { mnemonic: ABANDON.into(), network: AppNetwork::Mainnet };
        let r = block_on(LiquidWallet::connect(&creds, kv, FixedClock::new(0), EndpointResolver::with_defaults(AppNetwork::Mainnet)));
        if let Err(e) = r {
            assert!(matches!(e, Error::Service { chain: ChainId::Liquid, .. }), "{e}");
        }
        assert!(is_recoverable_persistence_error("UpdateOnDifferentStatus { wollet_status: 1 }"));
        assert!(is_recoverable_persistence_error("UpdateHeightTooOld"));
        assert!(!is_recoverable_persistence_error("Descriptor mismatch"));
    }

    #[test]
    fn send_validations_match_dart() {
        let mut w = connect(MemoryKv::new());
        let btc = SendRequest::new(ChainId::Bitcoin, "bc1q", 1);
        assert!(block_on(w.build_send(&btc)).unwrap_err().to_string().contains("only handles Liquid sends (got: bitcoin)"));
        let empty = SendRequest::new(ChainId::Liquid, "  ", 1);
        assert!(block_on(w.build_send(&empty)).unwrap_err().to_string().contains("destination is empty"));
        assert!(block_on(w.build_lbtc_send("lq1x", 0, None, false)).unwrap_err().to_string().contains("amount must be positive"));
        assert!(w.sign_pset("", ABANDON).unwrap_err().to_string().contains("pset is empty"));
        assert!(w.sign_pset("cHNldP8=", " ").unwrap_err().to_string().contains("mnemonic is empty"));
        assert!(w.sign_swap_pset("not a pset", ABANDON).is_err());
    }

    #[test]
    fn optimistic_delta_updates_cache() {
        let mut w = connect(MemoryKv::new());
        let b = w.apply_optimistic_balance_delta(&[(LBTC_ASSET_ID.into(), 500)]).clone();
        assert_eq!(b.amount_for_asset(LBTC_ASSET_ID), 500);
        assert_eq!(w.balance().amount_for_asset(LBTC_ASSET_ID), 500);
    }

    #[test]
    fn explorer_derives_checks_ownership_and_reveals_nothing() {
        let mut w = connect(MemoryKv::new());
        let ext = w.derived_addresses(Keychain::External, 0, 4).unwrap();
        assert_eq!(ext.iter().map(|a| a.index).collect::<Vec<_>>(), [0, 1, 2, 3]);
        assert!(ext.iter().all(|a| a.address.starts_with("lq1") && !a.used && a.keychain == Keychain::External));
        assert!(ext.iter().all(|a| a.unconfidential.as_deref().is_some_and(|u| u.starts_with("ex1"))));
        assert_eq!(ext[0].address, block_on(w.receive_address()).unwrap());
        let int = w.derived_addresses(Keychain::Internal, 0, 3).unwrap();
        assert_ne!(int[0].address, ext[0].address);
        assert_eq!(w.derived_addresses(Keychain::External, 2, 1).unwrap()[0], ext[2]);

        let own = |k, i| Some(AddressOwnership { keychain: k, index: i });
        assert_eq!(w.is_mine(&ext[3].address, OWNERSHIP_SCAN_LIMIT).unwrap(), own(Keychain::External, 3));
        assert_eq!(w.is_mine(ext[3].unconfidential.as_ref().unwrap(), 200).unwrap(), own(Keychain::External, 3));
        assert_eq!(w.is_mine(&int[2].address, 200).unwrap(), own(Keychain::Internal, 2));
        assert_eq!(w.is_mine(&ext[3].address, 3).unwrap(), None);
        assert!(matches!(w.is_mine("garbage", 200), Err(Error::InvalidInput(_))));
        assert!(matches!(w.is_mine("bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu", 200), Err(Error::InvalidInput(_))));

        assert!(w.unspent_outputs().unwrap().is_empty());
        let next = block_on(w.next_unused_address()).unwrap();
        assert_eq!(next, NextUnusedAddress { index: 0, address: ext[0].address.clone(), used: false });
        // Nothing is revealed: the same address comes back.
        assert_eq!(block_on(w.next_unused_address()).unwrap(), next);
    }

    #[test]
    fn futures_are_send_on_native() {
        fn assert_send<T: Send>(_: &T) {}
        let mut w = connect(MemoryKv::new());
        let f = w.sync();
        assert_send(&f);
        drop(f);
        let req = SendRequest::new(ChainId::Liquid, "lq1", 1);
        let f = w.send_onchain(&req, ABANDON);
        assert_send(&f);
    }
}
