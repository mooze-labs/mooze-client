//! Opt-in, local-only funded acceptance checks. Never starts or destroys a node.
use bitcoin::Amount;
use mooze_core::{
    domain::{AppNetwork, ChainId, SendRequest, WalletCredentials},
    testing::{FixedClock, MemoryKv},
    wallet::{bitcoin::BitcoinWallet, endpoints::EndpointResolver, liquid::LiquidWallet, mnemonic},
};
use nigiri_rs::{Bitcoin, Liquid, NigiriClient};
use std::{
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error + Send + Sync>>;

#[tokio::main]
async fn main() -> Result<()> {
    if std::env::args().nth(1).as_deref() != Some("--funded-local-regtest") {
        return Err("Run with --funded-local-regtest against an already running Nigiri".into());
    }
    // No endpoint environment overrides: this executable can only reach local Nigiri.
    let btc = NigiriClient::<Bitcoin>::new();
    let liquid = NigiriClient::<Liquid>::new();
    // Refresh an old regtest tip before Electrs readiness: it waits for IBD to end.
    // These rewards also mature the host-owned faucet without resetting its chain.
    let bitcoin_destination = btc.new_address().await?.to_string();
    btc.generate_to_address(101, &bitcoin_destination).await?;
    btc.wait_ready().await?;
    liquid.wait_ready().await?;
    println!("PASS: local Bitcoin and Liquid indexers ready");
    let credentials = WalletCredentials {
        mnemonic: mnemonic::generate(false),
        network: AppNetwork::Regtest,
    };
    let clock = Arc::new(FixedClock::new(
        SystemTime::now().duration_since(UNIX_EPOCH)?.as_millis() as u64,
    ));
    let endpoints = EndpointResolver::with_defaults(AppNetwork::Regtest)
        .with_custom_node(ChainId::Bitcoin, "http://127.0.0.1:30000")
        .with_custom_node(ChainId::Liquid, "http://127.0.0.1:30001");
    let bitcoin_store = MemoryKv::new();
    let liquid_store = MemoryKv::new();
    let mut bw = BitcoinWallet::connect(
        &credentials,
        bitcoin_store.clone(),
        clock.clone(),
        endpoints.clone(),
    )
    .await?;
    let mut lw = LiquidWallet::connect(
        &credentials,
        liquid_store.clone(),
        clock.clone(),
        endpoints.clone(),
    )
    .await?;
    let bitcoin_receive = bw.next_unused_address().await?.address;
    let liquid_receive = lw.receive_address().await?;
    assert!(bitcoin_receive.starts_with("bcrt1"));
    assert!(liquid_receive.starts_with("el1"));
    assert_eq!(lw.policy_asset(), nigiri_rs::LBTC_REGTEST_ASSET.to_string());
    btc.faucet(&bitcoin_receive, Some(Amount::from_sat(200_000)))
        .await?;
    liquid
        .faucet(&liquid_receive, Some(Amount::from_sat(200_000)))
        .await?;
    // Mint stays in the node wallet. Its RPC quantity is whole coins; metadata
    // precision does not change Elements' RPC amount scale. Fund our wallet with
    // an explicit base-unit Amount instead of interpreting mint's quantity.
    let liquid_destination = liquid.new_address().await?.to_string();
    let minted = liquid
        .mint(&liquid_destination, 1, "Mooze regtest fixture", "MZT")
        .await?;
    println!(
        "Local fixture issued: asset {} transfer {}",
        minted.asset, minted.txid
    );
    let asset_funding = liquid
        .faucet_asset(&liquid_receive, Amount::from_sat(100_000), &minted.asset)
        .await?;
    liquid.generate_to_address(1, &liquid_destination).await?;
    liquid
        .wait_for_confirmation(&asset_funding, Duration::from_secs(30))
        .await?;
    for _ in 0..30 {
        bw.sync().await?;
        lw.sync().await?;
        if bw.balance().assets.iter().any(|a| a.amount_sat == 200_000)
            && lw.balance().assets.iter().any(|a| {
                a.asset_id.as_deref() == Some(&minted.asset.to_string()) && a.amount_sat == 100_000
            })
        {
            break;
        }
        tokio::time::sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(bw.balance().assets[0].amount_sat, 200_000);
    let units = |wallet: &LiquidWallet<MemoryKv, Arc<FixedClock>>, asset: &str| {
        wallet
            .balance()
            .assets
            .iter()
            .find(|a| a.asset_id.as_deref() == Some(asset))
            .map_or(0, |a| a.amount_sat)
    };
    assert_eq!(units(&lw, lw.policy_asset()), 200_000);
    assert_eq!(units(&lw, &minted.asset.to_string()), 100_000);
    println!(
        "PASS: received BTC, L-BTC and local issued asset; exact balances and confidential unblinding"
    );

    let mut request = SendRequest::new(ChainId::Bitcoin, &bitcoin_destination, 10_000);
    request.fee_rate_override_sat_per_vbyte = Some(1.0);
    let (amount, fee) = bw.prepare_exact_send(&request).await?;
    assert_eq!(amount, 10_000);
    assert!(matches!(
        bw.send_onchain_authorized(&request, fee, || Err(mooze_core::Error::Session(
            "locked".into()
        )))
        .await,
        Err(mooze_core::Error::Session(_))
    ));
    let sent = bw.send_onchain_authorized(&request, fee, || Ok(())).await?;
    btc.generate_to_address(1, &bitcoin_destination).await?;
    btc.wait_for_confirmation(&sent.tx_id.parse()?, Duration::from_secs(30))
        .await?;
    println!(
        "PASS: BTC exact send, pre-sign revocation, confirmation {}",
        sent.tx_id
    );

    for asset in [lw.policy_asset().to_owned(), minted.asset.to_string()] {
        let mut request = SendRequest::new(ChainId::Liquid, &liquid_destination, 10_000);
        request.asset_id = Some(asset.clone());
        request.fee_rate_override_sat_per_vbyte = Some(1.0);
        let draft = lw.build_send(&request).await?;
        assert_eq!(draft.amount_sat, 10_000);
        assert!(matches!(
            lw.send_onchain_authorized_exact(
                &request,
                &credentials.mnemonic,
                draft.fee_sat,
                10_001,
                || Ok(())
            )
            .await,
            Err(mooze_core::Error::AmountChanged { .. })
        ));
        let sent = lw
            .send_onchain_authorized_exact(
                &request,
                &credentials.mnemonic,
                draft.fee_sat,
                draft.amount_sat,
                || Ok(()),
            )
            .await?;
        liquid.generate_to_address(1, &liquid_destination).await?;
        liquid
            .wait_for_confirmation(&sent.tx_id.parse()?, Duration::from_secs(30))
            .await?;
        for _ in 0..30 {
            lw.sync().await?;
            if lw
                .activity_views()?
                .0
                .iter()
                .any(|t| t.txid == sent.tx_id && t.height.is_some())
            {
                break;
            }
            tokio::time::sleep(Duration::from_secs(1)).await;
        }
        assert!(
            lw.activity_views()?
                .0
                .iter()
                .any(|t| t.txid == sent.tx_id && t.height.is_some())
        );
        println!(
            "PASS: Liquid exact recipient and bounded L-BTC fee, confirmed {} asset {}",
            sent.tx_id, asset
        );
    }
    assert_eq!(units(&lw, &minted.asset.to_string()), 90_000);

    // Max must preserve drain intent: an exact rebuild can change Liquid output/fee sizing.
    let mut max = SendRequest::new(ChainId::Liquid, &liquid_destination, 0);
    max.drain = true;
    max.fee_rate_override_sat_per_vbyte = Some(1.0);
    let draft = lw.build_send(&max).await?;
    let sent = lw
        .send_onchain_authorized_exact(
            &max,
            &credentials.mnemonic,
            draft.fee_sat,
            draft.amount_sat,
            || Ok(()),
        )
        .await?;
    liquid.generate_to_address(1, &liquid_destination).await?;
    liquid
        .wait_for_confirmation(&sent.tx_id.parse()?, Duration::from_secs(30))
        .await?;
    println!(
        "PASS: L-BTC Max preserved reviewed amount {} and fee {}",
        draft.amount_sat, draft.fee_sat
    );

    bw.sync().await?;
    let mut max = SendRequest::new(ChainId::Bitcoin, &bitcoin_destination, 0);
    max.drain = true;
    max.fee_rate_override_sat_per_vbyte = Some(1.0);
    let (amount, fee) = bw.prepare_exact_send(&max).await?;
    max.drain = false;
    max.amount_sat = amount;
    let sent = bw.send_onchain_authorized(&max, fee, || Ok(())).await?;
    btc.generate_to_address(1, &bitcoin_destination).await?;
    btc.wait_for_confirmation(&sent.tx_id.parse()?, Duration::from_secs(30))
        .await?;
    println!("PASS: BTC Max exact rebuild, amount {amount}, fee {fee}");

    // Reopen from cache, retaining the disposable credentials only in process memory.
    drop(bw);
    drop(lw);
    let mut bw = BitcoinWallet::connect(
        &credentials,
        bitcoin_store,
        clock.clone(),
        endpoints.clone(),
    )
    .await?;
    let mut lw = LiquidWallet::connect(&credentials, liquid_store, clock, endpoints).await?;
    for _ in 0..30 {
        bw.sync().await?;
        lw.sync().await?;
        if bw.balance().assets[0].amount_sat == 0 && units(&lw, lw.policy_asset()) == 0 {
            break;
        }
        tokio::time::sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(bw.balance().assets[0].amount_sat, 0);
    assert_eq!(units(&lw, lw.policy_asset()), 0);
    assert_eq!(units(&lw, &minted.asset.to_string()), 90_000);
    println!("PASS: reopen/resync, zero native balances and retained local asset balance");
    let mut fee_shortfall = SendRequest::new(ChainId::Liquid, &liquid_destination, 1_000);
    fee_shortfall.asset_id = Some(minted.asset.to_string());
    fee_shortfall.fee_rate_override_sat_per_vbyte = Some(1.0);
    assert!(matches!(lw.build_send(&fee_shortfall).await, Err(mooze_core::Error::InsufficientFeeAsset { .. })));
    println!("PASS: funded issued asset with zero L-BTC reports structured fee shortfall");

    Ok(())
}
