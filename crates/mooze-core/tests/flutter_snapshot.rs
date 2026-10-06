//! Imports the golden snapshot that the app's exporter test also checks.
//!
//! The exporter test asserts that the Flutter app writes exactly
//! `tests/fixtures/flutter_snapshot_v1.json`. This test asserts that the
//! core imports that file. Together they pin the format on both sides.

use std::sync::Arc;

use mooze_core::domain::ChainId;
use mooze_core::migration::{import_flutter_data, parse_snapshot};
use mooze_core::pix::{DepositStore, FavoritePayerStore, PixFlag, PixFlagsStore};
use mooze_core::store::{NodeSettings, NotifiedTxRegistry, TransactionStore};
use mooze_core::testing::{block_on, FixedClock, MemoryKv};

const FIXTURE: &[u8] = include_bytes!("fixtures/flutter_snapshot_v1.json");

#[test]
fn imports_the_golden_snapshot() {
    let snapshot = parse_snapshot(FIXTURE).expect("fixture parses");
    let kv = MemoryKv::new();
    let clock = Arc::new(FixedClock::new(1_759_686_400_000));
    let report = block_on(import_flutter_data(&kv, &clock, &snapshot)).expect("import");

    assert!(report.skipped.is_empty(), "unexpected skips: {:?}", report.skipped);
    for table in ["transactions", "swaps", "pegs", "deposits", "products", "sync_metadata", "favorite_payers"] {
        assert_eq!(report.copied.get(table), Some(&1), "{table}");
    }

    block_on(async {
        let tx = TransactionStore::new(kv.clone()).find_by_id("aa").await.unwrap().unwrap();
        assert_eq!(tx.label.as_deref(), Some("rent"));
        assert!(NotifiedTxRegistry::new(kv.clone()).contains(ChainId::Liquid, "aa").await.unwrap());
        assert!(DepositStore::new(kv.clone()).get_deposit("dep1").await.unwrap().is_some());
        assert_eq!(FavoritePayerStore::new(kv.clone()).get_all().await.unwrap().len(), 1);
        assert!(PixFlagsStore::new(kv.clone()).is_set(PixFlag::TutorialShown).await.unwrap());
        assert_eq!(NodeSettings::new(kv.clone()).node_url(ChainId::Bitcoin).await.unwrap(), "ssl://my.node:50002");
    });
}
