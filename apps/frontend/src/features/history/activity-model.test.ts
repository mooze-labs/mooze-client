import { it, expect } from "vitest";
import { filterActivity } from "./activity-model";
import type { WalletActivityDto } from "../../../../../crates/mooze-app/generated/types";
it("filters by asset across every movement and keeps unknown dates out of date ranges", () => {
  const row = {
    id: "t",
    chain: "Liquid",
    timestamp_ms: null,
    status: "Pending",
    confirmations: 0,
    movements: [
      { asset: { chain: "Liquid", asset_id: "a" }, delta_units: "-100" },
      { asset: { chain: "Liquid", asset_id: "b" }, delta_units: "10" },
    ],
    fee: null,
    addresses: [],
  } satisfies WalletActivityDto;
  expect(filterActivity([row], { asset: "Liquid:b" })).toHaveLength(1);
  expect(filterActivity([row], { from: "2026-01-01" })).toHaveLength(0);
  expect(filterActivity([row], { status: "Confirmed" })).toHaveLength(0);
});
