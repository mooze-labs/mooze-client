//! On-chain bitcoin wallet. Port of `lib/infra/bdk/**` and the bitcoin part
//! of the wallet repositories.
//!
//! The BDK wallet lives in memory. Its `ChangeSet` is serialized to JSON in
//! a [`KvStore`] after every change, so the wallet reloads without a full
//! scan. Network calls use `bdk_esplora` with a no-op sleeper: wasm has no
//! timer runtime, and retry pacing belongs to the platform.

use std::collections::HashSet;
use std::str::FromStr;
use std::time::Duration;

use bdk_esplora::esplora_client::{self, r#async::Sleeper, AsyncClient};
use bdk_esplora::EsploraAsyncExt;
use bdk_wallet::bitcoin::secp256k1::Secp256k1;
use bdk_wallet::bitcoin::{Address, Amount, FeeRate, Psbt, ScriptBuf};
use bdk_wallet::chain::{ChainPosition, Merge};
use bdk_wallet::descriptor::IntoWalletDescriptor;
use bdk_wallet::signer::SignersContainer;
use bdk_wallet::{ChangeSet, KeychainKind, SignOptions, Wallet};

use super::backend::ChainBackend;
#[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
use super::backend::{BitcoinElectrum, ElectrumConfig};
use super::descriptors::{
    bitcoin_descriptors, bitcoin_network, bitcoin_network_kind, BitcoinDescriptors,
};
use super::endpoints::EndpointResolver;
use super::explorer::{
    hex, index_range, AddressOwnership, DerivedAddressInfo, Keychain, NextUnusedAddress,
    WalletUtxoInfo,
};
use super::fees::BitcoinFeeEstimate;
use super::tracker::{sort_newest_first, TxTracker};
use crate::domain::{
    AppNetwork, AssetBalance, Balance, BroadcastResult, ChainId, FeeEstimate, ReceiveAddress,
    SendRequest, ServiceLifecycle, ServiceState, SyncOutcome, Transaction, TransactionDirection,
    TransactionEvent, TransactionSource, TransactionStatus, WalletCredentials,
};
use crate::ports::{Clock, KvStore};
use crate::{Error, Result};

/// KV key of the aggregated BDK `ChangeSet` (JSON).
pub const CHANGESET_KEY: &str = "wallet/bitcoin/changeset";
/// Addresses BDK derives ahead of the last revealed index.
pub const LOOKAHEAD: u32 = 25;
/// Unused scripts a full scan walks past before it stops.
pub const DEFAULT_STOP_GAP: usize = 20;
/// Concurrent esplora requests during a scan.
pub const PARALLEL_REQUESTS: usize = 5;
/// Receive-address walk limit (`nextFreshReceiveAddress(cap: 100)`).
pub const FRESH_ADDRESS_CAP: u32 = 100;

const CHAIN: ChainId = ChainId::Bitcoin;

fn svc(e: impl std::fmt::Display) -> Error {
    Error::service(CHAIN, e)
}

/// Fails for Electrum when the build cannot run it.
pub(crate) fn ensure_backend_supported(backend: &ChainBackend) -> Result<()> {
    let electrum_built = cfg!(all(feature = "electrum", not(target_arch = "wasm32")));
    if backend.is_electrum() && !electrum_built {
        return Err(Error::InvalidState(
            "the Electrum backend needs the `electrum` feature and a native target".into(),
        ));
    }
    Ok(())
}

/// Sleeper that returns at once. Esplora retries then run back to back.
#[derive(Debug, Clone, Copy, Default)]
pub struct NoopSleeper;

impl Sleeper for NoopSleeper {
    type Sleep = std::future::Ready<()>;
    fn sleep(_dur: Duration) -> Self::Sleep {
        std::future::ready(())
    }
}

/// Builds an async esplora client for `url`.
pub fn esplora_client(url: &str) -> Result<AsyncClient<NoopSleeper>> {
    esplora_client::Builder::new(url)
        .build_async_with_sleeper::<NoopSleeper>()
        .map_err(|e| Error::Network(e.to_string()))
}

/// Flat view of one wallet transaction. Port of `BdkTxView`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BdkTxView {
    pub txid: String,
    pub sent_sat: u64,
    pub received_sat: u64,
    /// `None` when BDK cannot compute the fee (a previous output is missing).
    pub fee_sat: Option<u64>,
    /// Block time (seconds) of the confirming block; `None` while unconfirmed.
    pub confirmation_time_s: Option<u64>,
    pub confirmation_height: Option<u32>,
}

impl BdkTxView {
    /// True when confirmed.
    pub fn is_confirmed(&self) -> bool {
        self.confirmation_time_s.is_some()
    }
}

/// Classifies a BDK transaction. Port of `_mapTx`.
///
/// Order: self-transfer (sent and received, delta within slack of the fee),
/// outgoing, incoming, internal. Slack is `max(1, fee / 100)` for fees over 100.
pub fn map_tx(t: &BdkTxView, now_ms: u64) -> Transaction {
    let received = t.received_sat as i64;
    let sent = t.sent_sat as i64;
    let fee = t.fee_sat.unwrap_or(0) as i64;

    let (direction, amount) = if sent > 0 && received > 0 {
        let delta = sent - received;
        let slack = if fee > 100 { fee / 100 } else { 1 };
        if (delta - fee).abs() <= slack {
            (TransactionDirection::SelfTransfer, fee)
        } else if sent > received {
            (TransactionDirection::Outgoing, delta.abs())
        } else {
            (TransactionDirection::Incoming, (received - sent).abs())
        }
    } else if sent > 0 {
        (TransactionDirection::Outgoing, sent)
    } else if received > 0 {
        (TransactionDirection::Incoming, received)
    } else {
        (TransactionDirection::Internal, 0)
    };

    let (status, ts, confirmations) = match t.confirmation_time_s {
        // NOTE(port): Dart reports 1 confirmation for any confirmed tx.
        Some(s) => (TransactionStatus::Confirmed, s * 1000, 1),
        None => (TransactionStatus::Pending, now_ms, 0),
    };
    let mut tx = Transaction::new(t.txid.clone(), CHAIN, direction, status, amount, fee, ts);
    tx.confirmations = confirmations;
    tx.source = Some(TransactionSource::Bdk);
    tx
}

/// Maps a BDK balance. Port of `_mapBalance`.
///
/// NOTE(port): `amount_sat` is the BDK total, which already includes the
/// pending amounts also reported in `pending_sat`. Kept as in Dart.
pub fn map_balance(b: &bdk_wallet::Balance, now_ms: u64) -> Balance {
    let pending = b.trusted_pending.to_sat() + b.untrusted_pending.to_sat() + b.immature.to_sat();
    Balance {
        assets: vec![AssetBalance {
            chain: CHAIN,
            asset_id: None,
            amount_sat: b.total().to_sat(),
            precision: 8,
            ticker: Some("BTC".to_owned()),
            pending_sat: pending,
        }],
        snapshot_at_ms: now_ms,
    }
}

/// Every canonical wallet transaction as a [`BdkTxView`]. Port of `txViews`.
pub fn tx_views(wallet: &Wallet) -> Vec<BdkTxView> {
    wallet
        .transactions()
        .map(|c| {
            let tx = &c.tx_node.tx;
            let (sent, received) = wallet.sent_and_received(tx);
            let fee = wallet.calculate_fee(tx).ok().map(|a| a.to_sat());
            let (time, height) = match &c.chain_position {
                ChainPosition::Confirmed { anchor, .. } => {
                    (Some(anchor.confirmation_time), Some(anchor.block_id.height))
                }
                ChainPosition::Unconfirmed { .. } => (None, None),
            };
            BdkTxView {
                txid: c.tx_node.txid.to_string(),
                sent_sat: sent.to_sat(),
                received_sat: received.to_sat(),
                fee_sat: fee,
                confirmation_time_s: time,
                confirmation_height: height,
            }
        })
        .collect()
}

/// Scripts that ever received funds: UTXOs plus every output of every
/// wallet transaction. Port of `usedScriptHexes`.
fn used_scripts(wallet: &Wallet) -> HashSet<ScriptBuf> {
    let mut used: HashSet<ScriptBuf> = wallet
        .list_unspent()
        .map(|u| u.txout.script_pubkey)
        .collect();
    for c in wallet.transactions() {
        for out in &c.tx_node.tx.output {
            used.insert(out.script_pubkey.clone());
        }
    }
    used
}

/// Next receive address with no on-chain history. Port of
/// `nextFreshReceiveAddress`: start at BDK's first unused address, walk
/// past used scripts, reveal up to the chosen index. Stages changes.
/// Returns the address and its external index.
pub fn next_fresh_receive_address(wallet: &mut Wallet, cap: u32) -> Result<(u32, Address)> {
    let used = used_scripts(wallet);
    let mut info = wallet.next_unused_address(KeychainKind::External);
    let mut walked = 0;
    while used.contains(&info.address.script_pubkey()) && walked < cap {
        walked += 1;
        info = wallet.peek_address(KeychainKind::External, info.index + 1);
    }
    if used.contains(&info.address.script_pubkey()) {
        return Err(svc(format!(
            "no unused receive address found within {cap}-index window"
        )));
    }
    let _ = wallet.reveal_addresses_to(KeychainKind::External, info.index);
    Ok((info.index, info.address))
}

fn to_keychain(k: KeychainKind) -> Keychain {
    match k {
        KeychainKind::External => Keychain::External,
        KeychainKind::Internal => Keychain::Internal,
    }
}

fn to_bdk_keychain(k: Keychain) -> KeychainKind {
    match k {
        Keychain::External => KeychainKind::External,
        Keychain::Internal => KeychainKind::Internal,
    }
}

/// Addresses of `keychain` at `start..start + count`, without revealing them.
/// An address is used if its script holds a UTXO or appears in any wallet
/// transaction output (Dart `usedScriptHexes`).
pub fn derived_addresses(
    wallet: &Wallet,
    keychain: Keychain,
    start: u32,
    count: u32,
) -> Vec<DerivedAddressInfo> {
    let used = used_scripts(wallet);
    index_range(start, count)
        .map(|i| {
            let info = wallet.peek_address(to_bdk_keychain(keychain), i);
            let script = info.address.script_pubkey();
            DerivedAddressInfo {
                keychain,
                index: i,
                address: info.address.to_string(),
                unconfidential: None,
                script_hex: hex(script.as_bytes()),
                used: used.contains(&script),
            }
        })
        .collect()
}

/// Unspent wallet outputs with their address and derivation.
pub fn unspent_outputs(wallet: &Wallet) -> Vec<WalletUtxoInfo> {
    wallet
        .list_unspent()
        .filter(|u| !u.is_spent)
        .map(|u| {
            let (height, time) = match &u.chain_position {
                ChainPosition::Confirmed { anchor, .. } => {
                    (Some(anchor.block_id.height), Some(anchor.confirmation_time))
                }
                ChainPosition::Unconfirmed { .. } => (None, None),
            };
            let address = Address::from_script(&u.txout.script_pubkey, wallet.network())
                .map(|a| a.to_string())
                .unwrap_or_default();
            WalletUtxoInfo {
                txid: u.outpoint.txid.to_string(),
                vout: u.outpoint.vout,
                address,
                unconfidential: None,
                script_hex: hex(u.txout.script_pubkey.as_bytes()),
                keychain: to_keychain(u.keychain),
                index: u.derivation_index,
                amount_sat: u.txout.value.to_sat(),
                asset_id: None,
                confirmation_height: height,
                confirmation_time_s: time,
            }
        })
        .collect()
}

/// Derivation of `address` if the wallet owns it.
///
/// BDK knows the scripts up to the last revealed index plus the lookahead,
/// so an owned address past that window reports `None`, as `isMine` did in Dart.
/// Fails for an unparseable address or one of another network.
pub fn address_ownership(wallet: &Wallet, address: &str) -> Result<Option<AddressOwnership>> {
    let parsed = Address::from_str(address.trim())
        .and_then(|a| a.require_network(wallet.network()))
        .map_err(|e| Error::invalid(format!("invalid bitcoin address: {e}")))?;
    Ok(wallet
        .derivation_of_spk(parsed.script_pubkey())
        .map(|(k, index)| AddressOwnership {
            keychain: to_keychain(k),
            index,
        }))
}

/// Signers for the receive and change descriptors.
fn build_signers(desc: &BitcoinDescriptors, network: AppNetwork) -> Result<Vec<SignersContainer>> {
    let secp = Secp256k1::new();
    [desc.external.as_str(), desc.internal.as_str()]
        .into_iter()
        .map(|d| {
            let (public, keymap) = d
                .into_wallet_descriptor(&secp, bitcoin_network_kind(network))
                .map_err(svc)?;
            Ok(SignersContainer::build(keymap, &public, &secp))
        })
        .collect()
}

/// Rejects requests this service cannot handle, with the Dart messages.
fn check_request(request: &SendRequest, verb: &str) -> Result<()> {
    if request.chain != CHAIN {
        return Err(svc(format!(
            "bitcoin service only handles Bitcoin on-chain {verb} (got: {})",
            request.chain.as_str()
        )));
    }
    if let Some(a) = &request.asset_id {
        return Err(svc(format!(
            "bitcoin service does not handle asset sends (got assetId: {a})"
        )));
    }
    Ok(())
}

/// Builds an unsigned PSBT. Port of `_buildPsbt`.
///
/// `drain` or `subtract_fee_from_amount` drains the whole wallet to the
/// destination and ignores `amount_sat`. A fee-rate override is rounded up
/// to whole sat/vB; without it BDK uses its default rate.
pub fn build_psbt(wallet: &mut Wallet, request: &SendRequest) -> Result<Psbt> {
    let address = Address::from_str(request.destination.trim())
        .and_then(|a| a.require_network(wallet.network()))
        .map_err(|e| svc(format!("invalid address: {e}")))?;
    let script = address.script_pubkey();
    let mut builder = wallet.build_tx();
    if request.drain || request.subtract_fee_from_amount {
        builder.drain_wallet().drain_to(script);
    } else {
        builder.add_recipient(script, Amount::from_sat(request.amount_sat));
    }
    if let Some(rate) = request.fee_rate_override_sat_per_vbyte {
        builder.fee_rate(FeeRate::from_sat_per_vb_u32(
            rate.ceil().clamp(0.0, u32::MAX as f64) as u32,
        ));
    }
    builder
        .finish()
        .map_err(|e| svc(format!("bdk build PSBT failed: {e}")))
}

/// Reviewed on-chain send. Port of `PreparedOnchainBitcoinTransaction`.
#[derive(Debug, Clone, PartialEq)]
pub struct PreparedBitcoinSend {
    pub destination: String,
    /// For a drain: total value of the wallet inputs spent (legacy `details.sent`).
    pub amount_sat: u64,
    pub network_fee_sat: u64,
    pub drain: bool,
    pub fee_rate_sat_per_vbyte: Option<u64>,
}

/// BDK wallet plus esplora client. Port of `BitcoinWalletServiceImpl`.
pub struct BitcoinWallet<K: KvStore, C: Clock> {
    wallet: Wallet,
    /// Software signers for both keychains. Built from the mnemonic at connect.
    signers: Vec<SignersContainer>,
    network: AppNetwork,
    kv: K,
    clock: C,
    persisted: ChangeSet,
    endpoints: EndpointResolver,
    client: Option<(String, AsyncClient<NoopSleeper>)>,
    backend: ChainBackend,
    #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
    electrum: Option<BitcoinElectrum>,
    needs_full_scan: bool,
    stop_gap: usize,
    tracker: TxTracker,
    last_list: Vec<Transaction>,
    last_balance: Balance,
    state: ServiceState,
}

impl<K: KvStore, C: Clock> BitcoinWallet<K, C> {
    /// Loads the wallet from `kv`, or creates it if the store is empty.
    /// Primes balance and history from the stored state (cold restore).
    /// Port of `connect`.
    pub async fn connect(
        credentials: &WalletCredentials,
        kv: K,
        clock: C,
        endpoints: EndpointResolver,
    ) -> Result<Self> {
        if credentials.is_absent() {
            return Err(Error::Credential("mnemonic is empty".into()));
        }
        let network = credentials.network;
        let desc = bitcoin_descriptors(&credentials.mnemonic, network)
            .map_err(|e| svc(format!("bdk init failed: {e}")))?;
        let stored = kv.get(CHANGESET_KEY).await?;
        let (wallet, persisted) = match stored {
            Some(bytes) => {
                let cs: ChangeSet = serde_json::from_slice(&bytes).map_err(Error::storage)?;
                let loaded = Wallet::load()
                    .descriptor(KeychainKind::External, Some(desc.external.clone()))
                    .descriptor(KeychainKind::Internal, Some(desc.internal.clone()))
                    .check_network(bitcoin_network(network))
                    .lookahead(LOOKAHEAD)
                    .load_wallet_no_persist(cs.clone())
                    .map_err(|e| svc(format!("bdk init failed: {e}")))?;
                match loaded {
                    Some(w) => (w, cs),
                    None => (
                        Self::create(&desc.external, &desc.internal, network)?,
                        ChangeSet::default(),
                    ),
                }
            }
            None => (
                Self::create(&desc.external, &desc.internal, network)?,
                ChangeSet::default(),
            ),
        };
        let now = clock.now_ms();
        let signers = build_signers(&desc, network)?;
        let mut this = Self {
            wallet,
            signers,
            network,
            kv,
            clock,
            persisted,
            endpoints,
            client: None,
            backend: ChainBackend::Esplora,
            #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
            electrum: None,
            needs_full_scan: true,
            stop_gap: DEFAULT_STOP_GAP,
            tracker: TxTracker::new(),
            last_list: Vec::new(),
            last_balance: Balance::default(),
            state: ServiceState::default(),
        };
        this.persist().await?;
        this.refresh_cache(now);
        this.tracker.prime(&this.last_list);
        this.state = ServiceState {
            lifecycle: ServiceLifecycle::Connected,
            failure: None,
            last_sync_at_ms: None,
        };
        Ok(this)
    }

    fn create(external: &str, internal: &str, network: AppNetwork) -> Result<Wallet> {
        Wallet::create(external.to_owned(), internal.to_owned())
            .network(bitcoin_network(network))
            .lookahead(LOOKAHEAD)
            .create_wallet_no_persist()
            .map_err(|e| svc(format!("bdk init failed: {e}")))
    }

    /// Switches the chain backend. Drops cached connections.
    ///
    /// Electrum needs the `electrum` feature and a native target. Pair the
    /// switch with matching endpoints, for example
    /// [`EndpointResolver::with_electrum_defaults`].
    pub fn set_backend(
        &mut self,
        backend: ChainBackend,
        endpoints: EndpointResolver,
    ) -> Result<()> {
        ensure_backend_supported(&backend)?;
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
    async fn electrum_client(
        &mut self,
        config: &ElectrumConfig,
        what: &str,
    ) -> Result<BitcoinElectrum> {
        let url = self.endpoints.current(CHAIN)?.to_owned();
        if let Some(c) = &self.electrum {
            if c.url() == url {
                return Ok(c.clone());
            }
        }
        match BitcoinElectrum::connect(&url, config).await {
            Ok(c) => {
                self.electrum = Some(c.clone());
                Ok(c)
            }
            Err(e) => Err(self.net_err(what, e)),
        }
    }

    /// Records an Electrum failure. Drops the connection so the next call
    /// reconnects, possibly to the next endpoint.
    #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
    fn electrum_err(&mut self, what: &str, e: impl std::fmt::Display) -> Error {
        self.electrum = None;
        self.net_err(what, e)
    }

    /// Fetches a scan update through the configured backend.
    async fn fetch_update(&mut self, full: bool, start_s: u64) -> Result<bdk_wallet::Update> {
        #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
        if let ChainBackend::Electrum(config) = self.backend.clone() {
            let client = self.electrum_client(&config, "bdk sync failed").await?;
            let result = if full {
                client
                    .full_scan(
                        self.wallet.start_full_scan_at(start_s).build(),
                        self.stop_gap,
                    )
                    .await
            } else {
                client
                    .sync(
                        self.wallet
                            .start_sync_with_revealed_spks_at(start_s)
                            .build(),
                    )
                    .await
            };
            return result.map_err(|e| self.electrum_err("bdk sync failed", e));
        }
        let client = self.client()?;
        if full {
            let req = self.wallet.start_full_scan_at(start_s).build();
            match client
                .full_scan(req, self.stop_gap, PARALLEL_REQUESTS)
                .await
            {
                Ok(u) => Ok(u.into()),
                Err(e) => Err(self.net_err("bdk sync failed", e)),
            }
        } else {
            let req = self
                .wallet
                .start_sync_with_revealed_spks_at(start_s)
                .build();
            match client.sync(req, PARALLEL_REQUESTS).await {
                Ok(u) => Ok(u.into()),
                Err(e) => Err(self.net_err("bdk sync failed", e)),
            }
        }
    }

    /// Sets the full-scan stop gap (default 20).
    pub fn set_stop_gap(&mut self, stop_gap: usize) {
        self.stop_gap = stop_gap;
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

    /// Underlying BDK wallet, read-only.
    pub fn bdk(&self) -> &Wallet {
        &self.wallet
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

    /// Writes staged BDK changes, merged into the stored `ChangeSet`.
    pub async fn persist(&mut self) -> Result<()> {
        if let Some(staged) = self.wallet.take_staged() {
            self.persisted.merge(staged);
            let bytes = serde_json::to_vec(&self.persisted).map_err(Error::storage)?;
            self.kv.put(CHANGESET_KEY, bytes).await?;
        }
        Ok(())
    }

    fn refresh_cache(&mut self, now_ms: u64) {
        let mut mapped: Vec<Transaction> = tx_views(&self.wallet)
            .iter()
            .map(|v| map_tx(v, now_ms))
            .collect();
        sort_newest_first(&mut mapped);
        self.last_list = mapped;
        self.last_balance = map_balance(&self.wallet.balance(), now_ms);
    }

    fn client(&mut self) -> Result<AsyncClient<NoopSleeper>> {
        let url = self.endpoints.current(CHAIN)?.to_owned();
        match &self.client {
            Some((u, c)) if *u == url => Ok(c.clone()),
            _ => {
                let c = esplora_client(&url)?;
                self.client = Some((url, c.clone()));
                Ok(c)
            }
        }
    }

    fn net_err(&mut self, what: &str, e: impl std::fmt::Display) -> Error {
        self.endpoints.report_failure(CHAIN);
        svc(format!("{what}: {e}"))
    }

    /// Full scan on the first call of the session, then revealed-script
    /// syncs. Applies the update, persists, diffs and queues events.
    /// Port of `sync`. NOTE(port): the 60 s Dart timeout is the platform's job.
    pub async fn sync(&mut self) -> Result<SyncOutcome> {
        let t0 = self.clock.now_ms();
        let start_s = t0 / 1000;
        let full = self.needs_full_scan;
        let update = self.fetch_update(full, start_s).await?;
        self.endpoints.report_success(CHAIN);
        self.wallet
            .apply_update(update)
            .map_err(|e| svc(format!("bdk sync failed: {e}")))?;
        self.persist().await?;
        if full {
            self.needs_full_scan = false;
        }
        let now = self.clock.now_ms();
        self.refresh_cache(now);
        let changed = self.tracker.diff(&self.last_list, now);
        let end = self.clock.now_ms();
        self.state = ServiceState {
            lifecycle: ServiceLifecycle::Connected,
            failure: None,
            last_sync_at_ms: Some(end),
        };
        Ok(SyncOutcome {
            chain: CHAIN,
            fetched: self.last_list.len(),
            changed,
            duration_ms: end.saturating_sub(t0),
        })
    }

    /// Chain tip height. Port of `getBlockHeight`.
    pub async fn block_height(&mut self) -> Result<u32> {
        #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
        if let ChainBackend::Electrum(config) = self.backend.clone() {
            let client = self
                .electrum_client(&config, "bdk getHeight failed")
                .await?;
            return match client.tip_height().await {
                Ok(h) => {
                    self.endpoints.report_success(CHAIN);
                    Ok(h)
                }
                Err(e) => Err(self.electrum_err("bdk getHeight failed", e)),
            };
        }
        let client = self.client()?;
        match client.get_height().await {
            Ok(h) => {
                self.endpoints.report_success(CHAIN);
                Ok(h)
            }
            Err(e) => Err(self.net_err("bdk getHeight failed", e)),
        }
    }

    /// Backend fee estimates mapped to low/medium/fast.
    pub async fn fee_estimates(&mut self) -> Result<BitcoinFeeEstimate> {
        #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
        if let ChainBackend::Electrum(config) = self.backend.clone() {
            let client = self
                .electrum_client(&config, "fee estimates failed")
                .await?;
            return match client.fee_estimates().await {
                Ok(m) => {
                    self.endpoints.report_success(CHAIN);
                    Ok(BitcoinFeeEstimate::from_esplora_targets(&m))
                }
                Err(e) => Err(self.electrum_err("fee estimates failed", e)),
            };
        }
        let client = self.client()?;
        match client.get_fee_estimates().await {
            Ok(m) => {
                self.endpoints.report_success(CHAIN);
                Ok(BitcoinFeeEstimate::from_esplora_targets(&m))
            }
            Err(e) => Err(self.net_err("fee estimates failed", e)),
        }
    }

    /// Fee of the PSBT the request would build. Port of `estimateFee`.
    pub async fn estimate_fee(&mut self, request: &SendRequest) -> Result<FeeEstimate> {
        check_request(request, "estimates")?;
        let psbt = build_psbt(&mut self.wallet, request)?;
        self.persist().await?;
        let fee = psbt
            .fee()
            .map_err(|e| svc(format!("bdk estimateFee failed: {e}")))?;
        Ok(FeeEstimate {
            chain: CHAIN,
            priority: request.fee_priority,
            absolute_fee_sat: fee.to_sat(),
            fee_rate_sat_per_vbyte: request.fee_rate_override_sat_per_vbyte,
            estimated_blocks: None,
        })
    }

    /// Builds a send for review. Port of the legacy
    /// `buildOnchainBitcoinPaymentTransaction` and
    /// `buildDrainOnchainBitcoinTransaction`.
    pub async fn prepare_send(
        &mut self,
        destination: &str,
        amount_sat: u64,
        drain: bool,
        fee_rate_sat_per_vbyte: Option<u64>,
    ) -> Result<PreparedBitcoinSend> {
        let mut req = SendRequest::new(CHAIN, destination, amount_sat);
        req.drain = drain;
        req.fee_rate_override_sat_per_vbyte = fee_rate_sat_per_vbyte.map(|r| r as f64);
        let psbt = build_psbt(&mut self.wallet, &req)?;
        self.persist().await?;
        let fee = psbt.fee().map_err(svc)?.to_sat();
        let amount = if drain {
            let tx = psbt.clone().extract_tx_unchecked_fee_rate();
            self.wallet.sent_and_received(&tx).0.to_sat()
        } else {
            amount_sat
        };
        Ok(PreparedBitcoinSend {
            destination: destination.to_owned(),
            amount_sat: amount,
            network_fee_sat: fee,
            drain,
            fee_rate_sat_per_vbyte,
        })
    }

    /// Next unused receive address. Port of `nextReceiveAddress`.
    pub async fn next_receive_address(
        &mut self,
        asset_id: Option<&str>,
        label: Option<&str>,
    ) -> Result<ReceiveAddress> {
        if let Some(a) = asset_id {
            return Err(svc(format!(
                "bitcoin service does not handle asset receives (got assetId: {a})"
            )));
        }
        let (_, address) = next_fresh_receive_address(&mut self.wallet, FRESH_ADDRESS_CAP)
            .map_err(|e| svc(format!("bdk nextReceiveAddress failed: {e}")))?;
        self.persist().await?;
        let mut r = ReceiveAddress::onchain(CHAIN, address.to_string());
        r.label = label.map(str::to_owned);
        Ok(r)
    }

    /// Next receive address with no on-chain history, with its index.
    ///
    /// Same walk as [`Self::next_receive_address`]: it reveals up to the
    /// chosen index and persists, as Dart `getNextUnusedBitcoinAddress` did.
    pub async fn next_unused_address(&mut self) -> Result<NextUnusedAddress> {
        let (index, address) = next_fresh_receive_address(&mut self.wallet, FRESH_ADDRESS_CAP)
            .map_err(|e| svc(format!("bdk nextUnusedAddress failed: {e}")))?;
        self.persist().await?;
        Ok(NextUnusedAddress {
            index,
            address: address.to_string(),
            used: false,
        })
    }

    /// Addresses of `keychain` at `start..start + count`. Reveals nothing.
    pub fn derived_addresses(
        &self,
        keychain: Keychain,
        start: u32,
        count: u32,
    ) -> Vec<DerivedAddressInfo> {
        derived_addresses(&self.wallet, keychain, start, count)
    }

    /// Unspent outputs with address, derivation and confirmation.
    pub fn unspent_outputs(&self) -> Vec<WalletUtxoInfo> {
        unspent_outputs(&self.wallet)
    }

    /// Derivation of `address` if the wallet owns it. See [`address_ownership`].
    pub fn is_mine(&self, address: &str) -> Result<Option<AddressOwnership>> {
        address_ownership(&self.wallet, address)
    }

    /// Builds and signs the request. Returns the raw transaction and its fee.
    pub async fn build_signed(
        &mut self,
        request: &SendRequest,
    ) -> Result<(bdk_wallet::bitcoin::Transaction, u64)> {
        check_request(request, "sends")?;
        let mut psbt = build_psbt(&mut self.wallet, request)?;
        self.persist().await?;
        let signers: Vec<&SignersContainer> = self.signers.iter().collect();
        let finalized = self
            .wallet
            .sign_with_signers(&mut psbt, &signers, SignOptions::default())
            .map_err(|e| svc(format!("bdk sendOnchain failed: {e}")))?;
        if !finalized {
            return Err(svc("bdk sign returned false (watch-only descriptor?)"));
        }
        let fee = psbt
            .fee()
            .map_err(|e| svc(format!("bdk sendOnchain failed: {e}")))?
            .to_sat();
        let tx = psbt
            .extract_tx()
            .map_err(|e| svc(format!("bdk sendOnchain failed: {e}")))?;
        Ok((tx, fee))
    }

    /// Builds, signs and broadcasts. Port of `sendOnchain`.
    pub async fn send_onchain(&mut self, request: &SendRequest) -> Result<BroadcastResult> {
        let (tx, fee) = self.build_signed(request).await?;
        self.broadcast_tx(&tx).await?;
        self.endpoints.report_success(CHAIN);
        let txid = tx.compute_txid().to_string();
        let now = self.clock.now_ms();
        // NOTE(port): amount is the requested amount even for a drain, as in Dart.
        let mut mapped = Transaction::new(
            txid.clone(),
            CHAIN,
            TransactionDirection::Outgoing,
            TransactionStatus::Pending,
            request.amount_sat as i64,
            fee as i64,
            now,
        );
        mapped.address = Some(request.destination.clone());
        mapped.label = request.label.clone();
        mapped.source = Some(TransactionSource::Bdk);
        self.tracker.force_register(&mapped, now);
        self.last_list.insert(0, mapped.clone());
        Ok(BroadcastResult {
            chain: CHAIN,
            tx_id: txid,
            transaction: mapped,
            fee_paid_sat: Some(fee),
        })
    }

    /// Broadcasts through the configured backend.
    async fn broadcast_tx(&mut self, tx: &bdk_wallet::bitcoin::Transaction) -> Result<()> {
        #[cfg(all(feature = "electrum", not(target_arch = "wasm32")))]
        if let ChainBackend::Electrum(config) = self.backend.clone() {
            let client = self
                .electrum_client(&config, "bdk sendOnchain failed")
                .await?;
            return match client.broadcast(tx.clone()).await {
                Ok(_) => Ok(()),
                Err(e) => Err(self.electrum_err("bdk sendOnchain failed", e)),
            };
        }
        let client = self.client()?;
        match client.broadcast(tx).await {
            Ok(()) => Ok(()),
            Err(e) => Err(self.net_err("bdk sendOnchain failed", e)),
        }
    }

    /// Adds a transaction broadcast elsewhere. Idempotent by id.
    /// Port of `registerExternalBroadcast`.
    pub fn register_external_broadcast(&mut self, tx: Transaction) {
        if tx.chain != CHAIN {
            return;
        }
        let now = self.clock.now_ms();
        if self.tracker.register(&tx, now) {
            self.last_list.insert(0, tx);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{block_on, FixedClock, MemoryKv};

    const ABANDON: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    fn view(sent: u64, received: u64, fee: Option<u64>, time: Option<u64>) -> BdkTxView {
        BdkTxView {
            txid: "t".into(),
            sent_sat: sent,
            received_sat: received,
            fee_sat: fee,
            confirmation_time_s: time,
            confirmation_height: time.map(|_| 800_000),
        }
    }

    #[test]
    fn map_tx_classification() {
        let t = map_tx(&view(0, 5_000, None, Some(1_700_000_000)), 9);
        assert_eq!(t.direction, TransactionDirection::Incoming);
        assert_eq!((t.amount_sat, t.fee_sat), (5_000, 0));
        assert_eq!(
            (t.status, t.confirmations, t.timestamp_ms),
            (TransactionStatus::Confirmed, 1, 1_700_000_000_000)
        );
        assert_eq!(t.source, Some(TransactionSource::Bdk));

        let t = map_tx(&view(10_000, 0, Some(200), None), 9);
        assert_eq!(
            (t.direction, t.amount_sat),
            (TransactionDirection::Outgoing, 10_000)
        );
        assert_eq!(
            (t.status, t.confirmations, t.timestamp_ms),
            (TransactionStatus::Pending, 0, 9)
        );

        // Payment with change: sent 10_000, change 3_000, fee 200.
        let t = map_tx(&view(10_000, 3_000, Some(200), None), 9);
        assert_eq!(
            (t.direction, t.amount_sat),
            (TransactionDirection::Outgoing, 7_000)
        );

        // Consolidation: change equals inputs minus fee.
        let t = map_tx(&view(10_000, 9_800, Some(200), None), 9);
        assert_eq!(
            (t.direction, t.amount_sat),
            (TransactionDirection::SelfTransfer, 200)
        );
        // Slack: fee 5_000 -> slack 50.
        let t = map_tx(&view(100_000, 94_950, Some(5_000), None), 9);
        assert_eq!(t.direction, TransactionDirection::SelfTransfer);
        let t = map_tx(&view(100_000, 94_900, Some(5_000), None), 9);
        assert_eq!(
            (t.direction, t.amount_sat),
            (TransactionDirection::Outgoing, 5_100)
        );

        // Received more than sent (payjoin-like).
        let t = map_tx(&view(1_000, 4_000, Some(100), None), 9);
        assert_eq!(
            (t.direction, t.amount_sat),
            (TransactionDirection::Incoming, 3_000)
        );

        let t = map_tx(&view(0, 0, None, None), 9);
        assert_eq!(
            (t.direction, t.amount_sat),
            (TransactionDirection::Internal, 0)
        );
    }

    #[test]
    fn map_balance_sums_pending() {
        let b = bdk_wallet::Balance {
            immature: Amount::from_sat(1),
            trusted_pending: Amount::from_sat(10),
            untrusted_pending: Amount::from_sat(100),
            confirmed: Amount::from_sat(1_000),
        };
        let m = map_balance(&b, 7);
        assert_eq!(m.assets.len(), 1);
        let a = &m.assets[0];
        assert_eq!(
            (a.amount_sat, a.pending_sat, a.asset_id.clone()),
            (1_111, 111, None)
        );
        assert_eq!(a.ticker.as_deref(), Some("BTC"));
        assert_eq!(m.snapshot_at_ms, 7);
    }

    fn creds() -> WalletCredentials {
        WalletCredentials {
            mnemonic: ABANDON.into(),
            network: AppNetwork::Mainnet,
        }
    }

    fn connect(kv: MemoryKv) -> BitcoinWallet<MemoryKv, FixedClock> {
        block_on(BitcoinWallet::connect(
            &creds(),
            kv,
            FixedClock::new(1_000),
            EndpointResolver::with_defaults(AppNetwork::Mainnet),
        ))
        .unwrap()
    }

    #[test]
    fn receive_addresses_advance_and_persist() {
        let kv = MemoryKv::new();
        let mut w = connect(kv.clone());
        assert!(w.state().is_operational());
        let a0 = block_on(w.next_receive_address(None, Some("x"))).unwrap();
        assert_eq!(
            a0.address.as_deref(),
            Some("bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu")
        );
        assert_eq!(a0.label.as_deref(), Some("x"));
        // Unused address is handed out again.
        let again = block_on(w.next_receive_address(None, None)).unwrap();
        assert_eq!(again.address, a0.address);
        assert!(block_on(w.next_receive_address(Some("lbtc"), None)).is_err());

        // ChangeSet roundtrip: reload from the same store.
        let raw = block_on(kv.get(CHANGESET_KEY)).unwrap().unwrap();
        let cs: ChangeSet = serde_json::from_slice(&raw).unwrap();
        assert_eq!(cs.indexer.last_revealed.len(), 1);
        drop(w);
        let w2 = connect(kv.clone());
        assert_eq!(w2.bdk().derivation_index(KeychainKind::External), Some(0));
        assert!(w2.list_transactions().is_empty());
        assert_eq!(w2.balance().total_sat_for_chain(ChainId::Bitcoin), 0);
    }

    #[test]
    fn rejects_other_chains_and_assets_and_bad_addresses() {
        let mut w = connect(MemoryKv::new());
        let liquid = SendRequest::new(ChainId::Liquid, "lq1x", 1);
        let e = block_on(w.estimate_fee(&liquid)).unwrap_err();
        assert!(
            e.to_string()
                .contains("only handles Bitcoin on-chain estimates (got: liquid)"),
            "{e}"
        );
        let mut asset = SendRequest::new(ChainId::Bitcoin, "bc1q", 1);
        asset.asset_id = Some("x".into());
        assert!(block_on(w.send_onchain(&asset))
            .unwrap_err()
            .to_string()
            .contains("asset sends"));
        let bad = SendRequest::new(ChainId::Bitcoin, "not-an-address", 1);
        assert!(block_on(w.estimate_fee(&bad))
            .unwrap_err()
            .to_string()
            .contains("invalid address"));
        let testnet = SendRequest::new(
            ChainId::Bitcoin,
            "tb1qcr8te4kr609gcawutmrza0j4xv80jy8zeqchgx",
            1,
        );
        assert!(block_on(w.estimate_fee(&testnet))
            .unwrap_err()
            .to_string()
            .contains("invalid address"));
        // Empty wallet cannot fund a send.
        let ok = SendRequest::new(
            ChainId::Bitcoin,
            "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g",
            1_000,
        );
        assert!(block_on(w.estimate_fee(&ok))
            .unwrap_err()
            .to_string()
            .contains("bdk build PSBT failed"));
    }

    #[test]
    fn register_external_broadcast_is_idempotent() {
        let mut w = connect(MemoryKv::new());
        let tx = Transaction::new(
            "ext",
            ChainId::Bitcoin,
            TransactionDirection::Outgoing,
            TransactionStatus::Pending,
            5,
            1,
            1,
        );
        w.register_external_broadcast(tx.clone());
        w.register_external_broadcast(tx.clone());
        let mut liquid = tx;
        liquid.chain = ChainId::Liquid;
        liquid.id = "l".into();
        w.register_external_broadcast(liquid);
        assert_eq!(w.list_transactions().len(), 1);
        assert_eq!(w.take_events().len(), 1);
    }

    #[test]
    fn corrupt_changeset_is_a_storage_error() {
        let kv = MemoryKv::new();
        block_on(kv.put(CHANGESET_KEY, b"{not json".to_vec())).unwrap();
        let r = block_on(BitcoinWallet::connect(
            &creds(),
            kv,
            FixedClock::new(0),
            EndpointResolver::with_defaults(AppNetwork::Mainnet),
        ));
        assert!(matches!(r, Err(Error::Storage(_))));
    }

    /// Funds the wallet with an unconfirmed output to its first address.
    fn fund(w: &mut BitcoinWallet<MemoryKv, FixedClock>, sats: u64) {
        use bdk_wallet::bitcoin::{absolute, transaction, OutPoint, TxIn, TxOut};
        let to = w.wallet.peek_address(KeychainKind::External, 0).address;
        let tx = bdk_wallet::bitcoin::Transaction {
            version: transaction::Version::TWO,
            lock_time: absolute::LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint::new(
                    "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"
                        .parse()
                        .unwrap(),
                    0,
                ),
                ..Default::default()
            }],
            output: vec![TxOut {
                value: Amount::from_sat(sats),
                script_pubkey: to.script_pubkey(),
            }],
        };
        w.wallet.apply_unconfirmed_txs([(tx, 1)]);
        w.refresh_cache(5);
    }

    #[test]
    fn builds_and_signs_sends_and_drains() {
        let mut w = connect(MemoryKv::new());
        fund(&mut w, 100_000);
        assert_eq!(w.balance().pending_sat_for_chain(ChainId::Bitcoin), 100_000);
        assert_eq!(
            w.list_transactions()[0].direction,
            TransactionDirection::Incoming
        );
        let dest = "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g";

        let mut req = SendRequest::new(ChainId::Bitcoin, dest, 30_000);
        req.fee_rate_override_sat_per_vbyte = Some(1.2);
        let est = block_on(w.estimate_fee(&req)).unwrap();
        // One P2WPKH input, two outputs at 2 sat/vB (1.2 rounded up).
        assert!(
            est.absolute_fee_sat >= 2 * 140 && est.absolute_fee_sat <= 2 * 145,
            "{}",
            est.absolute_fee_sat
        );
        assert_eq!(est.fee_rate_sat_per_vbyte, Some(1.2));

        let (tx, fee) = block_on(w.build_signed(&req)).unwrap();
        assert_eq!(tx.output.len(), 2);
        assert!(tx.input[0].witness.len() == 2, "input is signed");
        assert!(tx.output.iter().any(|o| o.value.to_sat() == 30_000));
        assert_eq!(fee, est.absolute_fee_sat);

        // Drain: one output, value = balance - fee; prepared amount = inputs.
        let p = block_on(w.prepare_send(dest, 0, true, Some(3))).unwrap();
        assert!(p.drain);
        assert_eq!(p.amount_sat, 100_000);
        let mut drain = SendRequest::new(ChainId::Bitcoin, dest, 0);
        drain.subtract_fee_from_amount = true;
        drain.fee_rate_override_sat_per_vbyte = Some(3.0);
        let (tx, fee) = block_on(w.build_signed(&drain)).unwrap();
        assert_eq!(tx.output.len(), 1);
        assert_eq!(tx.output[0].value.to_sat(), 100_000 - fee);
        assert_eq!(fee, p.network_fee_sat);
    }

    const ADDR0: &str = "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu";
    const ADDR1: &str = "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g";
    const CHANGE0: &str = "bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el";

    #[test]
    fn derived_addresses_follow_bip84_and_reveal_nothing() {
        let w = connect(MemoryKv::new());
        let ext = w.derived_addresses(Keychain::External, 0, 2);
        assert_eq!(
            ext.iter().map(|a| a.address.as_str()).collect::<Vec<_>>(),
            [ADDR0, ADDR1]
        );
        assert_eq!(ext.iter().map(|a| a.index).collect::<Vec<_>>(), [0, 1]);
        assert!(ext
            .iter()
            .all(|a| !a.used && a.keychain == Keychain::External && a.unconfidential.is_none()));
        assert!(
            ext[0].script_hex.starts_with("0014") && ext[0].script_hex.len() == 44,
            "{}",
            ext[0].script_hex
        );
        let int = w.derived_addresses(Keychain::Internal, 0, 1);
        assert_eq!(
            (int[0].address.as_str(), int[0].keychain),
            (CHANGE0, Keychain::Internal)
        );
        let page = w.derived_addresses(Keychain::External, 1, 1);
        assert_eq!(page[0].address, ADDR1);
        assert!(w.derived_addresses(Keychain::External, 0, 0).is_empty());
        assert_eq!(w.bdk().derivation_index(KeychainKind::External), None);
    }

    #[test]
    fn is_mine_reports_keychain_and_index() {
        let w = connect(MemoryKv::new());
        assert_eq!(
            w.is_mine(ADDR1).unwrap(),
            Some(AddressOwnership {
                keychain: Keychain::External,
                index: 1
            })
        );
        assert_eq!(
            w.is_mine(CHANGE0).unwrap(),
            Some(AddressOwnership {
                keychain: Keychain::Internal,
                index: 0
            })
        );
        // Foreign mainnet address.
        assert_eq!(
            w.is_mine("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq")
                .unwrap(),
            None
        );
        // Past the lookahead window (no index revealed yet).
        let far = w
            .wallet
            .peek_address(KeychainKind::External, LOOKAHEAD + 5)
            .address
            .to_string();
        assert_eq!(w.is_mine(&far).unwrap(), None);
        assert!(matches!(
            w.is_mine("not-an-address"),
            Err(Error::InvalidInput(_))
        ));
        assert!(matches!(
            w.is_mine("tb1qcr8te4kr609gcawutmrza0j4xv80jy8zeqchgx"),
            Err(Error::InvalidInput(_))
        ));
    }

    #[test]
    fn utxos_used_flags_and_next_unused_follow_history() {
        let mut w = connect(MemoryKv::new());
        assert!(w.unspent_outputs().is_empty());
        let first = block_on(w.next_unused_address()).unwrap();
        assert_eq!(
            first,
            NextUnusedAddress {
                index: 0,
                address: ADDR0.into(),
                used: false
            }
        );

        fund(&mut w, 42_000);
        let utxos = w.unspent_outputs();
        assert_eq!(utxos.len(), 1);
        let u = &utxos[0];
        assert_eq!(
            (u.address.as_str(), u.keychain, u.index, u.amount_sat),
            (ADDR0, Keychain::External, 0, 42_000)
        );
        assert_eq!(
            (u.vout, u.asset_id.clone(), u.is_confirmed()),
            (0, None, false)
        );
        assert_eq!(u.outpoint(), format!("{}:0", u.txid));
        assert_eq!(
            u.script_hex,
            w.derived_addresses(Keychain::External, 0, 1)[0].script_hex
        );

        let ext = w.derived_addresses(Keychain::External, 0, 2);
        assert_eq!((ext[0].used, ext[1].used), (true, false));

        // Index 0 has history: the walk moves to index 1 and reveals it.
        let next = block_on(w.next_unused_address()).unwrap();
        assert_eq!(
            next,
            NextUnusedAddress {
                index: 1,
                address: ADDR1.into(),
                used: false
            }
        );
        assert_eq!(w.bdk().derivation_index(KeychainKind::External), Some(1));
        // Unused: the same address comes back.
        assert_eq!(block_on(w.next_unused_address()).unwrap().index, 1);
    }

    #[test]
    fn futures_are_send_on_native() {
        fn assert_send<T: Send>(_: &T) {}
        let mut w = connect(MemoryKv::new());
        let f = w.sync();
        assert_send(&f);
        drop(f);
        let req = SendRequest::new(ChainId::Bitcoin, "bc1q", 1);
        let f = w.send_onchain(&req);
        assert_send(&f);
        drop(f);
        let f = w.fee_estimates();
        assert_send(&f);
    }

    #[test]
    fn noop_sleeper_is_ready() {
        let f = NoopSleeper::sleep(Duration::from_secs(60));
        block_on(f);
        assert!(esplora_client("https://blockstream.info/api").is_ok());
    }
}
