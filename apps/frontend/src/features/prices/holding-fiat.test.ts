import { expect, it } from "vitest";
import type { HoldingView } from "../dashboard/holdings-model";
import {
  holdingFiat,
  latestRate,
  summarizeFiat,
  formatBrl,
} from "./holding-fiat";
const depix =
  "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189";
const row = (units = "25000000000"): HoldingView => ({
  key: `Liquid:${depix}`,
  metadata: {
    key: { chain: "Liquid", asset_id: depix },
    ticker: "DEPIX",
    precision: 8,
    approved: true,
  },
  balance_units: units,
  available_units: null,
  pending_units: "100000000",
  balanceText: "250",
  stale: false,
});
it("values verified DePix at exactly one BRL and rounds to cents without losing large balances", () => {
  expect(holdingFiat(row(), "Mainnet", {}).cents).toBe(25000n);
  expect(holdingFiat(row("100500000"), "Mainnet", {}).cents).toBe(101n);
  expect(
    holdingFiat(row("900719925474099300000000"), "Mainnet", {}).cents,
  ).toBe(900719925474099300n);
  expect(formatBrl(900719925474099301n, "pt-BR")).toContain(
    "9.007.199.254.740.993,01",
  );
});
it("rejects ticker impersonation, test coins, unknown precision, and unsynchronized balances", () => {
  const fake = row();
  fake.metadata.key.asset_id = "ab".repeat(32);
  expect(holdingFiat(fake, "Mainnet", {}).cents).toBeNull();
  expect(holdingFiat(row(), "Testnet", {}).cents).toBeNull();
  expect(
    holdingFiat(
      { ...row(), metadata: { ...row().metadata, precision: null } },
      "Mainnet",
      {},
    ).cents,
  ).toBeNull();
  expect(
    holdingFiat({ ...row(), balanceText: null }, "Mainnet", {}).cents,
  ).toBeNull();
  expect(
    holdingFiat({ ...row(), stale: true }, "Mainnet", {}).cents,
  ).toBeNull();
});
it("uses available market rates and labels incomplete totals instead of treating missing prices as zero", () => {
  const btc = {
    ...row("2500000"),
    key: "Bitcoin:native",
    metadata: {
      key: { chain: "Bitcoin" as const, asset_id: null },
      ticker: "BTC",
      precision: 8,
      approved: true,
    },
  };
  expect(
    holdingFiat(btc, "Mainnet", {
      Bitcoin: { price: 500000, timestamp: 123, source: "Provider" },
    }).cents,
  ).toBe(1250000n);
  const values = [
    holdingFiat(row(), "Mainnet", {}),
    holdingFiat(btc, "Mainnet", {}),
  ];
  expect(summarizeFiat([row(), btc], values)).toEqual({
    cents: 25000n,
    partial: true,
  });
  expect(summarizeFiat([btc], [values[1]])).toEqual({
    cents: null,
    partial: true,
  });
});
it("uses the newest valid observation and rejects stale, future, or invalid prices", () => {
  const now = 10_000_000;
  const history = {
    source: "Provider",
    fetched_at_ms: now,
    points: [
      { timestamp_ms: now - 100, price: 4 },
      { timestamp_ms: now - 1000, price: 3 },
    ],
  };
  expect(latestRate(history, now)?.price).toBe(4);
  expect(
    latestRate(
      { ...history, points: [{ timestamp_ms: now - 3_600_001, price: 4 }] },
      now,
    ),
  ).toBeNull();
  expect(
    latestRate(
      { ...history, points: [{ timestamp_ms: now + 600_000, price: 4 }] },
      now,
    ),
  ).toBeNull();
  expect(
    latestRate(
      { ...history, points: [{ timestamp_ms: now, price: NaN }] },
      now,
    ),
  ).toBeNull();
});
