//! Bitcoin and Liquid wallet methods. Port of the bridge wallet calls.
//!
//! The Liquid signing methods read the mnemonic from the secure store,
//! so no host ever passes it across the boundary. They check the wallet
//! first, so a missing wallet reports `InvalidState` before any credential
//! error.

use mooze_core::domain::{ChainId, WalletCredentials};
use mooze_core::store::CredentialStore;
use mooze_core::wallet::{BitcoinWallet, LiquidWallet};

use super::{not_connected, App, Inner};
use crate::convert::send_request;
use crate::dto::*;
use crate::{AppError, ErrorCode, Platform, Result};

/// Mnemonic from the secure store (`mnemonic_mainWallet`).
pub(crate) async fn load_mnemonic<P: Platform>(inner: &Inner<P>) -> Result<String> {
    let credentials = CredentialStore::new(inner.platform.secure(), inner.network).load().await?;
    if credentials.is_absent() {
        return Err(AppError::new(ErrorCode::Credential, "no mnemonic in the secure store"));
    }
    Ok(credentials.mnemonic)
}

impl<P: Platform> App<P> {
    pub async fn wallet_activity(&self) -> Result<Vec<WalletActivityDto>> {
        let mut rows = {
            let guard = self.inner.bitcoin.lock().await;
            let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
            let (views, tip) = w.activity_views();
            views.iter().map(|v| crate::activity::bitcoin_activity(v, tip)).collect::<Vec<_>>()
        };
        {
            let guard = self.inner.liquid.lock().await;
            let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
            let (views, tip) = w.activity_views()?;
            let policy = mooze_core::wallet::descriptors::liquid_policy_asset(self.inner.network);
            rows.extend(views.iter().map(|v| crate::activity::liquid_activity(v, tip, policy)));
        }
        rows.sort_by(|a, b| b.timestamp_ms.cmp(&a.timestamp_ms).then(a.id.cmp(&b.id)));
        Ok(rows)
    }
    /// Resolve the amount and fee without signing; Max uses the chain builder.
    pub async fn prepare_desktop_send(&self, chain: ChainDto, request: SendRequestDto) -> Result<(u64, u64)> {
        if chain == ChainDto::Bitcoin {
            let mut guard = self.inner.bitcoin.lock().await;
            let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
            Ok(wallet.prepare_exact_send(&send_request(&request, ChainId::Bitcoin)).await?)
        } else if chain == ChainDto::Liquid {
            let mut guard = self.inner.liquid.lock().await;
            let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
            let draft = wallet.build_send(&send_request(&request, ChainId::Liquid)).await?;
            Ok((draft.amount_sat, draft.fee_sat))
        } else {
            Err(AppError::new(ErrorCode::InvalidState, "unsupported chain"))
        }
    }
    pub async fn desktop_fee_rates(&self) -> Result<Vec<f64>> {
        let mut guard = self.inner.bitcoin.lock().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        let estimates = wallet.fee_estimates().await?;
        Ok(desktop_live_rates(&estimates.fee_by_block_target))
    }
    /// Exact string amounts for new hosts; legacy balance DTOs remain unchanged.
    pub async fn wallet_holdings(&self) -> Result<Vec<HoldingDto>> {
        let network = match self.inner.network {
            mooze_core::domain::AppNetwork::Mainnet => NetworkDto::Mainnet,
            mooze_core::domain::AppNetwork::Testnet => NetworkDto::Testnet,
            mooze_core::domain::AppNetwork::Regtest => NetworkDto::Regtest,
        };
        let mut balances = self.bitcoin_balance().await?.assets;
        balances.extend(self.liquid_balance().await?.assets);
        let rows: Vec<_> = balances.iter().map(|b| crate::assets::holding_for_network(network, b)).collect();
        let keys = crate::assets::approved_assets(network).into_iter().map(|m| m.key).chain(
            self.wallet_activity()
                .await?
                .into_iter()
                .flat_map(|row| row.movements.into_iter().map(|movement| movement.asset)),
        );
        Ok(crate::assets::include_historical_assets_for_network(network, rows, keys))
    }

    // ───────────────────────────── bitcoin

    /// Loads or creates the Bitcoin wallet for `mnemonic`.
    pub async fn bitcoin_connect(&self, mnemonic: String) -> Result<()> {
        let inner = &self.inner;
        let creds = WalletCredentials { mnemonic, network: inner.network };
        let mut wallet =
            BitcoinWallet::connect(&creds, inner.platform.kv(), inner.platform.clock(), inner.endpoints.clone())
                .await?;
        if inner.backend.is_electrum() {
            wallet.set_backend(inner.backend.clone(), inner.endpoints.clone())?;
        }
        *inner.bitcoin.lock().await = Some(wallet);
        Ok(())
    }

    /// Drops the Bitcoin wallet. Idempotent.
    pub async fn bitcoin_disconnect(&self) -> Result<()> {
        *self.inner.bitcoin.lock().await = None;
        Ok(())
    }

    /// Syncs the Bitcoin wallet.
    pub async fn bitcoin_sync(&self) -> Result<SyncOutcomeDto> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok((&w.sync().await?).into())
    }

    /// Bitcoin balance from local state.
    pub async fn bitcoin_balance(&self) -> Result<BalanceDto> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.balance().into())
    }

    /// Bitcoin transactions from local state, newest first.
    pub async fn bitcoin_transactions(&self) -> Result<Vec<TransactionDto>> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.list_transactions().iter().map(Into::into).collect())
    }

    /// Transaction changes since the last call.
    pub async fn bitcoin_take_events(&self) -> Result<Vec<TransactionEventDto>> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.take_events().iter().map(Into::into).collect())
    }

    /// Next unused receive address.
    pub async fn bitcoin_receive_address(&self, label: Option<String>) -> Result<ReceiveAddressDto> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok((&w.next_receive_address(None, label.as_deref()).await?).into())
    }

    /// Fee estimate for a send.
    pub async fn bitcoin_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok((&w.estimate_fee(&send_request(&request, ChainId::Bitcoin)).await?).into())
    }

    /// Builds, signs and broadcasts a send.
    pub async fn bitcoin_send(&self, request: SendRequestDto) -> Result<BroadcastResultDto> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok((&w.send_onchain(&send_request(&request, ChainId::Bitcoin)).await?).into())
    }

    pub async fn bitcoin_send_bounded(&self, request: SendRequestDto, max_fee_sat: u64) -> Result<BroadcastResultDto> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok((&w.send_onchain_bounded(&send_request(&request, ChainId::Bitcoin), max_fee_sat).await?).into())
    }

    pub async fn liquid_send_bounded(&self, request: SendRequestDto, max_fee_sat: u64) -> Result<BroadcastResultDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        let mnemonic = load_mnemonic(&self.inner).await?;
        Ok((&w.send_onchain_bounded(&send_request(&request, ChainId::Liquid), &mnemonic, max_fee_sat).await?).into())
    }

    /// Native hosts may revoke authorization while preparation awaits storage or a wallet lock.
    pub async fn bitcoin_send_authorized(
        &self,
        request: SendRequestDto,
        max_fee_sat: u64,
        authorize: impl FnOnce() -> mooze_core::Result<()> + Send,
    ) -> Result<BroadcastResultDto> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok((&w.send_onchain_authorized(&send_request(&request, ChainId::Bitcoin), max_fee_sat, authorize).await?)
            .into())
    }

    pub async fn liquid_send_authorized(
        &self,
        request: SendRequestDto,
        max_fee_sat: u64,
        authorize: impl FnOnce() -> mooze_core::Result<()> + Send,
    ) -> Result<BroadcastResultDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        let mnemonic = load_mnemonic(&self.inner).await?;
        Ok((&w
            .send_onchain_authorized(&send_request(&request, ChainId::Liquid), &mnemonic, max_fee_sat, authorize)
            .await?)
            .into())
    }

    pub async fn liquid_send_authorized_exact(
        &self,
        request: SendRequestDto,
        max_fee_sat: u64,
        expected_amount: u64,
        authorize: impl FnOnce() -> mooze_core::Result<()> + Send,
    ) -> Result<BroadcastResultDto> {
        let mut guard = self.inner.liquid.lock().await;
        let wallet = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        let mnemonic = load_mnemonic(&self.inner).await?;
        Ok((&wallet
            .send_onchain_authorized_exact(
                &send_request(&request, ChainId::Liquid),
                &mnemonic,
                max_fee_sat,
                expected_amount,
                authorize,
            )
            .await?)
            .into())
    }

    /// Chain tip height.
    pub async fn bitcoin_block_height(&self) -> Result<u32> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.block_height().await?)
    }

    /// Addresses of `keychain` at `start..start + count`. Reveals nothing.
    pub async fn bitcoin_derived_addresses(
        &self,
        keychain: KeychainDto,
        start: u32,
        count: u32,
    ) -> Result<Vec<DerivedAddressDto>> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.derived_addresses(keychain.into(), start, count).iter().map(Into::into).collect())
    }

    /// Unspent outputs with address, derivation and confirmation.
    pub async fn bitcoin_unspent_outputs(&self) -> Result<Vec<WalletUtxoDto>> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.unspent_outputs().iter().map(Into::into).collect())
    }

    /// Derivation of `address` if the wallet owns it. Fails with
    /// `InvalidInput` for an address it cannot parse.
    pub async fn bitcoin_is_mine(&self, address: String) -> Result<Option<AddressOwnershipDto>> {
        let guard = self.inner.bitcoin.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok(w.is_mine(&address)?.map(Into::into))
    }

    /// Next receive address with no history. Reveals up to it and persists.
    pub async fn bitcoin_next_unused_address(&self) -> Result<NextUnusedAddressDto> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        Ok((&w.next_unused_address().await?).into())
    }

    /// Adds a transaction broadcast elsewhere, for example a peg-in funding.
    pub async fn bitcoin_register_external_broadcast(&self, transaction: TransactionDto) -> Result<()> {
        let mut guard = self.inner.bitcoin.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Bitcoin))?;
        w.register_external_broadcast((&transaction).into());
        Ok(())
    }

    // ───────────────────────────── liquid

    /// Loads or creates the Liquid wallet for `mnemonic`.
    pub async fn liquid_connect(&self, mnemonic: String) -> Result<()> {
        let inner = &self.inner;
        let creds = WalletCredentials { mnemonic, network: inner.network };
        let mut wallet =
            LiquidWallet::connect(&creds, inner.platform.kv(), inner.platform.clock(), inner.endpoints.clone()).await?;
        if inner.backend.is_electrum() {
            wallet.set_backend(inner.backend.clone(), inner.endpoints.clone())?;
        }
        *inner.liquid.lock().await = Some(wallet);
        Ok(())
    }

    /// Drops the Liquid wallet. Idempotent.
    pub async fn liquid_disconnect(&self) -> Result<()> {
        *self.inner.liquid.lock().await = None;
        Ok(())
    }

    /// Syncs the Liquid wallet.
    pub async fn liquid_sync(&self) -> Result<SyncOutcomeDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok((&w.sync().await?).into())
    }

    /// Liquid balance from local state.
    pub async fn liquid_balance(&self) -> Result<BalanceDto> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.balance().into())
    }

    /// Re-reads balances from the local wallet, no network.
    pub async fn liquid_refresh_balance(&self) -> Result<BalanceDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.refresh_balance()?.into())
    }

    /// Applies known per-asset deltas to the cached balance.
    pub async fn liquid_apply_balance_delta(&self, asset_ids: Vec<String>, deltas: Vec<i64>) -> Result<BalanceDto> {
        if asset_ids.len() != deltas.len() {
            return Err(AppError::invalid_input("asset_ids and deltas differ in length"));
        }
        let pairs: Vec<(String, i64)> = asset_ids.into_iter().zip(deltas).collect();
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.apply_optimistic_balance_delta(&pairs).into())
    }

    /// Liquid transactions from local state, newest first.
    pub async fn liquid_transactions(&self) -> Result<Vec<TransactionDto>> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.list_transactions().iter().map(Into::into).collect())
    }

    /// Transaction changes since the last call.
    pub async fn liquid_take_events(&self) -> Result<Vec<TransactionEventDto>> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.take_events().iter().map(Into::into).collect())
    }

    /// Receive address, optionally for one asset.
    pub async fn liquid_receive_address(
        &self,
        asset_id: Option<String>,
        label: Option<String>,
    ) -> Result<ReceiveAddressDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok((&w.next_receive_address(asset_id.as_deref(), label.as_deref()).await?).into())
    }

    /// Addresses of `keychain` at `start..start + count`. Reveals nothing.
    pub async fn liquid_derived_addresses(
        &self,
        keychain: KeychainDto,
        start: u32,
        count: u32,
    ) -> Result<Vec<DerivedAddressDto>> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.derived_addresses(keychain.into(), start, count)?.iter().map(Into::into).collect())
    }

    /// Unspent outputs with address, derivation, asset and confirmation.
    pub async fn liquid_unspent_outputs(&self) -> Result<Vec<WalletUtxoDto>> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.unspent_outputs()?.iter().map(Into::into).collect())
    }

    /// Derivation of `address` among the first `scan_limit` addresses of
    /// each chain. Fails with `InvalidInput` for an address it cannot parse.
    pub async fn liquid_is_mine(&self, address: String, scan_limit: u32) -> Result<Option<AddressOwnershipDto>> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.is_mine(&address, scan_limit)?.map(Into::into))
    }

    /// LWK's last unused receive address, with a history check.
    pub async fn liquid_next_unused_address(&self) -> Result<NextUnusedAddressDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok((&w.next_unused_address().await?).into())
    }

    /// Unblinded UTXOs, for SideSwap.
    pub async fn liquid_utxos(&self) -> Result<Vec<LiquidUtxoDto>> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok(w.utxos()?.iter().map(Into::into).collect())
    }

    /// Fee estimate for a send.
    pub async fn liquid_estimate_fee(&self, request: SendRequestDto) -> Result<FeeEstimateDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok((&w.estimate_fee(&send_request(&request, ChainId::Liquid)).await?).into())
    }

    /// Builds an unsigned L-BTC send. A drain sends the whole L-BTC balance.
    pub async fn liquid_build_lbtc_send(
        &self,
        destination: String,
        amount_sat: u64,
        fee_rate_sat_per_vb: Option<f64>,
        drain: bool,
    ) -> Result<LiquidSendDraftDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        Ok((&w.build_lbtc_send(&destination, amount_sat, fee_rate_sat_per_vb, drain).await?).into())
    }

    /// Builds, signs and broadcasts a send. Signs with the stored mnemonic.
    pub async fn liquid_send(&self, request: SendRequestDto) -> Result<BroadcastResultDto> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        let mnemonic = load_mnemonic(&self.inner).await?;
        Ok((&w.send_onchain(&send_request(&request, ChainId::Liquid), &mnemonic).await?).into())
    }

    /// Signs a PSET with the stored mnemonic and broadcasts it. Returns the txid.
    pub async fn liquid_sign_and_broadcast(&self, pset: String) -> Result<String> {
        let mut guard = self.inner.liquid.lock().await;
        let w = guard.as_mut().ok_or_else(|| not_connected(ChainId::Liquid))?;
        let mnemonic = load_mnemonic(&self.inner).await?;
        Ok(w.sign_and_broadcast_pset(&pset, &mnemonic).await?)
    }

    /// Signs a SideSwap swap PSET with the stored mnemonic. Returns the signed PSET.
    pub async fn liquid_sign_swap_pset(&self, pset: String) -> Result<String> {
        let guard = self.inner.liquid.lock().await;
        let w = guard.as_ref().ok_or_else(|| not_connected(ChainId::Liquid))?;
        let mnemonic = load_mnemonic(&self.inner).await?;
        Ok(w.sign_swap_pset(&pset, &mnemonic)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::{open_test_app, ABANDON};
    use crate::ErrorCode;
    use mooze_core::testing::block_on;

    #[test]
    fn derives_the_same_first_addresses_as_the_flutter_app() {
        let (app, _plat) = open_test_app();
        block_on(app.bitcoin_connect(ABANDON.into())).unwrap();
        let ext = block_on(app.bitcoin_derived_addresses(KeychainDto::External, 0, 2)).unwrap();
        assert_eq!(ext[0].address, "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu");
        assert_eq!(ext[1].address, "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g");
        let change = block_on(app.bitcoin_derived_addresses(KeychainDto::Internal, 0, 1)).unwrap();
        assert_eq!(change[0].address, "bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el");
        let own = block_on(app.bitcoin_is_mine(ext[1].address.clone())).unwrap().unwrap();
        assert_eq!((own.keychain, own.index), (KeychainDto::External, 1));
        assert!(block_on(app.bitcoin_is_mine("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq".into())).unwrap().is_none());
        assert_eq!(block_on(app.bitcoin_is_mine("garbage".into())).unwrap_err().code, ErrorCode::InvalidInput);

        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let lq = block_on(app.liquid_derived_addresses(KeychainDto::External, 0, 1)).unwrap();
        assert!(lq[0].address.starts_with("lq1"), "{}", lq[0].address);
        assert!(block_on(app.liquid_transactions()).unwrap().is_empty());
    }

    #[test]
    fn calls_before_connect_report_invalid_state() {
        let (app, _plat) = open_test_app();
        let err = block_on(app.bitcoin_balance()).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidState);
        assert_eq!(err.message, "bitcoin wallet not connected");
    }

    #[test]
    fn balance_delta_lengths_must_match() {
        let (app, _plat) = open_test_app();
        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let err = block_on(app.liquid_apply_balance_delta(vec!["a".into()], vec![])).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidInput);
    }

    #[test]
    fn liquid_signing_without_wallet_reports_invalid_state_before_credentials() {
        let (app, _plat) = open_test_app();
        let err = block_on(app.liquid_sign_swap_pset("cHNldP8=".into())).unwrap_err();
        assert_eq!(err.code, ErrorCode::InvalidState);
        assert_eq!(err.message, "liquid wallet not connected");
    }

    #[test]
    fn liquid_signing_needs_a_stored_mnemonic() {
        let (app, _plat) = open_test_app();
        block_on(app.liquid_connect(ABANDON.into())).unwrap();
        let err =
            block_on(app.liquid_sign_swap_pset("cHNldP8BAgQCAAAAAQQBAAEFAQABBgEDAfsEAgAAAAA=".into())).unwrap_err();
        assert_eq!(err.code, ErrorCode::Credential);
    }
}

#[cfg(test)]
mod desktop_fee_tests {
    #[test]
    fn live_options_require_actual_backend_targets() {
        let partial = [("1".to_owned(), 5.0)].into_iter().collect();
        assert!(super::desktop_live_rates(&partial).is_empty());
        let complete = [("1".to_owned(), 5.0), ("6".into(), 2.0), ("25".into(), 1.0)].into_iter().collect();
        assert_eq!(super::desktop_live_rates(&complete), vec![1.0, 2.0, 5.0]);
    }
}

fn desktop_live_rates(rates: &std::collections::BTreeMap<String, f64>) -> Vec<f64> {
    let choose = |targets: &[&str]| {
        targets.iter().find_map(|target| rates.get(*target).copied().filter(|v| v.is_finite() && *v > 0.0))
    };
    match (choose(&["144", "25", "12"]), choose(&["6", "3"]), choose(&["1", "2"])) {
        (Some(low), Some(medium), Some(fast)) => vec![low, medium, fast],
        _ => vec![],
    }
}
