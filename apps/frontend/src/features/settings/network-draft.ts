import type { Chain } from "../../core/client";
import type { DesktopSettingsDto } from "../../core/desktop.generated";
export type NetworkDraftState = {
  saved: DesktopSettingsDto | null;
  endpoints: Record<Chain, string>;
  fallback: boolean;
};
export const emptyNetworkDraft: NetworkDraftState = {
  saved: null,
  endpoints: { Bitcoin: "", Liquid: "" },
  fallback: false,
};
const endpoint = (s: DesktopSettingsDto | null, c: Chain) =>
  (c === "Bitcoin" ? s?.bitcoin_node : s?.liquid_node) ?? "";
export const isNetworkDirty = (s: NetworkDraftState) =>
  s.saved !== null &&
  (s.endpoints.Bitcoin !== endpoint(s.saved, "Bitcoin") ||
    s.endpoints.Liquid !== endpoint(s.saved, "Liquid") ||
    s.fallback !== s.saved.public_fallback);
type Event =
  | { type: "loaded"; settings: DesktopSettingsDto }
  | { type: "saved"; chain: Chain; settings: DesktopSettingsDto }
  | { type: "editEndpoint"; chain: Chain; value: string }
  | { type: "editFallback"; value: boolean }
  | { type: "reset" };
export function reduceNetworkDraft(
  state: NetworkDraftState,
  event: Event,
): NetworkDraftState {
  switch (event.type) {
    case "editEndpoint":
      return {
        ...state,
        endpoints: { ...state.endpoints, [event.chain]: event.value },
      };
    case "editFallback":
      return { ...state, fallback: event.value };
    case "reset":
      return state.saved
        ? {
            saved: state.saved,
            endpoints: {
              Bitcoin: endpoint(state.saved, "Bitcoin"),
              Liquid: endpoint(state.saved, "Liquid"),
            },
            fallback: state.saved.public_fallback,
          }
        : emptyNetworkDraft;
    case "loaded":
    case "saved": {
      const next = { ...state.endpoints };
      for (const chain of ["Bitcoin", "Liquid"] as const) {
        if (
          !state.saved ||
          (event.type === "saved" && event.chain === chain) ||
          state.endpoints[chain] === endpoint(state.saved, chain)
        )
          next[chain] = endpoint(event.settings, chain);
      }
      return {
        saved: event.settings,
        endpoints: next,
        fallback:
          event.type === "saved" ||
          !state.saved ||
          state.fallback === state.saved.public_fallback
            ? event.settings.public_fallback
            : state.fallback,
      };
    }
  }
}
