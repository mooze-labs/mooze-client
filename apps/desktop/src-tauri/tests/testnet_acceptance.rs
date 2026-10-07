#![cfg(feature = "testnet")]
//! Opt-in disposable profile. Prints only public testnet addresses and chain data.
#![cfg(debug_assertions)]
use mooze_app::dto::BackendDto;
use mooze_desktop::{
    dto::WalletChain,
    platform::{runtime, NativePlatform},
    session::WalletSession,
};
#[tokio::test]
#[ignore = "requires explicit isolated profile, OS credential access and testnet connectivity"]
async fn disposable_profile_acceptance() {
    runtime::install_crypto_provider();
    let profile = std::env::var("MOOZE_TESTNET_PROFILE").expect("set an isolated profile name");
    let root = std::env::var_os("MOOZE_TESTNET_APP_DATA").expect("set the app data root");
    let platform = NativePlatform::open_debug_profile(root.into(), &profile).unwrap();
    let session = WalletSession::new(platform, BackendDto::Electrum);
    if session.status().await.unwrap().status == "empty" {
        session
            .import_wallet(
                mooze_core::wallet::mnemonic::generate(false),
                "123456".into(),
            )
            .await
            .unwrap();
    } else {
        session.unlock("123456".into()).await.unwrap();
    }
    session.set_lock_minutes(15).await.unwrap();
    for chain in [WalletChain::Bitcoin, WalletChain::Liquid] {
        println!(
            "RECEIVE {chain:?}: {}",
            session.receive(chain).await.unwrap().address.unwrap()
        );
    }
    let result = tokio::time::timeout(std::time::Duration::from_secs(90), async {
        loop {
            let snapshot = session.snapshot().await.unwrap();
            if snapshot.chains.len() == 2 {
                println!(
                    "CHAINS {}",
                    serde_json::to_string(&snapshot.chains).unwrap()
                );
                println!(
                    "HOLDINGS {}",
                    serde_json::to_string(&session.holdings().await.unwrap()).unwrap()
                );
                println!(
                    "ACTIVITY {}",
                    serde_json::to_string(&snapshot.activity).unwrap()
                );
                assert!(snapshot.chains.iter().all(|chain| chain.phase == "ready"));
                break;
            }
            tokio::time::sleep(std::time::Duration::from_millis(250)).await;
        }
    })
    .await;
    session.stop().await;
    result.expect("testnet sync timed out");
}
