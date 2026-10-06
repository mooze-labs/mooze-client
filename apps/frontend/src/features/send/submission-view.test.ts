import { expect, it } from "vitest";
import { selectSubmissionView } from "./submission-view";
import type { Snapshot } from "../../core/client";
const snapshot: Snapshot = {
  generation: 1,
  sync: null,
  chains: [],
  activity: [],
  submission: {
    version: 2,
    phase: "sent",
    chain: "Liquid",
    tx_id: "tx",
    request: null,
    debits: null,
  },
};
it("restores a broadcast receipt without inventing missing details or fees", () => {
  expect(selectSubmissionView(snapshot, null)).toMatchObject({
    phase: "broadcast",
    txid: "tx",
    request: null,
    debits: null,
    feeProvenance: "unavailable",
  });
});
it("matches confirmation and actual fees by chain and ID", () => {
  const row = {
    id: "tx",
    chain: "Bitcoin" as const,
    status: "Confirmed" as const,
    confirmations: 1,
    timestamp_ms: null,
    movements: [],
    fee: { asset: { chain: "Bitcoin" as const, asset_id: null }, units: "10" },
    addresses: [],
  };
  expect(
    selectSubmissionView({ ...snapshot, activity: [row] }, null)?.phase,
  ).toBe("broadcast");
  expect(
    selectSubmissionView(
      { ...snapshot, activity: [{ ...row, chain: "Liquid" }] },
      null,
    ),
  ).toMatchObject({ phase: "confirmed", feeProvenance: "activity" });
});
it("keeps unresolved outcomes uncertain", () => {
  expect(
    selectSubmissionView(
      {
        ...snapshot,
        submission: {
          ...snapshot.submission!,
          phase: "uncertain",
          tx_id: null,
        },
      },
      null,
    )?.phase,
  ).toBe("uncertain");
});
it("restores an approved fee bound from persisted v2 debits and prefers actual fees", () => {
  const request = {
    asset: { chain: "Liquid" as const, asset_id: "test" },
    destination: "tlq",
    amount: { mode: "Exact" as const, units: "100" },
    fee_rate_sat_per_vbyte: 0.1,
  };
  const persisted = {
    ...snapshot,
    submission: {
      ...snapshot.submission!,
      request,
      debits: [
        { asset: request.asset, units: "100" },
        {
          asset: { chain: "Liquid" as const, asset_id: "policy" },
          units: "20",
        },
      ],
    },
  };
  expect(selectSubmissionView(persisted, null)).toMatchObject({
    feeProvenance: "review",
    fee: { asset: { chain: "Liquid", asset_id: "policy" }, units: "20" },
  });
  const actual = {
    id: "tx",
    chain: "Liquid" as const,
    status: "Pending" as const,
    confirmations: 0,
    timestamp_ms: null,
    movements: [],
    addresses: [],
    fee: {
      asset: { chain: "Liquid" as const, asset_id: "policy" },
      units: "12",
    },
  };
  expect(
    selectSubmissionView({ ...persisted, activity: [actual] }, null),
  ).toMatchObject({ feeProvenance: "activity", fee: { units: "12" } });
  const btc = {
    ...snapshot,
    submission: {
      ...snapshot.submission!,
      chain: "Bitcoin" as const,
      request: {
        ...request,
        asset: { chain: "Bitcoin" as const, asset_id: null },
      },
      debits: [
        { asset: { chain: "Bitcoin" as const, asset_id: null }, units: "115" },
      ],
    },
  };
  expect(selectSubmissionView(btc, null)?.fee?.units).toBe("15");
});
