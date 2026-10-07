import { expect, it } from "vitest";
import { canConfirm } from "./swap-state";
it("only confirms a current unexpired review and never a pending submission", () => {
  const state = {
    phase: "Review",
    review: {
      id: "r",
      generation: 1,
      send_asset_id: "a",
      receive_asset_id: "b",
      send_units: "100",
      receive_units: "200",
      fees: [],
      expires_at_ms: 1000,
    },
    txid: null,
    message: null,
  };
  expect(canConfirm(state, 999, false)).toBe(true);
  expect(canConfirm(state, 1000, false)).toBe(false);
  expect(canConfirm(state, 999, true)).toBe(false);
  expect(canConfirm({ ...state, phase: "Submitting" }, 999, false)).toBe(false);
  expect(canConfirm({ ...state, review: null }, 999, false)).toBe(false);
});
