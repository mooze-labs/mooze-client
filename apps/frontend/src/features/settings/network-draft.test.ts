import { expect, it } from "vitest";
import {
  emptyNetworkDraft,
  reduceNetworkDraft,
  isNetworkDirty,
} from "./network-draft";
import type { DesktopSettingsDto } from "../../core/desktop.generated";
const settings: DesktopSettingsDto = {
  version: 1,
  lock_minutes: 5,
  locale: "en",
  bitcoin_unit: "BTC",
  privacy: false,
  bitcoin_node: "ssl://old-btc:50002",
  liquid_node: null,
  public_fallback: false,
};
it("preserves both dirty endpoints and global fallback across refresh and saving one chain", () => {
  let state = reduceNetworkDraft(emptyNetworkDraft, {
    type: "loaded",
    settings,
  });
  state = reduceNetworkDraft(state, {
    type: "editEndpoint",
    chain: "Bitcoin",
    value: "ssl://new-btc:50002",
  });
  state = reduceNetworkDraft(state, {
    type: "editEndpoint",
    chain: "Liquid",
    value: "ssl://new-liquid:50002",
  });
  state = reduceNetworkDraft(state, { type: "editFallback", value: true });
  state = reduceNetworkDraft(state, {
    type: "loaded",
    settings: { ...settings, lock_minutes: 15 },
  });
  expect(state.endpoints).toEqual({
    Bitcoin: "ssl://new-btc:50002",
    Liquid: "ssl://new-liquid:50002",
  });
  expect(state.fallback).toBe(true);
  state = reduceNetworkDraft(state, {
    type: "saved",
    chain: "Bitcoin",
    settings: {
      ...settings,
      bitcoin_node: "ssl://new-btc:50002",
      public_fallback: true,
    },
  });
  expect(state.endpoints.Liquid).toBe("ssl://new-liquid:50002");
  expect(isNetworkDirty(state)).toBe(true);
  expect(state.saved?.liquid_node).toBeNull();
  state = reduceNetworkDraft(state, { type: "reset" });
  expect(isNetworkDirty(state)).toBe(false);
});
