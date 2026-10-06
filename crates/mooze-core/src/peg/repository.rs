//! Peg repository over SideSwap. Port of `domain/repositories/peg_repository.dart`
//! and `data/repositories/peg_repository_impl.dart`.

use std::future::Future;

use serde::de::DeserializeOwned;

use super::entities::{
    aggregate_phase, PegDeposit, PegDirection, PegError, PegOrder, PegPhase, PegProgress,
    PegServerLimits,
};
use crate::ports::{MaybeSend, WsConnector};
use crate::sideswap::protocol::{PegOrderResponse, PegOrderStatus, Request, ServerStatus, TxState};
use crate::sideswap::SideSwapClient;
use crate::Error;

/// Peg operations against the provider.
pub trait PegRepository: MaybeSend {
    /// Minimums and fee percentages.
    fn get_limits(&mut self)
        -> impl Future<Output = Result<PegServerLimits, PegError>> + MaybeSend;

    /// Creates an order paying out to `payout_address`.
    fn create_order(
        &mut self,
        direction: PegDirection,
        payout_address: &str,
    ) -> impl Future<Output = Result<PegOrder, PegError>> + MaybeSend;

    /// One-shot status read.
    fn get_status(
        &mut self,
        direction: PegDirection,
        order_id: &str,
    ) -> impl Future<Output = Result<PegProgress, PegError>> + MaybeSend;
}

/// [`PegRepository`] backed by a [`SideSwapClient`].
#[derive(Debug)]
pub struct SideSwapPegRepository<C: WsConnector> {
    client: SideSwapClient<C>,
}

impl<C: WsConnector> SideSwapPegRepository<C> {
    /// Wraps a client.
    pub fn new(client: SideSwapClient<C>) -> Self {
        Self { client }
    }

    /// The client.
    pub fn client_mut(&mut self) -> &mut SideSwapClient<C> {
        &mut self.client
    }

    /// Returns the client.
    pub fn into_inner(self) -> SideSwapClient<C> {
        self.client
    }
}

/// Wire state to domain phase. Unknown keeps polling (detected).
pub fn tx_state_to_phase(state: TxState) -> PegPhase {
    match state {
        TxState::InsufficientAmount => PegPhase::InsufficientAmount,
        TxState::Detected => PegPhase::Detected,
        TxState::Processing => PegPhase::Processing,
        TxState::Done => PegPhase::Completed,
        TxState::Unknown => PegPhase::Detected,
    }
}

/// Maps `peg_status` to [`PegProgress`].
pub fn to_progress(status: &PegOrderStatus, direction: PegDirection) -> PegProgress {
    let deposits: Vec<PegDeposit> = status
        .list
        .iter()
        .map(|tx| PegDeposit {
            tx_id: tx.tx_hash.clone(),
            phase: tx_state_to_phase(tx.tx_state),
            amount_sat: tx.amount,
            payout_sat: tx.payout,
            payout_tx_id: tx.payout_txid.clone(),
            detected_confirmations: tx.detected_confs,
            total_confirmations: tx.total_confs,
        })
        .collect();
    PegProgress {
        order_id: status.order_id.clone(),
        direction,
        phase: aggregate_phase(&deposits),
        deposits,
        deposit_address: status.addr.clone(),
        payout_address: status.addr_recv.clone(),
    }
}

/// True if an RPC error text means the order does not exist.
pub fn looks_like_not_found(message: &str) -> bool {
    let m = message.to_lowercase();
    m.contains("not found") || m.contains("unknown order") || m.contains("no such order")
}

fn read_failure(e: Error) -> PegError {
    match e {
        Error::Protocol(m) => PegError::ProviderRejected(m),
        other => PegError::TransportFailure(other.to_string()),
    }
}

// NOTE(port): Dart surfaces model parse failures (TypeError) through the
// generic catch, so they become transport failures. Kept.
fn decode<T: DeserializeOwned>(v: serde_json::Value) -> Result<T, PegError> {
    serde_json::from_value(v).map_err(|e| PegError::TransportFailure(e.to_string()))
}

/// The client itself is a repository, so one connection can serve swaps and
/// pegs: pass `&mut client` where a [`PegRepository`] is expected.
impl<C: WsConnector> PegRepository for SideSwapClient<C> {
    async fn get_limits(&mut self) -> Result<PegServerLimits, PegError> {
        let v = self
            .call(&Request::server_status())
            .await
            .map_err(read_failure)?;
        let status: ServerStatus = decode(v)?;
        Ok(PegServerLimits::from(&status))
    }

    async fn create_order(
        &mut self,
        direction: PegDirection,
        payout_address: &str,
    ) -> Result<PegOrder, PegError> {
        if payout_address.trim().is_empty() {
            return Err(PegError::WalletFailure("endereço de destino vazio".into()));
        }
        let req = Request::peg(direction.as_peg_in_flag(), payout_address);
        let v = match self.call(&req).await {
            Ok(v) => v,
            // A create is not idempotent: the order may exist server-side.
            Err(Error::Timeout(d)) => {
                return Err(PegError::UnknownOutcome {
                    stage: "createOrder".into(),
                    detail: d,
                    order_id: None,
                })
            }
            Err(Error::Protocol(m)) => return Err(PegError::ProviderRejected(m)),
            Err(e) => return Err(PegError::TransportFailure(e.to_string())),
        };
        let r: PegOrderResponse = decode(v)?;
        Ok(PegOrder {
            order_id: r.order_id.clone(),
            direction,
            deposit_address: r.peg_addr.clone(),
            payout_address: payout_address.to_owned(),
            created_at_ms: r.created_at,
            expires_at_ms: r.expires_at_ms(),
        })
    }

    async fn get_status(
        &mut self,
        direction: PegDirection,
        order_id: &str,
    ) -> Result<PegProgress, PegError> {
        let req = Request::peg_status(direction.as_peg_in_flag(), order_id);
        let v = match self.call(&req).await {
            Ok(v) => v,
            Err(Error::Protocol(m)) if looks_like_not_found(&m) => {
                return Err(PegError::OrderNotFound(order_id.to_owned()))
            }
            Err(e) => return Err(read_failure(e)),
        };
        let status: PegOrderStatus = decode(v)?;
        Ok(to_progress(&status, direction))
    }
}

impl<C: WsConnector> PegRepository for SideSwapPegRepository<C> {
    fn get_limits(
        &mut self,
    ) -> impl Future<Output = Result<PegServerLimits, PegError>> + MaybeSend {
        self.client.get_limits()
    }

    fn create_order(
        &mut self,
        direction: PegDirection,
        payout_address: &str,
    ) -> impl Future<Output = Result<PegOrder, PegError>> + MaybeSend {
        self.client.create_order(direction, payout_address)
    }

    fn get_status(
        &mut self,
        direction: PegDirection,
        order_id: &str,
    ) -> impl Future<Output = Result<PegProgress, PegError>> + MaybeSend {
        self.client.get_status(direction, order_id)
    }
}

/// A borrowed repository is a repository. Lets a caller keep ownership.
impl<R: PegRepository> PegRepository for &mut R {
    fn get_limits(
        &mut self,
    ) -> impl Future<Output = Result<PegServerLimits, PegError>> + MaybeSend {
        (**self).get_limits()
    }

    fn create_order(
        &mut self,
        direction: PegDirection,
        payout_address: &str,
    ) -> impl Future<Output = Result<PegOrder, PegError>> + MaybeSend {
        (**self).create_order(direction, payout_address)
    }

    fn get_status(
        &mut self,
        direction: PegDirection,
        order_id: &str,
    ) -> impl Future<Output = Result<PegProgress, PegError>> + MaybeSend {
        (**self).get_status(direction, order_id)
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use serde_json::{json, Value};

    use super::*;
    use crate::testing::{block_on, MockWs};

    fn ws(handler: fn(&str, Value) -> Value) -> MockWs {
        MockWs::new(move |f| {
            let v: Value = serde_json::from_str(f).unwrap();
            let m = v["method"].as_str().unwrap().to_owned();
            if m == "login_client" {
                return vec![json!({"id": v["id"], "method": m, "result": {}}).to_string()];
            }
            let mut out = handler(&m, v["params"].clone());
            out["id"] = v["id"].clone();
            out["method"] = json!(m);
            vec![out.to_string()]
        })
    }

    #[test]
    fn limits_from_server_status() {
        let mut r = SideSwapPegRepository::new(SideSwapClient::new(
            ws(|_, _| {
                json!({"result": {"elements_fee_rate": 0.1, "min_peg_in_amount": 10000,
                "min_peg_out_amount": 25000, "server_fee_percent_peg_in": 0.1, "server_fee_percent_peg_out": 0.1}})
            }),
            "k",
        ));
        let l = block_on(r.get_limits()).unwrap();
        assert_eq!((l.min_peg_in_sat, l.min_peg_out_sat), (10_000, 25_000));
    }

    #[test]
    fn create_order_maps_response_and_errors() {
        let mut r = SideSwapPegRepository::new(SideSwapClient::new(
            ws(|_, p| {
                if p["recv_addr"] == "bad" {
                    json!({"error": {"code": -1, "message": "invalid address"}})
                } else {
                    json!({"result": {"created_at": 1786210521499u64, "expires_at": 0,
                    "order_id": "9093164d", "peg_addr": "lq1qqgdcmfjrx", "recv_amount": null}})
                }
            }),
            "k",
        ));
        let o = block_on(r.create_order(PegDirection::PegOut, "bc1qpayout")).unwrap();
        assert_eq!(
            (o.deposit_address.as_str(), o.payout_address.as_str()),
            ("lq1qqgdcmfjrx", "bc1qpayout")
        );
        assert_eq!((o.created_at_ms, o.expires_at_ms), (1786210521499, None));
        assert_eq!(
            block_on(r.create_order(PegDirection::PegOut, "bad")),
            Err(PegError::ProviderRejected("invalid address".into()))
        );
        assert!(matches!(
            block_on(r.create_order(PegDirection::PegOut, "  ")),
            Err(PegError::WalletFailure(_))
        ));
    }

    #[test]
    fn status_maps_deposits_and_not_found() {
        let mut r = SideSwapPegRepository::new(SideSwapClient::new(
            ws(|_, p| {
                if p["order_id"] == "gone" {
                    return json!({"error": {"message": "Order not found"}});
                }
                json!({"result": {"addr": "bc1qdep", "addr_recv": "lq1recv", "created_at": 1, "expires_at": 0,
                "order_id": "o1", "peg_in": true, "list": [
                    {"tx_hash": "a", "vout": 0, "status": "x", "amount": 60000, "payout": 59000,
                     "payout_txid": "pa", "created_at": 2, "tx_state": "Done", "tx_state_code": 4},
                    {"tx_hash": "b", "vout": 1, "status": "x", "amount": 40000, "created_at": 3,
                     "tx_state": "Detected", "tx_state_code": 2, "detected_confs": 1, "total_confs": 2}]}})
            }),
            "k",
        ));
        let p = block_on(r.get_status(PegDirection::PegIn, "o1")).unwrap();
        assert_eq!(p.phase, PegPhase::Detected);
        assert_eq!(p.total_deposited_sat(), 100_000);
        assert_eq!(p.payout_tx_id(), Some("pa"));
        assert_eq!(
            block_on(r.get_status(PegDirection::PegIn, "gone")),
            Err(PegError::OrderNotFound("gone".into()))
        );
    }

    #[test]
    fn borrowed_client_is_a_repository() {
        let mut client = SideSwapClient::new(
            ws(|_, _| {
                json!({"result": {"elements_fee_rate": 0.1, "min_peg_in_amount": 1000,
                "min_peg_out_amount": 2000, "server_fee_percent_peg_in": 0.1, "server_fee_percent_peg_out": 0.1}})
            }),
            "k",
        );
        async fn limits<R: PegRepository>(mut repository: R) -> Result<PegServerLimits, PegError> {
            repository.get_limits().await
        }
        assert_eq!(block_on(limits(&mut client)).unwrap().min_peg_out_sat, 2000);
        assert!(client.is_connected());
    }

    #[test]
    fn closed_socket_is_transport_failure() {
        let mut r = SideSwapPegRepository::new(SideSwapClient::new(MockWs::new(|_| vec![]), "k"));
        assert!(matches!(
            block_on(r.get_limits()),
            Err(PegError::TransportFailure(_))
        ));
    }

    #[test]
    fn every_tx_state_maps() {
        assert!(!tx_state_to_phase(TxState::Unknown).is_terminal());
        assert_eq!(tx_state_to_phase(TxState::Done), PegPhase::Completed);
        assert_eq!(
            tx_state_to_phase(TxState::InsufficientAmount),
            PegPhase::InsufficientAmount
        );
        assert_eq!(tx_state_to_phase(TxState::Processing), PegPhase::Processing);
    }
}
