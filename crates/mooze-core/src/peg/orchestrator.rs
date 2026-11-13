//! Peg quote and execution.

use std::future::Future;

use super::entities::{PegDirection, PegError, PegOrder, PegPhase};
use super::repository::PegRepository;
use crate::ports::{MaybeSend, MaybeSync};
use crate::Result;

/// A sized, unbroadcast funding transaction.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PegFundingQuote<H> {
    /// Wallet-specific handle (PSBT, Liquid draft).
    pub handle: H,
    /// What reaches the deposit address.
    pub amount_sat: u64,
    /// On-chain fee of the funding transaction.
    pub network_fee_sat: u64,
}

impl<H> PegFundingQuote<H> {
    /// Amount plus network fee.
    pub fn total_sat(&self) -> u64 {
        self.amount_sat + self.network_fee_sat
    }
}

/// Wallet side of a peg. The wallet module implements it.
pub trait PegWallet: MaybeSend + MaybeSync {
    /// Opaque funding handle.
    type Handle: MaybeSend + MaybeSync;

    /// Liquid address for peg-in proceeds (from LWK).
    fn liquid_payout_address(&self) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend;

    /// Bitcoin address for peg-out proceeds.
    fn bitcoin_payout_address(&self) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend;

    /// Sizes a Bitcoin funding transaction. Must refuse Liquid destinations.
    fn quote_bitcoin_funding(
        &self,
        destination: &str,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
    ) -> impl Future<Output = std::result::Result<PegFundingQuote<Self::Handle>, PegError>> + MaybeSend;

    /// Sizes a Liquid funding transaction. A drain reports the real amount.
    fn quote_liquid_funding(
        &self,
        destination: &str,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> impl Future<Output = std::result::Result<PegFundingQuote<Self::Handle>, PegError>> + MaybeSend;

    /// Signs and broadcasts a Bitcoin funding transaction. Returns the txid.
    fn broadcast_bitcoin_funding(
        &self,
        quote: PegFundingQuote<Self::Handle>,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend;

    /// Signs and broadcasts a Liquid funding transaction under the spend lock.
    fn broadcast_liquid_funding(
        &self,
        quote: PegFundingQuote<Self::Handle>,
    ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend;
}

/// Persistence of peg lifecycle steps.
pub trait PegStore: MaybeSend + MaybeSync {
    /// Records a created order before any broadcast. Idempotent.
    fn record_created(&self, order: &PegOrder, amount_sat: u64) -> impl Future<Output = Result<()>> + MaybeSend;

    /// Attaches the funding txid.
    fn record_funded(&self, order_id: &str, funding_tx_id: &str) -> impl Future<Output = Result<()>> + MaybeSend;

    /// Moves an order to a terminal phase.
    fn record_terminal(
        &self,
        order_id: &str,
        phase: PegPhase,
        payout_tx_id: Option<&str>,
        error_message: Option<&str>,
    ) -> impl Future<Output = Result<()>> + MaybeSend;
}

/// What the user sees before confirming.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PegQuote {
    pub direction: PegDirection,
    /// Gross amount committed.
    pub amount_sat: u64,
    pub network_fee_sat: u64,
    pub service_fee_sat: u64,
    pub minimum_sat: u64,
}

impl PegQuote {
    /// Network plus service fee.
    pub fn total_fee_sat(&self) -> u64 {
        self.network_fee_sat + self.service_fee_sat
    }

    /// Amount minus fees, floored at zero.
    pub fn estimated_receive_sat(&self) -> u64 {
        self.amount_sat.saturating_sub(self.total_fee_sat())
    }
}

/// A funded peg.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PegExecution {
    pub order: PegOrder,
    pub funding_tx_id: String,
}

/// Creates, persists and funds pegs.
#[derive(Debug)]
pub struct PegOrchestrator<R, W, S> {
    repository: R,
    wallet: W,
    store: S,
}

impl<R: PegRepository, W: PegWallet, S: PegStore> PegOrchestrator<R, W, S> {
    /// New orchestrator.
    pub fn new(repository: R, wallet: W, store: S) -> Self {
        Self { repository, wallet, store }
    }

    /// The repository.
    pub fn repository_mut(&mut self) -> &mut R {
        &mut self.repository
    }

    /// Prices a peg without creating an order. The funding transaction is
    /// sized against the wallet's own address (BTC address for peg-in,
    /// Liquid address for peg-out).
    pub async fn quote(
        &mut self,
        direction: PegDirection,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
    ) -> std::result::Result<PegQuote, PegError> {
        let limits = self.repository.get_limits().await?;
        let minimum = limits.minimum_for(direction);
        if !drain && amount_sat < minimum {
            return Err(PegError::BelowMinimum { minimum_sat: minimum, actual_sat: amount_sat });
        }
        let funding = if direction.is_peg_in() {
            let address = self.wallet.bitcoin_payout_address().await?;
            self.wallet.quote_bitcoin_funding(&address, amount_sat, fee_rate_sat_per_vbyte, drain).await?
        } else {
            let address = self.wallet.liquid_payout_address().await?;
            self.wallet.quote_liquid_funding(&address, amount_sat, fee_rate_sat_per_vbyte.map(f64::from), drain).await?
        };
        // A drain learns its amount here, after the network fee.
        ensure_minimum(funding.amount_sat, minimum)?;
        Ok(PegQuote {
            direction,
            amount_sat: funding.amount_sat,
            network_fee_sat: funding.network_fee_sat,
            service_fee_sat: limits.service_fee_sat(direction, funding.amount_sat),
            minimum_sat: minimum,
        })
    }

    async fn resolve_payout_address(
        &self,
        direction: PegDirection,
        external: Option<&str>,
    ) -> std::result::Result<String, PegError> {
        if let Some(ext) = external.map(str::trim).filter(|e| !e.is_empty()) {
            if direction.is_peg_in() {
                return Err(PegError::WalletFailure("peg-in deve receber em endereço da própria carteira".into()));
            }
            return Ok(ext.to_owned());
        }
        if direction.is_peg_in() {
            self.wallet.liquid_payout_address().await
        } else {
            self.wallet.bitcoin_payout_address().await
        }
    }

    /// Creates the order, records it, builds and broadcasts the funding.
    ///
    /// It never broadcasts an amount below the minimum of SideSwap, which
    /// does not process such a peg: the funds could be lost. The check does
    /// not rely on a previous [`Self::quote`].
    ///
    /// A peg-out also gets a return address before any L-BTC leaves (see
    /// [`Self::register_return_address`]): if the deposit still falls below
    /// the minimum, SideSwap sends it back to the wallet.
    pub async fn execute(
        &mut self,
        direction: PegDirection,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
        external_payout_address: Option<&str>,
    ) -> std::result::Result<PegExecution, PegError> {
        let minimum = self.repository.get_limits().await?.minimum_for(direction);
        if !drain {
            ensure_minimum(amount_sat, minimum)?;
        }
        let payout = self.resolve_payout_address(direction, external_payout_address).await?;
        let order = self.repository.create_order(direction, &payout).await?;

        if let Err(e) = self.store.record_created(&order, amount_sat).await {
            return Err(PegError::WalletFailure(format!("falha ao registrar operação: {e}")));
        }

        if !order.direction.is_peg_in() {
            if let Err(e) = self.register_return_address(&order).await {
                // Nothing was broadcast: the order is dead, the user can retry.
                self.mark_failed(&order.order_id, &e).await;
                return Err(e);
            }
        }

        let quote = if order.direction.is_peg_in() {
            self.wallet.quote_bitcoin_funding(&order.deposit_address, amount_sat, fee_rate_sat_per_vbyte, drain).await
        } else {
            self.wallet
                .quote_liquid_funding(&order.deposit_address, amount_sat, fee_rate_sat_per_vbyte.map(f64::from), drain)
                .await
        };
        // A drain learns its amount only here, after the network fee.
        let funding = match quote.and_then(|f| ensure_minimum(f.amount_sat, minimum).map(|()| f)) {
            Ok(f) => f,
            Err(e) => {
                // Nothing was broadcast: the order is dead.
                self.mark_failed(&order.order_id, &e).await;
                return Err(e);
            }
        };

        let broadcast = if order.direction.is_peg_in() {
            self.wallet.broadcast_bitcoin_funding(funding).await
        } else {
            self.wallet.broadcast_liquid_funding(funding).await
        };
        match broadcast {
            Ok(txid) => {
                // Best-effort: a lost annotation must not turn a sent tx into a failure.
                let _ = self.store.record_funded(&order.order_id, &txid).await;
                Ok(PegExecution { order, funding_tx_id: txid })
            }
            Err(e) => {
                self.mark_failed(&order.order_id, &e).await;
                Err(e)
            }
        }
    }

    /// Gives a peg-out order the address of our own Liquid wallet as its
    /// return address, and reads it back from the order status.
    ///
    /// SideSwap returns a peg-out deposit below its minimum
    /// (`InsufficientAmount`) to this address, minus the network fee.
    /// Without it, SideSwap keeps the deposit. The address is ours even when
    /// the BTC goes to an external address: the L-BTC left this wallet. A
    /// peg-in has no return: SideSwap keeps BTC below the minimum, so the
    /// minimum check is its only guard.
    async fn register_return_address(&mut self, order: &PegOrder) -> std::result::Result<(), PegError> {
        let address = self.wallet.liquid_payout_address().await?;
        self.repository.set_return_address(&order.order_id, &address).await?;
        let status = self.repository.get_status(order.direction, &order.order_id).await?;
        if status.return_address.as_deref() != Some(address.as_str()) {
            return Err(PegError::ProviderRejected("endereço de devolução não foi registrado".into()));
        }
        Ok(())
    }

    async fn mark_failed(&self, order_id: &str, error: &PegError) {
        let msg = error.message();
        // Best-effort: the row stays as created and is still recoverable.
        let _ = self.store.record_terminal(order_id, PegPhase::Failed, None, Some(&msg)).await;
    }
}

/// Refuses an amount below the minimum of SideSwap for the direction.
fn ensure_minimum(amount_sat: u64, minimum_sat: u64) -> std::result::Result<(), PegError> {
    if amount_sat < minimum_sat {
        return Err(PegError::BelowMinimum { minimum_sat, actual_sat: amount_sat });
    }
    Ok(())
}

#[cfg(all(test, not(target_arch = "wasm32")))]
pub(crate) mod tests {
    use std::future::ready;
    use std::sync::{Arc, Mutex};

    use super::*;
    use crate::peg::entities::{PegProgress, PegServerLimits};
    use crate::testing::block_on;
    use crate::Error;

    pub(crate) const LIMITS: PegServerLimits = PegServerLimits {
        min_peg_in_sat: 10_000,
        min_peg_out_sat: 25_000,
        server_fee_percent_peg_in: 0.1,
        server_fee_percent_peg_out: 0.1,
    };

    pub(crate) type Log = Arc<Mutex<Vec<String>>>;

    pub(crate) struct FakeRepo {
        pub log: Log,
        pub status: Option<std::result::Result<PegProgress, PegError>>,
        /// Answer to a return address registration.
        pub return_answer: std::result::Result<(), PegError>,
    }

    impl FakeRepo {
        pub(crate) fn new(log: Log, status: Option<std::result::Result<PegProgress, PegError>>) -> Self {
            Self { log, status, return_answer: Ok(()) }
        }
    }

    /// The status of `order-1`, a peg-out, with `return_address` registered.
    fn peg_out_status(return_address: Option<&str>) -> PegProgress {
        PegProgress {
            order_id: "order-1".into(),
            direction: PegDirection::PegOut,
            phase: PegPhase::AwaitingDeposit,
            deposits: vec![],
            deposit_address: "lq1-deposit".into(),
            payout_address: "bc1-own".into(),
            return_address: return_address.map(str::to_owned),
        }
    }

    impl PegRepository for FakeRepo {
        fn get_limits(&mut self) -> impl Future<Output = std::result::Result<PegServerLimits, PegError>> + MaybeSend {
            ready(Ok(LIMITS))
        }
        fn create_order(
            &mut self,
            direction: PegDirection,
            payout_address: &str,
        ) -> impl Future<Output = std::result::Result<PegOrder, PegError>> + MaybeSend {
            self.log.lock().unwrap().push(format!("create:{payout_address}"));
            ready(Ok(PegOrder {
                order_id: "order-1".into(),
                direction,
                deposit_address: if direction.is_peg_in() { "bc1-deposit".into() } else { "lq1-deposit".into() },
                payout_address: payout_address.to_owned(),
                created_at_ms: 1,
                expires_at_ms: None,
            }))
        }
        fn get_status(
            &mut self,
            _direction: PegDirection,
            _order_id: &str,
        ) -> impl Future<Output = std::result::Result<PegProgress, PegError>> + MaybeSend {
            self.log.lock().unwrap().push("status".into());
            ready(self.status.clone().unwrap_or(Err(PegError::TransportFailure("none".into()))))
        }
        fn set_return_address(
            &mut self,
            order_id: &str,
            address: &str,
        ) -> impl Future<Output = std::result::Result<(), PegError>> + MaybeSend {
            self.log.lock().unwrap().push(format!("return:{order_id}:{address}"));
            ready(self.return_answer.clone())
        }
    }

    struct FakeWallet {
        log: Log,
        fail_quote: bool,
        fail_broadcast: bool,
        /// Balance that a drain spends, before the network fee.
        drain_balance: u64,
    }

    impl PegWallet for FakeWallet {
        type Handle = String;
        fn liquid_payout_address(&self) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
            ready(Ok("lq1-own".into()))
        }
        fn bitcoin_payout_address(&self) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
            ready(Ok("bc1-own".into()))
        }
        fn quote_bitcoin_funding(
            &self,
            destination: &str,
            amount_sat: u64,
            _fee: Option<u32>,
            drain: bool,
        ) -> impl Future<Output = std::result::Result<PegFundingQuote<String>, PegError>> + MaybeSend {
            self.log.lock().unwrap().push(format!("quote-btc:{destination}"));
            let amount = if drain { self.drain_balance - 150 } else { amount_sat };
            ready(if self.fail_quote {
                Err(PegError::InsufficientFunds("no".into()))
            } else {
                Ok(PegFundingQuote { handle: destination.to_owned(), amount_sat: amount, network_fee_sat: 150 })
            })
        }
        fn quote_liquid_funding(
            &self,
            destination: &str,
            amount_sat: u64,
            _fee: Option<f64>,
            drain: bool,
        ) -> impl Future<Output = std::result::Result<PegFundingQuote<String>, PegError>> + MaybeSend {
            self.log.lock().unwrap().push(format!("quote-lbtc:{destination}"));
            // Drain: the balance minus the fee of 26.
            let amount = if drain { self.drain_balance - 26 } else { amount_sat };
            ready(if self.fail_quote {
                Err(PegError::InsufficientFunds("no".into()))
            } else {
                Ok(PegFundingQuote { handle: destination.to_owned(), amount_sat: amount, network_fee_sat: 26 })
            })
        }
        fn broadcast_bitcoin_funding(
            &self,
            q: PegFundingQuote<String>,
        ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
            self.log.lock().unwrap().push(format!("broadcast-btc:{}", q.handle));
            ready(if self.fail_broadcast { Err(PegError::WalletFailure("x".into())) } else { Ok("btc-txid".into()) })
        }
        fn broadcast_liquid_funding(
            &self,
            q: PegFundingQuote<String>,
        ) -> impl Future<Output = std::result::Result<String, PegError>> + MaybeSend {
            self.log.lock().unwrap().push(format!("broadcast-lbtc:{}", q.handle));
            ready(if self.fail_broadcast { Err(PegError::WalletFailure("x".into())) } else { Ok("lwk-txid".into()) })
        }
    }

    pub(crate) struct LogStore {
        pub log: Log,
        pub fail: bool,
    }

    impl PegStore for LogStore {
        fn record_created(&self, order: &PegOrder, amount_sat: u64) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push(format!("created:{}:{amount_sat}", order.order_id));
            ready(if self.fail { Err(Error::Storage("disk".into())) } else { Ok(()) })
        }
        fn record_funded(&self, order_id: &str, tx: &str) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push(format!("funded:{order_id}:{tx}"));
            ready(Ok(()))
        }
        fn record_terminal(
            &self,
            order_id: &str,
            phase: PegPhase,
            _payout: Option<&str>,
            _err: Option<&str>,
        ) -> impl Future<Output = Result<()>> + MaybeSend {
            self.log.lock().unwrap().push(format!("terminal:{order_id}:{}", phase.name()));
            ready(if self.fail { Err(Error::Storage("disk".into())) } else { Ok(()) })
        }
    }

    fn orch(
        fail_quote: bool,
        fail_broadcast: bool,
        fail_store: bool,
    ) -> (PegOrchestrator<FakeRepo, FakeWallet, LogStore>, Log) {
        orch_with(fail_quote, fail_broadcast, fail_store, 200_000)
    }

    fn orch_with(
        fail_quote: bool,
        fail_broadcast: bool,
        fail_store: bool,
        drain_balance: u64,
    ) -> (PegOrchestrator<FakeRepo, FakeWallet, LogStore>, Log) {
        let log: Log = Arc::default();
        (
            PegOrchestrator::new(
                // SideSwap keeps the return address that the peg-out registers.
                FakeRepo::new(log.clone(), Some(Ok(peg_out_status(Some("lq1-own"))))),
                FakeWallet { log: log.clone(), fail_quote, fail_broadcast, drain_balance },
                LogStore { log: log.clone(), fail: fail_store },
            ),
            log,
        )
    }

    /// Lines of the log that start with one of `prefixes`.
    fn logged(log: &Log, prefixes: &[&str]) -> Vec<String> {
        log.lock().unwrap().iter().filter(|l| prefixes.iter().any(|p| l.starts_with(p))).cloned().collect()
    }

    #[test]
    fn quote_refuses_a_drain_below_the_minimum() {
        // 25 010 of balance leaves 24 984 after the fee: below 25 000.
        let (mut o, _) = orch_with(false, false, false, 25_010);
        assert_eq!(
            block_on(o.quote(PegDirection::PegOut, 25_010, None, true)),
            Err(PegError::BelowMinimum { minimum_sat: 25_000, actual_sat: 24_984 })
        );
        // Peg-in: 10 100 leaves 9 950 after the fee: below 10 000.
        let (mut o, _) = orch_with(false, false, false, 10_100);
        assert_eq!(
            block_on(o.quote(PegDirection::PegIn, 10_100, None, true)),
            Err(PegError::BelowMinimum { minimum_sat: 10_000, actual_sat: 9_950 })
        );
    }

    #[test]
    fn execute_never_broadcasts_below_the_minimum() {
        // An amount below the minimum is refused before any order exists.
        let (mut o, log) = orch(false, false, false);
        assert_eq!(
            block_on(o.execute(PegDirection::PegOut, 12_000, None, false, None)),
            Err(PegError::BelowMinimum { minimum_sat: 25_000, actual_sat: 12_000 })
        );
        assert!(logged(&log, &["create", "quote", "broadcast"]).is_empty());

        // A drain learns its amount when the funding is sized. Below the
        // minimum, nothing is broadcast and the order is marked failed.
        let (mut o, log) = orch_with(false, false, false, 25_010);
        assert_eq!(
            block_on(o.execute(PegDirection::PegOut, 25_010, None, true, None)),
            Err(PegError::BelowMinimum { minimum_sat: 25_000, actual_sat: 24_984 })
        );
        assert!(logged(&log, &["broadcast"]).is_empty());
        assert_eq!(log.lock().unwrap().last().unwrap(), "terminal:order-1:failed");
    }

    #[test]
    fn quote_checks_minimum_and_never_creates_order() {
        let (mut o, log) = orch(false, false, false);
        assert_eq!(
            block_on(o.quote(PegDirection::PegOut, 12_000, None, false)),
            Err(PegError::BelowMinimum { minimum_sat: 25_000, actual_sat: 12_000 })
        );
        let q = block_on(o.quote(PegDirection::PegIn, 100_000, Some(3), false)).unwrap();
        assert_eq!((q.network_fee_sat, q.service_fee_sat, q.estimated_receive_sat()), (150, 100, 99_750));
        assert!(log.lock().unwrap().contains(&"quote-btc:bc1-own".to_owned()));
        let d = block_on(o.quote(PegDirection::PegOut, 0, None, true)).unwrap();
        assert_eq!((d.amount_sat, d.service_fee_sat, d.estimated_receive_sat()), (199_974, 200, 199_748));
        assert!(!log.lock().unwrap().iter().any(|l| l.starts_with("create")));
    }

    // SideSwap returns a peg-out deposit below its minimum to the return
    // address of the order, and only then. The order gets the address of our
    // own Liquid wallet, confirmed in its status, before any L-BTC leaves.
    #[test]
    fn execute_persists_before_broadcast() {
        let (mut o, log) = orch(false, false, false);
        let e = block_on(o.execute(PegDirection::PegOut, 30_000, None, false, None)).unwrap();
        assert_eq!(e.funding_tx_id, "lwk-txid");
        assert_eq!(
            *log.lock().unwrap(),
            vec![
                "create:bc1-own",
                "created:order-1:30000",
                "return:order-1:lq1-own",
                "status",
                "quote-lbtc:lq1-deposit",
                "broadcast-lbtc:lq1-deposit",
                "funded:order-1:lwk-txid"
            ]
        );
    }

    // A peg-in below the minimum is lost: SideSwap has no return for BTC.
    // The minimum check is its only guard.
    #[test]
    fn a_peg_in_registers_no_return_address() {
        let (mut o, log) = orch(false, false, false);
        block_on(o.execute(PegDirection::PegIn, 30_000, None, false, None)).unwrap();
        assert!(logged(&log, &["return", "status"]).is_empty());
    }

    // Without a confirmed return address, a peg-out deposit below the
    // minimum would be lost. Nothing is sent yet, so the order dies and the
    // user can try again.
    #[test]
    fn a_peg_out_without_a_confirmed_return_address_is_never_funded() {
        let refused = PegError::ProviderRejected("parsing address failed".into());
        let cases: Vec<(&str, std::result::Result<(), PegError>, std::result::Result<PegProgress, PegError>)> = vec![
            ("refused", Err(refused.clone()), Ok(peg_out_status(Some("lq1-own")))),
            ("not kept", Ok(()), Ok(peg_out_status(None))),
            ("another address", Ok(()), Ok(peg_out_status(Some("lq1-other")))),
            ("status unread", Ok(()), Err(PegError::TransportFailure("down".into()))),
        ];
        for (case, answer, status) in cases {
            let (mut o, log) = orch(false, false, false);
            o.repository_mut().return_answer = answer;
            o.repository_mut().status = Some(status);

            let result = block_on(o.execute(PegDirection::PegOut, 30_000, None, false, None));

            assert!(result.is_err(), "{case}");
            assert!(logged(&log, &["quote", "broadcast"]).is_empty(), "{case}");
            assert_eq!(log.lock().unwrap().last().unwrap(), "terminal:order-1:failed", "{case}");
        }
    }

    #[test]
    fn execute_store_failure_blocks_broadcast() {
        let (mut o, log) = orch(false, false, true);
        assert!(matches!(
            block_on(o.execute(PegDirection::PegIn, 30_000, None, false, None)),
            Err(PegError::WalletFailure(m)) if m.starts_with("falha ao registrar")
        ));
        assert!(!log.lock().unwrap().iter().any(|l| l.starts_with("broadcast")));
    }

    #[test]
    fn execute_failures_mark_failed() {
        let (mut o, log) = orch(true, false, false);
        assert!(matches!(
            block_on(o.execute(PegDirection::PegIn, 30_000, None, false, None)),
            Err(PegError::InsufficientFunds(_))
        ));
        assert_eq!(log.lock().unwrap().last().unwrap(), "terminal:order-1:failed");
        let (mut o, log) = orch(false, true, false);
        assert!(block_on(o.execute(PegDirection::PegIn, 30_000, None, false, None)).is_err());
        assert_eq!(log.lock().unwrap().last().unwrap(), "terminal:order-1:failed");
    }

    #[test]
    fn payout_address_rules() {
        let (mut o, log) = orch(false, false, false);
        block_on(o.execute(PegDirection::PegOut, 30_000, None, false, Some(" bc1ext "))).unwrap();
        assert_eq!(log.lock().unwrap()[0], "create:bc1ext");
        // The BTC goes to the external address, but a return still comes back
        // to our own wallet, which sent the L-BTC.
        assert!(log.lock().unwrap().contains(&"return:order-1:lq1-own".to_owned()));
        assert!(matches!(
            block_on(o.execute(PegDirection::PegIn, 30_000, None, false, Some("lq1ext"))),
            Err(PegError::WalletFailure(_))
        ));
        let (mut o, log) = orch(false, false, false);
        block_on(o.execute(PegDirection::PegIn, 30_000, None, false, Some("  "))).unwrap();
        assert_eq!(log.lock().unwrap()[0], "create:lq1-own");
    }
}
