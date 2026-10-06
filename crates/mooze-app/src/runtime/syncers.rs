//! `ChainSyncer` over the App wallets, one per chain.

use std::future::Future;
use std::sync::{Arc, Weak};

use futures::future::{select, Either};
use futures::pin_mut;
use mooze_core::domain::{ChainId, ServiceLifecycle, SyncOutcome, Transaction, WalletCredentials};
use mooze_core::ports::Timer;
use mooze_core::sync::ChainSyncer;
use mooze_core::{Error, MaybeSend, Result};

use crate::app::Inner;
use crate::runtime::sync_loop::Cancel;
use crate::Platform;

/// One chain of the app as the orchestrator sees it.
pub struct AppSyncer<P: Platform> {
    pub(crate) inner: Weak<Inner<P>>,
    pub(crate) chain: ChainId,
    pub(crate) timer: Arc<dyn Timer>,
    /// `stop()` and `Inner::drop` cancel a sync in flight through this.
    pub(crate) cancel: Arc<Cancel>,
}

impl<P: Platform> AppSyncer<P> {
    fn inner(&self) -> Result<Arc<Inner<P>>> {
        self.inner.upgrade().ok_or_else(|| Error::InvalidState("core closed".into()))
    }
}

// Explicit futures keep the MaybeSend bound visible at the impl site.
#[allow(clippy::manual_async_fn)]
impl<P: Platform> ChainSyncer for AppSyncer<P> {
    fn chain(&self) -> ChainId {
        self.chain
    }

    /// Connected while the wallet slot is filled. A wallet that is locked
    /// by a running call counts as connected, so a tick waits for it.
    fn lifecycle(&self) -> ServiceLifecycle {
        let Some(inner) = self.inner.upgrade() else {
            return ServiceLifecycle::Disconnected;
        };
        let connected = match self.chain {
            ChainId::Bitcoin => inner.bitcoin.try_lock().map(|g| g.is_some()).unwrap_or(true),
            _ => inner.liquid.try_lock().map(|g| g.is_some()).unwrap_or(true),
        };
        if connected {
            ServiceLifecycle::Connected
        } else {
            ServiceLifecycle::Disconnected
        }
    }

    /// Syncs the wallet, or fails with `Timeout` after `timeout_ms`, or
    /// with `InvalidState("sync cancelled")` when the runtime stops.
    /// Dropping the wallet future cancels its requests and releases the
    /// wallet, so the app state can go away.
    fn sync(&self, timeout_ms: u64) -> impl Future<Output = Result<SyncOutcome>> + MaybeSend {
        async move {
            if self.cancel.is_cancelled() {
                return Err(Error::InvalidState("sync cancelled".into()));
            }
            let inner = self.inner()?;
            let stop = async {
                let sleep = self.timer.sleep(timeout_ms);
                let cancelled = self.cancel.cancelled();
                pin_mut!(sleep, cancelled);
                matches!(select(sleep, cancelled).await, Either::Right(_))
            };
            let work = async {
                match self.chain {
                    ChainId::Bitcoin => {
                        let mut g = inner.bitcoin.lock().await;
                        g.as_mut()
                            .ok_or_else(|| Error::InvalidState("bitcoin wallet not connected".into()))?
                            .sync()
                            .await
                    }
                    _ => {
                        let mut g = inner.liquid.lock().await;
                        g.as_mut()
                            .ok_or_else(|| Error::InvalidState("liquid wallet not connected".into()))?
                            .sync()
                            .await
                    }
                }
            };
            pin_mut!(stop, work);
            match select(work, stop).await {
                Either::Left((r, _)) => r,
                Either::Right((true, _)) => Err(Error::InvalidState("sync cancelled".into())),
                Either::Right((false, _)) => {
                    Err(Error::Timeout(format!("{} sync exceeded {timeout_ms} ms", self.chain.as_str())))
                }
            }
        }
    }

    fn transactions(&self) -> impl Future<Output = Result<Vec<Transaction>>> + MaybeSend {
        async move {
            let inner = self.inner()?;
            Ok(match self.chain {
                ChainId::Bitcoin => {
                    inner.bitcoin.lock().await.as_ref().map(|w| w.list_transactions().to_vec()).unwrap_or_default()
                }
                _ => inner.liquid.lock().await.as_ref().map(|w| w.list_transactions().to_vec()).unwrap_or_default(),
            })
        }
    }

    /// Hosts connect through `App::bitcoin_connect` and `App::liquid_connect`.
    fn connect(&self, _credentials: &WalletCredentials) -> impl Future<Output = Result<()>> + MaybeSend {
        async { Ok(()) }
    }

    fn disconnect(&self) -> impl Future<Output = Result<()>> + MaybeSend {
        async { Ok(()) }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::runtime::sync_loop::Cancel;
    use crate::testing::{open_test_app, ABANDON};
    use mooze_core::sync::ChainSyncer;
    use mooze_core::testing::block_on;

    #[test]
    fn cancelled_syncer_returns_before_touching_the_wallet() {
        let (app, plat) = open_test_app();
        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let cancel = Arc::new(Cancel::default());
        cancel.cancel();
        let syncer = AppSyncer {
            inner: Arc::downgrade(&app.inner),
            chain: ChainId::Liquid,
            timer: plat.timer.clone(),
            cancel: cancel.clone(),
        };
        let err = block_on(syncer.sync(60_000)).unwrap_err();
        assert!(matches!(err, Error::InvalidState(ref m) if m == "sync cancelled"), "{err}");
        assert!(plat.http.requests().is_empty(), "no network call after cancel");
    }
}
