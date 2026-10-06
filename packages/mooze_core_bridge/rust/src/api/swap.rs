//! SideSwap asset swaps and Bitcoin <-> Liquid pegs.
//!
//! Thin wrappers over `mooze_app`. One WebSocket serves swaps and pegs.
//!
//! Server pushes reach Dart through `sideswapEvents`: the facade driver
//! reads the socket and the bridge forwards its `AppEvent::SideSwap` items
//! to the Dart stream. Cancel it with `sideswapCloseEvents` or by closing
//! the Dart subscription. Peg status is polled: call `pegRefreshDue` at
//! `nextWakeupMs`.

use flutter_rust_bridge::frb;
use mooze_app::convert::sideswap_closed_event;
use mooze_app::rules;

use super::core::{delegate, MoozeCore};
pub use super::types::*;
use crate::forward::SinkForwarder;
use crate::frb_generated::StreamSink;
use crate::ports::on_runtime;

// ───────────────────────────── pure helpers

/// Validates a peg amount (Dart `evaluatePegAmount`). The minimum comes
/// from `limits`, or `fallback_minimum_sats` when unknown. A drain is
/// always valid.
#[frb(sync)]
pub fn peg_validate_amount(
    direction: PegDirectionDto,
    amount_sat: Option<u64>,
    spendable_sat: u64,
    limits: Option<PegServerLimitsDto>,
    fallback_minimum_sats: u64,
    drain: bool,
) -> PegAmountValidationDto {
    rules::peg_validate_amount(
        direction,
        amount_sat,
        spendable_sat,
        limits,
        fallback_minimum_sats,
        drain,
    )
}

/// Default SideSwap endpoint.
#[frb(sync)]
pub fn sideswap_default_url() -> String {
    rules::sideswap_default_url()
}

// ───────────────────────────── MoozeCore

impl MoozeCore {
    /// Opens the SideSwap connection and logs in (Dart `SideswapService.init`).
    /// `url` null uses `sideswapDefaultUrl`. No-op when connected.
    pub async fn sideswap_connect(
        &self,
        api_key: String,
        url: Option<String>,
    ) -> Result<(), CoreError> {
        delegate!(self.sideswap_connect(api_key, url))
    }

    /// Closes the connection and stops the event stream. Idempotent.
    pub async fn sideswap_disconnect(&self) {
        let _ = delegate!(self.sideswap_disconnect());
    }

    /// True while the socket is open.
    pub async fn sideswap_is_connected(&self) -> bool {
        delegate!(self.sideswap_is_connected()).unwrap_or(false)
    }

    /// Server pushes: quotes, peg wallet balances, disconnects. The facade
    /// driver reads the socket while the stream is open. Opening a new
    /// stream replaces the old one, which ends with a `closed` item. Close
    /// it with `sideswapCloseEvents`, `sideswapDisconnect` or by cancelling
    /// the Dart subscription (the driver stops at its next item).
    pub async fn sideswap_events(
        &self,
        sink: StreamSink<SideSwapEventDto>,
    ) -> Result<(), CoreError> {
        let id = self.app.subscribe(Box::new(SinkForwarder(sink.clone())));
        let previous = self
            .events
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .replace((id, sink));
        if let Some((old_id, old_sink)) = previous {
            self.app.unsubscribe(old_id);
            let _ = old_sink.add(sideswap_closed_event());
        }
        delegate!(self.sideswap_start_events())
    }

    /// Stops the event stream task. The stream ends with a `closed` item.
    pub async fn sideswap_close_events(&self) {
        let _ = delegate!(self.sideswap_stop_events());
    }

    /// True while the event stream task runs.
    pub async fn sideswap_events_running(&self) -> bool {
        delegate!(self.sideswap_events_running()).unwrap_or(false)
    }

    /// SideSwap markets.
    pub async fn sideswap_markets(&self) -> Result<Vec<SideswapMarketDto>, CoreError> {
        delegate!(self.sideswap_markets())
    }

    /// SideSwap assets.
    pub async fn sideswap_assets(&self) -> Result<Vec<SideswapAssetDto>, CoreError> {
        delegate!(self.sideswap_assets())
    }

    /// Starts a quote subscription for `amount` of `send_asset_id`
    /// (Dart `SwapController.startQuote`). Stops the previous one. Funds it
    /// with the Liquid wallet UTXOs. Quotes arrive on `sideswapEvents`.
    pub async fn sideswap_start_quote(
        &self,
        send_asset_id: String,
        receive_asset_id: String,
        amount: u64,
    ) -> Result<StartQuoteDto, CoreError> {
        delegate!(self.sideswap_start_quote(send_asset_id, receive_asset_id, amount))
    }

    /// Stops the quote subscription. Best-effort.
    pub async fn sideswap_stop_quote(&self) {
        let _ = delegate!(self.sideswap_stop_quote());
    }

    /// Accepts a quote: stops quotes, fetches the PSET, signs it with the
    /// Liquid wallet and the mnemonic from the secure store, submits it.
    /// Returns the txid.
    pub async fn sideswap_execute_swap(&self, quote_id: u64) -> Result<String, CoreError> {
        delegate!(self.sideswap_execute_swap(quote_id))
    }

    // ───────────────────────────── pegs

    /// Peg minimums and fees from `server_status`.
    pub async fn peg_limits(&self) -> Result<PegServerLimitsDto, CoreError> {
        delegate!(self.peg_limits())
    }

    /// Prices a peg without creating an order.
    pub async fn peg_quote(
        &self,
        direction: PegDirectionDto,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
    ) -> Result<PegQuoteDto, CoreError> {
        delegate!(self.peg_quote(direction, amount_sat, fee_rate_sat_per_vbyte, drain))
    }

    /// Creates a peg order, stores it under `wallet_id`, funds it from the
    /// wallet and starts tracking it. `external_payout_address` is allowed
    /// only for peg-outs; null pays to the own wallet.
    pub async fn peg_execute(
        &self,
        wallet_id: String,
        direction: PegDirectionDto,
        amount_sat: u64,
        fee_rate_sat_per_vbyte: Option<u32>,
        drain: bool,
        external_payout_address: Option<String>,
    ) -> Result<PegExecutionDto, CoreError> {
        delegate!(self.peg_execute(
            wallet_id,
            direction,
            amount_sat,
            fee_rate_sat_per_vbyte,
            drain,
            external_payout_address
        ))
    }

    /// One-shot status of an order.
    pub async fn peg_status(
        &self,
        direction: PegDirectionDto,
        order_id: String,
    ) -> Result<PegProgressDto, CoreError> {
        delegate!(self.peg_status(direction, order_id))
    }

    /// Stored pegs of `wallet_id`, oldest first. Needs no connection.
    pub async fn peg_list(&self, wallet_id: String) -> Result<Vec<PegRecordDto>, CoreError> {
        delegate!(self.peg_list(wallet_id))
    }

    /// Resumes tracking of the pending pegs stored under `wallet_id`.
    /// Idempotent. Returns every tracked peg.
    pub async fn peg_restore(&self, wallet_id: String) -> Result<Vec<TrackedPegDto>, CoreError> {
        delegate!(self.peg_restore(wallet_id))
    }

    /// Every tracked peg.
    pub async fn peg_tracked(&self) -> Vec<TrackedPegDto> {
        delegate!(self.peg_tracked()).unwrap_or_default()
    }

    /// Stops tracking `order_id`. Storage is unchanged.
    pub async fn peg_untrack(&self, order_id: String) {
        let _ = delegate!(self.peg_untrack(order_id));
    }

    /// Polls every tracked peg whose time has come, persists terminal ones
    /// under `wallet_id`, and returns the new state (Dart `PegTracker`).
    /// Transport errors only reschedule.
    pub async fn peg_refresh_due(&self, wallet_id: String) -> Result<PegRefreshDto, CoreError> {
        delegate!(self.peg_refresh_due(wallet_id))
    }
}
