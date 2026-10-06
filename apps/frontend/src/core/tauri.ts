import { invoke, isTauri } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import type { DesktopClient, DesktopEvent } from "./client";
export const inDesktop = isTauri;
export const client: DesktopClient = {
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
