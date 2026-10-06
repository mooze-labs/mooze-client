//! Peg entities and errors. Port of `domain/entities/peg.dart` and
//! `domain/entities/peg_error.dart`.

use serde::{Deserialize, Serialize};

use crate::sideswap::protocol::ServerStatus;
use crate::Error;

/// Direction of a peg.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum PegDirection {
    /// BTC to L-BTC. Funded from the Bitcoin wallet.
    PegIn,
    /// L-BTC to BTC. Funded from the Liquid wallet.
    PegOut,
}

impl PegDirection {
    /// True for peg-in.
    pub fn is_peg_in(self) -> bool {
        self == PegDirection::PegIn
    }

    /// SideSwap's `peg_in` flag.
    pub fn as_peg_in_flag(self) -> bool {
        self.is_peg_in()
    }

    /// Direction from the `peg_in` flag.
    pub fn from_peg_in_flag(peg_in: bool) -> Self {
        if peg_in {
            PegDirection::PegIn
        } else {
            PegDirection::PegOut
        }
    }

    /// Audit-log label.
    pub fn audit_direction(self) -> &'static str {
        if self.is_peg_in() {
            "btc_to_lbtc"
        } else {
            "lbtc_to_btc"
        }
    }
}

/// A peg order created with SideSwap, before any deposit.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegOrder {
    /// SideSwap order id. The recovery key.
    pub order_id: String,
    pub direction: PegDirection,
    /// Where the user sends funds (from SideSwap).
    pub deposit_address: String,
    /// Where proceeds land (ours).
    pub payout_address: String,
    pub created_at_ms: u64,
    /// `None` when SideSwap reports no expiry.
    pub expires_at_ms: Option<u64>,
}

impl PegOrder {
    /// True after the expiry time.
    pub fn is_expired(&self, now_ms: u64) -> bool {
        self.expires_at_ms.is_some_and(|e| now_ms > e)
    }
}

/// Phase of a peg order or deposit.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum PegPhase {
    /// Order exists, no deposit yet.
    AwaitingDeposit,
    /// Deposit seen, gathering confirmations.
    Detected,
    /// SideSwap is executing the peg.
    Processing,
    /// Proceeds sent. Terminal.
    Completed,
    /// Deposit below the minimum. Terminal.
    InsufficientAmount,
    /// Local failure. Terminal.
    Failed,
}

impl PegPhase {
    /// True for completed, insufficient amount and failed.
    pub fn is_terminal(self) -> bool {
        matches!(
            self,
            PegPhase::Completed | PegPhase::InsufficientAmount | PegPhase::Failed
        )
    }

    /// Ordering used to refuse backward transitions.
    pub fn progress_rank(self) -> u8 {
        match self {
            PegPhase::Failed => 0,
            PegPhase::InsufficientAmount => 1,
            PegPhase::AwaitingDeposit => 2,
            PegPhase::Detected => 3,
            PegPhase::Processing => 4,
            PegPhase::Completed => 5,
        }
    }

    /// Dart enum name, for logs and store keys.
    pub fn name(self) -> &'static str {
        match self {
            PegPhase::AwaitingDeposit => "awaitingDeposit",
            PegPhase::Detected => "detected",
            PegPhase::Processing => "processing",
            PegPhase::Completed => "completed",
            PegPhase::InsufficientAmount => "insufficientAmount",
            PegPhase::Failed => "failed",
        }
    }
}

/// One deposit transaction inside an order.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegDeposit {
    pub tx_id: String,
    pub phase: PegPhase,
    pub amount_sat: u64,
    /// Paid out net of SideSwap's fee.
    pub payout_sat: Option<u64>,
    /// Txid on the destination chain.
    pub payout_tx_id: Option<String>,
    pub detected_confirmations: Option<u32>,
    pub total_confirmations: Option<u32>,
}

/// Aggregated state of an order.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PegProgress {
    pub order_id: String,
    pub direction: PegDirection,
    /// Least-advanced deposit wins.
    pub phase: PegPhase,
    pub deposits: Vec<PegDeposit>,
    pub deposit_address: String,
    pub payout_address: String,
}

impl PegProgress {
    /// True when the phase is terminal.
    pub fn is_terminal(&self) -> bool {
        self.phase.is_terminal()
    }

    /// Sum of all deposits.
    pub fn total_deposited_sat(&self) -> u64 {
        self.deposits.iter().map(|d| d.amount_sat).sum()
    }

    /// Sum of known payouts.
    pub fn total_payout_sat(&self) -> u64 {
        self.deposits.iter().filter_map(|d| d.payout_sat).sum()
    }

    /// Destination txid when exactly one payout exists.
    pub fn payout_tx_id(&self) -> Option<&str> {
        let mut ids = self
            .deposits
            .iter()
            .filter_map(|d| d.payout_tx_id.as_deref());
        match (ids.next(), ids.next()) {
            (Some(id), None) => Some(id),
            _ => None,
        }
    }
}

/// Least-advanced deposit governs the order phase. No deposits means awaiting.
pub fn aggregate_phase(deposits: &[PegDeposit]) -> PegPhase {
    deposits
        .iter()
        .map(|d| d.phase)
        .reduce(|a, b| {
            if a.progress_rank() <= b.progress_rank() {
                a
            } else {
                b
            }
        })
        .unwrap_or(PegPhase::AwaitingDeposit)
}

/// Minimums and fee percentages from `server_status`. No maximum exists.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct PegServerLimits {
    pub min_peg_in_sat: u64,
    pub min_peg_out_sat: u64,
    pub server_fee_percent_peg_in: f64,
    pub server_fee_percent_peg_out: f64,
}

impl From<&ServerStatus> for PegServerLimits {
    fn from(s: &ServerStatus) -> Self {
        Self {
            min_peg_in_sat: s.min_peg_in_amount,
            min_peg_out_sat: s.min_peg_out_amount,
            server_fee_percent_peg_in: s.server_fee_percent_peg_in,
            server_fee_percent_peg_out: s.server_fee_percent_peg_out,
        }
    }
}

impl PegServerLimits {
    /// Minimum for a direction.
    pub fn minimum_for(&self, direction: PegDirection) -> u64 {
        if direction.is_peg_in() {
            self.min_peg_in_sat
        } else {
            self.min_peg_out_sat
        }
    }

    /// Fee percent for a direction.
    pub fn fee_percent_for(&self, direction: PegDirection) -> f64 {
        if direction.is_peg_in() {
            self.server_fee_percent_peg_in
        } else {
            self.server_fee_percent_peg_out
        }
    }

    /// SideSwap's cut, rounded up so the fee is never understated.
    pub fn service_fee_sat(&self, direction: PegDirection, amount_sat: u64) -> u64 {
        let pct = self.fee_percent_for(direction);
        if pct <= 0.0 || amount_sat == 0 {
            return 0;
        }
        (amount_sat as f64 * pct / 100.0).ceil() as u64
    }
}

/// Failure taxonomy for peg operations.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PegError {
    /// Amount below SideSwap's minimum for the direction.
    BelowMinimum { minimum_sat: u64, actual_sat: u64 },
    /// Wallet cannot cover amount plus fees.
    InsufficientFunds(String),
    /// SideSwap rejected the request or sent an unusable payload.
    ProviderRejected(String),
    /// The order does not exist. Carries the order id.
    OrderNotFound(String),
    /// Socket down or no response. Retryable for reads.
    TransportFailure(String),
    /// The wallet could not build, sign or broadcast.
    WalletFailure(String),
    /// Another Liquid spend holds the UTXO lock.
    WalletBusy(String),
    /// A write may or may not have happened.
    UnknownOutcome {
        stage: String,
        detail: String,
        order_id: Option<String>,
    },
}

impl PegError {
    /// Portuguese user-facing message, same text as Dart.
    pub fn message(&self) -> String {
        match self {
            PegError::BelowMinimum { minimum_sat, .. } => format!("Valor mínimo é {minimum_sat} sats"),
            PegError::InsufficientFunds(d) => format!("Saldo insuficiente: {d}"),
            PegError::ProviderRejected(d) => format!("SideSwap recusou a operação: {d}"),
            PegError::OrderNotFound(_) => "Ordem não encontrada".to_owned(),
            PegError::TransportFailure(_) => "Falha de conexão com a SideSwap. Tente novamente.".to_owned(),
            PegError::WalletFailure(d) => format!("Erro na carteira: {d}"),
            PegError::WalletBusy(d) => d.clone(),
            PegError::UnknownOutcome { .. } => {
                "Não foi possível confirmar a operação. Verifique o histórico antes de tentar novamente.".to_owned()
            }
        }
    }
}

impl std::fmt::Display for PegError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.message())
    }
}

impl std::error::Error for PegError {}

impl From<PegError> for Error {
    fn from(e: PegError) -> Self {
        let msg = e.message();
        match e {
            PegError::BelowMinimum { .. } | PegError::InsufficientFunds(_) => {
                Error::InvalidInput(msg)
            }
            PegError::ProviderRejected(_) | PegError::OrderNotFound(_) => Error::Protocol(msg),
            PegError::TransportFailure(_) => Error::Network(msg),
            PegError::WalletBusy(_) => Error::InvalidState(msg),
            PegError::UnknownOutcome { .. } => Error::Timeout(msg),
            PegError::WalletFailure(_) => Error::Unexpected(msg),
        }
    }
}

/// Liquid address prefixes. Guards peg-in funding from reaching Liquid.
pub const LIQUID_ADDRESS_PREFIXES: [&str; 6] = ["lq1", "tlq1", "ex1", "tex1", "el1", "ert1"];

/// True if `address` looks like a Liquid address. Port of `PegWalletImpl`.
pub fn looks_like_liquid_address(address: &str) -> bool {
    let a = address.trim().to_lowercase();
    LIQUID_ADDRESS_PREFIXES.iter().any(|p| a.starts_with(p))
}

/// Maps a wallet error text to a peg error. Port of `_classifyWalletError`.
pub fn classify_wallet_error(message: &str) -> PegError {
    let m = message.to_lowercase();
    if m.contains("insufficient") || m.contains("insuficiente") || m.contains("saldo") {
        PegError::InsufficientFunds(message.to_owned())
    } else {
        PegError::WalletFailure(message.to_owned())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn dep(phase: PegPhase) -> PegDeposit {
        PegDeposit {
            tx_id: "t".into(),
            phase,
            amount_sat: 1000,
            payout_sat: None,
            payout_tx_id: None,
            detected_confirmations: None,
            total_confirmations: None,
        }
    }

    const LIMITS: PegServerLimits = PegServerLimits {
        min_peg_in_sat: 10_000,
        min_peg_out_sat: 25_000,
        server_fee_percent_peg_in: 0.1,
        server_fee_percent_peg_out: 0.1,
    };

    #[test]
    fn aggregation_least_advanced_wins() {
        assert_eq!(aggregate_phase(&[]), PegPhase::AwaitingDeposit);
        assert_eq!(
            aggregate_phase(&[dep(PegPhase::Completed), dep(PegPhase::Detected)]),
            PegPhase::Detected
        );
        assert_eq!(
            aggregate_phase(&[dep(PegPhase::Completed), dep(PegPhase::Completed)]),
            PegPhase::Completed
        );
        assert_eq!(
            aggregate_phase(&[dep(PegPhase::Completed), dep(PegPhase::InsufficientAmount)]),
            PegPhase::InsufficientAmount
        );
    }

    #[test]
    fn limits_and_fee_rounding() {
        assert_eq!(LIMITS.minimum_for(PegDirection::PegIn), 10_000);
        assert_eq!(LIMITS.minimum_for(PegDirection::PegOut), 25_000);
        assert_eq!(LIMITS.service_fee_sat(PegDirection::PegOut, 100_000), 100);
        assert_eq!(LIMITS.service_fee_sat(PegDirection::PegOut, 1001), 2);
        assert_eq!(LIMITS.service_fee_sat(PegDirection::PegOut, 199_974), 200);
        assert_eq!(LIMITS.service_fee_sat(PegDirection::PegOut, 0), 0);
    }

    #[test]
    fn payout_txid_only_when_unique() {
        let mut a = dep(PegPhase::Completed);
        a.payout_tx_id = Some("x".into());
        a.payout_sat = Some(900);
        let mut p = PegProgress {
            order_id: "o".into(),
            direction: PegDirection::PegIn,
            phase: PegPhase::Completed,
            deposits: vec![a.clone()],
            deposit_address: "d".into(),
            payout_address: "p".into(),
        };
        assert_eq!(p.payout_tx_id(), Some("x"));
        assert_eq!((p.total_deposited_sat(), p.total_payout_sat()), (1000, 900));
        p.deposits.push(a);
        assert_eq!(p.payout_tx_id(), None);
    }

    #[test]
    fn wallet_helpers() {
        assert!(looks_like_liquid_address(" LQ1qq..."));
        assert!(!looks_like_liquid_address("bc1q..."));
        assert!(matches!(
            classify_wallet_error("Saldo baixo"),
            PegError::InsufficientFunds(_)
        ));
        assert!(matches!(
            classify_wallet_error("boom"),
            PegError::WalletFailure(_)
        ));
        assert_eq!(
            PegError::BelowMinimum {
                minimum_sat: 10,
                actual_sat: 1
            }
            .message(),
            "Valor mínimo é 10 sats"
        );
        assert!(PegError::TransportFailure("x".into())
            .to_string()
            .starts_with("Falha"));
    }

    #[test]
    fn expiry() {
        let o = PegOrder {
            order_id: "o".into(),
            direction: PegDirection::PegOut,
            deposit_address: "d".into(),
            payout_address: "p".into(),
            created_at_ms: 0,
            expires_at_ms: Some(10),
        };
        assert!(!o.is_expired(10));
        assert!(o.is_expired(11));
    }
}
