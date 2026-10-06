//! Transaction change tracking shared by both wallets. Port of the
//! `_seen` map and `_diffAndEmit` in the BDK and LWK services.
//!
//! Dart pushed events into a broadcast stream. Here the wallet keeps an
//! outbox; the caller drains it with `take_events`.

use std::collections::HashMap;

use crate::domain::{Transaction, TransactionEvent, TransactionEventKind, TransactionStatus};

/// Last status and confirmations seen for each transaction id.
#[derive(Debug, Clone, Default)]
pub struct TxTracker {
    seen: HashMap<String, (TransactionStatus, u32)>,
    outbox: Vec<TransactionEvent>,
}

impl TxTracker {
    /// Empty tracker.
    pub fn new() -> Self {
        Self::default()
    }

    /// Records the list without emitting events (cold restore priming).
    pub fn prime(&mut self, txs: &[Transaction]) {
        for tx in txs {
            self.seen
                .insert(tx.id.clone(), (tx.status, tx.confirmations));
        }
    }

    /// True if the id was seen before.
    pub fn contains(&self, id: &str) -> bool {
        self.seen.contains_key(id)
    }

    /// Compares `incoming` with the seen state, queues one event per change
    /// and returns the number of changes.
    pub fn diff(&mut self, incoming: &[Transaction], now_ms: u64) -> usize {
        let mut changes = 0;
        for tx in incoming {
            let kind = match self.seen.get(&tx.id) {
                None => Some((TransactionEventKind::Created, None)),
                Some(&(status, conf)) if status != tx.status => {
                    Some((TransactionEventKind::StatusChanged, Some((status, conf))))
                }
                Some(&(status, conf)) if conf != tx.confirmations => Some((
                    TransactionEventKind::ConfirmationsChanged,
                    Some((status, conf)),
                )),
                Some(_) => None,
            };
            if let Some((kind, prev)) = kind {
                changes += 1;
                self.seen
                    .insert(tx.id.clone(), (tx.status, tx.confirmations));
                self.outbox.push(TransactionEvent {
                    kind,
                    transaction: tx.clone(),
                    observed_at_ms: now_ms,
                    previous_status: prev.map(|p| p.0),
                    previous_confirmations: prev.map(|p| p.1),
                });
            }
        }
        changes
    }

    /// Records a transaction the wallet just broadcast and queues a
    /// `created` event. Returns false (no event) if the id was seen.
    pub fn register(&mut self, tx: &Transaction, now_ms: u64) -> bool {
        if self.seen.contains_key(&tx.id) {
            return false;
        }
        self.seen
            .insert(tx.id.clone(), (tx.status, tx.confirmations));
        self.outbox.push(TransactionEvent {
            kind: TransactionEventKind::Created,
            transaction: tx.clone(),
            observed_at_ms: now_ms,
            previous_status: None,
            previous_confirmations: None,
        });
        true
    }

    /// Records a transaction and always queues a `created` event, like the
    /// BDK `sendOnchain` path (it does not check `_seen`).
    pub fn force_register(&mut self, tx: &Transaction, now_ms: u64) {
        self.seen.remove(&tx.id);
        self.register(tx, now_ms);
    }

    /// Drains queued events, oldest first.
    pub fn take_events(&mut self) -> Vec<TransactionEvent> {
        std::mem::take(&mut self.outbox)
    }

    /// Forgets everything (disconnect).
    pub fn clear(&mut self) {
        self.seen.clear();
        self.outbox.clear();
    }
}

/// Sorts newest first, like `sort((a, b) => b.timestamp.compareTo(a.timestamp))`.
pub fn sort_newest_first(txs: &mut [Transaction]) {
    txs.sort_by_key(|t| std::cmp::Reverse(t.timestamp_ms));
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{ChainId, TransactionDirection};

    fn tx(id: &str, status: TransactionStatus, conf: u32) -> Transaction {
        let mut t = Transaction::new(
            id,
            ChainId::Bitcoin,
            TransactionDirection::Incoming,
            status,
            10,
            1,
            5,
        );
        t.confirmations = conf;
        t
    }

    #[test]
    fn diff_emits_created_status_and_confirmations() {
        let mut tr = TxTracker::new();
        assert_eq!(tr.diff(&[tx("a", TransactionStatus::Pending, 0)], 1), 1);
        assert_eq!(tr.diff(&[tx("a", TransactionStatus::Pending, 0)], 2), 0);
        assert_eq!(tr.diff(&[tx("a", TransactionStatus::Confirmed, 1)], 3), 1);
        assert_eq!(tr.diff(&[tx("a", TransactionStatus::Confirmed, 2)], 4), 1);
        let ev = tr.take_events();
        assert_eq!(ev.len(), 3);
        assert_eq!(ev[0].kind, TransactionEventKind::Created);
        assert_eq!(ev[1].kind, TransactionEventKind::StatusChanged);
        assert_eq!(ev[1].previous_status, Some(TransactionStatus::Pending));
        assert_eq!(ev[2].kind, TransactionEventKind::ConfirmationsChanged);
        assert_eq!(ev[2].previous_confirmations, Some(1));
        assert!(tr.take_events().is_empty());
    }

    #[test]
    fn prime_and_register_dedup() {
        let mut tr = TxTracker::new();
        tr.prime(&[tx("a", TransactionStatus::Pending, 0)]);
        assert_eq!(tr.diff(&[tx("a", TransactionStatus::Pending, 0)], 1), 0);
        assert!(!tr.register(&tx("a", TransactionStatus::Pending, 0), 1));
        assert!(tr.register(&tx("b", TransactionStatus::Pending, 0), 1));
        tr.force_register(&tx("b", TransactionStatus::Pending, 0), 2);
        assert_eq!(tr.take_events().len(), 2);
    }

    #[test]
    fn sorts_newest_first() {
        let mut a = tx("a", TransactionStatus::Pending, 0);
        a.timestamp_ms = 1;
        let mut b = tx("b", TransactionStatus::Pending, 0);
        b.timestamp_ms = 9;
        let mut v = vec![a, b];
        sort_newest_first(&mut v);
        assert_eq!(v[0].id, "b");
    }
}
