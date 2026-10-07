/** Synthetic UI fixtures. No native imports, network requests, keys or persistence. */
import type { DesktopClient, Session, Snapshot } from "../core/client";
import type { AssetMetadataDto } from "../../../../crates/mooze-app/generated/types";
import type {
  DesktopSettingsDto,
  SwapStateDto,
  PixDepositViewDto,
} from "../core/desktop.generated";
export function createPreviewClient(mode = "unlocked"): DesktopClient {
  const timestamp = Date.now();
  const assets: AssetMetadataDto[] = ["BTC", "L-BTC", "DEPIX", "USDT"].map(
    (ticker, index) => ({
      key: {
        chain: index ? "Liquid" : "Bitcoin",
        asset_id: [
          null,
          "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d",
          "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
          "ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2",
        ][index],
      },
      ticker,
      precision: 8,
      approved: true,
    }),
  );
  const chains: Snapshot["chains"] = ["Bitcoin", "Liquid"].map((chain) => ({
    chain: chain as "Bitcoin" | "Liquid",
    phase: "ready",
    last_success_at_ms: timestamp,
    error: null,
  }));
  const snapshot: Snapshot = {
    generation: 1,
    submission: null,
    sync: null,
    chains,
    activity: assets.map((asset, index) => ({
      id: String(index + 5).repeat(64),
      chain: asset.key.chain,
      timestamp_ms: timestamp - index * 86400000,
      status: index === 1 ? "Pending" : "Confirmed",
      confirmations: index === 1 ? 0 : 6,
      movements: [
        {
          asset: asset.key,
          delta_units: ["1250000", "-1000000", "25000000000", "-5000000000"][
            index
          ],
        },
      ],
      fee: null,
      addresses: ["preview-address-not-for-payments"],
    })),
  };
  let settings: DesktopSettingsDto = {
    version: 1,
    lock_minutes: 5,
    locale: "pt-BR",
    bitcoin_unit: "BTC",
    privacy: false,
    bitcoin_node: null,
    liquid_node: null,
    public_fallback: false,
  };
  let session: Session = { status: mode, generation: 1, retry_after_ms: 0 };
  let swap: SwapStateDto = {
    phase: "Idle",
    review: null,
    txid: null,
    message: null,
  };
  const deposits: PixDepositViewDto[] = [];
  const noop = async () => {};
  const unsupported = async (): Promise<never> => {
    throw new Error("Unavailable in the synthetic preview.");
  };
  const unlock = async () => (session = { ...session, status: "unlocked" });
  return {
    nativeAuthStatus: async () => ({
      kind: "unsupported",
      availability: "unavailable",
      enabled: false,
      setup_offer_pending: false,
    }),
    unlockNative: unsupported,
    cancelNativeAuth: noop,
    setNativeAuthEnabled: unsupported,
    completeNativeAuthOffer: async () => ({
      kind: "unsupported",
      availability: "unavailable",
      enabled: false,
      setup_offer_pending: false,
    }),
    accountLevel: async () => ({
      current_level: "silver",
      next_level: "gold",
      progress: 0.62,
      per_transaction_brl: 400,
      minimum_brl: 20,
      daily_limit_brl: 5000,
      spent_today_brl: 1250,
      remaining_today_brl: 3750,
      tiers: ["bronze", "silver", "gold", "diamond"].map((key, order) => ({
        key,
        order,
        minimum_brl: 20,
        maximum_brl: [250, 500, 1000, 3000][order],
      })),
    }),
    priceHistory: async (market, currency, days) => ({
      source: "Synthetic preview",
      fetched_at_ms: timestamp,
      points: Array.from({ length: 97 }, (_, i) => ({
        timestamp_ms: timestamp - days * 86400000 * (1 - i / 96),
        price:
          (market === "Bitcoin" ? 62000 : 1) *
          (currency === "brl" ? 5.2 : 1) *
          (1 + 0.03 * Math.sin(i / 9) + i / 3000),
      })),
    }),
    hostInfo: async () => ({
      network: "Mainnet",
      backend: "Synthetic preview",
      liquid_policy_asset: assets[1].key.asset_id!,
      bitcoin_endpoints: [],
      liquid_endpoints: [],
      pix_enabled: true,
      swaps_enabled: true,
    }),
    sessionStatus: async () => session,
    subscribe: async () => () => {},
    recordActivity: noop,
    unlock,
    importWallet: unlock,
    lock: async () => (session = { ...session, status: "locked" }),
    snapshot: async () => snapshot,
    refresh: noop,
    holdings: async () => ({
      generation: 1,
      chains,
      holdings: assets.map((metadata, i) => ({
        metadata,
        balance_units: ["2485000", "12000000", "25000000000", "15000000000"][i],
        available_units: ["2485000", "11000000", "25000000000", "15000000000"][
          i
        ],
        pending_units: i === 1 ? "1000000" : "0",
      })),
    }),
    approvedAssets: async () => assets,
    settings: async () => settings,
    saveDisplay: async (locale, bitcoin_unit, privacy) =>
      (settings = { ...settings, locale, bitcoin_unit, privacy }),
    setLockMinutes: async (lock_minutes) =>
      (settings = { ...settings, lock_minutes }),
    saveNode: async () => settings,
    testNode: async () => "Preview only",
    diagnostics: async () => ({ preview: true }),
    exportDiagnostics: async () => false,
    receiveRequest: async (asset, amount, description) => ({
      address: "preview-address-not-for-payments",
      uri: `mooze-preview:invalid?asset=${asset.asset_id ?? "BTC"}&amount=${amount ?? ""}&description=${encodeURIComponent(description ?? "")}`,
    }),
    receiveAddress: unsupported,
    parsePaymentRequest: unsupported,
    feeOptions: async () => ({
      kind: "live",
      source: "Synthetic preview",
      observed_at_ms: timestamp,
      rates: [1, 2, 4],
    }),
    reviewSend: async (request) => ({
      id: "preview-review",
      generation: 1,
      request,
      is_max: request.amount.mode === "Max",
      fee_sat: 140,
      debits: [
        {
          asset: request.asset,
          units:
            request.amount.mode === "Exact" ? request.amount.units : "2485000",
        },
      ],
      expires_at_ms: Date.now() + 60000,
    }),
    confirmSend: unsupported,
    acknowledgeSubmission: noop,
    backendStatus: async () => ({ state: "Ready", retryable: false }),
    backendRetry: async () => ({ state: "Ready", retryable: false }),
    pixHistory: async () => ({
      deposits: [...deposits],
      creation_uncertain: false,
    }),
    pixCreate: async (request) => {
      const deposit: PixDepositViewDto = {
        deposit_id: `preview-${deposits.length}`,
        pix_key: "SYNTHETIC-PREVIEW-NOT-A-PAYMENT-CODE",
        asset_id: request.asset_id,
        amount_in_cents: request.amount_in_cents,
        status: "Pending",
        created_at_ms: Date.now(),
        expires_at_ms: Date.now() + 3600000,
        blockchain_txid: null,
        asset_amount: null,
      };
      deposits.unshift(deposit);
      return deposit;
    },
    pixAcknowledgeUncertain: noop,
    swapMarkets: async () => [
      {
        base_asset_id: assets[1].key.asset_id!,
        quote_asset_id: assets[3].key.asset_id!,
        fee_asset: "Quote",
        market_type: "Stablecoin",
      },
    ],
    swapStart: async (request) =>
      (swap = {
        phase: "Review",
        txid: null,
        message: null,
        review: {
          id: "preview-quote",
          generation: 1,
          ...request,
          send_units: request.amount_units,
          receive_units: (BigInt(request.amount_units) * 60000n).toString(),
          fees: [{ asset: assets[3].key, units: "1000000" }],
          expires_at_ms: Date.now() + 60000,
        },
      }),
    swapStatus: async () => swap,
    swapStop: noop,
    swapConfirm: unsupported,
    swapAcknowledge: noop,
    recoveryWords: async () => [],
    validateRecoveryPhrase: unsupported,
    beginSetup: async (extended) => ({
      setup_id: "preview",
      expires_at_ms: Date.now() + 600_000,
      words: Array.from(
        { length: extended ? 24 : 12 },
        (_, i) => `example${i + 1}`,
      ),
      challenge_indices: [0, 3, 8],
    }),
    completeSetup: unlock,
    cancelSetup: noop,
    revealRecoveryPhrase: unsupported,
    changePin: unsupported,
    removeWallet: unsupported,
  };
}
