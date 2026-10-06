import { expect, it } from "vitest";
import { selectHoldings, assetKey } from "./holdings-model";
import type { HoldingDto } from "../../../../../crates/mooze-app/generated/types";
const btc = {
  metadata: {
    key: { chain: "Bitcoin", asset_id: null },
    ticker: "BTC",
    precision: 8,
    approved: true,
  },
  balance_units: "0",
  available_units: null,
  pending_units: "0",
} satisfies HoldingDto;
it("distinguishes unsynchronized from zero and retains large unknown units", () => {
  const unknown = {
    metadata: {
      key: { chain: "Liquid", asset_id: "ab".repeat(32) },
      ticker: null,
      precision: null,
      approved: false,
    },
    balance_units: "9007199254740993",
    available_units: null,
    pending_units: null,
  } satisfies HoldingDto;
  const rows = selectHoldings(
    [btc, unknown],
    [
      {
        chain: "Bitcoin",
        phase: "error",
        last_success_at_ms: null,
        error: null,
      },
      {
        chain: "Liquid",
        phase: "error",
        last_success_at_ms: 1,
        error: "offline",
      },
    ],
    [],
  );
  expect(rows[0].balanceText).toBe(null);
  expect(rows[1].balanceText).toBe("9007199254740993");
  expect(rows[1].stale).toBe(true);
  expect(rows[1].metadata.approved).toBe(false);
  const ready = selectHoldings(
    [btc],
    [{ chain: "Bitcoin", phase: "ready", last_success_at_ms: 1, error: null }],
    [],
  );
  expect(ready[0].balanceText).toBe("0,00000000");
});
it("retains a zero TEST holding when it has activity", () => {
  const test = {
    ...btc,
    metadata: {
      ...btc.metadata,
      key: {
        chain: "Liquid" as const,
        asset_id:
          "38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5",
      },
      ticker: "TEST",
    },
  };
  expect(selectHoldings([test], [], [])).toHaveLength(0);
  expect(
    selectHoldings([test], [], [assetKey(test.metadata.key)]),
  ).toHaveLength(1);
});
