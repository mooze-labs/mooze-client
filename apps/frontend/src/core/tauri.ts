import { invoke, isTauri } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import type { DesktopClient, DesktopEvent } from "./client";
export const inDesktop = isTauri;
export const client: DesktopClient = {
  accountLevel: () => invoke("account_level"),
  priceHistory: (market, currency, days) =>
    invoke("price_history", { market, currency, days }),
  swapMarkets: () => invoke("swap_markets"),
  swapStart: (request) => invoke("swap_start", { request }),
  swapStatus: () => invoke("swap_status"),
  swapStop: () => invoke("swap_stop"),
  swapConfirm: (reviewId) => invoke("swap_confirm", { reviewId }),
  swapAcknowledge: () => invoke("swap_acknowledge"),
  backendStatus: () => invoke("backend_status"),
  backendRetry: () => invoke("backend_retry"),
  pixHistory: () => invoke("pix_history"),
  pixCreate: (request) => invoke("pix_create", { request }),
  pixAcknowledgeUncertain: () => invoke("pix_acknowledge_uncertain"),
  removeWallet: (pin) => invoke("remove_wallet", { pin }),
  diagnostics: () => invoke("diagnostics"),
  exportDiagnostics: () => invoke("export_diagnostics"),
  testNode: (chain, endpoint) => invoke("test_node", { chain, endpoint }),
  saveNode: (chain, endpoint, publicFallback) =>
    invoke("save_node", { chain, endpoint, publicFallback }),
  saveDisplay: (locale, bitcoinUnit, privacy) =>
    invoke("save_display", { locale, bitcoinUnit, privacy }),
  parsePaymentRequest: (input) => invoke("parse_payment_request", { input }),
  receiveRequest: (asset, amountUnits, description) =>
    invoke("receive_request", { asset, amountUnits, description }),
  feeOptions: (asset) => invoke("fee_options", { asset }),
  beginSetup: (extended) => invoke("begin_setup", { extended }),
  cancelSetup: (setupId) => invoke("cancel_setup", { setupId }),
  completeSetup: (setupId, answers, pin) =>
    invoke("complete_setup", { setupId, answers, pin }),
  revealRecoveryPhrase: (pin) => invoke("reveal_recovery_phrase", { pin }),
  changePin: (currentPin, newPin) =>
    invoke("change_pin", { currentPin, newPin }),
  recordActivity: (generation) => invoke("record_activity", { generation }),
  settings: () => invoke("settings"),
  setLockMinutes: (minutes) => invoke("set_lock_minutes", { minutes }),
  holdings: () => invoke("holdings"),
  approvedAssets: () => invoke("approved_assets"),
  hostInfo: () => invoke("host_info"),
  sessionStatus: () => invoke("session_status"),
  importWallet: (mnemonic, pin) => invoke("import_wallet", { mnemonic, pin }),
  unlock: (pin) => invoke("unlock", { pin }),
  lock: () => invoke("lock"),
  snapshot: () => invoke("snapshot"),
  refresh: () => invoke("refresh"),
  receiveAddress: (chain) => invoke("receive_address", { chain }),
  reviewSend: (request) => invoke("review_send", { request }),
  acknowledgeSubmission: () => invoke("acknowledge_submission"),
  confirmSend: async (reviewId) => {
    try {
      return await invoke("confirm_send", { reviewId });
    } catch (error) {
      if (error && typeof error === "object" && "code" in error) throw error;
      throw {
        code: "transport",
        message:
          "O resultado do envio é desconhecido. Atualize o histórico antes de tentar novamente.",
      };
    }
  },
  subscribe: (handler) =>
    listen<DesktopEvent>("mooze://event", (event) => handler(event.payload)),
};
