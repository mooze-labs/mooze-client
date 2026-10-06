//! The facade API as data, so hosts generate their bindings from one list.
//!
//! [`for_each_app_method!`] calls a host macro with every method. The
//! `codegen` feature adds [`METHODS`], the same list with TypeScript type
//! names, which `src/bin/codegen.rs` turns into the `CoreClient` interface.

/// Calls `$callback!` with every facade method.
///
/// Entry syntax: `name(param: Type, ...) -> ReturnType;` where every method
/// is `async` and returns `Result<ReturnType, AppError>`. `subscribe` and
/// `unsubscribe` take a sink and are bound by hand in each host.
#[macro_export]
macro_rules! for_each_app_method {
    ($callback:ident) => {
        $callback! {
            is_migrated() -> bool;
            import_flutter_snapshot(snapshot_json: String) -> MigrationReportDto;
            secure_get(key: String) -> Option<String>;
            secure_put(key: String, value: String) -> ();
            secure_delete(key: String) -> ();
            secure_list_keys(prefix: String) -> Vec<String>;
            api_set_base_url(base_url: String) -> ();
            auth_ensure_session() -> AuthEnsureDto;
            auth_access_token() -> String;
            auth_force_refresh() -> String;
            auth_refresh_current() -> bool;
            auth_invalidate() -> ();
            auth_reset() -> ();
            auth_set_device_safe(safe: bool) -> ();
            auth_device_id(serial: Option<String>, platform_id: Option<String>) -> String;
            api_set_metrics(metrics: Option<DeviceMetricsDto>) -> ();
            api_request(method: HttpMethodDto, path: String, json_body: Option<String>) -> ApiResponseDto;
            bitcoin_connect(mnemonic: String) -> ();
            bitcoin_disconnect() -> ();
            bitcoin_sync() -> SyncOutcomeDto;
            bitcoin_balance() -> BalanceDto;
            wallet_holdings() -> Vec<HoldingDto>;
            bitcoin_transactions() -> Vec<TransactionDto>;
            bitcoin_take_events() -> Vec<TransactionEventDto>;
            bitcoin_receive_address(label: Option<String>) -> ReceiveAddressDto;
            bitcoin_estimate_fee(request: SendRequestDto) -> FeeEstimateDto;
            bitcoin_send_bounded(request: SendRequestDto, max_fee_sat: u64) -> BroadcastResultDto;
            liquid_send_bounded(request: SendRequestDto, max_fee_sat: u64) -> BroadcastResultDto;
            bitcoin_send(request: SendRequestDto) -> BroadcastResultDto;
            bitcoin_block_height() -> u32;
            bitcoin_derived_addresses(keychain: KeychainDto, start: u32, count: u32) -> Vec<DerivedAddressDto>;
            bitcoin_unspent_outputs() -> Vec<WalletUtxoDto>;
            bitcoin_is_mine(address: String) -> Option<AddressOwnershipDto>;
            bitcoin_next_unused_address() -> NextUnusedAddressDto;
            bitcoin_register_external_broadcast(transaction: TransactionDto) -> ();
            liquid_connect(mnemonic: String) -> ();
            liquid_disconnect() -> ();
            liquid_sync() -> SyncOutcomeDto;
            liquid_balance() -> BalanceDto;
            liquid_refresh_balance() -> BalanceDto;
            liquid_apply_balance_delta(asset_ids: Vec<String>, deltas: Vec<i64>) -> BalanceDto;
            liquid_transactions() -> Vec<TransactionDto>;
            liquid_take_events() -> Vec<TransactionEventDto>;
            liquid_receive_address(asset_id: Option<String>, label: Option<String>) -> ReceiveAddressDto;
            liquid_derived_addresses(keychain: KeychainDto, start: u32, count: u32) -> Vec<DerivedAddressDto>;
            liquid_unspent_outputs() -> Vec<WalletUtxoDto>;
            liquid_is_mine(address: String, scan_limit: u32) -> Option<AddressOwnershipDto>;
            liquid_next_unused_address() -> NextUnusedAddressDto;
            liquid_utxos() -> Vec<LiquidUtxoDto>;
            liquid_estimate_fee(request: SendRequestDto) -> FeeEstimateDto;
            liquid_build_lbtc_send(destination: String, amount_sat: u64, fee_rate_sat_per_vb: Option<f64>, drain: bool) -> LiquidSendDraftDto;
            liquid_send(request: SendRequestDto) -> BroadcastResultDto;
            liquid_sign_and_broadcast(pset: String) -> String;
            liquid_sign_swap_pset(pset: String) -> String;
            pix_create_deposit(amount_in_cents: u64, asset_id: String, tax_id_number: Option<String>, address: Option<String>) -> PixDepositDto;
            pix_poll_tick() -> Vec<PixStatusEventDto>;
            pix_active_polls() -> u32;
            pix_cancel_polls() -> ();
            pix_get_deposit(deposit_id: String) -> Option<PixDepositDto>;
            pix_list_deposits(limit: Option<u32>, offset: Option<u32>) -> Vec<PixDepositDto>;
            pix_update_deposit_details(deposit_ids: Vec<String>) -> Vec<PixDepositDto>;
            pix_history(limit: Option<u32>, offset: Option<u32>) -> Vec<PixDepositDto>;
            pix_clear_deposits() -> ();
            favorite_payers_list() -> Vec<FavoritePayerDto>;
            favorite_payer_save(id: Option<u64>, label: String, cpf: String) -> Option<FavoritePayerSaveErrorDto>;
            favorite_payer_delete(id: u64) -> ();
            favorite_payer_cpf_exists(cpf: String, excluding_id: Option<u64>) -> bool;
            favorite_payers_clear() -> ();
            pix_flag_is_set(flag: PixFlagDto) -> bool;
            pix_flag_set(flag: PixFlagDto) -> ();
            pix_flag_reset(flag: PixFlagDto) -> ();
            sideswap_connect(api_key: String, url: Option<String>) -> ();
            sideswap_disconnect() -> ();
            sideswap_is_connected() -> bool;
            sideswap_start_events() -> ();
            sideswap_stop_events() -> ();
            sideswap_events_running() -> bool;
            sideswap_markets() -> Vec<SideswapMarketDto>;
            sideswap_assets() -> Vec<SideswapAssetDto>;
            sideswap_start_quote(send_asset_id: String, receive_asset_id: String, amount: u64) -> StartQuoteDto;
            sideswap_stop_quote() -> ();
            sideswap_execute_swap(quote_id: u64) -> String;
            peg_limits() -> PegServerLimitsDto;
            peg_quote(direction: PegDirectionDto, amount_sat: u64, fee_rate_sat_per_vbyte: Option<u32>, drain: bool) -> PegQuoteDto;
            peg_execute(wallet_id: String, direction: PegDirectionDto, amount_sat: u64, fee_rate_sat_per_vbyte: Option<u32>, drain: bool, external_payout_address: Option<String>) -> PegExecutionDto;
            peg_status(direction: PegDirectionDto, order_id: String) -> PegProgressDto;
            peg_list(wallet_id: String) -> Vec<PegRecordDto>;
            peg_restore(wallet_id: String) -> Vec<TrackedPegDto>;
            peg_tracked() -> Vec<TrackedPegDto>;
            peg_untrack(order_id: String) -> ();
            peg_refresh_due(wallet_id: String) -> PegRefreshDto;
            start(config: StartConfigDto) -> ();
            stop() -> ();
            is_running() -> bool;
            refresh_now() -> ();
            on_background(now_ms: u64) -> ();
            on_foreground(now_ms: u64, lock_enabled: bool) -> SessionLockStateDto;
            session_unlocked() -> ();
        }
    };
}

/// Compile-time check: every listed method exists on `App` with these types.
macro_rules! assert_methods_exist {
    ($($name:ident($($p:ident : $t:ty),*) -> $r:ty;)*) => {
        #[allow(dead_code, unused_variables, clippy::let_underscore_future)]
        fn _assert_methods_exist<P: $crate::Platform>(app: &$crate::App<P>) {
            use $crate::dto::*;
            $( let _ = |$($p: $t),*| async move { let _r: $crate::Result<$r> = app.$name($($p),*).await; }; )*
        }
    };
}
for_each_app_method!(assert_methods_exist);

#[cfg(feature = "codegen")]
pub use table::{ts_config, MethodSpec, TsName, METHODS};

#[cfg(feature = "codegen")]
mod table {
    use crate::dto::*;
    use ts_rs::TS;

    /// Returns the TypeScript name of one type.
    pub type TsName = fn() -> String;

    /// One facade method with the TypeScript names of its types.
    pub struct MethodSpec {
        pub name: &'static str,
        pub params: &'static [(&'static str, TsName)],
        pub returns: TsName,
    }

    /// ts-rs settings shared by the table and the codegen binary. 64-bit
    /// integers become `number`: serde_json writes them as JSON numbers and
    /// every amount in the API fits in 2^53.
    pub fn ts_config() -> ts_rs::Config {
        ts_rs::Config::new().with_large_int("number")
    }

    fn ts_name<T: TS>() -> String {
        T::name(&ts_config())
    }

    macro_rules! method_table {
        ($($name:ident($($p:ident : $t:ty),*) -> $r:ty;)*) => {
            /// Every facade method, in declaration order.
            pub static METHODS: &[MethodSpec] = &[
                $( MethodSpec {
                    name: stringify!($name),
                    params: &[$((stringify!($p), ts_name::<$t> as TsName)),*],
                    returns: ts_name::<$r> as TsName,
                }, )*
            ];
        };
    }
    for_each_app_method!(method_table);
}
