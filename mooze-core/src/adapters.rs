//! Glue between modules.
//!
//! Each feature module defines small traits for what it needs from other
//! modules (a token, an address, a signature). This module implements those
//! traits with the real services, so a platform can wire the app together.
//!
//! - [`SessionTokens`]: `auth` session for `pix`.
//! - [`LiquidService`]: Liquid wallet for `sync`, `sideswap` and `pix`.
//! - [`BitcoinService`]: Bitcoin wallet for `sync`.
//! - [`WalletPeg`]: both wallets for `peg`.
//!
//! The wallets take `&mut self`. The services keep each wallet behind an
//! async mutex, so callers share one service through `&self` or `Arc`.

// Trait impls return explicit futures so the MaybeSend bound stays visible.
#![allow(clippy::manual_async_fn)]

use std::future::Future;
use std::sync::{Arc, Mutex as StdMutex};

use futures::lock::{Mutex, MutexGuard};

use crate::api::SessionProvider;
use crate::domain::{
    ChainId, LiquidSendDraft, LiquidUtxo, SendRequest, ServiceLifecycle, SyncOutcome, Transaction, WalletCredentials,
};
use crate::peg::{PegError, PegFundingQuote, PegWallet};
use crate::pix::{AddressProvider, TokenProvider};
use crate::ports::{Clock, KvStore, MaybeSend, SecureStore};
use crate::sideswap::SwapSigner;
use crate::store::CredentialStore;
use crate::sync::ChainSyncer;
use crate::wallet::bitcoin::PreparedBitcoinSend;
use crate::wallet::{BitcoinWallet, ChainBackend, EndpointResolver, LiquidWallet};
use crate::{Error, Result};

/// Gives the `auth` session token to modules that need a bearer token.
#[derive(Debug, Clone)]
pub struct SessionTokens<P>(pub P);

impl<P: SessionProvider> TokenProvider for SessionTokens<P> {
    fn token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
        self.0.access_token()
    }
}

/// Wallet slot shared by both services: the wallet, if connected, and a
/// lifecycle snapshot readable without awaiting the async lock.
struct Slot<W> {
    wallet: Mutex<Option<W>>,
    lifecycle: StdMutex<ServiceLifecycle>,
}

impl<W> Slot<W> {
    fn new() -> Self {
        Self { wallet: Mutex::new(None), lifecycle: StdMutex::new(ServiceLifecycle::Uninitialized) }
    }

    fn lifecycle(&self) -> ServiceLifecycle {
        *self.lifecycle.lock().expect("lifecycle lock poisoned")
    }

    fn set_lifecycle(&self, value: ServiceLifecycle) {
        *self.lifecycle.lock().expect("lifecycle lock poisoned") = value;
    }

    async fn guard(&self) -> MutexGuard<'_, Option<W>> {
        self.wallet.lock().await
    }
}

fn not_connected(chain: ChainId) -> Error {
    Error::InvalidState(format!("{} wallet not connected", chain.as_str()))
}

/// Liquid wallet service.
///
/// It loads the mnemonic from the credential store for each signature.
/// The mnemonic never stays in memory between calls.
pub struct LiquidService<K: KvStore + Clone, C: Clock + Clone, S: SecureStore> {
    slot: Slot<LiquidWallet<K, C>>,
    kv: K,
    clock: C,
    endpoints: EndpointResolver,
    backend: ChainBackend,
    credentials: CredentialStore<S>,
}

impl<K: KvStore + Clone, C: Clock + Clone, S: SecureStore> LiquidService<K, C, S> {
    /// Service without a connected wallet. Call [`ChainSyncer::connect`].
    pub fn new(kv: K, clock: C, endpoints: EndpointResolver, credentials: CredentialStore<S>) -> Self {
        Self { slot: Slot::new(), kv, clock, endpoints, backend: ChainBackend::Esplora, credentials }
    }

    /// Uses `backend` for every wallet this service connects.
    ///
    /// `endpoints` passed to [`Self::new`] must match it, for example
    /// [`EndpointResolver::with_electrum_defaults`] for Electrum.
    pub fn with_backend(mut self, backend: ChainBackend) -> Self {
        self.backend = backend;
        self
    }

    /// Runs `f` with the connected wallet.
    pub async fn with_wallet<T>(&self, f: impl FnOnce(&mut LiquidWallet<K, C>) -> T) -> Result<T> {
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(f(wallet))
    }

    /// Fresh receive address.
    pub async fn receive_address(&self) -> Result<String> {
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        wallet.receive_address().await
    }

    /// Unsigned L-BTC send. A drain sends the whole L-BTC balance.
    pub async fn build_lbtc_send(
        &self,
        destination: &str,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> Result<LiquidSendDraft> {
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        wallet.build_lbtc_send(destination, amount_sat, fee_rate_sat_per_vb, drain).await
    }

    /// Signs with the stored mnemonic and broadcasts. Returns the txid.
    pub async fn sign_and_broadcast(&self, pset: &str) -> Result<String> {
        let credentials = self.credentials.load().await?;
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        wallet.sign_and_broadcast_pset(pset, &credentials.mnemonic).await
    }
}

impl<K, C, S> ChainSyncer for LiquidService<K, C, S>
where
    K: KvStore + Clone,
    C: Clock + Clone,
    S: SecureStore,
    LiquidWallet<K, C>: MaybeSend,
{
    fn chain(&self) -> ChainId {
        ChainId::Liquid
    }

    fn lifecycle(&self) -> ServiceLifecycle {
        self.slot.lifecycle()
    }

    fn sync(&self, _timeout_ms: u64) -> impl Future<Output = Result<SyncOutcome>> + MaybeSend {
        async move {
            let mut guard = self.slot.guard().await;
            let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
            wallet.sync().await
        }
    }

    fn transactions(&self) -> impl Future<Output = Result<Vec<Transaction>>> + MaybeSend {
        self.with_wallet(|w| w.list_transactions().to_vec())
    }

    fn connect(&self, credentials: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend {
        let credentials = credentials.clone();
        async move {
            self.slot.set_lifecycle(ServiceLifecycle::Connecting);
            let made = LiquidWallet::connect(&credentials, self.kv.clone(), self.clock.clone(), self.endpoints.clone())
                .await;
            let made = made.and_then(|mut wallet| {
                if self.backend.is_electrum() {
                    wallet.set_backend(self.backend.clone(), self.endpoints.clone())?;
                }
                Ok(wallet)
            });
            match made {
                Ok(wallet) => {
                    *self.slot.guard().await = Some(wallet);
                    self.slot.set_lifecycle(ServiceLifecycle::Connected);
                    Ok(())
                }
                Err(e) => {
                    self.slot.set_lifecycle(ServiceLifecycle::Errored);
                    Err(e)
                }
            }
        }
    }

    fn disconnect(&self) -> impl Future<Output = Result<()>> + MaybeSend {
        async move {
            *self.slot.guard().await = None;
            self.slot.set_lifecycle(ServiceLifecycle::Disconnected);
            Ok(())
        }
    }
}

impl<K, C, S> SwapSigner for LiquidService<K, C, S>
where
    K: KvStore + Clone,
    C: Clock + Clone,
    S: SecureStore,
    LiquidWallet<K, C>: MaybeSend,
{
    fn liquid_utxos(&self) -> impl Future<Output = Result<Vec<LiquidUtxo>>> + MaybeSend {
        async move { self.with_wallet(|w| w.utxos()).await? }
    }

    fn swap_address(&self) -> impl Future<Output = Result<String>> + MaybeSend {
        self.receive_address()
    }

    fn sign_swap_pset(&self, pset_b64: &str) -> impl Future<Output = Result<String>> + MaybeSend {
        let pset = pset_b64.to_owned();
        async move {
            let credentials = self.credentials.load().await?;
            self.with_wallet(|w| w.sign_swap_pset(&pset, &credentials.mnemonic)).await?
        }
    }
}

impl<K, C, S> AddressProvider for LiquidService<K, C, S>
where
    K: KvStore + Clone,
    C: Clock + Clone,
    S: SecureStore,
    LiquidWallet<K, C>: MaybeSend,
{
    fn liquid_receive_address(&self) -> impl Future<Output = Result<String>> + MaybeSend {
        self.receive_address()
    }
}

/// Bitcoin wallet service. BDK holds the signing keys after connect.
pub struct BitcoinService<K: KvStore + Clone, C: Clock + Clone> {
    slot: Slot<BitcoinWallet<K, C>>,
    kv: K,
    clock: C,
    endpoints: EndpointResolver,
    backend: ChainBackend,
}

impl<K: KvStore + Clone, C: Clock + Clone> BitcoinService<K, C> {
    /// Service without a connected wallet. Call [`ChainSyncer::connect`].
    pub fn new(kv: K, clock: C, endpoints: EndpointResolver) -> Self {
        Self { slot: Slot::new(), kv, clock, endpoints, backend: ChainBackend::Esplora }
    }

    /// Uses `backend` for every wallet this service connects.
    ///
    /// `endpoints` passed to [`Self::new`] must match it, for example
    /// [`EndpointResolver::with_electrum_defaults`] for Electrum.
    pub fn with_backend(mut self, backend: ChainBackend) -> Self {
        self.backend = backend;
        self
    }

    /// Runs `f` with the connected wallet.
    pub async fn with_wallet<T>(&self, f: impl FnOnce(&mut BitcoinWallet<K, C>) -> T) -> Result<T> {
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(f(wallet))
    }

    /// Fresh receive address.
    pub async fn receive_address(&self) -> Result<String> {
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        let r = wallet.next_receive_address(None, None).await?;
        r.address.ok_or_else(|| Error::service(ChainId::Bitcoin, "wallet returned no address"))
    }

    /// Sizes a send without signing it.
    pub async fn prepare_send(
        &self,
        destination: &str,
        amount_sat: u64,
        drain: bool,
        fee_rate_sat_per_vbyte: Option<u64>,
    ) -> Result<PreparedBitcoinSend> {
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        wallet.prepare_send(destination, amount_sat, drain, fee_rate_sat_per_vbyte).await
    }

    /// Builds, signs and broadcasts. Returns the txid.
    pub async fn send(&self, request: &SendRequest) -> Result<String> {
        let mut guard = self.slot.guard().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(wallet.send_onchain(request).await?.tx_id)
    }
}

impl<K, C> ChainSyncer for BitcoinService<K, C>
where
    K: KvStore + Clone,
    C: Clock + Clone,
    BitcoinWallet<K, C>: MaybeSend,
{
    fn chain(&self) -> ChainId {
        ChainId::Bitcoin
    }

    fn lifecycle(&self) -> ServiceLifecycle {
        self.slot.lifecycle()
    }

    fn sync(&self, _timeout_ms: u64) -> impl Future<Output = Result<SyncOutcome>> + MaybeSend {
        async move {
            let mut guard = self.slot.guard().await;
            let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
            wallet.sync().await
        }
    }

    fn transactions(&self) -> impl Future<Output = Result<Vec<Transaction>>> + MaybeSend {
        self.with_wallet(|w| w.list_transactions().to_vec())
    }

    fn connect(&self, credentials: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend {
        let credentials = credentials.clone();
        async move {
            self.slot.set_lifecycle(ServiceLifecycle::Connecting);
            let made = BitcoinWallet::connect(&credentials, self.kv.clone(), self.clock.clone(), self.endpoints.clone())
                .await;
            let made = made.and_then(|mut wallet| {
                if self.backend.is_electrum() {
                    wallet.set_backend(self.backend.clone(), self.endpoints.clone())?;
                }
                Ok(wallet)
            });
            match made {
                Ok(wallet) => {
                    *self.slot.guard().await = Some(wallet);
                    self.slot.set_lifecycle(ServiceLifecycle::Connected);
                    Ok(())
                }
                Err(e) => {
                    self.slot.set_lifecycle(ServiceLifecycle::Errored);
                    Err(e)
                }
            }
        }
    }

    fn disconnect(&self) -> impl Future<Output = Result<()>> + MaybeSend {
        async move {
            *self.slot.guard().await = None;
            self.slot.set_lifecycle(ServiceLifecycle::Disconnected);
            Ok(())
        }
    }
}

/// Funding handle for [`WalletPeg`]: a sized Bitcoin send or a Liquid draft.
#[derive(Debug, Clone, PartialEq)]
pub enum PegFunding {
    Bitcoin(PreparedBitcoinSend),
    Liquid(LiquidSendDraft),
}

impl Eq for PegFunding {}

/// Maps a wallet error to a peg error. Insufficient funds stay distinct,
/// because the peg flow shows a specific message for them.
fn peg_wallet_error(e: Error) -> PegError {
    let text = e.to_string();
    if text.to_ascii_lowercase().contains("insufficient") {
        PegError::InsufficientFunds(text)
    } else {
        PegError::WalletFailure(text)
    }
}

/// Both wallets as the funding source of peg-ins and peg-outs.
pub struct WalletPeg<K: KvStore + Clone, C: Clock + Clone, S: SecureStore> {
    liquid: Arc<LiquidService<K, C, S>>,
    bitcoin: Arc<BitcoinService<K, C>>,
}

impl<K: KvStore + Clone, C: Clock + Clone, S: SecureStore> WalletPeg<K, C, S> {
    /// Uses the two shared wallet services.
    pub fn new(liquid: Arc<LiquidService<K, C, S>>, bitcoin: Arc<BitcoinService<K, C>>) -> Self {
        Self { liquid, bitcoin }
    }
}

impl<K, C, S> PegWallet for WalletPeg<K, C, S>
where
    K: KvStore + Clone,
    C: Clock + Clone,
    S: SecureStore,
    LiquidWallet<K, C>: MaybeSend,
    BitcoinWallet<K, C>: MaybeSend,
{
    type Handle = PegFunding;

    fn liquid_payout_address(&self) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move { self.liquid.receive_address().await.map_err(peg_wallet_error) }
    }

    fn bitcoin_payout_address(&self) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move { self.bitcoin.receive_address().await.map_err(peg_wallet_error) }
    }

    fn quote_bitcoin_funding(
        &self,
        destination: &str,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
    ) -> impl Future<Output = std::result::Result<PegFundingQuote<PegFunding>, PegError>> + MaybeSend {
        let destination = destination.to_owned();
        async move {
            // BDK rejects addresses of other networks, so a Liquid
            // destination fails here instead of burning funds.
            let prepared = self
                .bitcoin
                .prepare_send(&destination, amount_sat, drain, fee_rate_sat_per_vbyte.map(u64::from))
                .await
                .map_err(peg_wallet_error)?;
            Ok(PegFundingQuote {
                amount_sat: prepared.amount_sat,
                network_fee_sat: prepared.network_fee_sat,
                handle: PegFunding::Bitcoin(prepared),
            })
        }
    }

    fn quote_liquid_funding(
        &self,
        destination: &str,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> impl Future<Output = std::result::Result<PegFundingQuote<PegFunding>, PegError>> + MaybeSend {
        let destination = destination.to_owned();
        async move {
            let draft = self
                .liquid
                .build_lbtc_send(&destination, amount_sat, fee_rate_sat_per_vb, drain)
                .await
                .map_err(peg_wallet_error)?;
            Ok(PegFundingQuote { amount_sat: draft.amount_sat, network_fee_sat: draft.fee_sat, handle: PegFunding::Liquid(draft) })
        }
    }

    fn broadcast_bitcoin_funding(
        &self,
        quote: PegFundingQuote<PegFunding>,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move {
            let PegFunding::Bitcoin(prepared) = quote.handle else {
                return Err(PegError::WalletFailure("expected a Bitcoin funding handle".into()));
            };
            let mut request = SendRequest::new(ChainId::Bitcoin, prepared.destination, prepared.amount_sat);
            request.drain = prepared.drain;
            request.fee_rate_override_sat_per_vbyte = prepared.fee_rate_sat_per_vbyte.map(|r| r as f64);
            self.bitcoin.send(&request).await.map_err(peg_wallet_error)
        }
    }

    fn broadcast_liquid_funding(
        &self,
        quote: PegFundingQuote<PegFunding>,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move {
            let PegFunding::Liquid(draft) = quote.handle else {
                return Err(PegError::WalletFailure("expected a Liquid funding handle".into()));
            };
            self.liquid.sign_and_broadcast(&draft.pset).await.map_err(peg_wallet_error)
        }
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::api::SessionProvider;
    use crate::domain::AppNetwork;
    use crate::testing::{block_on, FixedClock, MemoryKv};

    const MNEMONIC: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    fn credentials() -> WalletCredentials {
        WalletCredentials { mnemonic: MNEMONIC.into(), network: AppNetwork::Mainnet }
    }

    fn liquid() -> LiquidService<MemoryKv, Arc<FixedClock>, MemoryKv> {
        let secure = MemoryKv::new();
        let store = CredentialStore::new(secure, AppNetwork::Mainnet);
        block_on(store.save(&credentials())).unwrap();
        LiquidService::new(
            MemoryKv::new(),
            Arc::new(FixedClock::new(1_759_686_400_000)),
            EndpointResolver::with_defaults(AppNetwork::Mainnet),
            store,
        )
    }

    #[test]
    fn liquid_service_lifecycle_and_address() {
        let svc = liquid();
        block_on(async {
            assert_eq!(svc.lifecycle(), ServiceLifecycle::Uninitialized);
            assert!(matches!(svc.receive_address().await, Err(Error::InvalidState(_))));

            svc.connect(&credentials()).await.unwrap();
            assert_eq!(svc.lifecycle(), ServiceLifecycle::Connected);

            // Same address the wallet module pins for this mnemonic.
            let addr = svc.liquid_receive_address().await.unwrap();
            assert!(addr.starts_with("lq1"), "{addr}");
            assert_eq!(svc.swap_address().await.unwrap(), addr);
            assert!(svc.transactions().await.unwrap().is_empty());

            svc.disconnect().await.unwrap();
            assert_eq!(svc.lifecycle(), ServiceLifecycle::Disconnected);
            assert!(svc.transactions().await.is_err());
        });
    }

    #[test]
    fn failed_connect_marks_errored() {
        let svc = liquid();
        block_on(async {
            let bad = WalletCredentials::absent(AppNetwork::Mainnet);
            assert!(svc.connect(&bad).await.is_err());
            assert_eq!(svc.lifecycle(), ServiceLifecycle::Errored);
        });
    }

    #[test]
    fn bitcoin_service_address() {
        let svc = BitcoinService::new(
            MemoryKv::new(),
            Arc::new(FixedClock::new(1_759_686_400_000)),
            EndpointResolver::with_defaults(AppNetwork::Mainnet),
        );
        block_on(async {
            svc.connect(&credentials()).await.unwrap();
            assert_eq!(svc.receive_address().await.unwrap(), "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu");
        });
    }

    #[test]
    fn peg_error_mapping() {
        let e = peg_wallet_error(Error::service(ChainId::Bitcoin, "Insufficient funds: 10 sat available"));
        assert!(matches!(e, PegError::InsufficientFunds(_)));
        let e = peg_wallet_error(Error::service(ChainId::Bitcoin, "bad address"));
        assert!(matches!(e, PegError::WalletFailure(_)));
    }

    #[cfg(not(feature = "electrum"))]
    #[test]
    fn electrum_needs_the_feature() {
        let svc = BitcoinService::new(
            MemoryKv::new(),
            Arc::new(FixedClock::new(1_759_686_400_000)),
            EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet),
        )
        .with_backend(ChainBackend::Electrum(crate::wallet::ElectrumConfig::new(Arc::new(
            crate::testing::InlineSpawner,
        ))));
        block_on(async {
            assert!(matches!(svc.connect(&credentials()).await, Err(Error::InvalidState(_))));
            assert_eq!(svc.lifecycle(), ServiceLifecycle::Errored);
        });
    }

    #[cfg(feature = "electrum")]
    mod electrum {
        use super::*;
        use crate::testing::InlineSpawner;
        use crate::wallet::ElectrumConfig;

        /// Nothing listens on port 1, so connects fail at once.
        const CLOSED: &str = "tcp://127.0.0.1:1";

        fn config() -> ElectrumConfig {
            ElectrumConfig { spawner: Arc::new(InlineSpawner), timeout_s: 2, retry: 0, validate_domain: true }
        }

        #[test]
        fn bitcoin_electrum_failure_keeps_service_usable() {
            let endpoints =
                EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet).with_custom_node(ChainId::Bitcoin, CLOSED);
            let svc = BitcoinService::new(MemoryKv::new(), Arc::new(FixedClock::new(1_759_686_400_000)), endpoints)
                .with_backend(ChainBackend::Electrum(config()));
            block_on(async {
                svc.connect(&credentials()).await.unwrap();
                let err = svc.sync(60_000).await.unwrap_err();
                assert!(err.to_string().contains("bdk sync failed"), "{err}");
                // Offline work still runs after a network failure.
                assert_eq!(svc.receive_address().await.unwrap(), "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu");
                assert_eq!(svc.lifecycle(), ServiceLifecycle::Connected);
            });
        }

        #[test]
        fn liquid_electrum_failure_is_reported() {
            let endpoints =
                EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet).with_custom_node(ChainId::Liquid, CLOSED);
            let secure = MemoryKv::new();
            let store = CredentialStore::new(secure, AppNetwork::Mainnet);
            block_on(store.save(&credentials())).unwrap();
            let svc = LiquidService::new(MemoryKv::new(), Arc::new(FixedClock::new(1_759_686_400_000)), endpoints, store)
                .with_backend(ChainBackend::Electrum(config()));
            block_on(async {
                svc.connect(&credentials()).await.unwrap();
                let err = svc.sync(60_000).await.unwrap_err();
                assert!(err.to_string().contains("lwk sync failed"), "{err}");
                assert!(svc.liquid_receive_address().await.unwrap().starts_with("lq1"));
            });
        }

        /// Live scan against the default Blockstream Electrum servers.
        /// Run by hand: `cargo test --features electrum -- --ignored live_`
        #[test]
        #[ignore = "needs network"]
        fn live_electrum_scan_both_chains() {
            let config = ElectrumConfig { spawner: Arc::new(InlineSpawner), timeout_s: 30, retry: 2, validate_domain: true };
            let clock = Arc::new(FixedClock::new(1_759_686_400_000));
            let btc = BitcoinService::new(
                MemoryKv::new(),
                clock.clone(),
                EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet),
            )
            .with_backend(ChainBackend::Electrum(config.clone()));
            let secure = MemoryKv::new();
            let store = CredentialStore::new(secure, AppNetwork::Mainnet);
            block_on(store.save(&credentials())).unwrap();
            let lq = LiquidService::new(
                MemoryKv::new(),
                clock,
                EndpointResolver::with_electrum_defaults(AppNetwork::Mainnet),
                store,
            )
            .with_backend(ChainBackend::Electrum(config));
            block_on(async {
                btc.connect(&credentials()).await.unwrap();
                let outcome = btc.sync(60_000).await.unwrap();
                eprintln!("bitcoin electrum: {outcome:?}");
                // The well-known test mnemonic has public mainnet history.
                assert!(outcome.fetched > 0, "expected history for the abandon wallet");
                lq.connect(&credentials()).await.unwrap();
                let outcome = lq.sync(60_000).await.unwrap();
                eprintln!("liquid electrum: {outcome:?}");
            });
        }
    }

    struct FakeSession;
    impl SessionProvider for FakeSession {
        fn access_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            std::future::ready(Ok("jwt-1".to_owned()))
        }
        fn force_refresh_token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            std::future::ready(Ok("jwt-2".to_owned()))
        }
    }

    #[test]
    fn session_tokens_forward() {
        assert_eq!(block_on(SessionTokens(FakeSession).token()).unwrap(), "jwt-1");
    }
}
