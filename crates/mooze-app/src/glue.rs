//! Wires the App wallets into the core feature traits.
//!
//! - [`LiquidPort`]: the Liquid wallet as PIX `AddressProvider` and SideSwap
//!   `SwapSigner`. Signing reads the mnemonic from the secure store.
//! - [`WalletPegPort`]: both wallets as the `PegWallet`.
//!
//! The ports hold a `Weak` reference to the app state, so a port stored
//! inside that state never keeps it alive.

// Trait impls return explicit futures so the MaybeSend bound stays visible.
#![allow(clippy::manual_async_fn)]

use std::future::Future;
use std::sync::{Arc, Weak};

use mooze_core::adapters::PegFunding;
use mooze_core::domain::{ChainId, LiquidUtxo, SendRequest};
use mooze_core::peg::entities::classify_wallet_error;
use mooze_core::peg::{PegError, PegFundingQuote, PegWallet};
use mooze_core::pix::AddressProvider;
use mooze_core::ports::MaybeSend;
use mooze_core::sideswap::SwapSigner;
use mooze_core::{Error, Result};

use crate::app::wallets::load_mnemonic;
use crate::app::Inner;
use crate::Platform;

fn gone() -> Error {
    Error::InvalidState("core closed".into())
}

fn not_connected(chain: ChainId) -> Error {
    Error::InvalidState(format!("{} wallet not connected", chain.as_str()))
}

/// Reads the mnemonic, mapping the facade error back to the core error.
async fn mnemonic<P: Platform>(inner: &Inner<P>) -> Result<String> {
    load_mnemonic(inner)
        .await
        .map_err(|e| Error::Credential(e.message))
}

// ───────────────────────────── Liquid port

/// The Liquid wallet as address source and swap signer.
pub struct LiquidPort<P: Platform> {
    inner: Weak<Inner<P>>,
}

impl<P: Platform> Clone for LiquidPort<P> {
    fn clone(&self) -> Self {
        Self {
            inner: self.inner.clone(),
        }
    }
}

impl<P: Platform> LiquidPort<P> {
    pub(crate) fn new(inner: &Arc<Inner<P>>) -> Self {
        Self {
            inner: Arc::downgrade(inner),
        }
    }

    fn inner(&self) -> Result<Arc<Inner<P>>> {
        self.inner.upgrade().ok_or_else(gone)
    }

    async fn receive_address(&self) -> Result<String> {
        let inner = self.inner()?;
        let mut guard = inner.liquid.lock().await;
        let wallet = guard
            .as_mut()
            .ok_or_else(|| not_connected(ChainId::Liquid))?;
        wallet.receive_address().await
    }
}

impl<P: Platform> AddressProvider for LiquidPort<P> {
    fn liquid_receive_address(&self) -> impl Future<Output = Result<String>> + MaybeSend {
        async move { self.receive_address().await }
    }
}

impl<P: Platform> SwapSigner for LiquidPort<P> {
    fn liquid_utxos(&self) -> impl Future<Output = Result<Vec<LiquidUtxo>>> + MaybeSend {
        async move {
            let inner = self.inner()?;
            let guard = inner.liquid.lock().await;
            guard
                .as_ref()
                .ok_or_else(|| not_connected(ChainId::Liquid))?
                .utxos()
        }
    }

    fn swap_address(&self) -> impl Future<Output = Result<String>> + MaybeSend {
        async move { self.receive_address().await }
    }

    fn sign_swap_pset(&self, pset_b64: &str) -> impl Future<Output = Result<String>> + MaybeSend {
        let pset = pset_b64.to_owned();
        async move {
            let inner = self.inner()?;
            let mnemonic = mnemonic(&inner).await?;
            let guard = inner.liquid.lock().await;
            guard
                .as_ref()
                .ok_or_else(|| not_connected(ChainId::Liquid))?
                .sign_swap_pset(&pset, &mnemonic)
        }
    }
}

// ───────────────────────────── peg wallet port

fn peg_error(e: Error) -> PegError {
    classify_wallet_error(&e.to_string())
}

/// Both wallets as the funding source of pegs. Port of `WalletPeg`.
pub struct WalletPegPort<P: Platform> {
    inner: Weak<Inner<P>>,
}

impl<P: Platform> WalletPegPort<P> {
    #[allow(dead_code)] // used by the peg methods
    pub(crate) fn new(inner: &Arc<Inner<P>>) -> Self {
        Self {
            inner: Arc::downgrade(inner),
        }
    }

    fn inner(&self) -> std::result::Result<Arc<Inner<P>>, PegError> {
        self.inner.upgrade().ok_or_else(|| peg_error(gone()))
    }
}

impl<P: Platform> PegWallet for WalletPegPort<P> {
    type Handle = PegFunding;

    fn liquid_payout_address(
        &self,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move {
            let inner = self.inner()?;
            let mut guard = inner.liquid.lock().await;
            let wallet = guard
                .as_mut()
                .ok_or_else(|| peg_error(not_connected(ChainId::Liquid)))?;
            wallet.receive_address().await.map_err(peg_error)
        }
    }

    fn bitcoin_payout_address(
        &self,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move {
            let inner = self.inner()?;
            let mut guard = inner.bitcoin.lock().await;
            let wallet = guard
                .as_mut()
                .ok_or_else(|| peg_error(not_connected(ChainId::Bitcoin)))?;
            let r = wallet
                .next_receive_address(None, None)
                .await
                .map_err(peg_error)?;
            r.address
                .ok_or_else(|| PegError::WalletFailure("wallet returned no address".into()))
        }
    }

    fn quote_bitcoin_funding(
        &self,
        destination: &str,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
    ) -> impl Future<Output = std::result::Result<PegFundingQuote<PegFunding>, PegError>> + MaybeSend
    {
        let destination = destination.to_owned();
        async move {
            let inner = self.inner()?;
            let mut guard = inner.bitcoin.lock().await;
            let wallet = guard
                .as_mut()
                .ok_or_else(|| peg_error(not_connected(ChainId::Bitcoin)))?;
            // BDK rejects addresses of other networks, so a Liquid
            // destination fails here instead of burning funds.
            let prepared = wallet
                .prepare_send(
                    &destination,
                    amount_sat,
                    drain,
                    fee_rate_sat_per_vbyte.map(u64::from),
                )
                .await
                .map_err(peg_error)?;
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
    ) -> impl Future<Output = std::result::Result<PegFundingQuote<PegFunding>, PegError>> + MaybeSend
    {
        let destination = destination.to_owned();
        async move {
            let inner = self.inner()?;
            let mut guard = inner.liquid.lock().await;
            let wallet = guard
                .as_mut()
                .ok_or_else(|| peg_error(not_connected(ChainId::Liquid)))?;
            let draft = wallet
                .build_lbtc_send(&destination, amount_sat, fee_rate_sat_per_vb, drain)
                .await
                .map_err(peg_error)?;
            Ok(PegFundingQuote {
                amount_sat: draft.amount_sat,
                network_fee_sat: draft.fee_sat,
                handle: PegFunding::Liquid(draft),
            })
        }
    }

    fn broadcast_bitcoin_funding(
        &self,
        quote: PegFundingQuote<PegFunding>,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move {
            let PegFunding::Bitcoin(prepared) = quote.handle else {
                return Err(PegError::WalletFailure(
                    "expected a Bitcoin funding handle".into(),
                ));
            };
            let mut request =
                SendRequest::new(ChainId::Bitcoin, prepared.destination, prepared.amount_sat);
            request.drain = prepared.drain;
            request.fee_rate_override_sat_per_vbyte =
                prepared.fee_rate_sat_per_vbyte.map(|r| r as f64);
            let inner = self.inner()?;
            let mut guard = inner.bitcoin.lock().await;
            let wallet = guard
                .as_mut()
                .ok_or_else(|| peg_error(not_connected(ChainId::Bitcoin)))?;
            Ok(wallet
                .send_onchain(&request)
                .await
                .map_err(peg_error)?
                .tx_id)
        }
    }

    fn broadcast_liquid_funding(
        &self,
        quote: PegFundingQuote<PegFunding>,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
        async move {
            let PegFunding::Liquid(draft) = quote.handle else {
                return Err(PegError::WalletFailure(
                    "expected a Liquid funding handle".into(),
                ));
            };
            let inner = self.inner()?;
            let mnemonic = mnemonic(&inner).await.map_err(peg_error)?;
            let mut guard = inner.liquid.lock().await;
            let wallet = guard
                .as_mut()
                .ok_or_else(|| peg_error(not_connected(ChainId::Liquid)))?;
            wallet
                .sign_and_broadcast_pset(&draft.pset, &mnemonic)
                .await
                .map_err(peg_error)
        }
    }
}
