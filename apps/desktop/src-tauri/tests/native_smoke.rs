#![cfg(feature = "testnet")]
//! Explicit opt-in: real OS credential store and public testnet endpoints.
use mooze_app::dto::BackendDto;
use mooze_desktop::{
    dto::WalletChain,
    platform::{runtime, secure_store::KeyringStore, sled_kv::SledKv, NativePlatform},
    session::WalletSession,
};

#[tokio::test]
#[ignore = "requires macOS Keychain access and public testnet connectivity"]
async fn native_persistence_and_testnet_sync() {
    runtime::install_crypto_provider();
    let directory = tempfile::tempdir().unwrap();
    let service = format!("app.mooze.desktop.smoke.{}", uuid::Uuid::new_v4());
    let p = NativePlatform {
        kv: SledKv::open(directory.path().join("testnet")).unwrap(),
        secure: KeyringStore::new(service.clone()),
    };
    let s = WalletSession::new(p.clone(), BackendDto::Electrum);
    let result = tokio::time::timeout(std::time::Duration::from_secs(150), async {
        let started = std::time::Instant::now();
        s.import_wallet(
            mooze_core::wallet::mnemonic::generate(false),
            "123456".into(),
        )
        .await
        .unwrap();
        eprintln!("native import and keychain: {:?}", started.elapsed());
        for chain in [WalletChain::Bitcoin, WalletChain::Liquid] {
            let address = s.receive(chain).await.unwrap();
            assert!(!address.address.as_deref().unwrap_or_default().is_empty());
            eprintln!("{chain:?} receive address generated");
        }
        s.lock().await.unwrap();
        assert!(s.snapshot().await.is_err());
        s.stop().await;
        let restarted = WalletSession::new(p, BackendDto::Electrum);
        assert_eq!(restarted.status().await.unwrap().status, "locked");
        restarted.unlock("123456".into()).await.unwrap();
        loop {
            let snapshot = restarted.snapshot().await.unwrap();
            if snapshot.chains.len() == 2 {
                for c in &snapshot.chains {
                    eprintln!(
                        "{:?}: {}, last success {:?}, elapsed {:?}",
                        c.chain,
                        c.phase,
                        c.last_success_at_ms,
                        started.elapsed()
                    );
                }
                restarted.stop().await;
                assert!(
                    snapshot.chains.iter().all(|c| c.phase == "ready"),
                    "one or more testnet endpoints failed"
                );
                break;
            }
            tokio::time::sleep(std::time::Duration::from_millis(250)).await;
        }
    })
    .await;
    s.stop().await;
    // Only this invocation's isolated disposable credential item is removed.
    let _ = keyring::Entry::new(&service, "wallet-secrets")
        .unwrap()
        .delete_credential();
    result.expect("native smoke timed out");
}
