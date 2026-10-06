//! Wires the App wallets into the core feature traits.
//!
//! - [`LiquidPort`]: the Liquid wallet as PIX `AddressProvider` and SideSwap
//!   `SwapSigner`. Signing reads the mnemonic from the secure store.
//! - [`WalletPegPort`]: both wallets as the `PegWallet`.
//! - [`SideSwapState`]: one SideSwap connection shared by swaps and pegs,
//!   the peg tracker, and the event driver task.
//!
//! The ports hold a `Weak` reference to the app state, so a port stored
//! inside that state never keeps it alive.

// Trait impls return explicit futures so the MaybeSend bound stays visible.
#![allow(clippy::manual_async_fn)]

use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex as StdMutex, Weak};

use futures::future::{select, Either};
use futures::pin_mut;
use mooze_core::adapters::PegFunding;
use mooze_core::domain::{ChainId, LiquidUtxo, SendRequest};
use mooze_core::peg::entities::classify_wallet_error;
use mooze_core::peg::{PegError, PegFundingQuote, PegTracker, PegWallet};
use mooze_core::pix::AddressProvider;
use mooze_core::ports::{Clock, MaybeSend, Spawner, Timer};
use mooze_core::sideswap::{Notification, ReconnectPolicy, SwapService, SwapSigner};
use mooze_core::{Error, Result};
use tokio::sync::{Mutex, MutexGuard, Notify};

use crate::convert::{
    sideswap_balance_event, sideswap_closed_event, sideswap_disconnected_event,
    sideswap_quote_event,
};
use crate::dto::{QuoteDto, SideSwapEventDto, SideSwapEventKind};

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

// ───────────────────────────── SideSwap state and driver

pub(crate) type Swap<P> = SwapService<<P as Platform>::Ws, LiquidPort<P>>;

/// How often the driver checks the quote timeout and yields the lock.
const DRIVER_TICK_MS: u64 = 500;

/// Receives driver events. Returns false when no receiver is left, which
/// stops the driver.
#[cfg(not(target_arch = "wasm32"))]
pub(crate) type Emit = Arc<dyn Fn(SideSwapEventDto) -> bool + Send + Sync>;
/// Receives driver events. Returns false when no receiver is left, which
/// stops the driver.
#[cfg(target_arch = "wasm32")]
pub(crate) type Emit = Arc<dyn Fn(SideSwapEventDto) -> bool>;

/// Control block of one driver task.
#[derive(Default)]
pub(crate) struct DriverCtl {
    cancelled: AtomicBool,
    /// Wakes the driver: a command wants the session lock, or a cancel.
    wake: Notify,
}

impl DriverCtl {
    fn is_cancelled(&self) -> bool {
        self.cancelled.load(Ordering::SeqCst)
    }

    pub(crate) fn cancel(&self) {
        self.cancelled.store(true, Ordering::SeqCst);
        self.wake.notify_one();
    }

    /// Waits up to `ms`, or less if woken. Returns true when cancelled.
    async fn pause(&self, timer: &dyn Timer, ms: u64) -> bool {
        let sleep = timer.sleep(ms);
        let woken = self.wake.notified();
        pin_mut!(sleep, woken);
        let _ = select(sleep, woken).await;
        self.is_cancelled()
    }
}

/// SideSwap connection, peg tracker and event driver of one app.
pub(crate) struct SideSwapState<P: Platform> {
    /// Swap service over the client. `None` until `sideswap_connect`.
    session: Mutex<Option<Swap<P>>>,
    /// Tracked pegs. Lock after `session` when both are needed.
    pub(crate) pegs: Mutex<PegTracker>,
    driver: StdMutex<Option<Arc<DriverCtl>>>,
}

impl<P: Platform> Default for SideSwapState<P> {
    fn default() -> Self {
        Self {
            session: Mutex::new(None),
            pegs: Mutex::new(PegTracker::default()),
            driver: StdMutex::new(None),
        }
    }
}

impl<P: Platform> SideSwapState<P> {
    fn driver(&self) -> Option<Arc<DriverCtl>> {
        self.driver
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .clone()
    }

    /// Locks the session for a command. Wakes the driver first, so it
    /// releases the lock instead of waiting for the next frame.
    pub(crate) async fn lock(&self) -> MutexGuard<'_, Option<Swap<P>>> {
        if let Some(ctl) = self.driver() {
            ctl.wake.notify_one();
        }
        self.session.lock().await
    }

    /// True while a driver task runs.
    pub(crate) fn driver_running(&self) -> bool {
        self.driver().is_some_and(|c| !c.is_cancelled())
    }

    /// Stops the driver task, if any. Its event stream then ends.
    pub(crate) fn stop_driver(&self) {
        if let Some(ctl) = self.driver.lock().unwrap_or_else(|e| e.into_inner()).take() {
            ctl.cancel();
        }
    }

    /// Replaces the driver task.
    pub(crate) fn start_driver(
        self: &Arc<Self>,
        spawner: &dyn Spawner,
        timer: Arc<dyn Timer>,
        clock: Arc<dyn Clock>,
        emit: Emit,
    ) {
        let ctl = Arc::new(DriverCtl::default());
        if let Some(old) = self
            .driver
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .replace(ctl.clone())
        {
            old.cancel();
        }
        let state = self.clone();
        spawner.spawn(Box::pin(async move {
            drive(&state, &ctl, timer.as_ref(), clock.as_ref(), &emit).await;
            ctl.cancelled.store(true, Ordering::SeqCst);
            // `closed` ends this driver's stream. A replaced driver stays
            // silent: its successor owns the subscribers now, and the host
            // already closed the old stream itself.
            let current = state.driver();
            if current.is_none_or(|c| Arc::ptr_eq(&c, &ctl)) {
                let _ = emit(sideswap_closed_event());
            }
        }));
    }
}

/// What one driver step produced.
enum Step {
    /// No session: nothing to read.
    Idle,
    /// Woken by a command, a cancel or the tick.
    Woken,
    Quote(Result<mooze_core::sideswap::QuoteResponse>),
    Note(Result<Notification>),
}

/// Reads server pushes and emits them until cancelled or the receiver is gone.
///
/// Holds the session lock only while it waits for a frame, racing a wake-up
/// from commands and a tick. Frames are read with a cancel-safe receive, so
/// dropping the read loses nothing. Transport errors emit `disconnected` and
/// back off with the reconnect policy; the next read reconnects and logs in.
async fn drive<P: Platform>(
    state: &SideSwapState<P>,
    ctl: &DriverCtl,
    timer: &dyn Timer,
    clock: &dyn Clock,
    emit: &Emit,
) {
    let policy = ReconnectPolicy::default();
    let mut attempt: u32 = 0;
    while !ctl.is_cancelled() {
        let step = {
            let mut guard = state.session.lock().await;
            match guard.as_mut() {
                None => Step::Idle,
                Some(swap) => {
                    let mut ready: Vec<SideSwapEventDto> = swap
                        .drain_quotes()
                        .into_iter()
                        .map(|q| sideswap_quote_event(QuoteDto::from(&q)))
                        .collect();
                    if let Some(t) = swap.poll_quote_timeout(clock.now_ms()) {
                        ready.push(sideswap_quote_event(QuoteDto::from(&t)));
                    }
                    if !ready.is_empty() {
                        drop(guard);
                        for e in ready {
                            if !emit(e) {
                                return;
                            }
                        }
                        continue;
                    }
                    let active = swap.active().is_some();
                    let read = async move {
                        if active {
                            Step::Quote(swap.next_quote().await)
                        } else {
                            Step::Note(swap.client_mut().next_event().await)
                        }
                    };
                    let woken = ctl.pause(timer, DRIVER_TICK_MS);
                    pin_mut!(read, woken);
                    match select(read, woken).await {
                        Either::Left((step, _)) => step,
                        Either::Right(_) => Step::Woken,
                    }
                }
            }
        };
        let failed = match step {
            Step::Idle => {
                if ctl.pause(timer, DRIVER_TICK_MS).await {
                    return;
                }
                continue;
            }
            Step::Woken => {
                // Let the waiting command take the (fair) lock first.
                timer.sleep(0).await;
                continue;
            }
            Step::Quote(Ok(q)) => {
                attempt = 0;
                if !emit(sideswap_quote_event(QuoteDto::from(&q))) {
                    return;
                }
                continue;
            }
            Step::Note(Ok(n)) => {
                attempt = 0;
                let event = match n {
                    Notification::PegInWalletBalance(sat) => Some(sideswap_balance_event(
                        SideSwapEventKind::PegInWalletBalance,
                        sat,
                    )),
                    Notification::PegOutWalletBalance(sat) => Some(sideswap_balance_event(
                        SideSwapEventKind::PegOutWalletBalance,
                        sat,
                    )),
                    _ => None,
                };
                if let Some(e) = event {
                    if !emit(e) {
                        return;
                    }
                }
                continue;
            }
            // A quiet socket is not an error: the receive timed out.
            Step::Quote(Err(Error::Timeout(_))) | Step::Note(Err(Error::Timeout(_))) => continue,
            Step::Quote(Err(e)) | Step::Note(Err(e)) => e,
        };
        if !emit(sideswap_disconnected_event(failed.to_string())) {
            return;
        }
        attempt += 1;
        let Some(delay) = policy.next_delay_ms(attempt) else {
            // Reconnect budget spent: the stream ends with `closed`.
            return;
        };
        let deadline = clock.now_ms() + delay;
        loop {
            let now = clock.now_ms();
            if now >= deadline {
                break;
            }
            if ctl.pause(timer, deadline - now).await {
                return;
            }
            // Woken by a command: wait for it, then keep backing off.
            timer.sleep(0).await;
        }
    }
}
