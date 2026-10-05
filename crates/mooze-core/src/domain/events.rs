use serde::{Deserialize, Serialize};

use super::{ChainId, Transaction, TransactionStatus};

/// Result of one chain sync.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncOutcome {
    pub chain: ChainId,
    pub fetched: usize,
    pub changed: usize,
    pub duration_ms: u64,
}

impl SyncOutcome {
    /// Outcome with zero counts.
    pub fn empty(chain: ChainId) -> Self {
        Self { chain, fetched: 0, changed: 0, duration_ms: 0 }
    }
}

/// Kind of transaction change.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum TransactionEventKind {
    Created,
    StatusChanged,
    ConfirmationsChanged,
}

/// A transaction appeared or changed during sync.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TransactionEvent {
    pub kind: TransactionEventKind,
    pub transaction: Transaction,
    pub observed_at_ms: u64,
    pub previous_status: Option<TransactionStatus>,
    pub previous_confirmations: Option<u32>,
}

impl TransactionEvent {
    /// Chain of the transaction.
    pub fn chain(&self) -> ChainId {
        self.transaction.chain
    }

    /// Compares a fresh record with the stored one. `None` if nothing changed.
    pub fn diff(previous: Option<&Transaction>, current: &Transaction, now_ms: u64) -> Option<Self> {
        let (kind, prev_status, prev_conf) = match previous {
            None => (TransactionEventKind::Created, None, None),
            Some(p) if p.status != current.status => {
                (TransactionEventKind::StatusChanged, Some(p.status), Some(p.confirmations))
            }
            Some(p) if p.confirmations != current.confirmations => {
                (TransactionEventKind::ConfirmationsChanged, Some(p.status), Some(p.confirmations))
            }
            Some(_) => return None,
        };
        Some(Self {
            kind,
            transaction: current.clone(),
            observed_at_ms: now_ms,
            previous_status: prev_status,
            previous_confirmations: prev_conf,
        })
    }
}
